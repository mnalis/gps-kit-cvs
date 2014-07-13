#include <unistd.h>
#include <stdlib.h>
#include <syslog.h>
#include <signal.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <string.h>
#include <netdb.h>
#include <stdarg.h>
#include <setjmp.h>
#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <assert.h>
#include <pwd.h>
#include <stdbool.h>
#include <math.h>

#include "config.h"
#if defined (HAVE_PATH_H)
#include <paths.h>
#else
#if !defined (_PATH_DEVNULL)
#define _PATH_DEVNULL    "/dev/null"
#endif
#endif
#if defined (HAVE_SYS_SELECT_H)
#include <sys/select.h>
#endif
#if defined (HAVE_SYS_STAT_H)
#include <sys/stat.h>
#endif
#if defined(HAVE_SYS_TIME_H)
#include <sys/time.h>
#endif

#if DBUS_ENABLE
#include <gpsd_dbus.h>
#endif

#include "gpsd.h"
#include "timebase.h"

/*
 * Timeout policy.  We can't rely on clients closing connections 
 * correctly, so we need timeouts to tell us when it's OK to 
 * reclaim client fds.  The assignment timeout fends off programs
 * that open connections and just sit there, not issuing a W or
 * doing anything else that triggers a device assignment.  Clients
 * in watcher or raw mode that don't read their data will get dropped 
 * when throttled_write() fills up the outbound buffers and the 
 * NOREAD_TIMEOUT expires.  Clients in the original polling mode have 
 * to be timed out as well.
 */
#define ASSIGNMENT_TIMEOUT	60
#define POLLER_TIMEOUT  	60*15
#define NOREAD_TIMEOUT		60*3

#define QLEN			5

/* Where to find the list of DGPS correction servers, if there is one */
#define DGPS_SERVER_LIST	"/usr/share/gpsd/dgpsip-servers"


/*
 * The name of a tty device from which to pick up whatever the local
 * owning group for tty devices is.  Used when we drop privileges.
 */
#define PROTO_TTY "/dev/ttyS0"

static fd_set all_fds;
static int debuglevel;
static bool in_background = false;
static jmp_buf restartbuf;
/*@ -initallelements -nullassign -nullderef @*/
static struct gps_context_t context = {
    .valid        = 0, 
    .sentdgps     = false, 
    .fixcnt       = 0, 
    .dsock        = -1, 
    .rtcmbytes    = 0, 
    .rtcmbuf      = {'\0'}, 
    .rtcmtime     = 0,
    .leap_seconds = LEAP_SECONDS, 
    .century      = CENTURY_BASE, 
#ifdef NTPSHM_ENABLE
    .shmTime      = {0},
    .shmTimeInuse = {0},
# ifdef PPS_ENABLE
    .shmTimePPS   = false,
# endif /* PPS_ENABLE */
#endif /* NTPSHM_ENABLE */
};
/*@ +initallelements +nullassign +nullderef @*/

static void onsig(int sig)
{
    longjmp(restartbuf, sig+1);
}

static int daemonize(void)
{
    int fd;
    pid_t pid;

    switch (pid = fork()) {
    case -1:
	return -1;
    case 0:	/* child side */
	break;
    default:	/* parent side */
	exit(0);
    }

    if (setsid() == -1)
	return -1;
    (void)chdir("/");
    /*@ -nullpass @*/
    if ((fd = open(_PATH_DEVNULL, O_RDWR, 0)) != -1) {
	(void)dup2(fd, STDIN_FILENO);
	(void)dup2(fd, STDOUT_FILENO);
	(void)dup2(fd, STDERR_FILENO);
	if (fd > 2)
	    (void)close(fd);
    }
    /*@ +nullpass @*/
    in_background = true;
    return 0;
}

#if defined(PPS_ENABLE)
static pthread_mutex_t report_mutex;
#endif /* PPS_ENABLE */

void gpsd_report(int errlevel, const char *fmt, ... )
/* assemble command in printf(3) style, use stderr or syslog */
{
    if (errlevel <= debuglevel) {
	char buf[BUFSIZ], buf2[BUFSIZ], *sp;
	va_list ap;

#if defined(PPS_ENABLE)
	(void)pthread_mutex_lock(&report_mutex);
#endif /* PPS_ENABLE */
	(void)strlcpy(buf, "gpsd: ", BUFSIZ);
	va_start(ap, fmt) ;
	(void)vsnprintf(buf + strlen(buf), sizeof(buf)-strlen(buf), fmt, ap);
	va_end(ap);

	buf2[0] = '\0';
	for (sp = buf; *sp != '\0'; sp++)
	    if (isprint(*sp) || (isspace(*sp) && (sp[1]=='\0' || sp[2]=='\0')))
		(void)snprintf(buf2+strlen(buf2), 2, "%c", *sp);
	    else
		(void)snprintf(buf2+strlen(buf2), 6, "\\x%02x", (unsigned)*sp);

	if (in_background)
	    syslog((errlevel == 0) ? LOG_ERR : LOG_NOTICE, "%s", buf2);
	else
	    (void)fputs(buf2, stderr);
#if defined(PPS_ENABLE)
	(void)pthread_mutex_unlock(&report_mutex);
#endif /* PPS_ENABLE */
    }
}

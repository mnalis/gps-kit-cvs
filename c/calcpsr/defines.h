/* $CSK: defines.h,v 1.5 2006/09/15 03:12:52 ckuethe Exp $ */
/* constant values */
/* --------------- */
#define C		299792458.0     /* WGS84 Speed of Light (metres/sec) */
#define L1		0.190293672798364900	/* Wavelength of L1 (metres) */
#define BPSData		(double)50.0	/* 50 bits per second */
#define Ms		(double)1000.0	/* milliseconds per second */
#define ChipCode	(double)1023.0	/* L1 chip numbers */
#define PHASELOCK	63		/* 3F status */


/* macro substitutions */
/* ------------------- */
#define MATCH 	0		/* for strncmpi values */
#define SUCCESS 1
#define FAILURE 0
#define YES 1
#define NO 0
#define ESC 0x1B

#define NumSvs	33		/* for satellite vector data */


/* required in calceph */
/* ------------------- */
#define EPHMK1		768
#define EPHMK1		768
#define EPHMK2		255
#define EPHMK3		65532
#define EPHMK4		65280
#define EPHMK5		65535
#define MASK		31	/* NAVGetHealthIndicator() */



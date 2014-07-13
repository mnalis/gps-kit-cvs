/* $CSK: datstruc.h,v 1.4 2006/09/15 01:21:48 ckuethe Exp $ */
/* global structures */
/* ----------------- */

typedef struct
{
int 	ID, /* message ID */
	channel, /* channel in track */
	SvID, /* satellite prn */
	status; /* hex value for current status (3F required) */
unsigned long BitNumber; /* 20 ms intervals into the week */
int	MsNumber, /* number of into 20 ms (range 0-20) */
	ChipNumber; /* Code tracking chip number (range 0-1023) */
long	CodePhase, /* 1/65536 of a chip */
	CarrierDoppler, /* Freq in Hz/0.0777 */
	TimeTag, /* Time tag of measeurment in ms */
	DeltaCarrierPhase; /* -deltaPsr*Accumulated Time (ms) * 0.19/1.024 */
int 	SearchCount, /* Not in use */
	CNo[10], /* 100 ms intervals of tracking data */
	BadPrCount, /* number of 20 ms checks that failed for power */
	BadDrCount, /* number of 20 ms checks that failed for carrier phase lock */
	AccumTime, /* time (in ms) for carrier accumulation */
	TrackLoopTime; /* 2 = 2ms loops, 15 = 10 ms dwell time loops */
}
RAWDATA;


typedef	struct
{
double	ephaf0; /* Clock phase offset coefficient */
	/* units: sec, range: -9.766e-04 to +9.766e-04 */

double	ephm0; /* Mean anomaly at reference time of week */
	/* units: radians, range: -pi to +pi */

double	ephe; /* Eccentricity of the satellite's orbit */
	/* units: n/a, range: 0 to 0.03 */

double	ephsqa; /* Square root of the transmitter's (sv) */
	/* semi-major orbital axis.	Assuming orbit is */
	/* elliptical. this parameter is used to */
	/* determine if the transmitter is ground-based. */
	/* units: meters ** 0.5, range: 0 to 8192 */

double	ephom0; /* (OMEGA)o - right ascension at reference time. */
	/* units: radians, range: -pi to pi */

double	ephi0; /* Io - Inclination angle at reference time. */
	/* units: radians, range: -pi to +pi */

double	ephw; /* w - argument of perigee. */
	/* units: radians, range: -pi to +pi */

double	ephomd; /* OMEGADOT - rate of right ascension. */
	/* units: radians/second, -pi e-07 to +pi e-07 */

double	ephtgd; /* group delay time.	accounts for time between */
	/* the generation of	the transmitter clock and */
	/* its actual broadcast. */
	/* units: seconds, range: -5.96e+08 to +5.96e+08 */

double	ephaf2; /* Clock frequency drift coefficient. equal to 0 */
	/* if almanac data. */
	/* units: sec/sec*sec, -3.5e-15 to +3.5e-15 */

double	ephaf1; /* clock frequency offset coefficient. */
	/* units: sec/sec, range: -3.72e-09 to +3.72e-09 */

double	ephcrs; /* Crs - amplitude of the sine harmonic correction */
	/* term to the orbit radius. */
	/* units: meters, range: -1024e-4 to +1024 */

double	ephmdn; /* mean motion difference from computed value. */
	/* equal to 0 if almanac data. */
	/* units: radians/seconds,-11.6e-09 to +11.6e-09 */

double	ephcuc; /* Crc - amplitude of the cosine harmonic correctio*/
	/* term to the argument of latitude. equal to 0 if */
	/* almanac data. */
	/* units: radians, range: -6.1e-05 to +6.1e+05 */

double	ephcus; /* Cus - amplitude of the sine harmonic correction */
	/* term to the argument of latitude. equal to zero */
	/* if almanac data. */
	/* units: radians, range: -6.1e-05 to +6.1e-05 */

double	ephcic; /* Cic - amplitude of the cosine harmonic correc- */
	/* tion term to the angle of inclination. equal to */
	/* 0 if almanac data. */
	/* units: radians, range: -6.1e-05 to +6.1e-05 */

double	ephcis; /* Cis - amplitude of the sine harmonic correction */
	/* term to the angle	of inclination. equal to 0 if */
	/* almanac data.  */
	/* units: radians, range: -6.1e-05 to +6.1e-05 */

double	ephcrc; /* Crc - amplitude of the cosine harmonic correc- */
	/* tion term to the orbit radius.	equal to 0 if */
	/* almanac data. */
	/* units: meters, range: -1024 to +1024 */

double	ephidt; /* IDOT - rate of change of inclination angle. */
	/* equal to 0 if almanac data. */
	/* units: radians/second, -29.3e-10 to +29.3e-10 */

long	ephadc; /* data set indicator number of ephemeris parameter*/
	/* which vary from curve fit to curve fit. equal to*/
	/* 0 if almanac data. */
	/* units: seconds, range: 1 to 524288 */
	/* this is hte same as AODE !!! */

long	ephtoc; /* the clock correction parameters af0,af1 and af2 */
	/* define a curve	used to correct the time sent */
	/* from the satellite. the clock time is the */
	/* reference point for which the curve is valid. */
	/* units: seconds, range: 0 to 604800 */

long	ephtoe; /* Toe - gps time of week referenced from the start*/
	/* of the week. the middle of the fit interval from*/
	/* which calculations are based,for ephemeris data,*/
	/* this time is 2 or 3 hours after the start	of the*/
	/* interval, depending on the length of the  */
	/* interval. if almanac data, this time is 3.5 days*/
	/* after the start of the week. */
	/* units: seconds, range: 0 to 604800 */

short	ephfit; /* duration of the interval over which the */
	/* satellite's ephemeris fit (a segment of its */
	/* orbital path) has been forecast. */
	/* 0 = 4 hour segment forecast */
	/* 1 = 6 hour segment forecast */
	/* units: n/a, range: o or 1 */

short	ephwno; /* gps week number broadcast by the transmitter or */
	/* forecast by	the almanac. */
	/* units: weeks, range: 0 to 1023 */

short	ephacc; /* user range accuracy. */
	/* units: n/a, range: 0 to 15 */

short	ephsta; /* ephemeris data status indicator indicating the */
	/* following: */
	/* 0 = eph or almanac data not available */
	/* 1 = ephemeris_local_entity contains ephem data */
	/* 2 = ephemeris_local_entity contains almanac data*/
	/* units: n/a, range: 0 to 2 */

long	ephaodc; /* Age of data clock - not required ?? */
double	ephdeltan; /* almanac parameter - not required */

}
EPHEMERIS_DEFS;


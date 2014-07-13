/* $CSK: protos.h,v 1.4 2006/09/15 01:21:48 ckuethe Exp $ */
/* function prototypes */
/* ------------------- */


/* calcpsr.c */
/* --------- */
void ComputePsr(	FILE * /* fpMEAS */,
			RAWDATA * /* raw */,
			int * /* NewEpoch */ );

void SavePSR(		int /* svid */,
			double /* psr */,
			double /* ReceiverTime */,
			double /* ExtrapolationTime */,
			int /* ReferenceChannel */,
			int /* ReferenceSvID */ );

void SaveRawData(	int /* svid */,
			char * /* buffer */ );

/* caleph.c */
/* -------- */
int CalcEphParameters(	char * /* buffer */,
			FILE * /* fpEPH */ );

double  NAVConvertDataBits (	unsigned long data,
				short dt_pos,
				short dt_len,
				short dt_scl,
				short dt_sig );  /* sirf function */

short GetHealth(	short /* h_code */ ); /* sirf function */


/* $CSK: caleph.c,v 1.10 2006/09/15 03:07:45 ckuethe Exp $ */
/* this function set deals with decoding of the EPH data */
/* from the polled command                               */
/* ----------------------------------------------------- */

#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>


/* local headers */
/* ------------- */
#include "defines.h"
#include "datstruc.h"
#include "protos.h"


/*
 *	Ephemeris constants	..........................................
 */

typedef struct
{
	short	ephpos;
	short	ephlen;
	short	ephscl;
	short	ephsig;
}
EPHCON;

const EPHCON	ephcon[] =
{
	{ 6,	10,	  0,	0 },	/*  0 */
	{ 0,	 4,	  0,	0 },	/*  1 */
	{ 0,	10,	  0,	0 },	/*  2 */
	{ 8,	 8,	-31,	1 },	/*  3 */
	{ 0,	16,	  4,	0 },	/*  4 */
	{ 8,	 8,	-55,	1 },	/*  5 */
	{ 0,	16,	-43,	1 },	/*  6 */
	{ 0,	22,	-31,	1 },	/*  7 */
	{ 0,	16,	 -5,	1 },	/*  8 */
	{ 0,	16,	-43,	1 },	/*  9 */
	{ 0,	32,	-31,	1 },	/* 10 */
	{ 0,	16,	-29,	1 },	/* 11 */
	{ 0,	32,	-33,	0 },	/* 12 */
	{ 0,	16,	-29,	1 },	/* 13 */
	{ 0,	32,	-19,	0 },	/* 14 */
	{ 0,	16,	  4,	0 },	/* 15 */
	{ 7,	 1,	  0,	0 },	/* 16 */
	{ 0,	16,	-29,	1 },	/* 17 */
	{ 0,	32,	-31,	1 },	/* 18 */
	{ 0,	16,	-29,	1 },	/* 19 */
	{ 0,	32,	-31,	1 },	/* 20 */
	{ 0,	16,	 -5,	1 },	/* 21 */
	{ 0,	32,	-31,	1 },	/* 22 */
	{ 0,	24,	-43,	1 },	/* 23 */
	{ 2,	14,	-43,	1 },	/* 24 */
};
/*
 *	SV ok indicies	................................................
 */
const short	svok[] =
{
	 0,	/*  0 */
	 1,	/*  1 */
	 4,	/*  2 */
	 7,	/*  3 */
	 9,	/*  4 */
	10,	/*  5 */
	13,	/*  6 */
	14,	/*  7 */
	15,	/*  8 */
	16,	/*  9 */
	19,	/* 10 */
	22,	/* 11 */
	25,	/* 12 */
	27,	/* 13 */
};
/*
 *	CA only indicies	.............................................
 */
const short	caonly[] =
{
	 5,	/*  0 */
	 6,	/*  1 */
	17,	/*  2 */
	18,	/*  3 */
};

/*
 *	L1 only indicies	.............................................
 */
const short	l1only[] =
{
	 8,	/*  0 */
	26,	/*  1 */
};

/*
 *	SV bad indicies	.............................................
 */
const short	svbad[] =
{
	 2,	/*  0 */
	 3,	/*  1 */
	11,	/*  2 */
	12,	/*  3 */
	20,	/*  4 */
	21,	/*  5 */
	23,	/*  6 */
	24,	/*  7 */
	28,	/*  8 */
	29,	/*  9 */
	30,	/* 10 */
	31,	/* 11 */
};



int CalcEphParameters(char *buffer, FILE *fpEPH)
{
EPHEMERIS_DEFS eph;	/* ephemeris values */

long tempor;	/* temp value for shifting */
double ret_data;	/* double returned after calc, then re casted */

int i,j;		/* loop index */
short Svid = 0;	/* svid of ephemeris */
long ephdata[3][15];	/* each sv has a 3x15 16 bit but stored in 32 bits fields */
short EphHealth;	/* health status as defined by ICD 200 */
static int ephcount[33]={0};	/* number of eph record fro each SV */

/* initialize all values to a zero */
/* ------------------------------- */
	for(i=0;i<3;i++)
	{
		for(j=0;j<15;j++)
			ephdata[i][j]=0;
	}

/* data file is in three packets (subframe 1,2,3) */
/* ---------------------------------------------- */
	sscanf(buffer,
	    "%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld,%10ld",
	    &ephdata[0][0], &ephdata[0][1], &ephdata[0][2], &ephdata[0][3],
	    &ephdata[0][4], &ephdata[0][5], &ephdata[0][6], &ephdata[0][7],
	    &ephdata[0][8], &ephdata[0][9], &ephdata[0][10], &ephdata[0][11],
	    &ephdata[0][12], &ephdata[0][13], &ephdata[0][14], &ephdata[1][0],
	    &ephdata[1][1], &ephdata[1][2], &ephdata[1][3], &ephdata[1][4],
	    &ephdata[1][5], &ephdata[1][6], &ephdata[1][7], &ephdata[1][8],
	    &ephdata[1][9], &ephdata[1][10], &ephdata[1][11], &ephdata[1][12],
	    &ephdata[1][13], &ephdata[1][14], &ephdata[2][0], &ephdata[2][1],
	    &ephdata[2][2], &ephdata[2][3], &ephdata[2][4], &ephdata[2][5],
	    &ephdata[2][6], &ephdata[2][7], &ephdata[2][8], &ephdata[2][9],
	    &ephdata[2][10], &ephdata[2][11], &ephdata[2][12],
	    &ephdata[2][13], &ephdata[2][14]);

/* SVid of 0 (zero) are invalid */
/* ---------------------------- */
	if((ephdata[0][0]==0) || (ephdata[1][0]==0) || (ephdata[2][0]==0))
		return (FAILURE);

/* ensure that the data has an associated SVid */
/* ------------------------------------------- */
	if((ephdata[0][0]!=ephdata[1][0]) || (ephdata[1][0]!=ephdata[2][0]) || (ephdata[2][0]!=ephdata[0][0]))
		return (FAILURE);

/* decode each subframe */
/* -------------------- */
	for(i=0;i<3;i++)
	{

/* compute the eph parameters based on ephdef.h */
/* -------------------------------------------- */
		switch(i)
		{
			case 0: /* subframe 1 */
				/* SVid */
				Svid=ephdata[i][0];

/* keep track of number of eph for the Sv. */
/* --------------------------------------- */
				ephcount[Svid]++;

				/* week no. */
				ret_data = NAVConvertDataBits(ephdata[i][3],
				    ephcon[0].ephpos, ephcon[0].ephlen,
				    ephcon[0].ephscl, ephcon[0].ephsig);
				eph.ephwno = (short)ret_data;


				/* user range accuracy */
				ret_data = NAVConvertDataBits(ephdata[i][3],
				    ephcon[1].ephpos, ephcon[1].ephlen,
				    ephcon[1].ephscl, ephcon[1].ephsig);
				eph.ephacc = (short)ret_data;

				/* satellite health */
				EphHealth=GetHealth((short)(ephdata[i][4]>>10));

				/* AODC */
				tempor = ((ephdata[i][4] & EPHMK1) |
				    (ephdata[i][10] & EPHMK2));
				ret_data = NAVConvertDataBits(tempor,
				    ephcon[2].ephpos, ephcon[2].ephlen,
				    ephcon[2].ephscl, ephcon[2].ephsig);
				 eph.ephaodc = (long)ret_data;

				/* group delay */
				eph.ephtgd = NAVConvertDataBits(ephdata[i][10],
				    ephcon[3].ephpos, ephcon[3].ephlen,
				    ephcon[3].ephscl, ephcon[3].ephsig);

				/* Time of Clock */
				ret_data = NAVConvertDataBits(ephdata[i][11],
				    ephcon[4].ephpos, ephcon[4].ephlen,
				    ephcon[4].ephscl, ephcon[4].ephsig);
				eph.ephtoc = (long)ret_data;

				/* satellite clock polynomial values (Af2, Af1, Af0) */
				eph.ephaf2 = NAVConvertDataBits(ephdata[i][12],
				    ephcon[5].ephpos, ephcon[5].ephlen,
				    ephcon[5].ephscl, ephcon[5].ephsig);

				tempor = (((ephdata[i][12] & EPHMK2) <<  8) | 
				    ((ephdata[i][13] & EPHMK4) >> 8));
				eph.ephaf1 = NAVConvertDataBits(tempor,
				    ephcon[6].ephpos, ephcon[6].ephlen,
				    ephcon[6].ephscl, ephcon[6].ephsig);

				tempor = (((ephdata[i][13] & EPHMK2) << 14) | 
				    ((ephdata[i][14] & EPHMK3) >> 2));
				eph.ephaf0 = NAVConvertDataBits(tempor,
				    ephcon[7].ephpos, ephcon[7].ephlen,
				    ephcon[7].ephscl, ephcon[7].ephsig);

/* printf out results */
/* ------------------ */
				fprintf(fpEPH, "\n\nSubframe 1 data for Sv. Id. -> %d \n",Svid);
				fprintf(fpEPH, "Week Nmber = %d, User range Accuracy = %d\n", eph.ephwno, eph.ephacc);
				fprintf(fpEPH, "Eph Health = %d, AODC = %ld\n",EphHealth, eph.ephaodc);
				fprintf(fpEPH, "Group Delay = %.10lf, TOC = %ld\n", eph.ephtgd, eph.ephtoc);
				fprintf(fpEPH, "Clock Parameters Af0 %.10lf, Af1 %.10lf, Af2 %.10lf\n", eph.ephaf0, eph.ephaf1, eph.ephaf2);

				break;

			case 1:		/* sub frame 2 */

				/* SVid */
				Svid=ephdata[i][0];

				/* Amplitude of sign harmonic */
				tempor = (((ephdata[i][3] & EPHMK2) <<  8) |
				    ((ephdata[i][4] & EPHMK4) >> 8));
				eph.ephcrs = NAVConvertDataBits(tempor,
				    ephcon[8].ephpos, ephcon[8].ephlen,
				    ephcon[8].ephscl, ephcon[8].ephsig);

				/* Delta tan - Almanac parameter */
				tempor = (((ephdata[i][4] & EPHMK2) <<  8) |
				    ((ephdata[i][5] & EPHMK4) >> 8));
				eph.ephdeltan = NAVConvertDataBits(tempor,
				    ephcon[9].ephpos, ephcon[9].ephlen,
				    ephcon[9].ephscl, ephcon[9].ephsig) * M_PI;

				/* Mean Anomoly at reference time */
				tempor = (((ephdata[i][5] & EPHMK2) << 24) |
				    ((ephdata[i][6] & EPHMK5) << 8));
				tempor = (tempor | ((ephdata[i][7] & EPHMK4)
				    >> 8));
				eph.ephm0 = NAVConvertDataBits(tempor,
				    ephcon[10].ephpos, ephcon[10].ephlen,
				    ephcon[10].ephscl, ephcon[10].ephsig)
				    * M_PI;

				/* Amplitutude of Cosine Harmonic correction */
				tempor = (((ephdata[i][7] & EPHMK2 ) << 8) |
				    ((ephdata[i][8] & EPHMK4) >> 8));
				eph.ephcuc = NAVConvertDataBits(tempor,
				    ephcon[11].ephpos, ephcon[11].ephlen,
				    ephcon[11].ephscl, ephcon[11].ephsig );

				/* Eccentricity of Satellite Orbit */
				tempor = (((ephdata[i][8] & EPHMK2) << 24) |
				    ((ephdata[i][9] & EPHMK5) << 8));
				tempor = (tempor | ((ephdata[i][10] & EPHMK4)
				    >> 8));
				eph.ephe = NAVConvertDataBits(tempor,
				    ephcon[12].ephpos, ephcon[12].ephlen,
				    ephcon[12].ephscl, ephcon[12].ephsig);

				/* Amplitude of Sine Harmonic Correction */
				tempor = (((ephdata[i][10] & EPHMK2) <<  8) |
				    ((ephdata[i][11] & EPHMK4) >> 8));
				eph.ephcus = NAVConvertDataBits(tempor,
				    ephcon[13].ephpos, ephcon[13].ephlen,
				    ephcon[13].ephscl, ephcon[13].ephsig);

				/* square root of A (seni major axis) */
				tempor = (((ephdata[i][11] & EPHMK2) << 24) |
				    ((ephdata[i][12] & EPHMK5) << 8));
				tempor = (tempor | ((ephdata[i][13] & EPHMK4)
				    >> 8));
				eph.ephsqa = NAVConvertDataBits(tempor,
				    ephcon[14].ephpos, ephcon[14].ephlen,
				    ephcon[14].ephscl, ephcon[14].ephsig);

				/* Time of Ephemeris */
				tempor = (((ephdata[i][13] & EPHMK2) <<  8) |
				    ((ephdata[i][14] & EPHMK4) >> 8));
				ret_data = NAVConvertDataBits(tempor,
				    ephcon[15].ephpos, ephcon[15].ephlen,
				    ephcon[15].ephscl, ephcon[15].ephsig);
				eph.ephtoe = (long)ret_data;

				/* Fit interval of satellite orbit */
				ret_data = NAVConvertDataBits(ephdata[i][14],
				    ephcon[16].ephpos, ephcon[16].ephlen,
				    ephcon[16].ephscl, ephcon[16].ephsig);
				eph.ephfit = (short)ret_data;

				fprintf(fpEPH, "\nSubframe 2 data for Sv. Id. -> %d \n",Svid);
				fprintf(fpEPH, "crs = %.10lf , Deltan= %.10lf, Mean Anomoly = %.10lf\n", eph.ephcrs, eph.ephdeltan, eph.ephm0);
				fprintf(fpEPH, "cuc = %.10lf , eccentricity = %.10lf, cus = %.10lf\n", eph.ephcuc, eph.ephe, eph.ephcus);
				fprintf(fpEPH, "sqrtA = %.10lf , Time of Eph = %ld, Orbit Fit = %d\n", eph.ephsqa, eph.ephtoe, eph.ephfit);

				break;

			case 2:		/* subframe 3 */

				/* SVid */
				Svid=ephdata[i][0];

				/* Amplitude of Cosine Harmonic Correction */
				eph.ephcic = NAVConvertDataBits(ephdata[i][3],
				    ephcon[17].ephpos, ephcon[17].ephlen,
				    ephcon[17].ephscl, ephcon[17].ephsig);

				/* Omega0 - Right ascension at reference time */
				tempor = (((ephdata[i][4] & EPHMK5) << 16) | 
				    (ephdata[i][5] & EPHMK5));
				eph.ephom0 = NAVConvertDataBits(tempor,
				    ephcon[18].ephpos, ephcon[18].ephlen,
				    ephcon[18].ephscl, ephcon[18].ephsig) 
				    * M_PI;

				/* Amplitude of Sine Harmonic Correction */
				eph.ephcis = NAVConvertDataBits(ephdata[i][6],
				    ephcon[19].ephpos, ephcon[19].ephlen,
				    ephcon[19].ephscl, ephcon[19].ephsig);

				/* I0 - Inclination angle at reference time */
				tempor = (((ephdata[i][7] & EPHMK5) << 16) | 
				    (ephdata[i][8] & EPHMK5));
				eph.ephi0 = NAVConvertDataBits(tempor,
				    ephcon[20].ephpos, ephcon[20].ephlen,
				    ephcon[20].ephscl, ephcon[20].ephsig) 
				    * M_PI;

				/* Amplitude of Cosine Harmonic Correction ... */
				eph.ephcrc = NAVConvertDataBits(ephdata[i][9],
				    ephcon[21].ephpos, ephcon[21].ephlen,
				    ephcon[21].ephscl, ephcon[21].ephsig);

				/* w (omega) - argument of Perigee */
				tempor = (((ephdata[i][10] & EPHMK5) << 16) | 
				    (ephdata[i][11] & EPHMK5));
				eph.ephw = NAVConvertDataBits(tempor,
				    ephcon[22].ephpos, ephcon[22].ephlen,
				    ephcon[22].ephscl, ephcon[22].ephsig)	
				    * M_PI;

				/* Omega dot - rate of right ascension */
				tempor = (((ephdata[i][12] & EPHMK5) <<  8) | 
				    ((ephdata[i][13] & EPHMK4) >> 8));
				eph.ephomd = NAVConvertDataBits(tempor,
				    ephcon[23].ephpos, ephcon[23].ephlen,
				    ephcon[23].ephscl, ephcon[23].ephsig) 
				    * M_PI;

				/* I dot - Rate of change of Inclination Angle */
				eph.ephidt = NAVConvertDataBits(ephdata[i][14],
				    ephcon[24].ephpos, ephcon[24].ephlen,
				    ephcon[24].ephscl, ephcon[24].ephsig) 
				    * M_PI;

				fprintf(fpEPH, "\nSubframe 3 data for Sv. Id. -> %d \n",Svid);
				fprintf(fpEPH, "cic = %.10lf, Omega 0 = %.10lf, cis = %.10lf\n", eph.ephcic, eph.ephom0, eph.ephcis);
				fprintf(fpEPH, "I0 = %.10lf, crc = %.10lf, Omega = %.10lf\n", eph.ephi0, eph.ephcrc, eph.ephw);
				fprintf(fpEPH, "Omega dot = %.10lf, I dot = %.10lf \n", eph.ephomd, eph.ephidt);

				break;
		}
	}
/* output results to file */
/* ---------------------- */
	printf("\tEph for SV %d (%d) found\n", Svid, ephcount[Svid]);

	return(SUCCESS);
}

/*
***************************************************************************
*                                                                         *
* NAVConvertDataBits                                                      *
*                                                                         *
* Input:                                                                  *
*                                                                         *
* Output:                                                                 *
*                                                                         *
* Description:                                                            *
*       This routine will convert raw data (i.e. the binary subframe raw  *
*       data) into double precision floating point values.                *
*                                                                         *
*       Check ICD-GPS-200 page 85 for more detail.                        *
*                                                                         *
****************************************************************************/

#define NOT_0_LONG			((long)(~0L))	/* Not 0 for long */
#define ONE_SHFLEFT_30		(01L << 30)

double  NAVConvertDataBits (unsigned long data, short dt_pos, short dt_len,
	short dt_scl, short dt_sig)
{
	double  ret_data;
  	long loc_dt_scl = dt_scl;
	short	temp;

	/*
   ***********************************************************
   * Shift the data by {dt_pos+dt_len} bits to the left and  *
   * get the data alone from the total bit length using ~0   *
   ************************************************************/

	if ((temp=(short)(dt_pos+dt_len)) != 32)
		data = (data & ~(NOT_0_LONG << temp));

	/*
   ***********************************************************
   * Get {dt_len} bits from the data from position {dt_pos}  *
   ************************************************************/

	data = data >> dt_pos;
	if (dt_sig == 1)
	{
		if ( ( data & (01L << (dt_len - 1)) ) != 0)
			data = data | (NOT_0_LONG << (dt_len - 1) );
		ret_data = (signed long) data;
	}
	else
		ret_data = (unsigned long) data;
	/*
   *********************************************************
   * Scale the bits of {data} by the scale factor          *
   * {2 exp dt_scl}                                        *
   **********************************************************/

	if (loc_dt_scl >= 0)
	{
		while (loc_dt_scl > 30)
		{
			ret_data *= (ONE_SHFLEFT_30);
			loc_dt_scl -= 30;
		}
		ret_data *= (01L << loc_dt_scl);
	}
	else
	{
		loc_dt_scl = -loc_dt_scl;
		while(loc_dt_scl > 30)
		{
			ret_data /= ((long) ONE_SHFLEFT_30);
			loc_dt_scl -= 30;
		}
		ret_data /= (01L << loc_dt_scl );
	}

	/*
   *****************************************************
   * If dt_sig = 1, then the value is a negative value *
   ******************************************************/
	return (ret_data);

} /* NAVConvertDataBits() */


/*
***************************************************************************
*                                                                         *
* GetHealth                                                               *
*                                                                         *
*       This subroutine converts the 5-bit satellite health               *
*       code (table 20-(viii, icd-gps-200) to the following health        *
*       indicator, AND RETURNS IT:                                        *
*                                                                         *
*             0 = sv ok                                                   *
*             1 = use c/a only                                            *
*             2 = use l1 only                                             *
*             3 = l2 data free                                            *
*             4 = sv useless                                              *
*                                                                         *
****************************************************************************/

short GetHealth(short h_code)
{
int i;		/* loop index */


   h_code &= (short) MASK;       /* mask off 6th bit of health code */

   /*
   ***************************
   * check for sv signals ok *
   ****************************/
	for (i=0; i<=(sizeof(svok)/sizeof(svok[0])); ++i)
	{
		if (h_code == svok[i])
			return(0);
	}

   /*
   **************************
   * check for use c/a only *
   ***************************/
	for (i=0; i<=(sizeof(caonly)/sizeof(caonly[0])); ++i)
	{
		if (h_code == caonly[i])
			return(1);
	}

   /*
   ***************************
   * check for l1 only       *
   ****************************/
	for (i=0; i<=(sizeof(l1only)/sizeof(l1only[0])); ++i)
	{
		if (h_code == l1only[i])
			return(2);
	}

   /*
   ***************************
   * check for sv useless    *
   ****************************/

	for (i=0; i<=(sizeof(svbad)/sizeof(svbad[0])); ++i)
	{
		if (h_code == svbad[i])
			return(4);
	}

   /*
   ***************************
   * code not found          *
   ****************************/
	return(4);
}/* GetHealth() */




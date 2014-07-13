/* $CSK: calcpsr.c,v 1.8 2006/09/15 15:42:30 ckuethe Exp $ */
/* all functions associated with measurement data */
/* ---------------------------------------------- */

#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


/* local headers */
/* ------------- */
#include "defines.h"
#include "datstruc.h"
#include "protos.h"


extern double IntegratedCarrier[NumSvs];	/* defined in main.c  */
static double PreviousPSR[NumSvs]={0};		/* for delta range calcs */
static double PreviousDelta[NumSvs]={0};	/* for delta range calcs */

/* Functions

1) ComputePsr()			Hazen Gehue		Aug 4, 1998

*/

void ComputePsr(FILE *fpMEAS, RAWDATA *raw, int *NewEpoch)
{
int i;			/* loop index */
static int TimeAdjust=NO;	/* flag for 100 ms adjustment */
double TransmitTime;	/* signal left satellite */
static double ReceiverTime=0.0;	/* signal arrives at user */
double PseudoRange;	/* computed value in metres */
static int long RTtag;	/* inital TTag used for inital RT */
double ExtrapValue;	/* change in distance for PSR to get common time */
double Delta_Psr;	/* delta range (m/s) */

static int ReferenceChannel;	/* for debug purposes */
static int ReferenceSvID;

/* Psr=(Receive Time (RT) - Transmit Time (TT)) * C */


/* if a new epoch is set then increment the values by one second */
/* ------------------------------------------------------------- */
	if(*NewEpoch==YES && ReceiverTime!=0.0)
	{
		ReceiverTime+=1.0;
		RTtag+=1000;
		*NewEpoch=NO;
		fprintf(fpMEAS,"\n\nReceiver Time %.3lf\n",ReceiverTime);

/* get the channel number and svid of the RtTag reference */
/* ------------------------------------------------------ */
		ReferenceChannel=raw->channel;
		ReferenceSvID=raw->SvID;
	}

/* If a 100 ms jump has occured then ignore that measurement epoch */
/* ----------------------------------------------------------- */
	if(TimeAdjust==YES && *NewEpoch==NO)
		return;

/*
 * we must first set the recevier time (not the same as GPS time) to some
 * initalized value. The first estimation of receiver time can be
 * Transmit time of the first channel + 0.07 (propagation time)
 * RTtag (receiver time tag) = ttag of the channel
 * NOTE - data cannot contain a restart as this will result in a
 * reinitialization of the receiver time and RTTag
 */

/*
 * ******* NOTE ******
 * in the event of a restart (i.e. power cycle) this sequence of events
 * must be restarted
 */

/* for now, the first epoch time is indicated by the ReceiverTime==0.0 */
/* each new epoch then has the ReceiverTime and RTTag incremented by 1 sec. */
/* the receiver clock bias is then allowed to grow. */
/* --------------------------------------------------------- */
	if(ReceiverTime==0.0)	/* initiliazation stage */
	{
		ReceiverTime = ((double)raw->BitNumber/BPSData)
		    + ((double)raw->MsNumber/Ms)
		    + ((double)raw->ChipNumber/ChipCode/Ms)
		    + ((double)raw->CodePhase/65536.0/ChipCode/Ms) + 0.07;
		RTtag=raw->TimeTag;
		*NewEpoch=NO;
		TimeAdjust=NO;
		fprintf(fpMEAS,"\n\nReceiver Time %.3lf\n",ReceiverTime);
	}
/*
 * NOTE **  if the extrapolation time (raw->TimeTag-RTtag) has jumped
 * (ms adjustment) then you must restart the process.  This occurs as
 * the system calibrates itself and adjusts the clock to be closer to
 * GPStime for the PPS output. If PPS is disabled then this will not
 * occur. The Extraplolation value should be less than 20 ms.
 */
	if((raw->TimeTag-RTtag)>20.0)		/* ms adjustment has occured */
	{
		ReceiverTime=0.0;
		fprintf(fpMEAS,"\n\nTime Adjustment !! Recalculating Receiver Time.\n\n");
		TimeAdjust=YES;

/* Set all values to zero */
/* ---------------------- */
		for(i=0;i<NumSvs;i++)
			IntegratedCarrier[i]=0.0;

		return;
	}

/*
 * required data
 *	data bit number (BN)
 *	ms number (MSN)
 *	chip number (CN)
 *	code phase (CP)
 *	time tag (TTag)
 *	delta carrier (DC)
 *
 * Where: TT (sec) = (BN/50) + (MSN/1000) + (CN/1023/1000)+(CP/65536/1023/1000)
 *	  RT (sec) = T + (TTag/1000)
 *
 * Psr values must be interpolated to the one second boundary to make all
 * values valid at the same time. Also convert to metres.
 *
 * this is an instantaneous measurement
 *
 *	Psr(at TTag) = (RT-TT)*C
 */

	TransmitTime = ((double)raw->BitNumber/BPSData)
	    + ((double)raw->MsNumber/Ms)
	    + ((double)raw->ChipNumber/ChipCode/Ms)
	    + ((double)raw->CodePhase/65536.0/ChipCode/Ms);

/* receive times  must be aligned to measurement times       */
/* valid at channel time NOT reference time (i.e. channel 0) */

	PseudoRange = ((ReceiverTime + (raw->TimeTag-RTtag) / 1000.0) -
	    TransmitTime) * C;
	fprintf(fpMEAS,"%2d  raw %15.3lf  ", raw->SvID, PseudoRange);

/* extrapolated to a common ttag as defined by RTTAG (reference time) */
/* the extrapolation time is TimeTag(channel)-RTtag */

	ExtrapValue = ((raw->TimeTag-RTtag) / 1000.0) *
	    ((raw->DeltaCarrierPhase * L1) / (raw->AccumTime * 1.024));
	PseudoRange += ((raw->TimeTag-RTtag) / 1000.0) *
	    ((raw->DeltaCarrierPhase * L1) / (raw->AccumTime * 1.024));

/* to improve precision add in in the extrapolation due to the correlation */
/* interval intervals are either 2 ms (1) or 10 ms (5) */

	 if(raw->TrackLoopTime == 1)	/* 2 ms tracking loop time */
	 {
		PseudoRange -= (0.25 / 1023000.0) * C;
		PseudoRange += (0.001 * ((raw->DeltaCarrierPhase * L1) /
		    (raw->AccumTime * 1.024)));
	 }
	 else	/* 10 ms loop - valid at the half way point */
		PseudoRange += (0.005 * ((raw->DeltaCarrierPhase * L1) /
		    (raw->AccumTime * 1.024)));


/* compute the delta  range  (if valid delta phase)  */

	if(raw->AccumTime>0)
		Delta_Psr =- (raw->DeltaCarrierPhase * L1) /
		    (raw->AccumTime * 1.024);
	else
		Delta_Psr = raw->CarrierDoppler * .0777 * L1; /* m/s */

	fprintf(fpMEAS," ext %15.3lf   Extrap Time %ld   com time %15.3lf  ",
	    ExtrapValue, raw->TimeTag-RTtag, PseudoRange);

/* to get the accumulted carrier data the accum time must be > 0, */
/* then the sums are valid, otherwise the sums must be reset to 0 */
/* this could be used as an indication of a cycle slip (internal or */
/* signal blockage) */

	if(raw->AccumTime == 0)
		IntegratedCarrier[raw->SvID] = 0.0;
	else if(raw->AccumTime == 1000)	/* 1 second accumulation  */
		IntegratedCarrier[raw->SvID] += Delta_Psr / L1;

	fprintf(fpMEAS," Delta Carrier %.3lf Int Carrier %.3lf\n",
	    Delta_Psr / L1, IntegratedCarrier[raw->SvID]);

/* speparate files for each range based on the svid */

	SavePSR(raw->SvID, PseudoRange, ReceiverTime, raw->TimeTag-RTtag,
	    ReferenceChannel, ReferenceSvID); /* calc.psr */

}

void SavePSR(int svid, double psr, double ReceiverTime,
    double ExtrapolationTime, int ReferenceChannel, int ReferenceSvID)
{
char PSRfile[15];		/* ext = svid */
char ext[5];			/* file ext */
FILE *fpPSR;


	memset(PSRfile,'\0',sizeof(PSRfile));
	memset(ext,'\0',sizeof(ext));
	strncpy(PSRfile,"p_range.",8);
	snprintf(ext,5,"%03d", svid);
	strncat(PSRfile,ext,3);

	if((fpPSR=fopen(PSRfile,"a"))==NULL)
		return;

/* first time through just assign the value to the previous value */
/* -------------------------------------------------------------- */
	if(PreviousPSR[svid]==0.0)
	{
		/* time rch rid id ex time psr Dpsr ddpsr */
		fprintf(fpPSR,
		    "%10.3lf %3d %3d %3d %3.0lf %15.3lf %15.3lf %10.3lf\n",
		    ReceiverTime, ReferenceChannel, ReferenceSvID, svid,
		    ExtrapolationTime, psr, 0.0, 0.0);
		PreviousPSR[svid] = psr;
		PreviousDelta[svid] = 0.0;

		fclose(fpPSR);
		return;
	}
	if(PreviousDelta[svid]==0.0)
	{
		/* time rch rid id ex time psr Dpsr ddpsr */
		fprintf(fpPSR,
		    "%10.3lf %3d %3d %3d %3.0lf %15.3lf %15.3lf %10.3lf\n",
		    ReceiverTime, ReferenceChannel, ReferenceSvID, svid,
		    ExtrapolationTime, psr, PreviousPSR[svid] - psr, 0.0);

		PreviousDelta[svid] = PreviousPSR[svid] - psr;
		PreviousPSR[svid] = psr;
		fclose(fpPSR);
		return;
	}
	else
	{
		/* time rch rid id ex time psr Dpsr ddpsr */
		fprintf(fpPSR,
		    "%10.3lf %3d %3d %3d %3.0lf %15.3lf %15.3lf %10.3lf\n",
		    ReceiverTime, ReferenceChannel, ReferenceSvID, svid,
		    ExtrapolationTime, psr, PreviousPSR[svid] - psr,
		    PreviousDelta[svid] - (PreviousPSR[svid] - psr));

		PreviousDelta[svid]=PreviousPSR[svid]-psr;
		PreviousPSR[svid]=psr;
	}
	fclose(fpPSR);
}

void SaveRawData(int svid, char *buffer)
{
char RAWfile[15];		/* ext = svid */
char ext[5];			/* file ext */
FILE *fpRAW;


	memset(RAWfile,'\0',sizeof(RAWfile));
	memset(ext,'\0',sizeof(ext));

	strncpy(RAWfile,"svdata.",7);
	snprintf(ext,5,"%03d", svid);

	strncat(RAWfile,ext,3);


	if((fpRAW=fopen(RAWfile,"a"))==NULL)
		return;
	else
		fprintf(fpRAW,"%s",buffer);

	fclose(fpRAW);
}









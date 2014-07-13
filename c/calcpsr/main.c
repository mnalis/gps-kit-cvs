/* $CSK: main.c,v 1.19 2006/09/15 02:34:13 ckuethe Exp $ */
/* calcs Psr, decodes eph based on the raw data message 005 */
/* -------------------------------------------------------- */
#include <sys/types.h>
#include <sys/stat.h>
#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


/* local headers */
/* ------------- */
#include "defines.h"
#include "datstruc.h"
#include "protos.h"

/* global variable */
/* --------------- */
RAWDATA rwd;			/* message 005 data  - defined in defines.h */

double IntegratedCarrier[NumSvs];	/* integrated carrier phase for all Svs */

int main (int argc,char *argv[])
{
char DATAfile[15];		/* input data file */
char MEASfile[15];		/* output measurement data file */
char EPHfile[15];		/* output ephemeris data file */
char buffer[1000];		/* for scanning in of the data */
char basename[10];		/* file name no ext */
int NewEpoch=NO;	/* estimated GPS time from our receiver */
int i;                  /* loop index */

struct stat sb;
double FileSize;			/* size of raw_data file */
double completed=0.0;		/* amount of file completed */
double Percent;				/* % completed */
int handle;					/* size of raw_data file */
int count=0;				/* screen output */


FILE *fpDATA, *fpMEAS, *fpEPH;		/* associated file pointers */

/* erase all pseudo files for sv specific data */
/* ------------------------------------------- */
	system("/bin/rm -f p_range.* svdata.* *.eph *.msr");

	memset(basename,'\0',sizeof(basename));

/* if command line */
/* --------------- */
	if(argc==2)
		strncpy(basename,argv[1],8);
	else
	{
		memset(basename,'\0',sizeof(basename));
		printf("Please enter data file for processing (*.gps) -> ");
		scanf("%s",basename);
	}

/* set filenames and add ext */
/* ------------------------- */
	memset(DATAfile,'\0',sizeof(DATAfile));
	memset(MEASfile,'\0',sizeof(MEASfile));
	memset(EPHfile,'\0',sizeof(EPHfile));

	strncpy(MEASfile,basename,8);
	strncpy(DATAfile,basename,8);
	strncpy(EPHfile,basename,8);

	strlcat(DATAfile,".gps",15);		/* raw data input file */
	strlcat(MEASfile,".msr",15);     /* computed Psr and data file */
	strlcat(EPHfile,".eph",15);     /* computed Psr and data file */

/* blast through the file */
/* ---------------------- */
	if((fpDATA=fopen(DATAfile,"r"))==NULL)
	{
		perror("error opening data file");
		exit(1);
	}

	if((fpMEAS=fopen(MEASfile,"w"))==NULL)
	{
		perror("error opening measurement file");
		exit(1);
	}

	if((fpEPH=fopen(EPHfile,"w"))==NULL)
	{
		perror("error opening ephemeris file");
		exit(1);
	}

/* determine the size of the raw_data file */
/* --------------------------------------- */
	handle = fileno(fpDATA);
	stat(DATAfile, &sb);
	FileSize=sb.st_size;

/* initialize the summation data points for the accumulated carrier data */
/* --------------------------------------------------------------------- */
	for(i=0;i<NumSvs;i++)
		IntegratedCarrier[i]=0.0;

	memset(buffer,'\0',sizeof(buffer));
	while(fgets(buffer,sizeof(buffer),fpDATA)!=NULL)
	{
		count++;     /* count each line for % completed computation output */

/* compute percentage of file processed */
/* ------------------------------------ */
		completed+=(double) strlen(buffer);
		Percent=((completed/FileSize)*100.0);
		if(count%1000==0)
		{
			printf("Percent completed %.1lf  \n",Percent);
			count=0;
		}

/* Decode EPh logged to file */
/* ------------------------- */
	if(strncasecmp(buffer,"EPHEMERIS SVID:",15)==MATCH)
		CalcEphParameters(&buffer[17],fpEPH);				/* calceph.c */



/* the data comes in several strings - each epoch is started with the string */
/* Week:972  TOW:23013094  EstGPSTime:230130943 ms  SVCnt:6  Clock Drift:74617 Hz  Clock Bias:7228507 ns */
/* This is a quick fix to determine the start of the next epoch */
/* ------------------------------------------------------------ */
		if(strncasecmp(buffer,"WEEK",4)==MATCH)
			NewEpoch=YES;

		if(buffer[0]=='5' && buffer[1]==',')
		{
			if(sscanf(buffer,"%15d, %15d, %15d, %2x, %15ld, %15d, %15d, %15ld, %15ld, %15ld, %15ld, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d, %15d",
				&rwd.ID,&rwd.channel,&rwd.SvID,&rwd.status,		/* int  */
				&rwd.BitNumber,                                 /* unsigned long */
				&rwd.MsNumber,&rwd.ChipNumber,					/* int */
				&rwd.CodePhase,&rwd.CarrierDoppler,&rwd.TimeTag,/* long */
				&rwd.DeltaCarrierPhase,                         /* long */
				&rwd.SearchCount,                              /* int */
				&rwd.CNo[0],&rwd.CNo[1],&rwd.CNo[2],&rwd.CNo[3],&rwd.CNo[4], /* int */
				&rwd.CNo[5],&rwd.CNo[6],&rwd.CNo[7],&rwd.CNo[8],&rwd.CNo[9], /*int */
				&rwd.BadPrCount,&rwd.BadDrCount,&rwd.AccumTime,&rwd.TrackLoopTime)!=26)	/* int */
			{
				memset(buffer,'\0',sizeof(buffer));
				continue;
			}
			else if(rwd.status == PHASELOCK)
			{

/* save the raw data for analysis */
/* ------------------------------ */
				SaveRawData(rwd.SvID,buffer);	/* calcpsr.c */
				ComputePsr(fpMEAS,&rwd,&NewEpoch);		/* calcpsr.c */
			}

		}
		memset(buffer,'\0',sizeof(buffer));
	}
	fclose(fpDATA);
	fclose(fpMEAS);
	fclose(fpEPH);

	return 0;
}





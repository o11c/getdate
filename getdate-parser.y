%name-prefix "getdate_yy"

%{
/*
**  Originally written by Steven M. Bellovin <smb@research.att.com> while
**  at the University of North Carolina at Chapel Hill.  Later tweaked by
**  a couple of people on Usenet.  Completely overhauled by Rich $alz
**  <rsalz@bbn.com> and Jim Berets <jberets@bbn.com> in August, 1990;
**
**  This grammar has 10 shift/reduce conflicts.
**
**  This code is in the public domain and has no copyright.
*/
/* SUPPRESS 287 on yaccpar_sccsid *//* Unused static variable */
/* SUPPRESS 288 on yyerrlab *//* Label unused */

#ifdef HAVE_CONFIG_H
#if defined (emacs) || defined (CONFIG_BROKETS)
#include <config.h>
#else
#include "config.h"
#endif
#endif

/* Since the code of getdate.y is not included in the Emacs executable
   itself, there is no need to #define static in this file.  Even if
   the code were included in the Emacs executable, it probably
   wouldn't do any harm to #undef it here; this will only cause
   problems if we try to write to a static variable, which I don't
   think this code needs to do.  */
#ifdef emacs
#undef static
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* The code at the top of get_date which figures out the offset of the
   current time zone checks various CPP symbols to see if special
   tricks are need, but defaults to using the gettimeofday system call.
   Include <sys/time.h> if that will be used.  */

#if	defined(vms)
# include <types.h>
#else /* defined(vms) */
# include <sys/types.h>
#endif	/* !defined(vms) */
# include "xtime.h"

#if defined (STDC_HEADERS) || defined (USG)
#include <string.h>
#endif

/* Some old versions of bison generate parsers that use bcopy.
   That loses on systems that don't provide the function, so we have
   to redefine it here.  */
#if !defined (HAVE_BCOPY) && defined (HAVE_MEMCPY) && !defined (bcopy)
#define bcopy(from, to, len) memcpy ((to), (from), (len))
#endif

#if defined (STDC_HEADERS)
#include <stdlib.h>
#endif

/* NOTES on rebuilding getdate.c (particularly for inclusion in CVS
   releases):

   We don't want to mess with all the portability hassles of alloca.
   In particular, most (all?) versions of bison will use alloca in
   their parser.  If bison works on your system (e.g. it should work
   with gcc), then go ahead and use it, but the more general solution
   is to use byacc instead of bison, which should generate a portable
   parser.  I played with adding "#define alloca dont_use_alloca", to
   give an error if the parser generator uses alloca (and thus detect
   unportable getdate.c's), but that seems to cause as many problems
   as it solves.  */

extern struct tm	*gmtime();
extern struct tm	*localtime();

static int yyparse ();
static int yyerror ();

#define EPOCH		1970
#define SECSPERDAY	(24L * 60L * 60L)
%}

%code requires {
#include <sys/types.h>

/*
**  Daylight-savings mode:  on, off, or not yet known.
*/
typedef enum _DSTMODE {
    DSTon, DSToff, DSTmaybe
} DSTMODE;

/*
**  Meridian:  am, pm, or 24-hour style.
*/
typedef enum _MERIDIAN {
    MERam, MERpm, MER24
} MERIDIAN;


/*
**  Global variables.  We could get rid of most of these by using a good
**  union as the yacc stack.  (This routine was originally written before
**  yacc had the %union construct.)  Maybe someday; right now we only use
**  the %union very rarely.
*/
char	*yyInput;
DSTMODE	yyDSTmode;
time_t	yyDayOrdinal;
time_t	yyDayNumber;
int	yyHaveDate;
int	yyHaveDay;
int	yyHaveRel;
int	yyHaveTime;
int	yyHaveZone;
time_t	yyTimezone;
time_t	yyDay;
time_t	yyHour;
time_t	yyMinutes;
time_t	yyMonth;
time_t	yySeconds;
time_t	yyYear;
MERIDIAN	yyMeridian;
time_t	yyRelMonth;
time_t	yyRelSeconds;


int getdate_yylex ();
}

%expect 10

%union {
    time_t		Number;
    enum _MERIDIAN	Meridian;
}

%token	tAGO tDAY tDAYZONE tID tMERIDIAN tMINUTE_UNIT tMONTH tMONTH_UNIT
%token	tSEC_UNIT tSNUMBER tUNUMBER tZONE tDST

%type	<Number>	tDAY tDAYZONE tMINUTE_UNIT tMONTH tMONTH_UNIT
%type	<Number>	tSEC_UNIT tSNUMBER tUNUMBER tZONE
%type	<Meridian>	tMERIDIAN o_merid

%%

spec	: /* NULL */
	| spec item
	;

item	: time {
	    yyHaveTime++;
	}
	| zone {
	    yyHaveZone++;
	}
	| date {
	    yyHaveDate++;
	}
	| day {
	    yyHaveDay++;
	}
	| rel {
	    yyHaveRel++;
	}
	| cvsstamp {
	    yyHaveTime++;
	    yyHaveDate++;
	    yyHaveZone++;
	}
	| number
	;

cvsstamp: tUNUMBER '.' tUNUMBER '.' tUNUMBER '.' tUNUMBER '.' tUNUMBER '.' tUNUMBER {
	    yyYear = $1;
	    if (yyYear < 100) yyYear += 1900;
	    yyMonth = $3;
	    yyDay = $5;
	    yyHour = $7;
	    yyMinutes = $9;
	    yySeconds = $11;
	    yyDSTmode = DSToff;
	    yyTimezone = 0;
	}
	;

time	: tUNUMBER tMERIDIAN {
	    yyHour = $1;
	    yyMinutes = 0;
	    yySeconds = 0;
	    yyMeridian = $2;
	}
	| tUNUMBER ':' tUNUMBER o_merid {
	    yyHour = $1;
	    yyMinutes = $3;
	    yySeconds = 0;
	    yyMeridian = $4;
	}
	| tUNUMBER ':' tUNUMBER tSNUMBER {
	    yyHour = $1;
	    yyMinutes = $3;
	    yyMeridian = MER24;
	    yyDSTmode = DSToff;
	    yyTimezone = - ($4 % 100 + ($4 / 100) * 60);
	}
	| tUNUMBER ':' tUNUMBER ':' tUNUMBER o_merid {
	    yyHour = $1;
	    yyMinutes = $3;
	    yySeconds = $5;
	    yyMeridian = $6;
	}
	| tUNUMBER ':' tUNUMBER ':' tUNUMBER tSNUMBER {
	    yyHour = $1;
	    yyMinutes = $3;
	    yySeconds = $5;
	    yyMeridian = MER24;
	    yyDSTmode = DSToff;
	    yyTimezone = - ($6 % 100 + ($6 / 100) * 60);
	}
	;

zone	: tZONE {
	    yyTimezone = $1;
	    yyDSTmode = DSToff;
	}
	| tDAYZONE {
	    yyTimezone = $1;
	    yyDSTmode = DSTon;
	}
	|
	  tZONE tDST {
	    yyTimezone = $1;
	    yyDSTmode = DSTon;
	}
	;

day	: tDAY {
	    yyDayOrdinal = 1;
	    yyDayNumber = $1;
	}
	| tDAY ',' {
	    yyDayOrdinal = 1;
	    yyDayNumber = $1;
	}
	| tUNUMBER tDAY {
	    yyDayOrdinal = $1;
	    yyDayNumber = $2;
	}
	;

date	: tUNUMBER '/' tUNUMBER {
	    yyMonth = $1;
	    yyDay = $3;
	}
	| tUNUMBER '/' tUNUMBER '/' tUNUMBER {
	    if ($1 >= 100) {
		yyYear = $1;
		yyMonth = $3;
		yyDay = $5;
	    } else {
		yyMonth = $1;
		yyDay = $3;
		yyYear = $5;
	    }
	}
	| tUNUMBER tSNUMBER tSNUMBER {
	    /* ISO 8601 format.  yyyy-mm-dd.  */
	    yyYear = $1;
	    yyMonth = -$2;
	    yyDay = -$3;
	}
	| tUNUMBER '.' tUNUMBER '.' tUNUMBER {
	    yyYear = $1;
	    yyMonth = $3;
	    yyDay = $5;
	}
	| tUNUMBER tMONTH tSNUMBER {
	    /* e.g. 17-JUN-1992.  */
	    yyDay = $1;
	    yyMonth = $2;
	    yyYear = -$3;
	}
	| tMONTH tUNUMBER {
	    yyMonth = $1;
	    yyDay = $2;
	}
	| tMONTH tUNUMBER ',' tUNUMBER {
	    yyMonth = $1;
	    yyDay = $2;
	    yyYear = $4;
	}
	| tUNUMBER tMONTH {
	    yyMonth = $2;
	    yyDay = $1;
	}
	| tUNUMBER tMONTH tUNUMBER {
	    yyMonth = $2;
	    yyDay = $1;
	    yyYear = $3;
	}
	;

rel	: relunit tAGO {
	    yyRelSeconds = -yyRelSeconds;
	    yyRelMonth = -yyRelMonth;
	}
	| relunit
	;

relunit	: tUNUMBER tMINUTE_UNIT {
	    yyRelSeconds += $1 * $2 * 60L;
	}
	| tSNUMBER tMINUTE_UNIT {
	    yyRelSeconds += $1 * $2 * 60L;
	}
	| tMINUTE_UNIT {
	    yyRelSeconds += $1 * 60L;
	}
	| tSNUMBER tSEC_UNIT {
	    yyRelSeconds += $1;
	}
	| tUNUMBER tSEC_UNIT {
	    yyRelSeconds += $1;
	}
	| tSEC_UNIT {
	    yyRelSeconds++;
	}
	| tSNUMBER tMONTH_UNIT {
	    yyRelMonth += $1 * $2;
	}
	| tUNUMBER tMONTH_UNIT {
	    yyRelMonth += $1 * $2;
	}
	| tMONTH_UNIT {
	    yyRelMonth += $1;
	}
	;

number	: tUNUMBER {
	    if (yyHaveTime && yyHaveDate && !yyHaveRel)
		yyYear = $1;
	    else {
		if($1>10000) {
		    yyHaveDate++;
		    yyDay= ($1)%100;
		    yyMonth= ($1/100)%100;
		    yyYear = $1/10000;
		}
		else {
		    yyHaveTime++;
		    if ($1 < 100) {
			yyHour = $1;
			yyMinutes = 0;
		    }
		    else {
		    	yyHour = $1 / 100;
		    	yyMinutes = $1 % 100;
		    }
		    yySeconds = 0;
		    yyMeridian = MER24;
	        }
	    }
	}
	;

o_merid	: /* NULL */ {
	    $$ = MER24;
	}
	| tMERIDIAN {
	    $$ = $1;
	}
	;

%%


/* ARGSUSED */
static int
yyerror(s)
    char	*s;
{
  (void)s;
  return 0;
}


static time_t
ToSeconds(Hours, Minutes, Seconds, Meridian)
    time_t	Hours;
    time_t	Minutes;
    time_t	Seconds;
    MERIDIAN	Meridian;
{
    if (Minutes < 0 || Minutes > 59 || Seconds < 0 || Seconds > 59)
	return -1;
    switch (Meridian) {
    case MER24:
	if (Hours < 0 || Hours > 23)
	    return -1;
	return (Hours * 60L + Minutes) * 60L + Seconds;
    case MERam:
	if (Hours < 1 || Hours > 12)
	    return -1;
	if (Hours == 12)
	    Hours = 0;
	return (Hours * 60L + Minutes) * 60L + Seconds;
    case MERpm:
	if (Hours < 1 || Hours > 12)
	    return -1;
	if (Hours == 12)
	    Hours = 0;
	return ((Hours + 12) * 60L + Minutes) * 60L + Seconds;
    default:
	abort ();
    }
    /* NOTREACHED */
}


/* Year is either
   * A negative number, which means to use its absolute value (why?)
   * A number from 0 to 99, which means a year from 1900 to 1999, or
   * The actual year (>=100).  */
static time_t
Convert(Month, Day, Year, Hours, Minutes, Seconds, Meridian, DSTmode)
    time_t	Month;
    time_t	Day;
    time_t	Year;
    time_t	Hours;
    time_t	Minutes;
    time_t	Seconds;
    MERIDIAN	Meridian;
    DSTMODE	DSTmode;
{
    static int DaysInMonth[12] = {
	31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    };
    time_t	tod;
    time_t	Julian;
    int		i;

    if (Year < 0)
	Year = -Year;
    if (Year < 69)
	Year += 2000;
    else if (Year < 100)
	Year += 1900;
    DaysInMonth[1] = Year % 4 == 0 && (Year % 100 != 0 || Year % 400 == 0)
		    ? 29 : 28;
    /* Checking for 2038 bogusly assumes that time_t is 32 bits.  But
       I'm too lazy to try to check for time_t overflow in another way.  */
    if (Year < EPOCH || Year > 2038
     || Month < 1 || Month > 12
     /* Lint fluff:  "conversion from long may lose accuracy" */
     || Day < 1 || Day > DaysInMonth[(int)--Month])
	/* FIXME:
	 * It would be nice to set a global error string here.
	 * "February 30 is not a valid date" is much more informative than
	 * "Can't parse date/time: 100 months" when the user input was
	 * "100 months" and addition resolved that to February 30, for
	 * example.  See rcs2-7 in src/sanity.sh for more. */
	return -1;

    for (Julian = Day - 1, i = 0; i < Month; i++)
	Julian += DaysInMonth[i];
    for (i = EPOCH; i < Year; i++)
	Julian += 365 + (i % 4 == 0);
    Julian *= SECSPERDAY;
    Julian += yyTimezone * 60L;
    if ((tod = ToSeconds(Hours, Minutes, Seconds, Meridian)) < 0)
	return -1;
    Julian += tod;
    if (DSTmode == DSTon
     || (DSTmode == DSTmaybe && localtime(&Julian)->tm_isdst))
	Julian -= 60 * 60;
    return Julian;
}


static time_t
DSTcorrect(Start, Future)
    time_t	Start;
    time_t	Future;
{
    time_t	StartDay;
    time_t	FutureDay;

    StartDay = (localtime(&Start)->tm_hour + 1) % 24;
    FutureDay = (localtime(&Future)->tm_hour + 1) % 24;
    return (Future - Start) + (StartDay - FutureDay) * 60L * 60L;
}


static time_t
RelativeDate(Start, DayOrdinal, DayNumber)
    time_t	Start;
    time_t	DayOrdinal;
    time_t	DayNumber;
{
    struct tm	*tm;
    time_t	now;

    now = Start;
    tm = localtime(&now);
    now += SECSPERDAY * ((DayNumber - tm->tm_wday + 7) % 7);
    now += 7 * SECSPERDAY * (DayOrdinal <= 0 ? DayOrdinal : DayOrdinal - 1);
    return DSTcorrect(Start, now);
}


static time_t
RelativeMonth(Start, RelMonth)
    time_t	Start;
    time_t	RelMonth;
{
    struct tm	*tm;
    time_t	Month;
    time_t	Year;

    if (RelMonth == 0)
	return 0;
    tm = localtime(&Start);
    Month = 12 * (tm->tm_year + 1900) + tm->tm_mon + RelMonth;
    Year = Month / 12;
    Month = Month % 12 + 1;
    return DSTcorrect(Start,
	    Convert(Month, (time_t)tm->tm_mday, Year,
		(time_t)tm->tm_hour, (time_t)tm->tm_min, (time_t)tm->tm_sec,
		MER24, DSTmaybe));
}


#define TM_YEAR_ORIGIN 1900

/* Yield A - B, measured in seconds.  */
static long
difftm (a, b)
     struct tm *a, *b;
{
  int ay = a->tm_year + (TM_YEAR_ORIGIN - 1);
  int by = b->tm_year + (TM_YEAR_ORIGIN - 1);
  int days = (
	      /* difference in day of year */
	      a->tm_yday - b->tm_yday
	      /* + intervening leap days */
	      +  ((ay >> 2) - (by >> 2))
	      -  (ay/100 - by/100)
	      +  ((ay/100 >> 2) - (by/100 >> 2))
	      /* + difference in years * 365 */
	      +  (long)(ay-by) * 365
	      );
  return (60*(60*(24*days + (a->tm_hour - b->tm_hour))
	      + (a->tm_min - b->tm_min))
	  + (a->tm_sec - b->tm_sec));
}

time_t
get_date(p, now)
    char		*p;
    struct timeb	*now;
{
    struct tm		*tm, gmt;
    struct timeb	ftz;
    time_t		Start;
    time_t		tod;
    time_t nowtime;

    yyInput = p;
    if (now == NULL) {
	struct tm *gmt_ptr;

        now = &ftz;
	(void)time (&nowtime);

	gmt_ptr = gmtime (&nowtime);
	if (gmt_ptr != NULL)
	{
	    /* Make a copy, in case localtime modifies *tm (I think
	       that comment now applies to *gmt_ptr, but I am too
	       lazy to dig into how gmtime and locatime allocate the
	       structures they return pointers to).  */
	    gmt = *gmt_ptr;
	}

	if (! (tm = localtime (&nowtime)))
	    return -1;

	if (gmt_ptr != NULL)
	    ftz.timezone = difftm (&gmt, tm) / 60;
	else
	    /* We are on a system like VMS, where the system clock is
	       in local time and the system has no concept of timezones.
	       Hopefully we can fake this out (for the case in which the
	       user specifies no timezone) by just saying the timezone
	       is zero.  */
	    ftz.timezone = 0;

	if(tm->tm_isdst)
	    ftz.timezone += 60;
    }
    else
    {
	nowtime = now->time;
    }

    tm = localtime(&nowtime);
    yyYear = tm->tm_year + 1900;
    yyMonth = tm->tm_mon + 1;
    yyDay = tm->tm_mday;
    yyTimezone = now->timezone;
    yyDSTmode = DSTmaybe;
    yyHour = 0;
    yyMinutes = 0;
    yySeconds = 0;
    yyMeridian = MER24;
    yyRelSeconds = 0;
    yyRelMonth = 0;
    yyHaveDate = 0;
    yyHaveDay = 0;
    yyHaveRel = 0;
    yyHaveTime = 0;
    yyHaveZone = 0;

    if (yyparse()
     || yyHaveTime > 1 || yyHaveZone > 1 || yyHaveDate > 1 || yyHaveDay > 1)
	return -1;

    if (yyHaveDate || yyHaveTime || yyHaveDay) {
	Start = Convert(yyMonth, yyDay, yyYear, yyHour, yyMinutes, yySeconds,
		    yyMeridian, yyDSTmode);
	if (Start < 0)
	    return -1;
    }
    else {
	Start = nowtime;
	if (!yyHaveRel)
	    Start -= ((tm->tm_hour * 60L + tm->tm_min) * 60L) + tm->tm_sec;
    }

    Start += yyRelSeconds;
    Start += RelativeMonth(Start, yyRelMonth);

    if (yyHaveDay && !yyHaveDate) {
	tod = RelativeDate(Start, yyDayOrdinal, yyDayNumber);
	Start += tod;
    }

    /* Have to do *something* with a legitimate -1 so it's distinguishable
     * from the error return value.  (Alternately could set errno on error.) */
    return Start == -1 ? 0 : Start;
}


#if	defined(TEST)

/* ARGSUSED */
int
main(ac, av)
    int		ac;
    char	*av[];
{
    char	buff[128];
    time_t	d;

    (void)printf("Enter date, or blank line to exit.\n\t> ");
    (void)fflush(stdout);
    while (gets(buff) && buff[0]) {
	d = get_date(buff, (struct timeb *)NULL);
	if (d == -1)
	    (void)printf("Bad format - couldn't convert.\n");
	else
	    (void)printf("%s", ctime(&d));
	(void)printf("\t> ");
	(void)fflush(stdout);
    }
    exit(0);
    /* NOTREACHED */
}
#endif	/* defined(TEST) */

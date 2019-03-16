/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
// $Header: d:/sh/RCS/sql.cpp 2.0 93/07/14 09:45:25 Steve Exp $

extern "C" {
short _Far16 _Pascal  sqlestar_api (void);
short _Far16 _Pascal  sqlestrd_api (char *,	/* database */
		      char *,	  /* spare, password */
		      unsigned char,	   /* use */
		      struct SQLCA *);	   /* SQLCA */
short _Far16 _Pascal sqlacall(unsigned short,
			       unsigned short,
			       unsigned short,
			       unsigned short,
			       void *);
short _Far16 _Pascal sqlastop(void *);
short _Far16 _Pascal sqlastrt(void *,
			       void *,
			       struct SQLCA *);
short _Far16 _Pascal sqlausda(unsigned short,
			       struct Sqlda *,
			       void *);
}

#define   SQLCODE	 sqlca->sqlcode
#define   SQLWARN0	 sqlca->sqlwarn[0]
#define   SQLWARN1	 sqlca->sqlwarn[1]
#define   SQLWARN2	 sqlca->sqlwarn[2]
#define   SQLWARN3	 sqlca->sqlwarn[3]
#define   SQLWARN4	 sqlca->sqlwarn[4]
#define   SQLWARN5	 sqlca->sqlwarn[5]
#define   SQLWARN6	 sqlca->sqlwarn[6]
#define   SQLWARN7	 sqlca->sqlwarn[7]
#define   SQLWARN8	 sqlca->sqlwarn[8]
#define   SQLWARN9	 sqlca->sqlwarn[9]
#define   SQLWARNA	 sqlca->sqlwarn[10]

#pragma pack(1)
struct SQLCA
{
   unsigned char  sqlcaid[8];		/* Eyecatcher = 'SQLCA   ' */
   long 	  sqlcabc;		/* SQLCA size in bytes = 136 */
   long 	  sqlcode;		/* SQL return code */
   short	  sqlerrml;		/* Length for SQLERRMC */
   unsigned char  sqlerrmc[70]; 	/* Error message tokens */
   unsigned char  sqlerrp[8];		/* Diagnostic information */
   long 	  sqlerrd[6];		/* Diagnostic information */
   unsigned char  sqlwarn[11];		/* Warning flags */
   unsigned char  sqlstate[5];		/* State corresponding to SQLCODE */
};
#pragma pack()

static SQLCA sqlca;

#include <stdarg.h>
#include <stdio.h>
#include <string.h>


class DATABASE
  {
   static int started;
  public:
   DATABASE( char * dbname, unsigned char dbuse, SQLCA* sqlca );
   int isstarted();
   long COMMIT( SQLCA* sqlca, char* pid  );
   long ROLLBACK( SQLCA* sqlca, char* pid  );
  };

int DATABASE::started;

DATABASE::DATABASE( char * dbname, unsigned char use, SQLCA* sqlca  )
  {
   if( !started )
     {
      SQLCA inisqlca;
      sqlestar_api();
      use &= 0xdf;
      if( use != 'X' && use != 'S' ) return;
      sqlestrd_api( dbname,"",'S', &inisqlca );
      started=( inisqlca.sqlcode  ) ? 0 : 1;
     }
  }
long DATABASE::COMMIT( SQLCA* sqlca , char* pid )
  {
   sqlastrt( pid,0L,sqlca);
   sqlacall((unsigned short)21,0,0,0,0L);
   sqlastop(0L);
   return SQLCODE;
  }
long DATABASE::ROLLBACK( SQLCA* sqlca, char* pid  )
  {
   sqlastrt( pid,0L,sqlca);
   sqlacall((unsigned short)28,0,0,0,0L);
   sqlastop(0L);
   return SQLCODE;
  }

#pragma pack( 1 )
struct SQLVAR
  {
   short	  sqltype;	     /* Variable data type */
   short	  sqllen;	     /* Variable data length */
   void  * _Seg16  sqldata;	      /* Pointer to variable data value */
   short * _Seg16  sqlind;	     /* Pointer to Null indicator */
   struct sqlname		     /* Variable Name */
     {
      short	     length;	     /* Name length [1..30] */
      unsigned char  data[30];	     /* Variable or Column name */
     }	sqlname;
  };

struct Sqlda
  {
   char  sqldaid[8];			/* Eye catcher = 'SQLDA   ' */
   long 	  sqldabc;		/* SQLDA size in bytes = 16+44*SQLN */
   short	  sqln; 		/* Number of SQLVAR elements */
   short	  sqld; 		/* # of used SQLVAR elements */
   SQLVAR sqlvar[1];
  };

#pragma pack( )

class SQLDA
  {
   static short nosqldas;	      // counter used to name sqlda's
   short sqlid; 		      // number for this sqlda
   Sqlda *ada;			      // actual sqlda
  public:
   SQLDA( char *t,short noargs )
     {
      if( ! noargs )
	{
	 ada=(Sqlda *)0;
	 sqlid=0;
	}
      else
	{
	 ada=(Sqlda*) new char[ sizeof(Sqlda) + (noargs-1)*sizeof(SQLVAR) ];
	 sqlid=(ada==0) ? ( short )0 : nosqldas++;
	 SQLCA ca;
	 strncpy( ada->sqldaid, "SQLDA   ", 8 );
	 ada->sqldabc=sizeof( Sqlda )+(noargs-1)*sizeof( SQLVAR );
	 ada->sqln=ada->sqld=noargs;
	 sqlastrt( t, 0, &ca );
	 sqlausda( sqlid, ada, ( void* )0 );	     // register sqlda
	 sqlastop( 0 );
	}
      }
   ~SQLDA(){ delete [] ada;}
   void setv( int i, short tp, short ln, void *da, short *ind )
     {
      SQLVAR *v=( SQLVAR* )&ada->sqlvar;
      v[i].sqltype=tp;
      v[i].sqllen=ln;
      v[i].sqldata=da;
      v[i].sqlind=ind;
     }
   inline short id(){ return sqlid; }
   SQLVAR* var(  ){return ( SQLVAR* )&ada->sqlvar;}
  };

short SQLDA::nosqldas=1;

class CURSOR
  {
   SQLDA outda;
   SQLDA inda;
   SQLCA *ca;
   unsigned char *top;
   short stmntno;
  public:
   CURSOR( SQLCA* c,unsigned char * t,short sno, short nooargs,
	   short noinargs, ...);

   long close();
   long fetch();
   long open();
   SQLVAR* invars(  );
   SQLVAR* outvars(  );
  };

   SQLVAR* CURSOR::invars(  ){ return inda.var(); }
   SQLVAR* CURSOR::outvars( ){ return outda.var();}

CURSOR::CURSOR( SQLCA* c,unsigned char * t,short sno, short nooargs,
		short noinargs, ...):
		ca(c), top(t), stmntno( sno ),
		outda( (char *) t, nooargs ), inda( (char *) t, noinargs )
  {
   int i;
   va_list list;
   va_start( list, noinargs );
   SQLVAR* v=( nooargs ) ? outda.var() : 0;
   for( i=0; i<nooargs; i++, v++ )
     {
      v->sqltype=va_arg( list, short );
      v->sqllen=va_arg( list, short );
      v->sqldata=va_arg( list, void * );
      v->sqlind=( short * )va_arg( list, void * );
     }
   v=( noinargs ) ? inda.var() : 0;
   for( i=0; i<noinargs; i++ , v++)
     {
      v->sqltype=va_arg( list, short );
      v->sqllen=va_arg( list, short );
      v->sqldata=va_arg( list, void * );
      v->sqlind=( short * )va_arg( list, void * );
     }
   va_end( list );
  }

long CURSOR::close()
     {
      sqlastrt(top,0L,ca);
      sqlacall(20, stmntno, 0, 0, 0 );
      sqlastop(0L);
      return ca->sqlcode;
     }
long CURSOR::fetch()
     {
      sqlastrt(top,0L,ca);
      sqlacall(25, stmntno, 0, inda.id(), 0 );
      sqlastop(0L);
      return ca->sqlcode;
     }
long CURSOR::open()
     {
      sqlastrt(top,0L,ca);
      sqlacall(26, stmntno, outda.id(), 0, 0 );
      sqlastop(0L);
      return ca->sqlcode;
     }

class QUERY
  {
   SQLDA outda;
   SQLDA inda;
   SQLCA *ca;
   unsigned char *top;
   short stmntno;
   unsigned short action;
  public:
   QUERY::QUERY( SQLCA* c, unsigned char * t, short sno, unsigned short act,
		 short nooargs, short noinargs,... );
   long exec();
   SQLVAR * invars(){return inda.var();}
   SQLVAR * outvars(){return outda.var();}
  };

QUERY::QUERY( SQLCA* c, unsigned char * t, short sno, unsigned short act,
	      short nooargs, short noinargs,... ):
	      ca(c), top(t), stmntno( sno ), action( act ),
	      outda( (char *) t, nooargs ), inda( (char *) t, noinargs )
  {
   int i;
   va_list list;
   va_start( list, noinargs );
   SQLVAR* v=( nooargs ) ? outda.var() : 0;
   for( i=0; i<nooargs; i++, v++ )
     {
      v->sqltype=va_arg( list, short );
      v->sqllen=va_arg( list, short );
      v->sqldata=va_arg( list, void * );
      v->sqlind=( short * )va_arg( list, void * );
     }
   v=( noinargs ) ? inda.var() : 0;
   for( i=0; i<noinargs; i++ , v++)
     {
      v->sqltype=va_arg( list, short );
      v->sqllen=va_arg( list, short );
      v->sqldata=va_arg( list, void * );
      v->sqlind=( short * )va_arg( list, void * );
     }
   va_end( list );
  }

long QUERY::exec()
  {
   sqlastrt(top, 0L, ca);
   sqlacall(action, stmntno, outda.id(), inda.id(), 0 );
   sqlastop(0L);
   return ca->sqlcode;
  }


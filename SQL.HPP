/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
// $Header: d:/sh/RCS/sql.hpp 2.0 93/07/14 09:42:53 Steve Exp $

#ifndef __SQL_HPP__
#define __SQL_HPP__

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

class DATABASE
  {
   static int started;
  public:
   DATABASE( char * dbname, unsigned char db_usage, SQLCA* sqlca);
   int isstarted();
   long COMMIT( SQLCA* sqlca, char* pid  );
   long ROLLBACK( SQLCA* sqlca, char* pid  );
  };


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
   SQLDA( char *t,short noargs );
   ~SQLDA(){ delete [] ada; }
   void setv( int i, short tp, short ln, void *da, short *ind );
   inline short id(){ return sqlid; }
   SQLVAR* var(  ){return ( SQLVAR* )&ada->sqlvar;}
  };


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


class QUERY
  {
   SQLDA outda;
   SQLDA inda;
   SQLCA *ca;
   unsigned char *top;
   short stmntno;
   unsigned short action;
  public:
   QUERY( SQLCA* c, unsigned char * t, short sno, unsigned short act,
		 short nooargs, short noinargs,... );
   long exec();
   SQLVAR * invars(){return inda.var();}
   SQLVAR * outvars(){return outda.var();}
  };

#endif

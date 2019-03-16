/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
/* $Header: h:/ubin/RCS/mksql.cmd 2.0 93/07/14 10:08:09 Steve Exp $ */
/* I will clean this up -- some day! For now, it works. */

'@echo off'
upper='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
lower='abcdefghijklmnopqrstuvwxyz'
parse upper arg a b c d
if c='' | d<>'' then do
  say 'Builds stuff for an ".SPP" file.'
  say ''
  say 'Arguments are: Database Table Pointer_Symbol'
  exit
end
do j=1 to queued()
  pull g
end
c=translate( c, lower, upper )
n=translate( b, lower, upper )
'call describe ' a b '| rxqueue '
j=0
s=  '         SELECT'
do i=1 to queued()
pull a
if substr(a, 1, 8)='--------' then
  do
   found=1
   iterate
  end
if found='FOUND' then iterate
if word( a,2 )='RECORD(S)' then  leave
if word( a,1 )='' then iterate
j=j+1
aa=a
a= translate(a, lower, upper )
select
  when	word(a,2 )= 'timestmp' then do
      descb.j='char '
      desce.j=word( a,1 )
      desc.j='[27]'
      end
  when word( a, 2 )='date' then do
      descb.j='char '
      desce.j=word( a,1 )
      desc.j='[12]'
      end

  when word( a, 2 )='char' then do
      descb.j='char '
      desce.j=word( a,1 )
      if word( a,3 )=1 then  desc.j=''
      else
	do
	  desc.j='['||word( a,3 )||']'
	end
      end

  when word( a, 2 )='time' then do
      descb.j='char '
      desce.j=word( a,1 )
      desc.j='[10]'
      end

  when word( a, 2 )='longvar' then do
      descb.j='char '
      desce.j=word( a,1 )
      desc.j='[32700]'
      end

  when	word(a,2 )= 'varchar' | word(a,2)='char' then do
      descb.j='char '
      desce.j=word( a,1 )
      desc.j='[' || word(a,3)+1 || ']'
      end
  when	word(a,2 )= 'decimal' then do
      descb.j='double '
      desce.j=word(a,1)
      desc.j=''
      end

  when	word(a,2 )= 'float' then do
      descb.j='double '
      desce.j=word(a,1)
      desc.j=''
      end

  when	word(a,2 )= 'integer' then do
      descb.j='long '
      desce.j=word(a,1)
      desc.j=''
      end
  when	word(a,2 )= 'smallint' then  do
      descb.j='short '
      desce.j=word(a,1)
      desc.j=''
      end
  otherwise say 'error in table '
  end
assign.j=n ||'_'|| word( a, 1 ) ||'='|| c || '.' || word( a, 1 )||';'
assign.j= c || '.' || word( a, 1 )||';'

fetch.j=  word( a,1 )
sel.j=word( aa,1 )
if word( a,5 )='y' then ni.j=fetch.j || '_ni'
end

g=translate( substr( n, 1, 1 ), upper,lower )||substr( n,2 )
say 'class' g
say '  {'
say '  public:'
do i=1 to j
  out='  ' descb.i||desce.i
/*  if desc.i<>1 then out=out||'['||desc.i|| '];'
  else ; */ out=out||desc.i';'
  say out
  end
do i=1 to j
  if substr( ni.i,1,2 )<>'NI' then say '   short ' ni.i || ';'
  end
say '  };'
say '//static' g c || ';'

do i=1 to j
if substr(ni.i,1,2)<>'NI' then
out= '//CV(' sel.i ',' strip(descb.i) ':' || c || '.'||desce.i || desc.i  ':'||c||'.'||ni.i  ')'
else
out= '//CV(' sel.i ',' strip(descb.i) ':' || c || '.'||desce.i || desc.i  ')'
if i=j then say out
else; say out||','
end

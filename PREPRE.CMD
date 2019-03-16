/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
/*$Header: d:/sh/RCS/PREPRE.CMD 1.1 93/07/15 20:46:36 Steve Exp $*/
arg  a1 a2 a3
'@echo off'
parse value a1 with aaaa '.' b
if b<> 'SPP'  then
  do
    say 'Builds .cpp from .spp -- args are: *.spp database_name'
    exit 51
  end
aaa=aaaa || '.sqc'
'@del' aaa '2>nul'
line=-1
var=''
o=1
action=''
cur=1;
varnum=1
inline=0
doparens=0
do while lines( a1 )>0
  l= linein( a1 )
  l=translate( l, ' ', d2c(9) )
  line=line+1
  if l='' then do; oline.o=l;o=o+1; iterate; end;
  comp=pos('//',l)
  if comp<>0 then do; oline.o=substr( l,1,comp-1 );o=o+1; iterate; end;
  if inline =0 then
    do
     qp=pos( 'QUERY',l )
     if qp<>0 then
       do
/*say ':'||substr( l, qp-1, 1 )
say ':'||substr( l, qp+5, 1 )*/
	 if substr( l, qp-1, 1 )=' ' & substr( l, qp+5,1 )=' ' then
	   do
	     parse value l with aa 'QUERY' var '(' rest
	     if  var='' then
	       do
		 say 'Syntax Error: no name supplied for' action  'near line' line+1 'in file' a1
		 say ''
		 say 'Line text:'  l
		 exit 21
	       end
	     action='QUERY'
	     oline.o= aa action var || '(';o=o+1
	     inline=1
	     out='('
	     parens=0
	     l=rest
	   end
	end
     cp= pos( 'CURSOR',l )
     if cp<>0 then
       do
	 if substr( l, cp-1, 1 )=' ' & substr( l, cp+6,1 )=' ' then
	   do
	      parse value l with aa 'CURSOR' var '(' rest
	      if  var='' then
	       do
		  say 'Syntax Error: no name supplied for' action  'near line' line+1 'in file' a1
		  say ''
		  say 'Line text:'  l
		  exit 21
	       end
	      action='CURSOR'
	      oline.o= aa action var || '(';o=o+1
	      inline=1
	      out='('
	      parens=0
	      l=rest
	   end
	 end
    end
  if inline=0 then  do;oline.o=l; o=o+1; end;
  else
    do
      out= out l
      if lastpos( ';', l )= length( l ) & length( l )<>0 then
	do
	  inline=0
	  call	cp
	end
    end
end
do j=1 to varnum-1
  call lineout aaa,  '#define ' fmt.j || j  addr.j
end
do j=1 to varnum-1
 if substr( nv.j,1, 2 )<>'NV' then call lineout aaa,  '#define' fmt.j || '_ni' ||j nv.j
end
call lineout aaa,  ''
call lineout aaa,  'BEGIN SQL DECLARE'
call lineout aaa,  'exec sql begin declare section;'
do j=1 to varnum-1
  li=type.j fmt.j||j
  if lgth.j>=1 then li=li||'['||strip(lgth.j)||']'
  call lineout aaa,  li||';'
end
do j=1 to varnum-1
  if substr( nv.j,1,2 )<>'NV'  then call lineout aaa,  'short' fmt.j ||'_ni'||j ||';'
end
call lineout aaa,  'exec sql end declare section;'
call lineout aaa,  'END SQL DECLARE'
call lineout aaa,  '$$$END SQL DECLARE'
call lineout aaa,  ''
do j=1 to o-1
  parse value oline.j with  pr '#include ' mid '<' incf '>'
  if incf<>'' then call lineout aaa, '$$$INCLUDE' || oline.j
  else
  call lineout aaa,  oline.j
end
exit


cp:  /*procedure expose out parens action var aa varnum col. nv. addr. type. lgth. fmt. cur*/
      start=1
      parens=1
      do while start<>0
	start= pos( '(', out, start+1 )
	if start<>0 then parens=parens+1
      end

      start=1
      do while start<>0
	start=pos( ')', out, start+1 )
	if start<>0 then parens=parens-1
      end

if parens=0 then
  do
    out=substr( out, pos('(', out)+1 , lastpos( ')', out )-1 )
    out=substr( out, 1 , lastpos( ')', out )-1 )
    text='exec sql'
    if action='CURSOR' then
      do
	text.cur=text 'declare' var 'cursor for'
	fetch.cur='exec sql fetch' var 'into'
	open.cur='exec sql open' var ';'
	close.cur='exec sql close' var ';'
	call collvars
	if result<>0 then exit result
	oline.o='$$ BEGIN CURSOR';o=o+1
	oline.o=text.cur; o=o+1
	oline.o= fetch.cur; o=o+1
	oline.o=open.cur; o=o+1
	oline.o= close.cur;o=o+1
	oline.o='$$ END CURSOR';o=o+1
	oline.o= ');' ; o=o+1
	cur=cur+1
      end
    if action='QUERY' then
      do
	open.cur=''
	close.cur=''
	fetch.cur=''
	text.cur='exec sql '
	call collvars
	if result<>0 then exit result
oline.o='$$ BEGIN QUERY';o=o+1
	oline.o= text.cur; o=o+1
oline.o='$$ END QUERY';o=o+1
	oline.o= ');' ; o=o+1
	cur=cur+1
      end
  end
else
do
  say  'Unbalanced parentheses error: near line' line+1
  say parens out
  exit 7
end
return 5

collvars:
start=1
s=1
q=1
ostart=start
do while s<>0 | q<>0
  s=pos( 'CV', out, start+1 )
  q=pos( 'QV', out, start+1 )
  if s=0 & q=0 then leave
  if (s>0 & s<q) | q=0 then do; start=s; v='CV'; end
  if (q>0 & q<s) | s=0 then do; start=q; v='QV'; end
  pct=1
  do j=pos('(', out, start)+1 to 10000
    if substr( out, j, 1 )='(' then pct=pct+1
    if substr( out, j, 1 )=')' then pct=pct-1
    if pct=0 then leave
  end

  pre=strip( substr( out, ostart, start-ostart ) )
  ostart=j+1
  pc=strip(substr( out, start, j-start ))
  sv=strip(substr( out, start ))
  parse value sv with '(' qq ')'
  if v='CV' then
    do
      parse value qq with a ',' b
      if b='' then
	do
	  say 'Column name omitted: ' sv 'near line' line+1
	  return 71
	end
    end
  else; b=qq
  parse value b with c ':' d ':' e
  if c='' then
    do
      say 'Syntax error: No data type specified'
      say out
      return  81
    end
  a=strip(a)
  c=strip(c)
  d=strip(d)
  e=strip(e)
  fmt.varnum=v
  parse value d with d '[' g ']' .
  addr.varnum=d
  if c<>'long' & c<>'short' & c<>'double' & c<>'char' then
    do
      say ''
      say 'Syntax Error: near line' line+1 'in file' a1
      say 'Type is:' c
      say 'SQL host variable types must be char, long, short or double.'
      exit 21
    end
  type.varnum=c
  lgth.varnum=g
  if v='CV' then
    do
      col.varnum=a
      fetch.cur=fetch.cur  ':'||v||varnum
      if e<>'' then
	do
	  nv.varnum=e
	  fetch.cur=fetch.cur ':'||v||'_ni'||varnum
	end
      fetch.cur=fetch.cur ','
      text.cur=text.cur pre a
    end
  if v='QV' then
    do
      if e<>'' then nv.varnum=e
      if action='CURSOR' then
	do
	  text.cur=text.cur pre ':' || v ||varnum
	end
      else
	do
	  text.cur=text.cur pre ':'||v||varnum
	end
      if e<>'' then text.cur=text.cur ':'||v||'_ni'||varnum
    end
  varnum=varnum+1
end
if fetch.cur <>'' then fetch.cur=substr( fetch.cur, 1, length( fetch.cur)-1  ) ';'
text.cur=text.cur substr( out, j+1 ) ';'
return 0


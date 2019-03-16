/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
/* $Header: d:/sh/RCS/postpre.cmd 2.0 93/07/14 10:04:18 Steve Exp $ */
arg  ar a2 a3
if a2='' then parse value translate( ar, ' ', d2c(9) ) with a1 a2
else; a1=ar;
indecl=0
do while chars( a1 )>0	& indecl=0
  l=linein( a1 )
  if l='static unsigned char sqla_program_id[40] =' then do
    call lineout a2, l
    l=linein( a1 );call lineout a2, l
    l=linein( a1 );call lineout a2, l
    indecl=1
  end
end

do while lines( a1 )>0
  l= linein( a1 )
  parse value l with  c d
  if c='$$$END' then leave
end

do while chars( a1 )>0
  l=linein( a1 )
  select
    when substr( l, 1, 10 )='$$$INCLUDE' then
       call lineout a2, substr( l, 11 )
    when substr( l, 1, 5 )='#line' then iterate
    when substr( l, 1, 15 )='$$ BEGIN CURSOR' then
      do
	action='C'
	call cursor
      end
    when substr( l, 1, 14 )='$$ BEGIN QUERY' then
      do
	action='Q'
	call cursor
      end
    otherwise call lineout a2, l
  end
end
return

cursor:
inloop=1
do while inloop=1
  l=linein( a1 )
  o=1
  dab.1=0
  da.1=''
  dab.2=0
  da.2=''
  v=','
  do while  chars( a1 )>0  & inloop=1
      l=linein( a1 )
      select
	when strip(l)='$$ END CURSOR' | strip(l)='$$ END QUERY' then
	  do
	    call lineout a2, '&sqlca,sqla_program_id,' b ||',' var  dab.1 v dab.2
	    call lineout a2, da.1  da.2
	    inloop=0
	  end
	when substr( strip( l ), 1, 8 )='sqlacall' then
	  do
	    parse value l with '(' a ',' b ',' c ',' d ',' e ')' .
	    if action='Q' then var=a || v
	    else; var=''
	  end
	when substr( strip( l ), 1, 8 )='sqlaaloc' then
	  do
	    parse value l with '(' a ',' b ',' c ',' d ')' .
	    dab.a=0
	  end
	when substr( strip( l ),1,8 )='sqlasetv' then
	  do
	    parse value l with '(' a ',' b ',' c ',' d ',' e ',' f ',' g ')' .
	    dab.a=dab.a + 1
	    da.a=da.a v c v d v e v f
	  end
	otherwise iterate
       end
  end
end
return

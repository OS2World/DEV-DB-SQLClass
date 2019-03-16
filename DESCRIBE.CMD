/* (C) Copyright Stephen B. Behman, 1993 -- All rights reserved. */
/* $Header: h:/ubin/RCS/describe.cmd 2.0 93/07/14 10:09:25 Steve Exp $ */
'@echo off'
parse upper arg dbname	tbnam
tbnam=strip( tbnam )
  if tbnam ='' then do
  say 'Describes the Columns in a Database Table'
  say ''
  Say 'Arguments are DatabaseName table_name'
  exit
end
call dbm 'start database manager'
call dbm 'stop using database'
call dbm 'start using database' dbname
if result <> 0 then exit
sql="select name,coltype,length, scale, nulls, colno from sysibm.syscolumns  where tbname like '"|| tbnam || "' order by name, colno"
call dbm  sql

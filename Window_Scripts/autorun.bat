@echo off

set PYTHONPATH=C:\OSGeo4W\apps\python27\lib;C:\OSGeo4W\apps\python27\lDLLs;C:\OSGeo4W\apps\python27\libs;C:\OSGeo4W\apps\python27\include;
set PATH=%PATH%;C:\OSGeo4W\bin;

REM Unix in Win2k starts here
doskey ls=dir/b $*
doskey ll=dir $*
doskey cat=type $*
doskey ..=cd..
doskey grep=find "$1" $2 
doskey mv=ren $*
doskey rm=del $*

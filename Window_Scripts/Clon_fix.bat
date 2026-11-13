REM input: %1 = Input geotiff file (no extension necessary)
REM input: %2 = clon (typically 0) 
REM input: %3 = output format (vrt or GTiff) 


@echo off
set OSGEO4W_ROOT=C:\OSGeo4W
PATH=%OSGEO4W_ROOT%\bin;%PATH%
for %%f in (%OSGEO4W_ROOT%\etc\ini\*.bat) do call %%f
@echo on

set input=%1.tif 
set lon=%2
set outform=%3

IF %3==vrt (
set output=%1_clon%2.vrt
echo %output%
)


IF %3==GTiff (
set output=%1_clon%2.tif
echo %output%
)

REM Use Python script to generate LMMP Confidence mapping from FOM map 
python C:\scripts\NewCenterLon_Equi.py -of %outform% -clon %lon% %input% %output%


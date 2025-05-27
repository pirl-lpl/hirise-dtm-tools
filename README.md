# hirise-dtm-tools
HiRISE DTM tools

```
DTM_prep
	- Several modifications to call helper scripts that are new additions to the DTM subsystem 
	- Helper scripts have been updated to handle missing RED4, replaced with SYN4 balance cube.
	- Commented out call to jitplot
	- Updated to accommodate SYN4 by adding a flag to output text file _SS_statistics.lis
	- Updated path to hi4socet, hinoproj and hidata4socet to point to versions newly committed to the HiRISE subsystem which can deal with SYN4 data.


copy_balance_cubes.pl
	- Helper script new addition to the DTM subsystem, called by DTM_prep
	- Gets a the balance cubes from the HiCCDStitch data area and unzips them.
	- Writes a list of the cubes that is an input to hi4socet.


hi4socet_HiROC.pl
	- Modified from original USGS script. 
	- Helper script new addition to the DTM subsystem.
	- Called by DTM_prep.
	- Takes the list output from copy_balance_cubes.pl 
	- Calls hinoproj.
	- Then takes the output from hinoproj and runs ISIS app socetlinescankeywords.
	- Finally stretches cubes to 8-bit and exports as .raw format.


hinoproj_HiROC.pl
	- Modified from original USGS script. 
	- Helper script new addition to the DTM subsystem.
	- Runs ISIS application noproj on each CCD image strip, followed by hijitreg to mosaic into a single 'noproj' cube.
	- Modified to process observations with SYN4 balance cubes.
	- Called by hi4socet.


hidata4socet_HiROC.pl
	- Helper script new addition to the DTM subsystem.
	- Modified from original USGS script. 
	- Takes the output of hinoproj to acquire MOLA data from a local data area.
	- Fixes issue where equatorial project only acquired MOLA gridded DEM either >0 or <0 latitude.
    - Uses location-dependent paths to access MOLA data.


DTM_prep
   |
   |                     
   |---> 1. copy_balance_cubes 
   |            |
   |            |
   |            v  
   |---> 2. hi4socet -------------|     
   |           |                  |
   |           |---> 3. hinoproj  |
   |                              |
   |---> 4. hidata4socet <--------|       
                 
```
         
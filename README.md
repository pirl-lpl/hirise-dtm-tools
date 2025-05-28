# hirise-dtm-tools
HiRISE DTM tools


This repository contains a version of the preprocessing scripts for HiRISE stereo pairs 
intended for photogrammetric processing following the ISIS3/SOCET SET workflow[1,2]. 

These scripts have been modified to accommodate the loss of CCD RED4, 
 replaced by the IR10 CCD which is renamed SYN4 (for Synthetic RED4) in the HiRISE 
 Operations Center (HiROC) pipelines [3].

Minimal modifications have been made for users outside of the HiRISE Operations Center.

It is suggested the scripts be placed in a directory called DTM.

Instructions below assume the user runs the wrapper script, `DTM_prep`. 


#### Modify DTM_prep

DTM_prep is a wrapper script that calls the other scripts in this
repository.

Replace all instances of `$HiRISE_ROOT` with the path to your local
 DTM directory. (Or set a local environment variable called `HiRISE_ROOT` to the 
 path to the DTM directory.)

 
#### Modify copy_balance_cubes.pl

`copy_balance_cubes.pl` copies the intermediate image cubes for each CCD after 
 radiometric calibration, colloquially referred to as the "balance" cubes.

Modify line 106 to point to your local path containing the "balance" cubes, if you
have them.


#### Modify hi4socet_HiROC.pl

Replace all instances of `$HiRISE_ROOT` with the path to your local
 DTM directory. 

#### Modify hinoproj_HiROC.pl

No modifications needed. 

#### Modify hidata4socet_HiROC.pl

Hardcode your local file paths on lines 23–27.

## How to Run the Scripts

Make sure that ISIS3 is initiated in your environment before running.


Call `DTM_prep` as follows:

```
    DTM_prep projectName OBSID_1 dejit_flag OBSID_2 dejit_flag conf_file  

	Where
		projectName   is a descriptive name of the project, such as Columbus_Crater
		OBSID_1       is the observation ID of one of the stereo pair, such as PSP_004052_2045
		OBSID_2       is the other half of the stereo pair (the order doesn't matter)
		dejit_flag    can be 'y' or 'n' (w/o single quotes). If this is 'y', only the RED4-5 cubes
		                will be run through the standard prep script. The user should already have 
		                the dejittered RED mosaic cube, which requires different preprocessing.
		conf_file     is the path to the user's DTMgen.conf file located in their own directory.
```

For external users, the `conf_file` argument is just a dummy argument, so it should not matter
what you put there. 

Example command:

``` DTM_prep North_Residual_Cap_1347E_845N PSP_009834_2645 n PSP_009873_2645 n foo ```

#### Notes

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

For questions contact Sarah Sutton (ssutton at lpl dot arizona dot edu).


### References

[1] [Kirk et al., 2008](https://doi.org/10.1029/2007JE003000)

[2] [Sutton et al., 2022](https://doi.org/10.3390/rs14102403)

[3] [Sutton et al., 2025](https://www.hou.usra.edu/meetings/lpsc2025/pdf/2463.pdf)

         
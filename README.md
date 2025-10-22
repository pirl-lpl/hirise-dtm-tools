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


## Preprocessing color

The script `hicolor4socet_isis343-4.pl` and `hicolor_noproj_isis344.pl` preprocess HiRISE color.

`hicolor4socet` calls `hicolor_noproj`.

Both scripts were originally written by Annie Howington, formerly of the USGS, and have not been modified much for use at HiROC.

Do change the path to your scripts folder (specifically the folder containing `hicolor_noproj`) on line 22 of `hicolor4socet`.

Go to the /data/DTM_working/Projects/<Project_name>/ directory. Make a directory called <image_ID>_COLOR in the project directory.
`cd /data/DTM_working/Projects/<Project_name>/`
`mkdir <image_ID>_COLOR`
`cd <image_ID>_COLOR`

Copy the UNFILTERED_COLOR4 and UNFILTERED_COLOR5 cubes from the /HiRISE/Data/HiColorNorm/<mission_phase>/<ORB_range>/<Image_ID> to the <image_ID>_COLOR directory. For Example:
`cp /path/to/ESP/ORB_023100_023199/ESP_023119_1550/ESP_023119_1550_UNFILTERED_COLOR{4,5}.cub.gz .`

If necessary type gunzip *.gz (Most of the UNFILTERED_COLOR cubes have been gzipped, so they end in .gz).
Make a list of these two cubes: ls *.cub > cubelist

Run hicolor4socet.pl
`/path/to/hicolor4socet_isis343-4.pl cubelist`

## Import Color to SOCET SET

Copy the .raw file for each color band over to the SOCET SET workstation.

In a Windows Command prompt, run for example:

`start_socet -single import_colorHiRISE.exe ESP_088929_1845_UNFILTERED_COLOR_BG.raw ESP_088929_1845_REDmos_hijitreged.sup`

Repeat for each color band, importing it to match the corresponding REDmos_hijitreged image (.sup file).

Validate that each color band imported correctly by loading the corresponding REDmos_hijitreged image in the left eye, and the color band in the right eye in SOCET SET. 

They should match exactly, with the color band only overlying the center of the REDmos swath.

## Run orthophoto script to automatically produce Orthophotos.

To generate all the orthophoto settings files and a batch file automatically, run orthoscriptV0.91.py on the SOCET SET workstation.

1. Run the script in the terminal or just run it by double clicking the file. Either way will work.

2. The script will prompt you for your project name.  You can copy and paste that from the SOCET SET menu.

3. The script will prompt you for the number of images you want to generate orthos. IMPORTANT NOTE: the script auto grabs the images ID after you select it 
later on as well as grabbing the COLOR Sup files from your COLOR directory if its formated correctly

4. The script will prompt you to select the image sup file for orthos generation in a GUI similar to  file explorer and after each one you select 
it will print the name in the terminal for you to see what images you've selected so far.

5. The script will run through a similar prompt and selection process for the DTM and the Calc Ortho Boundry file for ortho generation.

6. once all the files are selected the script will generate all the appropriate .set files as well as a numbered master orthos file in case you run 
multiple and place them in your batch_dir.

7. From there just double click the master_orthos.bat file and let the files generate.


### References

[1] [Kirk et al., 2008](https://doi.org/10.1029/2007JE003000)

[2] [Sutton et al., 2022](https://doi.org/10.3390/rs14102403)

[3] [Sutton et al., 2025](https://www.hou.usra.edu/meetings/lpsc2025/pdf/2463.pdf)

         
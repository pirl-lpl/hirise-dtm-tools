These are a collection of useful scripts used in the production process and can all be copied to a "C:\scripts" directory. 
After doing so you will want to add the C:\scripts directory to your path

## Installing and adding Path on Windows

In the Windows start menu, right-click on Computer > Properties
- Go to Advanced System Settings > Environment Variables
- In the list of System variables, locate the variable called "Path" and Edit it
- Add at the end ";C:\SOCET_SET_5.6.0\bin;C:\scripts;C:\Program Files (x86)\HiRISE\autoTriangulation\;C:\Program Files (x86)\HiRISE\autoTriangulation\gnuplot\bin" (or copy and paste the list of variables to a text editor, edit and then re-copy the updated list back into the Path variable).

## Aoriginals.bat

  A simple but useful batch command to copy original sup files during the MST step of SocetSet production
essentially the command of "cp ORIGINAL\* . " which should be ran/called in your E:\SocetSet\data\<ProjectName>\  directory

## Backup.py

  An alternative to the USGS BackupOrientation tool to create save states of your project while working. 
Associated BackupREADME.txt 

## Clon_fix.bat

## NewCenterLon_Equi.py

## arcmap9_fixjp2.exe

## autorun.bat

## color instruction.txt

  An example of the command used to import COLOR from the E:\Socet\images\<ProjectName>\isis\COLOR directory after moving preprocessed COLOR products to the ...\<ProjectName>\isis\COLOR folder

## socet_crash.bat

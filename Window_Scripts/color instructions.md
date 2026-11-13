## Sample workflow instructions for shorcutting the import of COLOR into Socet for orthophoto production step.
<ins> Make sure any instance of <ProjectName> you replace with your own projects name, in this example Troughs_Ridges_Chryse_Planitia is the example project name</ins>

- Open a windows powershell
- $ ```E:```
- $ ```cd Socet\images\Troughs_Ridges_Chryse_Planitia\isis\COLOR```
  -  _Or wherever you are storing your COLOR products on your local workstation machine_
- $ ```Get-ChildItem *COLOR*.raw | ForEach-Object { $n = $_.Name; 'call start_socet -single import_colorHiRISE.exe Troughs_Ridges_Chryse_Planitia ' + $n + ' ' + $n.Substring(0,15) + '_REDmos_hijitreged.sup' } | Out-File -FilePath color_import.bat -Encoding ascii```
- $ ```./color_import.bat```
  - _this executes the .bat file you just made and imports the COLOR files into SocetSet which will be viewable in the image loader after it finishes_

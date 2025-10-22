###########################################################################################################
# Written by Maximus Cabrera for HiROC as part of the 
# DTM creation process to help with creating ortho-rectified images
# in a much shorter time by taking inputs from user to see how many
# Ortho images they need generated and creating the set and bat file
# for image generation in bulk.
#
# Version: 0.9 - orthoscriptV0.91.py Maximus Cabrera 11/12/22
#
# Copyright (C) 2022 Arizona Board of Regents on behalf of the Planetary
# Image Research Laboratory, Lunar and Planetary Laboratory at the
# University of Arizona.
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License. 
###########################################################################################################

import os
import sys
import numpy
from tkFileDialog import askopenfilename						

projectname = raw_input("enter name of project \t\t")																																			#obtains project name from user in order to find relevant data
os.chdir("C:\SOCET_SET_5.6.0\data")																																								#change directory to SOCET_SET data directory with all prj files
prj = open("{}.prj".format(projectname),"r")																																					#opens prj file and reads it to obtain the project data path
prj.readline()
path = prj.readline()
path = path.replace('DATA_PATH',' ')
path = path.strip()
datafiles = os.listdir('{}'.format(path)) 																																						#Lists all files within data directory
locationread = open("C:\SOCET_SET_5.6.0\internal_dbs\DEVICE\location.list","r")																													#Opens locations.list file for data extraction

for line in locationread:																																										#Reads location.list file and extracts the appropriate path given project name 
	if projectname in line:
		line = line.replace('\t',' ') #replaces all possible \t tabs with space
		line = line.strip() #strips away repeat spaces
		line = line.split(" ") #splits line into an array to  grab file location
		
		imgloc = line[-1]
		
print(imgloc)



os.chdir("{}".format(imgloc))
imgfiles = os.listdir('{}\isis'.format(imgloc))																																					#lists all files within image directory for given project and checks to see if a COLOR directory exists
if os.path.exists('{}\isis\COLOR'.format(imgloc)) == True:
	imgfiles += os.listdir('{}\isis\COLOR'.format(imgloc))

imgnumber=int(input('input number of images for orthos generation, Color images that match img ID will be grabbed as well \t\t'))																#prompts user for how many orthos they wish to generate


def imgID(x):																																													#funtion that will return the ImgID from raw name of image file 
	name = os.path.basename(x).split('_')
	real_name = '{}_{}_{}'.format(name[0],name[1],name[2])
	return real_name

imglist=[]
n=0
while n < imgnumber:																																											#This loop executes several funtions:
	print('select image raw file for ortho generation')
	temp = askopenfilename(title='select image for orthos generation',filetypes=[('RAW files','.raw')])																							#prompts user to select the image raw file that they wish to use 
	temp = imgID(temp)																																											#uses ImgID function to get image id of raw file
	print(temp)
	for entry in imgfiles:																																										#looks to see if files with image id exist within image directory																																					
		if temp in entry and entry.endswith(".raw"):																																			#selects only image files that end in .raw
			temp2 = (entry.split(".raw"))[0]																																					#if both conditions are met the file is accepted and the .raw ending is stripped off for later
			for entry2 in datafiles:																																							#looks to see if a sup file of the same name exists in data directory
				if entry2 == ("{}.sup".format(temp2)):
					imglist.append(entry2)																																						#sup file is added to img list for ortho generation
	n += 1
	print(imglist)																																												#prints list for user to see
	
os.chdir('{}'.format(path))
binlist = []
for entry in imglist:																																											#for each sup file within the imglist, file is read and from the TOTAL_SAMPLES line we are able to determine the bin size of image and add that to the bin list
	read = open(entry,"r")
	for line in read:
		if 'TOTAL_SAMPLES' in line:
			temp = line.split(" ")
			temp = int(temp[-1])
			if temp == 20000:
				binlist.append(1)
			else:
				binlist.append(2)


print('select the DTM file you want to use for Ortho Generation')
dth = askopenfilename(title='select DTM you want to use',filetypes=[("DTH files",".dth")])						#prompts user to input the dth file using a file selector
print(dth)	
os.system("start_socet -single calcOrthoBdry {} {}".format(projectname,dth))																			#runs calcOrthoBdry cmd hopefully								
dth = os.path.basename(dth)																																										#returns the selected file with just the raw name and extension
dth = (dth.split('.dth'))[0]
dthread = open('{}.dth'.format(dth),"r")																																						#Opens dth file for data extraction

for line in dthread:

	if 'SPACING_XY' in line:
		binsize = line																																											#finds the line that contains bin size and saves it for extraction
binsize = binsize.split(" ")																																									# line [37]-[39] will split off all of the excess in the line leaving only the exact binning size as an integer
binsize = numpy.unique(binsize)
binsize = str(binsize[1])
binsize = int(binsize.replace('.000000',''))
if binsize > 2:																																													#checks to make sure bin size was obtained correctly and if not it will stop the script
		print("the bin size on your dth file was either found incorrectly or the DTM was made incorrectly please check it")
		sys.exit()

print("select the calcortho file for ortho generation")			
calcortho = askopenfilename(title='select calcortho file for ortho generation',filetypes=[("Text Document",".log")])
orthoread = open('{}'.format(calcortho),"r")																																					#prompts user to input calcortho file and opens it for data extraction
LLlon=[]
LLlat=[]
URlon=[]
URlat=[]
for line in orthoread:																																											#checks the calcortho file and grabs only the important lines containing the coords
	if line.startswith("LL: Lon")==True or line.startswith("LL: X")==True:
		LLlon.append(line)

	if line.startswith("LL: Lat")==True or line.startswith("LL: Y")==True:
		LLlat.append(line)

	if line.startswith("UR: Lon")==True or line.startswith("UR: X")==True:
		URlon.append(line)

	if line.startswith("UR: Lat")==True or line.startswith("UR: Y")==True: 
		URlat.append(line)

#print(LLlat)
#print(LLlon)
#print(URlat)
#print(URlon)


if len(LLlon) == 0:																																											
	LLlon = LLlon[0]
	LLlat = LLlat[0]
	URlon = URlon[0]
	URlat = URlat[0]
else:	
	LLlon = ((LLlon[-1]).split(" "))[-1]
	LLlat = ((LLlat[-1]).split(" "))[-1]
	URlon = ((URlon[-1]).split(" "))[-1]
	URlat = ((URlat[-1]).split(" "))[-1]

os.chdir('{}\\batch_dir'.format(path))
files= str(os.listdir(os.getcwd()))
batcount = files.count('master_orthos')
if batcount == 0:
	masterorthos = open("master_orthos_0.bat","a")
else:
	masterorthos = open("master_orthos_{}.bat".format(batcount),"a")

def	orthowrite(img):																																											#function that will generate orthoset files 
	index= imglist.index(img)																																									#each img file has the same location in the array as its bin size so it can be found by looking in the same place 
	imgorthobin = binsize
	imgorthobin2 = 25*binlist[index]
	img_name= (img.split(".sup"))[0]
	
	file=open('{}_{}.set'.format(img,imgorthobin),'w')																																			#Generates the appropriate set file for meter set file
	file.write('setting_file                  1.1\n')
	file.write('ortho.project \t\t\t\t\t C:\SOCET_SET_5.6.0\data\{}.prj\n'.format(projectname))
	file.write('ortho.task                       SIMPLE_ORTHO\n')
	file.write('ortho.image \t\t\t\t\t {}\n'.format(img))
	file.write('ortho.use_dtm                    YES\n')												
	file.write('ortho.dtm \t\t\t\t\t\t {}.dth\n'.format(dth))
	file.write('ortho.elevation                  0.0\n')
	file.write('ortho.foot_entry                 TWO\n')												
	file.write('ortho.ul_x \t\t\t\t\t\t {}'.format(LLlon))
	file.write('ortho.ul_y \t\t\t\t\t\t {}'.format(URlat))
	file.write('ortho.ur_x \t\t\t\t\t\t {}'.format(URlon))
	file.write('ortho.ur_y \t\t\t\t\t\t {}'.format(URlat))
	file.write('ortho.ll_x \t\t\t\t\t\t {}'.format(LLlon))
	file.write('ortho.ll_y \t\t\t\t\t\t {}'.format(LLlat))
	file.write('ortho.lr_x \t\t\t\t\t\t {}'.format(URlon))
	file.write('ortho.lr_y \t\t\t\t\t\t {}'.format(LLlat))
	file.write('ortho.output_file \t\t\t\t {}_{}m_o\n'.format(img_name,imgorthobin))
	file.write('ortho.output_location \t\t\t {}\n'.format(projectname))
	file.write('ortho.file_format                img_type_tiff_tiled\n')
	file.write('ortho.jpeg_quality               90\n')
	file.write('ortho.gsd \t\t\t\t\t\t {}\n'.format(imgorthobin))
	file.write('ortho.doq_overedge               300.0\n')
	file.write('ortho.doq_size                   QUARTER\n')
	file.write('ortho.grid_btn                   NO\n')
	file.write('ortho.grid_int                   20\n')
	file.write('ortho.arc_world                  YES\n')
	file.write('ortho.ortho_info                 YES\n')
	file.write('ortho.auto_min                   YES\n')
	file.write('ortho.auto_load                  NO\n')
	file.write('ortho.construct_geotiff          YES\n')
	file.write('ortho.use_tin_map                YES\n')
	file.write('ortho.allow_dense_dtm            NO\n')
	file.write('ortho.background_color           BLACK\n')
	file.write('ortho.interp                     BILINEAR\n')
	file.write('ortho.ortho_mate                 NO\n')
	file.write('ortho.base_to_height             1.0\n')
	file.write('ortho.left_or_right              LEFT\n')
	
	file=open('{}_{}.set'.format(img,imgorthobin2),'w')																																	#Generates the appropriate set file for centimeter set file
	file.write('setting_file                  1.1\n')
	file.write('ortho.project \t\t\t\t\t C:\SOCET_SET_5.6.0\data\{}.prj\n'.format(projectname))
	file.write('ortho.task                       SIMPLE_ORTHO\n')
	file.write('ortho.image \t\t\t\t\t {}\n'.format(img))
	file.write('ortho.use_dtm                    YES\n')												
	file.write('ortho.dtm \t\t\t\t\t\t {}.dth\n'.format(dth))
	file.write('ortho.elevation                  0.0\n')
	file.write('ortho.foot_entry                 TWO\n')												
	file.write('ortho.ul_x \t\t\t\t\t\t {}'.format(LLlon))
	file.write('ortho.ul_y \t\t\t\t\t\t {}'.format(URlat))
	file.write('ortho.ur_x \t\t\t\t\t\t {}'.format(URlon))
	file.write('ortho.ur_y \t\t\t\t\t\t {}'.format(URlat))
	file.write('ortho.ll_x \t\t\t\t\t\t {}'.format(LLlon))
	file.write('ortho.ll_y \t\t\t\t\t\t {}'.format(LLlat))
	file.write('ortho.lr_x \t\t\t\t\t\t {}'.format(URlon))
	file.write('ortho.lr_y \t\t\t\t\t\t {}'.format(LLlat))
	file.write('ortho.output_file \t\t\t\t {}_{}cm_o\n'.format(img_name,imgorthobin2))
	file.write('ortho.output_location \t\t\t {}\n'.format(projectname))
	file.write('ortho.file_format                img_type_tiff_tiled\n')
	file.write('ortho.jpeg_quality               90\n')
	file.write('ortho.gsd \t\t\t\t\t\t .{}\n'.format(imgorthobin2))
	file.write('ortho.doq_overedge               300.0\n')
	file.write('ortho.doq_size                   QUARTER\n')
	file.write('ortho.grid_btn                   NO\n')
	file.write('ortho.grid_int                   20\n')
	file.write('ortho.arc_world                  YES\n')
	file.write('ortho.ortho_info                 YES\n')
	file.write('ortho.auto_min                   YES\n')
	file.write('ortho.auto_load                  NO\n')
	file.write('ortho.construct_geotiff          YES\n')
	file.write('ortho.use_tin_map                YES\n')
	file.write('ortho.allow_dense_dtm            NO\n')
	file.write('ortho.background_color           BLACK\n')
	file.write('ortho.interp                     BILINEAR\n')
	file.write('ortho.ortho_mate                 NO\n')
	file.write('ortho.base_to_height             1.0\n')
	file.write('ortho.left_or_right              LEFT\n')
	
	
	
	file.close()														#closes file
	masterorthos.write("call ""C:\SOCET_SET_5.6.0\\bin\start_socet"" -log ""E:\Socet\data\{}\\batch_dir\queue_batchlog.txt"" -single orthophoto -batch -a conventional -s {}_{}.set\n".format(projectname,img,imgorthobin))			#writes lines into the master_bat_file for each set
	masterorthos.write("call ""C:\SOCET_SET_5.6.0\\bin\start_socet"" -log ""E:\Socet\data\{}\\batch_dir\queue_batchlog.txt"" -single orthophoto -batch -a conventional -s {}_{}.set\n".format(projectname,img,imgorthobin2))

for entry in imglist:
	orthowrite(entry)
print("**all your set files and masterorthos have been made and sent to your batch_dir please check and make sure your set files and master orthos bat are generated correctly**")


#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Sep  8 08:16:05 2022
This script will take the users project name as an input in order to navigate to their
project directory, from there it will then copy over all the necessary files in order to
create the appropriate backup along with the correct backup number.
@author: Max
"""

import os

projectname = raw_input("enter name of project \t\t\t")                       #prompts the user for the project name in order to establish path
os.chdir("C:\SOCET_SET_5.6.0\data")										#change directory to SOCET_SET data directory with all prj files
prj = open("{}.prj".format(projectname),"r")
prj.readline()
x = prj.readline()
x = x.replace('DATA_PATH',' ')
x = x.strip()
path=x
os.chdir(path)
filelist = str(os.listdir(path))                                               #lists all the files in directory
backupnumber = filelist.count("Backup")                                       #counts all that have Backup in name in order to establish what backup we are creating

if backupnumber == 0:                                                         #check if no backup has been created yet this will create the first "Backup_0"
    os.system('mkdir {}_Backup_0'.format(projectname))

else:
    os.system('mkdir {}_Backup_{}'.format(projectname,backupnumber))                         #if they're are already backups made this will make the newest one with the appropriate name

Destination =".\{}_Backup_{}".format(projectname,backupnumber)                               #defines the destination of the new backup folder so we can send files there


os.system('copy *.atf {}'.format(Destination))                                  #attempts to copy atf files and checks to make sure it ran
backupfolder = str(os.listdir(Destination))
atfcheck= backupfolder.count('.atf')
if atfcheck > 0:
    print('**atf files copied**')
else:
    print('**problem encountered transfering atf files**')
    
    
os.system('copy *.gpf {}'.format(Destination))                                  #attempts to copy gpf files and checks to make sure it ran
backupfolder = str(os.listdir(Destination))
gpfcheck= backupfolder.count('.gpf')
if gpfcheck > 0:
    print('**gpf files copied**')
else:
    print('**problem encountered transfering gpf files**')


os.system('copy *.ocov {}'.format(Destination))                                 #attempts to copy ocov files and checks to make sure it ran
backupfolder = str(os.listdir(Destination))
ocovcheck= backupfolder.count('.ocov')
if ocovcheck > 0:
    print('**ocov files copied**')
else:
    print('**problem encountered transfering ocov files**')
    
    
os.system('copy *.iop {}'.format(Destination))                                  #attempts to copy iop files and checks to make sure it ran (more than 1)
backupfolder = str(os.listdir(Destination))
iopcheck= backupfolder.count('.iop')
if iopcheck > 1:
    print('**iop files copied**')
else:
    print('**problem encountered transfering iop files**')
    
os.system('copy *.ipf {}'.format(Destination))                                  #attempts to copy ipf files and checks to make sure it ran (more than 1)
backupfolder = str(os.listdir(Destination))
ipfcheck= backupfolder.count('.ipf')
if ipfcheck > 1:
    print('**ipf files copied**')
else:
    print('**problem encountered transfering ipf files**')

os.system('copy *.rep {}'.format(Destination))                                  #attempts to copy rep files and checks to make sure it ran
backupfolder = str(os.listdir(Destination))
repcheck= backupfolder.count('.rep')
if repcheck > 0:
    print('**rep files copied**')
else:
    print('**problem encountered transfering rep files**')
    
os.system('copy *.sup {}'.format(Destination))                                  #attempts to copy sup files and checks to make sure it ran (more than 1)
backupfolder = str(os.listdir(Destination))
supcheck= backupfolder.count('.sup')
if supcheck > 1:
    print('**sup files copied**')
else:
    print('**problem encountered transfering sup files**')

if atfcheck >0 and gpfcheck >0 and ocovcheck>0 and iopcheck>1 and ipfcheck>1 and repcheck>0 and supcheck>1:     #checks to see if any problems occured copying any of the file types and alerts the user that the backup may have been made incorrectly
    print('{}_Backup_{} created successfully'.format(projectname,backupnumber))
else:
    print('something went wrong during backup process check {}_Backup_{} directory'.format(projectname,backupnumber))

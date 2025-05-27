#!/usr/bin/perl

# Copyright (C) 2004-2024 Arizona Board of Regents on behalf of the Lunar and
# Planetary Laboratory at the University of Arizona.
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

use strict;
use warnings;
use File::Copy;
#use PIRL::pvl_addons;
use Getopt::Long;

#-------------------------------------------------------------------------------
# Copies the REDX.balance.cub or SYNX.balance.cub from HiStitch.
# Use as part of the set up for creating SOCET SET DTMs.
# By Sarah Mattson 1/4/2008 HiRISE Operation Center.
# Modified by SM 6/18/2008 to allow for zipped cubes.
# Modified 10/16/2008 to accommodate different mission phases. SM
# Modified 4/26/2010 - corrected printout of list to check for existence of cube. SM
# Modified 10/27/2010 - added beginning and ending CCD number input arguments. SM
# Modified 10/9/2023 - Allow for case where RED4 has been replaced by SYN4. SS
# Modified 3/13/2024 - Generalize for any SYN- cubes. 
#                      Clean up argument check and usage. SS
# Version 1.0 
#   Committed to CVS 3/14/2024 - first commit
# 
#-------------------------------------------------------------------------------
#
# Run this script in the directory where you would like to copy the cubes.
#
# Sample command line for all RED cubes (default setting!)
# % copy_balance_cubes.pl PSP_002377_2180 0 9
#
# Sample command line for only RED 4-5 cubes (for DTM_prep using with dejittered images)
# % copy_balance_cubes.pl PSP_002377_2180 4 5
#
# Sample command line for all COLOR cubes
# % copy_balance_cubes.pl PSP_002377_2180 10 13
#
#-------------------------------------------------------------------------------


my $OBSID = $ARGV[0]; 
my $start_CCD = $ARGV[1];
my $end_CCD   = $ARGV[2];

my $CCD;
my $ret;
my $cmd;

my $usage = "\nUsage: \n\t copy_balance_cubes.pl <Observation_ID> <begnningCCD#> <endingCCD#>
\n\t where: \n
\tRequired:
\t  <Observation_ID> is the HiRISE observation ID, e.g., PSP_002377_1860
\tOptional:
\t  <begnningCCD#> is the first CCD number of the range to copy, e.g. 0
\t  <endingCCD#> is the last CCD number of the range to copy, e.g., 9 \n
\texample: copy_balance_cubes.pl PSP_002377_1860 4 5
\texample: copy_balance_cubes.pl PSP_002377_1860 10 13
\tIf start and end CCDs are not specified, the default set is RED0 through RED9.\n\n";


#-------------------------------------------------------------------------------
# Check to see if CCD start and end numbers were specified.
# Otherwise, default to 0-9 for all RED CCDs.
#-------------------------------------------------------------------------------


  if ($#ARGV < 0 || $#ARGV > 2) {
      print "$usage\n";
      exit 1;
    }
    elsif ($#ARGV == 0 && length($ARGV[0]) < 15) {
      print "\nPlease provide a valid HiRISE image ID.\n";
      print "$usage\n";
      exit 1;
      }
    elsif ($#ARGV == 0 || $#ARGV == 1) { 
      $start_CCD = 0;
	  $end_CCD = 9;
      print STDOUT "\n$OBSID CCDs $start_CCD through $end_CCD will be copied.\n\n";
      }
    elsif ($#ARGV == 2) {
      print STDOUT "\n$OBSID CCDs $start_CCD through $end_CCD will be copied.\n\n";
      }


#-------------------------------------------------------------------------------
# Parse the image ID to construct the file path and copy the balance cubes
# to the current directory.
#-------------------------------------------------------------------------------

my $ORBNUM = substr ($OBSID,4,4);
my $ORB = "ORB_".$ORBNUM."00_".$ORBNUM."99/";
my $MISSION_PHASE = substr ($OBSID,0,3);
my $HPATH = "/HiRISE/Data/HiStitch/".$MISSION_PHASE."/".$ORB.$OBSID."/".$OBSID;

for ($CCD = $start_CCD; $CCD < $end_CCD+1; $CCD++)
{
print STDOUT "CCD = $CCD\n";
 my $PATH      = $HPATH."_RED".$CCD.".balance.cub";
 my $PATHGZ    = $HPATH."_RED".$CCD.".balance.cub.gz";
 my $SYNPATH   = $HPATH."_SYN".$CCD.".balance.cub";
 my $SYNPATHGZ = $HPATH."_SYN".$CCD.".balance.cub.gz";
 
 	if (-e $PATH) {
    print STDOUT "Copying $PATH\n";
  	$cmd = "cp $PATH .";
  	$ret = system($cmd);
 	}
 	# if .balance.cub is not there, look for gzipped cube
 	elsif (-e $PATHGZ) {
    print STDOUT "Copying $PATHGZ\n";
 	$cmd = "cp $PATHGZ .";
    $ret = system($cmd);
    $cmd = "gunzip -f *.gz";
    $ret = system($cmd);
    }
 	# if the RED cube is not there, look for SYN cube
    elsif (-e $SYNPATH) {
      print STDOUT "Copying $SYNPATH\n";
      $cmd = "cp $SYNPATH .";
      $ret = system($cmd);
    }
 	# if the SYN balance.cub cube is not there, look for gzipped cube
	elsif (-e $SYNPATHGZ) {
	  print STDOUT "Copying $SYNPATHGZ\n";
	  $cmd = "cp $SYNPATHGZ .";
	  $ret = system($cmd);
	  $cmd = "gunzip -f *.gz";
	  $ret = system($cmd);
    }
  else {
    print STDOUT "$PATH not found. Zipped cube not found. Cannot copy.\n";
  }
}
 
#-------------------------------------------------------------------------------
# Check to see if the image list exists, and delete if it does.
#-------------------------------------------------------------------------------
my $list  = $OBSID.".list";
if (-e $list) {unlink($list)};
my $outfile = $list;

#-------------------------------------------------------------------------------
# Create the list of balance cubes copied for subsequent programs.
#-------------------------------------------------------------------------------
$cmd = "ls *.cub >> $outfile";
$ret = system($cmd);
 

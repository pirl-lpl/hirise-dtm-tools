#!/usr/bin/perl -s

################################################################################
# NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE
#
#      This script is not supported by ISIS.
#      If you have problems please contact Annie Howington-Kraus
#      at ahowington@usgs.gov
#
# NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE
################################################################################

use File::Copy;

my ($progname) = ($0 =~ m#([^/]+)$#);  # get the name of this program

################################################################################
#
# Location-dependent paths, fix for your system:

#$hicolor_noproj_path = "/usgs/cdev/contrib/bin/";
$hicolor_noproj_path = "/data/DTM_working/bin/";
# End of Location-dependent paths
################################################################################

$email = "ahowington\@usgs.gov";

$isisversion = "isis3.4.4";

my $usage = "

**************************************************************************
**** NOTE: $progname runs under isis version: $isisversion  ****
**************************************************************************

Command:  $progname fromlist [matchCube]

Where:
       fromlist = Ascii file containing a list of input COLOR balanced HiRISE
       ISIS3 cube filenames with extensions. Each filename must be on a
       separate line in the list. If the input files reside in a directory
       other than the present-working-directory, you must also include the
       path to the cubes.

       matchCube = Optional user selection of CCD in fromlist to set as
       the \"match cube\".  This CCD is used as the match cube when running
       noproj, and is held in the output noproj mosaic when fine-tuning 
       placement of the noproj'ed CCDs via hijitreg.  The default is RED5.

Description:

       $progname performs ISIS3 processing on HiRISE COLOR cubes to create
       the images and files neeeded for Socet Set color ortho processing.
       Specifically, $progname:

          1) creates a 32-bit noproj'ed COLOR mosaic of the cubes
          2) converts each color band of the  32-bit mosaic to separate 8-bit
             RED, IR and BLUE images and reports the stretch
             pairs used for the conversion to *_STRETCH_PAIRS.lis
          3) converts the 8-bit images to raw files (*.raw)

       You will need to bring only the *.raw files to your Socet Set
       workstation and run import_color_pushbroom to do the import.
       (import_color_pushbroom will require the support file of the RED
        noproj mosaic that was controlled to MOLA).

       Errors encountered in the processing goes to files:
       \"hicolor4socet.err\" and \"hicolor_noproj.err\"

       Any errors with ISIS programs will cause this script to abort.

**************************************************************************
**************************************************************************
NOTICE:
       This script is not supported by ISIS.
       If you have problems please contact Annie Howington-Kraus
       at $email
**************************************************************************
**************************************************************************
";

#####################################################################
#  MAIN APPLICATION SECTION
#  Author: Elpitha Howington-Kraus
#  Date:   January 23 2007
#  Version: 2.0
#  History: MAY 12 2009 - E Howington-Kraus, USGS, Flagstaff Original Version
#                         (a modification of hicolor4socet.pl)
#           JAN 11 2010 - EHK as of isis3.1.21 no longer need extra backslash
#                         in front of quotation marks, so removed them
#           DEC 07 2011 - EHK, added isisversion to documentation
#           JUL 18 2013 - EHK,
#                         1) made changes for isis3.4.4
#                         2) removed SOCET SET workaround
#                         3) added explicit path to getkey so that
#                            this script is portable to external
#                            users that have installed the unix 
#                            version of getkey on their systems
#                         4) added location-dependent path, $hicolor_noproj_path,
#                            to top of script for ease of editing by external
#                            users
#                         5) updated error message to follow current style
#####################################################################

#--------------------------------------------------------------------
# Forces a buffer flush after every print, printf, and write on the
# currently selected output handle.  Let's you see output as it's
# happening.
#---------------------------------------------------------------------
   $| = 1;

#--------------------------------------------------------------------
# First make sure this is a "flagstaf" machine and setisis was run
#--------------------------------------------------------------------

  $GROUP = `printenv GROUP`;
  chomp ($GROUP);

  if ($GROUP eq "flagstaf")
     { 
     $ISISVERSION = `printenv IsisVersion`;
     chomp ($ISISVERSION);
     $len = length($ISISVERSION);
     if ($len == 0)
        {
        print "\nISIS VERSION MUST BE ESTABLISHED FIRST...ENTER:\n";
        print "\nsetisis $isisversion\n\n";
        exit 1;
        }
     }

#---------------------------------------------------------------------
# Get this system's $ISISROOT/bin absolute path to be used for running
# getkey
# --------------------------------------------------------------------

  $ISISROOT_bin_path = `printenv ISISROOT`;
  chomp($ISISROOT_bin_path);
  $ISISROOT_bin_path = $ISISROOT_bin_path . "/bin";
 
#---------------------------------------------------------------------
# Check the argument list
#---------------------------------------------------------------------
   if ($#ARGV < 0 || $#ARGV > 2)
      {
      print "$usage\n";
      exit 1;
      }

#---------------------------------------------------------------------
# Obtain the input parameters
#---------------------------------------------------------------------

   $fromlist = $ARGV[0];
   if ($#ARGV == 1) {$matchCube = $ARGV[1];}

#---------------------------------------------------------------------
# If the hicolor4socet.prt & "hicolor4socet.err" files exist, then delete them
#---------------------------------------------------------------------

   if (-e "hicolor4socet.prt") {unlink("hicolor4socet.prt");}
   if (-e "hicolor4socet.err") {unlink("hicolor4socet.err");}

#---------------------------------------------------------------------
# Open LOG file
#---------------------------------------------------------------------

   $log = "hicolor4socet.err";
   open (LOG,">$log") or die "\n Cannot open $log\n";

#---------------------------------------------------------------------
# Make sure input list file and matchCube exists
#---------------------------------------------------------------------

   if (!(-e $fromlist))
      {
      print "*** ERROR *** Input list file does not exist: $fromlist\n";
      print "hicolor4socet.pl will terminate\n";
      exit 1;
      }

   if ($#ARGV == 1 && !(-e $matchCube))
      {
      print "*** ERROR *** Input match Cube does not exist: $matchCube\n";
      print "hicolor4socet.pl will terminate\n";
      exit 1;
      }

#---------------------------------------------------------------------
# Make sure '*' character is not at end of file names in fromlist
#---------------------------------------------------------------------

   if (-e "temp0101010") {unlink "temp0101010";}
   $cmd = "cp $fromlist temp0101010";
   system ($cmd);
   unlink $fromlist;
   $cmd = "cat temp0101010 | sed s/\*// > $fromlist";
   system ($cmd);
   unlink "temp0101010";

#---------------------------------------------------------------------
# If matchCube was not input by user, set it to COLOR5
#---------------------------------------------------------------------

   if ($#ARGV == 0)
      {

      $matchCube = " ";

      open(LST,"<$fromlist");
      while ($input=<LST>)
         {
         chomp($input);

         $CCD = `$ISISROOT_bin_path/getkey from=$input grpname=Instrument keyword=CcdId`;
         chomp ($CCD);
         $len = length($CCD);
         if($len == 0) {
           $cmd = "$ISISROOT_bin_path/getkey from=$input grpname=Instrument keyword=CcdId";
           ReportErrAndDie("getkey failed on command:\n$cmd");
         }

         if ($CCD eq "RED5")
            {
            $matchCube = $input;
            }
         }
      }

   close(LST);

#----------------------------------------------------------------------
# Now run hicolor_noproj.pl to geneate a mosaic of noproj'ed COLOR CCDs
#----------------------------------------------------------------------

   $cmd = "$hicolor_noproj_path/hicolor_noproj_isis344.pl $fromlist $matchCube";
   system($cmd) == 0 || ReportErrAndDie("hicolor_noproj_isis344.pl failed on command:\n$cmd");

#---------------------------------------------------------------------
# Following the noproj naming convention, create the noproj'ed mosaic
# name
#---------------------------------------------------------------------

   $firstdot = index($matchCube,".");
   $core_name = substr($matchCube,0,$firstdot-1);

   $mosCube = $core_name . "mos_hijitreged.noproj.cub";

#---------------------------------------------------------------------
# Convert each band of the noproj'ed mosaic to individual 8-bit images
#---------------------------------------------------------------------

   $ir_band = $mosCube . "+1";
   $ir_min = $core_name . "_nearIR.min.txt";
   $ir_max = $core_name . "_nearIR.max.txt";
   $ir_byteCube = $core_name . "_nearIR.8bit.cub";
   $ir_stretch_file = $core_name . "_nearIR_STRETCH_PAIRS.lis";

   convert_to_byte ($ir_band, $ir_min, $ir_max, $ir_byteCube, $ir_stretch_file);

   $red_band = $mosCube . "+2";
   $red_min = $core_name . "_RED.min.txt";
   $red_max = $core_name . "_RED.max.txt";
   $red_byteCube = $core_name . "_RED.8bit.cub";
   $red_stretch_file = $core_name . "_RED_STRETCH_PAIRS.lis";

   convert_to_byte ($red_band, $red_min, $red_max, $red_byteCube, $red_stretch_file);

   $bg_band = $mosCube . "+3";
   $bg_min = $core_name . "_BG.min.txt";
   $bg_max = $core_name . "_BG.max.txt";
   $bg_byteCube = $core_name . "_BG.8bit.cub";
   $bg_stretch_file = $core_name . "_BG_STRETCH_PAIRS.lis";

   convert_to_byte ($bg_band, $bg_min, $bg_max, $bg_byteCube, $bg_stretch_file);

#---------------------------------------------------------------------
# Get raw noproj'ed mosaic for Socet Set
# and delete temporary translated cube
#---------------------------------------------------------------------

   $ir_rawImg = $core_name . "_IR.raw";
   $red_rawImg = $core_name . "_RED.raw";
   $bg_rawImg = $core_name . "_BG.raw";

   $cmd = "isis2raw from=$ir_byteCube to=$ir_rawImg bittype=8bit stretch=none";
   system($cmd) == 0 || ReportErrAndDie("isis2raw failed on command:\n$cmd");

   $cmd = "isis2raw from=$red_byteCube to=$red_rawImg bittype=8bit stretch=none";
   system($cmd) == 0 || ReportErrAndDie("isis2raw failed on command:\n$cmd");

   $cmd = "isis2raw from=$bg_byteCube to=$bg_rawImg bittype=8bit stretch=none";
   system($cmd) == 0 || ReportErrAndDie("isis2raw failed on command:\n$cmd");

#---------------------------------------------------------------------
# Rename print.prt file
#---------------------------------------------------------------------

   rename ("print.prt","hicolor4socet.prt");

#---------------------------------------------------------------------
# Close the LOG file.
# If an error was detected, print out the log file
#---------------------------------------------------------------------

   close (LOG);

   @lines = `cat $log`;
   if (scalar(@lines) > 0)
      {
      print "\n*** Errors detected in processing ***\n\n";
      print @lines;
      print "\n";
      print "\n*** See hicolor_noproj.prt and hicolor4socet.prt for details ***\n\n";
      }
   else
      {
      unlink ($log);
      }

   exit;

##############################################################################
#  Subroutine convert_to_byte:  converts the input image band to 8-bit
#                               by running percent and stretch.  The percentage
#                               values to stretch the image to 8-bit are those
#                               used by the HiRISE Team (i.e, 0.1 and 99.99).
#
#                               input: image band
#                               output: min/max text files output by percent
#                                       (named *.min and *.max), and
#                                       a listing of the stretch pairs used
#                                       to convert to 8-bit (named
#                                       *STRETCH_PAIRS.lis)
#
##############################################################################                               
sub convert_to_byte # band min.txt max.txt byteCube  stretch.txt
                    # @_[0] @_[1]   @_[2]   @_[3]      @_[4]
   {
     $band = @_[0];
     $min_file = @_[1];
     $max_file = @_[2];
     $byteCube = @_[3];
     $stretch_file = @_[4];

     #---------------------------------------------------------------------
     #  Run percent to get DN values of image histogram and 0.1% and 99.99%
     #  Results of percent are stored in *.min and *.max files
     #---------------------------------------------------------------------

     $cmd = "percent from=$band to=$min_file percentage=0.1";
     system($cmd) == 0 || ReportErrAndDie("percent failed on command:\n$cmd");

     $cmd = "percent from=$band to=$max_file percentage=99.99";
     system($cmd) == 0 || ReportErrAndDie("percent failed on command:\n$cmd");

     #---------------------------------------------------------------------
     #  Extract the min/max values from the min/max files
     #---------------------------------------------------------------------

     $min = `$ISISROOT_bin_path/getkey from=$min_file grpname=Results keyword=Value`;
     $len = length($min);
     if($len == 0) {
       $cmd = "$ISISROOT_bin_path/getkey from=$min_file grpname=Results keyword=Value";
       ReportErrAndDie("getkey failed on command:\n$cmd");
     }
     chomp ($min);

     $max = `$ISISROOT_bin_path/getkey from=$max_file grpname=Results keyword=Value`;
     $len = length($max);
     if($len == 0) {
       $cmd = "$ISISROOT_bin_path/getkey from=$max_file grpname=Results keyword=Value";
       ReportErrAndDie("getkey failed on command:\n$cmd");
     }
     chomp ($max);

     #---------------------------------------------------------------------
     #  Stretch the image to 8-bit
     #---------------------------------------------------------------------

     if ($min > 0)
        {
        $cmd = "stretch from=$band to=$byteCube+8bit+1:254 pairs=\"0:0 $min:1 $max:254\" lis=1.0 lrs=1.0 his=254 hrs=254";
        }
     else
        {
        $negmin = $min - 1;
        $cmd = "stretch from=$band to=$byteCube+8bit+1:254 pairs=\"$negmin:0 $min:1 $max:254\" lis=1.0 lrs=1.0 his=254 hrs=254";
        }
      system ($cmd) == 0 || ReportErrAndDie("stretch failed on command:\n$cmd");


     #---------------------------------------------------------------------
     #  Create report file for 32-bit to 8-bit stretch pairs
     #---------------------------------------------------------------------

     open (STR,">$stretch_file") or die "\n Cannot open $stretch_file\n";

     print STR "image: $band\n";

     if ($min > 0)
        { print STR "stretch pairs: \"0:0 $min:1 $max:254\"\n"; }
     else
        { print STR "stretch pairs: \"$negmin:0 $min:1 $max:254\"\n"; }

     close STR;

   }

##############################################################################
#  Error Handling Subroutine
##############################################################################
sub ReportErrAndDie
    {
    my $ERROR=shift;

    print "$ERROR\n";
    print "hicolor4socet.pl aborted\n";

    print LOG "$ERROR\n";
    close(LOG);
    exit 1;
    }


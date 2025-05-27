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

#---------------------------------------------------------------------
# Get this system's $HiRISE_ROOT absolute path 
#---------------------------------------------------------------------

my $HiRISE_ROOT = `printenv HiRISE_ROOT`;
  chomp($HiRISE_ROOT);
  
# Add trailing slash to HiRISE_ROOT so path is correct regardless of environment path setup.
$HiRISE_ROOT = $HiRISE_ROOT."/";
  
$hinoproj_path = "$HiRISE_ROOT"."/DTM/";

# End of Location-dependent paths
################################################################################
 
$email = "ssutton\@lpl.arizona.edu";

$isisversion = "isis6.0.0";

my $usage = "

**************************************************************************
**** NOTE: $progname runs under isis version: $isisversion  ****
**************************************************************************

Command:  $progname fromlist [matchCube]

Where:
       fromlist = Ascii file containing a list of input balanced HiRISE
       ISIS3 cube filenames with extensions. Each filename must be on a
       separate line in the list. If the input files reside in a directory
       other than the present-working-directory, you must also include the
       path to the cubes.

       matchCube = Optional user selection of CCD in fromlist to set as
       the \"match cube\".  This CCD is used as the match cube when running
       noproj, and is held in the output noproj mosaic when fine-tuning 
       placement of the noproj'ed CCDs via hijitreg.  The default is RED5.

Description:

       $progname performs ISIS3 processing on HiRISE RED CCDs to create
       the images and files neeeded for Socet Set stereoprocessing.
       Specifically, $progname:

          1) creates a 32-bit noproj'ed mosaic of the CCDs 
          2) converts the 32-bit mosaic to 8-bit and reports the stretch
             pairs used for the conversion to *_STRETCH_PAIRS.lis
          3) converts the 8-bit image to a raw file (*.raw)
          4) creates a list file of the Socet Set USGSAstroLineScanner
             sensor model's keywords and values (*_keywords.lis)

       You will need to bring only the *.raw and *_keywords.lis files to
       your Socet Set workstation and run import_pushbroom to do the import.

       Errors encountered in the processing goes to files:
       \"hi4socet.err\" and \"hinoproj.err\"

       Any errors with ISIS programs will cause this script to abort.

**************************************************************************
**************************************************************************
NOTICE:
       $progname runs under isis version: $isisversion
       This script is not supported by ISIS.
       If you have problems please contact Annie Howington-Kraus
       at $email
**************************************************************************
**************************************************************************
";

#####################################################################
#  MAIN APPLICATION SECTION
#  Author: Elpitha Howington-Kraus
#  Version: 2.0
#  History: JAN 23 2007 - E Howington-Kraus, USGS, Flagstaff Original Version
#                         (originally named hibalanced2ss_linux.pl)
#           Feb 27 2007 - EHK, modified to incorporate latest versions of
#                         noproj and hijitreg, and hitrans.pl workaround
#                         for Socet Set 
#           Apr 25 2007 - EHK, corrected test for negative minimum value
#                         when stretching RED mosaic to 8bit
#           May 18 2007 - EHK Modified to use system default shape model (i.e.
#                         mola) when running spiceinit rather than the
#                         ellipsoid.
#           Jul 31 2007 - EHK Added test to make sure 'setisis' was run
#           Jun 04 2008 - EHK Mapped special pixel values LIS=LRS=1.0 and
#                         HIS=HRS=254.0 when stretching to 8-bit.  This is to
#                         avoid replacing HRS pixels with NULLs when running
#                         map2map in ISIS3
#           Jul 15 2008 - EHK Updated handmos command as per changes in
#                         ISIS3.1.16
#           Nov  5 2008 - EHK Added run of calc_pushbroom_keywords for redesign
#                         of importing ISIS images processed on a linux/solaris
#                         machine to a Socet Set machine running windows/solaris
#           Nov 13 2008 - EHK Added a subroutine for error handling.  It will
#                         report an error and then terminate further processing.
#           Nov 18 2008 - EHK Removed ".balance" from keyword list filename
#           Jan 27 2009 - EHK Placed all perl scripts in usgs-contrib area,
#                         so removed hardcoded path to hinoproj.pl and
#                         calc_pushbroom_keywords
#           Feb  2 2009 - EHK, Had to hardcode path to calc_pushbroom_keywords
#                         afterall.  Also, deleted the "4Socet" cube file...
#                         it is no longer needed for SS import.
#           Feb  3 2009 - EHK, added creation of STRETCH_PAIRS.lis file
#                         needed for conversion of 8-bit images back to
#                         I/F values.
#           Jun  9 2009 - EHK, made script more portable by checking
#                         if this script was being run on an Astro
#                         machine (by verifying GROUP=flagstaff), before
#                         checking for the ISIS version
#           Jun 25 2009 - EHK, corrected bug/typo
#           Oct 12 2009 - EHK, as of isis3.1.21 no longer need extra backslash
#                         in front of quotation marks, so removed them
#           Oct 08 2010 - EHK renamed output keywords.lis file to follow
#                         the default file names expected by the
#                         USGS_import_pushbroom utility in Socet Set
#           Nov 15 2010 - EHK added calc_pushbroom_keywords_path variable
#           Dec 07 2011 - EHK, added isisversion to documentation
#           May 02 2012 - EHK, added hinoproj_path for easier portability
#                         outside of astrogeology center, and updated
#                         isisversion to isis3.3.1
#           May 15 2012 - EHK, Changed error message to print failed
#                         command to the string....this is more diagnositic
#           May 22 2012 - EHK, updated isisversion to isis3.4.0
#           Jan 09 2013 - EHK, replaced calc_pushbroom_keywords with
#                         socetlinescankeywords; spiceinit with blobs
#                         attached, and removed workarounds
#           Mar 06 2013 - EHK, socetlinescankeywords is now formally in isis
#                         so removed socetlinescankeywords_path, and changed
#                         parameter "pushkey" to "to" (as is the isis
#                         convention for the output file parameter)
#           Mar 12 2013 - EHK,
#                         1) made changes for isis3.4.3
#                         2) added explicit path to getkey so that
#                            this script is portable to external
#                            users that have installed the unix 
#                            version of getkey on their systems
#                         3) moved location-dependent paths to top
#                            of script for ease of editing by external
#                            users
#                         4) updated documentation
#           Sep 17 2024 - Sarah Sutton, Univ. of Arizona (SS),
#                         1) Updated to call hinoproj customized to allow for SYN4 in
#                            HiROC pipelines to replace missing RED4 CCD.
#                         2) Changed lower end of default contrast stretch from
#                            5 percent to 1 percent.
#           Dec 06 2024 - SS, Added trailing slash to HiRISE_ROOT path variable.
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

#   $GROUP = `printenv GROUP`;
#   chomp ($GROUP);
# 
#   if ($GROUP eq "flagstaf")
#      { 
#      $ISISVERSION = `printenv IsisVersion`;
#      chomp ($ISISVERSION);
#      $len = length($ISISVERSION);
#      if ($len == 0)
#         {
#         print "\nISIS VERSION MUST BE ESTABLISHED FIRST...ENTER:\n";
#         print "\nsetisis $isisversion\n\n";
#         exit 1;
#         }
#      }

#---------------------------------------------------------------------
# Get this system's $ISISROOT/bin absolute path to be used for running
# getkey
# --------------------------------------------------------------------

  $ISISROOT_bin_path = `printenv ISISROOT`;
  chomp($ISISROOT_bin_path);
  $ISISROOT_bin_path = $ISISROOT_bin_path . "/bin/";
 
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
# If the hi4socet.prt & "hi4socet.err" files exist, then delete them
#---------------------------------------------------------------------

   if (-e "hi4socet.prt") {unlink("hi4socet.prt");}
   if (-e "hi4socet.err") {unlink("hi4socet.err");}

#---------------------------------------------------------------------
# Open LOG file
#---------------------------------------------------------------------

   $log = "hi4socet.err";
   open (LOG,">$log") or die "\n Cannot open $log\n";

#---------------------------------------------------------------------
# Make sure input list file and matchCube exists
#---------------------------------------------------------------------

   if (!(-e $fromlist))
      {
      print "*** ERROR *** Input list file does not exist: $fromlist\n";
      print "hi4socet.pl will terminate\n";
      exit 1;
      }

   if ($#ARGV == 1 && !(-e $matchCube))
      {
      print "*** ERROR *** Input match Cube does not exist: $matchCube\n";
      print "hi4socet.pl will terminate\n";
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
# If matchCube was not input by user, set it to RED5
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

#---------------------------------------------------------------------
# Following the noproj naming convention, create the noproj'ed mosaic
# name (needed now to base the output keywords.lis file)
#---------------------------------------------------------------------

   $firstdot = index($matchCube,".");
   $core_name = substr($matchCube,0,$firstdot-1);
   $ext = substr($matchCube,$firstdot);
   $cubExt = index($ext,".cub");
   if ($cubExt > 0)
      { $ext2 = substr($ext,0,$cubExt); }
   else
      { $ext2 = $ext; }

   $mosCube = $core_name . "mos_hijitreged" . $ext2 . ".noproj.cub";

#---------------------------------------------------------------------
# Run hinoproj.pl to geneate a mosaic of noproj'ed CCDs
#---------------------------------------------------------------------

    $cmd = "$HiRISE_ROOT"."DTM/hinoproj_HiROC.pl $fromlist $matchCube";         	  
    system($cmd) == 0 || ReportErrAndDie("hinoproj_HiROC.pl failed on command:\n$cmd");

#---------------------------------------------------------------------
# Run socetlinescankeywords to get the SS keyword values
# for the SS USGSAstroLineScanner sensor model
#---------------------------------------------------------------------

   $keyFile = $core_name . "mos_hijitreged_keywords.lis";

    $cmd = "socetlinescankeywords from=$mosCube to=$keyFile";
    system($cmd) == 0 || ReportErrAndDie ("socetlinescankeywords failed on command:\n$cmd");

#---------------------------------------------------------------------
# Convert noproj'ed mosaic to 8-bit
#---------------------------------------------------------------------

   $cmd = "percent from=$mosCube to=p0001.temp.txt percentage=0.01";					  
   system($cmd) == 0 || ReportErrAndDie("percent failed on command:\n$cmd");

   $cmd = "percent from=$mosCube to=p9995.temp.txt percentage=99.95";
   system($cmd) == 0 || ReportErrAndDie("percent failed on command:\n$cmd");

   $min = `$ISISROOT_bin_path/getkey from=p0001.temp.txt grpname=Results keyword=Value`;
   $len = length($min);
   if($len == 0) {
     $cmd = "$ISISROOT_bin_path/getkey from=p0001.temp.txt grpname=Results keyword=Value";
     ReportErrAndDie("getkey failed on command:\n$cmd");
   }
   chomp ($min);

   $max = `$ISISROOT_bin_path/getkey from=p9995.temp.txt grpname=Results keyword=Value`;
   $len = length($max);
   if($len == 0) { 
     $cmd = "$ISISROOT_bin_path/getkey from=p9995.temp.txt grpname=Results keyword=Value";
     ReportErrAndDie("getkey failed on command:\n$cmd");
   }
   chomp ($max);

   $ext = index($mosCube,".cub");
   $core_name = substr($mosCube,0,$ext);
   $byteCube = $core_name . ".8bit.cub";

   if ($min > 0)
      {
      $cmd = "stretch from=$mosCube to=$byteCube+8bit+1:254 pairs=\"0:0 $min:1 $max:254\" lis=1.0 lrs=1.0 his=254 hrs=254";
      }
   else
      {
      $negmin = $min - 1;
      $cmd = "stretch from=$mosCube to=$byteCube+8bit+1:254 pairs=\"$negmin:0 $min:1 $max:254\" lis=1.0 lrs=1.0 his=254 hrs=254";
      }
   system ($cmd) == 0 || ReportErrAndDie("stretch failed on command:\n$cmd");

   unlink("p0001.temp.txt");
   unlink("p9995.temp.txt");

#---------------------------------------------------------------------
#  Create report file for 32-bit to 8-bit stretch pairs
#---------------------------------------------------------------------

   $img_name = substr($core_name,0,15);

   $stretch_file = $img_name . "_STRETCH_PAIRS.lis";

   open (STR,">$stretch_file") or die "\n Cannot open $stretch_file\n";

   print STR "image: $mosCube\n";

   if ($min > 0)
      { print STR "stretch pairs: \"0:0 $min:1 $max:254\"\n"; }
   else
      { print STR "stretch pairs: \"$negmin:0 $min:1 $max:254\"\n"; }

   close STR;

#---------------------------------------------------------------------
# Get raw noproj'ed mosaic for Socet Set
# and delete temporary translated cube
#---------------------------------------------------------------------

   $firstdot = index($byteCube,".");
   $core_name = substr($byteCube,0,$firstdot);
   $rawImg = $core_name . ".raw";

   $cmd = "isis2raw from=$byteCube to=$rawImg bittype=8bit stretch=none";
   system($cmd) == 0 || ReportErrAndDie("isis2raw failed on command:\n$cmd");

#---------------------------------------------------------------------
# Rename print.prt file
#---------------------------------------------------------------------

   rename ("print.prt","hi4socet.prt");

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
      print "\n*** See hinoproj.prt and hi4socet.prt for details ***\n\n";
      }
   else
      {
      unlink ($log);
      }

   exit;

##############################################################################
#  Error Handling Subroutine
##############################################################################
sub ReportErrAndDie
    {
    my $ERROR=shift;

    print "$ERROR\n";
    print "hi4socet.pl aborted\n";

    print LOG "$ERROR\n";
    close(LOG);
    exit 1;
    }


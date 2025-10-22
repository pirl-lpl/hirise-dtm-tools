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

my ($progname) = ($0 =~ m#([^/]+)$#);  # get the name of this program

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

       $progname creates a reconstructed and undistorted COLOR HiRISE image.
       First noproj is run on each input COLOR CCD, using by default CCD RED5
       as the \"match cube \", or the match cube specified by the user.
       After noproj is complete for the input COLOR CCDs, hijitreg is run to
       gather line/sample translations between band 1 of the noproj'ed
       COLOR4 and COLOR5 CCDs.  The results of hijitreg are applied when
       mosaicking the indivdual COLOR CCDs to reconstruct the image - with
       the match cube held.

       Errors encountered in the processing goes to file: \"hicolor_noproj.err\"

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
#  Date:   February 26 2007
#  Version: 1
#  History: MAY 12 2009 - E Howington-Kraus, USGS, Flagstaff Original Version
#                         (a modification of hinoproj.pl)
#           JAN 07 2010 - EHK, changed parameter 'input' to 'priority'
#                         as per changes to handmos in ISIS3.1.21
#           DEC 07 2011 - EHK, added isisversion to documentation	
#           JUL 18 2013 - EHK,
#                         1) made changes for isis3.4.4
#                         2) added explicit path to getkey so that
#                            this script is portable to external
#                            users that have installed the unix 
#                            version of getkey on their systems
#                         3) updated error message to follow current style
#####################################################################

#---------------------------------------------------------------------
# Forces a buffer flush after every print, printf, and write on the
# currently selected output handle.  Let's you see output as it's
# happening.
#---------------------------------------------------------------------
   $| = 1;

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
# If the hicolor_noproj.prt & "hicolor_noproj.err" files exist, then delete them
#---------------------------------------------------------------------

   if (-e "hicolor_noproj.prt") {unlink("hicolor_noproj.prt");}
   if (-e "hicolor_noproj.err") {unlink("hicolor_noproj.err");}

#---------------------------------------------------------------------
# Open LOG file
#---------------------------------------------------------------------

   $log = "hicolor_noproj.err";
   open (LOG,">$log") or die "\n Cannot open $log\n";

#---------------------------------------------------------------------
# Make sure input list file and matchCube exists
#---------------------------------------------------------------------

   if (!(-e $fromlist))
      {
      print "*** ERROR *** Input list file does not exist: $fromlist\n";
      print "hicolor_noproj.pl will terminate\n";
      exit 1;
      }

   if ($#ARGV == 1 && !(-e $matchCube))
      {
      print "*** ERROR *** Input match Cube does not exist: $matchCube\n";
      print "hicolor_noproj.pl will terminate\n";
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
# Make sure in input cubes are 3 band (color) images
#---------------------------------------------------------------------

   open(LST,"<$fromlist");
   while ($input=<LST>)
      {
      chomp($input);

      $bands = `$ISISROOT_bin_path/getkey from=$input grpname=Dimensions keyword=Bands`;
      chomp ($bands);
      $len = length($bands);
      if($len == 0) {
        $cmd = "$ISISROOT_bin_path/getkey from=$input grpname=Dimensions keyword=Bands";
        ReportErrAndDie("getkey failed on command:\n$cmd");
      }

      if ($bands != 3) { ReportErrAndDie("$input is not a COLOR cube"); }
      }

   close(LST);

#---------------------------------------------------------------------
# If matchCube was not input by user, set it to RED5
# Otherwise, get the CCD # of the matchCube input by the user
#---------------------------------------------------------------------

   if ($#ARGV == 0)
      {
      open(LST,"<$fromlist");
      $matchCube = " ";

      while ($matchCube eq " ")
         {
         $input=<LST>;
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
            $matchCubeCCD = 5;
            }
         }
      }
   else
      {
      $CCD = `$ISISROOT_bin_path/getkey from=$matchCube grpname=Instrument keyword=CcdId`;
      chomp ($CCD);

      $len = length($CCD);
      if($len == 0) {
        $cmd = "$ISISROOT_bin_path/getkey from=$matchCube grpname=Instrument keyword=CcdId";
        ReportErrAndDie("getkey failed on command:\n$cmd");
      }

      $len--;
      $matchCubeCCD = substr($CCD,$len,1);
      }

   if ($matchcube eq " ")
      {
      print "*** ERROR *** Input list file does not contain a RED5 CCD\n";
      print "              Rerun hicolor_noproj with your desired match cube\n";
      print "              supplied at the command line.\n";
      print "hicolor_noproj.pl terminated\n";
      exit 1;
      }

   close(LST);

#---------------------------------------------------------------------
# Generate noproj'ed cubes by
#    1) spiceinit, with blobs
#    2) spicefit
#    3) noproj, using the matchCube determined above
#    4) mosaic RED noproj'ed CCDs using hijitreg to fine-tune CCD placement
#
# Along the way, temporary files are deleted
#---------------------------------------------------------------------

   #Run spiceinit and spicefit on matchCube first so that it can be used
   #as the noproj match cube for the other CCD

   $cmd = "spiceinit FROM=$matchCube attach=yes";
   system($cmd) == 0 || ReportErrAndDie("spiceinit failed on command:\n$cmd");

   $cmd = "spicefit FROM=$matchCube";
   system($cmd) == 0 || ReportErrAndDie("spicefit failed on command:\n$cmd");

   open(LST,"<$fromlist");
   while ($input=<LST>)
      {
      chomp($input);

      $cubExt = index($input,".cub");
      if ($cubExt > 0)
         { $core_name = substr($input,0,$cubExt); }
      else
         { $core_name = $input; }

      $noprojCube = $core_name . ".noproj.cub";
      print NOPROJLST "$noprojCube\n";

      if ($input eq $matchCube)
         {
         # We already ran spiceinit and spicefit, just need to save
         # corresponding noprojCube name.
         $matchCubeNoproj = $noprojCube;
         }
      else
         {
         $cmd = "spiceinit FROM=$input attach=yes";
         system($cmd) == 0 || ReportErrAndDie("spiceinit failed on command:\n$cmd");

         $cmd = "spicefit FROM=$input";
         system($cmd) == 0 || ReportErrAndDie("spiceinit failed on command:\n$cmd");
         }

      $source="frommatch";
      $cmd = "noproj from=$input match=$matchCube to=$noprojCube source=$source interp=bilinear";
      system($cmd) == 0 || ReportErrAndDie("noproj failed on command:\n$cmd");
      }

   close(LST);

#---------------------------------------------------------------------
# Run Hijigreg on band 1 of the noproj'ed CCDs to calculate line/samp
# translations to be applied during mosaic
#---------------------------------------------------------------------

   # Split noproj'ed cubes naming convention between core_name (minus
   # the actual CCD#) and the series of extensions.
   $firstdot = index($noprojCube,".");
   $core_name = substr($noprojCube,0,$firstdot-1);
   $ext = substr($noprojCube,$firstdot);

   $from= $core_name . "4" . $ext ."+2";

   $match = $core_name . "5" . $ext ."+2";

   $flat = "flat_color.f4m5.txt";

   $cmd = "hijitreg from=$from match=$match flatfile=$flat";
   system($cmd) == 0 || ReportErrAndDie("hijitreg failed on command:\n$cmd");

   $avgSampOffset = `grep \"Average Sample Offset\" $flat | awk '{print \$5}'`;
   $avgLineOffset = `grep \"Average Line Offset\" $flat | awk '{print \$5}'`;
   chomp ($avgSampOffset);
   chomp ($avgLineOffset);

   # set the Line and sample translation to (rounded) integer values
   # of the offsets calculated by hijitreg
   $ST = sprintf("%.0f",$avgSampOffset);
   $LT = sprintf("%.0f",$avgLineOffset);

#   unlink ($flat);

#---------------------------------------------------------------------
# Mosaic the noproj'ed CCDs by holding the matchCubeCCD and applying
# the line/sample translation to the other CCD.  Individual  noproj'ed
# CCDs are along the way.
#---------------------------------------------------------------------

   # Remove .cub from series of extensions, then generate mosaic name
   $len = length($ext);
   $ext2 = substr($ext,0,$len-4);
   $mosCube = $core_name . "mos_hijitreged" . $ext2 . ".cub";

   # rename the noproj'ed matchCube to mosCube so as to maintain label
   # info (and skip the need to run getkey for number of lines and samps
   # when creating an output cube via handmos)
   rename ($matchCubeNoproj,$mosCube);

   # Now mosaic the remaining CCD
   $SSM = 1;
   $SLM = 1;
   if ($matchCubeCCD == 5)
      {
      $from= $core_name . "4" . $ext;
      $SSM = $SSM + $ST;
      $SLM = $SLM + $LT;
      $cmd = "handmos from=$from mosaic=$mosCube outsample=$SSM outline=$SLM outband=1 priority=beneath";
      system($cmd) == 0 || ReportErrAndDie("handmos failed on command:\n$cmd");

      unlink ($from);
      }
   else
      {
      $from= $core_name . "5" . $ext;
      $SSM = $SSM - $ST;
      $SLM = $SLM - $LT;
      $cmd = "handmos from=$from mosaic=$mosCube outsample=$SSM outline=$SLM outband=1 priority=beneath";
      system($cmd) == 0 || ReportErrAndDie("handmos failed on command:\n$cmd");

      unlink ($from);
      }

#---------------------------------------------------------------------
# Rename print.prt file
#---------------------------------------------------------------------

   rename ("print.prt","hicolor_noproj.prt");

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
      print "\n*** See hicolor_noproj.prt for details ***\n\n";
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
    print "hicolor_noproj.pl aborted\n";

    print LOG "$ERROR\n";
    close(LOG);
    exit 1;
    }


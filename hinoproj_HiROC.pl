#!/usr/bin/perl -s

my ($progname) = ($0 =~ m#([^/]+)$#);  # get the name of this program

$email = "ssutton\@lpl.arizona.edu";

$isisversion = "isis6.0.0";  # Tested under ISIS v6.0.0

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

       *******************************************************************
       *** The fromlist can contain RED, BG and IR filtered CCDs,      ***
       *** however, the RED CCD images must be listed last in the list ***
       *******************************************************************

       matchCube = Optional user selection of CCD in fromlist to set as
       the \"match cube\".  This CCD is used as the match cube when running
       noproj, and is held in the output noproj mosaic when fine-tuning 
       placement of the noproj'ed CCDs via hijitreg.  The default is RED5.


Description:

       $progname creates a reconstructed and undistorted RED HiRISE image.
       First noproj is run on each input CCD, using by default CCD RED5
       as the \"match cube \", or the match cube specified by the user.
       After noproj is complete for all input CCDs, hijitreg is run to
       gather line/sample translations between noproj'ed CCDs.  The results
       of hijitreg are applied when mosaicking the indivdual CCDs to
       reconstruct the image - with the match cube held.

       Errors encountered in the processing goes to file: \"hinoproj.err\"

**************************************************************************
**************************************************************************
NOTICE:
       NOTE: $progname runs under isis version: $isisversion
       This script is not supported by ISIS.
       If you have problems please contact Sarah Sutton
       at $email 
**************************************************************************
**************************************************************************

";

#####################################################################
#  MAIN APPLICATION SECTION
#  Author: Elpitha Howington-Kraus
#  Version: 2.0
#  History: Feb 26 2007 - E Howington-Kraus, USGS, Flagstaff Original Version
#           Apr 25 2007 - EHK Modified to
#				1) also noproj IR and BG CCDs, but not
#				   include them in the hijitreg and
#				   mosaicing process because hijitreg
#				   only works on RED noproj'ed CCDs
#				2) process a subset of RED CCDs
#                               3) run hijitreg out of the ISIS system area
#                                  (the needed version is in ISIS3.1.11+)
#                               4) keep the flat files output by hijitreg
#	    May 18 2007 - EHK Modified to use system default shape model (i.e.
#			      mola) when running spiceinit rather than the
#			      ellipsoid.
#			         (1) There should be little difference in the
#				     noproj output using mola vs the ellipsoid.
#                                    (Using mola won't remove height info as
#                                    in orthorectified products)
#                                (2) The a-priori pointing may be more
#                                    accurate in SS when relative to mola
#                                    surface.
#			         (3) However, we may see some issues in the
#                                    poles because of the flight track...can
#                                    really only tell by testing.
#           Sep 14 2007 - EHK Added source=frommatch when running noproj
#                         because the default (source=frommatch) is not
#                         adhere'ed to (as is evidenced in the print.prt file)
#           Jul 15 2008 - EHK Updated handmos command as per changes in
#                         ISIS3.1.16
#           Nov 13 2008 - Added a subroutine for error handling.  It will 
#                         report an error and then terminate further processing.
#           Dec  4 2008 - Changed noproj to use bilinear interpolation rather
#                         than cubic convolution (to avoid potential nulled
#                         pixels).
#           Oct 12 2009 - EHK, Updated call to handmos as per changes in
#                         isis3.1.21
#           Dec 07 2011 - EHK, added isisversion to documentation	
#           May 02 2011 - EHK, updated isisversion to isis3.3.1
#           May 15 2012 - EHK, Changed error message to print failed
#                         command to the string....this is more diagnositic
#           Mar 12 2013 - EHK,
#                         1) made changes for isis3.4.3
#                         2) added explicit path to getkey so that
#                            this script is portable to external
#                            users that have installed the unix 
#                            version of getkey on their systems
#                         3) updated documentation
#           Sep 17 2024 - Sarah Sutton, University of Arizona (SS)
#                         Updated ISIS version to 6.0.0
#                         Updated to accommodate replacing RED4 with IR10 (SYN4) in
#                         HiROC pipelines.
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
# If the hinoproj.prt & "hinoproj.err" files exist, then delete them
#---------------------------------------------------------------------

   if (-e "hinoproj.prt") {unlink("hinoproj.prt");}
   if (-e "hinoproj.err") {unlink("hinoproj.err");}

#---------------------------------------------------------------------
# Open LOG file
#---------------------------------------------------------------------

   $log = "hinoproj.err";
   open (LOG,">$log") or die "\n Cannot open $log\n";

#---------------------------------------------------------------------
# Make sure input list file and matchCube exists
#---------------------------------------------------------------------

   if (!(-e $fromlist))
      {
      print "*** ERROR *** Input list file does not exist: $fromlist\n";
      print "hinoproj.pl will terminate\n";
      exit 1;
      }

   if ($#ARGV == 1 && !(-e $matchCube))
      {
      print "*** ERROR *** Input match Cube does not exist: $matchCube\n";
      print "hinoproj.pl will terminate\n";
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
      print "              Rerun hinoproj with your desired match cube\n";
      print "              supplied at the command line.\n";
      print "hinoproj.pl terminated\n";
      exit 1;
      }

   close(LST);

#---------------------------------------------------------------------
# Determine the range of input RED CCDs
#---------------------------------------------------------------------

   $MinRedCCD = 99;
   $MaxRedCCD = -99;

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

      $filter = substr($CCD,0,2);
      if ($filter eq "RE" || $filter eq "IR")			
         {
         $CCDnum = substr($CCD,3,1);
         if ($filter eq "IR" && $CCDnum == 0)
            {
            $CCDnum = 4;
            }
         if ($CCDnum < $MinRedCCD) {$MinRedCCD = $CCDnum;}
         if ($CCDnum > $MaxRedCCD) {$MaxRedCCD = $CCDnum;}
         }
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
   #as the noproj match cube for all CCDs

   $cmd = "spiceinit FROM=$matchCube attach=yes ";
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
      #print NOPROJLST "$noprojCube\n";					# not used?

      if ($input eq $matchCube)
         {
         # We already ran spiceinit and spicefit, just need to save
         # corresponding noprojCube name.
         $matchCubeNoproj = $noprojCube;
         }
      else
         {
         $cmd = "spiceinit FROM=$input attach=yes ";
         system($cmd) == 0 || ReportErrAndDie("spiceinit failed on command:\n$cmd");  			

         $cmd = "spicefit FROM=$input";
         system($cmd) == 0 || ReportErrAndDie("spiceinit failed on command:\n$cmd");  			
        
         #$matchCubeNoproj = $noprojCube;				# is this a bug? It seems to take the last cube in the fromlist and declare it the "match noproj cube"

         }

      $source="frommatch";
      $cmd = "noproj from=$input match=$matchCube to=$noprojCube source=$source interp=bilinear";  
      system($cmd) == 0 || ReportErrAndDie("noproj failed on command:\n$cmd");			    		
      }

   close(LST);


#---------------------------------------------------------------------
# If using SYN4, copy the SYN4 noproj cube and rename it RED4.								
#---------------------------------------------------------------------
   open(LST,"<$fromlist");
   while ($input=<LST>) {
   
   chomp($input);
   
   	if ($input =~ m/SYN/) {
    print STDOUT "There is a SYN4 cube present: $SYNcube\n";
    
   $firstdot = index($input,".");
   $core_name = substr($input,0,$firstdot-4);
   $ext = ".balance.noproj.cub";
  
  	my $SYNbalance = substr($input,0,$firstdot);
  	my $SYNnoproj = $SYNbalance . $ext;
 
    my $RED4noproj = $core_name . "RED4" . $ext;
    print STDOUT "Copying $SYNnoproj to $RED4noproj\n";

    $cmd = "cp $SYNnoproj $RED4noproj";
    system($cmd) == 0 || ReportErrAndDie("failed on command:\n$cmd");

    }
}
   close(LST);


#---------------------------------------------------------------------
# Run Hijitreg on adjacent noproj'ed CCDs to calculate line/samp
# translations to be applied during mosaic
#---------------------------------------------------------------------

   # Intialize LineTranslation and SampleTranslation arrays (for RED CCDs)
   @LT=(0,0,0,0,0,0,0,0,0,0);
   @ST=(0,0,0,0,0,0,0,0,0,0);

   # Split noproj'ed cubes naming convention between core_name (minus
   # the actual CCD#) and the series of extensions.
   $firstdot = index($noprojCube,".");
   $core_name = substr($noprojCube,0,$firstdot-4);								
   $ext = substr($noprojCube,$firstdot);

   for ($fromCCD=$MinRedCCD; $fromCCD<=$MaxRedCCD-1; $fromCCD++)
      {
      $from= $core_name . "RED" . $fromCCD . $ext;								
      
      $matchCCD = $fromCCD + 1;
      $match = $core_name . "RED" . $matchCCD . $ext;							

      $flat = "flat.f" . $fromCCD . "m" . $matchCCD . ".txt";

      $cmd = "hijitreg from=$from match=$match flatfile=$flat";
      print STDOUT "\n$cmd\n";
      system($cmd) == 0 || ReportErrAndDie("hijitreg failed on command:\n$cmd");			

      $avgSampOffset = `grep \"Average Sample Offset\" $flat | awk '{print \$5}'`;
      $avgLineOffset = `grep \"Average Line Offset\" $flat | awk '{print \$5}'`;
      chomp ($avgSampOffset);
      chomp ($avgLineOffset);
      
      # If the channel that would be the overlap for hijitreg is missing, replace NULL offsets with 0 values.
      if ($avgSampOffset eq "NULL") {
          $avgSampOffset = 0;
          }
      if ($avgLineOffset eq "NULL") {
          $avgLineOffset = 0;
          }

      #fill Line and sample translation arrays with (rounded) integer values
      #of the offsets calculated by hijitreg
      if ($fromCCD < $matchCubeCCD)
         {
         @ST[$fromCCD] = sprintf("%.0f",$avgSampOffset);
         @LT[$fromCCD] = sprintf("%.0f",$avgLineOffset);
         }
      else
         {
         @ST[$matchCCD] = sprintf("%.0f",$avgSampOffset);
         @LT[$matchCCD] = sprintf("%.0f",$avgLineOffset);
         }

###      unlink ($flat);
      }

#---------------------------------------------------------------------
# Mosaic the noproj'ed RED CCDs starting with the matchCCD and filling
# to the left, then filling to the right of the matchCCD...applying
# line and sample translations, and deleting individual noproj'ed
# CCDs along the way.
#---------------------------------------------------------------------

   # Remove .cub from series of extensions, then generate mosaic name
   $len = length($ext);
   $ext2 = substr($ext,0,$len-4);
   $mosCube = $core_name . "REDmos_hijitreged" . $ext2 . ".cub";				

print STDOUT "Core name $core_name\n";
print STDOUT "Moscube name $mosCube\n";

   # rename the noproj'ed matchCube to mosCube so as to maintain label
   # info (and skip the need to run getkey for number of lines and samps
   # when creating an output cube via handmos)
#   rename ($matchCubeNoproj,$mosCube);			# Replaced Perl rename with system cp - SS
	$cmd = "cp $matchCubeNoproj $mosCube";
	system($cmd) == 0 || ReportErrAndDie("Failed on command:\n$cmd");


   # Now mosaic CCDs from matchCCD to MinRedCCD
   $SSM = 1;
   $SLM = 1;
   for ($fromCCD=$matchCubeCCD-1; $fromCCD>=$MinRedCCD; $fromCCD--)
      {
      $from= $core_name . "RED" . $fromCCD . $ext;								
      $SSM = $SSM + @ST[$fromCCD];
      $SLM = $SLM + @LT[$fromCCD];
      $cmd = "handmos from=$from mosaic=$mosCube outsample=$SSM outline=$SLM outband=1 priority=beneath";
      system($cmd) == 0 || ReportErrAndDie("handmos failed on command:\n$cmd");

      unlink ($from);				
      }

   # Now mosaic CCDs from matchCCD to MaxRedCCD
   $SSM = 1;
   $SLM = 1;
   for ($fromCCD=$matchCubeCCD+1; $fromCCD<=$MaxRedCCD; $fromCCD++)
      {
      $from= $core_name . "RED" . $fromCCD . $ext;								
      $SSM = $SSM - @ST[$fromCCD];
      $SLM = $SLM - @LT[$fromCCD];
      $cmd = "handmos from=$from mosaic=$mosCube outsample=$SSM outline=$SLM outband=1 priority=beneath";
      system($cmd) == 0 || ReportErrAndDie("handmos failed on command:\n$cmd");

      unlink ($from);									
      }

#---------------------------------------------------------------------
# Rename print.prt file
#---------------------------------------------------------------------

   rename ("print.prt","hinoproj.prt");

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
      print "\n*** See hinoproj.prt for details ***\n\n";
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
    print "hinoproj.pl aborted\n";

    print LOG "$ERROR\n";
    close(LOG);
    exit 1;
    }


#!/usr/bin/perl
use File::Copy;

print "INSTALLATION SCRIPT FOR DROIDS v3.0 DEBIAN and R PACKAGE DEPENDENCIES\n";
sleep(2);

print "DROIDS v3.0 main dependencies also include Amber16/18, R, and UCSF Chimera on a Debian\n";
print "system Linux build or virtual machine with one or two dedicated Nvidia GPUs + CUDA 9.0\n";
print "NOTE: avoid CUDA 7.0 and CUDA 10.0+ with Amber\n";
print "Use the AMBER_installer.pl script to intall these first\n";
print "DROIDS-3.0.tar.gz (is free from our website (proteindynamics.net) or GitHub repo)\n";
sleep(2);


print "Please answer the following questions about your VM instance or Linux system\n";
sleep(1);

print "\nEnter your admin user name for this computer or VM\n\n";
  $UserName = <STDIN>; 
  chop($UserName);

print "\nEnter chimera version you use or plan to install here (e.g. '1.11' or '1.13')\n\n";
  $ChimeraName = <STDIN>; 
  chop($ChimeraName);


sleep(1); print "\nchecking perl version - looking for Perl 5.0\n\n"; system('perl -v'); sleep(1);

#install Perl modules
sleep(1); print "\ninstalling perl modules\n\n"; sleep(1);system('sudo cpan App::cpanminus'); system ('sudo apt install cpanminus'); system('sudo cpanm Statistics::Descriptive'); sleep(1);

# install and update Debian packages
sleep(1); print "\nchecking Debian packages\n\n"; sleep(1);
print "\nDo you need to install the xfce4 desktop, xrdp, and VNC? (y/n) (this is only needed for Google Cloud VM instance)?\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "y" || $yn eq "Y" || $yn eq "yes"){sleep(1); print "\ninstalling xrdp and xfce4 desktop\n\n"; sleep(1); system('sudo apt-get install xrdp xfce4'); sleep(1);}
if($yn eq "y" || $yn eq "Y" || $yn eq "yes"){sleep(1); print "\ninstalling VNC\n\n"; sleep(1); system('sudo apt install tightvncserver'); sleep(1);}
sleep(1); print "\ninstalling htop\n\n"; sleep(1); system('sudo apt-get install htop'); sleep(1);
sleep(1); print "\ninstalling gedit\n\n"; sleep(1); system('sudo apt-get install gedit'); sleep(1);
sleep(1); print "\ninstalling gdebi\n\n"; sleep(1); system('sudo apt-get install gdebi'); sleep(1);
sleep(1); print "\ninstalling gparted\n\n"; sleep(1); system('sudo apt-get install gparted'); sleep(1);
sleep(1); print "\ninstalling vokoscreen\n\n"; sleep(1); system('sudo apt-get install vokoscreen'); sleep(1);
sleep(1); print "\ninstalling evince\n\n"; sleep(1); system('sudo apt-get install evince'); sleep(1);
sleep(1); print "\ninstalling grace\n\n"; sleep(1); system('sudo apt-get install grace'); sleep(1);
sleep(1); print "\ninstalling perl-tk\n\n"; sleep(1); system('sudo apt-get install perl-tk'); sleep(1);
sleep(1); print "\ninstalling python-tk\n\n"; sleep(1); system('sudo apt-get install python-tk'); sleep(1);
sleep(1); print "\ninstalling python-gi\n\n"; sleep(1); system('sudo apt-get install python-gi'); sleep(1);
sleep(1); print "\ninstalling python-kivy\n\n"; sleep(1); system('sudo apt-get install python-kivy'); sleep(1);
sleep(1); print "\ninstalling gstreamer\n\n"; sleep(1); system('sudo apt-get install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio'); sleep(1);
sleep(1); print "\ninstalling steam and VR dependencies\n\n"; sleep(1); system('sudo apt-get install steam steam-devices libvulkan1'); sleep(1);
#sleep(1); print "\ninstalling Amber dependencies\n\n"; sleep(1); system('sudo apt-get install csh flex patch gfortran g++ make xorg-dev bison libbz2-dev'); sleep(1);
sleep(1); print "\nrunning updates\n\n"; sleep(1); system('sudo apt-get update'); sleep(1);

# check R installation
sleep(1); print "\ninstalling R\n\n"; sleep(1); system('sudo apt-get install r-base-core r-base r-base-dev'); sleep(1);
sleep(1); print "\ninstalling R and R packages\n\n";

sleep(1); print "\ninstalling some R packages  (type 'y' if this hangs)\n\n";
print "\nIf script fails here, open terminal and install R (sudo apt-get install r-base-core r-base r-base-dev) then type 'R' at command line, then 'install.packages('package name') ...names = ggplot2 gridExtra dplyr caret FNN e1071 kernlab class MASS ada randomForest CCA CCP doParallel foreach rpsychi...then 'q()'\n\n";

#install R and R packages
open (Rinput, "| R --vanilla")||die "could not start R command line\n";
print Rinput "chooseCRANmirror(graphics = getOption('menu.graphics'), ind = 81, local.only = TRUE)\n";
print Rinput "install.packages('ggplot2')\n";
print Rinput "install.packages('gridExtra')\n";
print Rinput "install.packages('dplyr')\n";
print Rinput "install.packages('caret')\n";
print Rinput "install.packages('FNN')\n";
print Rinput "install.packages('e1071')\n";
print Rinput "install.packages('kernlab')\n";
print Rinput "install.packages('class')\n";
print Rinput "install.packages('MASS')\n";
print Rinput "install.packages('ada')\n";
print Rinput "install.packages('randomForest')\n";
print Rinput "install.packages('CCA')\n";
print Rinput "install.packages('CCP')\n";
print Rinput "install.packages('doParallel')\n";
print Rinput "install.packages('foreach')\n";
print Rinput "install.packages('rpsychi')\n";
# load some libraries to check installation
print Rinput "library(ggplot2)\n";
print Rinput "library(gridExtra)\n";
print Rinput "library(lattice)\n";
print Rinput "library(FNN)\n";
print Rinput "library(MASS)\n";
print Rinput "library(CCA)\n";
print Rinput "library(CCP)\n";
print Rinput "library(e1071)\n";
print Rinput "library(kernlab)\n";
print Rinput "library(class)\n";
print Rinput "library(caret)\n";
print Rinput "library(dplyr)\n";
print Rinput "library(ada)\n";
print Rinput "library(randomForest)\n";
print Rinput "library(parallel)\n";
print Rinput "library(foreach)\n";
print Rinput "library(doParallel)\n";
print Rinput "library(rpsychi)\n";
# write to output file and quit R
print Rinput "q()\n";# quit R 
print Rinput "n\n";# save workspace image?
close Rinput;
print "\n\n";

#unzip and move DROIDS
sleep(1); print "\nlooking for DROIDS-3.0.tar.gz folder on desktop (rename download file if needed)\n\n"; sleep(1);
print "\nAre you ready? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;} 
$Dname = 'DROIDS-3.0.tar.gz'; 
sleep(1); print "\nunzipping DROIDS\n\n"; sleep(1); system('tar xvzf '.$Dname); sleep(1);

# find chimera paths
sleep(1); print "\nlocating paths to steam, chimera and chimerax\n";
sleep(1); system ('which steam');
sleep(1); system ('locate /bin/ChimeraX | egrep ./ | grep bin');
sleep(1); system ('locate /bin/chimera | egrep ./ | grep bin');
# create paths.ctl
sleep(1); print "\ncreating paths.ctl file\n";
open (PTH, ">"."paths.ctl" || die "could not create paths.ctl file\n");
print PTH "amber_path	/home/$UserName/Desktop/amber18/	# path to amber home folder\n";
print PTH "chimera_path	~/.local/UCSF-Chimera64-$ChimeraName/bin/	# path to Chimera executable\n";
print PTH "chimerax_path	/home/$UserName/Desktop/chimerax-2019.01.19/bin/	# path to ChimeraX executable\n";
print PTH "teleap_path	/home/$UserName/Desktop/amber18/dat/leap/cmd/	# path to teLeap force field folder\n";
print PTH "steam_path	/usr/bin/steam 	# path to steam executable\n";
print "\ndouble check Chimera working paths and version numbers in paths.ctl file, edit if needed, then copy it manually into your DROIDS folder\n\n"; 
print "\nDO NOT INCLUDE FILENAME FOR EXECUTABLE IN THE PATH\n"; sleep(2);

system ('gedit paths.ctl');
print "\n\nDROIDS v3.0 INSTALLATION COMPLETE\n\n";

print "\n(optional) to install md4vr, remove md4vr.zip from DROIDS folder to desktop and unzip\n";
print "make sure steamOS and steamVR are working correctly,then follow README\n\n";

exit;  



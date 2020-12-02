#!/usr/bin/perl
use File::Copy;

print "INSTALLATION SCRIPT FOR AMBER 16/18 and OpenMM and UCSF Chimera\n";
sleep(2);

print "DROIDS v3.0 main dependencies include Amber16/18, R, and UCSF Chimera on a Debian\n";
print "system Linux build or virtual machine with one or two dedicated Nvidia GPUs + CUDA 9.0\n";
print "NOTE: avoid CUDA 7.0 with Amber\n";
sleep(2);

print "You will need the following file\n";
print "Amber18.tar.gz (licensed from https://ambermd.org/)\n";
print "openMM can be used as alternative (free from https://openmm.org/)\n";
print "AmberTools18.tar.gz or AmberTools19.tar.gz (free from https://ambermd.org/)\n";
print "chimera-1.14-linux_x86_64 or preferred version (free from https://www.cgl.ucsf.edu/chimera/)\n";
print "Modeller .deb folder (e.g. modeller_9.20-1_amd64.deb from https://salilab.org/modeller/)";
print "\n\nDo you need to open web links to these programs?\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "y" || $yn eq "Y" || $yn eq "yes"){
sleep(1);
system('xdg-open http://ambermd.org/'); sleep(1);
system('xdg-open https://www.cgl.ucsf.edu/chimera/'); sleep(1);
system('xdg-open https://salilab.org/modeller/'); sleep(1);
print "you might also like ChimeraX (chimerax-daily.deb) for VR application\n\n";
system('xdg-open https://www.rbvi.ucsf.edu/chimerax/'); sleep(1);
};
sleep(1);
print "Please answer the following questions about your VM instance or Linux system\n";
sleep(1);

print "\nIs MD software and UCSF Chimera already installed on your system? (e.g. 'yes','y' or 'n','no')\n\n";
  $skipping = <STDIN>; 
  chop($skipping);
  
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
sleep(1); print "\ninstalling Amber dependencies\n\n"; sleep(1); system('sudo apt-get install csh flex patch gfortran g++ make xorg-dev bison libbz2-dev'); sleep(1);
sleep(1); print "\nrunning updates\n\n"; sleep(1); system('sudo apt-get update'); sleep(1);

# skip Amber install option
if($skipping eq "y" || $skipping eq "Y" || $skipping eq "yes"){print "\n amber installation skipped\n\n"; goto Askip;}

sleep(1); print "\nyou should have tar.bz2 versions of Ambertools18/19 and Amber18 on desktop\n\n"; 
sleep(1); print "\ninstalling AmberTools18\n\n";
print "\nAre you using AmberTools 18 or 19? (type '18 or '19')\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "19"){sleep(1); print "\nunzipping ambertools\n\n"; sleep(1); system('tar jxvf AmberTools19.tar.bz2'); sleep(1);}
if($yn eq "18"){sleep(1); print "\nunzipping ambertools\n\n"; sleep(1); system('tar jxvf AmberTools18.tar.bz2'); sleep(1);}
system('export AMBERHOME=/home/'.$UserName.'/Desktop/amber18');
system('gnome-terminal');
sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
print "cd amber18\n";
print "./configure -noX11 gnu\n";
print "make install\n";
#print "make test\n\n";
sleep(1); print "\nWhen AmberTools is installed, close secondary terminal\n\n"; sleep(1);
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

# update AMBERHOME on bashrc
sleep(1); print "\nupdating bashrc file\n"; sleep(1);
sleep(1); print "\nyou need to add the following lines to the bashrc file\n\n"; sleep(1);
print "source /home/".$UserName."/Desktop/amber18/amber.sh\n";
print "export AMBERHOME=/home/".$UserName."/Desktop/amber18\n";
print "export PATH="."\$PATH:"."\$AMBERHOME/bin\n";
#print "test -f /home/(host name)/Desktop/amber18/amber.sh\n";
system('gedit ~/.bashrc');
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

# run tests on AmberTools
#system('gnome-terminal');
#sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
#print "cd amber18\n";
#print "make test\n\n";
#sleep(1); print "\nWhen AmberTools is done testing, close secondary terminal\n\n"; sleep(1);
#print "\nAre you ready to continue? (y/n)\n\n";
#  $yn = <STDIN>; 
#  chop($yn);
#if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

# install CUDA
print "\nIs CUDA and cuda toolkit already installed? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "y" || $yn eq "Y" || $yn eq "yes"){print "\n CUDA installation skipped\n\n"; goto CDskip;}
#install cuda
sleep(1); print "\ninstalling cuda tool kit\n\n"; sleep(1); system('sudo apt install nvidia-cuda-toolkit'); sleep(1);
sleep(1); print "\nyou will need to download Linux .deb version of CUDA\n\n"; sleep(1); 
sleep(1); print "\nIMPORTANT NOTE: double check Amber webpage for supported CUDA versions (avoid CUDA 7.0)\n\n";
print "/nDo you want to open CUDA download webpages (y/n)\n";
$yn = <STDIN>; 
  chop($yn);
if($yn eq "y" || $yn eq "Y"){system('xdg-open https://developer.nvidia.com/cuda-toolkit-archive'); sleep(1);}

# install CUDA
system('gnome-terminal');
sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
print "sudo dpkg -i '.deb package name'\n";
print "sudo apt-get update\n";
print "sudo apt-get install cuda\n\n";
print "\ninstall patches manually if needed\n";
print "\nNOTE: double check that the downloaded .deb file permissions allow executable\n\n";
sleep(1); print "\nWhen CUDA is installed, close secondary terminal\n\n"; sleep(1);
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}
CDskip:

# update cuda home
sleep(1); print "\nupdating bashrc file\n"; sleep(1);
print "\nyou need to add the following lines to the bashrc file\n\n";
print "export CUDA_HOME=/usr/local/cuda-(version e.g. 9.0)\n";
print "export PATH=\$CUDA_HOME/bin:/usr/local/cuda-(version e.g. 9.0)/bin:\$PATH\n";
print "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\${AMBERHOME}/lib:\$CUDA_HOME/lib64:\$CUDA_H\$\n";
print "test -f /home/".$UserName."/Desktop/amber18/amber.sh  && source /home/".$UserName."/Desktop/amber18/amber.sh \n";
system('gedit ~/.bashrc');
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

print "\nDo you want to skip installing licensed version of Amber16/18 (i.e. pmemd.cuda) on your system? (e.g. 'yes','y' or 'n','no')\n\n";
  $skipping_amber = <STDIN>; 
  chop($skipping_amber);
# skip Amber install option
if($skipping_amber eq "y" || $skipping_amber eq "Y" || $skipping_amber eq "yes"){print "\n amber installation skipped\n\n"; goto Askip;}
# install Amber18
sleep(1); print "\ninstalling Amber18 (pmemd.cuda)\n\n";
sleep(1); print "\nchecking nvcc and c compilers\n\n"; sleep(1);
system('nvcc -V');
system('gcc --version');
sleep(1);
sleep(1); print "\nunzipping amber18\n\n"; sleep(1); system('tar jxvf Amber18.tar.bz2'); sleep(1);
system('gnome-terminal');
sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
print "cd amber18\n";
print "./configure -cuda gnu\n";
print "make install\n";
print "make test\n\n";

print "\nNOTE: if gcc compilers are too recent and 'make install' fails\n\n"; sleep(1);
print "sudo apt-get install gcc-5 g++-5 gfortran-5\n";
print "sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5 --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-5\n";
print "sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 40 --slave /usr/bin/g++ g++ /usr/bin/g++-7 --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-7 \n";
print "sudo update-alternatives --config gcc\n";

sleep(1); print "\nWhen Amber18 is installed, close second terminal\n\n"; sleep(1);
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

# copy and duplicate pmemd.cuda
sleep(1); print "copying and duplicating pmemd.cuda for dual GPUs\n"; sleep(1); 
copy("./amber18/bin/pmemd.cuda_SPFP", "./amber18/bin/pmemd0.cuda_SPFP")||die "could not find and copy pmemd.cuda\n";
copy("./amber18/bin/pmemd.cuda_SPFP", "./amber18/bin/pmemd1.cuda_SPFP")||die "could not find and copy pmemd.cuda\n";
copy("./amber18/bin/pmemd.cuda_DPFP", "./amber18/bin/pmemd0.cuda_DPFP")||die "could not find and copy pmemd.cuda\n";
copy("./amber18/bin/pmemd.cuda_DPFP", "./amber18/bin/pmemd1.cuda_DPFP")||die "could not find and copy pmemd.cuda\n";
system('chmod +x ./amber18/bin/pmemd0.cuda_SPFP');
system('chmod +x ./amber18/bin/pmemd1.cuda_SPFP');
system('chmod +x ./amber18/bin/pmemd0.cuda_DPFP');
system('chmod +x ./amber18/bin/pmemd1.cuda_DPFP');
Askip: # skip Amber install option

print "\nDo you want to install OpenMM on your system? (e.g. 'yes','y' or 'n','no')\n\n";
  $skipping_openmm = <STDIN>; 
  chop($skipping_openmm);
if($skipping_openmm eq "y" || $skipping_openmm eq "Y" || $skipping_openmm eq 'yes'){print "\n OpenMM installations skipped\n\n"; goto Oskip;}
sleep(1); print "\ninstalling OpenMM\n\n"; sleep(1); 
system('gnome-terminal');
sleep(1); print "\nmake sure miniconda is installed first (https://docs.conda.io/en/latest/miniconda.html)\n\n"; sleep(1);
sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
print "conda install -c omnia/label/cuda90 -c conda-forge openmm\n";
print "python -m simtk.testInstallation\n";
print "conda config --set auto_activate_base false\n";
sleep(1); print "\nWhen OpenMM is installed, close secondary terminal\n\n"; sleep(1);
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}
Oskip: # skip OpenMM install option

if($skipping eq "y" || $skipping eq "Y" || $skipping eq 'yes'){print "\n Chimera installations skipped\n\n"; goto Cskip;}

# install Chimera, ChimeraX and Modeller
sleep(1); print "\ninstalling UCSF Chimera binary file, and chimerax-daily tar.gz (option) and Modeller(option) .deb folders to your desktop\n\n"; sleep(1);
print "\n NOTE: make sure to have right clicked these, go to properties/permissions and allow them to run as executable\n\n"; sleep(1);
print "\nAre you ready? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}

print "\ntype name of Chimera bin file (e.g. chimera-1.13.1-linux_x86_64.bin)  NOTE:be sure file permission is set executable\n\n";
  $Cname = <STDIN>; 
  chop($Cname);
sleep(1); print "\ninstalling Chimera\n\n"; sleep(1); system('./'.$Cname); sleep(1);
#sleep(1); print "\nunzipping ChimeraX\n\n"; sleep(1); system('tar xvzf chimerax-daily.tar.gz'); sleep(1);
#sleep(1); print "\nIMPORTANT NOTE: ChimeraX runs from within extracted bin folder\n\n"; sleep(1);
print "\ntype name of Modeller .deb folder (e.g. modeller_9.20-1_amd64.deb)\n\n";
  $Mname = <STDIN>; 
  chop($Mname);
sleep(1); print "\ninstalling Modeller\n\n"; sleep(1); system('sudo apt install ./'.$Mname); sleep(1);
# install ChimeraX
print "\ninstall chimeraX \n";
system('gnome-terminal');
sleep(1); print "\nin the new terminal run the following commands\n\n"; sleep(1);
print "sudo dpkg -i chimerax-daily.deb\n";
print "sudo apt-get update\n";
print "sudo apt-get install chimerax-daily\n\n";

sleep(1); print "\nWhen chimeraX is installed, close secondary terminal\n\n"; sleep(1);
print "\nAre you ready to continue? (y/n)\n\n";
  $yn = <STDIN>; 
  chop($yn);
if($yn eq "n" || $yn eq "N"){print "\ninstallation interrupted\n\n"; exit;}
Cskip: # skip Chimera install

print "\n\nAMBER 16/18 and UCSF CHIMERA INSTALLATION COMPLETE\n\n";

print "\n(optional) to install md4vr, remove md4vr.zip from DROIDS folder to desktop and unzip\n";
print "make sure steamOS and steamVR are working correctly,then follow README\n\n";

exit;  



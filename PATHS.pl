#!/usr/bin/perl
use Tk;
#use strict;
#use warnings;
use feature ":5.10";

#### This creates a GUI to write the control files needed for the GPU accelerated pmemd.cuda pipeline ####

#### Declare variables ####
my $chimera_path = '';
my $amber_path= '';
my $teleap_path = '';
my $openmm_path = '';


sleep(1); print "\nlocating paths to amber, steam, chimera and chimerax\n";
system ('locate /bin/pmemd | egrep home | grep cuda');
system ('which steam');
system ('locate /bin/ChimeraX | egrep ./ | grep bin');
system ('locate /bin/chimera | egrep ./ | grep bin');


#### Create GUI ####
my $mw = MainWindow -> new; # Creates a new main window
$mw -> title("PATHS TO SOFTWARE (can exit if this ctl file is already correct)"); # Titles the main window
$mw->setPalette("gray");


# PATH Frame				
my $pathFrame = $mw->Frame();
	my $amberFrame = $pathFrame->Frame();
		my $amberLabel = $amberFrame->Label(-text=>"path to amber home folder(e.g. /home/greg/Desktop/amber16/) : ");
		my $amberEntry = $amberFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$amber_path
					);
	my $chimeraFrame = $pathFrame->Frame();
		my $chimeraLabel = $chimeraFrame->Label(-text=>"path to chimera executable (e.g. /opt/UCSF/Chimera64-1.11/bin/) : ");
		my $chimeraEntry = $chimeraFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$chimera_path
					);
     my $chimeraxFrame = $pathFrame->Frame();
		my $chimeraxLabel = $chimeraxFrame->Label(-text=>"path to ChimeraX executable (e.g. /home/greg/Desktop/chimerax-2019.01.19/bin/) : ");
		my $chimeraxEntry = $chimeraxFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$chimerax_path
					);   
	my $teleapFrame = $pathFrame->Frame();
		my $teleapLabel = $teleapFrame->Label(-text=>"path to force fields (e.g. /home/greg/Desktop/amber16/dat/leap/cmd/) : ");
		my $teleapEntry = $teleapFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$teleap_path
					);	
	my $steamFrame = $pathFrame->Frame();
		my $steamLabel = $steamFrame->Label(-text=>"path to steam executable (e.g. /usr/bin/) : ");
		my $steamEntry = $steamFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$steam_path
					);	
		
# Buttons
my $controlButton = $mw -> Button(-text => "make new PATHS control file (paths.ctl)", 
				-command => \&control,
				-background => 'gray45',
                -foreground => 'white'
				); # Creates a ctl file button

my $exitButton = $mw -> Button(-text => "exit if PATHS are already correctly specified", 
				-command => \&stop,
                -background => 'gray45',
                -foreground => 'white'
				); # Creates a go button

#### Organize GUI Layout ####
$exitButton->pack(-side=>"bottom",
			-anchor=>"s");
$controlButton->pack(-side=>"bottom",
			-anchor=>"s");

$amberLabel->pack(-side=>"left");
$amberEntry->pack(-side=>"left");
$chimeraLabel->pack(-side=>"left");
$chimeraEntry->pack(-side=>"left");
$chimeraxLabel->pack(-side=>"left");
$chimeraxEntry->pack(-side=>"left");
$teleapLabel->pack(-side=>"left");
$teleapEntry->pack(-side=>"left");
$steamLabel->pack(-side=>"left");
$steamEntry->pack(-side=>"left");

$amberFrame->pack(-side=>"top",
		-anchor=>"e");
$chimeraFrame->pack(-side=>"top",
		-anchor=>"e");
$chimeraxFrame->pack(-side=>"top",
		-anchor=>"e");
$teleapFrame->pack(-side=>"top",
		-anchor=>"e");
$steamFrame->pack(-side=>"top",
		-anchor=>"e");
$pathFrame->pack(-side=>"top",
		-anchor=>"n");

MainLoop; # Allows Window to Pop Up


########################################################################################
######################     SUBROUTINES     #############################################
########################################################################################
sub stop {exit;}
########################################################################################
sub control { # Write a control file and then call appropriate scripts that reference control file

### make qury protein control file ###	
open(my $ctlFile, '>', "paths.ctl") or die "Could not open output file";
print $ctlFile 
"amber_path\t$amber_path\t# path to amber home folder
chimera_path\t$chimera_path\t# path to Chimera executable
teleap_path\t$teleap_path\t# path to teLeap force field folder
steam_path\t$steam_path\t# path to steam executable";
close $ctlFile;

print "control file for PATHS is done (see paths.ctl)\n";

}


#################################################################################





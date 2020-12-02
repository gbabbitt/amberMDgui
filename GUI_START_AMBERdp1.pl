#!/usr/bin/perl
use Tk;
#use strict;
#use warnings;
use feature ":5.10";
use Statistics::Descriptive();
use File::Copy;

# specify the path to working directory for Chimera here
open(IN, "<"."paths.ctl") or die "could not find paths.txt file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
	 my @INrow = split (/\s+/, $INrow);
	 my $header = @INrow[0];
	 my $path = @INrow[1];
	 if ($header eq "chimera_path"){$chimera_path = $path;}
}
close IN;
print "path to Chimera .exe\t"."$chimera_path\n";

#### This creates a GUI to write the control files needed for the GPU accelerated pmemd.cuda pipeline ####

#### Declare variables ####
my $fileIDq = '';
my $fileIDr = '';
my $forceID = '';
my $runsID = '';
my $implicit=0;
my $explicit=0;
my $solvType = '';
my $cutoffValueHeat=300;
my $cutoffValueEq=10;
my $cutoffValueProd=5;
my $cutoffValueSalt=0.0;
my $cutoffValueHeatFS=0;
my $cutoffValueEqFS=0;
my $cutoffValueProdFS=0;
my @fullfile;
my @chainlen;
my @fullfile2;
my @chainlen2;

#### Create GUI ####
my $mw = MainWindow -> new; # Creates a new main window
$mw -> title("MD control settings"); # Titles the main window
$mw->setPalette("gray");

my $MDheatScale = $mw->Scale(-label=>"Length of MD heating run (ps) :",
			-orient=>'h',
			-digit=>3,
			-from=>0,
			-to=>1000,
			-variable=>\$cutoffValueHeat,
			-tickinterval=>200,
			-resolution=>10,
			-length=>205
			);

my $MDeqScale = $mw->Scale(-label=>"Length of MD equilibration run (ns) :",
			-orient=>'h',
			-digit=>3,
			-from=>0,
			-to=>20,
			-variable=>\$cutoffValueEq,
			-tickinterval=>5,
			-resolution=>1,
			-length=>205
			);

my $MDprodScale = $mw->Scale(-label=>"Length of each MD sample run (ns) :",
			-orient=>'h',
			-digit=>3,
			-from=>0,
			-to=>20,
			-variable=>\$cutoffValueProd,
			-tickinterval=>5,
			-resolution=>1,
			-length=>205
			);

my $MDsaltScale = $mw->Scale(-label=>"extra salt conc (M) (implicit only)  :",
			-orient=>'h',
			-digit=>3,
			-from=>0,
			-to=>0.6,
			-variable=>\$cutoffValueSalt,
			-tickinterval=>0.2,
			-resolution=>0.05,
			-length=>205
			);

# Solvation Frame
my $solnFrame = $mw->Frame(	-label => "METHOD OF SOLVATION",
				-relief => "groove",
				-borderwidth => 2
				);
	my $implicitCheck = $solnFrame->Radiobutton( -text => "implicit - Generalized Born",
						-value=>"im",
						-variable=>\$solvType
						);
	my $explicitCheck = $solnFrame->Radiobutton( -text => "explicit - Particle Mesh Ewald",
						-value=>"ex",
						-variable=>\$solvType
						);

# Simulation Frame
my $simFrame = $mw->Frame(	-label => "MD SIMULATION ENGINE",
				-relief => "groove",
				-borderwidth => 2
				);
	my $amberCheck = $simFrame->Radiobutton( -text => "pmemd.cuda (amber) - licensed",
						-value=>"amber",
						-variable=>\$simType
						);
	my $openCheck = $simFrame->Radiobutton( -text => "OpenMM - open source",
						-value=>"open",
						-variable=>\$simType
						);

# PDB ID Frame				
my $pdbFrame = $mw->Frame();
	#my $QfileFrame = $pdbFrame->Frame();
	#	my $QfileLabel = $QfileFrame->Label(-text=>"pdb ID without DNA/RNA/lipid (e.g. 1cdw_unbound) : ");
	#	my $QfileEntry = $QfileFrame->Entry(-borderwidth => 2,
	#				-relief => "groove",
	#				-textvariable=>\$fileIDq
	#				);
	my $RfileFrame = $pdbFrame->Frame();
		my $RfileLabel = $RfileFrame->Label(-text=>"pdb ID with DNA/RNA/lipid (e.g. 1cdw_bound) : ");
		my $RfileEntry = $RfileFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$fileIDr
					);
		
	my $forceFrame = $pdbFrame->Frame();
		my $forceLabel = $forceFrame->Label(-text=>"protein force field (e.g. leaprc.protein.ff14SB): ");
		my $forceEntry = $forceFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$forceID
					);
      my $dforceFrame = $pdbFrame->Frame();
		my $dforceLabel = $dforceFrame->Label(-text=>"DNA/RNA/lipid force field (e.g. leaprc.DNA.OL15): ");
		my $dforceEntry = $dforceFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$dforceID
					);    
	my $runsFrame = $pdbFrame->Frame();
		my $runsLabel = $runsFrame->Label(-text=>"number of repeated MD sample runs: ");
		my $runsEntry = $runsFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$runsID
					);
     my $chainFrame = $pdbFrame->Frame();
		my $chainLabel = $chainFrame->Label(-text=>"number of protein chains (e.g. 3 = A/B/C): ");
		my $chainEntry = $chainFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$chainN
					); 
	my $startFrame = $pdbFrame->Frame();
		my $startLabel = $startFrame->Label(-text=>"start numbering AA's on chain at (e.g. 1): ");
		my $startEntry = $startFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$startN
					);
       $startN = 1; # this is now hard coded - Nov 2018
       
# Buttons
my $controlButton = $mw -> Button(-text => "make MD, cpptraj, and DROIDS control files (.ctl)", 
				-command => \&control
				); # Creates a ctl file button

my $launchButton = $mw -> Button(-text => "launch MD run - may take many hours", 
				-command => \&launch,
				-background => 'gray45',
				-foreground => 'white'
				); # Creates a launch button

my $killButton = $mw -> Button(-text => "kill MD run on GPU", 
				-command => \&kill
				); # Creates a kill button

my $survButton = $mw -> Button(-text => "open GPU job survellience", 
				-command => \&surv
				); # Creates a surv button

my $teLeapButton = $mw -> Button(-text => "generate topology and coordinate files (teLeap)", 
				-command => \&teLeap
				); # Creates a teLeap button
my $reduceButton = $mw -> Button(-text => "dry and reduce structure (run pdb4amber)", 
				-command => \&reduce
				); # Creates a pdb4amber button
my $alignButton = $mw -> Button(-text => "create sequence and structural alignment (UCSF Chimera)", 
				-command => \&align
				); # Creates a align button
#my $infoButton = $mw -> Button(-text => "create atom info files", 
#				-command => \&info
#				); # Creates a file button

#my $fluxButton = $mw -> Button(-text => "create atom fluctuation files", 
#				-command => \&flux
#				); # Creates a file button

my $doneButton = $mw -> Button(-text => "open output files and render movie", 
				-command => \&done
				); # Creates a file button
my $stopButton = $mw -> Button(-text => "exit DROIDS", 
				-command => \&stop
				); # Creates a file button


#### Organize GUI Layout ####
$stopButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$doneButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
#$fluxButton->pack(-side=>"bottom",
#			-anchor=>"s"
#			);
#$infoButton->pack(-side=>"bottom",
#			-anchor=>"s"
#			);
$killButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$launchButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$teLeapButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
#$alignButton->pack(-side=>"bottom",
#			-anchor=>"s"
#    		);
$controlButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$reduceButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$survButton->pack(-side=>"bottom",
			-anchor=>"s"
			);

#$QfileLabel->pack(-side=>"left");
#$QfileEntry->pack(-side=>"left");
$RfileLabel->pack(-side=>"left");
$RfileEntry->pack(-side=>"left");
$forceLabel->pack(-side=>"left");
$forceEntry->pack(-side=>"left");
$dforceLabel->pack(-side=>"left");
$dforceEntry->pack(-side=>"left");
$runsLabel->pack(-side=>"left");
$runsEntry->pack(-side=>"left");
$chainLabel->pack(-side=>"left");
$chainEntry->pack(-side=>"left");
#$startLabel->pack(-side=>"left");
#$startEntry->pack(-side=>"left");

$forceFrame->pack(-side=>"top",
		-anchor=>"e");
$dforceFrame->pack(-side=>"top",
		-anchor=>"e");
#$QfileFrame->pack(-side=>"top",
#		-anchor=>"e");
$RfileFrame->pack(-side=>"top",
		-anchor=>"e");
$runsFrame->pack(-side=>"top",
		-anchor=>"e");
$chainFrame->pack(-side=>"top",
		-anchor=>"e");
#$startFrame->pack(-side=>"top",
#		-anchor=>"e");
$pdbFrame->pack(-side=>"top",
		-anchor=>"n");

$implicitCheck->pack();
$explicitCheck->pack();
$solnFrame->pack(-side=>"top",
		-anchor=>"n"
		);
$amberCheck->pack();
$openCheck->pack();
$simFrame->pack(-side=>"top",
		-anchor=>"n"
		);
$MDheatScale->pack(-side=>"top");
$MDeqScale->pack(-side=>"top");
$MDprodScale->pack(-side=>"top");
$MDsaltScale->pack(-side=>"top");

MainLoop; # Allows Window to Pop Up


########################################################################################
######################     SUBROUTINES     #############################################
########################################################################################
sub stop {exit;}
########################################################################################

sub control { # Write a control file and then call appropriate scripts that reference control file

sleep(2);



print "IMPORTANT: prior to analyses, remove TER lines for all DNA chains \n";
print "from $fileIDr"."REDUCED.pdb PDB file, then type 'done'\n\n";
system "gedit $fileIDr"."REDUCED.pdb\n";
my $done = <STDIN>;
chop($done);
if ($done ne "done"){exit;}

	if ($solvType eq "im") {$repStr = "implicit";}
	if ($solvType eq "ex") {$repStr = "explicit";}
	
	# convert all times to femtosec
	$cutoffValueHeatFS = $cutoffValueHeat*1000;
	$cutoffValueEqFS = $cutoffValueEq*1000000;
	$cutoffValueProdFS = $cutoffValueProd*1000000;

   
### make query protein control file ###

### get chain information from PDB

### make ref protein control file ###
## extract information from PDB
open(INPUTFILE2, $fileIDr."REDUCED.pdb");
    # load input into array
    chomp(@fullfile2 = <INPUTFILE2>);
    close(INPUTFILE2);

my $count = 0;
for(my $line = 0; $line < scalar @fullfile2; $line++){
    ## go down first column until you hit TER
    chomp($fullfile2[$line]);
    my @entry = (split (/\s+/, $fullfile2[$line]));
    if ($entry[0] eq "TER") {
        # get each chain length
        my $len = $entry[4];
        if ($len eq ''){$len = $entry[3]; $len =~ s/\D//g;} #fixes concatenation of chain ID and residue number when > 1000
        $chainlen2[$count] = $len;
        #print "$count\t$chainlen2[$count]\n";
        $count++;
    }
}
## write to control file
open(my $ctlFile2, '>', "MDr.ctl") or die "Could not open output file";
print $ctlFile2 
"PDB_ID\t".$fileIDr."REDUCED\t# Protein Data Bank ID for MD run
Number_Chains\t$chainN\t# Number of chains on structure\n";
$allchainlen = 0;
for(my $cnt = 0; $cnt < scalar @chainlen2; $cnt++){
    my $chain = chr($cnt + 65);
    #print "$cnt";
    #print "$chainlen2[$cnt]\n";
    #print "length$chain\t$chainlen2[$cnt]\n";
    print $ctlFile2 "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    print "MDr.ctl\n";
    print "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    $allchainlen = $allchainlen + $chainlen2[$cnt];
}

# define vector reference point (...as mid sequence in Chain A)
#$vectref = int(0.5*$allchainlen);
#if ($vector_enter eq 'y'){
#sleep(1);print "\nCHOOSE AN AMINO ACID RESIDUE AS REFERENCE POINT FOR VECTOR (i.e. shape) ANALYSIS (default = 1)\n\n";
#my $vectref = <STDIN>;
#chop($vectref);
#if ($vectref eq ''){$vectref = 1;}
#}

print $ctlFile2
"Force_Field\t$forceID\t# AMBER force field to use in MD runs
DNA_Field\t$dforceID\t# AMBER force field to use in MD runs
Number_Runs\t$runsID\t# number of repeated samples of MD runs
Heating_Time\t$cutoffValueHeatFS\t# length of heating run (fs)
Equilibration_Time\t$cutoffValueEqFS\t# length of equilibration run (fs)
Production_Time\t$cutoffValueProdFS\t# length of production run (fs)
Solvation_Method\t$repStr\t# method of solvation (implicit or explicit)
Salt_Conc\t$cutoffValueSalt\t# salt concentration (implicit only, PME=O)";
close $ctlFile2;

print "MD control files are made (see MDq.ctl and MDr.ctl)\n";
################################
### make cpptraj ctl files
sleep(0.5);

if ($solvType eq "im") {$implicit = 1;}
if ($solvType eq "ex") {$explicit = 1;}

### make atom info control files ###	

open(ctlFile2, '>', "atominfo_$fileIDr"."_0.ctl") or die "Could not open output file";
my $parm_label2 = '';
if ($implicit == 1) {my $parm_label2 = "vac_"."$fileIDr"."REDUCED.prmtop"; print ctlFile2 "parm $parm_label2\n";}
if ($explicit == 1) {my $parm_label2 = "wat_"."$fileIDr"."REDUCED.prmtop"; print ctlFile2 "parm $parm_label2\n";}
my $traj_label2 = "prod_"."$fileIDr"."REDUCED_0".".nc";
print ctlFile2 "trajin $traj_label2\n";
print ctlFile2 "resinfo !(:WAT)\n"; # all residues but not water
print ctlFile2 "atominfo \@CA,C,O,N,H&!(:WAT)\n"; # mask for all protein backbone atoms eliminating water
close ctlFile2;



for (my $i = 0; $i < $runsID; $i++){
### make atom flux control files ###	

open(ctlFile4, '>', "atomflux_$fileIDr"."_$i.ctl") or die "Could not open output file";
my $parm_label4 = '';
if ($implicit == 1) {my $parm_label4 = "vac_"."$fileIDr"."REDUCED.prmtop"; print ctlFile4 "parm $parm_label4\n";}
if ($explicit == 1) {my $parm_label4 = "wat_"."$fileIDr"."REDUCED.prmtop"; print ctlFile4 "parm $parm_label4\n";}
my $traj_label4 = "prod_"."$fileIDr"."REDUCED_$i".".nc";
print ctlFile4 "trajin $traj_label4\n";	
print ctlFile4 "rms first\n";
print ctlFile4 "average crdset MyAvg\n";
print ctlFile4 "run\n";
print ctlFile4 "rms ref MyAvg\n";
print ctlFile4 "atomicfluct out fluct_$fileIDr"."_$i.txt \@CA,C,O,N,H&!(:WAT)\n";
if($vector_enter eq 'y'){print ctlFile4 "atomiccorr \@CA,C,O,N&!(:WAT) out corrALL_$fileIDr"."_$i.txt\n";}
#print ctlFile4 "byatom\n";  # hash out for avg atom flux, unhash for total atom flux
print ctlFile4 "run\n";
close ctlFile4;

  } # end per run loop 

my $prefix = "";
open(metafile, '>', "$fileIDr.meta") or die "Could not open output file";
if ($implicit == 1) {$prefix = "vac";}
if ($explicit == 1) {$prefix = "wat";}
print metafile "amber\n$prefix"."_$fileIDr.prmtop\nprod_$fileIDr"."_0.nc\n";
close metafile;

print "\n\ncpptraj control files is made\n\n";

##########################################
# make control file for DROIDS	
sleep(0.5);
print("Making DROIDS.ctl file...\n");
	if ($ribbon == 1 && $surface == 0) {$repStr = "ribbon";}  # opaque ribbon rep only
	if ($surface == 1 && $ribbon == 0) {$repStr =  "surface";} # opaque surface rep only
	if ($surface == 1 && $ribbon == 1) {$repStr =  "ribbonsurface";} # opaque ribbon with transparent surface

	$testStr = "flux"; $testStrLong = "fluctuation";  # file and folder labels
	
open(CTL, '>', "DROIDS.ctl") or die "Could not open output file";
#print CTL "query\t"."$fileIDq\t # Protein Data Bank ID for query structure\n";
print CTL "reference\t"."$fileIDr\t # Protein Data Bank ID for reference structure (or neutral model)\n";
#print CTL "length\t"."$lengthID\t # number of amino acids on chain\n";
print CTL "num_chains\t"."$chainN\t # number of chains in structure\n";
$chainTTL = 0;
for(my $cnt = 0; $cnt < scalar @chainlen2; $cnt++){
    my $chain = chr($cnt + 65);
    #print "$cnt";
    #print "$chainlen2[$cnt]\n";
    #print "length$chain\t$chainlen2[$cnt]\n";
    print CTL "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    print "DROIDS.ctl\n";
    print "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    $chainTTL = $chainlen2[$cnt];
}
print CTL "length\t"."$chainTTL\t # total length of chain\n";
print CTL "start\t"."$startN\t # number of AA at start of chain\n";
print CTL "shape\t"."$vector_enter\t # also analyze protein shape change?\n";
#print CTL "cutoff_value\t"."$cutoffValue\t # p-value under which the KS comparison will be considered significant\n";
#print CTL "representations\t"."$repStr\t # methods of molecular representation in Chimera (ribbon and/or surface)\n";
#print CTL "test_type\t"."$testStr\t # test method (sequence = local Grantham dist, structure = RMSD, fluctuation = MD)\n";
#print CTL "color_scheme\t"."$colorType\t # output color scheme (red-green, yellow-blue, or orange-magenta)\n";
close CTL;
print("DROIDS ctl file is made\n");
##############################################
#  create list of chain labels
##############################################
@alphabet = ("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z");
@chainlist = ();
if($chainN > 26) {print "warning - number of chains exceeds alphabet\n";}
for(my $l = 0; $l < $chainN; $l++){
     $letter = $alphabet[$l];
     push(@chainlist, $letter);
     }
print "chains in structure are...\n";
print @chainlist;
print "\n\n";

print "NOTE: if the chain designations look as if they have been calculated incorrectly\n";
print "you will need to edit...re-enter lengths manually in MDq.ctl, MDr.ctl, DROIDS.ctl\n\n";
##############################################
}  # end sub


#####################################################################################################

sub teLeap { # create topology and coordinate files 
#system "perl teLeap_dnaproteinQuery.pl\n";
system "perl teLeap_dnaproteinReference.pl\n";
#my $filecheck1 = "vac_".$fileIDq."REDUCED.prmtop";
my $filecheck2 = "vac_".$fileIDr."REDUCED.prmtop";
#my $filecheck3 = "wat_".$fileIDq."REDUCED.inpcrd";
my $filecheck4 = "wat_".$fileIDr."REDUCED.inpcrd";
#my $size1 = -s $filecheck1;
my $size2 = -s $filecheck2;
#my $size3 = -s $filecheck3;
my $size4 = -s $filecheck4;
print "$size1\t"."$size2\t"."$size3\t"."$size4\n";
if ($size2 <= 10 || $size4 <= 10){print "teLeap may have failed (double check pdb files for problems)\n";}
else {print "teLeap procedure appears to have run (double check .prmtop and .inpcrd files)\n";}
}

######################################################################################################
sub reduce { # create PDB files for teLeap
sleep(1);print "DO YOU WANT TO REDUCE THE ENTIRE STRUCTURE? (y or n)\n";
print "i.e. answer 'n' if protonation state is already prepared ahead of time \n";
my $reduce_enter = <STDIN>;
chop($reduce_enter);
#if ($reduce_enter eq "y"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry --reduce \n";}
#if ($reduce_enter eq "n"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry \n";}
if ($reduce_enter eq "y"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "n"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry \n";}
#if ($reduce_enter eq "yes"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry --reduce \n";}
#if ($reduce_enter eq "no"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry \n";}
if ($reduce_enter eq "yes"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "no"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry \n";}
sleep(1);
print "opening USCF Chimera and loading both PDB structures\n\n";
print "CHECK THAT ALL CHAINS ARE NUMBERED SEQUENTIALLY STARTING FROM 1 to END OF LAST CHAIN\n";
print "NOTE: move and relabel DNA chains to be after protein chains\n";
print "(use Tools/Structure Editing/Renumber Residues)\n\n";
system("$chimera_path"."chimera $fileIDr"."REDUCED.pdb\n");
#system("$chimera_path"."chimera $fileIDq"."REDUCED.pdb\n");
sleep(1);
print "\n\npdb4amber is completed\n\n";
}

######################################################################################################

sub launch { # launch MD run
if($simType eq "amber"){
    #system "perl MD_proteinQuery.pl\n";
    #sleep(2);
    system "perl MD_proteinReference.pl\n";
    print "\n\n";
    print "MD SIMULATIONS ARE COMPLETED\n\n";
    }
if($simType eq "open" && $solvType eq "ex"){
    system "conda config --set auto_activate_base true\n";
    system "x-terminal-emulator\n";
    print "\nRUN THE FOLLOWING SCRIPT IN THE NEW TERMINAL\n";
    #print "python MD_proteinQuery_openMM.py\n";
    print "python MD_proteinReference_openMM.py\n";
    sleep(2);
    print "\n\n";
    system "conda config --set auto_activate_base false\n";
    print "CLOSE TERMINAL WHEN BOTH MD SIMULATIONS ARE COMPLETED\n\n";
    }
if($simType eq "open" && $solvType eq "im"){
    print "Implicit solvent is not supported in OpenMM. Use explicit solvent\n\n";
    }
}

######################################################################################################

sub kill { # kill MD run
system "pkill pmemd\n";	
}

######################################################################################################

sub surv {
	### open job survalience terminals ######
system "x-terminal-emulator -e top\n";
system "x-terminal-emulator -e nvidia-smi -l 20\n";
}

######################################################################################################

###################################################################################################

sub done {
# open .out files for data
print "MD output files are opened sequentially and copied to MDoutput folder\n\n";
sleep(2);
mkdir MDoutput;
for (my $i = 0; $i < $runsID; $i++){
     system ("gedit prod_$fileIDr"."REDUCED_$i.out\n");
     $infile = "prod_$fileIDr"."REDUCED_$i.out";
     $outfile = "./MDoutput/prod_$fileIDr"."REDUCED_$i.out";
     copy($infile, $outfile)
}
# image and movie rendering
print "TO RECORD MOVIE:\n";
print "On Main Menu go to Tools/MD Ensemble Analysis/MD movie\n";
print "select input file (e.g. wat_1cdw_boundREDUCED.prmtop)\n";
print "add trajectory file (e.g. prod_1cdw_boundREDUCED_0.nc)\n";
print "on MD Movie window go to File/Record Movie\n\n";
sleep(2);
system("$chimera_path"."chimera");

}
##################################################################################################


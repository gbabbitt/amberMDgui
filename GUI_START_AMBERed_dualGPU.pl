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
my $cutoffValueHeat=100;
my $cutoffValueEq=10;
my $cutoffValueProd=10;
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
			-to=>500,
			-variable=>\$cutoffValueEq,
			-tickinterval=>100,
			-resolution=>10,
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
	my $QfileFrame = $pdbFrame->Frame();
		my $QfileLabel = $QfileFrame->Label(-text=>"pdb ID query (e.g. 4n56) : ");
		my $QfileEntry = $QfileFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$fileIDq
					);
	my $RfileFrame = $pdbFrame->Frame();
		my $RfileLabel = $RfileFrame->Label(-text=>"pdb ID reference (e.g. 1kfd) : ");
		my $RfileEntry = $RfileFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$fileIDr
					);
		
	my $forceFrame = $pdbFrame->Frame();
		my $forceLabel = $forceFrame->Label(-text=>"Force Field (e.g. leaprc.protein.ff14SB): ");
		my $forceEntry = $forceFrame->Entry(-borderwidth => 2,
					-relief => "groove",
					-textvariable=>\$forceID
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
my $infoButton = $mw -> Button(-text => "create atom info files", 
				-command => \&info
				); # Creates a file button

my $fluxButton = $mw -> Button(-text => "create atom fluctuation files", 
				-command => \&flux
				); # Creates a file button

my $doneButton = $mw -> Button(-text => "parse / prepare files for DROIDS", 
				-command => \&done
				); # Creates a file button
my $stopButton = $mw -> Button(-text => "exit DROIDS", 
				-command => \&stop
				); # Creates a file button


#### Organize GUI Layout ####
$stopButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
#$doneButton->pack(-side=>"bottom",
#			-anchor=>"s"
#			);
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
$alignButton->pack(-side=>"bottom",
			-anchor=>"s"
    		);
$controlButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$reduceButton->pack(-side=>"bottom",
			-anchor=>"s"
			);
$survButton->pack(-side=>"bottom",
			-anchor=>"s"
			);


$QfileLabel->pack(-side=>"left");
$QfileEntry->pack(-side=>"left");
$RfileLabel->pack(-side=>"left");
$RfileEntry->pack(-side=>"left");
$forceLabel->pack(-side=>"left");
$forceEntry->pack(-side=>"left");
$runsLabel->pack(-side=>"left");
$runsEntry->pack(-side=>"left");
$chainLabel->pack(-side=>"left");
$chainEntry->pack(-side=>"left");
#$startLabel->pack(-side=>"left");
#$startEntry->pack(-side=>"left");

$forceFrame->pack(-side=>"top",
		-anchor=>"e");
$QfileFrame->pack(-side=>"top",
		-anchor=>"e");
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
	if ($solvType eq "im") {$repStr = "implicit";}
	if ($solvType eq "ex") {$repStr = "explicit";}
	
	# convert all times to femtosec
	$cutoffValueHeatFS = $cutoffValueHeat*1000;
	$cutoffValueEqFS = $cutoffValueEq*1000000;
	$cutoffValueProdFS = $cutoffValueProd*1000000;

   
### make query protein control file ###

### get chain information from PDB
## read in .pdb file
open(INPUTFILE, $fileIDq."REDUCED.pdb");
    # load input into array
    #print"success";
    chomp(@fullfile = <INPUTFILE>);
    close(INPUTFILE);

my $count = 0;
for(my $line = 0; $line < scalar @fullfile; $line++){
    ## go down first column until you hit TER
    chomp($fullfile[$line]);
    my @entry = (split (/\s+/, $fullfile[$line]));
    if ($entry[0] eq "TER") {
        # get each chain length
        my $len = $entry[4];
        if ($len eq ''){$len = $entry[3]; $len =~ s/\D//g;}  #fixes concatenation of chain ID and residue number when > 1000
        $chainlen[$count] = $len;
        #print "$chainlen[$count]\n";
        $count++;
    }
}
### write control file
open(my $ctlFile1, '>', "MDq.ctl") or die "Could not open output file";
print $ctlFile1 
"PDB_ID\t".$fileIDq."REDUCED\t# Protein Data Bank ID for MD run
Number_Chains\t$chainN\t# Number of chains on structure\n";
for(my $ent = 0; $ent < scalar @chainlen; $ent++){
    my $chain = chr($ent + 65);
    print $ctlFile1 "length$chain\t$chainlen[$ent]\t #end of chain designated\n";
    print "MDq.ctl\n";
    print "length$chain\t$chainlen[$ent]\t #end of chain designated\n";
}
print $ctlFile1
"Force_Field\t$forceID\t# AMBER force field to use in MD runs
Number_Runs\t$runsID\t# number of repeated samples of MD runs
Heating_Time\t$cutoffValueHeatFS\t# length of heating run (fs)
Equilibration_Time\t$cutoffValueEqFS\t# length of equilibration run (fs)
Production_Time\t$cutoffValueProdFS\t# length of production run (fs)
Solvation_Method\t$repStr\t# method of solvation (implicit or explicit)
Salt_Conc\t$cutoffValueSalt\t# salt concentration (implicit only, PME=O)
Temperature_Query\t$tempQ\t# temperature of query run (300K is same as ref run)";
close $ctlFile1;

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
for(my $cnt = 0; $cnt < scalar @chainlen2; $cnt++){
    my $chain = chr($cnt + 65);
    #print "$cnt";
    #print "$chainlen2[$cnt]\n";
    #print "length$chain\t$chainlen2[$cnt]\n";
    print $ctlFile2 "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    print "MDr.ctl\n";
    print "length$chain\t$chainlen2[$cnt]\t #end of chain designated\n";
    
}
print $ctlFile2
"Force_Field\t$forceID\t# AMBER force field to use in MD runs
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
open(ctlFile1, '>', "atominfo_$fileIDq"."_0.ctl") or die "Could not open output file";
my $parm_label1 = '';
if ($implicit == 1) {my $parm_label1 = "vac_"."$fileIDq"."REDUCED.prmtop"; print ctlFile1 "parm $parm_label1\n";}
if ($explicit == 1) {my $parm_label1 = "wat_"."$fileIDq"."REDUCED.prmtop"; print ctlFile1 "parm $parm_label1\n";}
my $traj_label1 = "prod_"."$fileIDq"."REDUCED_0".".nc";
print ctlFile1 "trajin $traj_label1\n";
print ctlFile1 "resinfo !(:WAT)\n"; # all residues but not water
print ctlFile1 "atominfo \@CA,C,O,N,H&!(:WAT)\n"; # mask for all protein backbone atoms eliminating water
close ctlFile1;

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
open(ctlFile3, '>', "atomflux_$fileIDq"."_$i.ctl") or die "Could not open output file";
my $parm_label3 = '';
if ($implicit == 1) {my $parm_label3 = "vac_"."$fileIDq"."REDUCED.prmtop"; print ctlFile3 "parm $parm_label3\n";}
if ($explicit == 1) {my $parm_label3 = "wat_"."$fileIDq"."REDUCED.prmtop"; print ctlFile3 "parm $parm_label3\n";}
my $traj_label3 = "prod_"."$fileIDq"."REDUCED_$i".".nc";
print ctlFile3 "trajin $traj_label3\n";	
print ctlFile3 "rms first\n";
print ctlFile3 "average crdset MyAvg\n";
print ctlFile3 "run\n";
print ctlFile3 "rms ref MyAvg\n";
print ctlFile3 "atomicfluct out fluct_$fileIDq"."_$i.txt \@CA,C,O,N,H&!(:WAT)\n";
#print ctlFile3 "byatom\n"; # hash out for avg atom flux, unhash for total atom flux
print ctlFile3 "run\n";
close ctlFile3;

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
print CTL "query\t"."$fileIDq\t # Protein Data Bank ID for query structure\n";
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
system "perl teLeap_proteinQuery.pl\n";
system "perl teLeap_proteinReference.pl\n";
my $filecheck1 = "vac_".$fileIDq."REDUCED.prmtop";
my $filecheck2 = "vac_".$fileIDr."REDUCED.prmtop";
my $filecheck3 = "wat_".$fileIDq."REDUCED.inpcrd";
my $filecheck4 = "wat_".$fileIDr."REDUCED.inpcrd";
my $size1 = -s $filecheck1;
my $size2 = -s $filecheck2;
my $size3 = -s $filecheck3;
my $size4 = -s $filecheck4;
print "$size1\t"."$size2\t"."$size3\t"."$size4\n";
if ($size1 <= 10 || $size2 <= 10 || $size3 <= 10 || $size4 <= 10){print "teLeap may have failed (double check pdb files for problems)\n";}
else {print "teLeap procedure appears to have run (double check .prmtop and .inpcrd files)\n";}
}

######################################################################################################
sub reduce { # create PDB files for teLeap
sleep(1);print "DO YOU WANT TO REDUCE THE ENTIRE STRUCTURE? (y or n)\n";
print "i.e. answer 'n' if protonation state is already prepared ahead of time \n";
my $reduce_enter = <STDIN>;
chop($reduce_enter);
if ($reduce_enter eq "y"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "n"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry \n";}
if ($reduce_enter eq "y"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "n"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry \n";}
if ($reduce_enter eq "yes"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "no"){system "pdb4amber -i $fileIDq.pdb -o ".$fileIDq."REDUCED.pdb --dry \n";}
if ($reduce_enter eq "yes"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry --reduce \n";}
if ($reduce_enter eq "no"){system "pdb4amber -i $fileIDr.pdb -o ".$fileIDr."REDUCED.pdb --dry \n";}
sleep(1);
print "\n\npdb4amber is completed\n\n";
}

######################################################################################################

sub launch { # launch MD run
if($simType eq "amber"){
    system "x-terminal-emulator -e perl MD_proteinQuery_dualGPU.pl\n";
    sleep(2);
    system "x-terminal-emulator -e perl MD_proteinReference_dualGPU.pl\n";
    print "\n\n";
    print "MD SIMULATIONS ARE COMPLETED WHEN TERMINALS CLOSE\n\n";
    }
if($simType eq "open" && $solvType eq "ex"){
    system "conda config --set auto_activate_base true\n";
    system "x-terminal-emulator\n";
    system "x-terminal-emulator\n";
    print "\nRUN THE FOLLOWING SCRIPTS SIMULTANEOUSLY IN THE NEW TERMINALS\n";
    print "python MD_proteinQuery_dualGPU_openMM.py\n";
    print "python MD_proteinReference_dualGPU_openMM.py\n";
    sleep(2);
    print "\n\n";
    system "conda config --set auto_activate_base false\n";
    print "CLOSE TERMINALS WHEN BOTH MD SIMULATIONS ARE COMPLETED\n\n";
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

sub align{

print "STEP 1 - Here you will need to run MatchMaker in UCSF Chimera\n\n";
print "STEP 2 - Then run Match-Align in UCSF Chimera for each chain\n\n";
print "            if satisfied with alignment, save as a clustal file\n";
print "            (e.g. my_align.aln)\n\n";

print "continue? (y/n)\n";
my $go = <STDIN>;
chop($go);
if ($go eq "n") {exit;}
sleep(1);
print "            opening USCF Chimera and loading PDB ref structure\n\n";
print "            CREATE YOUR STRUCTURAL/SEQUENCE ALIGNMENT (.aln) NOW \n\n";
system("$chimera_path"."chimera $fileIDr"."REDUCED.pdb $fileIDq"."REDUCED.pdb\n");
# properly rename .aln file for DROIDS  
$chainlabel = '';
for (my $cl = 0; $cl < scalar @chainlist; $cl++){
     $chainlabel = $chainlist[$cl];
print "\nPlease enter name of your saved chain $chainlabel alignment file (e.g my$chainlabel"."_align.aln)\n";
my $align_name = "";
my $align_file = <STDIN>;
chop($align_file);
sleep(1);
# open and read first line header
open(IN, "<"."$align_file") or die "could not find alignment file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
      my $refINrow = $IN[$i+2];
	 my @INrow = split (/\s+/, $INrow);
	 my @refINrow = split (/\s+/, $refINrow);
      my $header = $INrow[0];
      my $ref_header = $refINrow[0];
      if ($header eq "CLUSTAL"){$align_name = $ref_header;}
      }
my @name_segment = split (/REDUCED/, $align_name);
if ($chainlabel eq "A"){$pdb_name = $name_segment[0];}
$split_name = $name_segment[0]."_align".$chainlabel.".aln";
$oldfilename = $align_file;
$newfilename = $split_name;
print "copying $align_file"." to $split_name\n";
# rename file with header
copy($oldfilename, $newfilename);
}
# create concatenated .aln master file
open (OUT, ">"."$pdb_name"."_align.aln");
for (my $ccl = 0; $ccl < scalar @chainlist; $ccl++){
     $chainlabel = $chainlist[$ccl];
     open (IN, "<"."$pdb_name"."_align".$chainlabel.".aln");
     my @IN = <IN>;
     print OUT @IN;
     print OUT "\n";
     #print @IN;
     #print "\n";
     close IN;
     }    
close OUT;
################
sleep(0.5);
print "\n\n alignment procedure is complete\n";
sleep(0.5);
	
}



###################################################################################################

sub info { # launch atom info
system("cpptraj "."-i ./atominfo_$fileIDq"."_0.ctl | tee cpptraj_atominfo_$fileIDq.txt");
system("cpptraj "."-i ./atominfo_$fileIDr"."_0.ctl | tee cpptraj_atominfo_$fileIDr.txt");
}

###################################################################################################

sub flux { # launch atom fluctuation calc
for (my $i = 0; $i < $runsID; $i++){
system("cpptraj "."-i ./atomflux_$fileIDq"."_$i.ctl | tee cpptraj_atomflux_$fileIDq.txt");
system("cpptraj "."-i ./atomflux_$fileIDr"."_$i.ctl | tee cpptraj_atomflux_$fileIDr.txt");
  }
}

###################################################################################################

sub done {

#print "Enter residue number at the start of both chains\n";
#print "(e.g. enter 389 if starts at THR 389.A) \n";
#print "(e.g. enter 1 if starts at MET 1.A) \n\n";
#my $startN = <STDIN>;
#chop($startN);

sleep(2);
print "\n\n searching for atom info file = "."cpptraj_atominfo_$fileIDr.txt\n";
sleep(2);
print "\n\n creating atom_residue_list_$fileIDr.txt\n";
open(OUT, ">"."atom_residue_list_$fileIDr.txt") or die "could open output file\n";
print OUT "atomnumber\t"."atomlabel\t"."resnumber\t"."reslabel\n";
open(IN, "<"."cpptraj_atominfo_$fileIDr.txt") or die "could not find atom info file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
	 my @INrow = split (/\s+/, $INrow);
	 $atomnumber = @INrow[1];
	 $atomlabel = @INrow[2];
	 $resnumber = @INrow[3];
	 $resindex = $resnumber + ($startN - 1);
	 $reslabel = @INrow[4];
      if ($atomnumber eq "CA"|| $atomnumber eq "C" || $atomnumber eq "O" || $atomnumber eq "N"){ #finds correct whitespace frame when atomnumber > 10000
          $atomnumber = @INrow[0];
	     $atomlabel = @INrow[1];
	     $resnumber = @INrow[2];
	     $resindex = $resnumber + ($startN - 1);
	     $reslabel = @INrow[3];
          }
	 if ($atomlabel eq "CA"|| $atomlabel eq "C" || $atomlabel eq "O" || $atomlabel eq "N"){print OUT "$atomnumber\t $atomlabel\t $resindex\t $reslabel\n"}
   }
close IN;
close OUT;
sleep(2);
print "\n\n creating atom_residue_list_$fileIDq.txt\n";
open(OUT, ">"."atom_residue_list_unmodified_$fileIDq.txt") or die "could open output file\n";
print OUT "atomnumber\t"."atomlabel\t"."resnumber\t"."reslabel\n";
open(IN, "<"."cpptraj_atominfo_$fileIDq.txt") or die "could not find atom info file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
	 my @INrow = split (/\s+/, $INrow);
	 $atomnumber = @INrow[1];
	 $atomlabel = @INrow[2];
	 $resnumber = @INrow[3];
	 $resindex = $resnumber + ($startN - 1);
	 $reslabel = @INrow[4];
      if ($atomnumber eq "CA"|| $atomnumber eq "C" || $atomnumber eq "O" || $atomnumber eq "N"){ #finds correct whitespace frame when atomnumber > 10000
          $atomnumber = @INrow[0];
	     $atomlabel = @INrow[1];
	     $resnumber = @INrow[2];
	     $resindex = $resnumber + ($startN - 1);
	     $reslabel = @INrow[3];
          }
	 if ($atomlabel eq "CA"|| $atomlabel eq "C" || $atomlabel eq "O" || $atomlabel eq "N"){print OUT "$atomnumber\t $atomlabel\t $resindex\t $reslabel\n"}
   }
close IN;
close OUT;
sleep(2);
#################################################################
print "\n\n modifying alignment for color mapping to reference structure\n";
sleep(2);  # need to remove indels from ref sequence and any corresponding AA's in query

open(OUT1, ">"."$fileIDr"."_alignREFMAP.aln") or die "could not open output file\n";
open(IN1, "<"."$fileIDr"."_align.aln") or die "could not open alignment...did you save as (.aln)?\n";
print OUT1 "CLUSTAL W ALN saved from UCSF Chimera/MultAlignViewer\n\n";
my @IN1 = <IN1>;
my $position = 0;
for (my $i = 0; $i < scalar @IN1; $i++){
	my $IN1row = $IN1[$i];
	my $IN1nextrow = $IN1[$i+1];
	if ($IN1row =~ m/$fileIDr/){my @IN1row = split(/\s+/, $IN1row); $header_ref = $IN1row[0]; $seq_ref =$IN1row[1]; print "$header_ref\t"."$seq_ref\n";
															my @IN1nextrow = split(/\s+/, $IN1nextrow); $header_query = $IN1nextrow[0]; $seq_query =$IN1nextrow[1]; print "$header_query\t"."$seq_query\n";
															my @seq_ref = split(//,$seq_ref);
															my @seq_query = split(//,$seq_query);
															my $new_seq_ref = "";
															my $new_seq_query = "";
															for (my $ii = 0; $ii < length $seq_ref; $ii++){
																      my $respos = $ii+1;
																			$position = $position+1;
																			my $AAref = @seq_ref[$ii]; 
																			my $AAquery = @seq_query[$ii];
																			if ($AAref ne "."){$new_seq_ref = $new_seq_ref.$AAref; $new_seq_query = $new_seq_query.$AAquery;}
															}
															print OUT1 "$header_ref\t"."$new_seq_ref\n";
															print OUT1 "$header_query\t"."$new_seq_query\n\n";
																													
															}
}
close OUT1;
close IN1;
sleep (2);

#################################################################
print "\n\n calculating AA sequence similarity and Grantham distances\n";
sleep(2);
print "\n\n creating vertical alignment files\n";
sleep(2);
open(OUT1, ">"."$fileIDr"."_vertalign_ref.aln") or die "could not open output file\n";
print OUT1 "respos\t"."seq_ref\n";
open(OUT2, ">"."$fileIDq"."_vertalign_query.aln") or die "could not open output file\n";
print OUT2 "respos\t"."seq_query\n";
open(OUT3, ">"."$fileIDr"."_vertalign_ref_indexed.aln") or die "could not open output file\n";
print OUT3 "respos\t"."seq_ref\n";
open(OUT4, ">"."$fileIDq"."_vertalign_query_indexed.aln") or die "could not open output file\n";
print OUT4 "respos\t"."seq_query\n";
open(OUT5, ">"."myGranthamDistances.txt") or die "could not open output file\n";
print OUT5 "respos\t"."distance\n";
open(IN1, "<"."$fileIDr"."_alignREFMAP.aln") or die "could not open alignment...did you save as (.aln)?\n";
my @IN1 = <IN1>;
my $position = 0;
my $positionINDEX = $startN-1;
my $AAsame_cnt = 0;
my $AA_cnt = 0;
my @gDISTS = ();
for (my $i = 0; $i < scalar @IN1; $i++){
	my $IN1row = $IN1[$i];
	my $IN1nextrow = $IN1[$i+1];
	if ($IN1row =~ m/$fileIDr/){my @IN1row = split(/\s+/, $IN1row); $header_ref = $IN1row[0]; $seq_ref =$IN1row[1]; print "$header_ref\t"."$seq_ref\n";
															my @IN1nextrow = split(/\s+/, $IN1nextrow); $header_query = $IN1nextrow[0]; $seq_query =$IN1nextrow[1]; print "$header_query\t"."$seq_query\n";
															my @seq_ref = split(//,$seq_ref);
															my @seq_query = split(//,$seq_query);
															for (my $ii = 0; $ii < length $seq_ref; $ii++){
																      $gDIST = '';
																			my $respos = $ii+1;
																			my $AAref = @seq_ref[$ii]; 
																			my $AAquery = @seq_query[$ii];
																			$position = $position+1;
																			$positionINDEX = $positionINDEX+1;
																			if ($AAquery eq $AAref){$AAsame_cnt = $AAsame_cnt + 1;}
																			if ($AAquery ne $AAref || $AAquery eq $AAref){$AA_cnt = $AA_cnt + 1;}
																			open(IN2, "<"."amino1to3.txt") or die "could not open amino1to3.txt\n";
																			my @IN2 = <IN2>;
																			#print "AAref "."$AAref\n";
																			#print "AAquery "."$AAquery\n";
																			for (my $iii = 0; $iii < scalar @IN2; $iii++){
																					my $AArow = @IN2[$iii];
																					my @AArow = split(/\s+/, $AArow);
																					$AAone = @AArow[0]; $AAthree = @AArow[1];
																					if ($AAone eq $AAref){print OUT1 "$position\t"."$AAthree\n"}
																					if ($AAone eq $AAquery){print OUT2 "$position\t"."$AAthree\n"}
																					if ($AAone eq $AAref){print OUT3 "$positionINDEX\t"."$AAthree\n"}
																					if ($AAone eq $AAquery){print OUT4 "$positionINDEX\t"."$AAthree\n"}
																			  	}
																			# determine Grantham distance
																			if ($AAquery eq $AAref || $AAquery eq "." || $AAref eq "."){$gDIST = 0;}
																			if ($AAquery ne $AAref && $AAquery ne "." && $AAref ne "."){
																			open(IN3, "<"."GranthamScores.txt") or die "could not open amino1to3.txt\n";
																			my @IN3 = <IN3>;
																			for (my $iiii = 0; $iiii < scalar @IN3; $iiii++){
																					my $GDrow = @IN3[$iiii];
																					my @GDrow = split(/\s+/, $GDrow);
																					$AAqueryTEST = @GDrow[0]; $AArefTEST = @GDrow[1]; $gDISTtest = @GDrow[2];
																					if(uc $AAqueryTEST eq $AAquery && uc $AArefTEST eq $AAref){$gDIST = $gDISTtest;} # grantham matrix
																					elsif(uc $AAqueryTEST eq $AAref && uc $AArefTEST eq $AAquery){$gDIST = $gDISTtest;} # to cover other half of matrix
																					}
																			}
																			
																			print OUT5 "$position\t"."$gDIST\n";
																			if ($gDIST > 0) {push (@gDISTS, $gDIST);} # average only non-zero Grantham Distances
																																																									 
													        }
															}
}
close OUT1;
close OUT2;
close OUT3;
close OUT4;
close OUT5;
close IN1;
close IN2;

### whole sequence stats
$statSCORE = new Statistics::Descriptive::Full; # residue avg flux - reference
           $statSCORE->add_data (@gDISTS);
					 $avg_gDIST = $statSCORE->mean();
					 $avg_gDIST = sprintf "%.2f", $avg_gDIST;

$AAseqsim = int(($AAsame_cnt/$AA_cnt+0.0001)*100);
$AAseq_matchfreq = ($AAsame_cnt/$AA_cnt+0.0001)*100;
$AAseq_matchfreq = sprintf "%.2f", $AAseq_matchfreq;
print "\n\nAA sequence similarity = "."$AAseqsim"."%\n";
print "avg Grantham Distance = "."$avg_gDIST"."\n";
open(OUT6, ">"."mySeqSTATS.txt") or die "could not open output file\n";
print OUT6 "label\t"."value\n";
print OUT6 "AAmatchFreq\t"."$AAseq_matchfreq\n";
print OUT6 "avgGranthamDist\t"."$avg_gDIST\n";
close OUT6;

sleep (2);


#################################################################################
print "\n\n adding gaps to query atom residue list (if needed)\n";
sleep(2);

open(IN1, "<"."atom_residue_list_unmodified_$fileIDq.txt") or die "could not open atom_residue_list.txt\n";
open(IN2, "<"."$fileIDq"."_vertalign_query_indexed.aln") or die "could not open output file\n";
open(OUT, ">"."atom_residue_list_$fileIDq.txt") or die "could not make atom_residue_list.txt\n";
#print OUT "atomnumber\t"."atomlabel\t"."resnumber\t"."reslabel\n";
my @IN1 = <IN1>;
my @IN2 = <IN2>;
$indelCount = 0;
for (my $i = 0; $i < scalar @IN1; $i++){ # scan residue list
	         my $IN1row = $IN1[$i];
			     my @IN1row = split(/\s+/, $IN1row);
			     my $atomnumber = $IN1row[0];
			     my $atomlabel = $IN1row[1];
			     my $resindex = $IN1row[2];
					 my $reslabel = $IN1row[3];
					 				 
					 for (my $j = 0; $j < scalar @IN2; $j++){ # scan alignment
			        my $IN2row = $IN2[$j];
			        my @IN2row = split(/\s+/, $IN2row);
			        my $pos_query = $IN2row[0] - $indelCount;
			        my $res_query = $IN2row[1];
							my $resindexgap = $resindex + $indelCount;
							#print "$pos_query\t"."$resindex\n";
				      if ($pos_query == $resindex && $res_query eq "xxx"){print OUT "na\t"."na\t"."na\t"."xxx\n"; print OUT "na\t"."na\t"."na\t"."xxx\n";print OUT "na\t"."na\t"."na\t"."xxx\n";print OUT "na\t"."na\t"."na\t"."xxx\n"; $indelCount = $indelCount+1}
							if ($pos_query == $resindex && $res_query ne "xxx"){print OUT "$atomnumber\t"."$atomlabel\t"."$resindexgap\t"."$reslabel\n";}		
			       
						 }
					 
					 #print "$reslabel\t".@skipped."\n";
					 
			}

close IN1;
close IN2;
close OUT;

#########################################################################################
##########  FLUX analysis     ###########################################################
#########################################################################################
print "\n\n collecting atomic fluctuation values (may take a minute)\n\n";
sleep(2);
open (OUT1, ">"."DROIDSfluctuation.txt") or die "could not create output file\n";
print OUT1 "sample\t"."pos_ref\t"."res_ref\t"."res_query\t"."atomnumber\t"."atomlabel\t"."flux_ref\t"."flux_query\n";
open(IN3, "<"."atom_residue_list_$fileIDr.txt") or die "could not open atom_residue_list.txt\n";
open(IN4, "<"."atom_residue_list_$fileIDq.txt") or die "could not open atom_residue_list.txt\n";
my @IN3 = <IN3>;
my @IN4 = <IN4>;
      for (my $i = 0; $i < scalar @IN3; $i++){ # scan atom type
			     my $IN3row = $IN3[$i];
	         my @IN3row = split(/\s+/, $IN3row); 
			     my $atomnumberR = $IN3row[0]; my $atomlabelR = $IN3row[1]; my $resnumberR = $IN3row[2]; my $reslabelR = $IN3row[3];
					 my $IN4row = $IN4[$i];
	         my @IN4row = split(/\s+/, $IN4row); 
			     my $atomnumberQ = $IN4row[0]; my $atomlabelQ = $IN4row[1]; my $resnumberQ = $IN4row[2]; my $reslabelQ = $IN4row[3];
					 #print "atom+res REF"."$atomnumberR\t"."$atomlabelR\t"."$resnumberR\t"."$reslabelR\n";	                  
					 #print "atom+res QUERY"."$atomnumberQ\t"."$atomlabelQ\t"."$resnumberQ\t"."$reslabelQ\n";
					 # assemble fluctuation data
			     for (my $ii = 0; $ii < $runsID; $ii++){  #scan flux data
	            $sample = $ii;
							open(IN5, "<"."fluct_$fileIDq"."_$ii.txt") or die "could not open fluct file for $fileIDq\n";
              open(IN6, "<"."fluct_$fileIDr"."_$ii.txt") or die "could not open fluct file for $fileIDr\n";
	            my @IN5 = <IN5>;
              my @IN6 = <IN6>;
			        $flux_query = '';
							$flux_ref = '';
							for (my $iii = 0; $iii < scalar @IN5; $iii++){
							    my $IN5row = $IN5[$iii];
									$IN5row =~ s/^\s+//;# need trim leading whitespace if present 
	                my @IN5row = split(/\s+/, $IN5row);
									my $Qtest_atom_decimal = $IN5row[0];
									my $Qtest_atom = int($Qtest_atom_decimal);
							    #print "Q "."$Qtest_atom\t"."$atomnumberQ\n";
									if($atomnumberQ eq $Qtest_atom){$flux_query = $IN5row[1];}
							  }	
							for (my $iii = 0; $iii < scalar @IN6; $iii++){
									my $IN6row = $IN6[$iii];
									$IN6row =~ s/^\s+//;# need trim leading whitespace if present 
	                my @IN6row = split(/\s+/, $IN6row);
			            my $Rtest_atom_decimal = $IN6row[0];
									my $Rtest_atom = int($Rtest_atom_decimal);
									#print "R "."$Rtest_atom\t"."$atomnumberR\n";
									if($atomnumberR eq $Rtest_atom){$flux_ref = $IN6row[1];}
							  }
							
					    if($resnumberR =~/\d/ && $flux_query=~/\d/ && $reslabelQ ne "xxx"){
							    #print "$sample\t"."$resnumberR\t"."$reslabelR\t"."$reslabelQ\t"."$atomnumberR\t"."$atomlabelR\t"."$flux_ref\t"."$flux_query\n";
							    print OUT1 "$sample\t"."$resnumberR\t"."$reslabelR\t"."$reslabelQ\t"."$atomnumberR\t"."$atomlabelR\t"."$flux_ref\t"."$flux_query\n";
							    }
							if($resnumberR =~/\d/ && $reslabelQ eq "xxx"){
							    #print "$sample\t"."$resnumberR\t"."$reslabelR\t"."$reslabelQ\t"."$atomnumberR\t"."$atomlabelR\t"."$flux_ref\t"."NA\n";
							    print OUT1 "$sample\t"."$resnumberR\t"."$reslabelR\t"."$reslabelQ\t"."$atomnumberR\t"."$atomlabelR\t"."NA\t"."NA\n";
							    }
							
							
							} 	
							
							close IN5;
              close IN6;
							
					
							}
					 
	
close IN3;
close IN4;
close OUT1;

########################################################################################
print "\n\n choose homology level for comparing backbone atom dynamics\n\n";
print " strict = collect only exact matching aligned residues\n";
print "          (e.g. position 5 -> LEU LEU)\n";
print "          (this will allow sites of mutations to be visualized later)\n\n";
print " loose  = collect any aligned residues\n";
print "          (e.g. position 5 -> LEU LEU or position 5 -> LEU ALA)\n"; 
print "          (this will NOT allow sites of mutations to be visualized later)\n\n";
# choose homology
my $homology = <STDIN>;
chop($homology);

#$homology = "loose";
#print "\nHOMOLOGY WILL BE LOOSE FOR THIS ANALYSIS\n\n";
#sleep(2);

#$homology = "strict";
#print "\nHOMOLOGY WILL BE STRICT FOR THIS ANALYSIS\n\n";
#sleep(2);


open(CTL, '>>', "DROIDS.ctl") or die "Could not open output file";
print CTL "homology\t"."$homology\t # homology as 'strict' or 'loose'\n";
close CTL;

print "\n\n averaging DROIDSfluctuations by residue\n\n";
mkdir ("atomflux") or die "please delete atomflux folder from previous run\n";
open (IN, "<"."DROIDSfluctuation.txt") or die "could not create input file\n";
my @IN = <IN>;
open (OUT2, ">"."DROIDSfluctuationAVG.txt") or die "could not create output file\n";
print OUT2 "pos_ref\t"."res_ref\t"."res_query\t"."flux_ref_avg\t"."flux_query_avg\t"."delta_flux\t"."abs_delta_flux\t"."KLdivergence\n";
@REFfluxAvg = ();
@QUERYfluxAvg = ();
$KL = 0;
for (my $j = 0; $j < scalar @IN; $j++){ # scan atom type
			     my $INrow = $IN[$j];
	         my @INrow = split(/\s+/, $INrow); 
			     my $sample = $INrow[0];
					 my $pos_ref = $INrow[1];
					 my $res_ref = $INrow[2];
					 my $res_query = $INrow[3];
					 my $atomnumber = $INrow[4];
					 my $atomlabel = $INrow[5];
					 my $flux_ref = $INrow[6];
					 my $flux_query = $INrow[7];
					 push(@REFfluxAvg, $flux_ref);
					 push(@QUERYfluxAvg, $flux_query);
					 my $INnextrow = $IN[$j+1];
	         my @INnextrow = split(/\s+/, $INnextrow); 
			     my $next_pos = $INnextrow[1];
					 print OUT "$sample\t"."$pos_ref\t"."$res_ref\t"."$res_query\t"."$atomnumber\t"."$atomlabel\t"."$flux_ref\t"."$flux_query\n";
					 
					 if ($homology eq "loose"){
					 if(($j == 1 || $pos_ref ne $next_pos) && $res_query ne "xxx"){  # loose homology = collect all aligned residues  
           open (OUT, ">"."./atomflux/DROIDSfluctuation_$next_pos.txt") or die "could not create output file\n";
           print OUT "sample\t"."pos_ref\t"."res_ref\t"."res_query\t"."atomnumber\t"."atomlabel\t"."flux_ref\t"."flux_query\n";
					                         
                          if ($pos_ref =~ m/\d/ && $j>1){
                              $statSCORE = new Statistics::Descriptive::Full; # residue avg flux - reference
                              $statSCORE->add_data (@REFfluxAvg);
					     $flux_ref_avg = $statSCORE->mean();
                              #$flux_ref_n = $statSCORE->count();
                              #print "flux_ref_n\t"."$flux_ref_n\n";
					     $statSCORE = new Statistics::Descriptive::Full; # residue avg flux - query
                              $statSCORE->add_data (@QUERYfluxAvg);
					     $flux_query_avg = $statSCORE->mean();
                              #$flux_query_n = $statSCORE->count();
                              #print "flux_query_n\t"."$flux_query_n\n";
					     $delta_flux = ($flux_query_avg - $flux_ref_avg);
					     $abs_delta_flux = abs($flux_query_avg - $flux_ref_avg);
                              # calculate JS divergence
                              open (TMP1, ">"."flux_values_temp.txt") or die "could not create temp file\n";
                              print TMP1 "flux_ref\t"."flux_query\n";
                              for (my $t = 0; $t <= scalar @REFfluxAvg; $t++){print TMP1 "$REFfluxAvg[$t]\t"; print TMP1 "$QUERYfluxAvg[$t]\n";}
                              close TMP1;
                              open (TMP2, ">"."flux_values_KL.txt") or die "could not create temp file\n";
                              close TMP2;
                              open (Rinput, "| R --vanilla")||die "could not start R command line\n";
                              print Rinput "library('FNN')\n";
                              print Rinput "data = read.table('flux_values_temp.txt', header = TRUE)\n"; 
                              $flux_ref = "data\$flux_ref"; # flux on reference residue
                              $flux_query = "data\$flux_query"; # flux on query residue
                              print Rinput "d1 = data.frame(fluxR=$flux_ref, fluxQ=$flux_query)\n";
                              #print Rinput "print(d1)\n";
                              print Rinput "myKL<-KL.dist($flux_ref, $flux_query, k=10)\n";
                              print Rinput "print(myKL[10])\n";
                              print Rinput "sink('flux_values_KL.txt')\n";
                              print Rinput "print(myKL[10])\n";
                              print Rinput "sink()\n";
                              # write to output file and quit R
                              print Rinput "q()\n";# quit R 
                              print Rinput "n\n";# save workspace image?
                              close Rinput;
                              open (TMP3, "<"."flux_values_KL.txt") or die "could not create temp file\n";
                              my @TMP3 = <TMP3>;
                              for (my $tt = 0; $tt <= scalar @TMP3; $tt++){
                              $TMP3row = $TMP3[$tt];
                              @TMP3row = split (/\s+/, $TMP3row);
                              $header = $TMP3row[0];
                              $value = $TMP3row[1];
                              #print "$header\t"."$value\n";
                              if ($header eq "[1]"){$KL = $value;}
                              }
                              if ($delta_flux <= 0){$KL = -$KL;} # make KL value negative if dFLUX is negative
                              print "my KL is "."$KL\n";
                              close TMP3;
                              print OUT2 "$pos_ref\t"."$res_ref\t"."$res_query\t"."$flux_ref_avg\t"."$flux_query_avg\t"."$delta_flux\t"."$abs_delta_flux\t"."$KL\n";
					     @REFfluxAvg = ();
                              @QUERYfluxAvg = ();
                              }
					 if ($next_pos eq ''){next;}
					 }}
					 					 
					 if ($homology eq "strict"){
					 if(($j == 1 || $pos_ref ne $next_pos) && $res_ref eq $res_query && $res_query ne "xxx"){ # strict homology = collect only exact matching residues  
           open (OUT, ">"."./atomflux/DROIDSfluctuation_$next_pos.txt") or die "could not create output file\n";
           print OUT "sample\t"."pos_ref\t"."res_ref\t"."res_query\t"."atomnumber\t"."atomlabel\t"."flux_ref\t"."flux_query\n";
					         
                          if ($pos_ref =~ m/\d/ && $j>1){
                              $statSCORE = new Statistics::Descriptive::Full; # residue avg flux - reference
                              $statSCORE->add_data (@REFfluxAvg);
					     $flux_ref_avg = $statSCORE->mean();
					     $statSCORE = new Statistics::Descriptive::Full; # residue avg flux - query
                              $statSCORE->add_data (@QUERYfluxAvg);
					     $flux_query_avg = $statSCORE->mean();
					     $delta_flux = ($flux_query_avg - $flux_ref_avg);
					     $abs_delta_flux = abs($flux_query_avg - $flux_ref_avg);
					     # calculate JS divergence
                              open (TMP1, ">"."flux_values_temp.txt") or die "could not create temp file\n";
                              print TMP1 "flux_ref\t"."flux_query\n";
                              for (my $t = 0; $t <= scalar @REFfluxAvg; $t++){print TMP1 "$REFfluxAvg[$t]\t"; print TMP1 "$QUERYfluxAvg[$t]\n";}
                              close TMP1;
                              open (TMP2, ">"."flux_values_KL.txt") or die "could not create temp file\n";
                              close TMP2;
                              open (Rinput, "| R --vanilla")||die "could not start R command line\n";
                              print Rinput "library('FNN')\n";
                              print Rinput "data = read.table('flux_values_temp.txt', header = TRUE)\n"; 
                              $flux_ref = "data\$flux_ref"; # flux on reference residue
                              $flux_query = "data\$flux_query"; # flux on query residue
                              print Rinput "d1 = data.frame(fluxR=$flux_ref, fluxQ=$flux_query)\n";
                              #print Rinput "print(d1)\n";
                              print Rinput "myKL<-KL.dist($flux_ref, $flux_query, k=10)\n";
                              print Rinput "print(myKL[10])\n";
                              print Rinput "sink('flux_values_KL.txt')\n";
                              print Rinput "print(myKL[10])\n";
                              print Rinput "sink()\n";
                              # write to output file and quit R
                              print Rinput "q()\n";# quit R 
                              print Rinput "n\n";# save workspace image?
                              close Rinput;
                              open (TMP3, "<"."flux_values_KL.txt") or die "could not create temp file\n";
                              my @TMP3 = <TMP3>;
                              for (my $tt = 0; $tt <= scalar @TMP3; $tt++){
                              $TMP3row = $TMP3[$tt];
                              @TMP3row = split (/\s+/, $TMP3row);
                              $header = $TMP3row[0];
                              $value = $TMP3row[1];
                              #print "$header\t"."$value\n";
                              if ($header eq "[1]"){$KL = $value;}
                              }
                              if ($delta_flux <= 0){$KL = -$KL;} # make KL value negative if dFLUX is negative
                              print "my KL is "."$KL\n";
                              close TMP3;
                              print OUT2 "$pos_ref\t"."$res_ref\t"."$res_query\t"."$flux_ref_avg\t"."$flux_query_avg\t"."$delta_flux\t"."$abs_delta_flux\t"."$KL\n";
					     @REFfluxAvg = ();
                              @QUERYfluxAvg = ();
                              }
					 if ($next_pos eq ''){next;}
					 }}
					 
					 
																
}
close IN;
close OUT;
close OUT2;

sleep(2);

##################################################################################################
print "\n\n done parsing CPPTRAJ data files\n\n";
sleep(2);
#################################################################################################
# create chain ID column DROIDSfluctuationAVG.txt and make chain specific output data files

print " reading control file to get chain lengths\n\n";
@lengthlist = ();
$chainlabel = '';
for (my $cl = 0; $cl < scalar @chainlist; $cl++){
     $chainlabel = $chainlist[$cl];

my $AA_count = '';

open(IN, "<"."DROIDS.ctl") or die "could not find CPPTRAJ input control file\n";
my @IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    my $INrow = $IN[$c];
    my @INrow = split (/\s+/, $INrow);
    my $header = $INrow[0];
    my $value = $INrow[1];
    #print "$header\t"."$value\n";
    if ($header eq "length$chainlabel") { $AA_count = $value; push (@lengthlist, $AA_count);}
}
close IN;
sleep(1);
}
print @chainlist;
print @lengthlist;
print "\n\n";
$pointer = 0;
$mychain = $chainlist[$pointer];
$mylength = $lengthlist[$pointer];
$prevlength = 0;
open(OUT, ">"."DROIDSfluctuationAVGchain.txt") or die "could open DROIDS DATA file\n";
open(IN, "<"."DROIDSfluctuationAVG.txt") or die "could not find DROIDS DATA file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
      chomp $INrow;
      my @INrow = split (/\s+/, $INrow);
	 if ($i == 0){print OUT "$INrow\t"."chain\n";}
      my $header = $INrow[0];
      #print "$header\t"."$mylength\t"."$mychain\n";
      if ($i > 0 && $header > $mylength){$pointer = $pointer+1; $mychain = $chainlist[$pointer]; $mylength = $lengthlist[$pointer];}
      if ($i > 0 && $header <= $mylength){print OUT "$INrow\t"."$mychain\n";}
      }
close IN;
sleep(1);
close OUT;
sleep(1);
print "chain lengths added to DROIDSfluctuationAVGchain.txt file\n\n";

#############################################
system "perl GUI_STATS_DROIDSed.pl\n";	
}

##################################################################################################


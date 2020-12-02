#!/usr/bin/perl -w
#use warnings;
#use strict;
use File::Copy;
use List::Util qw(shuffle);

# specify the path to working directory for teLeap here
open(IN, "<"."paths.ctl") or die "could not find paths.txt file\n";
my @IN = <IN>;
for (my $i = 0; $i < scalar @IN; $i++){
	 my $INrow = $IN[$i];
	 my @INrow = split (/\s+/, $INrow);
	 my $header = @INrow[0];
	 my $path = @INrow[1];
	 if ($header eq "teleap_path"){$teleap_path = $path;}
}
close IN;
print "path to teLeap .exe\t"."$teleap_path\n";

##########################################

# NOTE ctl files  intentionally reversed for teLeap prep on lp3
print "control file inputs\n\n";

open(IN, "<"."MDq.ctl") or die "could not find MD.ctl control file\n";
@IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    $INrow = $IN[$c];
    @INrow = split (/\s+/, $INrow);
    $header = $INrow[0];
    $value = $INrow[1];
    print "$header\t"."$value\n";
    if ($header eq "PDB_ID") { $PDB_IDref = $value;}
    if ($header eq "UNBOUND_ID") { $PDB_IDref_unbound = $value;}
    if ($header eq "LIGAND_ID") { $LIGAND_ID = $value;}
    if ($header eq "Force_Field") { $Force_Field = $value;}
    if ($header eq "LIGAND_Field") { $LIGAND_Field = $value;}
    if ($header eq "Number_Runs") { $Number_Runs = $value;}
    if ($header eq "Heating_Time") { $Heating_Time = $value;}
    if ($header eq "Equilibration_Time") { $Equilibration_Time = $value;}
	if ($header eq "Production_Time") { $Production_Time = $value;}
    if ($header eq "Solvation_Method") { $Solvation_Method = $value;}

}
close IN;
open(IN, "<"."MDr.ctl") or die "could not find MD.ctl control file\n";
@IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    $INrow = $IN[$c];
    @INrow = split (/\s+/, $INrow);
    $header = $INrow[0];
    $value = $INrow[1];
    print "$header\t"."$value\n";
    if ($header eq "PDB_ID") { $PDB_IDquery = $value;}
    if ($header eq "UNBOUND_ID") { $PDB_IDquery_unbound = $value;}
    
}
close IN;

#my $protein_label = $ARGV[0];
my $protein_labelR = $PDB_IDref;
my $protein_labelQ = $PDB_IDquery;
my $protein_labelR_unbound = $PDB_IDref_unbound;
my $protein_labelQ_unbound = $PDB_IDquery_unbound;
my $ligand_label = $LIGAND_ID;


my $method = $Solvation_Method; # "explicit" or "implicit"
my $prmtop;
my $igb;
my $ntb;
my $cut;

if ($method eq "explicit") {
	$prmtop = "wat"; # "vac" or "wat"
	$igb = 0;
	$ntb = 1;
	$cut = 8.5;
}

if ($method eq "implicit") {
	$prmtop = "vac"; # "vac" or "wat"
	$igb = 1;
	$ntb = 0;
	$cut = 999;
}

my $num_runs = $Number_Runs; # Number of repeated production runs
my $len_prod = $Production_Time; # Length of each production run in fs (nstlim value)
my $len_eq = $Equilibration_Time; # Length of equilibration run in fs
my $len_heat = $Heating_Time; # Length of heat run in fs
my $forcefield = $Force_Field; # specify AMBER forcefield
my $ligandfield = $LIGAND_Field; # specify AMBER DNA forcefield

=pod

if (-e "$protein_label.pdb") { print "$protein_label.pdb found\n"; }
#print "Reducing $protein_label\n";
#system("pdb4amber -i $protein_label.pdb -o reduced_$protein_label.pdb --reduce --dry 2> $protein_label"."reduce.log");# --reduce --dry");

# PDBs further reduced manually by deleting heteroatoms
=cut

####################################################################
# Ligand: Prepare the input file for tleap 
####################################################################
open(LEAP_LIGAND, ">"."$ligand_label.bat") or die "could not open LEAP file\n";
	print LEAP_LIGAND "source "."$teleap_path"."$ligandfield\n";
     print LEAP_LIGAND "source "."$teleap_path"."leaprc.water.tip3p\n";
	print LEAP_LIGAND "ligand$ligand_label = loadmol2 $ligand_label.mol2\n";
     print LEAP_LIGAND "check ligand$ligand_label\n";
     print LEAP_LIGAND "loadamberparams $ligand_label".".frcmod\n";
     print LEAP_LIGAND "saveoff ligand$ligand_label ligand.lib\n";
     print LEAP_LIGAND "saveamberparm ligand$ligand_label vac_$ligand_label.prmtop vac_$ligand_label.inpcrd\n";
     #print LEAP_LIGAND "addions ligand$ligand_label Na+ 0\n"; # only use to charge or neutralize explicit solvent
	#print LEAP_LIGAND "saveamberparm ligand$ligand_label ion_$ligand_label.prmtop ion_$ligand_label.inpcrd\n";
	print LEAP_LIGAND "solvateoct ligand$ligand_label TIP3PBOX 10.0\n";
	print LEAP_LIGAND "saveamberparm ligand$ligand_label wat"."_$ligand_label.prmtop wat"."_$ligand_label.inpcrd\n";
     print LEAP_LIGAND "quit\n";
close LEAP_LIGAND;

print "  preparing ligand input file for teLeap\n\n";
sleep(1);
####################################################################
# Protein: Prepare the input file for tleap 
####################################################################
open(LEAP_PROTEIN, ">"."$protein_labelR.bat") or die "could not open LEAP file\n";
	print LEAP_PROTEIN "source "."$teleap_path"."$forcefield\n";
	print LEAP_PROTEIN "source "."$teleap_path"."leaprc.water.tip3p\n";
     print LEAP_PROTEIN "protein$protein_labelR_unbound = loadpdb $protein_labelR_unbound.pdb\n";
	print LEAP_PROTEIN "saveamberparm protein$protein_labelR_unbound vac_$protein_labelR_unbound.prmtop vac_$protein_labelR_unbound.inpcrd\n";
	print LEAP_COMPLEX "addions complex$protein_labelR_unbound Na+ 0\n"; # to charge or neutralize explicit solvent
	print LEAP_COMPLEX "addions complex$protein_labelR_unbound Cl- 0\n"; # to charge or neutralize explicit solvent
     print LEAP_PROTEIN "saveamberparm protein$protein_labelR_unbound ion_$protein_labelR_unbound.prmtop ion_$protein_labelR_unbound.inpcrd\n";
	print LEAP_PROTEIN "solvateoct protein$protein_labelR_unbound TIP3PBOX 10.0\n";
	print LEAP_PROTEIN "saveamberparm protein$protein_labelR_unbound wat"."_$protein_labelR_unbound.prmtop wat"."_$protein_labelR_unbound.inpcrd\n";
	print LEAP_PROTEIN "quit\n";
close LEAP_PROTEIN;

print "  preparing unbound protein input file for teLeap\n\n";
sleep(1);

####################################################################
# Ligand-Protein complex: create file for tleap 
####################################################################
open(LEAP_COMPLEX, ">"."$protein_labelQ.bat") or die "could not open LEAP file\n";
	print LEAP_COMPLEX "source "."$teleap_path"."$forcefield\n";
     print LEAP_COMPLEX "source "."$teleap_path"."$ligandfield\n";
     print LEAP_COMPLEX "source "."$teleap_path"."leaprc.water.tip3p\n";
	print LEAP_COMPLEX "loadoff ligand.lib\n";
     print LEAP_COMPLEX "protein$protein_labelR_unbound = loadpdb $protein_labelR_unbound.pdb\n";
     print LEAP_COMPLEX "loadamberparams $ligand_label".".frcmod\n";
     print LEAP_COMPLEX "ligand$ligand_label = loadmol2 $ligand_label.mol2\n";
     print LEAP_COMPLEX "complex$protein_labelQ = combine{protein$protein_labelR_unbound ligand$ligand_label}\n";
     print LEAP_COMPLEX "savepdb complex$protein_labelQ complex_$protein_labelQ.pdb\n";
     print LEAP_COMPLEX "saveamberparm complex$protein_labelQ vac_$protein_labelQ.prmtop vac_$protein_labelQ.inpcrd\n";
     print LEAP_COMPLEX "addions complex$protein_labelQ Na+ 0\n"; # to charge or neutralize explicit solvent
	print LEAP_COMPLEX "addions complex$protein_labelQ Cl- 0\n"; # to charge or neutralize explicit solvent
	print LEAP_COMPLEX "saveamberparm complex$protein_labelQ ion_$protein_labelQ.prmtop ion_$protein_labelQ.inpcrd\n";
	print LEAP_COMPLEX "solvateoct complex$protein_labelQ TIP3PBOX 10.0\n";
	print LEAP_COMPLEX "saveamberparm complex$protein_labelQ wat"."_$protein_labelQ.prmtop wat"."_$protein_labelQ.inpcrd\n";
     print LEAP_COMPLEX "quit\n";
close LEAP_COMPLEX;

print "  preparing protein-ligand input file for teLeap\n\n";
sleep(1);


######################################################################
print "  edit teLeap setup if desired (e.g. change water model, box size/shape, or charging)\n";
print "  default is simple rigid 3 point model, charge neutralized with Na+\n";
print "  close .bat when done\n\n";
sleep(2);

system "gedit $ligand_label.bat\n";
system "gedit $protein_labelR.bat\n";
system "gedit $protein_labelQ.bat\n";

######################################################################################
# Run sequence through tleap: prepare topology (prmtop) and coordinate (inpcrd) files
######################################################################################
print "  running ligand input file for teLeap\n\n";
sleep(1);
open(TLEAP_LIGAND, '|-', "tleap -f $ligand_label.bat");
	print<TLEAP_LIGAND>;
close TLEAP_LIGAND;
print "  running protein input file for teLeap\n\n";
sleep(1);
open(TLEAP_PROTEIN, '|-', "tleap -f $protein_labelR.bat");
	print<TLEAP_PROTEIN>;
close TLEAP_PROTEIN;
print "  running protein-ligand input file for teLeap\n\n";
sleep(1);
open(TLEAP_COMPLEX, '|-', "tleap -f $protein_labelQ.bat");
	print<TLEAP_COMPLEX>;
close TLEAP_COMPLEX;

sleep(1);


######################################################################
print "teLeap on Reference structure is complete\n\n";


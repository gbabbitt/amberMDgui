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

###########################################################
for (my $g = 0; $g < 2; $g++){
if ($g == 0) {open(MUT, "<"."copy_list.txt");}
if ($g == 1) {open(MUT, "<"."variant_list.txt");}
#if ($g == 1) {open(MUT2, "<"."variant_ligand_list.txt");}
my @MUT = <MUT>;
#my @MUT2 = <MUT2>;
#print @MUT;
for (my $p = 0; $p < scalar @MUT; $p++){
	 if ($p == 0){next;}
      if ($g == 1 && $p == 1){next;}
      if ($g == 1 && $p == 2){next;}
      my $MUTrow = $MUT[$p];
      my @MUTrow = split (/\s+/, $MUTrow);
	 $fileIDq = $MUTrow[0];
      #if($g == 1){
      #my $MUT2row = $MUT2[$p];
      #my @MUT2row = split (/\s+/, $MUT2row);
	 #$fileIDl = $MUT2row[0];
      #}
      print "\nmaking teLeap files for $fileIDq.pdb\n";
      sleep(2);
      #############


print "control file inputs\n\n";

open(IN, "<"."MDq_deploy_$fileIDq.ctl") or die "could not find MD.ctl control file\n";
@IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    $INrow = $IN[$c];
    @INrow = split (/\s+/, $INrow);
    $header = $INrow[0];
    $value = $INrow[1];
    print "$header\t"."$value\n";
    if ($header eq "PDB_ID") { $PDB_ID = $value;}
    if ($header eq "LIGAND_ID") { $LIGAND_ID = $value;}
    if ($header eq "Force_Field") { $Force_Field = $value;}
    if ($header eq "ADD_Field") { $Add_Field = $value;}
    if ($header eq "Number_Runs") { $Number_Runs = $value;}
    if ($header eq "Heating_Time") { $Heating_Time = $value;}
    if ($header eq "Equilibration_Time") { $Equilibration_Time = $value;}
    if ($header eq "Production_Time") { $Production_Time = $value;}
    if ($header eq "Solvation_Method") { $Solvation_Method = $value;}

}
open(IN, "<"."MDr.ctl") or die "could not find MD.ctl control file\n";
@IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    $INrow = $IN[$c];
    @INrow = split (/\s+/, $INrow);
    $header = $INrow[0];
    $value = $INrow[1];
    print "$header\t"."$value\n";
    if ($header eq "PDB_ID") { $PDB_ID_ref = $value;}
    
}


#my $protein_label = $ARGV[0];
my $protein_label = $PDB_ID;
my $ligand_label = $LIGAND_ID;
my $protein_labelQ = $PDB_ID;
my $protein_labelR = $PDB_ID_ref;

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
my $addfield = $Add_Field; # specify AMBER forcefield
=pod

if (-e "$protein_label.pdb") { print "$protein_label.pdb found\n"; }
#print "Reducing $protein_label\n";
#system("pdb4amber -i $protein_label.pdb -o reduced_$protein_label.pdb --reduce --dry 2> $protein_label"."reduce.log");# --reduce --dry");

# PDBs further reduced manually by deleting heteroatoms
=cut


####################################################################
# if Ligand ID present: Prepare the input file for tleap 
####################################################################

open(LEAP_LIGAND, ">"."$ligand_label.bat") or die "could not open LEAP file\n";
	print LEAP_LIGAND "source "."$teleap_path"."$addfield\n";
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
# If Ligand-Protein complex needed: create file for tleap 
####################################################################
open(LEAP_COMPLEX, ">"."$protein_labelQ.bat") or die "could not open LEAP file\n";
	print LEAP_COMPLEX "source "."$teleap_path"."$forcefield\n";
     print LEAP_COMPLEX "source "."$teleap_path"."$addfield\n";
     print LEAP_COMPLEX "source "."$teleap_path"."leaprc.water.tip3p\n";
	print LEAP_COMPLEX "loadoff ligand.lib\n";
     #print LEAP_COMPLEX "protein$protein_labelR = loadpdb $protein_labelR.pdb\n";
     print LEAP_COMPLEX "protein$protein_label = loadpdb $protein_label.pdb\n";  # replaces line above for teLeap setup of ligand bound sims
     print LEAP_COMPLEX "loadamberparams $ligand_label".".frcmod\n";
     print LEAP_COMPLEX "ligand$ligand_label = loadmol2 $ligand_label.mol2\n";
     #print LEAP_COMPLEX "complex$protein_labelQ = combine{protein$protein_labelR ligand$ligand_label}\n";
     print LEAP_COMPLEX "complex$protein_labelQ = combine{protein$protein_label ligand$ligand_label}\n";  # replaces line above for teLeap setup of ligand bound sims
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

#system "gedit $ligand_label.bat\n";
#system "gedit $protein_labelR.bat\n";
system "gedit $protein_labelQ.bat\n";

######################################################################

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


close MUT;
#close MUT2;
} #end for loop
} # end outer for loop
######################################################################

print "teLeap on Query structure is complete\n\n";

exit;

#!/usr/bin/perl -w
#use warnings;
#use strict;
use File::Copy;
use List::Util qw(shuffle);

print "control file inputs\n\n";

open(IN, "<"."MD.ctl") or die "could not find MD.ctl control file\n";
@IN = <IN>;
for (my $c = 0; $c <= scalar @IN; $c++){
    $INrow = $IN[$c];
    @INrow = split (/\s+/, $INrow);
    $header = $INrow[0];
    $value = $INrow[1];
    print "$header\t"."$value\n";
    if ($header eq "PDB_ID") { $PDB_ID = $value;}
    if ($header eq "Force_Field") { $Force_Field = $value;}
    if ($header eq "Number_Runs") { $Number_Runs = $value;}
    if ($header eq "Heating_Time") { $Heating_Time = $value;}
    if ($header eq "Equilibration_Time") { $Equilibration_Time = $value;}
	if ($header eq "Production_Time") { $Production_Time = $value;}
    if ($header eq "Solvation_Method") { $Solvation_Method = $value;}

}

#my $protein_label = $ARGV[0];
my $protein_label = $PDB_ID;

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

=pod

if (-e "$protein_label.pdb") { print "$protein_label.pdb found\n"; }
#print "Reducing $protein_label\n";
#system("pdb4amber -i $protein_label.pdb -o reduced_$protein_label.pdb --reduce --dry 2> $protein_label"."reduce.log");# --reduce --dry");

# PDBs further reduced manually by deleting heteroatoms
=cut
####################################################################
# Protein: Prepare the input file for tleap 
####################################################################
open(LEAP_PROTEIN, ">"."$protein_label.bat") or die "could not open LEAP file\n";
	print LEAP_PROTEIN "source /home/greg/Desktop/amber16/dat/leap/cmd/leaprc.$forcefield\n";
	print LEAP_PROTEIN "source leaprc.water.tip3p\n";
	print LEAP_PROTEIN "protein$protein_label = loadpdb $protein_label.pdb\n";
	print LEAP_PROTEIN "saveamberparm protein$protein_label vac_$protein_label.prmtop vac_$protein_label.inpcrd\n";
	print LEAP_PROTEIN "addions protein$protein_label Na+ 0\n"; # only use to charge or neutralize explicit solvent
	print LEAP_PROTEIN "saveamberparm protein$protein_label ion_$protein_label.prmtop ion_$protein_label.inpcrd\n";
	print LEAP_PROTEIN "solvateoct protein$protein_label TIP3PBOX 10.0\n";
	print LEAP_PROTEIN "saveamberparm protein$protein_label wat"."_$protein_label.prmtop wat"."_$protein_label.inpcrd\n";
	print LEAP_PROTEIN "quit\n";
close LEAP_PROTEIN;

sleep(1);

######################################################################################
# Run sequence through tleap: prepare topology (prmtop) and coordinate (inpcrd) files
######################################################################################
open(TLEAP_PROTEIN, '|-', "tleap -f $protein_label.bat");
	print<TLEAP_PROTEIN>;
close TLEAP_PROTEIN;

sleep(1);

#########################################################################
# Amino Acid: Prepare (minimization, heating, production MD) input files for sander
##########################################################################

# Prepare minimization file for sander
open(SANDER_MIN_AA, ">"."$protein_label"."_min.in") or die "could not open SANDER_MINIMIZATION file\n";
	print SANDER_MIN_AA "Minimize\n";
	print SANDER_MIN_AA "&cntrl\n";
	print SANDER_MIN_AA "imin=1,\n";
	#print SANDER_MIN_AA "ntx=1,\n";
	#print SANDER_MIN_AA "irest=0,\n";
	print SANDER_MIN_AA "maxcyc=2000,\n";
	print SANDER_MIN_AA "ncyc=1000,\n";
	#print SANDER_MIN_AA "ntpr=100,\n";
	#print SANDER_MIN_AA "ntwx=100,\n";
	print SANDER_MIN_AA "cut=$cut,\n";
	print SANDER_MIN_AA "igb=$igb,\n";
	print SANDER_MIN_AA "ntb=$ntb,\n";
	print SANDER_MIN_AA "restraint_wt = 1,\n";
	print SANDER_MIN_AA "restraintmask = 1-23',\n";
	print SANDER_MIN_AA "saltcon = 0.1,\n";

	print SANDER_MIN_AA "/\n";
close SANDER_MIN_AA;

# Prepare heating file for sander
open(SANDER_HEAT_AA, ">"."$protein_label"."_heat.in") or die "could not open SANDER_HEATING file\n";
	print SANDER_HEAT_AA "Heat\n"; 
	print SANDER_HEAT_AA "&cntrl\n"; 
	print SANDER_HEAT_AA "imin=0,\n"; 		
	print SANDER_HEAT_AA "ntx=1,\n"; 		
	print SANDER_HEAT_AA "irest=0,\n"; 
	print SANDER_HEAT_AA "nstlim=$len_heat,\n"; 
	print SANDER_HEAT_AA "dt=0.002,\n"; 	
	print SANDER_HEAT_AA "ntf=2,\n"; 		
	print SANDER_HEAT_AA "ntc=2,\n"; 		
	print SANDER_HEAT_AA "tempi=0.0,\n"; 	
	print SANDER_HEAT_AA "temp0=300.0,\n"; 
	print SANDER_HEAT_AA "ntpr=100,\n"; 
	print SANDER_HEAT_AA "ntwx=100,\n"; 
	print SANDER_HEAT_AA "cut=$cut,\n"; 
	print SANDER_HEAT_AA "ntb=$ntb,\n"; 
	print SANDER_HEAT_AA "ntp=0,\n"; 
	print SANDER_HEAT_AA "ntt=3,\n"; 
	print SANDER_HEAT_AA "gamma_ln=1,\n"; 
	#print SANDER_HEAT_AA "nmropt=1,\n"; 
	print SANDER_HEAT_AA "ig=-1,\n"; 
	print SANDER_HEAT_AA "igb=$igb,\n";
	print SANDER_HEAT_AA "taup=1,\n";
	print SANDER_HEAT_AA "/\n"; 
	print SANDER_HEAT_AA "&wt type='TEMP0', istep1=0, istep2=9000, value1=0.0, value2=300.0 /\n"; 
	print SANDER_HEAT_AA "&wt type='TEMP0', istep1=9001, istep2=10000, value1=300.0, value2=300.0 /\n"; 
	print SANDER_HEAT_AA "&wt type='END' /\n"; 

close SANDER_HEAT_AA;

# Prepare heating file for sander
open(SANDER_EQ_AA, ">"."$protein_label"."_eq.in") or die "could not open SANDER_HEATING file\n";
	print SANDER_EQ_AA "Equilibration\n"; 
	print SANDER_EQ_AA "&cntrl\n"; 
	print SANDER_EQ_AA "imin=0,\n"; 		
	print SANDER_EQ_AA "ntx=1,\n"; 		
	print SANDER_EQ_AA "irest=0,\n"; 
	print SANDER_EQ_AA "nstlim=$len_eq,\n"; 
	print SANDER_EQ_AA "dt=0.002,\n"; 	
	print SANDER_EQ_AA "ntf=2,\n"; 		
	print SANDER_EQ_AA "ntc=2,\n"; 		
	print SANDER_EQ_AA "tempi=300.0,\n"; 	
	print SANDER_EQ_AA "temp0=300.0,\n"; 
	print SANDER_EQ_AA "ntpr=100,\n"; 
	print SANDER_EQ_AA "ntwx=100,\n"; 
	print SANDER_EQ_AA "cut=$cut,\n"; 
	print SANDER_EQ_AA "ntb=$ntb,\n"; 
	print SANDER_EQ_AA "ntp=0,\n"; 
	print SANDER_EQ_AA "ntt=3,\n"; 
	print SANDER_EQ_AA "gamma_ln=1,\n"; 
	#print SANDER_EQ_AA "nmropt=1,\n"; 
	print SANDER_EQ_AA "ig=-1,\n"; 
	print SANDER_EQ_AA "igb=$igb,\n";
	print SANDER_EQ_AA "taup=1,\n";
	print SANDER_EQ_AA "/\n"; 

close SANDER_EQ_AA;

# Prepare production MD input file for sander
open(SANDER_PROD_AA, ">"."$protein_label"."_prod.in") or die "could not open SANDER_PRODUCTION file\n";
	print SANDER_PROD_AA "Production\n";
	print SANDER_PROD_AA "&cntrl\n";
	print SANDER_PROD_AA "imin=0,\n";
	print SANDER_PROD_AA "ntx=1,\n";
	print SANDER_PROD_AA "irest=0,\n";
	print SANDER_PROD_AA "nstlim=$len_prod,\n";
	print SANDER_PROD_AA "dt=0.002,\n";
	print SANDER_PROD_AA "ntf=2,\n";
	print SANDER_PROD_AA "ntc=2,\n"; 
	print SANDER_PROD_AA "tempi=300.0,\n";
	print SANDER_PROD_AA "temp0=300.0,\n";
	print SANDER_PROD_AA "ntpr=200,\n";
	print SANDER_PROD_AA "ntwx=200,\n";
	print SANDER_PROD_AA "cut=$cut,\n";
	print SANDER_PROD_AA "ntb=$ntb,\n";
	print SANDER_PROD_AA "ntp=0,\n";
	print SANDER_PROD_AA "ntt=3,\n";
	print SANDER_PROD_AA "gamma_ln=1,\n";
	print SANDER_PROD_AA "ig=-1,\n";
	print SANDER_PROD_AA "igb=$igb,\n";
	#print SANDER_PROD_AA "saltcon = 0.15,\n";
	print SANDER_PROD_AA "taup=1,\n";
	 # &wt...	
	print SANDER_PROD_AA "/\n";
close SANDER_PROD_AA;
sleep(1);

my $run_method = "pmemd.cuda"; # "sander" for CPU or "pmemd.cuda" for GPU;
my $method_ID = "pmemd";
###############################################################
# Amino Acid: Run minimization in sander
###############################################################

print "\ starting min run for "."min_$protein_label.out\n";

system("export CUDA_VISIBLE_DEVICES=0\n".'$AMBERHOME'."/bin/$run_method -O -i $protein_label"."_min.in -o min_$protein_label.out -p $prmtop"."_$protein_label.prmtop -c $prmtop"."_$protein_label.inpcrd -r min_$protein_label.rst -inf min_$protein_label.mdinfo &");
#-x min_$protein_label.nc
$seconds = 0;
$timestep = 5;
my $pid = `pgrep $method_ID -c`;
chomp $pid;
#print "$pid\n";
    my $chkpid = `pgrep $method_ID -c`;
    chomp $chkpid;
    #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
    while ($pid eq $chkpid){
		#-- recheck if pmemd process is running
		sleep($timestep);
        $seconds = $seconds + $timestep;  
        my $chkpid = `pgrep $method_ID -c`;
       	chomp $chkpid;
       	#print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
        if ($pid eq $chkpid) {print "\ $seconds"." secs into min run\t"."min_$protein_label.out\n";}
	    if ($pid ne $chkpid) {$pid = ''; $chkpid = ''; print "\ end minimization run\n";}
	    #system("tail -f amino_acid_min_$protein_label.out".".out");      
	}

sleep(1);
#######################################################################
# Amino Acid: Run Heating in sander
########################################################################

print "\ starting heating run for "."heat_$protein_label.out\n";
#if (-e "$protein_label"."_heat.in") { print ".in file found\n"; }
#if (-e "heat_$protein_label.out") { print ".out file found\n"; }
#if (-e "wat_$protein_label.prmtop") { print "prmtop file found\n"; }
#if (-e "wat_$protein_label.inpcrd") { print ".inpcrd file found\n"; }
#if (-e "heat_$protein_label.rst") { print ".rst file found\n"; }
#if (-e "heat_$protein_label.nc") { print "nc found\n"; }
#if (-e "heat_$protein_label.mdinfo") { print "info file found\n"; }
system("export CUDA_VISIBLE_DEVICES=0\n"."$run_method -O -i $protein_label"."_heat.in -o heat_$protein_label.out -p $prmtop"."_$protein_label.prmtop -c min_$protein_label.rst -r heat_$protein_label.rst -x heat_$protein_label.nc -inf heat_$protein_label.mdinfo &");
#system("export CUDA_VISIBLE_DEVICES=0\n".'$AMBERHOME'."/AmberTools/bin/$run_method -O -i $protein_label"."_heat.in -o heat_$protein_label.out -p wat_$protein_label.prmtop -c wat_$protein_label.inpcrd -r heat_$protein_label.rst -x heat_$protein_label.nc -inf heat_$protein_label.mdinfo &");

$seconds = 0;
$timestep = 10;
sleep(0.5);
$pid = `pgrep $method_ID -c`;
chomp $pid;
    $chkpid = `pgrep $method_ID -c`;
    chomp $chkpid;
    #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
    while ($pid eq $chkpid){
		#-- recheck if pmemd process is running
		sleep($timestep);
        $seconds = $seconds + $timestep;  
        $chkpid = `pgrep $method_ID -c`;
       	chomp $chkpid;
        #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
        if ($pid eq $chkpid) {print "\ $seconds"." secs into heating run\t"."heat_$protein_label.out\n";}
	#if ($pid ne $chkpid) {$pid = ''; $chkpid = ''; print "\ end heating run\n";}
		#system("tail -f amino_acid_min_$protein_label.out".".out");
	}
print "\ end heating run\n";
sleep(1);

######################################################################
# Amino Acid: Run Production MD in sander
######################################################################
print "\ starting eq run for "."eq_$protein_label.out\n";
system("export CUDA_VISIBLE_DEVICES=0\n"."$run_method -O -i $protein_label"."_eq.in -o eq_$protein_label.out -p $prmtop"."_$protein_label.prmtop -c heat_$protein_label.rst -r eq_$protein_label.rst -x eq_$protein_label.nc -inf eq_$protein_label.info &");

$seconds = 0;
$timestep = 60;
sleep(0.5);
$pid = `pgrep $method_ID -c`;
print "$pid\n";
chomp $pid;
    $chkpid = `pgrep $method_ID -c`;
    chomp $chkpid;
    #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
    while ($pid eq $chkpid){
		#-- recheck if pmemd process is running
		sleep($timestep);
        $seconds = $seconds + $timestep;
		$minutes = int($seconds/60);
        $chkpid = `pgrep $method_ID -c`;
	#print "$chkpid\n";
       	chomp $chkpid;
        #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
        if ($pid eq $chkpid) {print "\ $minutes"." mins into MD run\t"."eq_$protein_label.out\n";}
	#	if ($pid ne $chkpid) {$pid = ''; $chkpid = '';}
		    #system("tail -f amino_acid_min_$protein_label.out".".out")          
	}
print "\ end eq run $protein_label\n";

sleep(1);

######################################################################
# Amino Acid: Run Production MD in sander
######################################################################
for (my $jj = 0; $jj < $num_runs; $jj++) {
print "\ starting MD run for "."prod_$protein_label"."_$jj.out\n";
system("export CUDA_VISIBLE_DEVICES=0\n"."$run_method -O -i $protein_label"."_prod.in -o prod_$protein_label"."_$jj.out -p $prmtop"."_$protein_label.prmtop -c eq_$protein_label.rst -r prod_$protein_label.rst -x prod_$protein_label"."_$jj.nc -inf prod_$protein_label"."_$jj.info &");

$seconds = 0;
$timestep = 60;
sleep(0.5);
$pid = `pgrep $method_ID -c`;
print "$pid\n";
chomp $pid;
    $chkpid = `pgrep $method_ID -c`;
    chomp $chkpid;
    #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
    while ($pid eq $chkpid){
		#-- recheck if pmemd process is running
		sleep($timestep);
        $seconds = $seconds + $timestep;
		$minutes = int($seconds/60);
        $chkpid = `pgrep $method_ID -c`;
	#print "$chkpid\n";
       	chomp $chkpid;
        #print "check pmemd PID = "."$pid\t"."$chkpid\n"; 
        if ($pid eq $chkpid) {print "\ $minutes"." mins into MD run\t"."prod_$protein_label.out\n";}
	#	if ($pid ne $chkpid) {$pid = ''; $chkpid = '';}
		    #system("tail -f amino_acid_min_$protein_label.out".".out")          
	}
print "\ end MD run $jj\n";

sleep(1);
}
######################################################################

print "\n\n NEXT STEP- 'ctl+c' then run MD again using your homologous structure\n";
print "\n AFTERWARDS - 'ctl+c' then 'perl mainpipe_DROIDS.pl'\n";

exit;

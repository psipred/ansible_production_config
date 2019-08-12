#!/bin/csh

# Form input files for DMPfold from a single sequence
# Argument is a FASTA file with a single sequence

# Set the number of CPUs to use for HHblits, PSICOV, FreeContact and CCMpred
set ncpu = 1

# Set this 444120to point to the DMPfold directory
set dmpfolddir = /data/DMPfold

# Set the following to point to the relevant HH-suite locations
setenv HHLIB /data/hh-suite
setenv HHBIN /data/hh-suite/build/bin
setenv HHDB /data/hhdb/uniclust30_2018_08/uniclust30_2018_08

# Set this to point to the CCMpred bin directory
set ccmpreddir = /data/CCMpred/bin

# Set this to point to the FreeContact command
set freecontactcmd = /data/freecontact-1.0.21/src/freecontact

# Set this to point to the legac386484y BLAST bin directory
set ncbidir = /data/blast-2.2.26/bin

set bindir = $dmpfolddir/bin

set seqfile = $1
set target = $1:t:r

limit stacksize unlimited

echo "Running HHblits"
$HHBIN/hhblits -i $seqfile -d $HHDB -o $target.hhr -oa3m $target.a3m -e 0.01 -n 3 -cpu $ncpu -diff inf -cov 10 -Z 10000 -B 10000

cat $seqfile > $target.temp.fasta

$ncbidir/formatdb -i $target.a3m -t $target.a3m

if (! -e $target.temp.solv) then
    echo "Running PSIPRED & SOLVPRED"
    $bindir/runpsipredandsolvwithdb $target.temp.fasta $target.a3m
endif

egrep -v "^>" $target.a3m | sed 's/[a-z]//g' > $target.rawaln

$bindir/gapfilt $target.rawaln 0.5 > $target.aln

if (`cat $target.aln | wc -l` >= 5) then
    if (! -e $target.psicov) then
        echo "Running PSICOV"
        timeout 7200 $bindir/psicov -z $ncpu -o -d 0.03 $target.aln > $target.psicov
    endif
    if (! -e $target.evfold) then
        echo "Running FreeContact"
        timeout 7200 $freecontactcmd -a $ncpu < $target.aln > $target.evfold
    endif
    if (! -e $target.ccmpred) then
        echo "Running CCMpred"
        timeout 7200 $ccmpreddir/ccmpred -t $ncpu $target.aln $target.ccmpred
    endif
else
    echo "Fewer than 5 sequences in alignment, not running PSICOV/FreeContact/CCMpred"
    \rm -f $target.psicov $target.evfold $target.ccmpred
    touch $target.psicov $target.evfold $target.ccmpred
endif

echo "Forming DMPfold input files"
$bindir/alnstats $target.aln $target.colstats $target.pairstats

$bindir/dmp_makepredmaps $target.colstats $target.pairstats $target.psicov $target.evfold $target.ccmpred $target.temp.ss2 $target.temp.solv $target.map $target.fix

$bindir/cov21stats $target.aln $target.21c

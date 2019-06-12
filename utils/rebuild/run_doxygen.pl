#!/usr/local/bin/perl

use strict;
use warnings;
use File::Path;
use File::Copy;
use Cwd qw(getcwd realpath);

my $MAXDEPTH       = 5;
my $installsymlink = "/phenix/WWW/offline/doxygen_sPHENIX/html";

# clean up old checkout if exists and check out phuniverse
my @cleanup = ( "offline", "simulation" );

foreach my $cdir (@cleanup) {
	if ( -d $cdir ) {
		rmtree($cdir);
	}
}

                                                     
print "#################################\n";                                               
print "git clones \n";                                                              
print "#################################\n";        

system("git clone https://github.com/sPHENIX-Collaboration/coresoftware.git");
system("mv coresoftware master");
system("mkdir -pv coresoftware/blob/");
system("mv master coresoftware/blob/");


system("git clone https://github.com/sPHENIX-Collaboration/macros.git");
system("mv macros master");
system("mkdir -pv macros/blob/");
system("mv master macros/blob/");


system("git clone https://github.com/sPHENIX-Collaboration/analysis.git");
system("mv analysis master");
system("mkdir -pv analysis/blob/");
system("mv master analysis/blob/");


system("git clone https://github.com/sPHENIX-Collaboration/tutorials.git");
system("mv tutorials master");
system("mkdir -pv tutorials/blob/");
system("mv master tutorials/blob/");

system("git clone https://github.com/sPHENIX-Collaboration/prototype.git");
system("mv prototype master");
system("mkdir -pv prototype/blob/");
system("mv master prototype/blob/");

system("git clone https://github.com/sPHENIX-Collaboration/online_distribution.git");
system("mv online_distribution master");
system("mkdir -pv online_distribution/blob/");
system("mv master online_distribution/blob/");

print "###################################################################\n";
print "WARNING: please check the local path in Doxyfile is consistent with\n";
print "this directory = " . getcwd() . "\n";
print "###################################################################\n";

# exit;

system("/opt/sphenix/utils/bin/doxygen Doxyfile");
system("cp doxy.log html/");

my $realpath = realpath($installsymlink);

print "realpath: $realpath\n";

( my $linktg, my $number ) = $realpath =~ m/(.*)\.(\d+)$/;

$number++;
if ( $number > $MAXDEPTH ) {
	$number = 1;
}

my $wipearea = sprintf( "%s.%d", $linktg, $number );
if ( -d $wipearea ) {
	rmtree($wipearea);
}
my $movecmd = sprintf( "rsync -al html/ %s/", $wipearea );
print "wipearea: $wipearea\n";
system($movecmd);
unlink $installsymlink;
symlink $wipearea, $installsymlink;
# rmtree("html");




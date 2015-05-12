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
print "git clone https://github.com/sPHENIX-Collaboration/coresoftware.git\n";                                                              
print "#################################\n";        

system("git clone https://github.com/sPHENIX-Collaboration/coresoftware.git");
system("mv coresoftware/* ./");

print "###################################################################\n";
print "WARNING: please check the local path in Doxyfile is consistent with\n";
print "this directory = " . getcwd() . "\n";
print "###################################################################\n";

# exit;

system("/opt/phenix/bin/doxygen Doxyfile");
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




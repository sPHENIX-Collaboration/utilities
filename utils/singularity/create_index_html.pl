#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $containername = "rhic_sl7_ext.simg";

my %rootversion = ();
$rootversion{"new"} = "Root5";
$rootversion{"root6"} = "Root6";

my %tarball = ();
$tarball{"opt.tar.bz2"} = "coresoftware tarball";
$tarball{"offline_main.tar.bz2"} = "OFFLINE_MAIN tarball";
$tarball{"utils.tar.bz2"} = "utilities tarball";

my $opt_help = 0;

if ($#ARGV < 0 || $opt_help>0)
{
    print "usage: create_index_html.pl <target dir>\n";
    print "options:\n";
    print "--help         : print this help\n";
    exit 1;
}

my $targetdir = $ARGV[0];

if (! -d $targetdir)
{
    print "could not find target dir: $targetdir\n";
    exit 1;
}

my $indexfile = sprintf("%s/index.html",$targetdir);
open(F, ">$indexfile");

print F "<HTML>\n";
print F "<HEAD>\n";
print F "<TITLE>sPHENIX Singularity Container Download</TITLE>\n";
print F "</HEAD>\n";
print F "<BODY>\n";
print F "<h1>Welcome to the sPHENIX singularity download page</H1>\n";
print F "";

my $fullcontainer = sprintf("%s/%s",$targetdir,$containername);

if (-f $fullcontainer)
{
    print F "<h3>\n";
    print F "<a href=\"./$containername\">rcf Singularity Container image</a><p>\n";
    print F "</h3>\n";
}

opendir (my $dh, $targetdir);
my @dirs = grep {-d "$targetdir/$_" && ! /^\.{1,2}$/} readdir($dh);
foreach my $subdir (@dirs)
{
    print F "<p>\n";
    if (exists $rootversion{$subdir})
    {
	print F "<h2>$rootversion{$subdir} build</h2>\n";
    }
    else
    {
	print F "<h2>$subdir build</h2>\n";
    }
    foreach my $tb (keys %tarball)
    {
	my $fullfile = sprintf("%s/%s/%s",$targetdir,$subdir,$tb);
	if (-f $fullfile)
	{
	    print F "<h3> <a href=\"$fullfile\">$tarball{$tb}</a></h3></br>\n";
	}
    }
}
close($dh);
print F "</BODY>\n";
print F "</HTML>\n";
close(F);

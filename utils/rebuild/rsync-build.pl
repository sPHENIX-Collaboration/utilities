#!/usr/bin/perl
# this assumes our standard setup release_<buildtype>/<buildtype>-><install dir>
use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;
use File::Copy;

my $test;
GetOptions("test"=>\$test);


if ($#ARGV < 2)
{
    print "usage: rsync-build.pl <source volume> <target volume> <buildtype>\n";
    print "arguments:\n";
    print "--test:    dry run\n";
    exit(-1);
}

my $origdir = `pwd`;
my $src = $ARGV[0];
my $target = $ARGV[1];
my $buildtype = $ARGV[2];
my $cvmfsreleasedir;
my @sp1 = split(/\//,$src);
my $origvolume = $sp1[2];


@sp1 = split(/\//,$target);
my $tgtvolume = $sp1[2];

my $logfile = sprintf("%s.log",$tgtvolume);
open(LOG,">$logfile");
print LOG "orig: $origvolume\n";
print LOG "tgt : $tgtvolume\n";

# flag if we have a new release dir, need to create a bunch of softlinks
# and release more than usual
my $targetreleasedir_exists = 1;

if (! -d $src)
{
    print LOG "source volume $src does not exist\n";
    exit(-1);
}

if (! -d $target)
{
    print LOG "target $target does not exist, you need to create it (or typo)\n";
    exit(-1);
}

my $srcreleasedir = sprintf("%s/release_%s",$src, $buildtype);

if (! -d  $srcreleasedir)
{
    print LOG "source build subdir $srcreleasedir does not exist\n";
    exit(-1);
}

my $targetreleasedir = sprintf("%s/release_%s",$target, $buildtype);
if (! -d $targetreleasedir)
{
    $targetreleasedir_exists = 0;
    $cvmfsreleasedir = sprintf("%s",$target); # need to put CVMFSRELEASE here
    my $targetlink = sprintf("%s/%s",basename($targetreleasedir),$buildtype);
    if (defined $test)
    {
	print "would create $targetreleasedir\n";
	print "would cd to $target\n";
	print "would make softlink $buildtype -> $targetlink\n";
    }
    else
    {
	mkpath($targetreleasedir);
	chdir $target;
	symlink $targetlink, $buildtype;
    }
}

my $buildsymlink = sprintf("%s/%s",$srcreleasedir, $buildtype);
if (! -e $buildsymlink)
{
    print LOG "source symlink $buildsymlink does not exist\n";
    exit(-1);
}
my $reallink = `readlink $buildsymlink`;
chomp $reallink;
my $srcdir = sprintf("%s/%s",dirname($buildsymlink),basename($reallink));
my $realtarget = sprintf("%s",basename($reallink));
print LOG "src dir $srcdir\n";
print LOG "real $realtarget\n";

my $rsynccmd = sprintf("rsync -a --delete $srcdir $targetreleasedir");
print LOG "rsync cmd: $rsynccmd\n";

$reallink =~ s/$origvolume/$tgtvolume/; # replace sphenix.sdcc.bnl.gov
if (defined $test)
{
    print "would execute $rsynccmd\n";
    print "would chdir $targetreleasedir\n";
    print "would create symlink $buildtype -> $reallink\n";
}
else
{
    system($rsynccmd);
    chdir $targetreleasedir;
    unlink $buildtype if (-e $buildtype);
    symlink $reallink, $buildtype;
    chdir $target;
    my $tgtlink = sprintf("%s/%s",basename($targetreleasedir),$realtarget);
    print LOG "tgtlink: $tgtlink\n";
    if (! -e  $realtarget)
    {
	if (! defined $cvmfsreleasedir)
	{
	    $cvmfsreleasedir = sprintf("%s",$target); # need to put CVMFSRELEASE here
	}
	print LOG "softlink $realtarget -> $tgtlink\n";
	symlink $tgtlink, $realtarget;
    }
}

open(F,"find $targetreleasedir -type l |");
while (my $softlink = <F>)
{
    chomp $softlink;
    my $slinklocation = `readlink $softlink`;
    chomp $slinklocation;
    if ($slinklocation =~ /$origvolume/)
    {
	unlink $softlink if (-e $softlink);
	$slinklocation =~ s/$origvolume/$tgtvolume/g;
	if (! -e $slinklocation)
	{
	    print LOG "slinklocation $slinklocation not found\n";
	    exit(-1);
	}
	print LOG "creating $softlink -> $slinklocation\n";
	symlink $slinklocation, $softlink;
    }
}
close(F);


my $libdir = sprintf("%s/%s/lib",$targetreleasedir,$realtarget);
chdir $libdir;
print LOG "modifying *.la files\n";
print LOG "libdir: $libdir\n";
if (! defined $test)
{
    open(F,"find $libdir -maxdepth 1 -name '*.la' |");
    while (my $lafile = <F>)
    {
	chomp $lafile;
	open(F2,">tmpfile");
	open(F1,"$lafile");
	while (my $line = <F1>)
	{
	    $line =~ s/$origvolume/$tgtvolume/g;
	    print F2 $line;
	}
	close(F1);
	close(F2);
	move("tmpfile",$lafile);
    }
    close(F);
}

if (! defined $cvmfsreleasedir)
{
    $cvmfsreleasedir = $targetreleasedir;
}
if (! -d $cvmfsreleasedir)
{
    print LOG "$cvmfsreleasedir not found\n";
}
else
{
    my $touchcmd = sprintf("touch %s/CVMFSRELEASE",$cvmfsreleasedir);
    print LOG "executing $touchcmd\n";
    system($touchcmd);
}

close(LOG);

#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use Cwd;
use Env;
use File::Basename;

my $opt_all = 0;
my $opt_singularity = 0;
my $opt_optsphenix = 0;
my $opt_offline = 0;
GetOptions('all' => \$opt_all, 'singularity' => \$opt_singularity, 'opt' => \$opt_optsphenix, 'offline' => \$opt_offline);

if ($#ARGV < 0)
{
    print "usage: copy_to_target_area.pl <target dir>\n";
    print "options:\n";
    print "--all          : copy container, opt area and offline_main tar balls\n";
    print "--opt          : create and copy opt area tar ball\n";
    print "--offline      : create and copy offline_main tar ball\n";
    print "--singularity  : copy container\n";
    exit 1;
}
print "OFF: $OFFLINE_MAIN\n";
my $targetdir = $ARGV[0];
my $sourcedir = sprintf("/cvmfs/sphenix.sdcc.bnl.gov");
my $singularity_container = sprintf("%s/singularity/rhic_sl7_ext.simg",$sourcedir);
my $opt_dir = sprintf("/opt/sphenix/core");
my $opt_tmp_tarfile = sprintf("/tmp/opt.tar");
my @opt_dir_list = ("/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/bin",
                    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/etc",
                    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/include",
                    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/share",
		    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/stow",
		    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/lhapdf",
		    "/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/opt/sphenix/core/lhapdf-5.9.1");
my $offline_tmp_tarfile = sprintf("/tmp/offline_main.tar");
if (! -d $targetdir)
{
    print "target directory $targetdir does not exist\n";
    exit 1;
}

if ($opt_singularity > 0 || $opt_all > 0)
{
    print "copying singularity container\n";
    copy($singularity_container, $targetdir);
}
my $curdir = getcwd();
if ($opt_optsphenix > 0 || $opt_all > 0)
{
    my $rootdir = sprintf("%s/root",$OFFLINE_MAIN);
    my $g4dir = sprintf("%s/geant4",$OFFLINE_MAIN);
    my $rootlink = readlink($rootdir);
    my $g4link = readlink($g4dir);
    my $tarcmd = sprintf("tar -cf %s %s",$opt_tmp_tarfile,$rootlink);
    print "tarcmd: $tarcmd\n";
    system($tarcmd);
    my $rootsoftl = sprintf("%s/root",dirname($rootlink));
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$rootsoftl);
    print "tarcmd: $tarcmd\n";
    system($tarcmd);
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$g4link);
    print "tarcmd: $tarcmd\n";
    system($tarcmd);
    my $g4softl = sprintf("%s/geant4",dirname($g4link));
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$g4softl);
    print "tarcmd: $tarcmd\n";
    system($tarcmd);
    foreach my $dir (@opt_dir_list)
    {
	$tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$dir);
        print "tarcmd: $tarcmd\n";
	system($tarcmd);
    }
    my $zipcmd = sprintf("bzip2 %s",$opt_tmp_tarfile);
    system($zipcmd);
    my $zipfile = sprintf("%s.bz2",$opt_tmp_tarfile);
    print "moving $zipfile to $targetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $targetdir);
    }
    else
    {
	print "could not find $zipfile\n";
	exit 1;
    }
}

if ($opt_offline > 0 || $opt_all > 0)
{
    my $offline_symlink = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/x8664_sl7/release/release_new/new");
    my $tarcmd = sprintf("tar -cf %s %s",$offline_tmp_tarfile,$offline_symlink);
    print "executing $tarcmd\n";
    system($tarcmd);
    $tarcmd = sprintf("tar -caf %s %s",$offline_tmp_tarfile,$OFFLINE_MAIN);
    print "executing $tarcmd\n";
    system($tarcmd);
    my $zipcmd = sprintf("bzip2 %s",$offline_tmp_tarfile);
    system($zipcmd);
    my $zipfile = sprintf("%s.bz2",$offline_tmp_tarfile);
    print "moving $zipfile to $targetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $targetdir);
    }
    else
    {
	print "could not find $zipfile\n";
	exit 1;
    }
}



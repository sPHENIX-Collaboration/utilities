#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use File::Path;
use Cwd;
use Env;
use File::Basename;

my $opt_all = 0;
my $opt_singularity = 0;
my $opt_optsphenix = 0;
my $opt_optutils = 0;
my $opt_offline = 0;
my $opt_help = 0;
my $opt_sysname = 'x8664_sl7';
my $opt_test = 0;
my $opt_version = 'new';
GetOptions('all' => \$opt_all, 'help' => \$opt_help, 'offline' => \$opt_offline, 'opt' => \$opt_optsphenix, 'utils' => \$opt_optutils, 'singularity' => \$opt_singularity, 'test' => \$opt_test, 'version:s' => \$opt_version, 'sysname:s' => \$opt_sysname);

my $currdir = getcwd();

if ($#ARGV < 0 || $opt_help>0)
{
    print "usage: copy_to_target_area.pl <target dir>\n";
    print "options:\n";
    print "--all          : copy container, opt area and offline_main tar balls\n";
    print "--help         : print this help\n";
    print "--offline      : create and copy offline_main tar ball\n";
    print "--opt          : create and copy opt area tar ball\n";
    print "--singularity  : copy container\n";
    print "--sysname      : system name (x8664_sl7 [default] or gcc 8.3)\n";
    print "--test         : dryrun, print commands but do not execute them\n";
    print "--utils        : create and copy utils area tar ball\n";
    exit 1;
}
if (!$opt_all && !$opt_singularity && !$opt_optsphenix && !$opt_offline && !$opt_optutils)
{
    print "no tarball selected, select --all for all, --offline for offline, --opt for opt --utils for utils\n";
    exit 1;
}

# get the version (new, root6, ...)
my $version = basename($OFFLINE_MAIN);
$version =~ s/\..{1,}//; # remove decimal point and version (1-n), even for ana build
if ($version ne $opt_version)
{
    print "OFFLINE_MAIN version $version does not match requested version $opt_version\n";
    print "source the sphenix_setup script like:\n";
    print "source /cvmfs/sphenix.sdcc.bnl.gov/$opt_sysname/opt/sphenix/core/bin/sphenix_setup.csh -n $opt_version\n";
    print "and try again\n";
    exit 1;
}

if ($OFFLINE_MAIN !~ /$opt_sysname/)
{
    print "OFFLINE_MAIN does not match requested sysname $opt_sysname\n";
    print "source /cvmfs/sphenix.sdcc.bnl.gov/$opt_sysname/opt/sphenix/core/bin/sphenix_setup.csh -n $opt_version\n";
    print "and try again\n";
    exit 1;
}

my $targetdir = $ARGV[0];
my $sourcedir = sprintf("/cvmfs/sphenix.sdcc.bnl.gov");
my $singularity_container = sprintf("%s/singularity/rhic_sl7_ext.simg",$sourcedir);
my $opt_tmp_tarfile = sprintf("/tmp/opt.tar");
my $utils_tmp_tarfile = sprintf("/tmp/utils.tar");
my $core_basedir = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/opt/sphenix/core",$opt_sysname);
my @opt_dir_list = (sprintf("%s/bin",$core_basedir),
                    sprintf("%s/etc",$core_basedir),
                    sprintf("%s/include",$core_basedir),
                    sprintf("%s/lib",$core_basedir),
                    sprintf("%s/share",$core_basedir),
		    sprintf("%s/stow",$core_basedir),
		    sprintf("%s/lhapdf",$core_basedir),
		    sprintf("%s/lhapdf-5.9.1",$core_basedir));
if ($opt_sysname =~ /gcc-8.3/)
 {
    push(@opt_dir_list,sprintf("%s/binutils",$core_basedir));
    push(@opt_dir_list,sprintf("%s/gcc",$core_basedir));
}
my $offline_tmp_tarfile = sprintf("/tmp/offline_main.tar");
if (! -d $targetdir)
{
    print "target directory $targetdir does not exist\n";
    exit 1;
}

if ($opt_singularity > 0 || $opt_all > 0)
{
    print "copying singularity container\n";
    if (! $opt_test)
    {
	copy($singularity_container, $targetdir);
        chdir $targetdir;
        my $singularity_container_name = basename($singularity_container);
	my $make_md5 = sprintf("md5sum %s > %s.md5",$singularity_container_name,$singularity_container_name);
	system($make_md5);
	chdir $currdir;
    }
}

my $curdir = getcwd();
if ($opt_optsphenix > 0 || $opt_all > 0)
{
    my $opttargetdir = sprintf("%s/%s/%s",$targetdir,$opt_sysname,$opt_version);
    if (! $opt_test)
    {
	mkpath($opttargetdir);
    }
    my $rootdir = sprintf("%s/root",$OFFLINE_MAIN);
    my $g4dir = sprintf("%s/geant4",$OFFLINE_MAIN);
    my $rootlink = readlink($rootdir);
    my $g4link = readlink($g4dir);
    my $tarcmd = sprintf("tar -cf %s %s",$opt_tmp_tarfile,$rootlink);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    my $rootsoftl = sprintf("%s/root",dirname($rootlink));
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$rootsoftl);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd)
    };
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$g4link);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    my $g4softl = sprintf("%s/geant4",dirname($g4link));
    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$g4softl);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    foreach my $dir (@opt_dir_list)
    {
	$tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$dir);
        print "tarcmd: $tarcmd\n";
	if (! $opt_test)
	{
	    system($tarcmd);
	}
    }
    my $zipcmd = sprintf("bzip2 %s",$opt_tmp_tarfile);
    if (! $opt_test)
    {
	system($zipcmd);
    }
    my $zipfile = sprintf("%s.bz2",$opt_tmp_tarfile);
    print "moving $zipfile to $opttargetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $opttargetdir);
        chdir $opttargetdir;
        my $zipfile_name = basename($zipfile);
	my $make_md5 = sprintf("md5sum %s > %s.md5",$zipfile_name,$zipfile_name);
	system($make_md5);
	chdir $currdir;
    }
    else
    {
	if (! $opt_test)
	{
	    print "could not find $zipfile\n";
	    exit 1;
	}
    }
}
if ($opt_optutils > 0 || $opt_all > 0)
{
    my $opttargetdir = sprintf("%s/%s/%s",$targetdir,$opt_sysname,$opt_version);
    if (! $opt_test)
    {
	mkpath($opttargetdir);
    }
    my $utilsdir = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/opt/sphenix/utils",$opt_sysname);
    my $tarcmd = sprintf("tar  -cf %s %s",$utils_tmp_tarfile,$utilsdir);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    my $zipcmd = sprintf("bzip2 %s",$utils_tmp_tarfile);
    if (! $opt_test)
    {
	system($zipcmd);
    }
    my $zipfile = sprintf("%s.bz2",$utils_tmp_tarfile);
    print "moving $zipfile to $opttargetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $opttargetdir);
        chdir $opttargetdir;
        my $zipfile_name = basename($zipfile);
	my $make_md5 = sprintf("md5sum %s > %s.md5",$zipfile_name,$zipfile_name);
	system($make_md5);
	chdir $currdir;
    }
    else
    {
	if (! $opt_test)
	{
	    print "could not find $zipfile\n";
	    exit 1;
	}
    }
}

if ($opt_offline > 0 || $opt_all > 0)
{
    my $offtargetdir = sprintf("%s/%s/%s",$targetdir,$opt_sysname,$opt_version);
    if (! $opt_test)
    {
      mkpath($offtargetdir);
    }
    my $offline_symlink = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/release/release_%s/%s",$opt_sysname,$opt_version,$opt_version);
    my $tarcmd = sprintf("tar -cf %s %s",$offline_tmp_tarfile,$offline_symlink);
    print "executing $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    $offline_symlink = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/release/%s",$opt_sysname,$opt_version);
    $tarcmd = sprintf("tar -rf %s %s",$offline_tmp_tarfile,$offline_symlink);
    print "executing $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    $tarcmd = sprintf("tar -rf %s %s",$offline_tmp_tarfile,$OFFLINE_MAIN);
    print "executing $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    my $zipcmd = sprintf("bzip2 %s",$offline_tmp_tarfile);
    if (! $opt_test)
    {
	system($zipcmd);
    }
    my $zipfile = sprintf("%s.bz2",$offline_tmp_tarfile);
    print "moving $zipfile to $offtargetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $offtargetdir);
        chdir $offtargetdir;
        my $zipfile_name = basename($zipfile);
	my $make_md5 = sprintf("md5sum %s > %s.md5",$zipfile_name,$zipfile_name);
	system($make_md5);
	chdir $currdir;
    }
    else
    {
	if (! $opt_test)
	{
	    print "could not find $zipfile\n";
	    exit 1;
	}
    }
}


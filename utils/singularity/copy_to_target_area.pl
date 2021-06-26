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
my $opt_help = 0;
my $opt_mceg = 0;
my $opt_optsphenix = 0;
my $opt_optutils = 0;
my $opt_offline = 0;
my $opt_singularity = 0;
my $opt_sysname = 'gcc-8.3';
my $opt_test = 0;
my $opt_version = 'new';
my $opt_sourcevol = 'sphenix.sdcc.bnl.gov';
my $opt_subdir;
GetOptions('all' => \$opt_all, 'help' => \$opt_help, 'mceg' =>\$opt_mceg, 'offline' => \$opt_offline, 'opt' => \$opt_optsphenix, 'utils' => \$opt_optutils, 'singularity' => \$opt_singularity, 'test' => \$opt_test, 'version:s' => \$opt_version, 'sourcevolume:s' => \$opt_sourcevol, 'subdir:s' => \$opt_subdir, 'sysname:s' => \$opt_sysname);

my $optdir = "sphenix";
if ($opt_sourcevol !~ /sphenix/)
{
    $optdir = "fun4all";
}

my $currdir = getcwd();

if ($#ARGV < 0 || $opt_help>0)
{
    print "usage: copy_to_target_area.pl <target dir>\n";
    print "options:\n";
    print "--all          : copy container, opt area and offline_main tar balls\n";
    print "--help         : print this help\n";
    print "--mceg         : create and copy MCEG area\n";
    print "--offline      : create and copy offline_main tar ball\n";
    print "--opt          : create and copy opt area tar ball\n";
    print "--singularity  : copy container\n";
    print "--sourcevolume : cvmfs source volume\n";
    print "--sysname      : system name (x8664_sl7 [old] or gcc 8.3 [default])\n";
    print "--subdir       : subdirectory under source volume\n";
    print "--test         : dryrun, print commands but do not execute them\n";
    print "--utils        : create and copy utils area tar ball\n";
    exit 1;
}
if (!$opt_all && !$opt_singularity && !$opt_optsphenix && !$opt_offline && !$opt_optutils && !$opt_mceg)
{
    print "no tarball selected, select --all for all, --offline for offline, --opt for opt --utils for utils, --mceg for Monte Carlos\n";
    exit 1;
}

# get the version (new, root6, ...)
my $version = basename($OFFLINE_MAIN);
$version =~ s/\..{1,}//; # remove decimal point and version (1-n), even for ana build
if ($version ne $opt_version)
{
    print "OFFLINE_MAIN version $version does not match requested version $opt_version\n";
    print "source the sphenix_setup script like:\n";
    if (!defined $opt_subdir)
    {
	print "source /cvmfs/$opt_sourcevol/$opt_sysname/opt/$optdir/core/bin/sphenix_setup.csh -n $opt_version\n";
    }
    else
    {
	print "source /cvmfs/$opt_sourcevol/$opt_subdir/$opt_sysname/opt/$optdir/core/bin/sphenix_setup.csh -n $opt_version\n";
    }

    print "and try again\n";
    exit 1;
}

if ($OFFLINE_MAIN !~ /$opt_sysname/)
{
    print "OFFLINE_MAIN does not match requested sysname $opt_sysname\n";
    print "source /cvmfs/$opt_sourcevol/$opt_sysname/opt/$optdir/core/bin/sphenix_setup.csh -n $opt_version\n";
    print "and try again\n";
    exit 1;
}

my $targetdir = $ARGV[0];
my $sourcedir = sprintf("/cvmfs/%s",$opt_sourcevol);
my $tmpdir = sprintf("/tmp/%s_%s_%s",$opt_sourcevol,$opt_sysname,$opt_version);
if (defined $opt_subdir)
{
    $sourcedir = sprintf("/cvmfs/%s/%s",$opt_sourcevol,$opt_subdir);
    $tmpdir = sprintf("/tmp/%s_%s_%s_%s",$opt_sourcevol,$opt_subdir,$opt_sysname,$opt_version);
}
mkpath($tmpdir);
my $singularity_container = sprintf("%s/singularity/rhic_sl7_ext.simg",$sourcedir);
my $opt_tmp_tarfile =sprintf("%s/opt.tar",$tmpdir);
my $mceg_tmp_tarfile = sprintf("%s/MCEG.tar",$tmpdir);
my $utils_tmp_tarfile = sprintf("%s/utils.tar",$tmpdir);
my $core_basedir = sprintf("/cvmfs/%s/%s/opt/%s/core",$opt_sourcevol,$opt_sysname,$optdir);

if (defined $opt_subdir)
{
 $core_basedir = sprintf("/cvmfs/%s/%s/%s/opt/%s/core",$opt_sourcevol,$opt_subdir,$opt_sysname,$optdir);
}

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
    push(@opt_dir_list,sprintf("%s/calibrations",$core_basedir));
    push(@opt_dir_list,sprintf("%s/fieldmaps",$core_basedir));
    push(@opt_dir_list,sprintf("/cvmfs/%s/default",$opt_sourcevol));
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

if ($opt_mceg > 0 || $opt_all > 0)
{
    my $opttargetdir = sprintf("%s/%s/%s",$targetdir,$opt_sysname,$opt_version);
    if (! $opt_test)
    {
	mkpath($opttargetdir);
    }
    my $mcegdir = sprintf("/cvmfs/%s/%s/MCEG",$opt_sourcevol,$opt_sysname);
    my $tarcmd = sprintf("tar  -cf %s %s",$mceg_tmp_tarfile,$mcegdir);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    my $zipcmd = sprintf("bzip2 %s",$mceg_tmp_tarfile);
    if (! $opt_test)
    {
	system($zipcmd);
    }
    my $zipfile = sprintf("%s.bz2",$mceg_tmp_tarfile);
    print "moving $zipfile to $targetdir\n";
    if (-f $zipfile)
    {
	move($zipfile, $targetdir);
        chdir $targetdir;
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

if ($opt_optsphenix > 0 || $opt_all > 0)
{
    my $opttargetdir = sprintf("%s/%s/%s",$targetdir,$opt_sysname,$opt_version);
    if (! $opt_test)
    {
	mkpath($opttargetdir,0,0750);
    }
    my $rootdir = sprintf("%s/root",$OFFLINE_MAIN);
    my $g4dir = sprintf("%s/geant4",$OFFLINE_MAIN);
    my $rootlink = readlink($rootdir);
    my $g4link = readlink($g4dir);
    if ($opt_sourcevol !~ /sphenix/)
    {
	$rootlink =~ s/sphenix/fun4all/;
	$g4link =~ s/sphenix/fun4all/;
    }
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
	if (-e $dir)
	{
	    $tarcmd = sprintf("tar  -rf %s %s",$opt_tmp_tarfile,$dir);
	    print "tarcmd: $tarcmd\n";
	    if (! $opt_test)
	    {
		system($tarcmd);
	    }
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
	mkpath($opttargetdir,0,0750);
    }
    my $utilsdir = sprintf("/cvmfs/%s/%s/opt/%s/utils",$opt_sourcevol,$opt_sysname,$optdir);
if (defined $opt_subdir)
{
    $utilsdir = sprintf("/cvmfs/%s/%s/%s/opt/%s/utils",$opt_sourcevol,$opt_subdir,$opt_sysname,$optdir);
}
    my $stowdir = sprintf("%s/stow",$utilsdir);
    my %restowlist = ();
    if (-f "utils_restow.list")
    {
	open(F,"utils_restow.list");
	while (my $line=<F>)
	{
	    chomp $line;
	    $restowlist{$line} = 1;
	}
	close(F);
    }
    chdir $stowdir;
    foreach my $pkg (keys %restowlist)
    {
	my $dirname = sprintf("./%s",$pkg);
	if (! -d $dirname)
	{
	    delete $restowlist{$pkg};
	    next;
	}
	my $unstowcmd = sprintf("stow -D %s",$pkg);
	print "executing $unstowcmd\n";
	system($unstowcmd);
    }
    chdir $currdir;
    my $excludelist = "";
    if (-f "utils_no_tar.list")
    {
	open(F,"utils_no_tar.list");
	while (my $line=<F>)
	{
            chomp $line;
	    $excludelist = sprintf("%s --exclude \'%s\' ",$excludelist,$line);
	}
	close(F);
    }
    my $tarcmd = sprintf("tar  -cf %s %s %s",$utils_tmp_tarfile,$excludelist,$utilsdir);
    print "tarcmd: $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    chdir $stowdir;
    foreach my $pkg (keys %restowlist)
    {
	my $stowcmd = sprintf("stow %s",$pkg);
	my $cvmfscatfile = sprintf("%s/.cvmfscatalog",$pkg);
        unlink $cvmfscatfile;
	print "executing $stowcmd\n";
	system($stowcmd);
        my $touchcmd = sprintf("touch %s",$cvmfscatfile);
        system($touchcmd);
    }
    chdir $currdir;
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
      mkpath($offtargetdir,0,0750);
    }
    my $offline_symlink = sprintf("/cvmfs/%s/%s/release/release_%s/%s",$opt_sourcevol,$opt_sysname,$opt_version,$opt_version);
    if (defined $opt_subdir)
    {
	$offline_symlink = sprintf("/cvmfs/%s/%s/%s/release/release_%s/%s",$opt_sourcevol,$opt_subdir,$opt_sysname,$opt_version,$opt_version);
    }
    my $tarcmd = sprintf("tar -cf %s %s",$offline_tmp_tarfile,$offline_symlink);
    print "executing $tarcmd\n";
    if (! $opt_test)
    {
	system($tarcmd);
    }
    $offline_symlink = sprintf("/cvmfs/%s/%s/release/%s",$opt_sourcevol,$opt_sysname,$opt_version);
    if (defined $opt_subdir)
    {
	$offline_symlink = sprintf("/cvmfs/%s/%s/%s/release/%s",$opt_sourcevol,$opt_subdir,$opt_sysname,$opt_version);
    }
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
rmtree($tmpdir);

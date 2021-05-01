#! /usr/bin/perl

# This script rebuilds the sPHENIX/EIC code base.  It checks out code from git,
# compiles it, and installs it in the appropriate directories in cvmfs (or AFS).
# In order for this script to work with afs, you need an AFS token (for
# installation).
use warnings;
use FindBin qw($Bin);
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Copy;
use File::Find;
use Getopt::Long;
use Time::Local;
use Config;
use Cwd qw(getcwd realpath);
use Env;
use POSIX;
#use strict;

sub SaveGitTagsToDB;
sub check_git_branch;
sub printhelp;
sub install_scanbuild_reports;
sub create_afs_taxi_dir;
sub check_expiration_date;
sub doSystemFail;
sub CreateCmakeCommand;

Env::import();

if ($#ARGV < 0)
{
    printhelp();
}
# save cmd args for echoing into logfile
my $cmdline = "build.pl";
for (my $arg = 0; $arg <= $#ARGV; $arg++)
{
    $cmdline = $cmdline . " $ARGV[$arg]";
}

if (! defined $OPT_SPHENIX)
{
    die "$OPT_SPHENIX not set - forgot to source the setup script?";
}

umask 002;
$MAIL = '/bin/mail';
my $SENDMAIL = "/usr/sbin/sendmail -t";
my $buildmanager = "pinkenburg\@bnl.gov";
my $CC = $buildmanager;

my %externalPackages = (
    "BeastMagneticField" => "BeastMagneticField",
    "boost" => "boost",
    "CGAL" => "CGAL",
    "CLHEP" => "CLHEP",
    "Eigen" => "Eigen",
    "EvtGen" => "EvtGen",
    "fastjet" => "fastjet",
    "gsl" => "gsl",
    "HepMC" => "HepMC",
    "log4cpp" => "log4cpp",
    "PHOTOS" => "PHOTOS",
    "pythia8" => "pythia8",
    "rapidjson" => "rapidjson",
    "rave" => "rave",
    "TAUOLA" => "TAUOLA",
    "tbb" => "tbb",
    "Vc" => "Vc"
    );
my $externalPackagesDir = "$OPT_SPHENIX";
my %externalRootPackages = (
    "DD4hep" => "DD4hep",
    "eic-smear" => "eic-smear",
    "EicToyModel" => "EicToyModel",
    "HepMC3" => "HepMC3",
    "KFParticle" => "KFParticle",
    "pythiaeRHIC" => "pythiaeRHIC",
    "sartre" => "sartre",
    "vgm" => "vgm"
    );
my $rootversion = `root-config --version`;
chomp $rootversion;
$rootversion =~ s/\//\./g;
# Keep track of where we were and when it was that we got underway
my $starttime = time;
my $date = `date`;
chomp $date;
my $cwd = getcwd;

my $buildSucceeded = 0;

# Set up some defaults for script options
my $default_repoowner = "sPHENIX-Collaboration";
$opt_gittag = '';
$opt_gitbranch = '';
$opt_version = 'new';
$opt_stage = 0;
$opt_db = 0;
$opt_scanbuild = 0;
$opt_coverity = 0;
$opt_lafiles = 0;
$opt_help = 0;
$opt_afs = 0;
$opt_repoowner = $default_repoowner;
$opt_includecheck = 0;
$opt_clang = 0;
$opt_sysname = 'default';
$opt_cvmfsvol = 'sphenix.sdcc.bnl.gov';
$opt_actsbranch = 'sPHENIX';

GetOptions('help', 'stage=i', 'afs',
           'version:s', 'tinderbox', 'gittag:s', 'gitbranch:s','source:s',
           'phenixinstall','workdir:s','insure','scanbuild',
           'coverity','covpasswd:s','notify','64', 'db:i', 'lafiles',
           'repoowner:s', 'includecheck', 'clang', 'sysname:s', 'cvmfsvol:s',
           'eic', 'actsbranch:s', 'ecce');

if ($opt_help)
  {
      printhelp();
  }

# Read in list of repositories
my @gitrepos = ();
my $repositoryfile = sprintf("%s/repositories.txt",$Bin);
my $packagefile = sprintf("%s/packages.txt",$Bin);
my $collaboration = "sPHENIX";
if ($opt_ecce)
{
 $repositoryfile = sprintf("%s/ecce-repositories.txt",$Bin);
 $packagefile = sprintf("%s/ecce-packages.txt",$Bin);
 $collaboration = "ECCE-EIC";
}
if ($opt_eic)
{
 $repositoryfile = sprintf("%s/eic-repositories.txt",$Bin);
 $packagefile = sprintf("%s/eic-packages.txt",$Bin);
 $collaboration = "EIC";
}
die unless open(IN,$repositoryfile);
while (<IN>)
  {
    next if (/^#/);
    chomp $_;
    push @gitrepos, $_;
  }
close(IN);
# Read in list of packages and contacts
my @package = ();
my %contact = ();
die unless open(IN,$packagefile);
while (<IN>)
{
    next if (/^#/);
    if ($_ =~ /acts/ && $opt_sysname !~ /gcc-8.3/)
    {
        next;
    }
    (my $p, my $c) = split(/\|/, $_, 2);
# remove \n at end of $c
             chomp $c;
    push @package, $p;
    $contact{$p} = $c;
  }
close(IN);

my $dbh;
if ( $opt_db && $opt_version !~ /pro/)
{
    use DBI;
    $dbh = DBI->connect("dbi:ODBC:phnxbld") || die $DBI::error;
    my $getpackages = $dbh->prepare("select package,contact from anatrainmodules where status > 0 order by ordering");
    $getpackages->execute() || die $DBI::error;
    while(my @pkts = $getpackages->fetchrow_array())
    {
        push @package, $pkts[0];
        $contact{$pkts[0]} = $pkts[1];
    }

    $getpackages->finish();
}

# only run 120 parallel build jobs if distcc is in the path (it is not
# right now), otherwise run numjobs = number of cores
# the -l adjusts for load, if the load is number of cores all cores are busy
# to first order (disk load goes into the load as well)
my $numcores  = do { local @ARGV='/proc/cpuinfo'; grep /^processor\s+:/, <>;};
my $JOBS = sprintf("-l %d -j %d", $numcores, $numcores);

my $MAXDEPTH = ($opt_version =~ m/pro/ || $opt_version =~ /ana/ || $opt_version =~ /mdc/ ) ? 9999999 : 4;
$opt_version .= '+insure' if $opt_insure;
# number of parallel builds with insure
if ($numcores > 25) {$numcores=25;} # we have 50 insure licenses, only use 1/2 maximum
$JOBS = sprintf("-j %d",$numcores) if $opt_insure;
$MAXDEPTH = 4 if $opt_insure;

$workdir = $opt_workdir ? $opt_workdir : '/home/'. $USER . '/' . $collaboration;
my $myhost = `hostname`;
chomp $myhost;
$startTime = time;
$sysname = $USER.'@'.$myhost.'#'.$Config{osname}.':'.$opt_version;
$compileFlags = ($sysname =~ m/linux/) ? ' INSTALL="/usr/bin/install -D -p" install_sh="/usr/bin/install -D -p"' : "";
$insureCompileFlags = " ";

$workdir .= "/$opt_version";

# Set up the working area: directories for source, build and install.
make_path($workdir, {mode => 0775}) unless -e $workdir;

# everything we need to do the scan build
# scan-build just goes in front of autogen.sh and make
# if we want to make a scan-build
# some packages do not build with scan-build (assembler)
# read them from config file
my $scanbuild = "";
my $scanlogdir = "";
my %scanbuildignore = ();
if ($opt_scanbuild)
{
    $scanlogdir = $workdir . "/scanlog";
    $scanbuild = sprintf("scan-build -plist-html -disable-checker deadcode.DeadStores -disable-checker core.NullDereference -k -o %s",$scanlogdir);
    make_path($scanlogdir, {mode => 0775}) unless -e $scanlogdir;
    my $ignorefile = $Bin . "/scanbuild_ignore.txt";
    if (-f  $ignorefile)
    { 
        open(F,"$ignorefile");
        while(my $line = <F>)
        {
            chomp $line;
            $scanbuildignore{$line} = 1;
        }
        close(F);
    }
#    else
#    {
#        print "could not find $ignorefile\n;"
#    }
}

my $covbuild = "";
my $covlogdir = "";
my %coverityignore = ();
if ($opt_coverity)
{
   $covcommonbuild = sprintf("cov-build");
    my $ignorefile = $Bin . "/coverityhtml_ignore.txt";
    if (-f  $ignorefile)
    { 
        open(F,"$ignorefile");
        while(my $line = <F>)
        {
            chomp $line;
            $coverityignore{$line} = 1;
        }
        close(F);
    }
    else
    {
        print "could not find $ignorefile\n;"
    }
   
}

$logfile = $workdir.'/rebuild.log';
open(LOG, ">$logfile");
select LOG;
$| = 1;
print LOG "Welcome to the ",$collaboration," $sysname rebuild \n started at ",$date,"\n";
# print how we were called
print LOG "How this script was called:\n";
print LOG "$cmdline\n\n";

# temporary until the new versions are okay to use in new build
# set this to play if you want to use this for the play build
if ($opt_version =~ /play/) 
{
    if ($opt_sysname =~ /gcc-8.3/)
    {
        $externalPackages{"boost"} = "boost-1.76.0";
        $externalPackages{"tbb"} = "tbb-2020.3";
	$externalRootPackages{"HepMC3"} = "HepMC3-3.2.3";
	$externalRootPackages{"DD4hep"} = "DD4hep-01-15";
    }
    else
    {
        $externalPackages{"rave"} = "rave-0.6.25_clhep-2.4.1.0";
        $externalPackages{"CLHEP"} = "clhep-2.4.1.0";
        $externalPackages{"gsl"} = "gsl-2.6";
    }
}
elsif ($opt_version =~ /test/) 
{
    $externalPackages{"gsl"} = "gsl-2.6";
}
elsif ($opt_version =~ /old/) # build with previous versions 
{
    if ($opt_sysname =~ /gcc-8.3/)
    {
        $externalPackages{"rave"} = "rave-0.6.25_clhep-2.4.1.0";
        $externalPackages{"CLHEP"} = "clhep-2.4.1.0";
        $externalPackages{"gsl"} = "gsl-2.5";
    }
    else
    {
	$externalPackages{"boost"} = "boost-1.67.0";
	$externalPackages{"fastjet"} = "fastjet-3.3.1";
	$externalPackages{"Eigen"} = "eigen-3.3.4";
	$externalPackages{"CGAL"} = "CGAL-4.12";
	$externalPackages{"pythia8"} = "pythia8235-hepmc2";
	$externalPackages{"rave"} = "rave-0.6.25_clhep-2.3.2.2";
    }
}
foreach my $pkg (sort keys %externalRootPackages)
{
    my $pkgname = sprintf("%s_root-%s",$externalRootPackages{$pkg},$rootversion);
    $externalRootPackages{$pkg} = $pkgname;
    print LOG "Adding $pkgname to external packages\n";
    $externalPackages{$pkg} = $pkgname;
}
print LOG "List of external packages rsynced from $externalPackagesDir\n";
foreach my $pack (sort keys %externalPackages)
{
    print LOG "$externalPackages{$pack}\n";
}

if ($opt_tinderbox)
  {
    # Let tinderbox know we've started
    my $tinderboxstring = sprintf("/phenix/WWW/offline/%s/tinderbox/handlemail.pl /phenix/WWW/offline/%s/tinderbox",$collaboration,$collaboration);
    open(TIND,"| $tinderboxstring");
    print TIND "\n";
    print TIND "tinderbox: tree: default\n";
    print TIND "tinderbox: builddate: ".$startTime."\n";
    print TIND "tinderbox: status: building\n";
    print TIND "tinderbox: build: ".$sysname."\n";
    print TIND "tinderbox: errorparser: unix\n";
    print TIND "tinderbox: END\n";
    close(TIND);
  }

# If we're doing a real sPHENIX/EIC install, then there is an official
# place where stuff is supposed to be installed.
my $afs_sysname;
if (-f "/usr/afsws/bin/fs")
{
    my $tmp = `/usr/afsws/bin/fs sysname`;
    ($afs_sysname) = $tmp =~ m/\'(.*)\'/;
}
elsif (-f "/usr/bin/fs")
{
    my $tmp = `/usr/bin/fs sysname`;
    ($afs_sysname) = $tmp =~ m/\'(.*)\'/;
}
if ($opt_sysname ne "default")
{
    $afs_sysname = $opt_sysname;
}
my $linktg;
if ($opt_phenixinstall && !$opt_scanbuild && !$opt_coverity)
{
    if ($opt_afs)
    {
        my $place = sprintf("/afs/rhic.bnl.gov/sphenix/%s",$opt_version);
        die "$place doesn't exist" unless -e $place;
        my $realpath = realpath($place);
        $realpath =~ s/\@sys/$afs_sysname/g;
        ($linktg,$number) = $realpath =~ m/(.*)\.(\d+)$/;
        # rhic.bnl.gov is the read only volume, we need to
        # change rhic.bnl.gov to .rhic.bnl.gov to install to read/write volume
        $realpath =~ s/\/afs\/rhic.bnl.gov/\/afs\/.rhic.bnl.gov/;
        ($inst,$number) = $realpath =~ m/(.*)\.(\d+)$/;
    }
    else
    {
        my $place = sprintf("/cvmfs/%s/%s/release/release_%s/%s",$opt_cvmfsvol,$afs_sysname,$opt_version,$opt_version);
	if ($opt_ecce)
	{
	    $place = sprintf("/cvmfs/%s/ecce/%s/release/release_%s/%s",$opt_cvmfsvol,$afs_sysname,$opt_version,$opt_version);
	}
        die "$place doesn't exist" unless -e $place;
        my $realpath = realpath($place);
#    ($linktg,$number) = $realpath =~ m/(.*)\.(\d+)$/;
        ($inst,$number) = $realpath =~ m/(.*)\.(\d+)$/;
        $linktg = $inst;
    }
}
else
  {
    $inst = $workdir.'/install';
    $linktg = $inst;
    $number = 0;
    #$realpath = realpath($inst); # DLW: at nevis we aren't a phenixinstall, but would like to have the numbering
    #($number) = $realpath =~ m/.*\.(\d+)$/;
  }

my $newnumber = ($number % $MAXDEPTH) + 1;
my $releasenumber = $newnumber;
$installDir = $inst.".".$newnumber;

my $linkTarget = $linktg.".".$newnumber;

# Make the source directory and (maybe) populate it from CVS.
$sourceDir = $opt_source ? $opt_source : $workdir."/source";
if ($opt_stage == 5)
{
  goto INSTALLONLY;
}
if (-e $sourceDir)
  {
    # Assume the source area is already here because the user knows
    # what they're doing.  Don't delete it!
    print LOG "Source directory, ".$sourceDir.", already exists.\n";
    print LOG "  Will not fetch new code from CVS.\n";
    $opt_stage = ($opt_stage == 0) ? 1 : $opt_stage;
  }
else
{
    make_path($sourceDir, {mode => 0775}) unless -e $sourceDir;
    chdir $sourceDir;
    my $statret = 0;
    $ENV{'GIT_ASKPASS'} = 'true';
    my %repoowner = ();
    foreach my $repo (@gitrepos)
    {
	$repoowner{$repo} =  $opt_repoowner;
        $gitcommand = sprintf("git ls-remote https://github.com/%s/%s.git > /dev/null 2>&1",$repoowner{$repo}, $repo);
        my $iret = system($gitcommand);
        if ($iret)
        {
            print LOG "repository https://github.com/$repoowner{$repo}/$repo.git does not exist, setting repoowner to $default_repoowner\n";
	    $repoowner{$repo} =  $default_repoowner;
	    $gitcommand = sprintf("git ls-remote https://github.com/%s/%s.git > /dev/null 2>&1",$repoowner{$repo}, $repo);
	    $iret = system($gitcommand);
	    if ($iret)
	    {
		print LOG "repository https://github.com/$repoowner{$repo}/$repo.git also does not exist\n";
	    }
        }
        $statret += $iret;
    }
    if ($statret)
    {
        close(LOG);
        exit 1;
    }
    foreach my $repo (@gitrepos)
    {
        if ($repo =~ /acts/)
        {
            $gitcommand = sprintf("git clone --branch %s -q https://github.com/%s/%s.git",$opt_actsbranch,$repoowner{$repo}, $repo);
        }
        else
        {
            $gitcommand = sprintf("git clone -q https://github.com/%s/%s.git",$repoowner{$repo}, $repo);
        }
        print LOG $gitcommand, "\n";
        goto END if &doSystemFail($gitcommand);
    }
    if ($opt_gitbranch ne '')
    {
        my $branchcount = 0;
        foreach my $repo (@gitrepos)
        {
            my $repodir = sprintf("%s/%s",$sourceDir,$repo);
            chdir $repodir;
            if (check_git_branch($opt_gitbranch))
            {
                $branchcount++;
                my $gitbranchcmd = sprintf("git checkout %s",$opt_gitbranch);
                print LOG $gitbranchcmd, "\n";
                goto END if &doSystemFail($gitbranchcmd);
            }
        }
        if ($branchcount == 0)
        {
            my $errstr = sprintf("branch %s does not exist in git repos",$opt_gitbranch);
            print LOG $errstr, "\n";
            goto END;
        }
    }
    if($opt_gittag ne '')
    {
        foreach my $repo (@gitrepos)
        {
            my $repodir = sprintf("%s/%s",$sourceDir,$repo);
            chdir $repodir;
            my $gittagcmd = sprintf("git checkout -b %s.%d %s",$opt_version,$newnumber,$opt_gittag);
            print LOG $gittagcmd, "\n";
            goto END if &doSystemFail($gittagcmd);
        }
    }
    # Get rid of the old installDir, if it exists.  If the source area
    # already exists, assume we are re-trying a failed build.  Don't
    # delete the installDir then.
  remove_tree($installDir, {error => \my $err} );
  if (@$err)
    {
      for my $diag (@$err)
        {
          my ($file, $message) = %$diag;
          if ($file eq '')
            {
              print LOG "general error: $message\n";
            }
          else
            {
              print LOG "problem unlinking $file: $message\n";
            }
        }
      print LOG "sleeping 10s\n";
      sleep(10);
      remove_tree($installDir, {error => \my $err2} );
      if (@$err)
        {
          for my $diag2 (@$err2)
            {
               my ($file2, $message2) = %$diag2;
               if ($file2 eq '')
                 {
                   print LOG "general error: $message2\n";
                 }
               else
                 {
                   print LOG "problem unlinking $file2: $message2\n";
                 }
            }
        }
    }
  }

# Make the build area.
$buildDir = $workdir."/build";
make_path($buildDir, {mode=> 0775}) unless -e $buildDir;

# We no longer try to install the insure reports directly in a web
# accessible area - if you want to put the reports on the web, copy
# them there after the build has succeeded.
if ($opt_insure)
  {
    $insureDir = $workdir.'/reports';
    if ($opt_stage == 0)
      {
        remove_tree($insureDir);
        make_path($insureDir, {mode => 0775});
        $gusDir = $workdir.'/gus';
        remove_tree($gusDir);
        make_path($gusDir, {mode => 0775});
        $ENV{GUSDIR} = $gusDir;
      }
   $insureCompileFlags = ' CC="insure gcc -g" CXX="insure g++" CCLD="insure g++"';
  }

# switch OFFLINE_MAIN to new install area and create it
$oldOfflineMain = $OFFLINE_MAIN;
$OFFLINE_MAIN = $installDir;
$ENV{OFFLINE_MAIN} = $installDir;
$ENV{ONLINE_MAIN} = $installDir;
$oldOfflineMain =~ s/\+/\\\+/;
$LD_LIBRARY_PATH =~ s/$oldOfflineMain/$OFFLINE_MAIN/ge;
$PATH =~ s/$oldOfflineMain/$OFFLINE_MAIN/ge;
make_path($installDir."/share", {mode => 0775}) unless -e $installDir."/share";

print LOG "===========================================\n";
print LOG "Here we can see if the environment is sane.\n";
print LOG "===========================================\n";
`printenv  >>$logfile 2>&1`;

# Start building packages
    if ($opt_stage < 2)
    {
        my $ROOTSYS_NOAFSSYS = realpath($ROOTSYS);
        $ROOTSYS_NOAFSSYS =~ s/\@sys/$afs_sysname/;
        my $G4_MAIN_NOAFSSYS = realpath($G4_MAIN);
        $G4_MAIN_NOAFSSYS =~ s/\@sys/$afs_sysname/;
        #change sphenix to fun4all to make eic happy
	if ($opt_eic || $opt_ecce)
	{
	    $G4_MAIN_NOAFSSYS =~ s/sphenix/fun4all/;
	    $ROOTSYS_NOAFSSYS =~ s/sphenix/fun4all/;
	}
        symlink $ROOTSYS_NOAFSSYS, $installDir."/root";
        $ENV{ROOTSYS} = $installDir."/root"; #to get ROOTSYS for configure
        symlink $G4_MAIN_NOAFSSYS, $installDir."/geant4";
        $ENV{G4_MAIN} = $installDir."/geant4"; #to get G4_MAIN for configure
        foreach my $m (sort keys %externalPackages)
        {
            my $dir = $externalPackagesDir."/".$externalPackages{$m};
            if (! -d $dir)
            {
                print LOG "cannot find dir $dir for package $m, skipping it\n";
		next;
            }
            chdir $dir;
            print LOG "rsyncing $dir\n";
            system("rsync -a . $installDir");
# needs boost patch
	    if ($opt_clang)
	    {
		$dir = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/patches/%s",$opt_sysname,$externalPackages{$m});
		if (! -d $dir)
		{
		    next;
		}
		chdir $dir;
		print LOG "rsyncing patch $dir\n";
		system("rsync -a --chmod=Fa-w . $installDir");
	    }
        }
        # patch for Eigen include path
        chdir $installDir . "/include";
        symlink "eigen3/Eigen", "Eigen";
        # patch for GenFit to install includes in subdir
        $dir = sprintf("%s/genfit2_root-%s",$externalPackagesDir,$rootversion);
        if (! -d $dir)
        {
            print LOG "cannot find dir $dir for genfit2\n";
            goto END;
        }
        chdir $dir;
	if (-d "./lib")
	{
	    system("rsync -a lib  $installDir");
	}
	if (-d "./lib64")
	{
	    system("rsync -a lib64  $installDir");
	}
        chdir "include";
        make_path($installDir."/include/GenFit", {mode => 0775}) unless -e $installDir."/include/GenFit";
	system("rsync -a . $installDir/include/GenFit");
# modify all *.la files of external packages to point to this OFFLINE_MAIN, if someone can figure
# out how to do the following one liner that would be enough:
#    system("perl -e \"s/libdir=.*/libdir='$OFFLINE_MAIN\/lib'/g\" -p -i.old $OFFLINE_MAIN/lib/*.la");
# Since I did not succeed with this here is the ugly by hand implementation:
#        $repl = "libdir='" . $OFFLINE_MAIN . "/lib'";
#        open(F,"find $OFFLINE_MAIN/lib -name '*.la' -print |");
#        while ($lafile = <F>)
#        {
#            chomp $lafile;
#            $bckfile = $lafile . ".bck";
#            move($lafile,$bckfile);
#            open(F1,$bckfile);
#            open(F2,">$lafile");
#            while ($line = <F1>)
#            {
#                $line =~ s/libdir=.*/$repl/g;
#                print F2 $line;
#            }
#            close(F1);
#            unlink $bckfile;
#            close(F2);
#        }
#        close(F);

        # remove the la files - we do not need them
	my $rmlacmd = sprintf("rm %s/lib/*.la",$OFFLINE_MAIN);
	system($rmlacmd);

	foreach my $m (@package)
	{
	    my $sdir = realpath($sourceDir)."/".$m;
	    if (! -d $sdir)
	    {
		print LOG "$sdir not found, skipping\n";
		next;
	    }
	    my $bdir = realpath($buildDir)."/".$m;
	    make_path($bdir, {verbose=>1, mode => 0775});
	    chdir $bdir;

	    # Populate top-level directories with their own copy of .psrc
	    # so that Insure++ will know where to send its output.  This
	    # keeps the little compilations done by autoconf from spewing
	    # Insure output to the screen.
	    if ($opt_insure)
	    {
		($base = $m) =~ s|/|.|g;
		copy("$Bin/insure.psrc", $bdir."/.psrc");
		open(OUT, ">>.psrc");
		print OUT "insure++.report_file $insureDir/$base.txt\n";
		print OUT "insure++.runtime off\n";
		close(OUT);
	    }

	    chomp ($date = `date`);
	    print LOG "========================================================\n";
	    print LOG "configuring package $m                                  \n";
	    print LOG "at $date                                                \n";
	    if ($m =~ /acts/)
	    {
		$arg = CreateCmakeCommand("acts", $sdir);
	    }
	    else
	    {
		if ( $opt_scanbuild && exists $scanbuildignore{$m})
		{
		    $arg = "env $compileFlags $sdir/autogen.sh --prefix=$installDir";
		}
		else
		{
		    if ($opt_clang)
		    {
			$arg = "env CXX=clang++ CC=clang $compileFlags $scanbuild $sdir/autogen.sh --prefix=$installDir --cache-file=$buildDir/config.cache";
		    }
		    else
		    {
			$arg = "env $compileFlags $scanbuild $sdir/autogen.sh --prefix=$installDir --cache-file=$buildDir/config.cache";
		    }
		}
	    }
	    print LOG "Running $arg\n";
	    print LOG "========================================================\n";

	    if (&doSystemFail($arg))
	    {
		if ($opt_notify)
		{
		    print LOG "\nsending configure failure mail to $contact{$m}, cc $CC\n";
		    open( MAIL, "|$SENDMAIL" );
		    print MAIL "To: $contact{$m}\n";
		    print MAIL "From: The ",$collaboration," rebuild daemon\n";
		    print MAIL "Cc: $CC\n";
		    print MAIL "Subject: your configure crashed the build\n\n";
		    print MAIL "\n";
		    print MAIL "Hello,\n";
		    print MAIL "The rebuild crashed in module $m at $date.\n";
		    print MAIL "\"$arg\" failed: $? \n";
		    print MAIL "Please look at the rebuild log, found on: \n";
		    print MAIL "https://phenix-intra.sdcc.bnl.gov/software/",$collaboration,"/tinderbox\n";
		    print MAIL "Yours, The Rebuild Daemon \n";
		    close(MAIL);
		}
		goto END;
	    }

	    # Populate all subdirectories with their own copy of .psrc so
	    # that Insure++ will know where to send its output.
	    if ($opt_insure)
	    {
		find sub { -d &&
			       !(realpath($File::Find::name) eq realpath($bdir)) &&
			       copy($bdir."/.psrc", $File::Find::name)}, $bdir;
	    }
	}
    }

# set ROOTSYS to local root softlink if stage > 1 
# otherwise we get ROOTSYS from phenix_setup.csh which 
# points to previous successful install
$ENV{ROOTSYS} = $installDir."/root";
$ENV{G4_MAIN} = $installDir."/geant4";

if ($opt_stage < 3)
  {
      foreach $m (@package)
      {
        if ($m =~ /acts/)
        {
          next;
        }
        $sdir = realpath($sourceDir)."/".$m;
	if (! -d $sdir)
	{
	    print LOG "$sdir not found, skipping\n";
	    next;
	}
        $bdir = realpath($buildDir)."/".$m;
        chdir $bdir;
        chomp ($date = `date`);

        print LOG "=======================================================\n";
        print LOG "installing header files and scripts in  $m             \n";
        print LOG "at $date                                               \n";
        print LOG "=======================================================\n";
        $arg = "make $JOBS install-data";

        if (&doSystemFail($arg))
          {
            if ($opt_notify)
              {
                print LOG "\nsending install-data failure mail to $contact{$m}, cc $CC\n";
                open( MAIL, "|$SENDMAIL" );
                print MAIL "To: $contact{$m}\n";
                print MAIL "From: The ",$collaboration," rebuild daemon\n";
                print MAIL "Cc: $CC\n";
                print MAIL "Subject: your install-data crashed the build\n\n";
                print MAIL "\n";
                print MAIL "Hello,\n";
                print MAIL "The rebuild crashed in $m.\n";
                print MAIL "\"$arg\" failed: $? \n";
                print MAIL "Please look at the rebuild log: \n";
                print MAIL "https://phenix-intra.sdcc.bnl.gov/software/",$collaboration,"/tinderbox\n";
                print MAIL "Yours, The Rebuild Daemon\n";
                close(MAIL);
              }
            goto END;
          }
      }
  }

if ($opt_stage < 4)
  {
    foreach $m (@package)
      {
          if ($opt_coverity)
          {
              if (defined $opt_covpasswd)
              {
                  $covbuild = sprintf("%s --dir %s/covtmp",$covcommonbuild,$workdir);
              }
              else
              {
                  $covbuild = sprintf("%s --dir %s/covtmp/%s",$covcommonbuild,$workdir,$m);
              }
          }
	  $sdir = realpath($sourceDir)."/".$m;
	  if (! -d $sdir)
	  {
	      print LOG "$sdir not found, skipping\n";
	      next;
	  }
        $bdir = realpath($buildDir)."/".$m;
        chdir $bdir;
        chomp ($date = `date`);

        print LOG "=================================\n";
        print LOG "building $m                      \n";
        print LOG "at $date                         \n";

# MuTrigLL1Emulator does not compile with insure
        if ($m =~ /MuTrigLL1Emulator/ && $opt_insure)
        {
            $arg = "make CCLD='insure g++' $JOBS ";
        }
        else
        {
            if ( $opt_scanbuild && ! exists $scanbuildignore{$m})
            {
               $arg = "$scanbuild make $insureCompileFlags $JOBS ";
            }
            else
            {
                if ($opt_includecheck)
                {
                    $arg = "make -k CXX='include-what-you-use -I/opt/sphenix/utils/lib/clang/11.1.0/include ' "
                }
                else
                {
                    $arg = "$covbuild make $insureCompileFlags $JOBS ";
                }
            }
        }
        print LOG "Running $arg\n";
        print LOG "=================================\n";
        if (&doSystemFail($arg))
        {
            if ($opt_notify)
            {
                print LOG "\nsending compile failure mail to $contact{$m}, cc $CC\n";
                open( MAIL, "|$SENDMAIL" );
                print MAIL "To: $contact{$m}\n";
                print MAIL "From: The ",$collaboration," rebuild daemon\n";
                print MAIL "Cc: $CC\n"; 
                print MAIL "Subject: your code crashed the $opt_version build\n\n";
                print MAIL "Hello,\n";
                print MAIL "The rebuild crashed in $m on $date:\n";
                print MAIL "\"$arg\" reason: $? \n";
                print MAIL "Please look at the rebuild log, found on: \n";
                print MAIL "https://phenix-intra.sdcc.bnl.gov/software/",$collaboration,"/tinderbox\n";
                print MAIL "Sincerely, the rebuild daemon \n";
                close(MAIL);
            }
            goto END;
        }
        chomp ($date = `date`);

        print LOG "=================================\n";
        print LOG "installing $m                    \n";
        print LOG "at $date                         \n";

        if ($m =~ /MuTrigLL1Emulator/ && $opt_insure)
        {
            $arg = "make CCLD='insure g++' $JOBS install ";
        }
        else
        {
            $arg = "$covbuild make $insureCompileFlags $JOBS install ";
        }
        print LOG "Running $arg\n";
        print LOG "=================================\n";
        if (&doSystemFail($arg))
          {
            if ($opt_notify)
              {
                print LOG "\nsending compile failure mail to $contact{$m}, cc $CC\n";
                open( MAIL, "|$SENDMAIL" );
                print MAIL "To: $contact{$m}\n";
                print MAIL "From: The ",$collaboration," rebuild daemon\n";
                print MAIL "Cc: $CC\n";
                print MAIL "Subject: your code crashed the build\n\n";
                print MAIL "Hello,\n";
                print MAIL "The rebuild crashed in $m on $date:\n";
                print MAIL "\"$arg\" reason: $? \n";
                print MAIL "Please look at the rebuild log, found on: \n";
                print MAIL "https://phenix-intra.sdcc.bnl.gov/software/",$collaboration,"/tinderbox\n";
                print MAIL "Sincerely, the rebuild daemon \n";
                close(MAIL);
              }
            goto END;
          }

          if (! $opt_lafiles)
          {
              # GET RID OF INSTALLED POINTLESS LA FILES
              # Get rid of this package's installed la_files if we didn't build
              # static archives. For dynamic libraries they are pointless.

              # find all la files in current build directory's .libs directory
              use File::Find;
              my @la_files;
              find(
                  sub {
                      my $fname = $File::Find::name;
                      push @la_files, $fname if $fname =~ /\.libs\/.+\.la$/;
                  },
                  "."
                  );

              # find la files without associated static archive here and remove them from PREFIX
              use File::Basename;
              foreach my $la_f (@la_files) {
                  my $dir  = dirname($la_f);
                  my $base = basename($la_f);
                  my $stem = basename($la_f, "la");
                  my $a_f  = $dir . "/" . $stem . "a"; # name of the static archive in build dir
                  (-e $a_f) or unlink $installDir . "/lib/" . $base;
              }
              # DONE REMOVING POINTLESS LA FILES
          }
      }
    my $repo = "calibrations";
    $repoowner{$repo} = $opt_repoowner;
    $gitcommand = sprintf("git ls-remote https://github.com/%s/%s.git > /dev/null 2>&1",$repoowner{$repo}, $repo);
    my $iret = system($gitcommand);
    if ($iret)
    {
	print LOG "repository https://github.com/$repoowner{$repo}/$repo.git does not exist\n";
	$repoowner{$repo} = $default_repoowner;
	$gitcommand = sprintf("git ls-remote https://github.com/%s/%s.git > /dev/null 2>&1",$repoowner{$repo}, $repo);
	$iret = system($gitcommand);
	if ($iret)
	{
	    print LOG "repository https://github.com/$repoowner{$repo}/$repo.git also does not exist\n";
	}
    }
# rsync over calibrations to $OFFLINE_MAIN/rootmacros
    my $calibrationstargetdir = sprintf("%s/share/calibrations",$installDir);
    make_path($calibrationstargetdir,{mode => 0775});
    foreach my $repo (@gitrepos)
    {
	if ($repo =~ /calibrations/)
	{
	    my $calibsrcdir = sprintf("%s/%s",$sourceDir,$repo);
	    if (-d $calibsrcdir)
	    {
		print LOG "rsync calibrations from $calibsrcdir to $calibrationstargetdir\n";
		my $rsynccmd = sprintf("rsync -a %s/* --exclude '.git' %s",$calibsrcdir,$calibrationstargetdir);
		system($rsynccmd);
	    }
	}
    }
# rsync over common root macros to $OFFLINE_MAIN/rootmacros
    my $macrotargetdir = sprintf("%s/rootmacros",$installDir);
    make_path($macrotargetdir,{mode => 0775});
    foreach my $repo (@gitrepos)
    {
	if ($repo =~ /macro/)
	{
	    my $macrosrcdir = sprintf("%s/%s/common",$sourceDir,$repo);
	    if (-d $macrosrcdir)
	    {
		print LOG "rsync common ROOT macros from $macrosrcdir to $macrotargetdir\n";
		my $rsynccmd = sprintf("rsync -a %s/* %s",$macrosrcdir,$macrotargetdir);
		system($rsynccmd);
	    }
	}
    }
  }

# all done adjust remaining *.la files to point to /afs/rhic.bnl.gov/ instead 
# of /afs/.rhic.bnl.gov/
#my $cmd = sprintf("find %s/lib -name '*.la' -print | xargs sed -i 's/\\.rhic/rhic/g'",$OFFLINE_MAIN);
#print LOG "adjusting la files, replacing /afs/.rhic.bnl.gov by /afs/rhic.bnl.gov\n";
#system($cmd);

INSTALLONLY:

$buildSucceeded = 1;

# OK, installation done; move symlink over
print LOG "removing old installation symlink $inst\n";
unlink $inst if (-e $inst);
print LOG "creating symlink  $inst -> " .  basename($linkTarget) . ", full target: $linkTarget\n";
symlink basename($linkTarget), $inst;
# install for scan and coverity build means copying reports which are not in afs
if ($opt_phenixinstall && !$opt_scanbuild && !$opt_coverity)
{
    my $releasefile;
    if ($opt_afs)
    {
        my $releasedir = sprintf("/afs/rhic.bnl.gov/sphenix/sys/%s/log",$afs_sysname);
# if we don't have to release the afs volume we are done here
        if (! -d $releasedir)
        {
            $buildSucceeded=1;
            goto END;
        }
        $releasefile = sprintf("%s/afs.release",$releasedir);
    }
    else
    {
# tell cvmfs DB to keep builds separately to reduce amount of loaded lookups
        my $cvmfscatalognestfile = sprintf("%s/.cvmfscatalog",$installDir);
        system("touch $cvmfscatalognestfile");
        my $releasedir = sprintf("/cvmfs/%s/%s/release",$opt_cvmfsvol,$afs_sysname);
	if ($opt_ecce)
	{
	    $releasedir = sprintf("/cvmfs/%s/ecce/%s/release",$opt_cvmfsvol,$afs_sysname);
	}
        if ($opt_version =~ /ana/ || $opt_version =~ /pro/ || $opt_version =~ /mdc/)
        {
            my $symlinksource = sprintf("release_%s/%s.%d",$opt_version,$opt_version,$releasenumber);
            my $symlinktarget = sprintf("%s/%s.%d",$releasedir,$opt_version,$releasenumber);
            symlink $symlinksource, $symlinktarget;
            print LOG "creating symlink source: $symlinksource target: $symlinktarget\n";
        }
        else
        {
            $releasedir = sprintf("%s/release_%s",$releasedir,$opt_version);
        }

# if we don't have to release the afs volume we are done here
        if (! -d $releasedir)
        {
            $buildSucceeded=1;
            goto END;
        }
        $releasefile = sprintf("%s/CVMFSRELEASE",$releasedir);
    }
    chomp (my $date = `date`);
    print LOG "$date checking for existing $releasefile\n";
    if (-f $releasefile)
    {
        my $n = 40;
        while($n > 0)
        {
            sleep(30);
            if (! -f $releasefile)
            {
                goto NORELEASEFILE;
            }
            $n--;
        }
        chomp (my $date = `date`);
        print LOG "$date $releasefile still exist, build fails!\n";
        $buildSucceeded=0;
        goto END;
    }
NORELEASEFILE:
#    if ($opt_version =~ /ana/)
#      {
#        chomp ($date = `date`);
#        print LOG "$date creating taxi afs dirs\n";
#        create_afs_taxi_dir();
#      }
    chomp ($date = `date`);
    print LOG "copying build log to install area before releasing\n";
    print LOG "this is the last line you will see\n";
    close LOG;
    system("cp $logfile $installDir");
    open(LOG, ">>$logfile");
    print LOG "$date initiating release, touching $releasefile\n";
    system("touch $releasefile");
    my $n=70;
    while($n > 0)
    {
        sleep(30);
        if (! -f $releasefile)
        {
            chomp (my $date = `date`);
            my $cycles = 70-$n;
            print LOG "$date build is released after $cycles cycles\n";
            goto END;
        }
        chomp (my $date = `date`);
        print LOG "$date $releasefile still exists, counter: $n\n";
        $n--;
    }
    chomp ($date = `date`);
    print LOG "$date $releasefile still exists, giving up and failing build $n\n";
    $buildSucceeded=0;
    goto END;

}
else
{
    chomp (my $date = `date`);
    $buildSucceeded=1;
    if ($opt_scanbuild && $buildSucceeded==1 && $opt_phenixinstall)
    {
        &install_scanbuild_reports();
    }
    if ($opt_coverity && $buildSucceeded==1 && $opt_phenixinstall)
    {
        &install_coverity_reports();
    }
    print LOG "$date build success for local install\n";
}


END:{
  $buildSucceeded==1 && ($buildStatus='success', last END);
  $buildSucceeded==0 && ($buildStatus='busted', POSIX::_exit(-1), last END);
}

# save the latest commit id of the checkouts
my %repotags = ();
# first the calibrations
my $fullrepo = sprintf("sPHENIX-Collaboration/calibrations.git");
my $repodir = sprintf("%s/share/calibrations",$OFFLINE_MAIN);
if (-d $repodir)
{
    chdir $repodir;
    my $gittag = `git show | head -1 | awk '{print \$2}'`;
    chomp $gittag;
    $repotags{$fullrepo} = $gittag;
}
# then the repos from repositories.txt
foreach my $repo (@gitrepos)
{
    $repodir = sprintf("%s/%s",$sourceDir,$repo);
    if (-d $repodir)
    {
        chdir $repodir;
        $fullrepo = sprintf("%s/%s.git",$opt_repoowner, $repo);
        my $gittag = `git show | head -1 | awk '{print \$2}'`;
        chomp $gittag;
        $repotags{$fullrepo} = $gittag;
    }
}

if ($opt_tinderbox) 
  {
    print LOG "\n";
    print LOG "tinderbox: tree: default\n";
    print LOG "tinderbox: builddate: ".$startTime."\n";
    print LOG "tinderbox: status: ".$buildStatus."\n";
    print LOG "tinderbox: build: ".$sysname."\n";
    print LOG "tinderbox: errorparser: unix\n";
    print LOG "tinderbox: END\n";
    my $cmd = sprintf("cat %s | /phenix/WWW/offline/%s/tinderbox/handlemail.pl /phenix/WWW/offline/%s/tinderbox",$logfile,$collaboration,$collaboration);
    system($cmd);
  }

$rebuildInfo=$OFFLINE_MAIN.'/rebuild.info';
$sysInfo=`uname -a`;
$endtime = time;
$elapsedtime = $endtime - $starttime;
open (INFO, "> $rebuildInfo");
print INFO "\n";
print INFO " tree: default\n";
print INFO " status: ".$buildStatus."\n";
print INFO " build: ".$sysname."\n";
print INFO " at system: ".$sysInfo."\n";
print INFO " elapsed time: ".$elapsedtime." seconds\n";
print INFO " source dir:".$sourceDir."\n ";
print INFO " build dir:".$buildDir."\n ";
print INFO " install dir:".$installDir."\n ";
print INFO " for build logfile see: ".$logfile." or \n ";
print INFO " https://phenix-intra.sdcc.bnl.gov/software/",$collaboration,"/tinderbox/showbuilds.cgi?tree=default&nocrap=1&maxdate=".$startTime."\n";
if ($opt_gittag ne '')
{
  print INFO " git tag: ".$opt_gittag."\n";
}
if ($opt_gitbranch ne '')
{
 print INFO " git branch: ".$opt_gitbranch."\n";
}
else
{
    print INFO " git branch: master\n";
}
foreach my $key (keys %repotags)
{
    print INFO " git repo $key, tag: $repotags{$key}\n";
}
#print INFO " git command used: \n".$gitcommand."\n";
%month=('Jan',0,'Feb',1,'Mar',2,'Apr',3,'May',4,'Jun',5,'Jul',6,'Aug',7,'Sep',8,'Oct',9,'Nov',10,'Dec',11);
close (LOG);
open(LOG,"$logfile");
$action='';
$time=0;
$flag=0;
while (<LOG>) 
  {
    if ((/^libtoolize aclocal automake autoconf and (configure) on (\S*)/)||
        (/^(installing header) files and scripts in  (\S*)/)||
        (/^(building) (\S*)/)) 
      {
        $action=$newaction;
        $newaction="$1 $2";
      }
    if (/^======>\w\w\w (\w\w\w) *(\d*) (\d\d):(\d\d):(\d\d) \w\w\w (\d\d\d\d)/) 
      {
        $newtime=timelocal($5,$4,$3,$2-1,$month{$1},$6-1900);
        print INFO $action," takes ",$newtime-$time," seconds  \n" if $flag;
        $flag=1;
        $time=$newtime;
      }
  }

close(LOG);
close(INFO);

if ($opt_insure && $buildSucceeded==1)
{
    &check_insure_reports();
}
# save the git tags in DB only for the build account
my $username = getlogin || "jenkins";
if ($username eq "phnxbld")
{
    if ($opt_repoowner eq "sPHENIX-Collaboration")
    {
        SaveGitTagsToDB();
    }
}


# only expire modules if the ana build was successful
#if ($buildSucceeded==1 && $opt_version =~ /ana/ && $opt_version =~ /insure/)
if ($buildSucceeded==1 && $opt_version =~ /ana/)
{
#  check_expiration_date();
#  create_afs_taxi_dir();
}

if ( defined($dbh)) { $dbh->disconnect; }

sub doSystemFail
{
    close(LOG);
    my $arg = shift(@_) . ">> $logfile 2>&1";
    my $status = system($arg);
    open(LOG, ">>$logfile");
    if ($status)
    {
        print LOG "system $arg failed: $?\n";
    }
    if ($opt_includecheck)
    {
        $status = 0;
    }
    return $status;
}


sub check_insure_reports
{
    open(LOG, ">>$logfile");
    open(INSREP,"find $insureDir -maxdepth 1 -type f -size +0 -print | sort |");
    while($insure_report = <INSREP>)
    {
        chomp $insure_report;
        $package = basename($insure_report);
        $package =~ s/\.txt//;
        $package =~ s|\.|/|g;
        print LOG "found non zero sized insure report for package: $package\n";
        if ($package =~ /mutoo\/modules/)
        {
            print LOG "ignoring mutoo/modules\n";
            open(F,"$insure_report");
            while($line = <F>)
            {
                print LOG $line;
            }
            close(F);
            next;
        }
        if ($opt_notify)
        {
            print LOG "\nsending insure report mail to $contact{$m}, cc $CC\n";
            open( MAIL, "|$SENDMAIL" );
            print MAIL "To: $contact{$package}\n";
            print MAIL "From: The ",$collaboration," rebuild daemon\n";
            print MAIL "Cc: $CC\n";
            print MAIL "Subject: your code ticks off the insure compiler\n\n";
            print MAIL "Hello,\n";
            print MAIL "Insure found problems in module $package on $date.\n";
            print MAIL "The content of the report is attached.\n";
            print MAIL "Yours, The Rebuild Daemon \n\n";
            open(F,"$insure_report");
            while($line = <F>)
            {
                print MAIL $line;
            }
            close(F);
            close(MAIL);
        }
    }
    close(INSREP);
    close(LOG);
}

sub check_expiration_date
{
    my $currenttime = time;
    print "expiration date: $currenttime\n";
    my $getexpired = $dbh->prepare("select package,contact from anatrainmodules where status = 1 and expiration < $currenttime");
    $getexpired->execute();
    my $setexpired = $dbh->prepare("update anatrainmodules set status = -1 where package = ?");
    while(my @mods = $getexpired->fetchrow_array())
    {
        $setexpired->execute($mods[0]);
        open( MAIL, "|$SENDMAIL" );
        print MAIL "To: $contact{$mods[0]}\n";
        print MAIL "From: The ",$collaboration," rebuild daemon\n";
        print MAIL "Cc: $CC\n";
        print MAIL "Subject: your module $mods[0] expired\n\n";
        print MAIL "Hello,\n";
        print MAIL "Your module $mods[0] has reached is expiration date on $date.\n";
        print MAIL "You can reenable it on the web under:\n";
        print MAIL "https://phenix-intra.sdcc.bnl.gov/WWW/p/draft/anatrain/TrainV2/trainbuild/modifymodule.html\n";
        print MAIL "Yours, The Rebuild Daemon \n\n";
        close(MAIL);
    }
    $setexpired->finish();
    $getexpired->finish();
}

sub create_afs_taxi_dir
{
    my $afstaxipath = sprintf("%s/lib/taxi",$installDir);
    my $sharedir = sprintf("%s/share",$installDir);
    print LOG "creating $afstaxipath\n";
    make_path($afstaxipath, {mode => 0775}) unless -e $afstaxipath;
    system("fs setacl $afstaxipath anatrain id");
    system("fs setacl $sharedir anatrain id");
}

sub install_coverity_reports
{
    if (defined $opt_covpasswd)
    {
        my $covdir =  sprintf("%s/covtmp",$workdir);
        my $covanacmd = sprintf("cov-analyze  --disable DEADCODE --disable UNINIT_CTOR --disable FORWARD_NULL --disable UNUSED_VALUE --dir %s",$covdir);
        print LOG "$covanacmd\n";
        open(F2,"$covanacmd 2>&1 |");
        while(my $line = <F2>)
        {
            print LOG "$line";
        }
        close(F2);
        my $covcmd = sprintf("cov-commit-defects --host coverity.rcf.bnl.gov --stream coresoftware --user pinkenbu --dir %s",$covdir);
        print LOG "executing $covcmd\n";
        $covcmd = sprintf("%s --password %s",$covcmd,$opt_covpasswd);
        open(F2,"$covcmd 2>&1 |");
        while(my $line = <F2>)
        {
            print LOG "$line";
        }
        close(F2);
    }
    else
    {
        my $installroot = sprintf("/phenix/WWW/p/draft/phnxbld/%s/coverity/report",$collaboration);
        my $realpath = realpath($installroot);
        (my $inst,my $number) = $realpath =~ m/(.*)\.(\d+)$/;
        my $newnumber = ($number % 2) + 1;
        my $installdir = sprintf("%s.%d",$inst,$newnumber);
        remove_tree($installdir);
        make_path($installdir, {mode => 0775});
        my $indexfile = sprintf("%s/index.html",$installdir);
        print LOG "indexfile: $indexfile\n";
        open(F1,">$indexfile");
        for my $packages (sort keys %contact)
        {
            if (exists $coverityignore{$packages})
            {
                print LOG "dropping coverity html report generation for $packages\n";
                next;
            }
            my $covdir =  sprintf("%s/covtmp/%s",$workdir,$packages);
            my $htmldir = sprintf("%s/%s",$installdir,$packages);
            print LOG "analyzing $covdir writing to $htmldir\n";
            if (-d $covdir)
            {
                my $makehtml = 0;
                my $covanacmd = sprintf("cov-analyze  --disable DEADCODE --disable UNINIT_CTOR --disable FORWARD_NULL --disable UNUSED_VALUE --disable CONSTANT_EXPRESSION_RESULT --dir %s",$covdir);
                open(F2,"$covanacmd 2>&1 |");
                while(my $line = <F2>)
                {
                    chomp $line;
                    print LOG "$line\n";
                    if ($line =~ /Defect occurrences found/)
                    {
                        my @sp1 = split(/:/,$line);
                        my @sp2 = split(/ /,$sp1[1]);
                        if ($#sp2 > 1)
                        {
                            $makehtml = 1;
                        }
                    }
                }
                close(F2);
                if ($makehtml > 0)
                {
                    my $covcmd = sprintf("cov-format-errors --dir %s --html-output %s",$covdir,$htmldir);
                    print LOG "$covcmd\n";
                    open(F2,"$covcmd 2>&1 |");
                    my $addfile = 1;
                    while(my $line = <F2>)
                    {
                        print LOG "$line";
                        if ($line =~ /Processing 0 errors/)
                        {
                            $addfile = 0;
                            print LOG "not adding html file $packages to summary, it is empty\n";
                        }
                    }
                    close(F2);
                    my $packagename = $packages;
                    $packagename =~  s/\./\//g;
                    if ($addfile > 0)
                    {
                        print F1 "<a href=\"$packages\">$packages</a> contact: $contact{$packagename} </br>\n";
                    }
                }
                else
                {
                    print LOG "no coverity error for $packages\n";
                }
            }
        }
        close(F1);
        unlink $inst if (-e $inst);
        symlink $installdir, $inst;
    }
}

sub install_scanbuild_reports
{
    my $installroot = sprintf("/phenix/WWW/p/draft/phnxbld/%s/scan-build/scan",$collaboration);
    my $realpath = realpath($installroot);
    (my $inst,my $number) = $realpath =~ m/(.*)\.(\d+)$/;
    my $newnumber = ($number % 2) + 1;
    my $installdir = sprintf("%s.%d",$inst,$newnumber);
    remove_tree($installdir);
    make_path($installdir, {mode => 0775});
# copy all reports to WWW accessible place
    system("rsync -a $scanlogdir/ $installdir");
# make all files group readable (actual build errors are owner read only)
    system("find $installdir -type f -exec chmod 664 {} \\;");
# scan through directories, extract package name and create html index file
    my %packets;
    open(F,"find $installdir -maxdepth 1 -type d -name '20*' |");
    while(my $scandir = <F>)
    {
        chomp $scandir;
        my $indexfile = sprintf("%s/index.html",$scandir);
        open(F1,"$indexfile");
        while(my $line = <F1>)
        {
            if ($line =~ /Working Directory/)
            {
                chomp $line;
                my @sp1 = split(/\/build\//,$line);
#               print $sp1[1];
                my @sp2 = split(/</,$sp1[1]);
                $sp2[0] =~ s/\//\./g;
                $packets{$sp2[0]} = $scandir;
                last;
            }
        }
        close(F1);
    }
    close(F);
    my %mailinglist;
    my $indexfile = sprintf("%s/index.html",$installdir);
    open(F,">$indexfile");
    if (!keys %packets) # whoa - no scan build warnings!!!!
    {
        print F "<H1>Congratulations - No Scan Build Warnings</H1>\n:";
    }
    else
    {
        for my $packages (sort keys %packets)
        {
            my $hrefentry = basename($packets{$packages});
            my $packagename = $packages;
            $packagename =~  s/\./\//g;
            print F "<a href=\"$hrefentry\">$packages</a> contact: $contact{$packagename} </br>\n";
            if (exists $contact{$packagename})
            {
                $mailinglist{$packagename} = sprintf("https://phenix-intra.sdcc.bnl.gov/WWW/p/draft/phnxbld/%s/scan-build/scan/%s",$collaboration,$hrefentry);
            }
            else
            {
                print LOG "Could not locate contact for package $packagename\n";
            }
        }
    }
    close(F);
    unlink $inst if (-e $inst);
    symlink $installdir, $inst;
# now send the mails
    if ($opt_notify)
    {
        for my $package (sort keys %mailinglist)
        {
            if (! exists $contact{$package})
            {
                print LOG "Could not locate contact for package $package\n";
                next;
            }
            my $scancc = "pinkenburg\@bnl.gov";
            print LOG "\nsending scanbuild report mail to $contact{$package}, cc $scancc\n";
            open( MAIL, "|$SENDMAIL" );
            print MAIL "To: $contact{$package}\n";
            print MAIL "From: The ",$collaboration," rebuild daemon\n";
            print MAIL "Cc: $scancc\n";
            print MAIL "Subject: scan-build found issues in $package\n\n";
            print MAIL "Hello $contact{$package},\n";
            print MAIL "scan-build the static analyzer based on clang has found problems\n";
            print MAIL "in your module $package on $date.\n";
            print MAIL "The report is under\n\n";
            print MAIL "$mailinglist{$package}\n\n";
            print MAIL "All reports are available under\n\n";
            print MAIL "https://phenix-intra.sdcc.bnl.gov/WWW/p/draft/phnxbld/",$collaboration,"/scan-build/scan\n\n";
            print MAIL "instructions how to run scan-build yourself are in our wiki\n\n";
            print MAIL "https://wiki.bnl.gov/sPHENIX/index.php/Tools#scan_build\n\n";
            print MAIL "Please look at the report and fix the issues found\n";
            print MAIL "Sincerely yours, The Rebuild Daemon \n\n";
            close(MAIL);
        }
    }
}

sub printhelp
{
    print "--stage            Skip to stage N of the build process. \n";
    print "                     0 = CVS checkout (default) \n";
    print "                     1 = configure\n";
    print "                     2 = install headers \n";
    print "                     3 = compile and install \n";
    print "                     4 = run tests \n";
    print "                     5 = install only (scan-build) \n";
    print "--actsbranch='string' build ACTS from this branch\n";
    print "--afs              install in afs (cvmfs is default)\n";
    print "--clang            use clang instead of gcc\n";
    print "--coverity         Making a coverity build\n";
    print "--covpasswd='string'  the coverity password for the integrity manager\n";
    print "--cvmfsvol='string'  the target cvmfs volume";
    print "--db=[0,1]         Disable/enable access to phnxbld db (default is enable).\n";
    print "--ecce             build packages for ECCE\n";
    print "--eic              build packages for generic eic\n";
    print "--gittag='string'  git tag for source checkout.\n";
    print "--gitbranch='string' git branch to be used for build\n";
    print "--includecheck     run the clang based include file checker\n";
    print "--insure           Rebuild using the Insure++\n";
    print "--lafiles          build keeping libtool *.la files.\n";
    print "--notify           Contact responsibles in case of failure.\n";
    print "--phenixinstall    Install in the official AFS area. \n";
    print "--repoowner='string' repository owner (default: sPHENIX-Collaboration). \n";
    print "--scanbuild        Making a scan-build with clang\n";
    print "--source='string'  Use the specified source directory. Don't get\n";
    print "                   the source from CVS (i.e., skip stage 0)\n";
    print "--sysname          set system name for cvmfs/afs top dir\n";
    print "--tinderbox        Send build information to tinderbox.\n";
    print "--version='string' Prefix for installation area. Default: new\n";
    print "--workdir='string'  Set \$workdir (default is /home/\$USER/).\n";
    exit(0);
  }


# check if we have a remote branch in git
sub check_git_branch
{
    my $branchname = shift;
# the redir of stderr is needed to prevent obnoxious "From https://..."
# being send in a mail
    open(F,"git ls-remote --heads 2>/dev/null | awk \'{print \$2}\' |");
    while (my $line = <F>)
    {
        if ($line !~ /refs/)
        {
            next;
        }
        chomp $line;
        my @sp1 = split("/",$line);
        if ($sp1[$#sp1] eq $branchname )
        {
            close(F);
            return 1;
        }
    }
    close(F);
    return 0;
}

sub SaveGitTagsToDB()
{
    use DBI;
    $dbh = DBI->connect("dbi:ODBC:phnxbld") || die $DBI::error;
    my $chkbuild = $dbh->prepare("select build from buildtags where build=?");
    my $delbuild = $dbh->prepare("delete from buildtags where build=?");
    my $buildname = sprintf("%s.%d",$opt_version,$releasenumber);
    $chkbuild->execute($buildname);
    if ($chkbuild->rows > 0)
    {
        $delbuild->execute($buildname);
    }
    $chkbuild->finish();
    $delbuild->finish();

    my $insertbuild = $dbh->prepare("insert into buildtags (build, date, unixdate, reponame, tag) values (?, ?, ?, ?, ?)");
    my $unixdate = `date +%s`;
    chomp $unixdate;
    my $humandate = `date`;

    foreach my $key (keys %repotags)
    {
        $insertbuild->execute($buildname,$humandate,$unixdate,$key,$repotags{$key});
    }
    $insertbuild->finish();
}

sub CreateCmakeCommand
{
    my $packagename = shift;
    my $cmakesourcedir = shift;
    if ($packagename =~ /acts/)
    {
	my $cmakecmd = sprintf("cmake -DBOOST_ROOT=${OFFLINE_MAIN} -DTBB_ROOT_DIR=${OPT_SPHENIX}/%s -DEigen3_DIR=${OPT_SPHENIX}/eigen/share/eigen3/cmake -DROOT_DIR=${ROOTSYS}/cmake -DACTS_BUILD_TGEO_PLUGIN=ON -DACTS_BUILD_EXAMPLES=ON -DACTS_BUILD_EXAMPLES_PYTHIA8=ON -DPythia8_INCLUDE_DIR=${OFFLINE_MAIN}/include/Pythia8 -DPythia8_LIBRARY=${OFFLINE_MAIN}/lib/libpythia8.so -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_SKIP_INSTALL_RPATH=ON -DCMAKE_SKIP_RPATH=ON -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_INSTALL_PREFIX=$installDir -Wno-dev",$externalPackages{"tbb"});
        if ($opt_version =~ /debug/)
        {
            $cmakecmd = sprintf("%s -DCMAKE_BUILD_TYPE=Debug",$cmakecmd);
        }
        if ($opt_insure)
	{
# cmake is not able to digest 'insure g++' as compiler, so we create a little
# shell script with insure g++ -g and use it as compiler
# the shell script ends up in the acts build dir so we just leave it there
	    my $insurecompiler = `which insure`;
	    chomp $insurecompiler;
	    my $runscript = "run_gpp.sh";
	    open(F2,">$runscript");
            my $runcmd = sprintf("%s g++ -g \$*",$insurecompiler);
            print F2 "$runcmd\n";
	    close(F2);
	    chmod 0755, $runscript;
	    print LOG "using insure $insurecompiler\n";
	    $cmakecmd = sprintf("%s -DCMAKE_CXX_COMPILER=%s -DCMAKE_BUILD_TYPE=Debug",$cmakecmd,$runscript);
	}
	elsif ($opt_clang)
	{
	    my $cxxcompiler = `which clang++`;
	    chomp $cxxcompiler;
            my $ccompiler = `which clang`;
	    chomp $ccompiler;
	    $cmakecmd = sprintf("%s -DCMAKE_CXX_COMPILER=%s -DCMAKE_C_COMPILER=%s",$cmakecmd,$cxxcompiler,$ccompiler);
	}
	elsif ($opt_scanbuild)
	{
	    my $cxxcompiler = sprintf("/cvmfs/sphenix.sdcc.bnl.gov/%s/opt/sphenix/utils/stow/llvm-11.1.0/bin/../libexec/c++-analyzer",$opt_sysname);
	    chomp $cxxcompiler;
	    $cmakecmd = sprintf("%s -DCMAKE_CXX_COMPILER=%s",$cmakecmd,$cxxcompiler);
	}
	elsif (defined $CCACHE_DIR)
	{
	    my $cxxcompiler = `which g++`;
	    chomp $cxxcompiler;
            my $ccompiler = `which gcc`;
            chomp $ccompiler;
	    print LOG "using ccache dir $CCACHE_DIR with\nC++ compiler $cxxcompiler\nC compiler $ccompiler\n";
	    $cmakecmd = sprintf("%s -DCMAKE_CXX_COMPILER=%s -DCMAKE_C_COMPILER=%s",$cmakecmd,$cxxcompiler,$ccompiler);
	}
        $cmakecmd = sprintf("%s %s",$cmakecmd, $cmakesourcedir);
	return $cmakecmd;
    }
    print LOG "CreateCmakeCommand not implemented for $packagename\n";
    die;
}

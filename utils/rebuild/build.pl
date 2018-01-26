#! /usr/bin/perl

# This script rebuilds the PHENIX code base.  It checks out code from CVS,
# compiles it, and installs it in the appropriate directories in AFS.  In
# order for this script to work, you need an AFS token (for installation).

use FindBin qw($Bin);	
use File::Basename;
use File::Path;
use File::Copy;
use File::Find;
use Getopt::Long;
use Time::Local;
use Config;
use Cwd qw(getcwd realpath);
use Env;
#use strict;

Env::import();

if ($#ARGV < 0)
{
    goto printhelp;
}
# save cmd args for echoing into logfile
my $cmdline = "build.pl";
for (my $arg = 0; $arg <= $#ARGV; $arg++)
{
    $cmdline = $cmdline . " $ARGV[$arg]";
}

umask 002;
# only run 32 parallel build jobs if
# distcc is in the path, otherwise run 6 (our build machine has 6 cpus)
my $JOBS = "-j 6";
if ($PATH =~ /\/phenix\/u\/phnxbld\/distcc/)
{
  $JOBS = "-l 8.0 -j 120";
}
$MAIL = '/bin/mail';
my $SENDMAIL = "/usr/sbin/sendmail -t -v";
my $buildmanager = "pinkenburg\@bnl.gov";
my $CC = $buildmanager;
my @externalPackages = ("boost", "CGAL", "CLHEP", "Eigen", "EvtGen", "fastjet", "gsl", "HepMC", "PHOTOS", "pythia8", "rave", "TAUOLA");
my $externalPackagesDir = "$OPT_SPHENIX";
my @externalRootPackages = ("eic-smear", "sartre-1.20");
my $rootversion = `root-config --version`;
chomp $rootversion;
$rootversion =~ s/\//\./g;
# Keep track of where we were and when it was that we got underway
my $starttime = time;
my $date = `date`;
chomp $date;
my $cwd = getcwd;

my $buildSucceeded = 0;
# Read in list of packages and contacts
my @package = ();
my %contact = ();
die unless open(IN, "$Bin/packages.txt");
while (<IN>)
  {
    next if (/^#/);
    (my $p, my $c) = split(/\|/, $_, 2);
# remove \n at end of $c
	     chomp $c;
    push @package, $p;
    $contact{$p} = $c;
  }
close(IN);

# Set up some defaults for script options
$opt_gittag = '';
$opt_version = 'new';
$opt_stage = 0;
$opt_db = 0;
$opt_scanbuild = 0;
$opt_coverity = 0;
$opt_root6 = 0;
$opt_sl7 = 0;

GetOptions('help', 'stage=i',
	   'version:s', 'tinderbox', 'gittag:s',
	   'phenixinstall','workdir:s','insure','scanbuild',
	   'coverity','covpasswd:s','notify','64', 'db:i', 'root6', 'sl7');

if ($opt_help)
  {
printhelp:
    print "--stage            Skip to stage N of the build process. \n";
    print "                     0 = CVS checkout (default) \n";
    print "                     1 = configure\n";
    print "                     2 = install headers \n";
    print "                     3 = compile and install \n";
    print "                     4 = run tests \n";
    print "                     5 = install only (scan-build) \n";
    print "--source='string'  Use the specified source directory. Don't get\n";
    print "                     the source from CVS (i.e., skip stage 0)\n";
    print "--version='string' Prefix for installation area. Default: new\n";
    print "--tinderbox        Send build information to tinderbox.\n";
    print "--gittag='string'  CVS flags for source checkout. \n";
    print "--phenixinstall    Install in the official AFS area. \n";
    print "--workdir='string'  Set \$workdir (default is /home/\$USER/).\n";
    print "--insure           Rebuild using the Insure++\n";
    print "--scanbuild        Making a scan-build with clang\n";
    print "--coverity         Making a coverity build\n";
    print "--covpasswd='string'  the coverity password for the integrity manager\n";
    print "--notify           Contact responsibles in case of failure.\n";
    print "--db=[0,1]         Disable/enable access to phnxbld db (default is enable).\n";
    print "--root6            do whatever is needed to use root 6\n";
    print "--sl7              Build under SL7.\n";
    exit(0);
  }

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


my $MAXDEPTH = ($opt_version =~ m/pro/ || $opt_version =~ /ana/ ) ? 9999999 : 4;
$opt_version .= '+insure' if $opt_insure;
# number of parallel builds with insure
$JOBS = "-j 2 " if $opt_insure;
$MAXDEPTH = 4 if $opt_insure;

$workdir = $opt_workdir ? $opt_workdir : '/home/'. $USER . '/sPHENIX';

$startTime = time;
$sysname = $USER.'@'.$HOST.'#'.$Config{osname}.':'.$opt_version;
$compileFlags = ($sysname =~ m/linux/) ? ' INSTALL="/usr/bin/install -D -p" install_sh="/usr/bin/install -D -p"' : "";
$insureCompileFlags = " ";

# An area for reports visible via the web
$workNFS = $WORKNFS ? $WORKNFS : '/phenix/WWW/offline';
$CVSROOT = $CVSROOT ? $CVSROOT :  '/afs/rhic.bnl.gov/phenix/PHENIX_CVS';

$workdir .= "/$opt_version";

# Set up the working area: directories for source, build and install.
mkpath($workdir, 0, 0775) unless -e $workdir;

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
    $scanbuild = sprintf("scan-build -disable-checker deadcode.DeadStores -disable-checker core.NullDereference -k -o %s",$scanlogdir);
    mkpath($scanlogdir, 0, 0775) unless -e $scanlogdir;
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
    else
    {
	print "could not find $ignorefile\n;"
    }
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
print LOG "Welcome to the PHENIX $sysname rebuild \n started at ",$date,"\n";
# print how we were called
print LOG "How this script was called:\n";
print LOG "$cmdline\n\n";
foreach my $pkg (sort @externalRootPackages)
{
    my $pkgname = sprintf("%s_root-%s",$pkg,$rootversion);
    print LOG "Adding $pkgname to external packages\n";
    push(@externalPackages,$pkgname);
}

# temporary until the new versions are okay to use in new build
# set this to play if you want to use this for the play build
if ($opt_version =~ /play/) 
{
    @externalPackages = ();
    push(@externalPackages,"boost");
    push(@externalPackages,"CGAL");
    push(@externalPackages,"clhep-2.3.4.3");
    push(@externalPackages,"Eigen");
    push(@externalPackages,"EvtGen");
    push(@externalPackages,"fastjet");
    push(@externalPackages,"gsl");
    push(@externalPackages,"HepMC");
    push(@externalPackages,"PHOTOS");
    push(@externalPackages,"pythia8");
    push(@externalPackages,"rave-0.6.25-clhep-2.3.4.3");
    push(@externalPackages,"TAUOLA");
    print LOG "play build: replacing external packages with customized versions\n";
    foreach my $i (@externalPackages)
    {
	print LOG "$i\n";
    }
    foreach my $pkg (sort @externalRootPackages)
    {
	my $pkgname = sprintf("%s_root-%s",$pkg,$rootversion);
	print LOG "Adding $pkgname to external packages\n";
	push(@externalPackages,$pkgname);
    }
}

if ($opt_tinderbox)
  {
    # Let tinderbox know we've started
    open(TIND,"| /phenix/WWW/offline/sPHENIX/tinderbox/handlemail.pl /phenix/WWW/offline/sPHENIX/tinderbox");
    print TIND "\n";
    print TIND "tinderbox: tree: default\n";
    print TIND "tinderbox: builddate: ".$startTime."\n";
    print TIND "tinderbox: status: building\n";
    print TIND "tinderbox: build: ".$sysname."\n";
    print TIND "tinderbox: errorparser: unix\n";
    print TIND "tinderbox: END\n";
    close(TIND);
  }

# If we're doing a real PHENIX install, then there is an official
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
my $linktg;
if ($opt_phenixinstall && !$opt_scanbuild && !$opt_coverity)
{
    $place = '/afs/rhic.bnl.gov/sphenix/'.$opt_version;
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
    $inst = $workdir.'/install';
    $linktg = $inst;
    $number = 0;
    #$realpath = realpath($inst); # DLW: at nevis we aren't a phenixinstall, but would like to have the numbering
    #($number) = $realpath =~ m/.*\.(\d+)$/;
  }

my $newnumber = ($number % $MAXDEPTH) + 1;
$installDir = $inst.".".$newnumber;

my $linkTarget = $linktg.".".$newnumber;
if ($opt_stage == 5)
{
  goto INSTALLONLY;
}

# Make the source directory and (maybe) populate it from CVS.
$sourceDir = $opt_source ? $opt_source : $workdir."/source";
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
    mkpath($sourceDir, 0, 0775) unless -e $sourceDir;
    chdir $sourceDir;
    $gitcommand = "git clone https://github.com/sPHENIX-Collaboration/coresoftware.git";
    print LOG $gitcommand, "\n";
    goto END if &doSystemFail($gitcommand);
    $gitcommand = "git clone https://github.com/sPHENIX-Collaboration/online_distribution.git";
    print LOG $gitcommand, "\n";
    goto END if &doSystemFail($gitcommand);
    if($opt_gittag ne '')
      {
	my $gittagcmd = sprintf("git checkout -b %s.%d %s",$opt_version,$newnumber,$opt_gittag);
        print LOG $gittagcmd, "\n";
        goto END if &doSystemFail($gittagcmd);
      }
    # Get rid of the old installDir, if it exists.  If the source area
    # already exists, assume we are re-trying a failed build.  Don't
    # delete the installDir then.
    rmtree $installDir;

  }

# Make the build area.
$buildDir = $workdir."/build";
mkpath($buildDir,0,0775) unless -e $buildDir;

# We no longer try to install the insure reports directly in a web
# accessible area - if you want to put the reports on the web, copy
# them there after the build has succeeded.
if ($opt_insure)
  {
    $insureDir = $workdir.'/reports';
    if ($opt_stage == 0)
      {
        rmtree $insureDir;
        mkpath($insureDir, 0, 0775);
        $gusDir = $workdir.'/gus';
        rmtree $gusDir;
        mkpath($gusDir, 0, 0775);
        $ENV{GUSDIR} = $gusDir;
      }
   $insureCompileFlags = ' CC="insure gcc -g" CXX="insure g++" CCLD="insure g++"';
  }
$oldOfflineMain = $OFFLINE_MAIN;
$OFFLINE_MAIN = $installDir;
$ENV{OFFLINE_MAIN} = $installDir;
$ENV{ONLINE_MAIN} = $installDir;
$oldOfflineMain =~ s/\+/\\\+/;
$LD_LIBRARY_PATH =~ s/$oldOfflineMain/$OFFLINE_MAIN/ge;
$PATH =~ s/$oldOfflineMain/$OFFLINE_MAIN/ge;
mkpath($installDir."/share", 0, 0775) unless -e $installDir."/share";

print LOG "===========================================\n";
print LOG "Here we can see if the environment is sane.\n";
print LOG "===========================================\n";
`printenv  >>$logfile 2>&1`;

# Start building packages
    if ($opt_stage < 2)
    {
        my $ROOTSYS_NOAFSSYS = realpath($ROOTSYS);
        $ROOTSYS_NOAFSSYS =~ s/\@sys/$afs_sysname/;
	symlink $ROOTSYS_NOAFSSYS, $installDir."/root";
	$ENV{ROOTSYS} = $installDir."/root"; #to get ROOTSYS for configure
	my $G4_MAIN_NOAFS = realpath($G4_MAIN);
        $G4_MAIN_NOAFS =~ s/\@sys/$afs_sysname/;
        symlink $G4_MAIN_NOAFS, $installDir."/geant4";
        $ENV{G4_MAIN} = $installDir."/geant4"; #to get G4_MAIN for configure
	foreach my $m (@externalPackages)
	{
	    my $dir = $externalPackagesDir."/".$m;
	    if (! -d $dir)
	    {
		print LOG "cannot find dir $dir for package $m\n";
		if ($opt_notify)
		{
		    print LOG "\nsending external package failure mail to $buildmanager\n";
		    open( MAIL, "|$SENDMAIL" );
		    print MAIL "To: $buildmanager\n";
		    print MAIL "From: The Phenix rebuild daemon\n";
		    print MAIL "Subject: external package $dir does not exist\n\n";
		    print MAIL "\n";
		    print MAIL "Hello,\n";
		    print MAIL "The rebuild could not find the external package dir $dir of package $m at $date.\n";
		    print MAIL "Yours, The Rebuild Daemon \n";
		    close(MAIL);
		}
		goto END;
	    }
	    chdir $dir;
	    print LOG "rsyncing $dir\n";
	    system("rsync -a . $installDir");
	}
        # patch for GenFit to install includes in subdir
        $dir = sprintf("%s/genfit2_root-%s",$externalPackagesDir,$rootversion);
	if (! -d $dir)
	{
	    print LOG "cannot find dir $dir for genfit2\n";
	    goto END;
	}
        chdir $dir;
	system("rsync -a lib  $installDir");
	chdir "include";
	mkpath($installDir."/include/GenFit", 0, 0775) unless -e $installDir."/include/GenFit";
 	system("rsync -a . $installDir/include/GenFit");
# modify all *.la files of external packages to point to this OFFLINE_MAIN, if someone can figure
# out how to do the following one liner that would be enough:
#    system("perl -e \"s/libdir=.*/libdir='$OFFLINE_MAIN\/lib'/g\" -p -i.old $OFFLINE_MAIN/lib/*.la");
# Since I did not succeed with this here is the ugly by hand implementation:
	$repl = "libdir='" . $OFFLINE_MAIN . "/lib'"; 
	open(F,"find $OFFLINE_MAIN/lib -name '*.la' -print |");
	while ($lafile = <F>)
	{
	    chomp $lafile;
	    $bckfile = $lafile . ".bck";
	    move($lafile,$bckfile);
	    open(F1,$bckfile);
	    open(F2,">$lafile");
	    while ($line = <F1>)
	    {
		$line =~ s/libdir=.*/$repl/g;
		print F2 $line;
	    }
	    close(F1);
	    unlink $bckfile;
	    close(F2);
	}
	close(F);

    foreach my $m (@package)
      {
	my $sdir = realpath($sourceDir)."/".$m;
	my $bdir = realpath($buildDir)."/".$m;
	mkpath($bdir,0,0775);
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
	print LOG "========================================================\n";
	    if ( $opt_scanbuild && exists $scanbuildignore{$m})
	    {
		$arg = "env $compileFlags $sdir/autogen.sh --prefix=$installDir";
	    }
	    else
	    {
		$arg = "env $compileFlags $scanbuild $sdir/autogen.sh --prefix=$installDir --cache-file=$buildDir/config.cache";
	    }

	if (&doSystemFail($arg))
	  {
	    if ($opt_notify)
	      {
		print LOG "\nsending configure failure mail to $contact{$m}, cc $CC\n";
		open( MAIL, "|$SENDMAIL" );
		print MAIL "To: $contact{$m}\n";
                print MAIL "From: The Phenix rebuild daemon\n";
                print MAIL "Cc: $CC\n";	
                print MAIL "Subject: your configure crashed the build\n\n";
		print MAIL "\n";
	        print MAIL "Hello,\n";
		print MAIL "The rebuild crashed in module $m at $date.\n";
		print MAIL "\"$arg\" failed: $? \n";
		print MAIL "Please look at the rebuild log, found on: \n";
		print MAIL "http://www.phenix.bnl.gov/software/sPHENIX/tinderbox\n";
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
	$sdir = realpath($sourceDir)."/".$m;
	$bdir = realpath($buildDir)."/".$m;
	chdir $bdir;
        chomp ($date = `date`);

	print LOG "=======================================================\n";
	print LOG "installing header files and scripts in  $m             \n";
	print LOG "at $date                                               \n";
	print LOG "=======================================================\n";
	$arg = "make install-data";

	if (&doSystemFail($arg))
	  {
	    if ($opt_notify)
	      {
		print LOG "\nsending install-data failure mail to $contact{$m}, cc $CC\n";
		open( MAIL, "|$SENDMAIL" );
		print MAIL "To: $contact{$m}\n";
                print MAIL "From: The Phenix rebuild daemon\n";
                print MAIL "Cc: $CC\n";	
                print MAIL "Subject: your install-data crashed the build\n\n";
		print MAIL "\n";
		print MAIL "Hello,\n";
		print MAIL "The rebuild crashed in $m.\n";
		print MAIL "\"$arg\" failed: $? \n";
		print MAIL "Please look at the rebuild log: \n";
		print MAIL "http://www.phenix.bnl.gov/software/sPHENIX/tinderbox\n";
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
	$bdir = realpath($buildDir)."/".$m;
	chdir $bdir;
        chomp ($date = `date`);

	print LOG "=================================\n";
	print LOG "building $m                      \n";
	print LOG "at $date                         \n";
	print LOG "=================================\n";

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
	       $arg = "$covbuild make $insureCompileFlags $JOBS ";
	    }
	}
	if (&doSystemFail($arg))
	{
	    if ($opt_notify)
	    {
		print LOG "\nsending compile failure mail to $contact{$m}, cc $CC\n";
		open( MAIL, "|$SENDMAIL" );
		print MAIL "To: $contact{$m}\n";
		print MAIL "From: The Phenix rebuild daemon\n";
		print MAIL "Cc: $CC\n";	
		print MAIL "Subject: your code crashed the $opt_version build\n\n";
		print MAIL "Hello,\n";
		print MAIL "The rebuild crashed in $m on $date:\n";
		print MAIL "\"$arg\" reason: $? \n";
		print MAIL "Please look at the rebuild log, found on: \n";
		print MAIL "http://www.phenix.bnl.gov/software/sPHENIX/tinderbox\n";
		print MAIL "Sincerely, the rebuild daemon \n";
		close(MAIL);
	    }
	    goto END;
	}

	if ($m =~ /MuTrigLL1Emulator/ && $opt_insure)
	{
	    $arg = "make CCLD='insure g++' $JOBS install ";
	}
	else
	{
	    $arg = "$covbuild make $insureCompileFlags $JOBS install ";
	}
	if (&doSystemFail($arg))
	  {
	    if ($opt_notify)
	      {
		print LOG "\nsending compile failure mail to $contact{$m}, cc $CC\n";
		open( MAIL, "|$SENDMAIL" );
		print MAIL "To: $contact{$m}\n";
                print MAIL "From: The Phenix rebuild daemon\n";
                print MAIL "Cc: $CC\n";	
                print MAIL "Subject: your code crashed the build\n\n";
		print MAIL "Hello,\n";
		print MAIL "The rebuild crashed in $m on $date:\n";
		print MAIL "\"$arg\" reason: $? \n";
		print MAIL "Please look at the rebuild log, found on: \n";
		print MAIL "http://www.phenix.bnl.gov/software/sPHENIX/tinderbox\n";
		print MAIL "Sincerely, the rebuild daemon \n";
		close(MAIL);
	      }
	    goto END;
	  }

	  if (! $opt_sl7)
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
    my $gitcommand = "git clone https://github.com/sPHENIX-Collaboration/calibrations $OFFLINE_MAIN/share/calibrations";
    print LOG $gitcommand, "\n";
    goto END if &doSystemFail($gitcommand);
  }
# all done adjust libdir in remaining *.la files to point
# to /afs/rhic.bnl.gov/
$repl = "libdir='" . $linkTarget . "/lib'"; 
print LOG "adjusting la files, replacing libdir=$OFFLINE_MAIN/lib by $repl\n";
open(F,"find $OFFLINE_MAIN/lib -name '*.la' -print |");
while ($lafile = <F>)
{
    chomp $lafile;
    $bckfile = $lafile . ".bck";
    move($lafile,$bckfile);
    open(F1,$bckfile);
    open(F2,">$lafile");
    while ($line = <F1>)
    {
	$line =~ s/libdir=.*/$repl/g;
	print F2 $line;
    }
    close(F1);
    unlink $bckfile;
    close(F2);
}
close(F);

if ($opt_root6)
{
    print LOG "copying pcm files with\n";
    print LOG "find $buildDir -name '*.pcm' -exec cp {} $installDir/lib  \\;\n";
    system("find $buildDir -name '*.pcm' -exec cp {} $installDir/lib  \\;");
}

INSTALLONLY:

$buildSucceeded = 1;

# OK, installation done; move symlink over
unlink $inst if (-e $inst);
symlink $linkTarget, $inst;
# install for scan and coverity build means copying reports which are not in afs
if ($opt_phenixinstall && !$opt_scanbuild && !$opt_coverity)
{
    my $releasedir = sprintf("/afs/rhic.bnl.gov/sphenix/sys/%s/log",$afs_sysname);
# if we don't have to release the afs volume we are done here
    if (! -d $releasedir)
    {
	$buildSucceeded=1;
	goto END;
    }
    my $releasefile = sprintf("%s/afs.release",$releasedir);
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
	$buildSucceeded==0;
	goto END;
    }
NORELEASEFILE:
    if ($opt_version =~ /ana/)
      {
        chomp ($date = `date`);
	print LOG "$date creating taxi afs dirs\n";
        create_afs_taxi_dir();
      }
    chomp ($date = `date`);
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
    chomp (my $date = `date`);
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
  $buildSucceeded==0 && ($buildStatus='busted', last END);
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
    my $cmd = sprintf("cat %s | /phenix/WWW/offline/sPHENIX/tinderbox/handlemail.pl /phenix/WWW/offline/sPHENIX/tinderbox",$logfile);
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
print INFO " source dir:".$Link{'source'}."\n ";
print INFO " build dir:".$Link{'build'}."\n ";
print INFO " install dir:".$Link{'install'}."\n ";
print INFO " for build logfile see: ".$logfile." or \n ";
print INFO " http://www.phenix.bnl.gov/software/sPHENIX/tinderbox/showbuilds.cgi?tree=default&nocrap=1&maxdate=".$startTime."\n";
print INFO " git tag: \n".$opt_gittag."\n";
print INFO " git command used: \n".$gitcommand."\n";
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
    return $status;
  }


sub check_insure_reports
{
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
	    print MAIL "From: The Phenix rebuild daemon\n";
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
	print MAIL "From: The Phenix rebuild daemon\n";
	print MAIL "Cc: $CC\n";	
	print MAIL "Subject: your module $mods[0] expired\n\n";
	print MAIL "Hello,\n";
	print MAIL "Your module $mods[0] has reached is expiration date on $date.\n";
	print MAIL "You can reenable it on the web under:\n";
	print MAIL "https://www.phenix.bnl.gov/WWW/p/draft/anatrain/TrainV2/trainbuild/modifymodule.html\n";
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
    mkpath($afstaxipath, 0, 0775) unless -e $afstaxipath;
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
	my $covcmd = sprintf("cov-commit-defects --host rldap09.rcf.bnl.gov --stream coresoftware --user admin --dir %s",$covdir,$opt_covpasswd);
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
	my $installroot = "/phenix/WWW/p/draft/phnxbld/sphenix/coverity/report";
	my $realpath = realpath($installroot);
	(my $inst,my $number) = $realpath =~ m/(.*)\.(\d+)$/;
	my $newnumber = ($number % 2) + 1;
	my $installdir = sprintf("%s.%d",$inst,$newnumber);
	rmtree $installdir;
	mkpath($installdir, 0, 0775);
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
		    while(my $line = <F2>)
		    {
			print LOG "$line";
		    }
		    close(F2);
		    my $packagename = $packages;
		    $packagename =~  s/\./\//g;
		    print F1 "<a href=\"$packages\">$packages</a> contact: $contact{$packagename} </br>\n";
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
    my $installroot = "/phenix/WWW/p/draft/phnxbld/scan-build/scan";
    my $realpath = realpath($installroot);
    (my $inst,my $number) = $realpath =~ m/(.*)\.(\d+)$/;
    my $newnumber = ($number % 2) + 1;
    my $installdir = sprintf("%s.%d",$inst,$newnumber);
    rmtree $installdir;
    mkpath($installdir, 0, 0775);
# copy all reports to WWW accessible place
    system("cp -rp $scanlogdir/* $installdir");
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
    for my $packages (sort keys %packets)
    {
	my $hrefentry = basename($packets{$packages});
        my $packagename = $packages;
	$packagename =~  s/\./\//g;
	print F "<a href=\"$hrefentry\">$packages</a> contact: $contact{$packagename} </br>\n";
	if (exists $contact{$packagename})
	{
	    $mailinglist{$packagename} = "https://www.phenix.bnl.gov/WWW/p/draft/phnxbld/scan-build/scan/$hrefentry";
	}
	else
	{
	    print LOG "Could not locate contact for package $packagename\n";
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
	    my $scancc = "pinkenburg\@bnl.gov,bathe\@bnl.gov";
	    print LOG "\nsending scanbuild report mail to $contact{$package}, cc $scancc\n";
	    open( MAIL, "|$SENDMAIL" );
	    print MAIL "To: $contact{$package}\n";
	    print MAIL "From: The Phenix rebuild daemon\n";
	    print MAIL "Cc: $scancc\n";	
	    print MAIL "Subject: scan-build found issues in $package\n\n";
	    print MAIL "Hello $contact{$package},\n";
	    print MAIL "scan-build the static analyzer based on clang has found problems\n";
            print MAIL "in your module $package on $date.\n";
	    print MAIL "The report is under\n\n";
	    print MAIL "$mailinglist{$package}\n\n";
            print MAIL "All reports are available under\n\n";
            print MAIL "https://www.phenix.bnl.gov/WWW/p/draft/phnxbld/scan-build/scan\n\n";
	    print MAIL "instructions how to run scan-build yourself are in our wiki\n\n";
	    print MAIL "https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/Scan-build\n\n";
            print MAIL "Please look at the report and fix the issues found\n";
	    print MAIL "Sincerely yours, The Rebuild Daemon \n\n";
	    close(MAIL);
	}
    }
}


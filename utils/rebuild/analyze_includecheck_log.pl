#!/usr/bin/perl

# This parses the logfile from building with the clang include checker
# it should give a file by file summary which include files should be added
# and which ones should be removed
# naturally there is an ever growing list of exceptions for files which
# should not be removed or included
use strict;
use warnings;

sub checkadd;
sub checkfilename;
sub checkinclude;
sub checkremove;

if ($#ARGV < 0)
{
    print "usage: analyze_includecheck_log.pl <rebuild log>\n";
    exit(1);
}

if (! -f $ARGV[0])
{
    die " $ARGV[0] is not a file\n";
}

my %FileWithAddIssue;
my %FileWithRemoveIssue;
my $filename;
my $addactive = 0;
my $removeactive = 0;

open(F,"$ARGV[0]");
while(my $line = <F>)
{
#    chomp $line;
    if ($line =~ /The full include-list/)
    {
#        print $line;
	$addactive = 0;
	$removeactive = 0;
	next;
    }
    if ($line =~ /should add these lines/)
    {
#        print $line;
	my @sp1 = split(/ /,$line);
	my @sp2 = split(/source\//,$sp1[0]);
	$filename = $sp2[1];
	if (! defined $filename)
	{
	    $addactive = 0;
	    $removeactive = 0;
	    next;
	}

	if (! &checkfilename($filename))
	{
	    $addactive = 0;
	    $removeactive = 0;
	    next; 
	}
#	print "$line\n";
#	print "$filename\n";
	$addactive = 1;
	$removeactive = 0;
	next;
    }

    if ($addactive == 1)
    {
	if ($line =~ /\#include/ || $line =~ /class/)
	{
#	    print "$line\n";
	    if (&checkadd($line))
	    {
		if (! defined $filename)
		{
		    print "undefined filename: $line";
		}
		else
		{
		    push(@{$FileWithAddIssue{$filename}},$line);
		}
	    }
	    next;
	}
    }
    if ($line =~ /should remove these lines/)
    {
	my @sp1 = split(/ /,$line);
	my @sp2 = split(/source\//,$sp1[0]);
	$filename = $sp2[1];
	if (! defined $filename)
	{
	    $addactive = 0;
	    $removeactive = 0;
	    next;
	}

	if (! &checkfilename($filename))
	{
	    $addactive = 0;
	    $removeactive = 0;
	    next;
	}
#	print "$line\n";
#	print "$filename\n";
	$addactive = 0;
	$removeactive = 1;
	next;
    }
    if ($removeactive == 1)
    {
	if ($line =~ /\#include/ || $line =~ /class/)
	{
	    if (&checkremove($line))
	    {
		push(@{$FileWithRemoveIssue{$filename}},$line);
	    }
	    next;
	}
    }

}
close(F);

foreach my $file (sort keys %FileWithAddIssue)
{
    print "add for $file:\n";
    print "@{$FileWithAddIssue{$file}}\n";
    if (exists $FileWithRemoveIssue{$file})
    {
	print "remove:\n";
	print "@{$FileWithRemoveIssue{$file}}\n";
        delete $FileWithRemoveIssue{$file};
    }
    
}
foreach my $file (sort keys %FileWithRemoveIssue)
{
    print "remove for $file:\n";
    print "@{$FileWithRemoveIssue{$file}}\n";
}

sub checkadd
{
    my $include_line = shift(@_);
    if (! &checkinclude($include_line))
    {
	return 0;
    }
    if (
	$include_line =~ /\"boost\/accumulators\/framework\/accumulator_set.hpp\"/ ||
	$include_line =~ /\"boost\/accumulators\/framework\/extractor.hpp\"/ ||
	$include_line =~ /\"boost\/accumulators\/framework\/features.hpp\"/ ||
	$include_line =~ /\"boost\/accumulators\/statistics\/variance.hpp\"/ ||
	$include_line =~ /\"boost\/algorithm\/string\/classification.hpp\"/ ||
        $include_line =~ /\"boost\/algorithm\/string\/detail\/classification.hpp\"/ ||
	$include_line =~ /\"boost\/algorithm\/string\/split.hpp\"/ ||
	$include_line =~ /\"boost\/bimap\/bimap.hpp\"/ ||
	$include_line =~ /\"boost\/bimap\/container_adaptor\/container_adaptor.hpp\"/ ||
	$include_line =~ /\"boost\/bimap\/detail\/bimap_core.hpp\"/ ||
	$include_line =~ /\"boost\/bimap\/detail\/map_view_iterator.hpp\"/ ||
	$include_line =~ /\"boost\/bimap\/relation\/structured_pair.hpp\"/ ||
	$include_line =~ /\"boost\/format\/alt_sstream.hpp\"/ ||
	$include_line =~ /\"boost\/format\/format_class.hpp\"/ ||
	$include_line =~ /\"boost\/format\/format_fwd.hpp\"/ ||
	$include_line =~ /\"boost\/format\/format_implementation.hpp\"/ ||
	$include_line =~ /\"boost\/format\/free_funcs.hpp\"/ ||
	$include_line =~ /\"boost\/fusion\/iterator\/deref.hpp\"/ ||
	$include_line =~ /\"boost\/graph\/detail\/adjacency_list.hpp\"/ ||
	$include_line =~ /\"boost\/graph\/detail\/edge.hpp\"/ ||
	$include_line =~ /\"boost\/graph\/graph_selectors.hpp\"/ ||
        $include_line =~ /\"boost\/iterator\/iterator_facade.hpp\"/ ||
	$include_line =~ /\"boost\/multi_index\/detail\/bidir_node_iterator.hpp\"/ ||
	$include_line =~ /\"boost\/optional\/optional.hpp\"/ ||
	$include_line =~ /\"boost\/pending\/property.hpp\"/ ||
	$include_line =~ /\"boost\/type_index\/type_index_facade.hpp\"/ ||
        $include_line =~ /CLHEP\/Units\/SystemOfUnits.h/ ||
        $include_line =~ /\"Core\"/ ||
        $include_line =~ /Eigen\/src/  ||
        $include_line =~ /Eigen\/Dense/ ||
        $include_line =~ /\.icc/ ||
        $include_line =~ /\"Rtypes.h\"/ ||
        $include_line =~ /<Rtypes.h>/ ||
        $include_line =~ /\"RtypesCore.h"/ ||
        $include_line =~ /\"src\/Core/ ||
        $include_line =~ /<type_traits>/ ||
        $include_line =~ /class TBuffer/ ||
        $include_line =~ /class TClass/ ||
        $include_line =~ /class TMemberInspector/ 
	)
    {
	return 0;
    }
    return 1;
}

sub checkremove
{
    my $include_line = shift(@_);
    if (! &checkinclude($include_line))
    {
	return 0;
    }
    if (
	$include_line =~ /<boost\/bimap.hpp>/ ||
	$include_line =~ /<boost\/bind.hpp>/ ||
        $include_line =~ /<boost\/format.hpp>/ ||
        $include_line =~ /<Eigen\/Dense>/ ||
        $include_line =~ /<Eigen\/LU>/ ||
        $include_line =~ /ostream/ ||
        $include_line =~ /fstream/ ||
        $include_line =~ /sstream/
	)
    {
	return 0;
    }
    return 1;
}

sub checkinclude
{
    my $include_line = shift(@_);
    if (
         $include_line =~ /alloc_traits/
	)
    {
	return 0;
    }
    return 1;
}

sub checkfilename
{
    my $filename = shift(@_);
    if (
	$filename =~ /Dict/
	)
    {
	return 0;
    }
    return 1;
}

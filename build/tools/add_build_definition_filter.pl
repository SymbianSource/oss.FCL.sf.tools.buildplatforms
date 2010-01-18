#
# Copyright (c) 2007 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
#

use strict;
use File::Find;     # for finding
use File::Basename; # for fileparse
use File::Copy 'copy';
use File::Path;    
use Getopt::Long;

my (@sysdeffiles, @filters);

if ( !GetOptions(
	'i=s' => \@sysdeffiles,
	'f:s' => \@filters
	))
{
	&error_msg("Invalid arguments!\n");
}

if (!scalar (@filters)){	&error_msg("No filter(s) to set!\n")};
if (!scalar (@sysdeffiles)){	&error_msg("No files to set filters\n")};

my $checkfilters = "";
foreach (@filters) {
	next if ($_ !~ /\w/i);
	$checkfilters .=$_;
	$checkfilters .=",";
}
# no filters to add
if ($checkfilters eq "") {die "nothing to do\n";};

foreach my $file (@sysdeffiles) {
	eval {set_filters($file);};
	if ($@) {
		print "failed $@ \n";
	}
}

sub set_filters {
	my $sysdeffile = shift;
	my @updated_data;
	
 	open (ORIG,"${sysdeffile}") or die("Cannot open $sysdeffile");
	my @orig_data=<ORIG>;
	close ORIG;

	copy($sysdeffile, $sysdeffile.".orig");
	
	foreach (@orig_data) {
		chomp;
		if ($_ =~ /(<configuration)/i) {
			my $filterline = getfilterline($_);
			$_ =~ s/^.*filter=?\"/$&${filterline}/i;
			$_ =~ s/,\"/\"/i;
		}
		push @updated_data, $_."\n";
	}

	open (UPDATED, ">${sysdeffile}");
  print UPDATED @updated_data;
	close UPDATED;
}

sub getfilterline {
	my $conffilter = shift;
	my $newfilterline = ""; 

	$conffilter =~ s/.*filter=\"//i;
	$conffilter =~ s/\".*//i;
	
	my @oldfilters = split(',', $conffilter);
	
	foreach (@filters) {
		my $match = 0;
		next if ($_ !~ /\w/i);
# check if filter is defined already
		foreach my $old (@oldfilters) {
			if ($old eq $_) {
				$match = 1;
				last;
			}
		}
# add filter only if it is new
		if (!$match) {
			$newfilterline .= $_;
			$newfilterline .=",";
		}
		
	}

# remove last ',' if filters are not existed before
	if (! scalar (@oldfilters) && $newfilterline ne "") {
		$newfilterline =~ s/,$//i
	}
	
	return $newfilterline;
}

sub error_msg ($){
  my($ErrorMsg);
  ($ErrorMsg)=@_;
  my $given_command=$0;
  $given_command =~ s/.*\\(\w+\.\w+)$/$1/;
  print "Error: $ErrorMsg \n";
	print "Usage: \n$given_command -f <filter> -i <systemdefinition xml file>\n";
	print "           -f <filter> (multible allowed)\n";
	print "           -i <sysdef file> (multible allowed)\n";
	print "Example: \n$given_command -f test -i \\S60_SystemBuild.xml\n";
	print "\n";  
	die "\n";  
}

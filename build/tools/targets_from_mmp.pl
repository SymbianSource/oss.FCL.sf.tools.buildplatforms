#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#!/usr/bin/perl

# 
# ==============================================================================
#  Name        : targets_from_mmp.pl
#  Description : This script provides search functionality for target components
#                from mmp-files found from the environment.
#  Version     : 1
# ==============================================================================
# 

use strict;
use Cwd;
use File::Find;

use Getopt::Std;
use vars qw($opt_o $opt_i $opt_p $opt_s );

# -----------------------------------------------------------
# Check the arguments and if not any or too many print guide.
# -----------------------------------------------------------
if (( $#ARGV < 0) || ($#ARGV > 5))
{
         print <<USAGE;
         
Usage:    targets_from_mmp.pl [-p component] [-o output-file] [-s] [-i input-file]

   -p     prints the mmp-file(s) related to component.
   -i     specify the input file from where to search for
          mmp-target relation (value is "targets_from_mmps.txt"
          if else not specified).
   -s     scans the environment and prints the output to
          "targets_from_mmps.txt" or to separately specified
          file (with option -o).
   -o     output-file where to write scanning results.
 
 At least one option is required.
 
Examples: targets_from_mmp.pl -s
          targets_from_mmp.pl -s -o targets_from_mmps.txt
          targets_from_mmp.pl -p clock.dll
          targets_from_mmp.pl -p clock.dll -i targets_from_mmps.txt
USAGE
	exit -1;
}

# ---------------
# Collect options
# ---------------
getopts("o:i:p:s");

my ($inputfile, $outputfile);

# -----------------------------------------------------------
# If output-file is defined in arguments open specified file
# for printing the targets found from mmp-files.
# -----------------------------------------------------------
if ($opt_s)
{
	if ($opt_o)
	{
		$outputfile = $opt_o;
	}
	else
	{
		$outputfile = "targets_from_mmps.txt";
	}
	
	open (OUTPUT, ">$outputfile");
	print "\nWriting targets of mmp-files into \"$outputfile\".\n";
	
	find(\&doFind, cwd);
}

# ----------------------------------------------------
# If special input file is defined.
# ----------------------------------------------------
if ($opt_i)
{
	$inputfile = $opt_i;
}
else
{
	$inputfile = "targets_from_mmps.txt";
}

# ----------------------------------------------------
# If component to search is defined in arguments print
# indication of that on screen.
# ----------------------------------------------------
if ($opt_p)
{
	open (INPUT, $inputfile) or die "\nInputfile \"$inputfile\" not found, please check the filename or scan the environment first!\n";
	#print "\nSearching mmp-file for target \"$opt_p\" from \"$inputfile\"...\n\n";
	
	my $found_indicator=0;
	
	foreach my $line (<INPUT>)
	{
		if ($line =~ m/(.*) : $opt_p/i)
		{
			print "\n $opt_p -->\n" if ($found_indicator == 0);
			$found_indicator++;
			print "    $1";
		}
	}
	
	print "\nCould not find target \"$opt_p\" from any mmp-file (from \"$inputfile\")!\n" if ($found_indicator == 0);
	
	print "\n";
	close INPUT;
}

# --------------------------------------------
# Function to find the targets from mmp-files.
# --------------------------------------------
sub doFind
{
	my $file = $File::Find::name;
	
	$file =~ s,/,\\,g;
	return unless -f $file;
	
	return unless $file =~ /(?i)\.mmp$/;
	
	open F, $file or return;
	#print $file . "\n";

	if ($file =~ m/^\S:(.*)/i)
	{
		$file = $1;
	}
	
	my ($line, $foundSomething);
	
	$foundSomething = "false";
	
	while ($line=<F>)
	{
		if ($line=~ m/^[\s|\t]*(?i)TARGET[\s|\t]+(\S*).*$/)
		{
			# If output-file is defined print all findings to that.
			if ($outputfile)
			{

								
				print OUTPUT "$file : $1\n";
			}
			
			# If component to search is defined and found
			# print corresponding mmp-file on screen.
			
			$foundSomething = "true";
		}
	}
	
	if ($foundSomething eq "false")
	{
		#print "no TARGET found from $file\n";    
	}
	
	close F;
}

if ($outputfile)
{
	close OUTPUT;
}

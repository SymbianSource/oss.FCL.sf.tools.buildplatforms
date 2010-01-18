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
#!perl
# This script converts new-style System Definition XML files to the older
# .TXT file format (i.e. files of the type GT.TXT, Techview.TXT etc.)

#
# Modified by S60 to get two xml input file
# Can use cases when system model and system build located in different files
#

use strict;
use FindBin;		# for FindBin::Bin
use lib $FindBin::Bin;
use Getopt::Long;
use SysDefToText;

my $debug;

my ($config, $XMLfile, $outfile, $logfile) = ProcessCommandLine();

print STDERR "Configuration:    $config\n";
print STDERR "Input .XML file:  @$XMLfile\n";
print STDERR "Output .TXT file: $outfile\n";
if (defined $logfile)
    {
    print STDERR "Logfile:          $logfile\n";
    }

SysDefToText::ConvertFile($config, $XMLfile, $outfile, $logfile);

exit(0);

# ProcessCommandLine
#
# Inputs
#   @ARGV
#
# Outputs
#   Returns Configuration Nmae and filenames.
#
# Description
#   This function processes the command line
#   On error, exits via Usage();

sub ProcessCommandLine
{
    my ($help, $config, @XMLfile, $XMLfile1, $outfile, $logfile);
    my $args = @ARGV;

    my $ret = GetOptions('h' => \$help, 'n=s' => \$config, 'x=s' => \@XMLfile, 'o=s' => \$outfile, 'l=s' => \$logfile);

    if (($help) || (!$args) || (!$ret) || (!@XMLfile) || (!defined $config) || (!defined $outfile))
    {
        Usage();
    }
    if (@ARGV)
    {
        Usage ("Redundant information on command line: @ARGV");
    }
    return($config, \@XMLfile, $outfile, $logfile);
}

# Usage
#
# Input: Error message, if any
#
# Output: Usage information.
#

sub Usage
{
    if (@_)
    {
        print "\n****@_\n";
    }

    print <<USAGE_EOF;

    Usage: SysDefToText.pl parameters [options]

    Parameters:

    -x   XML System Model File [Multiple -x options allowed]
    -n   Named Configuration
    -o   Output Text (.TXT) file

    Options:

    -h   Display this Help and exit.
    -l   Logfile (.LOG)

USAGE_EOF

    exit 1;
}

sub dbgprint
{
    if($debug) { print ">>@_"; }
}

__END__

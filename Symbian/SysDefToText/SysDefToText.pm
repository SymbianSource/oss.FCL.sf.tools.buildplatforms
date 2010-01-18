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
# This module converts new-style System Definition XML files to the older
# .TXT file format (i.e. files of the type GT.TXT, Techview.TXT etc.)

package SysDefToText;
use strict;
use SysDefCollector;
use SysDefParser;

# ConvertFile
#
# Inputs
#   Name of XML file to read
#   Configuration name
#
# Outputs
#   Writes data to Text File
#   Writes to log file, if filename defined.
#
# Description
#   This is the "top level" subroutine for the conversion of a "SysDef" .XML file to an old format "Text" file.
#
sub ConvertFile
{
    my ($configname, $XMLfile, $outfile, $logfile) = @_;

#    my $XMLhandle = \*XMLFILE;
    my $outhandle = \*OUTFILE;
    my $loghandle = \*LOGFILE;

#    open $XMLhandle, "<$XMLfile" or die "Cannot open input file: $XMLfile";
    open $outhandle, ">$outfile" or die "Cannot open output file: $outfile";
    if (defined $logfile)
    {
        open $loghandle, ">$logfile" or die "Cannot open logfile: $logfile";
        print $loghandle "Processing: $XMLfile    Output to: $outfile\n";
        print $loghandle "==================================================\n";
    }
    else
    {
        $loghandle = \*STDERR;
    }
    
    my $sysdef = SysDefCollector->new($configname,$loghandle);
    my $parser = SysDefParser->new(-client => $sysdef->parserClient());

		foreach my $file (@$XMLfile) {
	    my $XMLhandle = \*file;
	    open $XMLhandle, "<$file" or die "Cannot open input file: $file";
	    $parser->parse($XMLhandle);
	    close $XMLhandle;
		}

    ## Suppress this debugging!
    ##{   # FTB just call dump() and test() routines.
        #$sysdef->dump($loghandle);
        #$sysdef->test($loghandle);
    ##}
    
    WriteHeader($outhandle,$configname,$XMLfile);

    my @list0 = $sysdef->options();          # ABLD options
    my @list1 = $sysdef->targets();
    WriteOptionList($outhandle,\@list0,\@list1);

    my @list2 = $sysdef->components();
    my $bootflag = $sysdef->specialInstructionsFlag();
    WriteComponentList($outhandle,\@list2,$bootflag);
    
#    close XMLFILE;
    close OUTFILE;
    if (defined $logfile) { close LOGFILE; }
}

# WriteHeader
#
# Inputs
#   Handle of Text file to which to write
#   Configuration name
#
# Outputs
#   Writes data to Text File
#
# Description
#   This subroutine initiates the old format "Text" file.
#
sub WriteHeader
{
    my $fh = shift;
    my $config = shift;
    my $XMLfile = shift;
    print $fh <<HEADER_TXT;
#
# ****************************** IMPORTANT NOTE ************************************
#
# This file was generated using information read from: @$XMLfile.
# The configuration was specified as: $config
#
# **********************************************************************************
#

HEADER_TXT
}

# WriteOptionList
#
# Inputs
#   Handle of Text file to which to write
#   Array reference for list of ABLD Options
#   Array reference for list of targets
#
# Outputs
#   Writes data to Text File
#
# Description
#   This subroutine writes out options and targets (one per line) to the old format "Text" file.
#   Note that option lines and target lines have the same format! 
#
sub WriteOptionList
{
    my $fh = shift;
    my $abldoptions = shift;      # Array ref.
    my $targets = shift;          # Array ref.
  
    print $fh "# Optional variations in the generated scripts\n\n";

    my $column2pos = 8;
    foreach my $option (@$abldoptions)
    {
        my $name = '<option ????>';
        if ($option =~ /^-(.+)/) {$name = "<option $1>"}
        my $len = length $name;
        while ($len > $column2pos) { $column2pos += 8; }
        printf $fh "%-*s\t# use abld %s\n", $column2pos, $name, $option;
    }

    foreach my $target (@$targets)
    {
        # abld targets are only one word
        next if ($target =~ /\w+\s+\w+/);
        my $name;
        if ($target =~ /(misa|mint|mcot|mtemplate|meig)/i)
        {
            $name = "<option arm_assp $target>";
        } else {
            $name = "<option $target>";
        }
        my $len = length $name;
        while ($len > $column2pos) { $column2pos += 8; }
        printf $fh "%-*s\t#\n", $column2pos, $name;
    }

    print $fh "\n";
}

# WriteComponentList
#
# Inputs
#   Handle of Text file to which to write
#   Hash reference for hash of Components
#
# Outputs
#   Writes data to Text File
#
# Description
#   This subroutine writes out the Name and filepath (abld_directory) for each component,
#   one component per line, to the old format "Text" file.
#
sub WriteComponentList
{
    my $fh = shift;
    my $listref = shift;    # Ordered array of array refs -> "Name" and "abld_directory" pairs
    my $bootflag = shift;   # Boolean flag indicates whether default bootstrap "component" required
    
    print $fh "# List of components required \n";
    print $fh "#\n# Name		abld_directory\n";

    if($bootflag)
        {
        print $fh "#\n# Bootstrapping....\n\n";
        print $fh "<special bldfiles E32Toolp group>			# Special installation for E32ToolP\n\n";
        print $fh "# Components:\n";
        }
    print $fh "#\n";

    ##print $fh "# Things which generate include files used by later components, e.g. .RSG, .MBG or .h files\n\n";
    ##print $fh "# Everything else\n\n";

    my $column2pos = 8;
    foreach my $component (@$listref)
    {
        my $len = length $component->[0];
        while ($len > $column2pos) { $column2pos += 8; }
        my $bldfile = $component->[1];
        if ($bldfile =~ /^\\/) {
          $bldfile =~ s/^\\//i;
        }
        printf $fh "%-*s\t%s\n", $column2pos, $component->[0], $bldfile;
    }
}

1;

__END__


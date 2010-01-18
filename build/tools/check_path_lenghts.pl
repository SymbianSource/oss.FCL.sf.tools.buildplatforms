#
# Copyright (c) 2002-2006 Nokia Corporation and/or its subsidiary(-ies).
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
# Description:  See the usage-method below.
#
use File::Find;
use File::Spec;
use Getopt::Long;
use strict;


# the 140 has not yet been officially defined. (7.7.2006)
my $limit = 140;
my $isFirstError = 1;
my @dirList;
my $resultFile = undef;


my $errString = qq(
The following filenames with path are longer than the allowed length,
which is $limit characters.

);


###########################################################################
###########################################################################
sub usage
{
    print "---------------------------------------------\n";
    print "THIS SCRIPT IS STILL UNDER EVALUATION. SOME INFORMATION\n";
    print "GIVEN IN THIS HELP HAS NOT YET BEEN AGREED ON\n";
    print "---------------------------------------------\n";
    print "\n";
    print "This script is intended to check the architectural domain (ADO)\n";
    print "directory hierarchy content in S60-build\n";
    print "It checks that the maximum path length does not exceed\n";
    print "the limitations specified for ADO structure.\n";
    print "All file names are listed, which exceed the specified limitation.\n";
    print "\n";
    print "Usage:\n";
    print "  $0 [-h|-help] [-t <theResultFilename>] -d <dir1> -d <dir2> \n";
    print "\n";
    print "Options:\n";
    print "  -h                  : Show this help\n";
    print "  -help               : Show this help\n";
    print "  -t <theFilename>    : The name of the file, where the errors are written.\n";
    print "                        If not specified errors are written to STDOUT\n";
    print "  -d <dir1>           : Absoluth path to the ADOs directory. The last item in the dir\n";
    print "                        should be the ADO name.\n";
    print "\n";
    print "Return values:\n";
    print "    0 : no errors found (or help wanted)\n";
    print "   -1 : errors found in check\n";
    print "   -2 : erronous command line parameters or in result file opening\n";
    print "\n";
    print "Usage example:\n";
    print "   in the below example replace \"<myadoname>\" with real ado name\n";
    print "   for example  <myadoname> == messaging\n";
    print "   perl $0 -t \my_path_results.txt -d \s60\app\<myadoname>\n";
    print "\n";
    print "Limitations:\n";
    print "  - No spaces allowed in the file or directory names !!!\n";
    print "\n";
}

###########################################################################
###########################################################################
sub errorUsage
{
    usage;
    exit(-2);
}
###########################################################################
###########################################################################
sub okUsage
{
    usage;
    exit(0);
}

###########################################################################
# Parses the command line parameters from ARGV
#
# Params: -
#
# Return: -		    
#
###########################################################################
sub parseCmdLine
{
    my $incorrectParam = 0;
    
    if( ! GetOptions('t=s'      => \$resultFile,
		     'd=s'      => \@dirList,
		     'h'        => \&okUsage,
		     'help'     => \&okUsage,
		     '<>'       => \&errorUsage))
    {
	exit(-2);
    }

    if(scalar(@dirList) == 0)
    {
	print STDERR  "\nERROR: At least one directory has to be specified with -d\n";
	exit(-2);
    }

    foreach  (@dirList)
    {
	if(/\s+/)
	{
	    print STDERR "\nERROR: No spaces allowed in directory names\n";
	    exit(-2);
	}
    }
}

sub handleFileopenError
{
    print STDERR  "\nERROR: Unable to open  $resultFile\n";
    exit(-2);
}

parseCmdLine;
if(defined($resultFile))
{
    open(FILEOUT,">$resultFile") || handleFileopenError;
}

###########################################################################
# print results
###########################################################################
sub printError
{

    if(defined($resultFile))
    {
	if($isFirstError > 0)
	{
	    $isFirstError = 0;
	    print FILEOUT $errString;
	}
	print FILEOUT join("",@_);;
    }
    else
    {
	if($isFirstError > 0)
	{
	    $isFirstError = 0;
	    print STDOUT $errString;
	}
	print STDOUT join("",@_);
    }
}

###########################################
# Conversion routine. 
#  - makes all dir separators to be "/"
#  - removes any drive letter from beginig of path
#########################################
sub convertPath
{
    my $path = shift;
    $path =~ s/\\/\//g;
    $path =~ s/^[A-Za-z]\://;
    
    return $path;
}

###########################################
# This function is called for each file by 
# the "find" functionality.
###########################################
my $currentlyHandling = "";
my $first = 1;
my $currentReplacement = "";
sub handleFile
{
    my $file = $_;
    my $fileDir = convertPath(File::Spec->catfile(File::Spec->splitdir($File::Find::dir)));
    if($fileDir !~ /^$currentlyHandling/i ||  $first == 1)
    {
	$first = 0;
      	$currentlyHandling = $fileDir;
    	my @items = File::Spec->splitdir($fileDir);
  	pop @items;
	$currentReplacement =  convertPath(File::Spec->catfile(@items));
	$currentReplacement .= "/";
    }

    my $total = convertPath($File::Find::name);

    $total =~ s/^$currentReplacement//g;
    
    if(length($total) > $limit)
    {
	printError "$total : " . length($total),"\n";
    }

}


# Gets the list of header files into the @filenames
find(\&handleFile,@dirList);


if(defined($resultFile))
{
    close FILEOUT;
}

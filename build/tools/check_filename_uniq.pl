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

my $isFirstError = 1;
my @dirList;
my $resultFile = undef;
my %extHash; # hash which contains the wanted extensions as keys

my $errString = qq(
The following filenames are not unique inside ADO. Note that if those
files are not part of compilation (listed in used bld.inf) => there 
are no immediate problems.

);


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
    $path =~ tr/A-Z/a-z/;
    
    return $path;
}

###########################################################################
###########################################################################
sub usage
{
    print "\n";
    print "This script is intended to check the architectural domain (ADO)\n";
    print "directory hierarchy content in S60-build.\n";
    print "It checks that the filenames with given extensions\n";
    print "are uniq inside the give ADO structure.\n";
    print "\n";
    print "Usage:\n";
    print "  $0 [-h|-help] [-t <theResultFilename>] [-e ext1 -e ext2] -d <dir1> -d <dir2> \n";
    print "\n";
    print "Options:\n";
    print "  -h                  : Show this help\n";
    print "  -help               : Show this help\n";
    print "  -t <theFilename>    : The name of the file, where the errors are written.\n";
    print "                        If not specified errors are written to STDOUT\n";
    print "  -d <dir1>           : Absoluth path to the ADOs directory. The last item in the dir\n";
    print "                        should be the ADO name.\n";
    print "  -e <ext1>           : file extensions that are checked.\n";
    print "                        If none given, then default value is \"-e mmp,mk\". \n";
    print "                        If one is specified then the default ones are not handled by default.\n";  
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
    print "   Below one only checks txt-files\n";
    print "   perl $0 -t \my_path_results.txt -e txt -d \s60\app\<myadoname>\n";
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
    my @extList;
    
    if( ! GetOptions('t=s'      => \$resultFile,
		     'd=s'      => \@dirList,
		     'e=s'      => \@extList,
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

    # if no ext given => use the default values.
    if(scalar(@extList) == 0)
    {
	$extHash{"mmp"} = 1;
	$extHash{"mk"} = 1;
    }
    else
    {
	# handle the extensions given	
	foreach my $param (@extList)
	{
	    my @items = split(",",$param);
	    foreach my $item (@items)
	    {
		# remove spaces
		$item =~ s/\s//g;
		$item = convertPath($item);
		$extHash{$item} = 1; 
	    }
	}
    }
}

###########################################################################
###########################################################################
sub handleFileopenError
{
    print STDERR  "\nERROR: Unable to open  $resultFile\n";
    exit(-2);
}


###########################################
# This function is called for each file by 
# the "find" functionality.
###########################################
# contains all the erronous file names, details in the 
# $refToFileHash
my $refToErrHash;
# content is:
# {filenamewithExt => (foundInDir1,foundInDir2)} 
my $refToFileHash; 

#actual function
sub handleFile
{
    my $file = convertPath($_);
    my $fileDir = convertPath(File::Spec->catfile(File::Spec->splitdir($File::Find::dir)));

    # the find seems to change the current dir => checking if the item is a dir
    # should be done from curr Dir (we need to add the ./ so that the -d (testing if
    # item is directory works)
    if( -d "./$file")
    {
	return;
    }

    # its a file, test wether the extension is what we want
    my @tmpList = split(/\./,$file);
    my $ext = pop @tmpList;

    if(defined($extHash{$ext}))
    {
	# is there same name already => if yes => error
	if(defined($$refToFileHash{$file}))
	{
	    $$refToErrHash{$file}  = 1;
	}
	# 1st occurance. Add as new item into the refToFileHash
	else
	{
	    my @list;
	    $$refToFileHash{$file} = \@list;
	}
	push(@{$$refToFileHash{$file}},$fileDir);
    }
}

###########################################################################
# MAIN functionality
###########################################################################
parseCmdLine;
if(defined($resultFile))
{
    open(FILEOUT,">$resultFile") || handleFileopenError;
}

# handle each root dir as separate case. This way
# we do not have to worry about stuff between dirs
foreach my $dir (@dirList)
{
    my %errFileHash;
    $refToErrHash = \%errFileHash;
    my %fileHash;
    $refToFileHash = \%fileHash;
    
    find(\&handleFile,($dir));
    
    # After one base dir has been handled, then print the found
    # errors related to that one.

    if(scalar(keys(%errFileHash)) > 0)
    {
	printError "\nUnder: $dir\n";
	foreach my $errFile (keys (%errFileHash))
	{
	    printError "   $errFile found in:\n";
	    foreach my $fileLoc (@{$fileHash{$errFile}})
	    {
		printError "      $fileLoc\n";
	    }
	}
    }
    else
    {
	printError "\nNo errors found under $dir\n";
    }
}

if(defined($resultFile))
{
    close FILEOUT;
}






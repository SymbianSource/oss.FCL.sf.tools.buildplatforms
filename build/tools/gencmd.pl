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
#    Generate xml that can give input for symbian tbs build system 
#
# ============================================================================
#  Name     : gencmd.pl
#  Part of  : Generate cmd file from input file
#  Origin   : S60 2.0,NMP
#  Created  : Tue Oct 6 11:32:47 2003
#  Version  : 1.0
#  Description: 
#    Generate xml that can give input for symbian tbs build system 
#	
#	
# structure of input file: 
# <[build]>         open specific build tag, not required, multiply allowed ( like <[build]><[build1]> )
#   [build] is given with parameter -b 
#   if [build] not match with given -b parameter, all lines inside this tag will ignore
# <\>               close specific build tag
#
# <#[name]>         open task block
#  cd \             specify directory where followed lines will be launch
#  command.cmd      command that will launch in above directory. command can be whatever (perl, cmd, exe...)
#  cd \temp         redefine directory where followed lines will be launch
#  command2.cmd     command that will launch in above directory. command can be whatever (perl, cmd, exe...)
# <\#>              close task block, close also specific build tag if open
#
# <parallel>        open parallel block, all task blocks that located inside same parallel block will be run parallel in tbs
# <\parallel>       close parallel block, close also task block and specific build tag
#
# comment (\\,#) and empty lines ingnore 
#
# example:
#
# <parallel>                        1st parallel block
# <#commonengine>                   first task
# cd \S60\commonengine\group       
# call bldmake bldfiles -k          command that will lauch 1st state
# call abld export -k               command that will lauch 2nd state
# <\#>
#  
# <#bldvariant>                     second task
# <S60_3_1>                         specify directory for 'S60_3_1' build
# cd \S60\misc\release\bldvariant\Series_60_3_1_elaf\group
# <\>
# <S60_3_2><S60_3_3>                specify directory for 'S60_3_2' and 'S60_3_3' build
# cd \S60\misc\release\bldvariant\elaf\group
# <\>
# call bldmake bldfiles -k          command that will lauch 1st state
# call abld export -k               command that will lauch 2nd state
# call abld export -w               command that will lauch 3rd state
# <\#>
# <\parallel>
#
# <parallel>                        2nd parallel block
# <#build_platforms>
# cd \s60\build_platforms\group
# call bldmake bldfiles -k          command that will lauch 4th state
# call abld export -k               command that will lauch 5th state
# <\#>
# <\parallel>
#

use strict;
use File::Find;     # for finding
use File::Basename; # for fileparse
use Getopt::Long;

#
# Variables...
#
my $version = "V1.0";
my $inputfile; # input filename
my $build; # S60_2X
my $outputfile; # input filename
my $component = "";
my ($cmdfile, $xmlfile, $product_name);
my $skip = 0;
my ($c, $i, $j);

if ( !GetOptions('i=s' => \$inputfile, 'b=s' => \$build, 'o=s' =>\$outputfile))
{
	&error_msg("Invalid arguments\n");
}

#
# Hello text
#
hello();

$build =~ tr/A-Z/a-z/; #Change all capitals to small    
  
open (INPUT,"$inputfile") or &error_msg("Cannot open $inputfile");
  open (XML_FILE,">$outputfile") or &error_msg("Cannot open $outputfile");
  pre_xml(\*XML_FILE);
  gen_xml_file(\*XML_FILE);
  post_xml(\*XML_FILE);
  close XML_FILE;
close INPUT;

sub gen_xml_file {
  my ($outputfile)=@_;
  my $parallel = 0;
  my $component_name = "";
  my $component_path = "\\";
  my @component_command;
  my %component_parallel;
  my $id = 1;
  my $stage = 1;
  
  while (<INPUT>) {
    next if (/^\/\//); # Skip comment lines
    next if (/^#/); # Skip comment lines
    next if (/^ *$/); # Skip empty lines 
  
  #  $_ =~ s/\//\\/g;    #Change / marks to \
    $_ =~ tr/A-Z/a-z/; #Change all capitals to small    
  
    chomp; #Remove line feed and carriage return  
 
# parallel block opened, components should build parallel 
    if (/^<parallel>/){
      $parallel = 1;
      next;
    }
# parallel block closed, write components that can build parallel to output file
    if (/^<\\parallel>/){
      my $loop = 1;
      my $line = 0;
      while ($loop) {
        my $found = 0;
        foreach $c (keys %component_parallel)
        {
          my @temp;
#            print "  $c : $i = $component_parallel{$c}[$i] : \n";
            @temp=keys %{$component_parallel{$c}[$line]};
            $j = "";
            $j = @temp[0];
            if ($j ne "") {
              print $outputfile "\t\t<Execute ID=\"$id\" Stage=\"$stage\" Component=\"$c\" Cwd=\"$j\" CommandLine=\"$component_parallel{$c}[$line]{$j}\"/>\n";
#              print "   \;command path = $j:command = $component_parallel{$c}[$line]{$j}\;\n";
              $found = 1;
              $id++;
            }
        }
        $line++;

        if (!$found) {
          $loop = 0;
        }
        else {
                  $stage++;

        }
      }

# clear variables
      %component_parallel =();
      $component_path = "\\";
      $parallel = 0;
      next;
    }
# component block end
    if (/^<\\#/){
    	if (!$skip) {
    	  $component_parallel{$component_name}=[@component_command];
  		}
  	  $skip = 0;
  	  @component_command = ();
  	  next;
  	}
# block end
    if (/^<\\>/) {
  	  $skip = 0;
  		next;
    }
    
    next if ($skip);
    if (!/^</) {
# get path for xml
      if (/^cd /){
      	$component_path = $_;
      	$component_path =~ s/^cd //;
    	  next;
    	}
    	my $rec = {};
# store command to @component_command variable
    	$rec->{$component_path} = $_;
      push (@component_command, $rec);
  		next;
    }
    
# get component name for xml
    if (/^<\#/){
    	$component_name = $_;
    	$component_name =~ s/^<\#//;
    	$component_name =~ s/>\Z//;
  	  next;
  	}
  	
# check build version, if not match skip next lines
    elsif (!/<$build>/){
    	$skip = 1;
    	next;
  	}
  }
}


sub hello
{
print "\nThis is gencmd.pl Version $version (C)Nokia Corporation 2002-2003\n"; 
}

sub error_msg ($){
  my($ErrorMsg);
  ($ErrorMsg)=@_;
  my $given_command=$0;
  $given_command =~ s/.*\\(\w+\.\w+)$/$1/;
  print "";
  print "\n";
  print "Error: $ErrorMsg \n\n";
  print "Usage: \n$given_command -b <build_name> -i <input file name> -o <output file>\n";
  print "Example:  \n$given_command bldmefirst.txt -b S60_3_1 -i data\bldmelast.txt -o \epoc32\tools\s60Build\bldmelast.xml\n";
  print "Example2: \n$given_command bldmefirst.txt -b S60_3_1_western -i data\variant_build.txt -o \epoc32\tools\s60Build\variant_build_western.xml\n";
  print "\n";  
  die "\n";    
}

# write pre information to output file
sub pre_xml {
  my ($outputfile)=@_;
  print $outputfile "<?xml version=\"1.0\"?>\n";
  print $outputfile "\t<!DOCTYPE Build  [\n";
  print $outputfile "\t<!ELEMENT Product (Commands)>\n";
  print $outputfile "\t<!ATTLIST Product name CDATA #REQUIRED>\n";
  print $outputfile "\t<!ELEMENT Commands (Execute+ | SetEnv*)>\n";
  print $outputfile "\t<!ELEMENT Execute EMPTY>\n";
  print $outputfile "\t<!ATTLIST Execute ID CDATA #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST Execute Stage CDATA #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST Execute Component CDATA #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST Execute Cwd CDATA #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST Execute CommandLine CDATA #REQUIRED>\n";
  print $outputfile "\t<!ELEMENT SetEnv EMPTY>\n";
  print $outputfile "\t<!ATTLIST SetEnv Order ID #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST SetEnv Name CDATA #REQUIRED>\n";
  print $outputfile "\t<!ATTLIST SetEnv Value CDATA #REQUIRED>\n";
  print $outputfile "]>\n\n";
  print $outputfile "<Product Name=\"$product_name\">\n";
  print $outputfile "\t<Commands>\n";
  print $outputfile "\t\t<!--Set Env-->\n";
  print $outputfile "\t\t<SetEnv Order=\"1\" Name=\"EPOCROOT\" Value=\"\\\"/>\n";
  print $outputfile "\t\t<SetEnv Order=\"2\" Name=\"PATH\" Value=\"\\epoc32\\gcc\\bin\;\\epoc32\\tools\;\%PATH\%\"/>\n\n";
}

# write post information to output file
sub post_xml {
  my ($outputfile)=@_;
  print $outputfile "\t</Commands>\n";
  print $outputfile "</Product>\n";
}


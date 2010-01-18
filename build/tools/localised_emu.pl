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
# Description: Script that takes an optional language ID as a parameter and updates features.dat and languages.txt
# in emulator environment.
#
# localised_emu.pl
#
# Script is RnD Emulator specific!
#
# Usage example: localised_emu.pl 
# Usage example: localised_emu.pl 31
# Usage example: localised_emu.pl 31 urel
# Usage example: localised_emu.pl 31 udeb
#

$HRHFILE = "\\epoc32\\include\\bldpublic.hrh";
$xml_china_filename = "\\epoc32\\include\\s60features_apac.xml";
$xml_japan_filename = "\\epoc32\\include\\s60features_japan.xml";
$xml_korean_filename = "\\epoc32\\include\\s60features_korean.xml";
@china_languages=(29,30,31,129,157,158,159,326,327);
@japan_languages=(32,160);
$korean_language=65;

$lang_id = $ARGV[0];
$ureludeb = lc $ARGV[1];

if ($lang_id eq "")
{
	$lang_id ="01";
  print "No language selected, default language used: $lang_id\n";
}

# Check that given id is digit
if (!($lang_id =~ /^\d+$/ ))
{
	$lang_id = "01";
	print "faulty lang id!\n";
	&printHelp;
	exit;
}

if ($ureludeb eq "")
{
	$ureludeb = "udeb";
	print "No urel/udeb selection made. Selecting UDEB.\n";
}

# Check that urel/udeb selection is valid
if (!(($ureludeb eq "urel") or ($ureludeb eq "udeb")))
{
	print "faulty urel/udeb selection!\n"; 
	&printHelp;
	exit;
}

$targetfile= "\\epoc32\\release\\winscw\\$ureludeb\\Z\\Resource\\bootdata\\languages.txt";

# check that given id is supported
open(HRHFILE) or die("Could not open bldpublic.hrh file.");
foreach $line (<HRHFILE>) {
    chomp($line);              # remove the newline from $line.
    if ($line =~ m/LANGUAGE_IDS/)
    {
    	if ($line =~ m/$lang_id/)
    	{
    		#print "Language ID found from bldpublic.hrh.\n";
    	} else
    	{
    	print "Not supported language ID selected.\n";
    	print "Supported language ID's:\n";
    	print "$line\n";
    	#$lang_id="01";
    	exit;
    	}
    	}
    	}
close(HRHFILE);

## generate feature.dat for emulator
if (grep {$_ eq $lang_id} @china_languages) {
  #print "China Language ID '$lang_id' selected.\n" ;
  system("perl -S \\epoc32\\tools\\features.pl \\epoc32\\rom\\include\\featuredatabase.xml $xml_china_filename -d=\\epoc32\\release\\winscw\\$ureludeb\\z\\private\\10205054\\");
	print "China version of features.dat generated.\n";
} elsif (grep {$_ eq $lang_id} @japan_languages) {
	#print "Japan Language ID '$lang_id' selected.\n" ;
	system("perl -S \\epoc32\\tools\\features.pl \\epoc32\\rom\\include\\featuredatabase.xml $xml_japan_filename -d=\\epoc32\\release\\winscw\\$ureludeb\\z\\private\\10205054\\");	
	print "Japan version of features.dat generated.\n";
} elsif ($lang_id == $korean_language) {
	#print "Korean Language ID '$lang_id' selected.\n" ;
	system("perl -S \\epoc32\\tools\\features.pl \\epoc32\\rom\\include\\featuredatabase.xml $xml_korean_filename -d=\\epoc32\\release\\winscw\\$ureludeb\\z\\private\\10205054\\");
	print "Korean version of features.dat generated.\n";
} else {
	#print "western Language ID '$lang_id' selected.\n" ;
	system("perl -S \\epoc32\\tools\\features.pl \\epoc32\\rom\\include\\featuredatabase.xml \\epoc32\\include\\s60features.xml -d=\\epoc32\\release\\winscw\\$ureludeb\\z\\private\\10205054\\");
	print "Western version of features.dat generated.\n";
}



# Put language ID to languages.txt
$version_string = sprintf("%s,d", $lang_id);

# Make sure that read only flag is off in the target file
chmod 0755, $targetfile;

# Write the version string in the unicode format
open OUT, ">$targetfile" or die "Can't open output file: $targetfile $!\n";
print OUT "\xFF\xFE";
for (my $i = 0; $i < length($version_string); $i++)
{
 printf OUT "%s\0", substr($version_string, $i, 1);
}
close OUT;

#start the actual emulator
if ((lc $ureludeb) eq "urel")
{
	system("epoc -rel");
	print "urel emulator started!\n";
} 
else
{
	system("epoc");
	print "udeb emulator started!\n";
} 



sub printHelp
{
	print "*****************************************\n";
	print "**Usage of the localised_emulator.pl:\n";
	print "**localised_emulator.pl <lang_ID> <urel/udeb>\n";
	print "**Default english udeb (01):localised_emulator.pl\n";
	print "**China language: localised_emulator.pl 31\n";
	print "*****************************************\n";
	print "China ID's: @china_languages\n";
	print "Japan ID's: @japan_languages\n";
	print "Korean ID: $korean_language\n";
}

exit;
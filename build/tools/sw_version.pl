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
#


use strict;
use Time::Local;
use File::Copy;
use Getopt::Long;


# Parameters

my $window_title;
my @custom_version;
my $S60_platform;
my $S60_version;
my $date;
my $string;
my $fwstring;
my $file;
my $bt;
my $fwid;

my $result = GetOptions(
		'w=s' => \$window_title, 
		'c=s' => \@custom_version, 
		'p=s' => \$S60_platform, 
		'pv=s' => \$S60_version,
		'pd=s' => \$date, 
		'bt' => \$bt,
		'fw=s' => \$fwid);	
if (!$result){&error_msg("Required Argument(s) are missing or wrong");}

	
#
# Main program
#
if ((!defined $S60_platform) && (!scalar @custom_version) && (!defined $window_title) && (!defined $bt)) {
	&error_msg("Required Argument(s) are missing");
}

if (defined $S60_platform) {
	initial_s60();
	sw_version(); 
}
elsif (scalar @custom_version){
	initial_custom();
	sw_version(); 
}

if (defined $window_title) {
	window_title ();
}

if (defined $bt) {
	bt_port_value();
}

if (defined $fwid) {
	fwid_version();
}


#
# S60 initialisation
#
sub initial_s60 (){
	my $version_short;

	if (defined $date) {
		unless ($date=~/now/i || $date=~/today/i || $date=~/\d\d-\d\d-\d\d/ ) {  &error_msg("Wrong date format. ");}
	}

# convert platform version string to short format
# like: S60_X_Y -> S60-XY
	my @temp_version = split('_',$S60_platform);

	foreach (@temp_version) {
		if ($version_short eq "") {
			$version_short = $_;
			$version_short .= "-";
		}
		else {
			$version_short .= $_;
		}
	}
	
	# create version string
	#V S60_31_200616\n20-04-06\nS60-31\n(c)NMP
	if (defined $date) {
		$string='V '.$S60_platform.'_'.$S60_version.'\n*DD*-*MM*-*YY*\n'.$version_short.'\n(c)NMP';
	}
	else {
		$string='V '.$S60_platform.'_'.$S60_version.'\nxx-xx-xx\nxxx-xxx\n(c)NMP';
	}

	$fwstring='V '.$S60_platform.'_'.$S60_version;
	
# set today to date
	if ($date=~/now/i || $date=~/today/i) {
		my ($time,$sek, $min, $hour, $day, $month, $year);
	  ($sek, $min, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
	  $month += 1;
	  $year += 1900;
	  
	  my $year_short=$year;
	  $year_short=~s/.*(\d\d)$/-$1/;
	  $date=$day.'-'.$month.$year_short
	}
	
	$string=~s/\*DD\*-\*MM\*-\*YY\*/$date/; 
}

#
# Custom initialisation
#
sub initial_custom (){
	foreach (@custom_version) {
		if ($string eq "") {
			$string=$_;
		}
		else {
			$string.='\n';
			$string.=$_;
		}
	}
}

#
# Write new version information for Version project
#
sub sw_version (){
	$file="\\sf\\os\\deviceplatformrelease\\version\\data\\sw.txt";
  open (to_file,">$file") || die " Cannot create $file Reason: $!\n";
  #
  # Writing the version string in the unicode format.
  #
  print to_file "\xFF\xFE";
  for (my $i = 0; $i < length($string); $i++) {
    printf to_file "%s\0", substr($string,$i, 1);
  }
  close (to_file);
}


#
# Write new fwid version information to fwid files
#
sub fwid_version (){
# $fwid (is path to fwid files) = \\s60_RnD\build_RnD\version_rnd\data\

	my $fwid_file=$fwid."fwid1.txt";
	write_unicode ($fwid_file, "id=core", "version=".$fwstring );

	my $fwid_file=$fwid."fwid2.txt";
	write_unicode ($fwid_file, "id=language", "version=".$fwstring." lang" );

	my $fwid_file=$fwid."fwid3.txt";
	write_unicode ($fwid_file, "id=customer", "version=".$fwstring." cust" );
}

#
# Writing the version string in the unicode format.
#

sub write_unicode (){
  my $unicode_file = shift;
  my @unicode_lines = @_;


  open (to_file,">$unicode_file") || die " Cannot create $unicode_file Reason: $!\n";
	binmode to_file;

  print to_file "\xFF\xFE";
	my $size = scalar(@unicode_lines);

	foreach my $l (@unicode_lines) {
	  for (my $i = 0; $i < length($l); $i++) {
     printf to_file "%s\0", substr($l,$i, 1);
 	  }

  	$size--;

		if ($size) {
	  	print to_file "\x0D\x00\x0A\x00";
	  }
	}	
  close (to_file);
}

#
# Change window title for s60config project
# Set new window title to epoc*.ini files 
#
sub window_title ($){
  my(@files);
  # read configuration files from epoc.ini
	my $epoc_ini_file="\\s60\\mw\\uiresources\\uiconfig\\s60config\\src\\epoc.ini";
  open(INI,$epoc_ini_file) or die "Cannot open $epoc_ini_file\n";
  while (<INI>) {
	  chomp; #Remove line feed and carriage return  
	  if (/^configuration /) {
      $_ =~ s/^configuration //;
      push @files, $_;
    }
	}
  close INI;

# change window title to each configuration file
	foreach my $input_file (@files) {
	  my @lines;
		$file="\\s60\\mw\\uiresources\\uiconfig\\s60config\\src\\$input_file";
	  open(IN,$file) or die "Cannot open $file";
	  @lines=<IN>;
	  close IN;
	
	  foreach (@lines){
	  	$string = $_;
	    if (/^\s*WindowTitle\s+\S+/i) {
	      $_ = "WindowTitle ".$window_title."\n";
	    }
		}
		
	  open (OUT,">$file") || die "Cannot open $file for overwriting!\n";
	  print OUT @lines;
	  close OUT;
	}
}

#
# Change correct port value to allow emulator booting
#
sub bt_port_value(){
  my @lines;  
  my $bt_string;
	$file="\\epoc32\\release\\WINSCW\\UDEB\\Z\\private\\101f7989\\Esock\\bt.bt.esk";
  open(IN,$file) or die "Cannot open $file";
  @lines=<IN>;
  close IN;

  foreach (@lines){
  	$bt_string = $_;
    if (/^\s*port=\s+\S+/i) {
      $_ = "port= -1\n";
    }
	}
	
  open (OUT,">$file") || die "Cannot open $file for overwriting!\n";
  print OUT @lines;
  close OUT;
}


sub error_msg ($){
  my($ErrorMsg);
  ($ErrorMsg)=@_;
  my $given_command=$0;
  $given_command =~ s/.*\\(\w+\.\w+)$/$1/;
  print "";
  print "\n";
  print "Error: $ErrorMsg \n";
  print "\n";  
  print "Usage: $given_command [options]\n\n";
  print "  Options for change version information\n";
  print "    -p S60_platform [optional with -c]\n";
  print "    -pv S60_version [optional, require -p]\n";
  print "    -pd date [optional, require -p]\n";
  print "    -c custom_version [optional with -p]\n\n";
  print "  Option for change emulator window title\n";
  print "    -w window_title [optional]\n\n";
  print "  Option for change bt port to -1 for emulator\n";
  print "    -bt [optional]\n";
  print "    -fwid [optional](To update fwid files for Fota in rnd)\n"; 
  print "\n\n";  
  print "DATE uses dd-mm-yy format or you can give now/today\n\n";  
  print "Example: $given_command -p S60_3_1 -pv 200616 -pd now\n";  
  print "Example: $given_command -w 92_200614 -p S60_3_1 -pv 200616 -pd now -bt\n";  
  print "Example: $given_command -w 92_200614 -p S60_3_1 -pv 200616 -pd 26-04-06\n";  
  print "Example: $given_command -c \"custom\" -c \"version\"\n";  
  print "Example: $given_command -fw \s60_RnD\build_RnD\version_rnd\data\"\n";  
  die "\n";    
}


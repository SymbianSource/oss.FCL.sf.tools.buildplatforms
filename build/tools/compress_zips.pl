#
# Copyright (c) 2006 Nokia Corporation and/or its subsidiary(-ies).
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
use File::Path;    
use File::Copy;    
use Getopt::Long;
use Cwd;

my ($back_up);
my (@zips, @temp_paths);
my (%zips_files, %zips_paths);

my $temp_dir = "\\compress_temp\\"; 
my $version = "1.0";

info();

if ( !GetOptions(
	'backup' => \$back_up,
	'z=s' => \@zips))
{
	&error_msg("Invalid arguments!\n");
}

if (! scalar (@zips)) {
	&error_msg("Invalid arguments!\n");
}

if (scalar (@zips) == 1) {
	&error_msg("More that one input file is needed!\n");
}

foreach (@zips) {
	if (! -e $_) {
		&error_msg("File not found : $_\n");
	}
}

foreach (@zips) {
	unzip_temp($_);
}

rezip();

rmtree($temp_dir);

sub unzip_temp {
	my $zip_file = shift;

	my($n, $d, $ext) = fileparse($zip_file, '\..*');
	
	mkpath ($temp_dir.$n);
	push @temp_paths, $n; 
	$zips_paths{$n}=$d;

	my $extrCmd = "7za.exe x -y ${zip_file} -o${temp_dir}${n}";
	print "$extrCmd";
	system ("$extrCmd");
	
	if ($back_up) { 
		 	print "rename ${zip_file} to ${d}${n}_orig${ext}\n";
		 	my $backup_name = ${d}.${n}."_orig".${ext};
		 	rename (${zip_file}, ${backup_name});
	}

		unlink (${zip_file});

	
	if (-e "${temp_dir}${n}\\checksum.md5") {
		unlink ("${temp_dir}${n}\\checksum.md5");
	}
	
	print "\\epoc32\\tools\\evalid.pl -g ${temp_dir}${n} ${temp_dir}${n}\\checksum.md5";	
	system ("\\epoc32\\tools\\evalid.pl -g ${temp_dir}${n} ${temp_dir}${n}\\checksum.md5");	
		
	open (MD5_FILE,"${temp_dir}${n}\\checksum.md5") or &error_msg("Cannot open ${temp_dir}${n}\\checksum.md5");
	
	while (<MD5_FILE>) {
 		chomp;
	  next if (/^\/\//); # Skip comment lines
	  next if (/^#/); # Skip comment lines
	  next if (/^ *$/); # Skip empty lines 
  	$_ =~ s/\//\\/g;    #Change / marks to \

		next if !/(TYPE=)/i;

		my $file_name = $_;
		$file_name =~ s/( TYPE=).*//i;

		$_ =~ s/.*MD5=//i;

	 	$file_name = lc $file_name;
	 	$file_name =~ s/\\/\//g;    #Change / marks to \
	
		my %temp;
		$temp{$_}=1;
		if (!exists $zips_files{$file_name}) {
			$zips_files{$file_name}={%temp};
		}
		else {
#				print "$zips_files{$file_name}{$_}\t $_ \n";
			if (exists $zips_files{$file_name}{$_}) {
				$zips_files{$file_name}->{$_}=$zips_files{$file_name}->{$_}+1;
			}
		}
	}
	
	close MD5_FILE;
}

sub rezip {
	my $given_files = scalar (@zips);
	my @zip_list;
	print "\nrezip $given_files \n";
	 
	 foreach my $key (keys %zips_files) {
		 foreach my $key2 (keys %{$zips_files{$key}}) {
	 		if ($zips_files{$key}{$key2} != $given_files) {
		  	$key =~ s/\//\\/g;    #Change / marks to \
	 			push @zip_list, $key."\n"; 
	 		}
		}
	}

  my $current_dir = cwd();
	foreach my $zip_name (keys %zips_paths) {
		my $name=$zips_paths{$zip_name}.$zip_name.".zip";
	  chdir(${temp_dir}.${zip_name});
		open (ZIP,"| zip -r $name -@");
		print ZIP @zip_list;
		close ZIP;
  	chdir($current_dir);
	}
}


sub info {
  print "compress_zips.pl   version $version \n";
  print "Remove files that are same in each given zipfile.\n";
  print "Uses evalid to compare files inside zips.\n";
}

sub error_msg ($){
  my($ErrorMsg);
  ($ErrorMsg)=@_;
  my $given_command=$0;
  $given_command =~ s/.*\\(\w+\.\w+)$/$1/;
  print "Error: $ErrorMsg \n";
	print "Usage: \n$given_command -z \\zips\\delta_western.zip -z \\zips\\delta_china.zip -z \\zips\\delta_japan.zip -backup\n";
	print "           -z <zipfile>  zipfiles that should compress, two or more are needed\n";
	print "           -backup       rename original zip files adding '_orig' end of the filename \n";
	print "Example: \n$given_command -z \\zips\\delta_western.zip -z \\zips\\delta_china.zip -z \\zips\\delta_japan.zip -backup\n";
	print "\n";  
	die "\n";  
}
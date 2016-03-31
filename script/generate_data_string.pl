#!/usr/bin/env perl -w

use strict;
use File::Slurp;

sub variableName {
    my $f = $_[0];
    $f =~ s|.*/||;
    $f =~ s/\./_/g;
    return $f;
}

sub escaped {
    my $string = $_[0];
    $string =~ s/\\/\\\\/g;
    $string =~ s/\0/\\0/g;
    $string =~ s/\t/\\t/g;
    $string =~ s/\n/\\n/g;
    $string =~ s/\r/\\r/g;
    $string =~ s/"/\\"/g;
    $string =~ s/'/\\'/g;
    return $string;
}

sub letStatement {
    my $file = $_[0];
    my $name = variableName($file);
    my $utf_text = read_file( $_[0], binmode => ':utf8', err_mode => 'carp' );
    unless ( $utf_text ) {
        return "// ERROR READING FILE\n";
    }
    my $contents = escaped($utf_text);
    return "let $name = \"$contents\";\n";
}

sub header {
    return <<EOF;
// Automatically generated file. Do not edit.

import Foundation

EOF
}

sub processFiles {
    my @files = @_;
    print(header());
    for my $file (@files) {
	print("// Generated from $file\n");
        print(letStatement($file));
	print("\n");
    }
}

sub xcode_main {
    my $filecount = $ENV{'SCRIPT_INPUT_FILE_COUNT'};
    unless ( defined($filecount) && $filecount > 0 ) {
        print STDERR "No input files provided.\n";
	return;
    }

    my @files = ();
    for (my $i = 0; $i < $filecount; $i++) {
	my $file = $ENV{"SCRIPT_INPUT_FILE_$i"};
	unless ( defined($file) ) {
            print STDERR "Expected environment variable 'SCRIPT_INPUT_FILE_$i'\n";
	    return;
	}
        push(@files, $file);
    }

    my $outputcount = $ENV{'SCRIPT_OUTPUT_FILE_COUNT'};
    my $outputfile = $ENV{'SCRIPT_OUTPUT_FILE_0'};
    unless ( defined($outputcount) && $outputcount == 1 && defined($outputfile) ) {
        print STDERR "Expected exactly 1 output file.\n";
	return;
    }

    unless ( open(OUT, '>', $outputfile) ) {
        print STDERR "Failed to open file for output: $outputfile\n";
	return;
    }
    select OUT;

    processFiles(@files);

    select STDOUT;
    close OUT;
}

sub argv_main {
    processFiles(@ARGV);
}

xcode_main();


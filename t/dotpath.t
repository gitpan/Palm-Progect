#!/usr/bin/perl

use strict;
use 5.005;
use Cwd;

my $Cwd;
BEGIN { $Cwd = getcwd(); chdir('t') if -d 't' }
END   { chdir($Cwd) }

use lib '../mlib';
use Test::More tests => 3;

require 'utility.pl';


my $perl        = $^X;
my $progconv    = '../bin/progconv';
my $infile_txt  = 'dot.test/infile.txt';
my $outfile_txt = 'dot.test/outfile.txt';

mkdir 'dot.test', 0777;

write_sample_txt($infile_txt);

unlink $outfile_txt;

ok(!-e $outfile_txt, "outfile clean");

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--tabstop=4',
    '--use-spaces',
    '--date-format=dd/mm/yyyy',
    $infile_txt, $outfile_txt
), 'executed progconv');

ok(compare_text_files($infile_txt, $outfile_txt), "converted file with dot in path");

#!/usr/bin/perl -w

use strict;
use 5.005;
use Cwd;

my $Cwd;
BEGIN { $Cwd = getcwd(); chdir('t') if -d 't' }
END   { chdir($Cwd) }

use lib '../mlib';

use Test::More tests => 3;

BEGIN { use_ok 'Palm::Progect' }
require 'utility.pl';

# Note that this is edge testing rather than unit testing.
# We are testing the functionality of the module as a whole.

# Here we load in a text file and check the following
# transformations:
#     * convert sample.txt to text.  Should be identical

my $perl                 = $^X;
my $progconv             = '../bin/progconv';
my $infile_txt           = 'infile.txt';
my $outfile_txt          = 'outfile.txt';

write_sample_txt($infile_txt);

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--csv-eol-pc',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    $infile_txt, $outfile_txt
), 'executed progconv');

ok(compare_text_files($infile_txt, $outfile_txt), 'text import/export');



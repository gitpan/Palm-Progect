#!/usr/bin/perl

use strict;
use 5.005;
use Cwd;

use lib 'mlib';

use Test::More tests => 4;

BEGIN { use_ok 'Palm::Progect' }
require 't/utility.pl';

# Note that this is edge testing rather than unit testing.
# We are testing the functionality of the module as a whole.

# Here we load in a text file and check the following
# transformations:
#     * convert sample.txt to pdb.
#     * convert pdb to text.  Should be identical to sample.txt

my $perl        = $^X;
my $progconv    = 'bin/progconv';
my $infile_txt  = 't/infile.txt';
my $infile_pdb  = 't/sample_18.pdb';
my $outfile_pdb = 't/outfile_23.pdb';
my $outfile_txt = 't/outfile.txt';

write_sample_txt($infile_txt);

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    # '--input-version=18',
    '--output-version=23',
    $infile_pdb, $outfile_pdb
), 'executed progconv');


ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    $outfile_pdb, $outfile_txt
), 'executed progconv');

ok(compare_text_files($infile_txt, $outfile_txt), 'pdb convert - v0.18 to v0.23');


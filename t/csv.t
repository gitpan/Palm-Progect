#!/usr/bin/perl

use strict;
use 5.005;
use Cwd;

my $Cwd;
BEGIN { $Cwd = getcwd(); chdir('t') if -d 't' }
END   { chdir($Cwd) }

use lib '../mlib';

BEGIN {
    eval {
        require Text::CSV_XS;
    };

    if ($@) {
        require Test::More;
        import Test::More qw(skip_all);
    }
    else {
        require Test::More;
        import Test::More tests => 5;
    }

}

BEGIN { use_ok 'Palm::Progect' }
require 'utility.pl';

# Note that this is edge testing rather than unit testing.
# We are testing the functionality of the module as a whole.

# Here we load in a text file and check the following
# transformations:
#     * convert sample.txt to csv.  Should be identical to sample.csv
#     * convert sample.csv to text.  Should be identical to sample.txt


my $perl        = $^X;
my $progconv    = '../bin/progconv';
my $infile_csv  = 'infile.csv';
my $infile_txt  = 'infile.txt';
my $outfile_csv = 'outfile.csv';
my $outfile_txt = 'outfile.txt';
my $outfile_pdb = 'outfile.pdb';

write_sample_txt($infile_txt);
write_sample_csv($infile_csv);

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--csv-eol-pc',
    '--date-format=dd/mm/yyyy',
    $infile_txt, $outfile_csv
), 'executed progconv');

ok(compare_csv_files($infile_csv, $outfile_csv, "\r\n"), 'csv export');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--csv-eol-pc',
    '--date-format=dd/mm/yyyy',
    $infile_csv, $outfile_txt
), 'executed progconv');

ok(compare_text_files($infile_txt, $outfile_txt), 'csv import');


# Palm::Progect.pm
#
# Perl class for dealing with Palm Progect databases.
#
# Author: Michael Graham
# Thanks to Andrew Arensburger's great Palm::* modules
# and sample code.

use strict;
use 5.005;

package Palm::Progect;

use Palm::Raw();
use Palm::StdAppInfo();
use Time::Local;

use vars qw( $VERSION @ISA );

$VERSION = '1.0.2';

@ISA = qw( Palm::Raw Palm::StdAppInfo );

my $Perl_Version = $];

my @Extra_Block_Chars_Head = (
    51, 0, 0, 4
);
my @Extra_Block_Chars_Tail = (
    0, 0, 64, 0,
);

=head1 NAME

Palm::Progect - Handler for Palm Progect databases.

=head1 SYNOPSIS

    use Palm::PDB;
    use Palm::Progect;

    my $pdb = new Palm::PDB;

    $pdb->Load('myprogect.pdb');

    # Read in the categories into a simple array
    my @categories = map { $_->{name} } @{$pdb->{'appinfo'}{'categories'}};

    # For any given record, the category will be a number
    # that indexes to the category array.
    my @records    = @{$pdb->{'records'};

    # ...
    # manipulate categories and records somehow
    # ...

    # Save a new pdb
    my $pdb = Palm::Progect->new();

    my $appinfo = {};
    Palm::StdAppInfo::seed_StdAppInfo($appinfo);
    my $start_category_id = $appinfo->{lastUniqueID};

    # Insert the "root record" if necessary
    unless ($records[0]{'level'} == 0) {
        unshift @records, $pdb->new_Root_Record();
    }

    # Write the categories, in order,
    # giving them sensible PDB numbers

    my $i;
    for ($i = 0; $i < @categories; $i++) {
        $appinfo->{'categories'}[$i] = {
            name    => $categories[$i],
            id      => $i ? $start_category_id + $i : 0,
            renamed => 0,
        };
    }

    $appinfo->{lastUniqueID} = $start_category_id + $i;

    # Rebuild the parent/child relationships
    @records = Palm::Progect->Repair_Tree(\@records);

    $pdb->{'name'}    = 'my new progect';
    $pdb->{'records'} = \@records;
    $pdb->{'appinfo'} = $appinfo;

    $pdb->Write('mynewprogect.pdb');

=head1 DESCRIPTION

The Progect PDB handler is a helper class for the Palm::PDB package. It
allows you to load and save Progect databases.

Generally, you load a Progect PDB file into memory, manipulate
its records, and then save a new PDB file to disk.

Modifying a Progect database "in place" is not well supported or tested.

This module was largely written in support of the B<progconv> utility,
which is a conversion utility which imports and exports between
Progect PDB files and other formats.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

=head2 Records

The records of the Progect DB.  A record is a I<node> in
the Progect tree.  It has a description, type
and date information, and can have a note.

Unlike nodes in a real tree, records in the Progect
don't maintain parent/child relationships with other
records.  Instead, records have a I<level>, which
is an indication of how many steps they are indented.

A record's child will have a higher level than
it's parent:


    first record                                  (level 1)
        child of first record                     (level 2)
        second child of first record              (level 2)
            grandchild of first record            (level 3)
    another record                                (level 1)

With the Palm::Progect module you can access the list
of records via:

    $record = $pdb->{records}[N]

Each record in the list is a hashref, containing
keys for the various fields that a Progect record can have:

=over 4

=item $record->{description}

A string, the text of the progect node.

=item $record->{level}

The indent level of the record.  See above under L<Records>.

=item $record->{note}

A string, the note (if any) attached to the progect node.

=item $record->{hasNote}

True if the record has a note, false otherwise

=item $record->{priority}

The priority of the record from 1 to 5, or 0 for no priority.

=item isAction

=item isProgress

=item isNumeric

=item isInfo

Any record can have one (and only one) of the above types.

If you are going to change the type of a record, remember
to set all the other types to false:

    undef $record->{isAction};
    undef $record->{isProgress};
    undef $record->{isNumeric};
    $record->{isInfo} = 1;

=item numericActual

The numerator of a numeric record.  If the numeric value of
a record is C<4/5>, then the C<numericActual> value is C<4>.

=item numericLimit

The denominator of a numeric record.  If the numeric value of
a record is C<4/5>, then the C<numericLimit> value is C<5>.

=item $record->{completed}

Completed has different values depending upon the type of record.
For action items, it is either 1 or 0, for complete or not complete.

For Progress items, it is a number between 1 and 100, indicating a
percentage.

For Numeric items it is a number between 1 and 100 indicating the
the integer percentage of the C<numericActual> value divided by
the C<numericLimit> value.

=item $record->{DateDue}

The due date of record, in standard unix time (i.e. number
of seconds since Jan 1, 1969).

To read this time value, use the localtime
function:

    my ($year, $month, $day);
    if ($record->{hasDueDate}) {
        my ($day, $month, $year) = (localtime $record->{dateDue})[3,4,5];
        $year += 1900;
        $month += 1;

        print "The date of this record is $year/$month/$day\n";
    }

To convert to this value when you are prepared to save the record,
use the Time::Local module:

    use Time::Local;
    eval {
        $record{dateDue}      = timelocal(0,0,0,$day,$month-1,$year)
        $record{hasDueDate}   = 1;
    };

=item $record->{hasDueDate}

True if the record has a due date, false otherwise.

=item $record->{hasToDo}

True if the record has a ToDo link, false otherwise.

=item $record->{opened}

=item $record->{hasNext}

=item $record->{hasPrev}

=item $record->{hasChild}

These properties are used by Progect to remember what
the parent/child relationship between records is.

You shouldn't mess with these directly.  Rather, call
the L<Repair_Tree> function before you save your PDB file.

=back

=cut

sub import {
    Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
        [ "lbPG", "DATA" ],
    );
}

=head1 CLASS METHODS

=head2 new

  $pdb = new Palm::Progect;

Create a new PDB, initialized with the various Palm::Progect fields
and an empty record list.

Use this method if you're creating a Progect PDB from scratch.

=cut

sub new {
    my $classname   = shift;
    my $self        = $classname->SUPER::new(@_);

    $self->{name}                 = "ProgectDB";       # Default
    $self->{creator}              = "lbPG";
    $self->{type}                 = "DATA";
    $self->{attributes}{resource} = 0;

    # Initialize the AppInfo block
    $self->{appinfo} = {
        sortOrder       => undef,       # XXX - ?
    };

    # Add the standard AppInfo block stuff
    &Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

    # Give the PDB a blank sort block
    $self->{sort} = undef;

    # Give the PDB an empty list of records
    $self->{records} = [];

    return $self;
}

=head2 Repair_Tree

This utility routine takes a list of categories, and based upon their
order and their level, determines their ancestral relationships,
filling in the following properties as appropriate for each record:

    hasNext
    hasPrev
    hasChild

Arguments: A List of records or a reference to one.

Returns: The list of records with relationships intact
or a reference, if called in a scalar context.

Example:

    my @records     = Palm::Progect->Rebuild_Relationships(@records);
    my $records_ref = Palm::Progect->Rebuild_Relationships(\@records);

=cut

sub Repair_Tree {
    my $self = shift;

    my $records = ref $_[0] eq 'ARRAY'? $_[0] : [ @_ ];

    # Insert the "root record" if necessary
    if ($records->[0]->{level}) {
        my $root_record = $self->new_Record();

        $root_record->{hasChild} = 1;
        $root_record->{level}    = 0;
        $root_record->{opened}   = 1;

        unshift @$records, $root_record;
    }

    # Fix relations between records

    my $num_records = @$records;

    for (my $i = 0; $i < $num_records; $i++) {
        my $rec      = $records->[$i];

        $rec->{hasChild} = 0;
        $rec->{hasNext}  = 0;
        $rec->{hasPrev}  = 0;

        if ($i == 0 and $num_records > 0) {
            $rec->{hasPrev}  = 0;

            my $next_rec = $records->[$i+1];
            $rec->{hasChild} = 1 if $next_rec->{level} > $rec->{level};

            # Look ahead to other records, see if we
            # can find one at the same level as us,
            # before we cross one at a previous level
            for (my $j = $i + 1; $j < $num_records; $j++) {

                my $other_record = $records->[$j];

                last if $other_record->{level} < $rec->{level};

                if ($other_record->{level} == $rec->{level}) {
                    $rec->{hasNext} = 1;
                    last;
                }
            }
        }
        else {
            my $prev_rec = $records->[$i-1];
            if ($num_records > $i) {
                my $next_rec = $records->[$i+1];
                $rec->{hasChild} = 1 if ($next_rec->{level} || 0) > ($rec->{level} || 0);
            }
            # Look ahead to other records, see if we
            # can find one at the same level as us,
            # before we cross one at a previous level
            if ($i < $num_records) {
                for (my $j = $i + 1; $j < $num_records; $j++) {

                    my $other_record = $records->[$j];

                    last if $other_record->{level} < $rec->{level};

                    if ($other_record->{level} == $rec->{level}) {
                        $rec->{hasNext} = 1;
                        last;
                    }
                }
            }
            # Same thing, working backwards
            for (my $j = $i - 1; $j > 0; $j--) {

                my $other_record = $records->[$j];

                last if $other_record->{level} < $rec->{level};

                if ($other_record->{level} == $rec->{level}) {
                    $rec->{hasPrev} = 1;
                    last;
                }
            }
        }
    }

    return @$records if wantarray;
    return $records;
}

=head1 OBJECT METHODS

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new Progect record, with blank values for all of the fields.
Returns the record.

=cut

sub new_Record {
    my $self = shift;
    my $record = $self->SUPER::new_Record(@_);

    $record->{level}      = 1;
    $record->{hasChild}   = 0;
    $record->{isProgress} = 1;
    $record->{opened}     = 1;
    $record->{data} = "";

    return $record;
}

=head2 new_Root_Record

  $record = $pdb->new_Root_Record;

Creates and returns a new Root Progect record.

This is the invisible, unnamed record at level 0 at the head of the
record list which 'contains' all other records.  You never see
this record in Progect, but it's necessary.

For Example:

    unless ($records[0]{level} == 0) {
        unshift @records, $pdb->new_Root_Record;
    }

=cut

sub new_Root_Record {
    my $self = shift;

    my $root_record = $self->new_Record();

    $root_record->{hasChild} = 1;
    $root_record->{level}    = 0;
    $root_record->{opened}   = 1;

    return $root_record;
}

sub ParseAppInfoBlock {
    my $self    = shift;
    my $data    = shift;
    my $appinfo = {};

    Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

    return $appinfo;
}

sub PackAppInfoBlock {
    my $self = shift;
    return Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});
}

=head2 ParseRecord

This is the method that reads the raw binary data of the Progect
record and parses it into fields of the C<%record> hash.

You should not need to call this method manually - it is
called automatically for every record when you load a Progect
database.

    my $parsed_record = $pdb->ParseRecord(%raw_record);

=cut

my $Unpack_Template;
my @Record_Keys;
sub ParseRecord {
    my $self = shift;
    my %record = @_;

    my (
        $flag_group1,
        $flag_group2,
        $flag_group3,
        $unused,
        $date_b1,
        $date_b2,
    );
    (
        $record{level},        # ok
        $flag_group1,
        $flag_group2,
        $flag_group3,
        $record{priority},     # ok
        $record{completed},    # ok
        $date_b1,
        $date_b2,

    ) = unpack 'CCCCCCCC', $record{data};

    # Perl won't unpack more than one ASCIIZ string at a time,
    # so we have to unpack them one at a time, skipping the
    # proper number of bytes each time:

    my $offset = 8;  #   8 bytes of flags

    $record{description} = unpack "x${offset}Z*", $record{data};

    $offset += length($record{description}) + 1;

    $record{note} = unpack "x${offset}Z*", $record{data};

    if ($record{note}) {
        $offset += length($record{note});
    }

    # The completed field is quite complicated and context specific:
    #   < 10 == PERCENTAGE
    #     16 == INFORMATIVE
    #     11 == ACTION
    #     12 == ACTION_OK
    #     13 == ACTION_NO
    #   > 20 == NUMERIC

    $record{isAction}   = ($record{completed} >= 11 and $record{completed} <= 13);
    $record{isProgress} = ($record{completed} <= 10);
    $record{isNumeric}  = ($record{completed} >= 20);
    $record{isInfo}     = ($record{completed} == 16);

    if ($record{isAction}) {
        $record{completed} = ($record{completed} == 12 ? 1 : undef);
    }
    elsif ($record{isProgress}) {
        $record{completed} = $record{completed} * 10;
    }
    elsif ($record{isInfo}) {
        undef $record{completed};
    }
    elsif ($record{isNumeric}) {
        my @extra = unpack "x${offset}C*", $record{data};

        $record{numericLimit}  = $extra[5] * 2**8 + $extra[6];
        $record{numericActual} = $extra[7] * 2**8 + $extra[8];
    }

    $record{hasNext}      = ($flag_group1 & 2**7) > 0; # ok
    $record{hasChild}     = ($flag_group1 & 2**6) > 0; # ok
    $record{opened}       = ($flag_group1 & 2**5) > 0; # ok
    $record{hasPrev}      = ($flag_group1 & 2**4) > 0; # ok

    # $record{hasStartDate} = ($flag_group2 & 2**7) > 0; # ??? not implemented
    # $record{hasPred}      = ($flag_group2 & 2**6) > 0; # ??? not implemented
    # $record{hasDuration}  = ($flag_group2 & 2**5) > 0; # ??? not implemented

    $record{hasDueDate}   = ($flag_group2 & 2**4) > 0; # always set?
    $record{hasToDo}      = ($flag_group2 & 2**3) > 0; # ok

    $record{hasNote}      = ($flag_group2 & 2**2) > 0; # ok

    # $record{hasLink}      = ($flag_group2 & 2**1) > 0; # ??? not implemented

    # $record{newTask}      = ($flag_group3 & 2**2)> 0; # not necessary
    # $record{newFormat}    = ($flag_group3 & 2**1)> 0; # not necessary
    # $record{nextFormat}   = ($flag_group3 & 2**0)> 0; # not implemented (not even by Progect?)

    # $record{extendedType} = (($flag_group2 & 2**0)      # not implemented.
    #                       +  ($flag_group3 & 2**7)      # and this list is probably wrong.
    #                       +  ($flag_group3 & 2**6)
    #                       +  ($flag_group3 & 2**5)
    #                       +  ($flag_group3 & 2**4));


    # For some reason, pri = 6 means "no priority"
    # probably because the "none" button is the 6th button
    # on the palm's screen.
    undef $record{priority} if $record{priority} == 6;

    # Date due field:
    # This field seems to be layed out like this:
    #     year  7 bits (0-128)
    #     month 4 bits (0-16)
    #     day   5 bits (0-32)

    my $day   = $date_b2 & (2**0 | 2**1 | 2**2 | 2**3 | 2**4);
    my $month = $date_b2 & (2**5 | 2**6 | 2**7);
    $month   /= (2**5);
    $month   += ($date_b1 & 1) * (2**3);

    my $year = int($date_b1 / 2); # shifts off LSB

    $year    += 1904 if $year;

    $record{hasDueDate} = 0 if ! ($day && $month && $year);

    # $record{dateDueYear}  = $year;
    # $record{dateDueMonth} = $month;
    # $record{dateDueDay}   = $day;
    eval {
        $record{dateDue}      = timelocal(0,0,0,$day,$month-1,$year) if $record{hasDueDate};
    };
    my $local = localtime(($record{dateDue} || 0));

    delete $record{offset};   # Don't need this
    delete $record{data};     # The raw data is no longer necessary
                              # now that we've parsed it.

    return \%record;
}

=head2 PackRecord

This is the method that packs C<%records> hash into
the raw binary data of the Progect record.

You should not need to call this method manually - it is
called automatically for every record when you save a Progect
database.

    my $raw_record = $pdb->ParseRecord(\%record);

=cut

sub PackRecord {
    my $self = shift;
    my $record = shift;

    my $data = '';

    my $extra_block = '';

    if ($record->{isAction}) {
        $record->{completed} = $record->{completed}? 12 : 13;
    }
    elsif ($record->{isProgress}) {
        $record->{completed} = int(($record->{completed}||0) / 10);
    }
    elsif ($record->{isInfo}) {
        $record->{completed} = 16;
    }
    elsif ($record->{isNumeric}) {
        if ($record->{numericActual}) {
            $record->{completed} = int($record->{numericLimit} / $record->{numericActual} / 10);
        }
        $record->{completed} += 20;
        $extra_block .= pack 'C*', @Extra_Block_Chars_Head;
        $extra_block .= pack 'n',  $record->{numericLimit};
        $extra_block .= pack 'n',  $record->{numericActual};
        $extra_block .= pack 'C*', @Extra_Block_Chars_Tail;
    }

    my $flag_group_1 = (
        ($record->{hasNext}  ? 2**7 : 0) |
        ($record->{hasChild} ? 2**6 : 0) |
        ($record->{opened}   ? 2**5 : 0) |
        ($record->{hasPrev}  ? 2**4 : 0)
    );

    $record->{'hasNote'} = 1 if $record->{'note'};

    my ($date_b1, $date_b2);

    if ($record->{dateDue}) {
        my ($day, $month, $year) = (localtime $record->{dateDue})[3,4,5];

        if ($day && $month && $year) {
            my $origdate = ($year + 1900).'/'.($month+1)."/$day";
            $year = $year + 1900 - 1904;
            $month = $month + 1;
            $date_b1 = $year * 2;
            $date_b1 = $date_b1 | (($month & 2**3) ? 1 : 0);

            my $month_lowbits = $month & (2**2 | 2**1 | 2**0);

            $date_b2 = ($month_lowbits * 2**5) | $day;

            $record->{hasDueDate} = 1;

        }
    }
    else {
        $record->{hasDueDate} = 0;
        $date_b1 = 0;
        $date_b2 = 0;
    }

    my $flag_group_2 = (
        ($record->{hasDueDate}   ? 2**4 : 0) |
        ($record->{hasToDo}      ? 2**3 : 0) |
        ($record->{hasNote}      ? 2**2 : 0)
    );

    # No priority is represented as priority=6
    $record->{priority} ||= 6;

    $data .= pack 'CCCxCCCC', (
        ($record->{level}     || 0),
        ($flag_group_1        || 0),
        ($flag_group_2        || 0),
        ($record->{priority}  || 0),
        ($record->{completed} || 0),
        ($date_b1             || 0),
        ($date_b2             || 0),
    );

    $data .= pack 'Z*', $record->{'description'};

    # Strangely, the unpack function seems
    # to have changed from 5.005 to 5.6.x
    # We need to manually add the null
    # at the end of packed strings for
    # version 5.005

    $data .= "\0" if $Perl_Version < 5.006;

    if ($record->{'hasNote'}) {
        $data .= pack 'Z*', $record->{'note'};
        $data .= "\0" if $Perl_Version < 5.006;
    }

    if (!$record->{'hasNote'}) {
        $data .= "\0";
    }

    if ($extra_block) {
        $data .= $extra_block;
    }

    return $data;

}

1;

__END__

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2001 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

progconv

Palm::PDB(3)

Palm::StdAppInfo(3)

http:://progect.sourceforge.net/

=cut


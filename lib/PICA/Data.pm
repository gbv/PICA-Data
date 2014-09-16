package PICA::Data;
# ABSTRACT: PICA record processing
# VERSION

use strict;
use Exporter 'import';
our @EXPORT_OK = qw(parse_pica_path pica_values pica_values pica_fields);
our %EXPORT_TAGS = (all => [@EXPORT_OK]); 

use Scalar::Util qw(reftype);

sub parse_pica_path {
    return if $_[0] !~ /([0-9*.]{3}\S)(\[([0-9*.]{2})\])?(\$?([_A-Za-z0-9]+))?(\/(\d+)(-(\d+))?)?/;
    my @path = (
        $1, # field
        $3, # occurrence
        defined $5 ? "[$5]" : "[_A-Za-z0-9]", # subfield_regex
    );

    push(@path, $7, $9) if defined $6; # from, to

    $path[0] =~ s/\*/./g;                     # field => field_regex
    $path[1] =~ s/\*/./g if defined $path[1]; # occurrence => occurrence_regex

    return \@path;
}

sub pica_values {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = parse_pica_path($path) unless ref $path;
    return unless $path;

    my $field_regex      = qr{$path->[0]};
    my $occurrence_regex = defined $path->[1] ? qr{$path->[1]} : undef;
    my $subfield_regex   = qr{$path->[2]};
    my $from             = $path->[3];
    my $len              = defined $path->[4] ? $path->[4] - $from + 1 : 1;
    $from = undef if $len < 1;

    my @values;

    foreach my $field (@$record) {
        next if $field->[0] !~ $field_regex;

        if ($occurrence_regex) {
            if (!defined $field->[1] || $field->[1] !~ $occurrence_regex) {
                next
            }
        }

        for (my $i = 2; $i < @$field; $i += 2) {
            if ($field->[$i] =~ $subfield_regex) {
                my $value = $field->[$i + 1];
                if (defined $from) {
                    $value = substr($value, $from, $len);
                    next if '' eq ($value // '');
                }
                push @values, $value;
            }
        }
    }

    return @values;
}

sub pica_fields {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = parse_pica_path($path) unless ref $path;
    return [] unless $path;

    my $fields = [];
    my $field_regex      = qr{$path->[0]};
    my $occurrence_regex = defined $path->[1] ? qr{$path->[1]} : undef;

    foreach my $field (@$record) {
        next if $field->[0] !~ $field_regex;

        if ($occurrence_regex) {
            if (!defined $field->[1] || $field->[1] !~ $occurrence_regex) {
                next
            }
        }
        push @$fields, [ @$field ];
    }

    return $fields;
}

sub pica_value {
    my ($record, $path) = @_;
    # TODO: more efficient implementation 
    my @values = pica_values($record, $path);
    return $values[0];
}

*values = *pica_values;
*value  = *pica_value;
*fields = *pica_fields;

=head1 DESCRIPTION

This module is aggregated methods and functions to process parsed PICA records,
represented by an array of arrays.

=head1 FUNCTIONS

=head2 pica_values( $record, $path )

Adopted from L<Catmandu::Fix::pica_map>, function can be used to extract a list
of subfield values from a PICA record based on a PICA path expression.

This function can also be called as C<values> on a blessed PICA::Data record:

    bless $record, 'PICA::Data';
    $record->values($path);

=head2 pica_value( $record, $path )

Same as C<pica_values> but only returns the first value. Can also be called as
C<value> on a blessed PICA::Data record.

=head2 pica_fields( $record, $path )

Returns a PICA record limited to fields specified in a PICA path expression.
Always returns an array reference. Can also be called as C<fields> on a blessed
PICA::Data record. 

=head2 parse_pica_path( $path )

Parses a PICA path expression. On success returns a list reference with:

=over

=item

regex string to match fields against (must be compiled with C<qr{...}> or C</.../>)

=item

regex string to match occurrences against (must be compiled)

=item

regex string to match subfields against (must be compiled)

=item

substring start position

=item

substring end position

=back


=head1 SEEALSO

L<PICA::Record> implements an alternative, more heavyweight encoding of PICA
records.

=cut

1;

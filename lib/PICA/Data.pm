package PICA::Data;
# ABSTRACT: PICA record processing
# VERSION

use strict;
use Exporter 'import';
our @EXPORT_OK = qw(pica_values pica_values pica_fields);
our %EXPORT_TAGS = (all => [@EXPORT_OK]); 

use Scalar::Util qw(reftype);
use List::Util qw(first);
use IO::Handle;
use PICA::Path;

sub pica_values {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return unless ref $path;

    my @values;

    foreach my $field (grep { $path->match_field($_) } @$record) {
        push @values, $path->match_subfields($field);
    }

    return @values;
}

sub pica_fields {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return [] unless defined $path;

    return [ grep { $path->match_field($_) } @$record ];
}

sub pica_value {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return unless defined $path;

    foreach my $field (@$record) {
        next unless $path->match_field($field);
        my @values = $path->match_subfields($field);
        return $values[0] if @values;
    }

    return;
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

=head1 SEEALSO

L<PICA::Record> implements an alternative, more heavyweight encoding of PICA
records.

=cut

1;

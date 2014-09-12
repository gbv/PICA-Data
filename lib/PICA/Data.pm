package PICA::Data;
# ABSTRACT: PICA record processing
# VERSION

use strict;
use Exporter 'import';
our @EXPORT_OK = qw(parse_pica_path pica_values);
our %EXPORT_TAGS = (all => [@EXPORT_OK]); 

sub parse_pica_path {
    return if $_[0] !~ /(\d{3}\S)(\[([0-9*]{2})\])?(\$?([_A-Za-z0-9]+))?(\/(\d+)(-(\d+))?)?/;
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

=head1 DESCRIPTION

This module is aggregated methods and functions to process parsed PICA records,
represented by an array of arrays.

=head1 FUNCTIONS

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

=head1 SEEALSO

L<PICA::Record> implements an alternative, more heavyweight encoding of PICA
records.

=cut

1;

package PICA::Writer::Plus;
# ABSTRACT: Normalized PICA+ format serializer
# VERSION

use strict;
use charnames qw(:full);
use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\x1D\x1A"; # TODO: check

use Moo;
with 'PICA::Writer::Handle';

sub _write_record {
    my ($self, $record) = @_;
    my $fh = $self->fh;

    foreach my $field (@$record) {
        print $fh $field->[0];
        if (defined $field->[1] and $field->[1] ne '') {
            print $fh "/".$field->[1];
        }
        print $fh ' ';
        for (my $i=4; $i<scalar @$field; $i+=2) {
            print $fh SUBFIELD_INDICATOR . $field->[$i] . $field->[$i+1];
        }
        print $fh END_OF_FIELD;
    }
    print $fh END_OF_RECORD;
}

=head1 DESCRIPTION

    use PICA::Writer::Plus;

    my $fh = \*STDOUT; # filehandle or object with method print, e.g. IO::Handle
    my $writer = PICA::Writer::Plus->new( fh => $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }

=method write ( @records )

Writes one or more records, given as hash with key 'C<record>' or as array
reference with a list of fields, as described in L<Catmandu::PICA>.

=head1 SEEALSO

The counterpart of this module is L<PICA::Parser::Plus>. An alternative writer,
not aligned with the L<Catmandu> framework, has been implemented as
L<PICA::Writer> included in the release of L<PICA::Record>.

=cut

1;

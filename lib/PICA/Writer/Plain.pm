package PICA::Writer::Plain;
# ABSTRACT: Plain PICA+ format serializer
# VERSION

use strict;
use charnames qw(:full);
use constant SUBFIELD_INDICATOR => '$';
use constant END_OF_FIELD       => "\n";
use constant END_OF_RECORD      => "\n";

use Moo;
with 'PICA::Writer::Handle';

sub _write_record {
    my ($self, $record) = @_;
    my $fh = $self->fh;

    foreach my $field (@$record) {
        print $fh $field->[0];
        if (defined $field->[1] and $field->[1] ne '') {
            print $fh "/".$field->[1]; # TODO: fix one-digit occ??
        }
        print $fh ' ';
        for (my $i=2; $i<scalar @$field; $i+=2) {
            my $value = $field->[$i+1];
            $value =~ s/\$/\$\$/g;
            print $fh SUBFIELD_INDICATOR . $field->[$i] . $value;
        }
        print $fh END_OF_FIELD;
    }
    print $fh END_OF_RECORD;
}

=head1 DESCRIPTION

    use PICA::Writer::Plain;

    my $fh = \*STDOUT; # filehandle or object with method print, e.g. IO::Handle
    my $writer = PICA::Writer::Plain->new( fh => $fh );

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

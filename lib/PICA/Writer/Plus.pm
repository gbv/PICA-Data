package PICA::Writer::Plus;
use strict;

our $VERSION = '0.20';

use charnames qw(:full);
use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{LINE FEED}"; # or \N{INFORMATION SEPARATOR THREE}? I would prefer newline separated format

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
        for (my $i=2; $i<scalar @$field; $i+=2) {
            print $fh SUBFIELD_INDICATOR . $field->[$i] . $field->[$i+1];
        }
        print $fh END_OF_FIELD;
    }
    print $fh END_OF_RECORD;
}

1;
__END__

=head1 NAME

PICA::Writer::Plus - Normalized PICA+ format serializer

=head1 SYNOPSIS

    use PICA::Writer::Plus;

    my $fh = \*STDOUT; # filehandle or object with method print, e.g. IO::Handle
    my $writer = PICA::Writer::Plus->new( fh => $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }

=head2 MODULES

=head2 write ( @records )

Writes one or more records, given as hash with key 'C<record>' or as array
reference with a list of fields, as described in L<PICA::Data>.

=head1 SEEALSO

The counterpart of this module is L<PICA::Parser::Plus>.

See L<Catmandu::Exporter::PICA> for usage of this module in L<Catmandu>.

An alternative writer had been implemented as L<PICA::Writer> included in the
release of L<PICA::Record>.

=cut

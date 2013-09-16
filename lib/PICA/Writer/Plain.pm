package PICA::Writer::Plain;
# ABSTRACT: Plain PICA+ format serializer
# VERSION

use strict;
use Moo;
use Scalar::Util qw(blessed openhandle);
use Carp qw(croak);

has fh => (
    is => 'rw', 
    isa => sub {
        local $Carp::CarpLevel = $Carp::CarpLevel+1;
        croak 'expect filehandle or object with method print!'
            unless defined $_[0] and openhandle($_[0])
            or (blessed $_[0] && $_[0]->can('print'));
    },
    default => sub { \*STDOUT }
);

sub write {
    my $self = shift;
    my $fh   = $self->fh;

    foreach my $record (@_) {
        $record = $record->{record} if ref $record eq 'HASH';
        foreach my $field (@$record) {
            print $fh $field->[0];
            if (defined $field->[1] and $field->[1] ne '') {
                print $fh "/".$field->[1]; # TODO: fix one-digit occ??
            }
            print $fh ' ';
            # ignore $field->[2,3] ...
            for (my $i=4; $i<scalar @$field; $i+=2) {
                my $value = $field->[$i+1];
                $value =~ s/\$/\$\$/g;
                print $fh '$'.$field->[$i].$value;
            }
            print $fh "\n"; # use "\x1D\x0A" for normalized
        }
        print $fh "\n"; # use "\x1D\x1A" for normalized"
    }
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

package PICA::Writer::Base;
use strict;
use warnings;

our $VERSION = '0.23';

use Scalar::Util qw(blessed openhandle reftype);
use Carp qw(croak);

sub new {
    my $class = shift;
    my (%options) = @_ % 2 ? (fh => @_) : @_;

    my $self = bless \%options, $class;

    my $fh = $self->{fh} // \*STDOUT;
    if (!ref $fh) {
        if ( open(my $handle, '>:encoding(UTF-8)', $fh) ) {
            $fh = $handle; 
        } else {
            croak "cannot open file for writing: $fh\n";
        }
    } elsif (!openhandle($fh) and !(blessed $fh && $fh->can('print'))) {
        croak 'expect filehandle or object with method print!'
    }    
    $self->{fh} = $fh;

    $self;
}

sub write {
    my $self = shift;

    foreach my $record (@_) {
        $record = $record->{record} if reftype $record eq 'HASH';
        $self->_write_record($record);
    }
}

1;
__END__

=head1 NAME

PICA::Writer::Base - Base class of PICA+ writers

=head1 SYNOPSIS

    use PICA::Writer::Plain;
    my $writer = PICA::Writer::Plain->new( $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }

    use PICA::Writer::Plus;
    $writer = PICA::Writer::Plus->new( $fh );
    ...

    use PICA::Writer::XML;
    $writer = PICA::Writer::XML->new( $fh );
    ...

=head1 DESCRIPTION

This abstract base class of PICA+ writers should not be instantiated directly.
Use one of the following subclasses instead:

=over 

=item L<PICA::Writer::Plain>

=item L<PICA::Writer::Plus>

=item L<PICA::Writer::XML>

=back

=head1 METHODS

=head2 new( [ $fh | fh => $fh ] )

Create a new PICA writer, writing to STDOUT by default. The optional C<fh>
argument can be a filename, a handle or any other blessed object with a
C<print> method, e.g. L<IO::Handle>.

L<PICA::Data> also provides a functional constructor C<pica_writer>.

=head2 write ( @records )

Writes one or more records, given as hash with key 'C<record>' or as array
reference with a list of fields, as described in L<PICA::Data>.

=head1 SEEALSO

See L<Catmandu::Exporter::PICA> for usage of this module within the L<Catmandu>
framework (recommended). 

Alternative (outdated) PICA+ writers had been implemented as L<PICA::Writer>
and L<PICA::XMLWriter> included in the release of L<PICA::Record>.

=cut

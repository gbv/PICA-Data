package Catmandu::Exporter::PICA;
#ABSTRACT: Package that exports PICA data
#VERSION

use namespace::clean;
use Catmandu::Sane;
use YAML::Any qw(Dump);
use Moo;

use PICA::Writer::Plus;
use PICA::Writer::Plain;
use PICA::Writer::XML;

with 'Catmandu::Exporter';

has type   => ( is => 'rw', default => sub { 'plus' } );
has writer => ( is => 'lazy' );

sub _build_writer {
    my ($self) = @_;

    my $type = lc $self->type;

    if ( $type =~ /^(pica)?plus$/ ) {
        PICA::Writer::Plus->new( fh => $self->fh );
    } elsif ( $type eq 'plain') {
        PICA::Writer::Plain->new( fh => $self->fh );
    } elsif ( $type eq 'xml') {
        PICA::Writer::XML->new( fh => $self->fh );
    } else {
        die "unknown type: $type";
    }
}
 
sub add {
    my ($self, $data) = @_;
    # utf8::decode ???
    $self->writer->write($data);
}

sub commit { # TODO: why is this not called automatically?
    my ($self) = @_;
    $self->writer->end if $self->can('end');
}

1;

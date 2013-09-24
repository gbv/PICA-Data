package Catmandu::Importer::PICA;
#ABSTRACT: Package that imports PICA+ data
#VERSION

use Catmandu::Sane;
use PICA::Parser::XML;
use PICA::Parser::Plus;
use PICA::Parser::Plain;
use Moo;

with 'Catmandu::Importer';

has type   => ( is => 'ro', default => sub { 'xml' } );
has parser => ( is => 'lazy' );

sub _build_parser {
    my ($self) = @_;

    my $type = lc $self->type;

    if ( $type =~ /^(pica)?plus$/ ) {
        PICA::Parser::Plus->new(  $self->fh );
    } elsif ( $type eq 'plain') {
        PICA::Parser::Plain->new( $self->fh );
    } elsif ( $type eq 'xml') {
        PICA::Parser::XML->new( $self->fh );
    } else {
        die "unknown type: $type";
    }
}

sub generator {
    my ($self) = @_;

    sub {
        return $self->parser->next();
    };
}

=head1 SYNOPSIS

    use Catmandu::Importer::PICA;

    my $importer = Catmandu::Importer::PICA->new(file => "pica.xml", type=> "XML");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 PICA

Parse PICA XML to native Perl hash containing two keys: '_id' and 'record'. 

  {
    'record' => [
                  [
                    '001@',
                    '',
                    '0',
                    '703'
                  ],
                  [
                    '001A',
                    '',
                    '0',
                    '2045:10-03-11'
                  ],
                  [
                    '028B',
                    '01',
                    'd',
                    'Thomas',
                    'a',
                    'Bartzanas'
                   ]

    '_id' => '658700774'
  },

=head1 METHODS

=head2 new(file => $filename,type=>$type)

Create a new PICA importer for $filename. Use STDIN when no filename is given. Type 
describes the sytax of the PICA records. Currently we support following types: PICAplus, XML.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::PICA methods are not idempotent: PICA feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;    # End of Catmandu::Importer::PICA

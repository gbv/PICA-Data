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

To convert between PICA+ syntax variants with the L<catmandu> command line client:

    catmandu convert PICA --type xml to PICA --type plain < picadata.xml

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

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:

=over

=item type

Describes the PICA+ syntax variant. Supported values (case ignored) include the
default value C<xml> for PicaXML, C<plain> for human-readable PICA+
serialization (where C<$> is used as subfield indicator) and C<plus> or
C<picaplus> for normalized PICA+.

=back

=cut

1;

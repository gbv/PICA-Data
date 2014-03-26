package Catmandu::Importer::SRU::Parser::picaxml;

# ABSTRACT: Package transforms SRU responses into Catmandu PICA
# VERSION

use Moo;
use PICA::Parser::XML;

sub parse {
    my ( $self, $record ) = @_;

    my $xml = $record->{recordData};
    my $parser = PICA::Parser::XML->new( $xml ); 
    my $record_hash = $parser->next();

    return $record_hash;
}

=head1 SYNOPSIS

my %attrs = (
    base => 'http://sru.gbv.de/gvk',
    query => '1940-5758',
    recordSchema => 'picaxml' ,
    parser => 'picaxml' ,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);

=head1 DESCRIPTION

Each picaxml response will be transformed into an format as defined by L<Catmandu::Importer::PICA>

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=cut

1;

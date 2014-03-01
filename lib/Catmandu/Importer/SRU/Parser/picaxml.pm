package Catmandu::Importer::SRU::Parser::picaxml;

use Moo;
use PICA::Parser::XML;

sub parse {
    my ( $self, $record ) = @_;

    my $xml = $record->{recordData};
    my $parser = PICA::Parser::XML->new( $xml ); 
    my $record_hash = $parser->next();

    return $record_hash;
}

=head1 NAME

  Catmandu::Importer::SRU::Parser::picaxml - Package transforms SRU responses into Catmandu PICA 

=head1 SYNOPSIS

my %attrs = (
    base => 'http://sru.gbv.de/gvk?version=1.1&operation=searchRetrieve&query=pica.tit%3Dentwicklung&maximumRecords=10&recordSchema=picaxml',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
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

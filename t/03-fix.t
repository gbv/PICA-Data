#!perl -T

use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Fix;
use Catmandu::Importer::PICA;

my $fixer = Catmandu::Fix->new(fixes => ['pica_map("001B", "date")','pica_map("001U0", "encoding")','pica_map("003\@0", "id")','remove_field("record"),','remove_field("_id"),']);
my $importer = Catmandu::Importer::PICA->new(file => "./t/picaxml.xml", type=> "XML");
my @records;
$fixer->fix($importer)->each(
    sub {
        push( @records, $_[0] );
    }
);

ok( $records[0]->{'id'} eq '658700774', 'fix id' );
ok( $records[0]->{'encoding'} eq 'utf8', 'fix encoding' );
ok( $records[0]->{'date'} eq '2045:09-04-1318:26:39.000', 'fix date' );
is_deeply( $records[1], {'id' => '65869538X', 'date' => '1999:22-11-1206:31:01.000', 'encoding' => 'utf8'}, 'fix record');

done_testing();
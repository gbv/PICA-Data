#!perl -T

use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Importer::PICA;

my $importer = Catmandu::Importer::PICA->new(file => "./t/files/picaxml.xml", type=> "XML");
my @records;
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 5, 'records');
ok( $records[0]->{'_id'} eq '658700774', 'record _id' );
is_deeply( $records[0]->{'record'}->[7], ['003@', '', '0', '658700774'],
    'record field'
);

$importer = Catmandu::Importer::PICA->new(file => "./t/files/picaplus.dat", type=> "PICAplus");
@records = ();
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 10, 'records');
ok( $records[0]->{'_id'} eq '1041318383', 'record _id' );
is_deeply( $records[0]->{'record'}->[5], ['003@', '', '0', '1041318383'],,
    'record field'
);

done_testing();
#!perl -T

use strict;
use warnings;
use Test::More;

use Catmandu::PICA;
my $parser = Catmandu::PICA->new( './t/picaxml.xml' );
isa_ok( $parser, 'Catmandu::PICA' );
my $record = $parser->next();
ok($record->{_id} eq '658700774', 'record _id' );
ok($record->{record}->[0][0] eq '001@', 'tag from first field' );
is_deeply($record->{record}->[1], ['001A', '', '_', '', '0', '2045:10-03-11'], 'second field');
ok($parser->next()->{_id} eq '65869538X', 'next record');

use Catmandu::PICAplus;
$parser = Catmandu::PICAplus->new( './t/picaplus.dat' );
isa_ok( $parser, 'Catmandu::PICAplus' );
$record = $parser->next();
ok($record->{_id} eq '1041318383', 'record _id' );
ok($record->{record}->[0][0] eq 'LDR', 'tag from first field' );
is_deeply($record->{record}->[1], ['001A', '', '_', '', '0', '1240:04-09-13'], 'second field');
ok($parser->next()->{_id} eq '1041318464', 'next record');

done_testing();
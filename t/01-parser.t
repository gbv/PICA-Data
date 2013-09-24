use strict;
use warnings;
use Test::More;
use utf8;

use PICA::Parser::XML;
my $parser = PICA::Parser::XML->new( './t/files/picaxml.xml' );
isa_ok( $parser, 'PICA::Parser::XML' );
my $record = $parser->next();
ok($record->{_id} eq '658700774', 'record _id' );
ok($record->{record}->[0][0] eq '001@', 'tag from first field' );
is_deeply($record->{record}->[1], ['001A', '', '0', '2045:10-03-11'], 'second field');
ok($parser->next()->{_id} eq '65869538X', 'next record');

use PICA::Parser::Plus;
$parser = PICA::Parser::Plus->new( './t/files/picaplus.dat' );
isa_ok( $parser, 'PICA::Parser::Plus' );
$record = $parser->next();
ok($record->{_id} eq '1041318383', 'record _id' );
ok($record->{record}->[0][0] eq '001A', 'tag from first field' );
is_deeply($record->{record}->[0], ['001A', '', '0', '1240:04-09-13'], 'first field');
ok($parser->next()->{_id} eq '1041318464', 'next record');

use PICA::Parser::Plain;
$parser = PICA::Parser::Plain->new( './t/files/plain.pica' );
isa_ok $parser, 'PICA::Parser::Plain';
$record = $parser->next;
is $record->{record}->[4]->[7], '柳经纬主编;', 'unicode from plain pica';
is_deeply $record->{record}->[9],
    [ '145Z', '40', 'a', '$$', 'b', 'test$$', 'c', '...' ], 'sub field with $';

done_testing();

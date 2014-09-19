use strict;
use warnings;
use Test::More;
use utf8;

use PICA::Data qw(pica_parser pica_writer);
use PICA::Parser::XML;
my $parser = pica_parser( XML => './t/files/picaxml.xml' );
isa_ok $parser, 'PICA::Parser::XML';

my $record = $parser->next;
ok $record->{_id} eq '658700774', 'record _id';
ok $record->{record}->[0][0] eq '001@', 'tag from first field';
is_deeply $record->{record}->[1], ['001A', '', 0 => '2045:10-03-11'], 'second field';
is_deeply $record->{record}->[5], ['001X', '', 0 => '0', x => '', y => ''], 'empty subfields';
ok $parser->next()->{_id} eq '65869538X', 'next record';

my $xml = q{<record xmlns="info:srw/schema/5/picaXML-v1.0"><datafield tag="001@"><subfield code="0">703</subfield></datafield><datafield tag="001A"><subfield code="0">2045:10-03-11</subfield></datafield><datafield tag="001B"><subfield code="0">2045:09-04-13</subfield><subfield code="t">18:26:39.000</subfield></datafield><datafield tag="001D"><subfield code="0">2045:14-05-11</subfield></datafield><datafield tag="001U"><subfield code="0">utf8</subfield></datafield><datafield tag="001X"><subfield code="0">0</subfield></datafield><datafield tag="002@"><subfield code="0">Oax</subfield></datafield><datafield tag="003@"><subfield code="0">658700774</subfield></datafield><datafield tag="004A"><subfield code="0">3642036805</subfield></datafield><datafield tag="004J"><subfield code="0">3642036813</subfield><subfield code="A">9783642036811</subfield><subfield code="f">160.45 €</subfield></datafield><datafield tag="006X"><subfield code="c">CIANDO</subfield><subfield code="0">43423</subfield></datafield><datafield tag="007G"><subfield code="c">GBV</subfield><subfield code="0">658700774</subfield></datafield><datafield tag="008E"><subfield code="a">ZDB-22-CAN</subfield></datafield><datafield tag="009@"><subfield code="a">CIANDO</subfield><subfield code="b">eBook</subfield></datafield><datafield tag="009P" occurrence="05"><subfield code="S">1</subfield><subfield code="a">http://ebooks.ciando.com/book/index.cfm/bok_id/43423</subfield><subfield code="n">CIANDO</subfield><subfield code="q">application/pdf</subfield><subfield code="v">10-03-11</subfield><subfield code="3">34</subfield><subfield code="A">CIANDO</subfield></datafield><datafield tag="009Q"><subfield code="S">1</subfield><subfield code="y">C</subfield><subfield code="a">http://www.ciando.com/img/books/big/3642036813_k.jpg</subfield><subfield code="n">CIANDO</subfield><subfield code="q">image/jpeg</subfield><subfield code="3">93</subfield><subfield code="A">Ciando</subfield></datafield><datafield tag="009Q"><subfield code="S">1</subfield><subfield code="y">C</subfield><subfield code="a">http://www.ciando.com/img/books/3642036813_k.jpg</subfield><subfield code="n">CIANDO</subfield><subfield code="q">image/jpeg</subfield><subfield code="3">93</subfield><subfield code="A">Ciando</subfield></datafield><datafield tag="009Q"><subfield code="S">0</subfield><subfield code="y">Inhaltsverzeichnis</subfield><subfield code="0">pdf</subfield><subfield code="a">http://www.gbv.de/dms/bowker/toc/9783642036804.pdf</subfield><subfield code="m">DE-601</subfield><subfield code="n">Bowker</subfield><subfield code="q">pdf/application</subfield><subfield code="v">2011-12-23</subfield><subfield code="3">04</subfield><subfield code="A">GBV</subfield><subfield code="B">2</subfield></datafield><datafield tag="009Q"><subfield code="S">1</subfield><subfield code="y">C</subfield><subfield code="a">http://www.ciando.com/img/books/width167/3642036813_k.jpg</subfield><subfield code="n">CIANDO</subfield><subfield code="q">image/jpeg</subfield><subfield code="3">93</subfield><subfield code="A">Ciando</subfield></datafield><datafield tag="009Q"><subfield code="S">1</subfield><subfield code="y">C</subfield><subfield code="a">http://www.ciando.com/pictures/bib/3642036813bib_t_1.jpg</subfield><subfield code="n">CIANDO</subfield><subfield code="q">image/jpeg</subfield><subfield code="3">93</subfield><subfield code="A">Ciando</subfield></datafield><datafield tag="010@"><subfield code="a">eng</subfield></datafield><datafield tag="011@"><subfield code="a">2010</subfield></datafield><datafield tag="013@"><subfield code="0">o3</subfield></datafield><datafield tag="016D"><subfield code="0">cr</subfield></datafield><datafield tag="016H"><subfield code="0">Elektronische Ressource</subfield></datafield><datafield tag="020F"><subfield code="a">The agricultural world has changed significantly during the last years. The excessive use of heavy machinery, waste disposal, the use of agrochemicals and new soil cultivation means led to severe problems, which agricultural engineers have to cope with in order to prevent soil from permanent irreversible damage.This Soil Biology volume will update readers on several cutting-edge aspects of sustainable soil engineering including topics such as: soil compaction, soil density increases, soil disturbance and soil fragmentation, soil tillage machineries and optimization of tillage tools, soil traffic and traction, effects of heavy agricultural machines, the use of robotics in agriculture and controlled traffic farming, mechanical weed control, the characterization of soil variability and the recycling of compost and biosolids in agricultural soils.</subfield></datafield><datafield tag="021A"><subfield code="a">Soil Engineering. (Soil Biology, Vol 20)</subfield></datafield><datafield tag="028A"><subfield code="d">Athanasios P.</subfield><subfield code="a">Dedousis</subfield></datafield><datafield tag="028B" occurrence="01"><subfield code="d">Thomas</subfield><subfield code="a">Bartzanas</subfield></datafield><datafield tag="032@"><subfield code="a">1. Aufl.</subfield></datafield><datafield tag="033A"><subfield code="p">[s.l.]</subfield><subfield code="n">Springer-Verlag</subfield></datafield><datafield tag="034D"><subfield code="a">Online Ressource (5007 KB, 300 S.)</subfield></datafield><datafield tag="044Z"><subfield code="b">ciando</subfield><subfield code="a">Politik Umweltpolitik</subfield></datafield></record>};

$parser = PICA::Parser::XML->new($xml);
isa_ok $parser, 'PICA::Parser::XML';
$record = $parser->next;
is $record->{_id}, '658700774', 'record _id';
is $record->{record}->[0][0], '001@', 'tag from first field';
is_deeply $record->{record}->[1], ['001A', '', '0', '2045:10-03-11'], 'second field';
ok !$parser->next, 'last record';

$parser = PICA::Parser::XML->new(\$xml);
ok $parser->next_record, 'read from string reference';

use PICA::Parser::Plus;
$parser = pica_parser('plus' => './t/files/picaplus.dat');
isa_ok $parser, 'PICA::Parser::Plus';
$record = $parser->next;
ok $record->{_id} eq '1041318383', 'record _id';
ok $record->{record}->[0][0] eq '001A', 'tag from first field';
is_deeply $record->{record}->[0], ['001A', '', '0', '1240:04-09-13'], 'first field';
ok $parser->next()->{_id} eq '1041318464', 'next record';
is_deeply $record->{record}->[3],
    [ '001U', '', 0 => 'utf8', x => '', 'y' => '' ], 'empty subfields';
my $count = 0;
while( $parser->next ) { $count++ }
is $count, 8, 'remaining records';

open my $fh, '<', 't/files/picaplus.dat';
$parser = PICA::Parser::Plus->new($fh);
$count = 0;
while( $parser->next ) { $count++ };
is $count, 10, 'parse plus from file handle';

use PICA::Parser::Plain;
$parser = PICA::Parser::Plain->new( './t/files/plain.pica' );
isa_ok $parser, 'PICA::Parser::Plain';
$record = $parser->next;
is $record->{record}->[4]->[7], '柳经纬主编;', 'unicode from plain pica';
is_deeply $record->{record}->[9],
    [ '145Z', '40', 'a', '$$', 'b', 'test$$', 'c', '...' ], 'sub field with $';
is_deeply $record->{record}->[13],
    [ '203@', '01', 0 => '917400194', x => '', y => '' ], 'empty subfields';
ok !$parser->next, 'last record';

my $str = '003@ '.PICA::Parser::Plus::SUBFIELD_INDICATOR.'01234'
        . PICA::Parser::Plus::END_OF_FIELD
        . '021A '.PICA::Parser::Plus::SUBFIELD_INDICATOR.'aHello $¥!'
        . PICA::Parser::Plus::END_OF_RECORD;

SKIP: {
    skip "utf8 is driving me crazy", 1;
    # TODO: why UTF-8 encoded while PICA plain is not?
    # See https://travis-ci.org/gbv/PICA-Data/builds/35711139
    use Encode;
    $record = [
         [ '003@', '', '0', '1234' ],
        # ok in perl <= 5.16
         [ '021A', '', 'a', encode('UTF-8',"Hello \$\N{U+00A5}!") ]
        # ok in perl >= 5.18  
        # [ '021A', '', 'a', 'Hello $¥!' ]
        ];
     
    open my $fh, '<', \$str;
    is_deeply pica_parser( plus => $fh )->next, { 
        _id => 1234, record => $record
    }, 'Plus format UTF-8 from string';
};

# what can possibly go wrong...

eval { pica_parser('doesnotexist') };
ok $@, 'unknown parser';

eval { pica_parser( xml => '' ) };
ok $@, 'invalid handle';

eval { pica_parser( plus => [] ) };
ok $@, 'invalid handle';

eval { pica_parser( plain => bless({},'MyFooBar') ) };
ok $@, 'invalid handle';

ok pica_parser('plus', \"003@ \x{1F}01")->next;
foreach ("0033 \x{1F}01", "003@/0 \x{1F}01") {
    eval { pica_parser('plus', \$_)->next };
    ok $@, 'invalid PICA field structure in PICA plus';
    my  $field = $_; $field =~ s/\x{1F}/\$/g;
    eval { pica_parser('plain', \$field)->next };
    ok $@, 'invalid PICA field structure in PICA plain';
}

done_testing;

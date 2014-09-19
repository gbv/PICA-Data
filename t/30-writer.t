use strict;
use Test::More;

use PICA::Data qw(pica_writer);
use PICA::Writer::Plain;
use PICA::Writer::Plus;
use PICA::Writer::XML;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my @pica_records = (
    [
      ['003@', '', '0', '1041318383'],
      ['021A', '', 'a', encode('UTF-8',"Hello \$\N{U+00A5}!")],
    ],
    {
      record => [
        ['028C', '01', d => 'Emma', a => 'Goldman']
      ]
    }
);

my ($fh, $filename) = tempfile();
my $writer = pica_writer( 'plain', fh => $fh );
foreach my $record (@pica_records) {
    $writer->write($record);
}
close $fh;

my $out = do { local (@ARGV,$/)=$filename; <> };
is $out, <<'PLAIN', 'Plain writer';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

($fh, $filename) = tempfile();
$writer = PICA::Writer::Plus->new( fh => $fh );

foreach my $record (@pica_records) {
    $writer->write($record);
}
close $fh;

$out = do { local (@ARGV,$/)=$filename; <> };
is $out, <<'PLUS', 'Plus Writer';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

($fh, $filename) = tempfile();
$writer = PICA::Writer::XML->new( fh => $fh );

foreach my $record (@pica_records) {
    $writer->write($record);
}
$writer->end;
close $fh;

$out = do { local (@ARGV,$/)=$filename; <> };

my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<collection xlmns="info:srw/schema/5/picaXML-v1.0">
<record>
  <datafield tag="003@">
    <subfield code="0">1041318383</subfield>
  </datafield>
  <datafield tag="021A">
    <subfield code="a">Hello $¥!</subfield>
  </datafield>
</record>
<record>
  <datafield tag="028C" occurrence="01">
    <subfield code="d">Emma</subfield>
    <subfield code="a">Goldman</subfield>
  </datafield>
</record>
</collection>
XML

is $out, $xml, 'XML writer';

{ 
  package MyStringWriter;
  sub print { $_[0]->{out} .= $_[1] } 
}

my $string = bless { }, 'MyStringWriter';

$writer = PICA::Writer::XML->new( fh => $string, start => 0 );
$writer->write($_) for map { bless $_, 'PICA::Data' } @pica_records;
$writer->end;
like $string->{out}, qr{^<record.+record>}sm, 'XML writer (to object, no start)';

my (undef, $filename) = tempfile(OPEN => 0);
pica_writer('plain', fh => $filename);
ok -e $filename, 'write to file';

eval { pica_writer('plain', fh => '') };
ok $@, 'invalid filename';

eval { pica_writer('plain', fh => {} ) };
ok $@, 'invalid handle';

done_testing;

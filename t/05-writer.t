use strict;
use Test::More;
use PICA::Writer::Plain;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);

my ($fh, $filename) = tempfile();
my $writer = PICA::Writer::Plain->new( fh => $fh );

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
foreach my $record (@pica_records) {
    $writer->write($record);
}

close($fh);

my $out = do { local (@ARGV,$/)=$filename; <> };
is $out, <<'PICA';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PICA

done_testing;

use strict;
use warnings;
use Test::More;

use PICA::Data ':all';
use PICA::Path;

my %pathes = (
    '003*$abc'     => [ qr{003.}, undef, qr{[abc]} ],
    '001B$0'       => [ qr{001B}, undef, qr{[0]} ],
    '123A[0*]/1-3' => [ qr{123A}, qr{0.}, qr{[_A-Za-z0-9]}, 1, 3 ],
);
foreach my $path (keys %pathes) {
    my $parsed = PICA::Path->new($path);
    is_deeply [@$parsed], $pathes{$path}, 'PICA::Path';
    is "$parsed", $path, 'stringify';
}

is "".PICA::Path->new('003*abc'), '003*$abc', 'stringify';
is "".PICA::Path->new('003*abc')->stringify(1), '003*abc', 'stringify';

use PICA::Parser::Plain;
my $record = PICA::Parser::Plain->new( './t/files/plain.pica' )->next;

foreach ('019@', PICA::Path->new('019@')) {
    is_deeply [ pica_values($record, $_) ], ['XB-CN'], 'pica_values';
}

bless $record, 'PICA::Data';
my %map = (
    '019@/0-1'  => ['XB'],
    '019@/1'  => ['B'],
    '019@/5'  => [],
#    '019@/3-' => ['CN'], # FIXME: not the whole string?!
#    '019@/-1' => ['XB'], # FIXME: not the whole string?
    '1...b' => ['9330','test$$'],
    '?+#' => [],
);
foreach (keys %map) {
    is_deeply [$record->values($_)], $map{$_}, "->values($_)";
}

is_deeply [$record->value('1...b')], ['9330'], '->value';

is_deeply $record->fields('010@'), 
    [ [ '010@', '', 'a' => 'chi'] ], '->field';

is_deeply $record->fields('?!*~'), [ ], 'invalid PICA path';
is scalar @{pica_fields($record,'1***')}, 5, 'pica_fields';

done_testing;

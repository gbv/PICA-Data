use strict;
use warnings;
use Test::More;

use PICA::Data ':all';

my %path = (
    '003*abc'      => [ '003.', undef, '[abc]' ],
    '001B$0'       => [ '001B', undef, '[0]' ],
    '123A[0*]/1-3' => [ '123A', '0.', '[_A-Za-z0-9]', 1, 3 ],
);
foreach (keys %path) {
    my $parsed = parse_pica_path($_);
    is_deeply $parsed, $path{$_}, 'parse_pica_path';
}

use PICA::Parser::Plain;
my $record = PICA::Parser::Plain->new( './t/files/plain.pica' )->next;

foreach ('019@', parse_pica_path('019@')) {
    is_deeply [ pica_values($record, $_) ], ['XB-CN'], 'pica_values';
}

bless $record, 'PICA::Data';
my %map = (
    '019@/0-1'  => ['XB'],
    '019@/1'  => ['B'],
    '019@/5'  => [],
#    '019@/3-' => ['CN'], # FIXME: not the whole string?!
#    '019@/-1' => ['XB'], # FIXME: not the whole string?
);
foreach (keys %map) {
    is_deeply [$record->values($_)], $map{$_}, '->values';
}

done_testing;

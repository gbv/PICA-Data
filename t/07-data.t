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

done_testing;

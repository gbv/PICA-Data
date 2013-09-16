use strict;
use Test::More;

foreach ( map { s{^lib/|\.pm\n$}{}g; s{/}{::}g; $_ } `find lib -iname *.pm` ) {
    use_ok $_;
}

diag "Testing Catmandu::PICA $Catmandu::PICA::VERSION, Perl $], $^X";

done_testing;

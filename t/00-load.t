#!perl -T

use Test::More;

BEGIN {
    my @modules = qw(
        PICA::Parser::Plus
        PICA::Parser::XML
        Catmandu::Importer::PICA
        Catmandu::PICA
        Catmandu::Fix::pica_map
    );
    foreach (@modules) {
        use_ok($_) || print "Bail out!\n";
    }
}

diag( "Testing Catmandu::PICA $Catmandu::PICA::VERSION, Perl $], $^X" );

done_testing;

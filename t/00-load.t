#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Catmandu::PICA' ) || print "Bail out!\n";
    use_ok( 'Catmandu::Importer::PICA' ) || print "Bail out!\n";
    use_ok( 'Catmandu::Fix::pica_map' ) || print "Bail out!\n";
}

diag( "Testing Catmandu::PICA $Catmandu::PICA::VERSION, Perl $], $^X" );

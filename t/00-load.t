use strict;
use Test::More;

foreach ( <DATA> ) {
    chomp;
    use_ok $_;
}

diag "Testing Catmandu::PICA $Catmandu::PICA::VERSION, Perl $], $^X";

done_testing;

# find lib -iname *.pm | perl -pe 's/\//::/g;s/^lib::|.pm$//g'
__DATA__
PICA::Writer::Plus
PICA::Writer::Plain
PICA::Writer::Handle
PICA::Writer::XML
PICA::Parser::Plus
PICA::Parser::Plain
PICA::Parser::XML
Catmandu::Importer::PICA
Catmandu::Exporter::PICA
Catmandu::PICA
Catmandu::Fix::pica_map

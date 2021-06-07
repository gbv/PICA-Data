use strict;
use Test::More;
use PICA::Data ':all';

is_diff(\"", \"001A \$x0", "+ 001A \$x0", 'add field');
is_diff(\"001A \$x0", \"", "- 001A \$x0", 'remove field');
is_diff(\"001A \$x0", \"001A \$x0\n002A \$x0", '+ 002A $x0', 'append field');
is_diff(\"001A \$x0\n002A \$x0", \"001A \$x0", '- 002A $x0', 'remove last field');
is_diff(\"001A \$x0\n002A \$x0", \"001A \$x0\n002A \$y1",
    "- 002A \$x0\n+ 002A \$y1", 'changed field');
is_diff(\"001A \$x0\n002A \$x0", \"002A \$x0\n001A \$x0", '', 'compare sorted');

sub is_diff {
    my $a = pica_parser(plain => shift)->next || [];
    my $b = pica_parser(plain => shift)->next || [];

    my $diff = pica_diff($a, $b)->string('plain');
    $diff =~ s/\n$//mg;

    is($diff, shift, shift);
}

done_testing;

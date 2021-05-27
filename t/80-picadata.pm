use strict;
use Test::More;
use App::picadata;

my $app;

my %default = (number => 0, help => '', color => 1, argv => [], path => []);

$app = App::picadata->new();
is_deeply $app, {%default, help => 1}, 'default arguments';

$app = App::picadata->new(qw(-3));
is_deeply $app, {%default, number => 3}, 'parse arguments';

$app = App::picadata->new(qw(003@ 123A|012X));
is_deeply $app, {%default, path => [qw(003@ 123A 012X)]},
    'detect path expressions';

done_testing;

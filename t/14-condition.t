use strict;
use Test::More;
use PICA::Path::Condition;

for (qw($a !$a $a>0)) {
    my $cond = PICA::Path::Condition->new($_);
    is $_, "$cond", $_;
}

sub match { PICA::Path::Condition->new($_[0])->match($_[1]) };

# numeric comparison

for (qw($a=1 $a!=1 $a>1 $a>=2 $a<2 $a<=1)) {
    ok match($_, [qw(012AX 0 a 1 a 2)]), $_;
}

for (qw($a<1 $a<=0 $a>=3)) {
    ok !match($_, [qw(012AX 0 a 1 a 2)]), $_;
}

for (qw($a=1)) {
    ok match($_, [qw(012AX 0 a 1)]), $_;
    ok !match($_, [qw(012AX 0 a 2)]), $_;
}

for (qw($a!=2)) {
    ok match($_, [qw(012AX 0 a 1)]), $_;
    ok !match($_, [qw(012AX 0 a 2)]), $_;
}

# string comparison

for (qw($a=x $a!=x $a>x $a>=y $a<y $a<=x)) {
    ok match($_, [qw(0xyAX 0 a x a y)]), $_;
}

for (qw($a<x $a<=a $a>=z)) {
    ok !match($_, [qw(0xyAX 0 a x a y)]), $_;
}

for (qw($a=x)) {
    ok match($_, [qw(0xyAX 0 a x)]), $_;
    ok !match($_, [qw(0xyAX 0 a y)]), $_;
}

for (qw($a!=y)) {
    ok match($_, [qw(0xyAX 0 a x)]), $_;
    ok !match($_, [qw(0xyAX 0 a y)]), $_;
}

done_testing;

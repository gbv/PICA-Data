package PICA::Path::Condition;
use v5.14.1;
use utf8;

our $VERSION = '1.27';

use List::Util 'any';

use overload '""' => \&stringify;

sub new {
    my ($class, $cond) = @_;

    return if $cond !~ /^
        (?<not>!)?
        (\$?(?<subfield>[_A-Za-z0-9]))
        (
          (?<operator>(=|!=|>=|<=|>|<))
          (?<value>.+)
        )?
    $/x;

    my $self = bless {%+}, $class;

    if ($self->{operator}) {
        my $value = $self->{value};
        if ($value =~ /^-?[0-9]+(\.[0-9]+)?$/) {
            my $op = $self->{operator} eq '=' ? '==' : $self->{operator};
            $self->{cmp} = eval "sub { \$_[0] $op $value }";    ## no critic
        }
        else {
            my %ops = (
                '='  => sub {$_[0] eq $value},
                '!=' => sub {$_[0] ne $value},
                '>'  => sub {$_[0] gt $value},
                '<'  => sub {$_[0] lt $value},
                '>=' => sub {$_[0] ge $value},
                '<=' => sub {$_[0] le $value},
            );
            $self->{cmp} = $ops{$self->{operator}};
        }
    }

    $self;
}

sub stringify {
    my $self = $_[0];
    ($self->{not} ? '!' : '') . '$'
        . $self->{subfield}
        . ($self->{operator} ? $self->{operator} . $self->{value} : '');
}

sub match {
    my ($self, $field) = @_;
    my (undef, undef, @sf) = @{$_[1]};
    my $subfield = $self->{subfield};

    my @values;
    for (my $i = 2; $i < @$field; $i += 2) {
        push @values, $field->[$i + 1] if $field->[$i] eq $self->{subfield};
    }

    my $match = @values > 0;
    if ($match && $self->{operator}) {
        $match = any {$self->{cmp}->($_)} @values;
    }

    return $self->{not} ? !$match : $match;
}

1;
__END__

=head1 NAME

PICA::Path::Condition - Check conditions as part of PICA Path expressions

=head1 DESCRIPTION

This class implements conditions in L<PICA::Path> expressions.

=cut

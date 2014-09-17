package PICA::Path;

our $VERSION = '0.15';

use strict;
use Carp qw(confess);

sub new {
    my ($class, $path) = @_;

    confess "invalid pica path" if $path !~ /
        ([0-9*.]{3}\S)
        (\[([0-9*.]{2})\])?
        (\$?([_A-Za-z0-9]+))?
        (\/(\d+)(-(\d+))?)?
    /x;

    my $field      = $1;
    my $occurrence = $3;
    my $subfield   = defined $5 ? "[$5]" : "[_A-Za-z0-9]";

    my @position;
    if (defined $6) { # from, to
        my ($from, $to) = ($7, $9);
        my $length = defined $to ? $to - $from + 1 : 1;
        if ($length >= 1) {
            @position = ($from, $length);
        }
    }

    $field =~ s/\*/./g;
    $field = qr{$field};
    
    if (defined $occurrence) {
        $occurrence =~ s/\*/./g;
        $occurrence = qr{$occurrence};
    }

    $subfield = qr{$subfield};

    bless [ $field, $occurrence, $subfield, @position ], $class;
}

sub match_field {
    my ($self, $field) = @_;

    if ( $field->[0] =~ $self->[0] && 
        (!$self->[1] || (defined $field->[1] && $field->[1] =~ $self->[1])) ) {
        return $field;
    }

    return
}

sub match_subfields {
    my ($self, $field) = @_;

    my $subfield_regex = $self->[2];
    my $from           = $self->[3];
    my $length         = $self->[4];

    my @values;

    for (my $i = 2; $i < @$field; $i += 2) {
        if ($field->[$i] =~ $subfield_regex) {
            my $value = $field->[$i + 1];
            if (defined $from) {
                $value = substr($value, $from, $length);
                next if '' eq ($value // '');
            }
            push @values, $value;
        }
    }

    return @values;
}

use overload '""' => \&stringify;

sub stringify {
    my ($self, $short) = @_;

    my ($field, $occurrence, $subfields) = map {
        defined $_ ? do {
            s/^\(\?[^:]*:(.*)\)$/$1/;
            s/\./*/g;
            $_ } : undef
        } ($self->[0], $self->[1], $self->[2]); 

    my $str = $field;

    if (defined $occurrence) {
        $str .= "[$occurrence]";
    }

    if (defined $subfields and $subfields ne '[_A-Za-z0-9]') {
        $subfields =~ s/\[|\]//g;
        unless( $short and $subfields !~  /^\$/ ) {
            $str .= '$';
        }
        $str .= $subfields;
    }

    if (defined $self->[3]) {
        $str .= '/' . $self->[3];
        if (defined $self->[4]) {
            $str .= '-' . ($self->[4] - $self->[3] + 1);
        }
    }

    $str;
}

1;
__END__

=head1 NAME

PICA::Path - PICA path expression to match field and subfield values

=head1 DESCRIPTION

PICA path expressions can be used to match fields and subfields of
L<PICA::Data> records. An instance of PICA::Path is a blessed array reference,
consisting of the following fields:

=over

=item

regular expression to match fields against

=item

regular expression to match occurrences against, or undefined

=item

regular expression to match subfields against

=item

substring start position

=item

substring end position

=back

=head1 METHODS

=head2 match_field( $field )

Check whether a given PICA field matches the field and occurrence of this path.
Returns the C<$field> on success.

=head2 match_subfields( $field )

Returns a list of matching subfields (optionally trimmed by from and length)
without inspection of field and occurrence values.

=head2 stringify( [ short ] )

Stringifies the PICA path to normalized form. Subfields are separated with
C<$>, unless called as C<stringify(1)> or the first subfield is C<$>.

=head1 SEE ALSO

L<Catmandu::Fix::pica_map>

=cut

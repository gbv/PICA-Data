package PICA::Error;
use v5.14.1;

use overload fallback => 1, '""' => \&message;

sub new {
    my $class = shift;
    my ($tag, $occ) = @{shift(@_)};

    my $error = {tag => $tag, @_};
    $occ                 = 0    if substr($tag, 0, 1) eq 2;
    $error->{occurrence} = $occ if $occ;

    # add error messages
    my $id = join '/', grep {$_} $tag, $occ;

    while (my ($code, $sf) = each %{$error->{subfields} // {}}) {
        $sf->{code}    = $code;
        $sf->{message} = _subfield_error_message($sf, $id);
    }

    $error->{message} = _field_error_message($error, $id)
        unless $error->{message};

    bless $error, $class;
}

sub message {
    $_[0]->{message} // '';
}

sub _subfield_error_message {
    my $error = shift;
    my $id    = (shift // '') . '$' . $error->{code};

    if ($error->{required}) {
        "missing subfield $id";
    }
    elsif ($error->{repeated}) {
        "subfield $id is not repeatable";
    }
    elsif ($error->{position}) {
        "invalid value at position $error->{position} of subfield $id";
    }
    elsif ($error->{pattern}) {
        "value of subfield $id does not match pattern $error->{pattern}";
    }
    elsif (defined $error->{order}) {
        "wrong subfield order of $id";
    }
    else {
        "unknown subfield $id";
    }
}

sub _field_error_message {
    my ($error, $id) = @_;

    if ($error->{required}) {
        "missing field $id";
    }
    elsif ($error->{repeated}) {
        "field $id is not repeatable";
    }
    elsif ($error->{subfields}) {
        my %sf      = %{$error->{subfields}};
        my $invalid = grep {$_->{message} !~ /^unknown/} values %sf;
        ($invalid ? "invalid" : "unknown")
            . " subfield"
            . (length keys %sf > 1 ? "s" : "")
            . " $id\$"
            . join '', sort keys %sf;
    }
    else {
        "unknown field $id";
    }
}

1;
__END__

=head1 NAME

PICA::Error - Information about malformed or invalid PICA data

=head1 DESCRIPTION

Instances of B<PICA::Error> provide information about malformed PICA data
(syntax errors such as impossible field tags and subfield codes) or violation
of an Avram Schema (more semantic errors such as wrong use of subfields). This
package should not be used directly, see L<PICA::Schema> instead.

=head1 PROPERTIES

=over

=item tag

Tag of the invalid field.

=item occurrence

Occurrence of the invalid field (if it has an occurrence).

=item required

Set if the field was required but missing.

=item repeated

Set if the non-repeatable field was repeated.

=item subfields

Set to a hash reference that maps invalid subfield codes to
L<subfield errrors|/SUBFIELD ERRORS>.

=item message

human-readable error message, deriveable from the rest of the error.

=back

=head1 SUBFIELD ERRORS

Subfields errors are given as hash references with this keys:

=over

=item code

Subfield code of the invalid subfield.

=item required

Set if the subfield was required but missing.

=item repeated

Set if the non-repeatable subfield was repeated.

=item order

Set to the expected order value if subfield occurred in wrong order.

=item value

The malformed subfield value if it did not match a pattern or positions.

=item pattern

Pattern which the subfield value did not match.

=item position

The position if value did not match positions or codes.

=item message

human-readable error message, deriveable from the rest of the error.

=back

=head1 METHODS

=head2 message

Returns the human readable error message. This is also returned when the error
instance is used in string context.

=cut

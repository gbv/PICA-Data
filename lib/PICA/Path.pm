package PICA::Path;
use strict;
use warnings;

our $VERSION = '1.00';

use Carp qw(confess);
use Scalar::Util qw(reftype);

use overload '""' => \&stringify;

sub new {
    my ( $class, $path ) = @_;

    confess "invalid pica path" if $path !~ /
        ([012.][0-9.][0-9.][A-Z@.]) # tag
        (\[([0-9.]{2,3})\])?        # occurence
        (\$?([_A-Za-z0-9]+))?       # subfields
        (\/(\d+)?(-(\d+)?)?)?       # position
    /x;

    my $field      = $1;
    my $occurrence = $3;
    my $subfield   = defined $5 ? "[$5]" : "[_A-Za-z0-9]";

    my @position;
    if ( defined $6 ) {    # from, to
        my ( $from, $dash, $to, $length ) = ( $7, $8, $9, 0 );

        if ($dash) {
            confess "invalid pica path" unless defined( $from // $to );   # /-
        }

        if ( defined $to ) {
            if ( !$from and $dash ) {    # /-X
                $from = 0;
            }
            $length = $to - $from + 1;
        }
        else {
            if ($8) {
                $length = undef;
            }
            else {
                $length = 1;
            }
        }

        if ( !defined $length or $length >= 1 ) {
            unless ( !$from and !defined $length ) {    # /0-
                @position = ( $from, $length );
            }
        }
    }

    $field = qr{$field};

    if ( defined $occurrence ) {
        $occurrence = qr{$occurrence};
    }

    $subfield = qr{$subfield};

    bless [ $field, $occurrence, $subfield, @position ], $class;
}

sub match {
    my ( $self, $record, $opt_ref ) = @_;

    my $subfield_regex = $self->[2];
    my $split          = $opt_ref->{'split'} // 0;
    my $join_char      = $opt_ref->{'join'} // '';
    my $pluck          = $opt_ref->{'pluck'} // 0;
    my $value_set      = $opt_ref->{'value'} // undef;
    my $nested_arrays  = $opt_ref->{'nested_arrays'} // 0;

# Do an implicit split for nested_arrays , except when no-implicit-split is set
    if ( $nested_arrays == 1 ) {
        $split = 1 unless $opt_ref->{'no-implicit-split'};
    }

    my $values;

    for my $field ( @{ $self->record_fields($record) } ) {
        next if not defined $field;

        my $value;

        if ($value_set) {
            for ( my $i = 2; $i < @{$field}; $i += 2 ) {
                if ( $field->[$i] =~ $subfield_regex ) {
                    $value = $value_set;
                    last;
                }
            }
        }
        else {
            $value = [];

            if ($pluck) {
                push( @$value,
                    ( $self->match_subfields( $field, { pluck => 1 } ) ) );
            }
            else {
                push( @$value, ( $self->match_subfields($field) ) );
            }
            if (@$value) {
                if ( !$split ) {
                    my @defined_values = grep { defined($_) } @$value;
                    $value = join $join_char, @defined_values;
                }
            }
            else {
                $value = undef;
            }
        }
        if ( defined $value ) {
            if ($split) {
                $value = [$value]
                    unless ( defined($value) && ref($value) eq 'ARRAY' );
                if ( defined($values) && ref($values) eq 'ARRAY' ) {

                    # With the nested arrays option a split will
                    # always return an array of array of values.
                    if ( $nested_arrays == 1 ) {
                        push @$values, $value;
                    }
                    else {
                        push @$values, @$value;
                    }
                }
                else {
                    if ( $nested_arrays == 1 ) {
                        $values = [$value];
                    }
                    else {
                        $values = [@$value];
                    }
                }
            }
            else {
                push @$values, $value;
            }
        }
    }

    if ( $split && defined $values ) {
        $values = $values;
    }
    elsif ( defined $values ) {
        $values = join $join_char, @$values;
    }
    else {
        # no result
    }
    return $values;
}

sub match_field {
    my ( $self, $field ) = @_;

    if ($field->[0] =~ $self->[0]
        && ( !$self->[1]
            || ( defined $field->[1] && $field->[1] =~ $self->[1] ) )
        )
    {
        return $field;
    }

    return;
}

sub match_subfields {
    my ( $self, $field, $opt_ref ) = @_;

    my $subfield_regex = $self->[2];
    my $from           = $self->[3];
    my $length         = $self->[4];

    my @values;

    if ( $opt_ref->{pluck} ) {

        # Treat the subfields as a hash index
        my $subfield_href = {};
        for ( my $i = 2; $i < @{$field}; $i += 2 ) {
            push @{ $subfield_href->{ $field->[$i] } }, $field->[ $i + 1 ];
        }

        my $subfields = $self->[2];
        $subfields =~ s{[^a-zA-Z0-9]}{}g;
        for my $subfield ( split( '', $subfields ) ) {
            my $value = $subfield_href->{$subfield} // [undef];
            if ( defined $from ) {
                push @values, map {
                    $length
                        ? substr( $_, $from, $length )
                        : substr( $_, $from )
                } @{$value};
            }
            else {
                push @values, @{$value};
            }

        }
    }
    else {
        for ( my $i = 2; $i < @$field; $i += 2 ) {
            if ( $field->[$i] =~ $subfield_regex ) {
                my $value = $field->[ $i + 1 ];
                if ( defined $from ) {
                    $value
                        = $length
                        ? substr( $value, $from, $length )
                        : substr( $value, $from );
                    next if '' eq ( $value // '' );
                }
                push @values, $value;
            }
        }
    }

    return @values;
}

sub record_fields {
    my ( $self, $record ) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    return [ grep { $self->match_field($_) } @$record ];
}

sub record_subfields {
    my ( $self, $record ) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';

    my @values;

    foreach my $field ( grep { $self->match_field($_) } @$record ) {
        push @values, $self->match_subfields($field);
    }

    return @values;
}

sub stringify {
    my ( $self, $short ) = @_;

    my ( $field, $occurrence, $subfields ) = map {
        defined $_
            ? do {
            s/^\(\?[^:]*:(.*)\)$/$1/;
            $_;
            }
            : undef
    } ( $self->[0], $self->[1], $self->[2] );

    my $str = $field;

    if ( defined $occurrence ) {
        $str .= "[$occurrence]";
    }

    if ( defined $subfields and $subfields ne '[_A-Za-z0-9]' ) {
        $subfields =~ s/\[|\]//g;
        unless ( $short and $subfields !~ /^\$/ ) {
            $str .= '$';
        }
        $str .= $subfields;
    }

    my ( $from, $length, $pos ) = ( $self->[3], $self->[4] );
    if ( defined $from ) {
        if ($from) {
            $pos = $from;
        }
        if ( !defined $length ) {
            if ($from) {
                $pos = "$from-";
            }
        }
        elsif ( $length > 1 ) {
            $pos .= '-' . ( $from + $length - 1 );
        }
        elsif ( $length == 1 && !$from ) {
            $pos = 0;
        }
    }

    $str .= "/$pos" if defined $pos;

    $str;
}

1;
__END__

=head1 NAME

PICA::Path - PICA path expression to match field and subfield values

=head1 SYNOPSIS

    use PICA::Path;
    use PICA::Parser::Plain;

    # extract URLs from PIC Records, given from STDIN
    my $urlpath = PICA::Path->new('009P$a');
    my $parser = PICA::Parser::Plain->new(\*STDIN);
    while ( my $record = $parser->next ) {
        print "$_\n" for $urlpath->record_subfields($record);
    }

=head1 DESCRIPTION

PICA path expressions can be used to match fields and subfields of
L<PICA::Data> records or equivalent record structures. An instance of
PICA::Path is a blessed array reference, consisting of the following fields:

=over

=item

regular expression to match field tags against

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

=head2 new( $expression )

Create a PICA path by parsing the path expression. The expression consists of

=over

=item

A tag, constisting of three digits, the first C<0> to C<2>, followed by a digit
or C<@>.  The character C<.> can be used as wildcard.

=item

An optional occurrence, given by two or three digits (or C<.> as wildcard) in brackets,
e.g. C<[12]>, C<[0.]> or C<[102]>.

=item

An optional list of subfields. Allowed subfield codes include C<_A-Za-z0-9>.

=item

An optional position, preceeded by C</>. Both single characters (e.g. C</0> for
the first), and character ranges (such as C<2-4>, C<-3>, C<2->...) are
supported.

=back

=head2 match( $record, \%opts )

Returns matched fields as string or array reference. 

Optional parameter:

=over
 
=item join STRING
 
By default all the matched values are joined into a string without a field 
separator. Use the join function to set the separator. Default: '' 
(empty string).

    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match($record, { join => ' - '} );
    is( $match, 'Title - Supplement' )
 
=item pluck 0|1
 
Be default, all subfields are added to the mapping in the order they are 
found in the record. Using the pluck option, one can select the required 
order of subfields to map. Default: 0.
 
    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match($record, { pluck => 1 } );
    is( $match, 'SupplementTitle' )

=item split 0|1
 
When split is set to 1 then all mapped values will be joined into an array 
instead of a string. Default: 0. 

    my $record = { _id => 123X, record => [[ '021A', '', 'a', 'Title', 'd', 'Supplement' ]] }
    my $path = PICA::Path->new( '021A' );
    my $match = $path->match( $record, { split => 1} );
    is_deeply( $match, ['Title', 'Supplement'] )

=item nested_arrays 0|1
 
When the split option is specified the output of the mapping will always be 
an array of strings (one string for each subfield found). Using the 
nested_array option the output will be an array of array of strings (one 
array item for each matched field, one array of strings for each matched 
subfield). Default: 0.

    my $record = { _id => 123X, record => [[ '045U', '', 'e', '003', 'e', '004' ], [ '045U', '', 'e', '005' ]] }
    my $path = PICA::Path->new( '045U' );
    my $match = $path->match($record, { nested_arrays => 1 } );
    is_deeply( $match, [['003', '004'], ['005']] )

=back

=head2 filter_record_fields( $record )

Returns an array reference with fields of a L<PICA::Data> that match the path.
Subfield codes are ignore.

=head2 match_field( $field )

Check whether a given PICA field matches the field and occurrence of this path.
Returns the C<$field> on success.

=head2 match_subfields( $field )

Returns a list of matching subfields (optionally trimmed by from and length)
without inspection field and occurrence values.


=head2 stringify( [ $short ] )

Stringifies the PICA path to normalized form. Subfields are separated with
C<$>, unless called as C<stringify(1)> or the first subfield is C<$>.

=head1 SEE ALSO

L<Catmandu::Fix::pica_map>

=cut

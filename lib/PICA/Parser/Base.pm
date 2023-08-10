package PICA::Parser::Base;
use v5.14.1;

our $VERSION = '2.10';

use PICA::Data::Field;
use Carp         qw(croak);
use Scalar::Util qw(reftype);
use Encode       qw(encode);

sub _new {
    my $class = shift;
    my (%options) = @_ % 2 ? (fh => @_) : @_;

    bless {
        strict   => !!$options{strict},
        fh       => defined $options{fh} ? $options{fh} : \*STDIN,
        annotate => $options{annotate},
        counter  => 0,
    }, $class;
}

sub new {
    my $self  = _new(@_);
    my $input = $self->{fh};

    # check for file or filehandle
    my $ishandle = eval {fileno($input);};
    if (!$@ && defined $ishandle) {
        $self->{reader} = $input;
    }
    elsif ($input !~ /\n/ and -e $input) {
        open($self->{reader}, "<:encoding(UTF-8)", $input)
            or croak "Failed to read from file $input\n";
    }
    elsif ((ref $input and reftype $input eq 'SCALAR')) {
        $input = encode('UTF-8', $$input);
        open($self->{reader}, "<:encoding(UTF-8)", \$input)
            or croak "Failed to read from string reference\n";
    }
    elsif ($input =~ /\n/) {
        $input = encode('UTF-8', $input);
        open($self->{reader}, "<:encoding(UTF-8)", \$input)
            or croak "Failed to read from string\n";
    }
    else {
        croak "file or filehandle $input does not exists";
    }

    $self;
}

sub count {
    return $_[0]->{counter};
}

sub next {
    my ($self) = @_;

    while (my $record = $self->_next_record) {
        next unless @$record;
        $self->{counter}++;

        # get last 003@ $0 as _id (TODO: _id for level 1 and 2?)
        my $id;
        if (my ($field) = grep {($_->[0] // '') =~ '003@'} @$record) {
            for (my $i = 2; $i < @$field; $i += 2) {
                if ($field->[$i] eq '0') {
                    $id = $field->[$i + 1];
                    last;
                }
            }
        }

        my @fields = map {bless $_, 'PICA::Data::Field'} @$record;
        return bless {record => \@fields, _id => $id}, 'PICA::Data';
    }

    return;
}

1;
__END__

=head1 NAME

PICA::Parser::Base - abstract base class of PICA parsers

=head1 SYNOPSIS

    use PICA::Parser::Plain;
    my $parser = PICA::Parser::Plain->new( $filename );

    while ( my $record = $parser->next ) {
        # do something
    }

    use PICA::Parser::Plus;
    my $parser = PICA::Parser::Plus->new( $filename );
    ... # records will be instances of PICA::Data

    use PICA::Parser::XML;
    my $parser = PICA::Parser::XML->new( $filename, start => 1 );
    ...

=head1 DESCRIPTION

This abstract base class of PICA+ parsers should not be instantiated directly.
Use one of the following subclasses instead:

=over

=item L<PICA::Parser::Plain>

=item L<PICA::Parser::Plus>

=item L<PICA::Parser::Binary>

=item L<PICA::Parser::Import>

=item L<PICA::Parser::XML>

=item L<PICA::Parser::PPXML>

=item L<PICA::Parser::JSON>

=back

=head2 CONFIGURATION

=over

=item strict

By default faulty fields in records are skipped with warnings. You can make
them fatal by setting the I<strict> parameter to 1.

=item annotate

By default some parsers also support annotated PICA. Set to true to enforce
field annotations or to false to forbid them.

=back

=head1 METHODS

=head2 new( [ $input | fh => $input ] [ %options ] )

Initialize parser to read from a given file, handle (e.g. L<IO::Handle>), or
reference to a Unicode string. L<PICA::Parser::XML> also detects plain XML strings.

=head2 next

Reads the next PICA+ record. Returns a L<PICA::Data> object (that is a blessed
hash with keys C<record> and optional C<_id>).

=head2 count

Get the number of records read so far.

=head1 SEE ALSO

See L<Catmandu::Importer::PICA> for usage of this module in L<Catmandu>.

Alternative PICA parsers had been implemented as L<PICA::PlainParser> and
L<PICA::XMLParser> and included in the release of L<PICA::Record> (DEPRECATED).

=cut

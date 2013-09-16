package PICA::Parser::Plus;
# ABSTRACT: PICA+ format parser
# VERSION

use strict;
use charnames qw< :full >;
use Carp qw(croak);

use constant LEADER_LEN         => 24;
use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";

=head1 SYNOPSIS

L<PICA::Parser::Plus> is a parser for PICA+ records. 

    use PICA::Parser::Plus;

    my $parser = PICA::Parser::Plus->new( $filename );

    while ( my $record_hash = $parser->next() ) {
        # do something        
    }

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $file  = shift;

    my $self = {
        filename   => undef,
        rec_number => 0,
        xml_reader => undef,
    };

    # check for file or filehandle
    my $ishandle = eval { fileno($file); };
    if ( !$@ && defined $ishandle ) {
        $self->{filename} = scalar $file;
        $self->{reader}   = $file;
    }
    elsif ( -e $file ) {
        open $self->{reader}, '<:encoding(UTF-8)', $file
            or croak "cannot read from file $file\n";
        $self->{filename} = $file;
    }
    else {
        croak "file or filehande $file does not exists";
    }
    return ( bless $self, $class );
}

=head2 next()

Reads the next record from PICA+ XML input stream. Returns a Perl hash.

=cut

sub next {
    my $self = shift;
    if ( my $line = $self->{reader}->getline() ) {
        $self->{rec_number}++;
        my $record = _decode($line);

        # get last subfield from 003@ as id
        my ($id) = map { $_->[-1] } grep { $_->[0] =~ '003@' } @{$record};
        return { _id => $id, record => $record };
    }
    return;
}

=head2 _decode()

Deserialize a PICA+ record to an array of field arrays.

=cut

sub _decode {
    my $reader = shift;
    chomp($reader);
    my @fields = split( END_OF_FIELD, $reader );
    my @record;
    push( @record, [ 'LDR', undef, undef, shift(@fields) ] );

    for my $field (@fields) {

        my ( $tag, $occurence, $data );
        if ( $field =~ m/^(\d{3}[A-Z@])(\/(\d{2}))?\s(.*)/ ) {
            $tag       = $1;
            $occurence = $3 // '';
            $data      = $4;
        }
        else {
            croak 'ERROR: no valid PICA field structure';
        }
        my @subfields = map { substr( $_, 0, 1 ), substr( $_, 1 ) }
            split( SUBFIELD_INDICATOR, substr( $data, 1 ) );
        push( @record, [ $tag, $occurence, '_', '', @subfields ] );
    }
    return \@record;
}

=head1 SEEALSO

L<PICA::PlainParser>, included in the release of L<PICA::Record> implements
another PICA+ format parser, not aligned with the L<Catmandu> framework.

=cut

1;    # End of PICA::Parser::Plus

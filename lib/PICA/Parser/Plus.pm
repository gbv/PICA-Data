package PICA::Parser::Plus;
use strict;

use charnames qw< :full >;
use Carp qw(croak);

use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{LINE FEED}"; # TODO

sub new {
    my $class = shift;
    my $file  = shift;

    my $self = {
        filename   => undef,
        rec_number => 0,
        reader => undef,
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

sub _decode {
    my $reader = shift;
    chomp($reader);
    my @fields = split( END_OF_FIELD, $reader );
    my @record;

    if ($fields[0] !~ m/.*SUBFIELD_INDICATOR/){
        # drop leader because usage is unclear
        shift(@fields);
    }
    
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
        push( @record, [ $tag, $occurence, @subfields ] );
    }
    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::Plus - Normalized PICA+ format parser

=head1 SYNOPSIS

    use PICA::Parser::Plus;

    my $parser = PICA::Parser::Plus->new( $filename );

    while ( my $record_hash = $parser->next ) {
        # do something        
    }

=head1 METHODS

=head2 next

Reads the next record from PICA+ XML input stream. Returns a Perl hash.

=head2 _decode

Deserialize a PICA+ record to an array of field arrays.

=head1 SEEALSO

The counterpart of this module is L<PICA::Writer::Plus>.

See L<Catmandu::Importer::PICA> for usage of this module in L<Catmandu>.

An alternative writer had been implemented as L<PICA::PlainParser> included in
the release of L<PICA::Record>.

=cut

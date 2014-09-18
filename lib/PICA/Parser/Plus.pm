package PICA::Parser::Plus;
use strict;

our $VERSION = '0.21';

use charnames qw< :full >;
use Carp qw(croak);

use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{LINE FEED}"; # TODO

sub new {
    my ($class, $input) = @_;

    my $self = bless { }, $class;

    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        $self->{filename} = scalar $input;
        $self->{reader}   = $input;
    } elsif ( -e $input ) {
        open $self->{reader}, '<:encoding(UTF-8)', $input
            or croak "cannot read from file $input\n";
        $self->{filename} = $input;
    } else {
        croak "file or filehandle $input does not exists";
    }

    bless $self, $class;
}

sub next {
    my ($self) = @_;

    # get last subfield from 003@ as id
    if ( my $record = $self->next_record ) {
        my ($id) = map { $_->[-1] } grep { $_->[0] =~ '003@' } @{$record};
        return { _id => $id, record => $record };
    }

    return;
}

sub next_record {
    my ($self) = @_;
     
    my $line = $self->{reader}->getline // return;
    chomp $line;

    my @fields = split END_OF_FIELD, $line;
    my @record;

    if ($fields[0] !~ m/.*SUBFIELD_INDICATOR/){
        # drop leader because usage is unclear
        shift @fields;
    }
    
    foreach my $field (@fields) {
        my ($tag, $occurence, $data);
        if ($field =~ m/^(\d{3}[A-Z@])(\/(\d{2}))?\s(.*)/) {
            $tag       = $1;
            $occurence = $3 // '';
            $data      = $4;
        } else {
            croak 'ERROR: no valid PICA field structure';
        }
        my @subfields = map { substr( $_, 0, 1 ), substr( $_, 1 ) }
                        split( SUBFIELD_INDICATOR, substr( $data, 1 ) );
        push @record, [ $tag, $occurence, @subfields ];
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

=head2 new( $input )

Initialize parser to read from a given file, handle (e.g. L<IO::Handle>), or
string reference.

=head2 next

Reads the next PICA+ record. Returns a hash with keys C<_id> and C<record>.

=head2 next_record

Reads the next PICA+ record. Returns an array of field arrays.

=head1 SEEALSO

The counterpart of this module is L<PICA::Writer::Plus>.

See L<Catmandu::Importer::PICA> for usage of this module in L<Catmandu>.

An alternative writer had been implemented as L<PICA::PlainParser> included in
the release of L<PICA::Record>.

=cut

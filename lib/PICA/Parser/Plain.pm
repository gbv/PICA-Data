package PICA::Parser::Plain;
use strict;

our $VERSION = '0.21';

use charnames qw(:full);
use constant SUBFIELD_INDICATOR => '$';
use constant END_OF_FIELD       => "\N{LINE FEED}";
use constant END_OF_RECORD      => "\N{LINE FEED}";

use Carp qw(croak);

use parent 'PICA::Parser::Plus';

sub next_record {
    my ($self) = @_;

    my $plain = undef;
    while ( my $line = $self->{reader}->getline ) {
        last if $line =~ /^\s*$/;
        $plain .= $line;
    }
    return unless defined $plain;

    chomp $plain;
    my @fields = split END_OF_FIELD, $plain;
    my @record;
    
    for my $field (@fields) {

        my ( $tag, $occurence, $data );
        if ( $field =~ m/^(\d{3}[A-Z@])(\/(\d{2}))?\s(.*)/ ) {
            $tag       = $1;
            $occurence = $3 // '';
            $data      = $4;
        } else {
            croak 'ERROR: no valid PICA field structure';
        }

        my @subfields = split /\$([^\$])/, $data;
        shift @subfields;
        push @subfields, '' if @subfields % 2;

        push @record, [ $tag, $occurence, @subfields ];
    }
    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::Plain - Plain PICA+ format parser

=head1 SYNOPSIS

    use PICA::Parser::Plain;

    my $parser = PICA::Parser::Plain->new( $filename );

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

L<PICA::PlainParser>, included in the release of L<PICA::Record> implements
another PICA+ format parser, not aligned with the L<Catmandu> framework.

=cut

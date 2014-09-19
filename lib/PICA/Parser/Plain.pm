package PICA::Parser::Plain;
use strict;
use warnings;

our $VERSION = '0.23';

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

=head2 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and details.

The counterpart of this module is L<PICA::Writer::Plain>.

=cut

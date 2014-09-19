package PICA::Parser::Plus;
use strict;
use warnings;

our $VERSION = '0.23';

use charnames qw< :full >;
use Carp qw(croak);

use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{LINE FEED}";

use parent 'PICA::Parser::Base';

sub next_record {
    my ($self) = @_;
     
    # TODO: does only work if END_OF_RECORD is LINE FEED
    my $line = $self->{reader}->getline // return;
    chomp $line;

    my @fields = split END_OF_FIELD, $line;
    my @record;

    if (index($fields[0],SUBFIELD_INDICATOR) == -1) {
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

=head2 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and details.

The counterpart of this module is L<PICA::Writer::Plus>.

=cut

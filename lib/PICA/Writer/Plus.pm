package PICA::Writer::Plus;
use strict;
use warnings;

our $VERSION = '0.23';

use charnames qw(:full);
use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{LINE FEED}"; # or \N{INFORMATION SEPARATOR THREE}? I would prefer newline separated format

use parent 'PICA::Writer::Base';

sub _write_record {
    my ($self, $record) = @_;
    my $fh = $self->{fh};

    foreach my $field (@$record) {
        $fh->print($field->[0]);
        if (defined $field->[1] and $field->[1] ne '') {
            $fh->print("/".$field->[1]);
        }
        $fh->print(' ');
        for (my $i=2; $i<scalar @$field; $i+=2) {
            $fh->print(SUBFIELD_INDICATOR . $field->[$i] . $field->[$i+1]);
        }
        $fh->print(END_OF_FIELD);
    }
    $fh->print(END_OF_RECORD);
}

1;
__END__

=head1 NAME

PICA::Writer::Plus - Normalized PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plus>.

=cut

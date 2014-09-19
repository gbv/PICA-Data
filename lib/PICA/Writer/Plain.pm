package PICA::Writer::Plain;
use strict;
use warnings;

our $VERSION = '0.23';

use charnames qw(:full);
use constant SUBFIELD_INDICATOR => '$';
use constant END_OF_FIELD       => "\n";
use constant END_OF_RECORD      => "\n";

use parent 'PICA::Writer::Base';

sub _write_record {
    my ($self, $record) = @_;
    my $fh = $self->{fh};

    foreach my $field (@$record) {
        $fh->print($field->[0]);
        if (defined $field->[1] and $field->[1] ne '') {
            $fh->print("/".$field->[1]); # TODO: fix one-digit occ??
        }
        print $fh ' ';
        for (my $i=2; $i<scalar @$field; $i+=2) {
            my $value = $field->[$i+1];
            $value =~ s/\$/\$\$/g;
            $fh->print(SUBFIELD_INDICATOR . $field->[$i] . $value);
        }
        $fh->print(END_OF_FIELD);
    }
    $fh->print(END_OF_RECORD);
}

1;
__END__

=head1 NAME

PICA::Writer::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plain>.

=cut

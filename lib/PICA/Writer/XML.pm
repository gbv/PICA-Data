package PICA::Writer::XML;
use strict;

use Moo;
with 'PICA::Writer::Handle';

sub BUILD {
    $_[0]->start;
}

sub start {
    print {$_[0]->fh} "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print {$_[0]->fh} "<collection xlmns=\"info:srw/schema/5/picaXML-v1.0\">\n";
}

sub _write_record {
    my ($self, $record) = @_;
    my $fh = $self->fh;

    print $fh "<record>\n";
    foreach my $field (@$record) {
        # this will break on bad tag/occurrence values
        print $fh "  <datafield tag=\"$field->[0]\"" . ( 
                defined $field->[1] && $field->[1] ne '' ?
                " occurrence=\"$field->[1]\"" : ""
            ) . ">\n";
            for (my $i=2; $i<scalar @$field; $i+=2) {
                my $value = $field->[$i+1];
                $value =~ s/</&lt;/g;
                $value =~ s/&/&amp;/g;
                # TODO: disallowed code points (?)
                print $fh "    <subfield code=\"$field->[$i]\">$value</subfield>\n";
            } 
        print $fh "  </datafield>\n";
    }
    print $fh "</record>\n";
}

sub end {
    print {$_[0]->fh} "</collection>\n";
}

1;
__END__

=head1 NAME

PICA::Writer::XML - PICA+ XML format serializer

=cut

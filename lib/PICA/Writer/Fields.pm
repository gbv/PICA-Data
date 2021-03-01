package PICA::Writer::Fields;
use v5.14.1;

our $VERSION = '1.15';

use parent 'PICA::Writer::Base';

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $fh     = $self->{fh};
    my $seen   = $self->{seen} // ($self->{seen} = {});
    my $schema = $self->{schema};

    foreach my $field (@$record) {
        my ($tag, $occ) = @$field;

        $occ = '' if $tag =~ /^2/;

        my $id = $tag;
        $id .= sprintf("/%02d"), if defined $occ and $occ ne '';

        # TODO: lookup $id in schema to catch occurrence ranges
        next if $seen->{$id};
        $seen->{$id} = 1;

        $self->write_identifier([$tag, $occ]);

        if ($schema) {
            my $def = $schema->{fields}{$id};
            my $label = $def ? $def->{label} // '' : '?';
            $fh->print("\t" . $label =~ s/[\r\n]+/ /mgr);
        }

        $fh->print("\n");
    }
}

1;
__END__

=head1 NAME

PICA::Writer::Fields - Summarize fields used in PICA+ records

=head2 DESCRIPTION

This writer shows information about fields used in PICA+ records. Every field
is only shown once. A L<PICA::Schema> can be provided with argument C<schema>
to shown field labels, if included in the schema.

=cut

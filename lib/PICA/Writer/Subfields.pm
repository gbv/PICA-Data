package PICA::Writer::Subfields;
use v5.14.1;

our $VERSION = '1.22';

use parent 'PICA::Writer::Base';

use Scalar::Util qw(reftype);
use PICA::Schema qw(clean_pica field_identifier);

sub write_record {
    my ($self, $record) = @_;
    $record = clean_pica($record) or return;

    my $fh     = $self->{fh};
    my $seen   = $self->{seen} // ($self->{seen} = {});
    my $schema = $self->{schema};

    for my $field (@$record) {
        my $tag = field_identifier($schema ? $schema : (), $field);

        for (my $i = 2; $i < @$field; $i += 2) {
            my $code = $field->[$i];
            my $id   = "$tag\$$code";
            next if $seen->{$id};
            $seen->{$id} = 1;

            $fh->print($id);

            if ($schema) {
                my $def = eval {$schema->{fields}{$tag}{subfields}{$code}};
                my $label = $def ? $def->{label} // '' : '?';
                $fh->print("\t" . $label =~ s/[\r\n]+/ /mgr);
            }
            $fh->print("\n");
        }

    }
}

1;
__END__

=head1 NAME

PICA::Writer::Subfields - Summarize subfields used in PICA+ records

=head2 DESCRIPTION

This writer shows information about subfields used in PICA+ records. Every
subfield is only shown once. A L<PICA::Schema> can be provided with argument
C<schema> to shown field labels, if included in the schema.

See L<PICA::Writer::Fields> for corresponding writer for field information.

=cut

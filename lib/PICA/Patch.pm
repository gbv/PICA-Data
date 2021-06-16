package PICA::Patch;
use v5.14.1;

our $VERSION = '1.25';

use PICA::Schema qw(field_identifier);

use Exporter 'import';
our @EXPORT_OK = qw(pica_diff pica_patch);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# Compare full fields, ignoring annotation of the latter
# note this does not strip occurrence from level 2 records!
sub cmp_fields {
    my @a = @{$_[0]};
    my @b = @{$_[1]};
    pop @b if @b % 2;
    return join("\t", @a) cmp join("\t", @b);
}

sub sorted_fields {
    PICA::Data::pica_fields(PICA::Data::pica_sort(shift));
}

*annotation = *PICA::Data::pica_annotation;

sub pica_diff {
    my $a       = sorted_fields(shift);
    my $b       = sorted_fields(shift);
    my %options = @_;

    my (@diff, $i, $j);

    my $changed = sub {
        my @field = @{$_[0]};
        annotation(\@field, $_[1]);
        push @diff, \@field;
    };

    while ($i < @$a && $j < @$b) {
        my $cmp = cmp_fields($a->[$i], $b->[$j]);

        if ($cmp < 0) {
            $changed->($a->[$i++], '-');
        }
        elsif ($cmp > 0) {
            $changed->($b->[$j++], '+');
        }
        else {
            push @diff, $a->[$i] if $options{keep};
            $i++;
            $j++;
        }
    }
    while ($i < @$a) {
        $changed->($a->[$i++], '-');
    }
    while ($j < @$b) {
        $changed->($b->[$j++], '+');
    }

    bless {record => \@diff}, 'PICA::Data';
}

sub no_match {
    my $field = shift;
    annotation($field, undef);
    die "records don't match, expected: " . PICA::Data::pica_string([$field]);
}

sub pica_patch {
    my $fields = sorted_fields(shift);
    my $diff   = sorted_fields(shift);

    for (map {annotation($_)} @$diff) {
        die "invalid PICA Patch annotation: $_\n" if $_ !~ /^[ +-]$/;
    }

    my ($i, $j);
PATCH: while ($i < @$fields && $j < @$diff) {
        my $cur;
        my $next = field_identifier($diff->[$j]);
        my $ann  = annotation($diff->[$j]);

        # while current field is behind or same
        while (($cur = field_identifier($fields->[$i])) le $next) {
            if ($cur eq $next && !cmp_fields($fields->[$i], $diff->[$j])) {
                if ($ann eq '-') {
                    splice @$fields, $i, 1;
                    last PATCH if $j++ == @$diff or $i == @$fields;
                    next;
                }

                # Don't add fully identical fields so also skip '+'
            }

            # keep current field
            last PATCH if ++$i == @$fields;
        }

        # current field is ahead
        if ($ann eq '+') {
            my $add = $diff->[$j++];
            annotation($add, undef);
            splice @$fields, $i++, 0, $add;
        }
        else {
            no_match($diff->[$j]);
        }
    }

    while ($j < @$diff) {
        if (annotation($diff->[$j]) eq '+') {
            $fields->[$i] = $diff->[$j++];
            annotation($fields->[$i++], undef);
        }
        else {
            no_match($diff->[$j]);
        }
    }

    bless {record => $fields}, 'PICA::Data';
}
1;
__END__

=head1 NAME

PICA::Patch - Implementation of PICA diff and patch

=head1 DESCRIPTION

This file contains the implementation of diff and patch algorithm for PICA+
records.  See functions C<pica_diff> and C<pica_patch> (or object methods
C<diff> and C<patch>) of L<PICA::Data> for usage.

Both diff and patch use annotated PICA records to express differences between
PICA records or changes to be applied to a PICA record (which is basically the
same). Fields can be annotated with:

=over

=item B<+>

To denote a field that should be added.

=item B<->

To denote a field that should be removed.

=item B<blank>

To denote a field that should be kept as it is.

=back

Modification of a field is expressed by removal of the old version followed by
addition of the new version.

Records are always sorted before application of diff or patch.

Modification of records that span multiple levels or records that subsume
multiple sub-records is I<not recommended>.

=cut
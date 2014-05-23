package Catmandu::Fix::pica_map;

# ABSTRACT: copy mab values of one field to a new field
# VERSION

use Catmandu::Sane;
use Carp qw(confess);
use Moo;

use Catmandu::Fix::Has;

has pica_path => ( fix_arg => 1 );
has path      => ( fix_arg => 1 );
has record    => ( fix_opt => 1 );
has split     => ( fix_opt => 1 );
has join      => ( fix_opt => 1 );
has value     => ( fix_opt => 1 );

sub emit {
    my ( $self, $fixer ) = @_;
    my $path       = $fixer->split_path( $self->path );
    my $record_key = $fixer->emit_string( $self->record // 'record' );
    my $join_char  = $fixer->emit_string( $self->join // '' );
    my $pica_path  = $self->pica_path;

    my $field_regex;
    my ( $field, $occurence, $subfield_regex, $from, $to );

    if ( $pica_path
        =~ /(\d{3}\S)(\[(\d{2})\])?([_A-Za-z0-9]+)?(\/(\d+)(-(\d+))?)?/ )
    {
        $field          = $1;
        $occurence      = $3;
        $subfield_regex = defined $4 ? "[$4]" : "[_A-Za-z0-9]";
        $from           = $6;
        $to             = $8;
    }
    else {
        confess "invalid pica path";
    }

    $field_regex = $field;
    $field_regex =~ s/\*/./g;

    my $var  = $fixer->var;
    my $vals = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars( $vals, '[]' );

    $perl .= $fixer->emit_foreach(
        "${var}->{${record_key}}",
        sub {
            my $var  = shift;
            my $v    = $fixer->generate_var;
            my $perl = "";

            $perl .= "next if ${var}->[0] !~ /${field_regex}/;";

            if ( $self->value ) {
                $perl .= $fixer->emit_declare_vars( $v,
                    $fixer->emit_string( $self->value ) );
            }
            else {
                my $i = $fixer->generate_var;
                my $add_subfields = sub {
                    my $start = shift;
                    "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {"
                        . "if (${var}->[${i}] =~ /${subfield_regex}/) {"
                        . "push(\@{${v}}, ${var}->[${i} + 1]);" . "}" . "}";
                };
                $perl .= $fixer->emit_declare_vars( $v, "[]" );
                $perl .= $add_subfields->(2);
                $perl .= "if (\@{${v}}) {";
                if ( !$self->split ) {
                    $perl .= "${v} = join(${join_char}, \@{${v}});";
                    if ( defined( my $off = $from ) ) {
                        my $len = defined $to ? $to - $off + 1 : 1;
                        $perl .= "if (eval { ${v} = substr(${v}, ${off}, ${len}); 1 }) {";
                    }
                }
                $perl .= $fixer->emit_create_path(
                    $fixer->var,
                    $path,
                    sub {
                        my $var = shift;
                        if ( $self->split ) {
                            "if (is_array_ref(${var})) {"
                                . "push \@{${var}}, ${v};"
                                . "} else {"
                                . "${var} = [${v}];" . "}";
                        }
                        else {
                            "if (is_string(${var})) {"
                                . "${var} = join(${join_char}, ${var}, ${v});"
                                . "} else {"
                                . "${var} = ${v};" . "}";
                        }
                    }
                );
                if ( defined($from) ) {
                    $perl .= "}";
                }
                $perl .= "}";
            }
            $perl;
        }
    );

    $perl;
}

1;

=head1 SYNOPSIS

    # Copy from field 003@ subfield 0 to dc.identifier hash
    pica_map('003A0','dc.identifier');

    # Copy from field 003@ subfield 0 to dc.identifier hash
    pica_map('010@a','dc.language');

    # Copy from field 009Q subfield a to foaf.primaryTopicOf array
    pica_map('009Qa','foaf.primaryTopicOf.$append');

    # Copy from field 028A subfields a and d to dc.creator hash joining them by ' '
    pica_map('028Aad','dcterms.creator', -join => ' ');

    # Copy from field 028A with ocurrance subfields a and d to dc.contributor hash joining them by ' '
    pica_map('028B[01]ad','dcterms.ccontributor', -join => ' ');

=cut

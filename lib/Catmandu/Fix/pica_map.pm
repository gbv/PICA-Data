package Catmandu::Fix::pica_map;
# ABSTRACT: copy mab values of one field to a new field
# VERSION

use Catmandu::Sane;
use Catmandu::Util qw(:is :data);
use Data::Dumper;
use Moo;

has path  => ( is => 'ro', required => 1 );
has key   => ( is => 'ro', required => 1 );
has mpath => ( is => 'ro', required => 1 );
has opts  => ( is => 'ro' );

around BUILDARGS => sub {
    my ( $orig, $class, $mpath, $path, %opts ) = @_;
    my ( $p, $key ) = parse_data_path($path) if defined $path && length $path;
    $orig->(
        $class,
        path  => $p,
        key   => $key,
        mpath => $mpath,
        opts  => \%opts
    );
};

sub fix {
    my ( $self, $data ) = @_;

    my $path  = $self->path;
    my $key   = $self->key;
    my $mpath = $self->mpath;
    my $opts  = $self->opts || {};
    $opts->{-join} = '' unless $opts->{-join};

    my $pica_pointer = $opts->{-record} || 'record';
    my $pica = $data->{$pica_pointer};

    my $fields = pica_field( $pica, $mpath );

    return $data if !@{$fields};

    my $match
        = [ grep ref, data_at( $path, $data, key => $key, create => 1 ) ]
        ->[0];

    for my $field (@$fields) {
        my $field_value = pica_subfield( $field, $mpath );

        next if is_empty($field_value);

        $field_value = [ $opts->{-value} ] if defined $opts->{-value};
        $field_value = join $opts->{-join}, @$field_value
            if defined $opts->{-join};
        $field_value = create_path( $opts->{-in}, $field_value )
            if defined $opts->{-in};
        $field_value = path_substr( $mpath, $field_value )
            unless index( $mpath, '/' ) == -1;

        if ( is_array_ref($match) ) {
            if ( is_integer($key) ) {
                $match->[$key] = $field_value;
            }
            else {
                push @{$match}, $field_value;
            }
        }
        else {
            if ( exists $match->{$key} ) {
                $match->{$key} .= $opts->{-join} . $field_value;
            }
            else {
                $match->{$key} = $field_value;
            }
        }
    }
    $data;
}

sub is_empty {
    my ($ref) = shift;
    for (@$ref) {
        return 0 if defined $_;
    }
    return 1;
}

sub path_substr {
    my ( $path, $value ) = @_;
    return $value unless is_string($value);
    if ( $path =~ /\/(\d+)(-(\d+))?/ ) {
        my $from = $1;
        my $to = defined $3 ? $3 - $from + 1 : 0;
        return substr( $value, $from, $to );
    }
    return $value;
}

sub create_path {
    my ( $path, $value ) = @_;
    my ( $p, $key, $guard ) = parse_data_path($path);
    my $leaf  = {};
    my $match = [
        grep ref,
        data_at( $p, $leaf, key => $key, guard => $guard, create => 1 )
    ]->[0];
    $match->{$key} = $value;
    $leaf;
}

# Parse a pica_path into parts
# 028B[01]ad    - field=028B, occurrence=01, subfields = a,d
# 001A0/5-13    - field=008, substring 5 to 13
sub parse_pica_path {
    my $path = shift;

    # more than 1 occurrence allowed:
    if ( $path =~ /(\d{3}\S)(\[(\d{2})\])?([_A-Za-z0-9]+)?(\/(\d+)(-(\d+))?)?/ ) {
        my $field    = $1;
        my $occurrence = $3;
        my $subfield = $4 ? "[$4]" : "[_A-Za-z0-9]";
        my $from     = $6;
        my $to       = $8;
        return {
            field    => $field,
            occurrence => $occurrence,
            subfield => $subfield,
            from     => $from,
            to       => $to
        };
    }
    else {
        return {};
    }
}

# Given a Catmandu::Importer::PICA item return for each matching field the
# array of subfields
# Usage: pica_field($data,'003@');
sub pica_field {
    my ( $pica_item, $path ) = @_;
    my $pica_path = parse_pica_path($path);
    my @results  = ();

    my $field = $pica_path->{field};
    $field =~ s/\*/./g;

    for (@$pica_item) {
        my ( $tag, $occurrence, @subfields ) = @$_;
        if ( $tag =~ /$field/ ) {
            if ( $pica_path->{occurrence} ) {
                push( @results, \@subfields ) if $pica_path->{occurrence} =~ /$occurrence/;
            }
            else {
                push( @results, \@subfields );
            }

        }
    }
    return \@results;
}

# Given a subarray of Catmandu::Importer::MAB subfields return all
# the subfields that match the $subfield regex
# Usage: pica_subfield($subfields,'[a]');
sub pica_subfield {
    my ( $subfields, $path ) = @_;
    my $pica_path = &parse_pica_path($path);
    my $regex    = $pica_path->{subfield};

    my @results = ();

    for ( my $i = 0; $i < @$subfields; $i += 2 ) {
        my $code = $subfields->[$i];
        my $val  = $subfields->[ $i + 1 ];
        push( @results, $val ) if $code =~ /$regex/;
    }
    return \@results;
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

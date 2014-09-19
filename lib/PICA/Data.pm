package PICA::Data;
use strict;
use warnings;

our $VERSION = '0.23';

use Exporter 'import';
our @EXPORT_OK = map { "pica_$_" } 
                 qw(parser writer values value fields holdings items path);
our %EXPORT_TAGS = (all => [@EXPORT_OK]); 

our $ILN_PATH = PICA::Path->new('101@a');
our $EPN_PATH = PICA::Path->new('203@/**0');

use Carp qw(croak);
use Scalar::Util qw(reftype);
use List::Util qw(first);
use IO::Handle;
use PICA::Path;

sub pica_values {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return unless ref $path;

    my @values;

    foreach my $field (grep { $path->match_field($_) } @$record) {
        push @values, $path->match_subfields($field);
    }

    return @values;
}

sub pica_fields {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return [] unless defined $path;

    return [ grep { $path->match_field($_) } @$record ];
}

sub pica_value {
    my ($record, $path) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    $path = eval { PICA::Path->new($path) } unless ref $path;
    return unless defined $path;

    foreach my $field (@$record) {
        next unless $path->match_field($field);
        my @values = $path->match_subfields($field);
        return $values[0] if @values;
    }

    return;
}

sub pica_items {
    my ($record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    my (@items, $current, $occurrence);

    foreach my $field (@$record) {
        if ($field->[0] =~ /^2/) {
            
            if ( ($occurrence // '') ne $field->[1] ) {
                if ($current) {
                    push @items, $current;
                    $current = undef;
                }
                $occurrence = $field->[1];
            }
            
            $current //= { record => [] };

            push @{$current->{record}}, [ @$field ];
            if ($field->[0] eq '203@') {
                ($current->{_id}) = $EPN_PATH->match_subfields($field);
            }
        } elsif ($current) {
            push @items, $current;
            $current    = undef;
            $occurrence = undef;
        }
    }

    push @items, $current if $current;

    return \@items;
}

sub pica_holdings {
    my ($record) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';
    my (@holdings, $field_buffer, $iln);

    foreach my $field (@$record) {
        my $tag = substr $field->[0], 0, 1;
        if ($tag eq '0') {
            next;
        } elsif ($tag eq '1') {
            if ($field->[0] eq '101@') {
                my ($id) = $ILN_PATH->match_subfields($field);
                if ( defined $iln && ($id // '') ne $iln ) {
                    push @holdings, { record => $field_buffer, _id => $iln };
                }
                $field_buffer = [ [@$field] ];
                $iln = $id;
                next;
            }
        }
        push @$field_buffer, [@$field];
    }

    if (@$field_buffer) {
        push @holdings, { record => $field_buffer, _id => $iln };
    }

    return \@holdings;
}

*values   = *pica_values;
*value    = *pica_value;
*fields   = *pica_fields;
*holdings = *pica_holdings;
*items    = *pica_items;

use PICA::Parser::XML;
use PICA::Parser::Plus;
use PICA::Parser::Plain;
use PICA::Writer::XML;
use PICA::Writer::Plus;
use PICA::Writer::Plain;

sub pica_parser {
    _pica_module('PICA::Parser', @_)
}

sub pica_writer {
    _pica_module('PICA::Writer', @_)
}

sub pica_path {
    PICA::Path->new(@_)
}

sub _pica_module {
    my $base = shift;
    my $type = lc(shift) // '';

    if ( $type =~ /^(pica)?plus$/ ) {
        "${base}::Plus"->new(@_);
    } elsif ( $type =~ /^(pica)?plain$/ ) {
        "${base}::Plain"->new(@_);
    } elsif ( $type =~ /^(pica)?xml$/ ) {
        "${base}::XML"->new(@_);
    } else {
        croak "unknown PICA parser type: $type";
    }
}

1;
__END__

=head1 NAME

PICA::Data - PICA record processing

=begin markdown 

[![Build Status](https://travis-ci.org/gbv/PICA-Data.png)](https://travis-ci.org/gbv/PICA-Data)
[![Coverage Status](https://coveralls.io/repos/gbv/PICA-Data/badge.png)](https://coveralls.io/r/gbv/PICA-Data)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/PICA-Data.png)](http://cpants.cpanauthors.org/dist/PICA-Data)

=end markdown

=head1 SYNOPSIS

    use PICA::Data ':all';
    $parser = pica_parser( xml => @options );
    $writer = pica_writer( plain => @options );
   
    use PICA::Parser::XML;
    use PICA::Writer::Plain;
    $parser = PICA::Parser::XML->new( @options );
    $writer = PICA::Writer::Plain->new( @options );

    while ( my $record = $parser->next ) {
        my $ppn      = pica_value($record, '003@0'); # == $record->{_id}
        my $holdings = pica_holdings($record);
        my $items    = pica_holdings($record);
        ...
    }
  
    # parse single record from string
    my $record = pica_parser('plain', \"...")->next;

=head1 DESCRIPTION

PICA::Data provides methods, classes, and functions to process PICA+ records
in Perl.

PICA+ is the internal data format of the Local Library System (LBS) and the
Central Library System (CBS) of OCLC, formerly PICA. Similar library formats
are the MAchine Readable Cataloging format (MARC) and the Maschinelles
Austauschformat fuer Bibliotheken (MAB). In addition to PICA+ in CBS there is
the cataloging format Pica3 which can losslessly be convert to PICA+ and vice
versa.

Records in PICA::Data are encoded either as as array of arrays, the inner
arrays representing PICA fields, or as an object with two fields, C<_id> and
C<record>, the latter holding the record as array of arrays, and the former
holding the record identifier, stored in field C<003@>, subfield C<0>. For
instance a minimal record with just one field C<003@>:

    {
      _id    => '12345X',
      record => [
        [ '003@', undef, '0' => '12345X' ]
      ]
    }

or in short form:

    [ [ '003@', undef, '0' => '12345X' ] ]

PICA path expressions can be used to facilitate processing PICA+ records.

=head1 CONSTRUCTORS

=head2 pica_parser( $type [, @options] )

Create a PICA parsers object. Case of the type is ignored and additional
parameters are passed to the parser's constructor.

=over

=item 

L<PICA::Parser::XML> for type C<xml> or C<picaxml> (PICA-XML)

=item 

L<PICA::Parser::Plus> for type C<plus> or C<picaplus> (normalized PICA+)

=item 

L<PICA::Parser::Plain> for type C<plain> or C<picaplain> (human-readable PICA+)

=back

=head2 pica_writer( $type [, @options] )

Create a PICA writer object in the same way as C<pica_parser> with one of

=over

=item 

L<PICA::Writer::XML> for type C<xml> or C<picaxml> (PICA-XML)


=item 

L<PICA::Writer::Plus> for type C<plus> or C<picaplus> (normalized PICA+)

=item 

L<PICA::Writer::Plain> for type C<plain> or C<picaplain> (human-readable PICA+)

=back

=head2 pica_path( $path )

Equivalent to C<< PICA::Path->new($path) >>.

=head1 ACCESSORS

The following function can also be called as method on a blessed PICA::Data
record by stripping the C<pica_...> prefix:

    bless $record, 'PICA::Data';
    $record->values($path);
    $record->items;
    ...

=head2 pica_values( $record, $path )

Extract a list of subfield values from a PICA record based on a PICA path
expression.

=head2 pica_value( $record, $path )

Same as C<pica_values> but only returns the first value. Can also be called as
C<value> on a blessed PICA::Data record.

=head2 pica_fields( $record, $path )

Returns a PICA record limited to fields specified in a PICA path expression.
Always returns an array reference. Can also be called as C<fields> on a blessed
PICA::Data record. 

=head2 pica_holdings( $record )

Returns a list (as array reference) of local holding records (level 1 and 2),
where the C<_id> of each record contains the ILN (subfield C<101@a>).

=head2 pica_items( $record )

Returns a list (as array reference) of item records (level 1),
where the C<_id> of each record contains the EPN (subfield C<203@/**0>).
 
=head1 CONTRIBUTORS

Johann Rolschewski, C<< <rolschewski@gmail.com> >>

Jakob Voss C<< <voss@gbv.de> >>

=head1 COPYRIGHT

Copyright 2014- Johann Rolschewski and Jakob Voss

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

Use L<Catmandu::PICA> for processing PICA records with the L<Catmandu> toolkit,
for instance to convert PICA XML to plain PICA+:

   catmandu convert PICA --type xml to PICA --type plain < picadata.xml

L<PICA::Record> implements an alternative framework for processing PICA+
records but development of the module is stalled.

=cut

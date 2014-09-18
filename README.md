# NAME

PICA::Data - PICA record processing

[![Build Status](https://travis-ci.org/gbv/PICA-Data.png)](https://travis-ci.org/gbv/PICA-Data)
[![Coverage Status](https://coveralls.io/repos/gbv/PICA-Data/badge.png)](https://coveralls.io/r/gbv/PICA-Data)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/PICA-Data.png)](http://cpants.cpanauthors.org/dist/PICA-Data)

# SYNOPSIS

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


# DESCRIPTION

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

# FUNCTIONS

## pica\_parser( $type \[, @options\] )

Create a PICA parsers object. Case of the type is ignored and additional
parameters are passed to the parser's constructor.

- [PICA::Parser::XML](https://metacpan.org/pod/PICA::Parser::XML)

    Type `xml` or `picaxml` for PICA+ in XML

- [PICA::Parser::Plus](https://metacpan.org/pod/PICA::Parser::Plus)

    Type `plus` or `picaplus` for normalizes PICA+

- [PICA::Parser::Plain](https://metacpan.org/pod/PICA::Parser::Plain)

    Type `plain` for plain, human-readable PICA+

## pica\_writer( $type \[, @options\] )

Create a PICA writer object in the same way as `pica_parser` with one of

- [PICA::Writer::XML](https://metacpan.org/pod/PICA::Writer::XML)
- [PICA::Writer::Plus](https://metacpan.org/pod/PICA::Writer::Plus)
- [PICA::Writer::Plain](https://metacpan.org/pod/PICA::Writer::Plain)

## pica\_values( $record, $path )

Extract a list of subfield values from a PICA record based on a PICA path
expression.

## pica\_value( $record, $path )

Same as `pica_values` but only returns the first value. Can also be called as
`value` on a blessed PICA::Data record.

## pica\_fields( $record, $path )

Returns a PICA record limited to fields specified in a PICA path expression.
Always returns an array reference. Can also be called as `fields` on a blessed
PICA::Data record. 

## pica\_holdings( $record )

Returns a list (as array reference) of local holding records (level 1 and 2),
where the `_id` of each record contains the ILN (subfield `101@a`).

## pica\_items( $record )

Returns a list (as array reference) of item records (level 1),
where the `_id` of each record contains the EPN (subfield `203@/**0`).

## pica\_items( $record )

## pica\_path( $path )

Equivalent to `PICA::Path->new($path)`.

# OBJECT ORIENTED INTERFACE

All `pica_...` function that expect a record as first argument can also be called 
as method on a blessed PICA::Data record by stripping the `pica_...` prefix:

    bless $record, 'PICA::Data';
    $record->values($path);
    $record->items;
    ...

# CONTRIBUTORS

Johann Rolschewski, `<rolschewski@gmail.com>`

Jakob Voss `<voss@gbv.de>`

# COPYRIGHT

Copyright 2014- Johann Rolschewski and Jakob Voss

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

Use [Catmandu::PICA](https://metacpan.org/pod/Catmandu::PICA) for processing PICA records with the [Catmandu](https://metacpan.org/pod/Catmandu) toolkit,
for instance to convert PICA XML to plain PICA+:

    catmandu convert PICA --type xml to PICA --type plain < picadata.xml

[PICA::Record](https://metacpan.org/pod/PICA::Record) implements an alternative framework for processing PICA+
records but development of the module is stalled.

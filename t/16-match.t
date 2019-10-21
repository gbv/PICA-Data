use strict;
use warnings;
use Test::More;

my $pkg;

BEGIN {
    $pkg = 'PICA::Path';
    use_ok $pkg;
}

require_ok $pkg;

my $record = {
    record => [
        [ '005A', '', '0', '1234-5678' ],
        [ '005A', '', '0', '1011-1213' ],
        [   '009Q', '', 'u', 'http://example.org/', 'x', 'A', 'z', 'B', 'z',
            'C'
        ],
        [ '021A', '', 'a', 'Title', 'd', 'Supplement' ],
        [   '031N', '',     'j', '1600', 'k', '1700',
            'j',    '1800', 'k', '1900', 'j', '2000'
        ],
        [ '045F', '01', 'a', '001' ],
        [ '045F', '02', 'a', '002' ],
        [ '045U', '', 'e', '003', 'e', '004' ],
        [ '045U', '', 'e', '005' ]
    ],
    _id => 1234
};

note('Single field, no subfield repetition');

{
    my $path  = PICA::Path->new('021A');
    my $match = $path->match($record);
    is( $match, 'TitleSupplement', 'match field' );
}

{
    my $path  = PICA::Path->new('021Aa');
    my $match = $path->match($record);
    is( $match, 'Title', 'match subfield' );
}

{
    my $path  = PICA::Path->new('021Aad');
    my $match = $path->match($record);
    is( $match, 'TitleSupplement', 'match subfields' );
}

{
    my $path  = PICA::Path->new('021Ada');
    my $match = $path->match($record);
    is( $match, 'TitleSupplement', 'match subfields' );
}

{
    my $path = PICA::Path->new('021Ada');
    my $match = $path->match( $record, { pluck => 1 } );
    is( $match, 'SupplementTitle', 'match subfields pluck' );
}

{
    my $path = PICA::Path->new('021Ada');
    my $match = $path->match( $record, { pluck => 1, join => ' ' } );
    is( $match, 'Supplement Title', 'match subfields pluck join' );
}

{
    my $path = PICA::Path->new('021A');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ 'Title', 'Supplement' ], 'match field split' );
}

{
    my $path = PICA::Path->new('021A');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [ [ 'Title', 'Supplement' ] ],
        'match field split nested_arrays'
    );
}

note('Single field, repeated subfields');

{
    my $path  = PICA::Path->new('009Q');
    my $match = $path->match($record);
    is( $match, 'http://example.org/ABC', 'match field' );
}

{
    my $path  = PICA::Path->new('009Qz');
    my $match = $path->match($record);
    is( $match, 'BC', 'match subfield' );
}

{
    my $path = PICA::Path->new('009Q');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply(
        $match,
        [ 'http://example.org/', 'A', 'B', 'C' ],
        'match field split'
    );
}

{
    my $path = PICA::Path->new('009Qz');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ 'B', 'C' ], 'match subfield split' );
}

{
    my $path = PICA::Path->new('009Qxz');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ 'A', 'B', 'C' ], 'match subfields split' );
}

{
    my $path = PICA::Path->new('009Qz');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [ [ 'B', 'C' ] ],
        'match subfield split nested_arrays'
    );
}

note('Repeated Field, no subfield repetition');

{
    my $path  = PICA::Path->new('005A');
    my $match = $path->match($record);
    is( $match, '1234-56781011-1213', 'match field' );
}

{
    my $path  = PICA::Path->new('005A0');
    my $match = $path->match($record);
    is( $match, '1234-56781011-1213', 'match subfield' );
}

{
    my $path = PICA::Path->new('005A');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ '1234-5678', '1011-1213' ], 'match field split' );
}

{
    my $path = PICA::Path->new('005A0');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ '1234-5678', '1011-1213' ], 'match subfield split' );
}

{
    my $path = PICA::Path->new('005A');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [ ['1234-5678'], ['1011-1213'] ],
        'match field split nested_arrays'
    );
}

note('Repeated field with repeated subfields');

{
    my $path  = PICA::Path->new('045U');
    my $match = $path->match($record);
    is( $match, '003004005', 'match field' );
}

{
    my $path  = PICA::Path->new('045Ue');
    my $match = $path->match($record);
    is( $match, '003004005', 'match subfield' );
}

{
    my $path = PICA::Path->new('045U');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ '003', '004', '005' ], 'match field split' );
}

{
    my $path = PICA::Path->new('045Ue');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ '003', '004', '005' ], 'match subfield split' );
}

{
    my $path = PICA::Path->new('045U');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [ [ '003', '004' ], ['005'] ],
        'match field split nested_arrays'
    );
}

note('Repeated field with occurrence');

{
    my $path  = PICA::Path->new('045F[01]');
    my $match = $path->match($record);
    is( $match, '001', 'match field occurence' );
}

{
    my $path = PICA::Path->new('045F[0.]');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ '001', '002' ], 'match field occurence split' );
}

note('Referencing the whole record');

{
    my $path  = PICA::Path->new('....');
    my $match = $path->match($record);
    is( $match,
        '1234-56781011-1213http://example.org/ABCTitleSupplement16001700180019002000001002003004005',
        'match field'
    );
}

{
    my $path  = PICA::Path->new('....a');
    my $match = $path->match($record);
    is( $match, 'Title001002', 'match subfield' );
}

{
    my $path = PICA::Path->new('....');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply(
        $match,
        [   "1234-5678",           "1011-1213",
            "http://example.org/", "A",
            "B",                   "C",
            "Title",               "Supplement",
            1600,                  1700,
            1800,                  1900,
            2000,                  "001",
            "002",                 "003",
            "004",                 "005"
        ],
        'match field split'
    );
}

{
    my $path = PICA::Path->new('....a');
    my $match = $path->match( $record, { split => 1 } );
    is_deeply( $match, [ "Title", "001", "002" ], 'match subfield split' );
}

{
    my $path = PICA::Path->new('....');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [   ["1234-5678"],
            ["1011-1213"],
            [ "http://example.org/", "A", "B", "C", ],
            [ "Title",               "Supplement" ],
            [ 1600, 1700, 1800, 1900, 2000, ],
            ["001"],
            ["002"],
            [ "003", "004" ],
            ["005"]
        ],
        'match field split nested_arrays'
    );
}

{
    my $path = PICA::Path->new('....a');
    my $match = $path->match( $record, { split => 1, nested_arrays => 1 } );
    is_deeply(
        $match,
        [ ["Title"], ["001"], ["002"] ],
        'match subfield split nested_arrays'
    );
}

note('Subtsring from field');

{
    my $path  = PICA::Path->new('021A/0-');
    my $match = $path->match($record);
    is( $match, 'TitleSupplement', 'match field substring' );
}

{
    my $path  = PICA::Path->new('021A/0-1');
    my $match = $path->match($record);
    is( $match, 'TiSu', 'match field substring' );
}

{
    my $path = PICA::Path->new('021Ada/0-1');
    my $match = $path->match( $record, { pluck => 1 } );
    is( $match, 'SuTi', 'match subfields substring pluck' );
}

{
    my $path = PICA::Path->new('021Ada/0-');
    my $match = $path->match( $record, { pluck => 1, split => 1 } );
    is_deeply(
        $match,
        [ 'Supplement', 'Title' ],
        'match substring subfields pluck split'
    );
}

done_testing();

package App::picadata;
use v5.14.1;

use Getopt::Long qw(GetOptionsFromArray :config bundling);
use Pod::Usage;
use PICA::Data;
use PICA::Schema;
use PICA::Schema::Builder;
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Scalar::Util qw(reftype);
use HTTP::Tiny;
use JSON::PP;
use List::Util 'sum';

sub new {
    my ($class, @argv) = @_;

    my $interactive = -t *STDOUT;
    my $help = !@argv && $interactive;

    my $number = 0;
    if (my ($i) = grep {$argv[$_] =~ /^-(\d+)$/} (0 .. @argv - 1)) {
        $number = -(splice @argv, $i, 1);
    }

    my $abbrev     = grep {$_ eq '-B'} @argv;
    my $noAnnotate = grep {$_ eq '-A'} @argv;

    my @path;

    my $opt = {
        number => \$number,
        help   => \$help,
        path   => \@path,
        schema => sub {
            my $schema = $_[1];
            my $json;
            if ($schema =~ qr{^https?://}) {
                my $res = HTTP::Tiny->new->get($schema);
                die "HTTP request failed: $schema\n" unless $res->{success};
                $json = $res->{content};
            }
            else {
                open(my $fh, "<", $schema)
                    or die "Failed to open schema file: $schema\n";
                $json = join "\n", <$fh>;
            }
            return PICA::Schema->new(decode_json($json));
        },
    };

    GetOptionsFromArray(
        \@argv,       $opt,           'from|f=s',  'to|t:s',
        'schema|s=s', 'annotate|A|a', 'build|B|b', 'unknown|u!',
        'count|c',    'order|o',      'path|p=s',  "number|n:i",
        'color|C',    'mono|M',       'help|h|?',  'version|V',
    ) or $opt->{failed} = 1;

    $opt->{number}   = $number;
    $opt->{help}     = $help;
    $opt->{annotate} = 0 if $noAnnotate;
    $opt->{abbrev}   = $abbrev if $abbrev;
    $opt->{color}    = !$opt->{mono} && ($opt->{color} || $interactive);
    $opt->{argv}     = \@argv;

    delete $opt->{schema} if reftype $opt->{schema} eq 'CODE';

    if (!@path) {
        my $pattern = '[012.][0-9.][0-9.][A-Z@.](\$[^|]+)?';
        while (@argv && $argv[0] =~ /^$pattern(\s*\|\s*($pattern)?)*$/) {
            push @path, shift @argv;
        }
    }
    if (@path) {
        @path = map {
            my $p = eval {PICA::Path->new($_)};
            $p || die "invalid PICA Path: $_\n";
        } grep {$_ ne ""} map {split /\s*\|\s*/, $_} @path;
    }

    bless $opt, $class;
}

my %types = (
    bin       => 'Binary',
    dat       => 'Binary',
    binary    => 'Binary',
    extpp     => 'Binary',
    ext       => 'Binary',
    plain     => 'Plain',
    pp        => 'Plain',
    plus      => 'Plus',
    norm      => 'Plus',
    normpp    => 'Plus',
    xml       => 'XML',
    ppxml     => 'PPXML',
    json      => 'JSON',
    ndjson    => 'JSON',
    fields    => 'Fields',
    f         => 'Fields',
    subfields => 'Subfields',
    sf        => 'Subfields',
);

sub run {
    my ($self) = @_;

    pod2usage(2) if $self->{failed};
    pod2usage(-verbose => 99, -sections => "SYNOPSIS|OPTIONS|DESCRIPTION")
        if $self->{help};

    if ($self->{version}) {
        say $PICA::Data::VERSION;
        exit
    }

    my @argv     = @{$self->{argv}};
    my $from     = $self->{from};
    my $to       = $self->{to};
    my $schema   = $self->{schema};
    my $build    = $self->{build};
    my $count    = $self->{count};
    my $annotate = $self->{annotate};

    my $input = '-';

    my @pathes = @{$self->{path} || []};
    my $sfpath = sum map {length $_->subfields > 0} @pathes;
    die "PICA Path must either all select fields or select subfields!\n"
        if $sfpath and $sfpath ne @pathes;

    $input = shift @argv if @argv;

    $from = $1 if !$from && $input =~ /\.([a-z]+)$/ && $types{lc $1};

    $from = 'plain' unless $from;
    pod2usage("unknown serialization type: $from") unless $types{lc $from};

    $to = $from
        unless ($to
        or $count
        or ($schema && !$annotate)
        or $build
        or $sfpath);
    pod2usage("unknown serialization type: $to")
        unless !$to
        or $types{lc $to};

    $build = PICA::Schema::Builder->new if $build;

    if ($input eq '-') {
        $input = *STDIN;
        binmode $input, ':encoding(UTF-8)';
    }
    my $parser = "PICA::Parser::${types{$from}}"->new($input, bless => 1);

    my $writer;
    binmode *STDOUT, ':encoding(UTF-8)';
    if ($to) {
        $writer = "PICA::Writer::${types{$to}}";
        $writer = $writer->new(
            color => (
                $self->{color}
                ? {
                    tag        => 'blue',
                    occurrence => 'blue',
                    code       => 'red',
                    value      => 'green'
                    }
                : undef
            ),
            schema   => $schema,
            annotate => $annotate
        );
    }

    my %schema_options
        = (ignore_unknown => !$self->{unknown}, annotate => $annotate);
    my $stats   = {records => 0, holdings => 0, items => 0, fields => 0};
    my $invalid = 0;
    my $number  = $self->{number};

    while (my $record = $parser->next) {
        if ($sfpath) {
            say $_ for map {@{$record->match($_, split => 1) // []}} @pathes;
        }

        $record = $record->sort if $self->{order};
        $record = {record => $record->fields(@pathes)} if @pathes;

        next unless @{$record->{record}};    # ignore empty records

        if ($schema && $to ne 'fields') {
            my @errors = $schema->check($record, %schema_options);
            if (@errors) {
                unless ($annotate) {
                    say(defined $record->{_id} ? $record->{_id} . ": $_" : $_)
                        for @errors;
                }
                $invalid++;
            }
        }
        $writer->write($record) if $writer;
        $build->add($record)    if $build;

        if ($count) {
            $stats->{holdings} += @{$record->holdings};
            $stats->{items}    += @{$record->items};
            $stats->{fields}   += @{$record->{record}};
        }
        $stats->{records}++;
        last if $number and $stats->{records} >= $number;
    }

    $writer->end() if $writer;

    if ($count) {
        $stats->{invalid} = $invalid;
        say $stats->{$_} . " $_"
            for grep {$stats->{$_}} qw(records invalid holdings items fields);
    }

    if ($build) {
        my $schema = $build->schema;
        print JSON::PP->new->indent->space_after->canonical->convert_blessed
            ->encode($self->{abbrev} ? $schema->abbreviated : $schema);
    }

    return !!$invalid;
}

=head1 NAME

App::picadata - Implementation of picadata command line application.

=head1 DESCRIPTION

This package implements the L<picadata> command line application.

=cut

1;

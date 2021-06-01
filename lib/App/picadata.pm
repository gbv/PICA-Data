package App::picadata;
use v5.14.1;

use Getopt::Long qw(GetOptionsFromArray :config bundling);
use Pod::Usage;
use PICA::Data qw(pica_parser pica_writer);
use PICA::Schema;
use PICA::Schema::Builder;
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Scalar::Util qw(reftype);
use JSON::PP;
use List::Util qw(any all);
use Text::Abbrev;

my %TYPES = (
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

my %COLORS
    = (tag => 'blue', occurrence => 'blue', code => 'red', value => 'green');

sub new {
    my ($class, @argv) = @_;

    my $interactive = -t *STDOUT;
    my $command = (!@argv && $interactive) ? 'help' : '';

    my $number = 0;
    if (my ($i) = grep {$argv[$_] =~ /^-(\d+)$/} (0 .. @argv - 1)) {
        $number = -(splice @argv, $i, 1);
    }

    my $abbrev     = grep {$_ eq '-B'} @argv;
    my $noAnnotate = grep {$_ eq '-A'} @argv;

    my @path;

    my $opt = {
        number  => \$number,
        help    => sub {$command = 'help'},
        version => sub {$command = 'version'},
        build   => sub {$command = 'build'},
        count   => sub {$command = 'count'},     # for backwards compatibility
        path    => \@path,
        schema  => sub {
            my $schema = $_[1];
            my $json;
            if ($schema =~ qr{^https?://}) {
                require HTTP::Tiny;
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

    my %cmd = abbrev
        qw(convert count fields subfields sf explain validate build diff patch help version);
    if ($cmd{$argv[0]}) {
        $command = $argv[0] eq 'sf' ? 'subfields' : $cmd{shift @argv};
    }
    $opt->{error} = "$command not implemented yet"
        if $command =~ /fields|subfields|explain|diff|patch/;

    GetOptionsFromArray(
        \@argv,       $opt,           'from|f=s',  'to|t:s',
        'schema|s=s', 'annotate|A|a', 'build|B|b', 'unknown|u!',
        'count|c',    'order|o',      'path|p=s',  "number|n:i",
        'color|C',    'mono|M',       'help|h|?',  'version|V',
    ) or pod2usage(2);

    $opt->{number}   = $number;
    $opt->{annotate} = 0 if $noAnnotate;
    $opt->{abbrev}   = $abbrev if $abbrev;
    $opt->{color}    = !$opt->{mono} && ($opt->{color} || $interactive);

    delete $opt->{$_} for qw(count build help version);
    delete $opt->{schema} if reftype $opt->{schema} eq 'CODE';

    my $pattern = '[012.][0-9.][0-9.][A-Z@.](\$[^|]+)?';
    while (@argv && $argv[0] =~ /^$pattern(\s*\|\s*($pattern)?)*$/) {
        push @path, shift @argv;
    }

    if (@path) {
        @path = map {
            my $p = eval {PICA::Path->new($_)};
            $p || die "invalid PICA Path: $_\n";
        } grep {$_ ne ""} map {split /\s*\|\s*/, $_} @path;

        if (all {$_->subfields ne ""} @path) {
            $command = 'select';
        }
        elsif (any {$_->subfields ne ""} @path) {
            $opt->{error}
                = "PICA Path must either all select fields or all select subfields!";
        }
    }

    $opt->{order} = 1 if $command =~ /(diff|patch)/;

    $opt->{command} = $command
        || ($opt->{schema} && !$opt->{annotate} ? 'validate' : 'convert');
    $opt->{input} = @argv ? \@argv : ['-'];

    $opt->{from}
        = ($opt->{input}[0] =~ /\.([a-z]+)$/ && $TYPES{lc $1}) ? $1 : 'plain'
        unless $opt->{from};
    $opt->{from} = $TYPES{lc $opt->{from}}
        or $opt->{error} = "unknown serialization type: " . $opt->{from};

    $opt->{to} = $opt->{from}
        if !$opt->{to} and $opt->{command} =~ /(convert|diff|patch)/;
    if ($opt->{to}) {
        $opt->{to} = $TYPES{lc $opt->{to}}
            or $opt->{error} = "unknown serialization type: " . $opt->{to};
    }

    bless $opt, $class;
}

sub run {
    my ($self) = @_;
    my $command = $self->{command};

    # commands that don't parse any input data
    if ($self->{error}) {
        pod2usage($self->{error});
    }
    elsif ($command eq 'help') {
        pod2usage(
            -verbose  => 99,
            -sections => "SYNOPSIS|COMMANDS|OPTIONS|DESCRIPTION|EXAMPLES"
        );
    }
    elsif ($command eq 'version') {
        say $PICA::Data::VERSION;
        exit
    }

    # initialize parser, writer, and schema builder
    my $input = $self->{input};

    if ($input->[0] eq '-') {
        $input = *STDIN;
        binmode $input, ':encoding(UTF-8)';
    }

    binmode *STDOUT, ':encoding(UTF-8)';

    my $parser = pica_parser($self->{from}, $input->[0], bless => 1);
    my $writer;
    if ($self->{to}) {
        $writer = pica_writer(
            $self->{to},
            color => ($self->{color} ? \%COLORS : undef),
            schema   => $self->{schema},
            annotate => $self->{annotate},
        );
    }

    my $builder
        = $command =~ /(build|fields|subfields|explain)/
        ? PICA::Schema::Builder->new
        : undef;

    # additional options
    my $number  = $self->{number};
    my @pathes  = @{$self->{path} || []};
    my $schema  = $self->{schema};
    my $stats   = {records => 0, holdings => 0, items => 0, fields => 0};
    my $invalid = 0;

    while (my $record = $parser->next) {
        if ($command eq 'select') {
            say $_ for map {@{$record->match($_, split => 1) // []}} @pathes;
        }

        $record = $record->sort if $self->{order};

        $record = {record => $record->fields(@pathes)} if @pathes;
        next unless @{$record->{record}};    # ignore empty records

        # TODO: also validate on other commands?
        if ($command eq 'validate') {
            my @errors = $schema->check(
                $record,
                ignore_unknown => !$self->{unknown},
                annotate       => $self->{annotate}
            );
            if (@errors) {
                unless ($self->{annotate}) {
                    say(defined $record->{_id} ? $record->{_id} . ": $_" : $_)
                        for @errors;
                }
                $invalid++;
            }
        }

        $writer->write($record) if $writer;
        $builder->add($record)  if $builder;

        if ($command eq 'count') {
            $stats->{holdings} += @{$record->holdings};
            $stats->{items}    += @{$record->items};
            $stats->{fields}   += @{$record->{record}};
        }
        $stats->{records}++;

        last if $number and $stats->{records} >= $number;
    }

    $writer->end() if $writer;

    # TODO: commands fields subfields, explain

    if ($command eq 'count') {
        $stats->{invalid} = $invalid;
        say $stats->{$_} . " $_"
            for grep {$stats->{$_}} qw(records invalid holdings items fields);
    }
    elsif ($command eq 'build') {
        my $schema = $builder->schema;
        print JSON::PP->new->indent->space_after->canonical->convert_blessed
            ->encode($self->{abbrev} ? $schema->abbreviated : $schema);
    }

    exit !!$invalid;
}

=head1 NAME

App::picadata - Implementation of picadata command line application.

=head1 DESCRIPTION

This package implements the L<picadata> command line application.

=cut

1;

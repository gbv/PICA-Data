use strict;
use warnings;
use PICA::Data qw(pica_parser);
use PICA::Schema;
use Test::More;
use YAML::Tiny;

my $tests = YAML::Tiny->read('t/files/schema-tests.yaml')->[0];

my %records = map { 
        ($_ => pica_parser('plain', fh => \($tests->{records}{$_}) )->next())
    } keys %{$tests->{records}};
my %schemas = map { 
        $_ => PICA::Schema->new($tests->{schemas}{$_})
    } keys %{$tests->{schemas}};

foreach (@{$tests->{tests}}) {
    my $schema = $schemas{$_->{schema}};
    my $record = $records{$_->{record}};
    my $options = $_->{options} || {}; 

    my @errors = $schema->check($record, %$options); 
    my $expect = $_->{result} || [];
    unless ( is_deeply \@errors, $expect ) {
        note (YAML::Tiny->Dump(\@errors));
    }
}

done_testing;

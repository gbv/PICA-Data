package Catmandu::Importer::PICA;

# ABSTRACT: Package that imports PICA+ data
# VERSION

use Catmandu::Sane;
use Catmandu::PICA;
use Catmandu::PICAplus;
use Moo;

no if $] >= 5.018, 'warnings', "experimental::smartmatch";

with 'Catmandu::Importer';

has type => ( is => 'ro', default => sub {'XML'} );

sub pica_generator {
    my $self = shift;

    my $file;

    given ( $self->type ) {
        when ('XML') {
            $file = Catmandu::PICA->new( $self->fh );
        }
        when ('PICAplus') {
            $file = Catmandu::PICAplus->new( $self->fh );
        }
        die "unknown";
    }

    sub {
        my $record = $file->next();
        return unless $record;
        return $record;
    };
}

sub generator {
    my ($self) = @_;
    my $type = $self->type;

    given ($type) {
        when ('XML') {
            return $self->pica_generator;
        }
        when ('PICAplus') {
            return $self->pica_generator;
        }
        die "need PICA+ data as input";
    }
}

=head1 SYNOPSIS

    use Catmandu::Importer::PICA;

    my $importer = Catmandu::Importer::PICA->new(file => "pica.xml", type=> "XML");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 PICA

Parse PICA XML to native Perl hash containing two keys: '_id' and 'record'. 

  {
    'record' => [
                  [
                    '001@',
                    '',
                    '_',
                    '',
                    '0',
                    '703'
                  ],
                  [
                    '001A',
                    '',
                    '_',
                    '',
                    '0',
                    '2045:10-03-11'
                  ],
                  [
                    '028B',
                    '01',
                    '_',
                    '',
                    'd',
                    'Thomas',
                    'a',
                    'Bartzanas'
                   ]

    '_id' => '658700774'
  },

=head1 METHODS

=head2 new(file => $filename,type=>$type)

Create a new PICA importer for $filename. Use STDIN when no filename is given. Type 
describes the sytax of the PICA records. Currently we support following types: PICAplus, XML.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::PICA methods are not idempotent: PICA feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;    # End of Catmandu::Importer::PICA

package PICA::Parser::XML;
use strict;

our $VERSION = '0.21';

use Carp qw(croak);
use XML::LibXML::Reader;

sub new {
    my ($class, $input) = @_;

    my $self = bless { }, $class;
    
    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        binmode $input; # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new(IO => $input)
            or croak "cannot read from filehandle $input\n";
        $self->{filename}   = scalar $input;
        $self->{xml_reader} = $reader;
    } elsif ( defined $input && $input !~ /\n/ && -e $input ) {
        my $reader = XML::LibXML::Reader->new(location => $input)
            or croak "cannot read from file $input\n";
        $self->{filename}   = $input;
        $self->{xml_reader} = $reader;
    } elsif ( defined $input && length $input > 0 ) {
        $input = ${$input} if (ref($input) // '' eq 'SCALAR'); 
        my $reader = XML::LibXML::Reader->new( string => $input )
            or croak "cannot read XML string $input\n";
        $self->{xml_reader} = $reader;
    } else {
        croak "file, filehande or string $input does not exists";
    }

    $self;
}

# duplicated in PICA::Data::Plus because no common superclass exists
sub next {
    my ($self) = @_;

    # get last subfield from 003@ as id
    if ( my $record = $self->next_record ) {
        my ($id) = map { $_->[-1] } grep { $_->[0] =~ '003@' } @{$record};
        return { _id => $id, record => $record };
    }

    return;
}

sub next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return unless $reader->nextElement('record');

    my @record;

    # get all field nodes from PICA record;
    foreach my $field_node ( $reader->copyCurrentNode(1)->getChildrenByTagName('*') ) {
        my @field;
        
        # get field tag number
        my $tag = $field_node->getAttribute('tag');
        my $occurrence = $field_node->getAttribute('occurrence') // '';
        push(@field, ($tag, $occurrence));
            
            # get all subfield nodes
            foreach my $subfield_node ( $field_node->getChildrenByTagName('*') ) {
                my $subfield_code = $subfield_node->getAttribute('code');
                my $subfield_data = $subfield_node->textContent;
                push(@field, ($subfield_code, $subfield_data));
            }
        push(@record, [@field]);
    };
    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::XML - PICA+ XML parser

=head1 SYNOPSIS

    use PICA::Parser::XML;

    my $parser = PICA::Parser::XML->new( $filename );

    while ( my $record_hash = $parser->next ) {
        # do something
    }

=head1 METHODS

=head2 new( $input )

Initialize parser to read from a given XML file, handle (e.g. L<IO::Handle>),
string reference, or XML string.

=head2 next

Reads the next PICA+ record. Returns a hash with keys C<_id> and C<record>.

=head2 next_record

Reads the next PICA+ record. Returns an array of field arrays.

=head1 SEEALSO

L<PICA::XMLParser>, included in the release of L<PICA::Record> implements
another PICA+ XML format parser, not aligned with the L<Catmandu> framework.

=cut

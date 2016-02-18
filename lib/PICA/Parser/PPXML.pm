package PICA::Parser::PPXML;
use strict;
use warnings;
use 5.008_005;

our $VERSION = '0.30';

use Carp qw(croak);
use XML::LibXML::Reader;

use parent 'PICA::Parser::Base';

sub new {
    my ($class, $input) = @_;

    my $self = bless { }, $class;
    
    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        binmode $input; # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new(IO => $input)
            or croak "cannot read from filehandle $input\n";
        $self->{xml_reader} = $reader;
    } elsif ( defined $input && $input !~ /\n/ && -e $input ) {
        my $reader = XML::LibXML::Reader->new(location => $input)
            or croak "cannot read from file $input\n";
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

sub next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return unless $reader->nextElement('record','http://www.oclcpica.org/xmlns/ppxml-1.0');

    my @record;

    # get all field from PICA record;
    foreach my $field ( $reader->copyCurrentNode(1)->getElementsByLocalName('tag') ) {
        my @field;
        
        # get field tag number
        my $tag = $field->getAttribute('id');
        my $occurrence = $field->getAttribute('occ') // '';
        push(@field, ($tag, $occurrence));
            
            # get all subfields
            foreach my $subfield ( $field->getElementsByLocalName('subf') ) {
                my $subfield_code = $subfield->getAttribute('id');
                my $subfield_data = $subfield->textContent;
                push(@field, ($subfield_code, $subfield_data));
            }
        push(@record, [@field]);
    };
    return \@record;
}

1;

__END__

=encoding utf-8

=head1 NAME

PICA::Parser::PPXML - Parser for the PICA+ XML format variant of the Deutsche Nationalbiliothek.

=head1 DESCRIPTION

See PICA::Parser::Base for synopsis and details.

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Use L<PICA::Parser::XML> for the standard variant of the PICA+ XML format.

=cut

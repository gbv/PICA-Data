package Catmandu::PICA;
#ABSTRACT: Catmandu modules for working with PICA+ data.
#VERSION

sub parse_pica_path {
    return if $_[0] !~ /(\d{3}\S)(\[([0-9*]{2})\])?([_A-Za-z0-9]+)?(\/(\d+)(-(\d+))?)?/;
    my @path = (
        $1, # field
        $3, # occurrence
        defined $4 ? "[$4]" : "[_A-Za-z0-9]", # subfield_regex
    );

    push(@path, $6, $8) if defined $5; # from, to

    $path[0] =~ s/\*/./g;                     # field => field_regex
    $path[1] =~ s/\*/./g if defined $path[1]; # occurrence => occurrence_regex

    return \@path;
}

=head1 DESCRIPTION

Catmandu::PICA provides methods to work with PICA+ data within the L<Catmandu>
framework.  See L<Catmandu::Introduction> and L<http://librecat.org/> for an
introduction into Catmandu.

=head1 CATMANDU MODULES

=over

=item * L<Catmandu::Importer::PICA>

=item * L<Catmandu::Exporter::PICA>

=item * L<Catmandu::Importer::SRU::Parser::picaxml>

=item * L<Catmandu::Fix::pica_map>

=back

=head1 INTERNAL MODULES

The following modules may be renamed or removed in a future release.

=over

=item * L<PICA::Parser::XML>

=item * L<PICA::Parser::Plus>

=item * L<PICA::Parser::Plain>

=item * L<PICA::Writer::XML>

=item * L<PICA::Writer::Plus>

=item * L<PICA::Writer::Plain>

=back

=head1 FUNCTIONS

=head2 parse_pica_path( $path )

Parses a PICA path expression. On success returns a list reference with:

=over

=item

regex string to match fields against (must be compiled with C<qr{...}> or C</.../>)

=item

regex string to match occurrences against (must be compiled)

=item

regex string to match subfields against (must be compiled)

=item

substring start position

=item

substring end position

=head1 CONTRIBUTORS

=encoding utf8

Johann Rolschewski, <rolschewski@gmail.com>

Jakob Voß <voss@gbv.de>

=cut

1; # End of Catmandu::PICA

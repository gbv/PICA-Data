requires 'Catmandu', '>= 0.7';
requires 'XML::LibXML::Reader', '>= 2.0';

# To get PICA via SRU
recommends 'Catmandu::SRU', '>= 0.032';
conflicts 'Catmandu::SRU', '< 0.032';

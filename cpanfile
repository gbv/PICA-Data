requires 'Catmandu', '>= 0.9';
requires 'XML::LibXML', '1.78';

# To get PICA via SRU
recommends 'Catmandu::SRU', '>= 0.032';
conflicts 'Catmandu::SRU', '< 0.032';

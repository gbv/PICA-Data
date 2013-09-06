Catmandu::PICA - Catmandu modules for working with PICA+ data.

# Installation

Install the latest distribution from CPAN:

    cpanm Catmandu::PICA

Install the latest developer version from GitHub:

    cpanm git@github.com:gbv/Catmandu-PICA.git@devel

# Contribution

For bug reports and feature requests use <https://github.com/gbv/Catmandu-PICA/issues>.

For contributions to the source code create a fork or use the `devel` branch. The master
branch should only contain merged and stashed changes to appear in Changelog.

Dist::Zilla and build requirements can be installed this way:

    cpan Dist::Zilla
    dzil authordeps | cpanm

Build and test your current state this way:

    dzil build
    dzil test 
    dzil smoke --release --author # test more

# Status

Build and test coverage of the `devel` branch at <https://github.com/gbv/Catmandu-PICA/>:

[![Build Status](https://travis-ci.org/gbv/Catmandu-PICA.png)](https://travis-ci.org/gbv/Catmandu-PICA)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-PICA/badge.png?branch=devel)](https://coveralls.io/r/gbv/Catmandu-PICA?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-PICA.png)](http://cpants.cpanauthors.org/dist/Catmandu-PICA)

#!/usr/bin/env bash

version=${1:-1.008004}
ll=http://search.cpan.org/CPAN/authors/id/A/AP/APEIRON/local-lib-${version}.tar.gz
wget -O - $ll | tar -xzf - 
cd local-lib*
perl Makefile.PL --bootstrap=$perl5
make test && make install

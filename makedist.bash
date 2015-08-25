make clean
rm -f MANIFEST
rm -f MYMETA.yml
rm -f MYMETA.json
rm META.yml
rm -rf *.gz
perl Makefile.PL
make
make test
make manifest
make distmeta
make dist


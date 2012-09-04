make OPENMP=1 LONGSEQUENCES=1 CATEGORIES=4 MAXKMERLENGTH=191

#####
ssh vbc
cd velvet_1.2.07
make OPENMP=1 LONGSEQUENCES=1 CATEGORIES=4 MAXKMERLENGTH=191 LDFLAGS=-static

rsync -av powell@vbc:velvet_1.2.07/velvet? linux-x86_64/


#####
(cd ../velvet_1.2.07 ; make OPENMP=1 LONGSEQUENCES=1 CATEGORIES=4 MAXKMERLENGTH=191)
rsync -av ../velvet_1.2.07/velvet? macosx-x86_64/

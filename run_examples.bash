set -e;

for p in $( ls -1d examples/* ); do
    swat $p
done



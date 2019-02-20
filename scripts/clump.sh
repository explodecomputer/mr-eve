#!/bin/bash

set -e

id=$1
gwasdir=$2
ldref=$3


bcftools view -i 'L10PVAL>7.30103' $gwasdir/$id/data.bcf | bcftools query -f'%ID %L10PVAL\n' > $gwasdir/$id/tophits.txt1

awk 'BEGIN {print "SNP P"}; {print $1, 10^-$2}' $gwasdir/$id/tophits.txt1 > $gwasdir/$id/tophits.txt

plink \
--bfile $ldref \
--clump $gwasdir/$id/tophits.txt \
--clump-kb 10000 \
--clump-r2 0.001 \
--clump-p1 5e-8 \
--clump-p2 5e-8 \
--out $gwasdir/$id/tophits.txt

awk '{ print $3 }' $gwasdir/$id/tophits.txt.clumped | sed '/^[[:space:]]*$/d' > $gwasdir/$id/snplist.txt

bcftools view -i "ID=@$gwasdir/$id/snplist.txt" $gwasdir/$id/data.bcf | bcftools query -f'%CHROM\t%POS\t%REF\t%ALT\tb37\t%ID\n' > $gwasdir/$id/clump.txt
rm $gwasdir/$id/snplist.txt

rm -f $gwasdir/$id/tophits.txt*


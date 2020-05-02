library(dplyr)
library(gwasvcf)
library(argparse)
library(genetics.binaRies)
library(mrever)
gwasvcf::set_plink()
gwasvcf::set_bcftools()

# create parser object
parser <- ArgumentParser()
parser$add_argument('--snplist', required=TRUE)
parser$add_argument('--gwasdir', required=TRUE)
parser$add_argument('--id', required=TRUE)
parser$add_argument('--out', required=TRUE)
parser$add_argument('--dbfile', required=TRUE)
parser$add_argument('--get-proxies', default='yes')
parser$add_argument('--tag-r2', type="double", default=0.6)
parser$add_argument('--tag-kb', type="double", default=5000)
parser$add_argument('--tag-nsnp', type="double", default=5000)
parser$add_argument('--palindrome-freq', type="double", default=0.4)
parser$add_argument('--no-clean', action="store_true", default=FALSE)
parser$add_argument('--instrument-list', default=FALSE, action="store_true")
parser$add_argument('--threads', type="integer", default=1)


args <- parser$parse_args()
str(args)
vcf <- file.path(args[['gwasdir']], args[['id']], paste0(args[['id']], ".vcf.gz"))
snplist <- scan(args[['snplist']], what="character")
str(snplist)
o1 <- gwasvcf::query_gwas(
	vcf=vcf, 
	rsid=snplist, 
	proxies=args[['get_proxies']], 
	dbfile=args[["dbfile"]], 
	tag_kb=args[["tag_kb"]], 
	tag_nsnp=args[["tag_nsnp"]], 
	tag_r2=args[["tag_r2"]]
) %>% 
	gwasvcf::vcf_to_tibble()

if(nrow(o1) == 0)
{
	message("No results found")
	mrever::write_out(o1, args[["out"]], header=FALSE)
	q()
}

o1 <- o1 %>%
	dplyr::select(id, rsid=ID, chr=seqnames, pos=start, ref=REF, alt=ALT, beta=ES, se=SE, pval=LP, af=AF, n=SS, ncase=NC, proxy=PR) %>%
	dplyr::mutate(pval = 10^-pval, id=id)

dplyr::glimpse(o1)

if(!is.null(args[['instrument_list']]))
{
	print("instruments")
	clumpfile <- file.path(args[['gwasdir']], args[['id']], "clump.txt")
	clump <- scan(clumpfile, what="character")
	o1$instrument <- o1$rsid %in% clump
}

mrever::write_out(o1, args[["out"]], header=FALSE)

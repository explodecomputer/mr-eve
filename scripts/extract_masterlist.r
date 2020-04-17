if(!require(gwasvcftools))
{
	if(!required(devtools)) install.packages("devtools")
	devtools::install_github("MRCIEU/gwasvcf")
}
library(gwasvcf)
library(argparse)
library(genetics.binaRies)
gwasvcf::set_plink()
gwasvcf::set_bcftools()

# create parser object
parser <- ArgumentParser()
parser$add_argument('--snplist', required=TRUE)
parser$add_argument('--gwasdir', required=TRUE)
parser$add_argument('--id', required=TRUE)
parser$add_argument('--out', required=TRUE)
parser$add_argument('--bfile', required=TRUE)
parser$add_argument('--get-proxies', default='yes')
parser$add_argument('--tag-r2', type="double", default=0.6)
parser$add_argument('--tag-kb', type="double", default=5000)
parser$add_argument('--tag-nsnp', type="double", default=5000)
parser$add_argument('--palindrome-freq', type="double", default=0.4)
parser$add_argument('--no-clean', action="store_true", default=FALSE)
parser$add_argument('--instrument-list', default=FALSE, action="store_true")
parser$add_argument('--threads', type="integer", default=1)


args <- parser$parse_args()
# args <- parser$parse_args(c("--bfile", "../../vcf-reference-datasets/ukb/ukb_ref", "--gwas-id", "2", "--snplist", "temp.snplist", "--no-clean", "--out", "out", "--bcf-dir", "../../gwas-files", "--vcf-ref", "../../vcf-reference-datasets/1000g/1kg_v3_nomult.bcf", "--get-proxies"))
print(args)
vcf <- file.path(args[['gwasdir']], args[['id']], paste0(args[['id']], ".vcf.gz"))
snplist <- scan(args[['snplist']], what="character")
str(snplist)
o1 <- gwasvcf::query_gwas(
	vcf=vcf, 
	rsid=snplist, 
	proxies=args[['get_proxies']], 
	bfile=args[["bfile"]], 
	tag_kb=args[["tag_kb"]], 
	tag_nsnp=args[["tag_nsnp"]], 
	tag_r2=args[["tag_r2"]]
) %>% gwasvcf::vcf_to_tibble()

print(head(o1))
print(dim(o1))

if(!is.null(args[['instrument_list']]))
{
	print("instruments")
	clumpfile <- file.path(args[['gwasdir']], args[['id']], "clump.txt")
	clump <- scan(clumpfile, what="character")
	o1$instrument <- o1$rsid %in% clump
}
write_out(o1, basename=args[["out"]], header=FALSE)


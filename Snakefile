import os.path
import re

# Define some variables
# REF = '../reference/1000g_filtered/data_maf0.01_rs_snps'
REF = '../vcf-reference-datasets/1000g_filtered/data_maf0.01_rs_snps'
VCFREF = '../vcf-reference-datasets/1000g/1kg_v3_nomult.bcf'
GWASDIR = '../gwas-files'
INSTRUMENTLIST = "instruments.txt"


# configfile: 'config.json'

# Find all the initial study files
ID = [ name for name in os.listdir(GWASDIR) if 
	os.path.isdir(os.path.join(GWASDIR, name)) and 
	os.path.isfile(os.path.join(GWASDIR, name, 'data.bcf')) ]
# ID1 = list(filter(lambda x: re.search('^UKB-a', x), ID))
# ID2 = list(filter(lambda x: re.search('^[0-9]', x), ID))
# ID = ID1 + ID2
# ID = ['2', '7']
# ID = ID[1:10]

with open("idlist.txt", "wt") as f:
	for id in ID:
		f.write("%s\n" % id)


# Create a rule defining all the final files

rule all:
	input: 
		expand('{GWASDIR}/{id}/derived/instruments/mr.rdata', GWASDIR=GWASDIR,id=ID)

# Step 1: clump each GWAS

rule clump:
	input:
		'{GWASDIR}/{id}/data.bcf'
	output:
		'{GWASDIR}/{id}/clump.txt'
	shell:
		"./scripts/clump.sh {wildcards.id} {GWASDIR} {REF}"

# Step 2: Create a master list of all unique instrumenting SNPs

rule master_list:
	input:
		expand('{GWASDIR}/{id}/clump.txt', GWASDIR=GWASDIR,id=ID)
	output:
		'instruments.txt'
	shell:
		'./scripts/instrument_list.py --dirs {GWASDIR} --output {output}'

# Step 3: Extract the master list from each GWAS

rule extract_master:
	input:
		'instruments.txt'
	output:
		'{GWASDIR}/{id}/derived/instruments/ml.csv.gz'
	shell:
		"mkdir -p studies/{wildcards.id}/derived/instruments/; Rscript scripts/extract_masterlist.r --snplist instruments.txt --bcf-dir {GWASDIR} --out {output} --bfile {REF} --vcf-ref {VCFREF} --gwas-id {wildcards.id} --instrument-list --get-proxies yes"

# Step 4: Perform MR

rule mr:
	input:
		'{GWASDIR}/{id}/derived/instruments/ml.csv.gz'
	output:
		'{GWASDIR}/{id}/derived/instruments/mr.rdata'
	shell:
		'Rscript scripts/mr.r --idlist idlist.txt --gwasdir {GWASDIR} --id {wildcards.id} --rf rf.rdata --what triangle --out {output} --threads 10'

# Step 5: Create neo4j files

# Step 6: Upload neo4j


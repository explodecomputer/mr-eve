import os.path
import re
import subprocess

# Define some variables
# REF = '../reference/1000g_filtered/data_maf0.01_rs_snps'
REF = '../vcf-reference-datasets/1000g_filtered/data_maf0.01_rs_snps'
VCFREF = '../vcf-reference-datasets/1000g/1kg_v3_nomult.bcf'
GWASDIR = '../gwas-files'
INSTRUMENTLIST = "instruments.txt"


subprocess.call("Rscript scripts/get_ids.r", shell=True)
subprocess.call("Rscript scripts/get_genes.r", shell=True)
subprocess.call("wget -O data/rf.rdata https://www.dropbox.com/s/5la7y38od95swcf/rf.rdata?dl=0", shell=True)

ID = [line.strip() for line in open("data/idlist.txt", 'r')]


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

rule neo4j:
	input:
		'{GWASDIR}/{id}/derived/instruments/mr.rdata'
	output:
		''
	shell:
		'Rscript scripts/prepare_neo4j.r'

# Step 6: Upload neo4j


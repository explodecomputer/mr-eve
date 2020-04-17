import os
import re
import subprocess
import json

with open("config.json", "r") as f:
  config = json.load(f)

GWASDIR = config['gwasdir']
OUTDIR = config['outdir']
LDREFHOST = config['ldrefhost']
LDREFPATH = OUTDIR + "/reference/" + config['ldrefname']
RFHOST = config['rfhost']

os.makedirs('job_reports', exist_ok=True)
os.makedirs(OUTDIR + '/reference', exist_ok=True)
os.makedirs(OUTDIR + '/resources', exist_ok=True)
os.makedirs(OUTDIR + '/neo4j', exist_ok=True)

IDLIST = OUTDIR + "/resources/ids.txt"
INSTRUMENTLIST = OUTDIR + "/resources/instruments.txt"

# all ids in gwasdir
ID = [x.strip().lower() for x in [y for y in os.listdir(GWASDIR)] if 'eqtl-a' not in x][0:10]
with open(IDLIST, 'w') as f:
  [f.writelines(x + '\n') for x in ID]

NTHREAD=10

# Create a rule defining all the final files

rule all:
	input:
		expand('{OUTDIR}/data/{id}/mr.rdata', OUTDIR=OUTDIR, id=ID),
		expand('{OUTDIR}/neo4j/somefile', OUTDIR=OUTDIR)


rule get_genes:
	output:
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR)
	shell:
		"Rscript scripts/get_genes.r {output}"

rule get_id_info:
	input:
		expand('{IDLIST}', IDLIST=IDLIST)
	output:
		expand('{IDLIST}.rdata', IDLIST=IDLIST)
	shell:
		"Rscript scripts/get_ids.r {input} {GWASDIR} {output}"

# Step 0: get LD reference files

rule download_ldref:
	output:
		expand("{LDREFPATH}.bed", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.bim", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.fam", LDREFPATH=LDREFPATH)
	shell:
		"curl -s {LDREFHOST} | tar xzvf - -C {OUTDIR}/reference"

rule download_rfobj:
	output:
		expand("{OUTDIR}/reference/rf.rdata", OUTDIR=OUTDIR)
	shell:
		"wget -O {output} {RFHOST}"

# Step 2: Create a master list of all unique instrumenting SNPs

rule instrument_list:
	input:
		# expand('{GWASDIR}/{ID}/clump.txt', GWASDIR=GWASDIR, ID=ID),
		expand('{IDLIST}', IDLIST=IDLIST)
	output:
		expand('{INSTRUMENTLIST}', INSTRUMENTLIST=INSTRUMENTLIST)
	shell:
		'./scripts/instrument_list.py --dirs {GWASDIR} --idlists {IDLIST} --output {output}'

# Step 3: Extract the master instrument list from each GWAS

rule extract_master:
	input:
		expand('{INSTRUMENTLIST}', INSTRUMENTLIST=INSTRUMENTLIST),
		expand('{LDREFPATH}.bed', LDREFPATH=LDREFPATH)
	output:
		'{OUTDIR}/data/{id}/ml.csv.gz'
	shell:
		"""
mkdir -p {OUTDIR}/data/{wildcards.id}
Rscript scripts/extract_masterlist.r \
--snplist {INSTRUMENTLIST} \
--gwasdir {GWASDIR} \
--out {output} \
--bfile {LDREFPATH} \
--id {wildcards.id} \
--instrument-list \
--get-proxies yes"
		"""

# Step 4: Perform MR

rule mr:
	input:
		ml = '{OUTDIR}/data/{id}/ml.csv.gz',
		rf = expand('{OUTDIR}/reference/rf.rdata', OUTDIR=OUTDIR),
		idlist = expand('{IDLIST}.rdata', IDLIST=IDLIST),
	output:
		'{OUTDIR}/data/{id}/mr.rdata'
	shell:
		"""
Rscript scripts/mr.r \
--idlist {input.idlist} \
--gwasdir {GWASDIR} \
--id {wildcards.id} \
--rf {input.rf} \
--what triangle \
--out {output} \
--threads {NTHREAD}
		"""

# Step 5: Create neo4j files

rule neo4j:
	input:
		expand('{OUTDIR}/data/{id}/mr.rdata', OUTDIR=OUTDIR, id=ID),
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR)
	output:
		expand('{OUTDIR}/neo4j/somefile', OUTDIR=OUTDIR)
	shell:
		'Rscript scripts/prepare_neo4j.r'

# Step 6: Upload neo4j


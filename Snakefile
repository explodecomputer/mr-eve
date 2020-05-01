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

os.makedirs(OUTDIR + '/job_reports', exist_ok=True)
os.makedirs(OUTDIR + '/reference', exist_ok=True)
os.makedirs(OUTDIR + '/resources', exist_ok=True)
os.makedirs(OUTDIR + '/neo4j', exist_ok=True)

IDLIST = OUTDIR + "/resources/ids.txt"
INSTRUMENTLIST = OUTDIR + "/resources/instruments.txt"

# all ids in gwasdir
ID = [x.strip() for x in [y for y in os.listdir(GWASDIR)] if 'eqtl-a' not in x]

NTHREAD=10

# Create a rule defining all the final files

rule all:
	input:
		expand('{OUTDIR}/data/{id}/ml.csv.gz', OUTDIR=OUTDIR, id=ID),
		expand('{OUTDIR}/data/{id}/mr.rdata', OUTDIR=OUTDIR, id=ID)
		# expand('{OUTDIR}/neo4j/somefile', OUTDIR=OUTDIR)


rule get_genes:
	output:
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR)
	shell:
		"Rscript scripts/get_genes.r {output}"


rule write_idlist:
	output:
		expand('{IDLIST}', IDLIST=IDLIST)
	run:
		with open(output[0], 'w') as f:
			[f.writelines(x + '\n') for x in ID]


rule get_id_info:
	input:
		expand('{IDLIST}', IDLIST=IDLIST)
	output:
		expand('{IDLIST}.rdata', IDLIST=IDLIST)
	shell:
		"Rscript scripts/get_ids.r {input} {GWASDIR} {output}"


rule download_ldref:
	output:
		expand("{LDREFPATH}.bed", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.bim", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.fam", LDREFPATH=LDREFPATH)
	shell:
		"curl -s {LDREFHOST} | tar xzvf - -C {OUTDIR}/reference"

rule create_ldref_sqlite:
	input:
		expand("{LDREFPATH}.bed", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.bim", LDREFPATH=LDREFPATH),
		expand("{LDREFPATH}.fam", LDREFPATH=LDREFPATH)
	output:
		expand("{LDREFPATH}.sqlite", LDREFPATH=LDREFPATH)
	shell:
		"Rscript -e 'gwasvcf::create_ldref_sqlite(\"{LDREFPATH}\", \"{LDREFPATH}.sqlite\")"

rule download_rfobj:
	output:
		expand("{OUTDIR}/reference/rf.rdata", OUTDIR=OUTDIR)
	shell:
		"wget -O {output} {RFHOST}"


rule instrument_list:
	input:
		# expand('{GWASDIR}/{ID}/clump.txt', GWASDIR=GWASDIR, ID=ID),
		expand('{IDLIST}', IDLIST=IDLIST)
	output:
		expand('{INSTRUMENTLIST}', INSTRUMENTLIST=INSTRUMENTLIST)
	shell:
		'./scripts/instrument_list.py --dirs {GWASDIR} --idlists {IDLIST} --output {output}'


rule extract_master:
	input:
		expand('{INSTRUMENTLIST}', INSTRUMENTLIST=INSTRUMENTLIST),
		expand('{LDREFPATH}.sqlite', LDREFPATH=LDREFPATH)
	output:
		'{OUTDIR}/data/{id}/ml.csv.gz'
	shell:
		"""
mkdir -p {OUTDIR}/data/{wildcards.id}
Rscript scripts/extract_masterlist.r \
--snplist {INSTRUMENTLIST} \
--gwasdir {GWASDIR} \
--out {output} \
--dbfile {LDREFPATH}.sqlite \
--id {wildcards.id} \
--instrument-list \
--get-proxies yes
		"""

# To speed up snakemake don't require exhaustive dependencies
rule check_extract_master:
	input: 
		expand('{OUTDIR}/data/{id}/ml.csv.gz', OUTDIR=OUTDIR, id=ID),
	output:
		'{OUTDIR}/resources/extract_master_flag'
	shell:
		"touch {output}"


rule mr:
	input:
		flag = expand('{OUTDIR}/resources/extract_master_flag', OUTDIR=OUTDIR),
		rf = expand('{OUTDIR}/reference/rf.rdata', OUTDIR=OUTDIR),
		idlist = expand('{IDLIST}.rdata', IDLIST=IDLIST)
	output:
		'{OUTDIR}/data/{id}/mr.rdata'
	shell:
		"""
Rscript scripts/mr.r \
--idlist {input.idlist} \
--outdir {OUTDIR} \
--id {wildcards.id} \
--rf {input.rf} \
--what eve \
--threads {NTHREAD}
		"""

rule neo4j:
	input:
		expand('{OUTDIR}/data/{id}/mr.rdata', OUTDIR=OUTDIR, id=ID),
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR)
	output:
		expand('{OUTDIR}/neo4j/somefile', OUTDIR=OUTDIR)
	shell:
		'Rscript scripts/prepare_neo4j.r'


# Upload neo4j ...


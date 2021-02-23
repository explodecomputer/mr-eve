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
ID1 = "ieu-a-2"

os.makedirs(OUTDIR + '/job_reports', exist_ok=True)
os.makedirs(OUTDIR + '/reference', exist_ok=True)
os.makedirs(OUTDIR + '/resources', exist_ok=True)
os.makedirs(OUTDIR + '/neo4j', exist_ok=True)

IDLIST = OUTDIR + "/resources/ids.txt"
INSTRUMENTLIST = OUTDIR + "/resources/instruments.txt"

# # all ids in gwasdir
# ID = [x.strip() for x in [y for y in os.listdir(GWASDIR)] if 'eqtl-a' not in x]

ID = open(IDLIST, 'r').read().strip().split('\n')[1:10]


CHUNKS=list(range(1,201))
NTHREAD=10

# Create a rule defining all the final files

rule all:
	input:
		# expand('{OUTDIR}/data/{id}/ml.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/mr.rdata', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/heterogeneity.rdata', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_mr.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_int.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_het.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_met.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_vt.csv.gz', OUTDIR=OUTDIR, id=ID),
		# expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_inst.csv.gz', OUTDIR=OUTDIR, id=ID),
		expand('{OUTDIR}/resources/extract_master_flag', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_mr_flag', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/{chunk}_mr.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		expand('{NEO4JDIR}/data/databases/graph.db/neostore.propertystore.db', NEO4JDIR=config['neo4j'])


rule get_genes:
	output:
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR)
	shell:
		"Rscript scripts/get_genes.r {output}"


# rule write_idlist:
# 	output:
# 		expand('{IDLIST}', IDLIST=IDLIST)
# 	run:
# 		with open(output[0], 'w') as f:
# 			[f.writelines(x + '\n') for x in ID]


# rule get_id_info:
# 	input:
# 		expand('{IDLIST}', IDLIST=IDLIST)
# 	output:
# 		expand('{IDLIST}.rdata', IDLIST=IDLIST)
# 	shell:
# 		"Rscript scripts/get_ids.r {input} {GWASDIR} {output}"


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

rule heterogeneity:
	input:
		'{OUTDIR}/data/{id}/mr.rdata'
	output:
		'{OUTDIR}/data/{id}/heterogeneity.rdata'
	shell:
		"""
Rscript scripts/heterogeneity.r \
--idlist {IDLIST}.rdata \
--outdir {OUTDIR} \
--id {wildcards.id} \
--what eve \
--threads {NTHREAD}
		"""

rule neo4j_mr:
	input:
		'{OUTDIR}/data/{id}/mr.rdata'
	output:
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_mr.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_moe.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_int.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_het.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_met.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_vt.csv.gz',
		'{OUTDIR}/data/{id}/neo4j_stage/{id}_inst.csv.gz'
	shell:
		"Rscript scripts/prepare_neo4j_mr.r {wildcards.id} {ID1}"

rule neo4j_mr_headers:
	input:
		expand('{OUTDIR}/data/{ID1}/mr.rdata', OUTDIR=OUTDIR, ID1=ID1)
	output:
		expand('{OUTDIR}/resources/neo4j_stage/header_mr.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_moe.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_int.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_het.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_met.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_vt.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/header_inst.csv.gz', OUTDIR=OUTDIR)
	shell:
		"Rscript scripts/prepare_neo4j_mr.r {ID1} {ID1}"

rule neo4j_others:
	input:
		expand('{OUTDIR}/resources/genes.rdata', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/instruments.txt', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/ids.txt.rdata', OUTDIR=OUTDIR),
	output:
		expand('{OUTDIR}/resources/neo4j_stage/genes.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/gv.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/traits.csv.gz', OUTDIR=OUTDIR),
		expand('{OUTDIR}/resources/neo4j_stage/variants.csv.gz', OUTDIR=OUTDIR)
	shell:
		'Rscript scripts/prepare_neo4j.r'


rule check_neo4j_mr:
	input:
		expand('{OUTDIR}/data/{id}/neo4j_stage/{id}_mr.csv.gz', OUTDIR=OUTDIR, id=ID),
	output:
		'{OUTDIR}/resources/neo4j_mr_flag'
	shell:
		"touch {output}"



rule collect_neo4j_mr:
	input:
		'{OUTDIR}/resources/neo4j_mr_flag'
	output:
		mr = '{OUTDIR}/resources/neo4j_stage/{chunk}_mr.csv.gz',
		moe = '{OUTDIR}/resources/neo4j_stage/{chunk}_moe.csv.gz',
		int = '{OUTDIR}/resources/neo4j_stage/{chunk}_int.csv.gz',
		het = '{OUTDIR}/resources/neo4j_stage/{chunk}_het.csv.gz',
		met = '{OUTDIR}/resources/neo4j_stage/{chunk}_met.csv.gz',
		vt = '{OUTDIR}/resources/neo4j_stage/{chunk}_vt.csv.gz',
		inst = '{OUTDIR}/resources/neo4j_stage/{chunk}_inst.csv.gz'
	run:
		import numpy
		import os
		l = numpy.array_split(numpy.array(ID), len(CHUNKS))[int(wildcards.chunk)-1]

		def inputfile(what, ids):
			return [OUTDIR + "/data/" + x + "/neo4j_stage/" + x + "_" + what + ".csv.gz" for x in ids]

		def cmd(inputs, output):
			return "cat {} | gunzip -c | awk NF | gzip -c > {}".format(inputs, output)

		os.system(cmd(" ".join(inputfile("mr", l)), output.mr))
		os.system(cmd(" ".join(inputfile("moe", l)), output.moe))
		os.system(cmd(" ".join(inputfile("int", l)), output.int))
		os.system(cmd(" ".join(inputfile("het", l)), output.het))
		os.system(cmd(" ".join(inputfile("met", l)), output.met))
		os.system(cmd(" ".join(inputfile("vt", l)), output.vt))
		os.system(cmd(" ".join(inputfile("inst", l)), output.inst))


rule create_neo4j_db:
	input:
		mr = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_mr.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		moe = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_moe.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		inte = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_int.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		het = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_het.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		met = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_met.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		vt = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_vt.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		inst = expand('{OUTDIR}/resources/neo4j_stage/{chunk}_inst.csv.gz', OUTDIR=OUTDIR, chunk=CHUNKS),
		header_mr = expand('{OUTDIR}/resources/neo4j_stage/header_mr.csv.gz', OUTDIR=OUTDIR),
		header_moe = expand('{OUTDIR}/resources/neo4j_stage/header_moe.csv.gz', OUTDIR=OUTDIR),
		header_inte = expand('{OUTDIR}/resources/neo4j_stage/header_int.csv.gz', OUTDIR=OUTDIR),
		header_het = expand('{OUTDIR}/resources/neo4j_stage/header_het.csv.gz', OUTDIR=OUTDIR),
		header_met = expand('{OUTDIR}/resources/neo4j_stage/header_met.csv.gz', OUTDIR=OUTDIR),
		header_vt = expand('{OUTDIR}/resources/neo4j_stage/header_vt.csv.gz', OUTDIR=OUTDIR),
		header_inst = expand('{OUTDIR}/resources/neo4j_stage/header_inst.csv.gz', OUTDIR=OUTDIR),
		genes = expand('{OUTDIR}/resources/neo4j_stage/genes.csv.gz', OUTDIR=OUTDIR),
		gv = expand('{OUTDIR}/resources/neo4j_stage/gv.csv.gz', OUTDIR=OUTDIR),
		traits = expand('{OUTDIR}/resources/neo4j_stage/traits.csv.gz', OUTDIR=OUTDIR),
		variants = expand('{OUTDIR}/resources/neo4j_stage/variants.csv.gz', OUTDIR=OUTDIR)
	output:
		expand('{NEO4JDIR}/data/databases/graph.db/neostore.propertystore.db', NEO4JDIR=config['neo4j'])
	run:
		import os
		mr = str(input.header_mr) + "," + ",".join(list(input.mr))
		moe = str(input.header_moe) + "," + ",".join(list(input.moe))
		inte = str(input.header_inte) + "," + ",".join(list(input.inte))
		het = str(input.header_het) + "," + ",".join(list(input.het))
		met = str(input.header_met) + "," + ",".join(list(input.met))
		vt = str(input.header_vt) + "," + ",".join(list(input.vt))
		inst = str(input.header_inst) + "," + ",".join(list(input.inst))
		cmd = config['neo4j'] + "/bin/neo4j-admin import " + \
			" --database graph.db" + \
			" --id-type STRING" + \
			" --nodes=GENE=" + str(input.genes) + \
			" --nodes=VARIANT=" + str(input.variants) + \
			" --nodes=TRAIT=" + str(input.traits) + \
			" --relationships=ANNOTATION=" + str(input.gv) + \
			" --relationships=INSTRUMENT=" + inst + \
			" --relationships=GENASSOC=" + vt + \
			" --relationships=MR=" + mr + \
			" --relationships=MRMOE=" + moe + \
			" --relationships=MRINTERCEPT=" + inte + \
			" --relationships=MRHET=" + het
			# " --relationships=METRICS=" + met
		os.system(cmd)
		# os.system(cmd)

# Upload neo4j ...

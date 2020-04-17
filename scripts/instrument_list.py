#!/usr/bin/env python3

import argparse
import logging
import itertools
import glob
import subprocess
import json
import os

parser = argparse.ArgumentParser(description = 'Extract and clump top hits')
parser.add_argument('--dirs', nargs='+', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--existing', required=False)
parser.add_argument('--idlists', nargs='+', required=False)


###args=parser.parse_args(['--dirs', '../../gwas-files', '--output', '../../gwas-files/instrument-master.txt'])

args = parser.parse_args()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
handler = logging.FileHandler(args.output+'.clump-log')
handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.info(json.dumps(vars(args), indent=1))

filelist = []
ndir = len(args.dirs)

# If idlists provided then make a list of clump files, 
# otherwise find all clump files in the directory lists

print(args.dirs[0])
print(args.idlists)

if args.idlists is not None:
	if not len(args.idlists) == len(args.dirs):
		raise Exception("--idlists must be empty or same length as --dirs")
	for i in range(len(args.dirs)):
		with open(args.idlists[i], 'r') as f:
			ids = [x.strip() for x in f.readlines()]
		candidateids = [args.dirs[i] + '/' + x + "/clump.txt" for x in ids]
		print(candidateids[1])
		filelist += [x for x in candidateids if os.path.isfile(x)]
else:
	for d in args.dirs:
		filelist += glob.glob(d + '/*/clump.txt')

logger.info("found " + str(len(filelist)) + " snp lists")

snps = {}
for f in filelist:
	n = set(line.strip() for line in open(f, 'rt'))
	logging.info(f)
	logging.info("number of loaded snps: " + str(len(n)))
	count = len(snps)
	snps = set(itertools.chain(snps, n))
	new_count = len(snps)
	logging.info("number of new snps: " + str(new_count - count))

logging.info("total instrument count: " + str(new_count))

if args.existing is not None:
	# Read in file
	# retain unique SNPs compared to existing
	logging.info("reading in snps from existing instrument list: " + f)
	existing = set(line.strip() for line in open(args.existing, 'rt'))
	logging.info("number of existing snps: " + str(len(existing)))
	newsnps = snps - existing
	logging.info("new snps: " + str(len(existing)))
	snps = snps | existing
	o = open(args.output + ".newlist", 'wt')
	[o.write(x + '\n') for x in snps]
	o.close()


o = open(args.output, 'wt')
[o.write(x + '\n') for x in snps]
o.close()



#!/bin/bash

snakemake -pr \
-j 500 \
--cluster-config bc4-cluster.json \
--cluster "sbatch \
  --partition={cluster.partition} \
  --nodes={cluster.nodes} \
  --ntasks-per-node={cluster.ntask} \
  --cpus-per-task={cluster.ncpu} \
  --time={cluster.time} \
  --mem={cluster.mem} \
  --output={cluster.output}"



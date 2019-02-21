#!/bin/bash

#SBATCH --job-name=neo4j
#SBATCH --array=0
#SBATCH --nodes=1 --cpus-per-task=10 --time=0-12:00:00
#SBATCH --partition=mrcieu
#SBATCH --output=job_reports/slurm-%A_neo4j.out
#SBATCH --mem=15G

echo "Running on ${HOSTNAME}"
module add languages/r/3.4.4

cd ${HOME}/mr-eve/mr-eve

time Rscript scripts/prepare_neo4j.r

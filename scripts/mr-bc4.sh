#!/bin/bash

#SBATCH --job-name=mr
#SBATCH --array=0-1000
#SBATCH --nodes=1 --cpus-per-task=10 --time=0-12:00:00
#SBATCH --partition=mrcieu
#SBATCH --output=job_reports/slurm-%A_%a.out
#SBATCH --mem=20G

echo "Running on ${HOSTNAME}"
module add languages/r/3.4.4

if [ -n "${1}" ]; then
  echo "${1}"
  SLURM_ARRAY_TASK_ID=${1}
fi

i=${SLURM_ARRAY_TASK_ID}
i=$((i + 1000))

cd ${HOME}/mr-eve/mr-eve
ids=($(cat idlist))

echo ${#ids[@]}
id=`echo ${ids[$i]}`
echo $id
if [ -z "$id" ]
then
	echo "outside range"
	exit
fi

GWASDIR='../gwas-files'
output="$GWASDIR/$id/derived/instruments/mr.rdata"


Rscript scripts/mr.r --idlist idlist --gwasdir $GWASDIR --id $id --rf rf.rdata --what triangle --out $output --threads 10



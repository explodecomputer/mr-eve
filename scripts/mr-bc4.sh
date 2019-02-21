#!/bin/bash

#SBATCH --job-name=mr
#SBATCH --array=0-1000
#SBATCH --nodes=1 --cpus-per-task=10 --time=0-12:00:00
#SBATCH --partition=mrcieu
#SBATCH --output=job_reports/slurm-%A_%a.out
#SBATCH --mem=15G

echo "Running on ${HOSTNAME}"
module add languages/r/3.4.4

cd ${HOME}/mr-eve/mr-eve

GWASDIR='../gwas-files'
IDINFO="resources/idinfo.rdata"
RF="resources/rf.rdata"
THREADS="10"
IDLIST="resources/idlist.txt"
ids=($(cat $IDLIST))


if [ -n "${1}" ]; then
	echo "${1}"
	id=$1
else
	i=${SLURM_ARRAY_TASK_ID}
	# i=$((i + 1000))
	id=`echo ${ids[$i]}`
fi

OUTPUT="$GWASDIR/$id/derived/instruments/mr.rdata"

echo "Total number of ids: ${#ids[@]}"
echo "Analysing $id"
if [ -z "$id" ]
then
	echo "outside range"
	exit
fi



time Rscript scripts/mr.r --idlist $IDLIST --gwasdir $GWASDIR --id $id --rf $RF --what eve --out $OUTPUT --threads $THREADS --idinfo $IDINFO

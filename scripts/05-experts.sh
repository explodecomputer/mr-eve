#!/bin/bash

#PBS -N mr2
#PBS -o job_reports/mr2-output
#PBS -e job_reports/mr2-error
#PBS -l walltime=00:30:00
#PBS -t 1-724
#PBS -l nodes=1:ppn=1
#PBS -S /bin/bash

set -e

echo "Running on ${HOSTNAME}"

if [ -n "${1}" ]; then
	echo "${1}"
	PBS_ARRAYID=${1}
fi

i=${PBS_ARRAYID}

cd ${HOME}/repo/mr-eve/scripts

Rscript 05-experts.r ${i}


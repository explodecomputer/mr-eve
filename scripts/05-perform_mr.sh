#!/bin/bash

#PBS -N mr
#PBS -o job_reports/mr-output
#PBS -e job_reports/mr-error
#PBS -l walltime=12:00:00
#PBS -t 1-724
#PBS -l nodes=1:ppn=4
#PBS -S /bin/bash

set -e

echo "Running on ${HOSTNAME}"

if [ -n "${1}" ]; then
	echo "${1}"
	PBS_ARRAYID=${1}
fi

i=${PBS_ARRAYID}

cd ${HOME}/repo/mr-eve/scripts

Rscript 05-perform_mr.r ${i}


# MR of everything versus everything

## Repositories

[https://github.com/explodecomputer/instrument-directionality](https://github.com/explodecomputer/instrument-directionality): Generate and analyse the mixture of experts model

[https://github.com/explodecomputer/mr-eve](https://github.com/explodecomputer/mr-eve): Construct the MR-EvE database. Includes `makemreve` R package for housing various functions

[https://github.com/mrcieu/mrever](https://github.com/mrcieu/mrever): R package for generating and querying the MR-EvE graph database

[https://github.com/mrcieu/mr-eve-webapp](https://github.com/mrcieu/mr-eve-webapp): Shiny web app for interfacing with MR-EvE

---

## Snakemake

Configure to run on cluster using `bc4-cluster.json`:

```
{
        "__default__" :
        {
                "partition": "mrcieu",
                "nodes": "1",
                "ncpu": "1",
                "ntask": "1",
                "time": "0:30:00",
                "mem": "10G",
                "output": "logs/{wildcards.id}.out"
        }
}
```

Ideally output would actually be `logs/{rule}.{wildcards.id}.out` but I don't think slurm likes really long long file names?

In principle this should then run from the root directory

```
mkdir logs
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
```

On bc4 it has to run in the background, like in screen for example. To test that it is submitting 

```
snakemake --cluster-config bc4-cluster.json \
--cluster "echo \
  '--partition={cluster.partition} \
  --nodes={cluster.nodes} \
  --ntasks-per-node={cluster.ntask} \
  --cpus-per-task={cluster.ncpu} \
  --time={cluster.time} \
  --mem={cluster.mem} \
  --output={cluster.output}' && " --jobs 1
```

What `--cluster` does is just append the argument in front of the command that is being run. So the above will just run the job without sending to the cluster, and instead printing what it would send to the cluster.

---

## Notes

Create a lower-triangular matrix of all results.

- `A-B` is allowed
- `A-A` is not
- `B-A` is not

## Results that need to be generated

Genetic associations
- Instruments for traits
- All trait instruments extracted from each trait

MR results
- Store a bi-directional MR result. 

## Programming strategy

We want to be able to easily update as new studies come in. To do this, we have to avoid duplicating previous results, while storing new results effectively. We can either re-do everything anytime new data comes along, and keep it simply structured; or have a complex structure with an inventory of results on top.

Opting for the latter to allow more agile updating.

Use a sqlite database of analyses that have been run - this is the 'inventory'. The inventory is there to record what results have been generated.

If we want to generate more results we can put forth trait A and trait B candidates, then query the inventory to get a list of trait pairs that need to be run.

This generates two files - trait pairs to be run, and a unique trait list. They are generated in a new slice.

Snakefile applied to those new files.
1. clump traits A and B if necessary PARALLEL
2. get unique SNPs SINGLE
3. check instrument list - what new ones need to be obtained SINGLE
4. extract updated instrument list from traits A and B PARALLEL
5. perform analysis on extracted data PARALLEL
6. update inventory
7. upload to neo4j

---

## To do

At the moment a lot is hard coded. Need to make it flexible such that new incoming data leads to a separate instance of the whole pipeline, with the new IDs determining how things are run

Also, need to copy across any new elastic files and update bcf directory

- use `config.json` for paths
- migrate to `mrever` R package
- generate per-variant heterogeneity stats

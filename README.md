# MR-EVE

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

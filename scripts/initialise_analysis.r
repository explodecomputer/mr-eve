stopifnot(basename(getwd()) == "mr-eve")


library(makemreve)
library(argparse)
library(data.table)


library(argparse)

# create parser object
parser <- ArgumentParser()
parser$add_argument('--candidate', required=TRUE)
parser$add_argument('--data-dir', required=TRUE)
parser$add_argument('--required-files', required=FALSE, default='harmonised.bcf')

args <- parser$parse_args()

candidate <- fread(args[["candidate"]], header=FALSE)
names(candidate) <- c("trait_a", "trait_b", "method")
traitlist <- unique(c(candidate$trait_a, candidate$trait_b))

o <- check_candidate_ids(traitlist, args[["data_dir"]], args[["required_files"]])

candidate <- subset(candidate, trait_a %in% o & trait_b %in% o)
stopifnot(nrow(candidate) > 0)

candidate <- initialise_analysis(candidate)

dir.create(file.path("slices", candidate$slice[1]), recursive=TRUE)

save(candidate, file=file.path("slices", candidate$slice[1], "candidate.rdata"))
write.table(unique(c(candidate$trait_a, candidate$trait_b)), file=file.path("slices", candidate$slice[1], "traitlist.txt"), row=F, col=F, qu=F)

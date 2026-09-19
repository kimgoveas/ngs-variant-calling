#!/usr/bin/env bash
# Stage 3: work out where in the reference each fragment originated.
#
# bwa index builds a searchable index of the reference first - without it,
# locating each 150 bp read in an 80 kb reference thousands of times over
# would be far slower.
set -euo pipefail

PROJECT=~/final_project
REF="$PROJECT"/data/ref_genome/project_reference.fa

module load spack
module load bwa

cd "$PROJECT"
bwa index "$REF"

for sample in projectA projectB
do
    bwa mem "$REF" \
        data/trimmed_fastq/"${sample}"_R1.trim.fastq \
        data/trimmed_fastq/"${sample}"_R2.trim.fastq \
        > results/sam/"${sample}"_R.aligned.sam
done

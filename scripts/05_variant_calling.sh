#!/usr/bin/env bash
# Stage 5: find positions where the reads disagree with the reference.
#
#   mpileup   - walk the reference position by position and tabulate what every
#               overlapping read says at that spot. No decisions, just counting.
#   call      - decide, per position, whether the tally is better explained by a
#               real genetic difference or by sequencing error.
#               --ploidy 1 assumes one chromosome copy (see 06 for why that matters)
#               -m  multiallelic caller
#               -v  output variant sites only
#   varFilter - final screen on coverage, quality and suspicious call clusters
set -euo pipefail

PROJECT=~/final_project
REF="$PROJECT"/data/ref_genome/project_reference.fa

module load spack
module load bcftools

cd "$PROJECT"

for sample in projectA projectB
do
    bcftools mpileup -O b -o results/bcf/"${sample}"_R_raw.bcf \
        -f "$REF" results/bam/"${sample}"_R.aligned.sorted.bam

    bcftools call --ploidy 1 -m -v \
        -o results/vcf/"${sample}"_R_variants.vcf \
        results/bcf/"${sample}"_R_raw.bcf

    vcfutils.pl varFilter results/vcf/"${sample}"_R_variants.vcf \
        > results/vcf/"${sample}"_R_final_variants.vcf

    printf '%s final variant count: ' "${sample}"
    grep -v "#" results/vcf/"${sample}"_R_final_variants.vcf | wc -l
done

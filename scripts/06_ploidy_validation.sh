#!/usr/bin/env bash
# Stage 6: test whether the negative result is real or an artefact of the
# ploidy assumption.
#
# Stage 5 called with --ploidy 1, which assumes a single chromosome copy and so
# a single base at every position. That is right for bacteria, which is where
# the workflow came from. Human genomes are diploid, and inherited cancer
# variants are usually heterozygous - carried on one copy and not the other, so
# only about half the reads at that position show it. A haploid model has no way
# to represent that and would treat the mixed signal as error.
#
# Re-calling at --ploidy 2 from the existing BCF files is cheap: no re-alignment
# needed, the pileup is already computed.
set -euo pipefail

PROJECT=~/final_project

module load spack
module load bcftools

cd "$PROJECT"

for sample in projectA projectB
do
    bcftools call --ploidy 2 -m -v \
        -o results/vcf/"${sample}"_R_variants_p2.vcf \
        results/bcf/"${sample}"_R_raw.bcf

    echo "=== ${sample} at ploidy 2 ==="
    bcftools view -H results/vcf/"${sample}"_R_variants_p2.vcf
done

# What to look at in any record that appears:
#   QUAL   confidence that anything differs here. Below ~10 is not credible.
#   DP     total read depth at the position.
#   DP4    ref-forward, ref-reverse, alt-forward, alt-reverse. A true
#          heterozygote should show roughly half the reads supporting the alt.
#   MQ     mapping quality. High MQ with low QUAL means the reads are placed
#          confidently but the base call itself is uncertain.
#   GT/PL  genotype and phred-scaled likelihoods (lower = more likely, best
#          normalised to 0). A small gap between the het and hom-ref
#          likelihoods means the caller cannot distinguish them.

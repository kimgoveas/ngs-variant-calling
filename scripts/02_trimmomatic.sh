#!/usr/bin/env bash
# Stage 2: remove adapter sequence and low-quality read tails.
#
#   ILLUMINACLIP  - find and cut the Nextera paired-end adapters. Adapters are
#                   synthetic handles added during library prep; when a fragment
#                   is shorter than the read length the sequencer reads into them.
#   SLIDINGWINDOW:4:20 - slide a 4-base window along the read and truncate once
#                   mean quality inside it drops below Q20 (1-in-100 error rate).
#   MINLEN:25     - discard reads shorter than 25 bp after trimming, since very
#                   short reads map to too many places to be informative.
set -euo pipefail

PROJECT=~/final_project
ADAPTERS=/opt/ohpc/pub/apps/spack/local/linux-rocky9-haswell/gcc-11.5.0/trimmomatic-0.39-pbqavdro5c7bciyithpfahjoimbqj6dk/share/adapters/NexteraPE-PE.fa

module load spack
module load trimmomatic

cd "$PROJECT"/data/untrimmed_fastq

for infile in *_R1.fastq
do
    base=$(basename "${infile}" _R1.fastq)
    trimmomatic PE "${infile}" "${base}"_R2.fastq \
        "${base}"_R1.trim.fastq "${base}"_R1un.trim.fastq \
        "${base}"_R2.trim.fastq "${base}"_R2un.trim.fastq \
        SLIDINGWINDOW:4:20 MINLEN:25 \
        ILLUMINACLIP:"${ADAPTERS}":2:40:15
done 2> "$PROJECT"/docs/trimmomatic.log

mv ./*.trim* "$PROJECT"/data/trimmed_fastq/

# Survival rates. Forward/Reverse Only Surviving should ideally be 0, meaning
# no fragment lost one of its two ends.
grep -E 'Input Read Pairs' "$PROJECT"/docs/trimmomatic.log

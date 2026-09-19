#!/usr/bin/env bash
# Stage 4: housekeeping. None of this changes the data, it just organises the
# alignments so the variant caller can work through them position by position.
#
#   view -S -b  - SAM (text) to BAM (compressed binary)
#   sort        - order reads by reference coordinate rather than by the order
#                 BWA happened to emit them, so all reads covering a position sit together
#   index       - build a lookup table for random access
set -euo pipefail

PROJECT=~/final_project

module load spack
module load samtools

cd "$PROJECT"

for sample in projectA projectB
do
    samtools view -S -b results/sam/"${sample}"_R.aligned.sam \
        > results/bam/"${sample}"_R.aligned.bam

    samtools sort -o results/bam/"${sample}"_R.aligned.sorted.bam \
        results/bam/"${sample}"_R.aligned.bam

    samtools index results/bam/"${sample}"_R.aligned.sorted.bam

    echo "--- ${sample} ---"
    samtools flagstat results/bam/"${sample}"_R.aligned.sorted.bam | head -5
    printf 'mean depth: '
    samtools depth -a results/bam/"${sample}"_R.aligned.sorted.bam \
        | awk '{s+=$3; n++} END {printf "%.1fx over %d bp\n", s/n, n}'
done

#!/usr/bin/env bash
# Stage 1: build the project directory tree and run quality control on the raw reads.
# FastQC checks each read file against ~10 diagnostic modules and reports PASS/WARN/FAIL.
set -euo pipefail

PROJECT=~/final_project

mkdir -p "$PROJECT"/{docs,data/{ref_genome,trimmed_fastq,untrimmed_fastq}}
mkdir -p "$PROJECT"/results/{sam,bam,bcf,vcf,fastqc_untrimmed_reads}

# The 4 project FASTQ files go in data/untrimmed_fastq/ and project_reference.fa
# goes in data/ref_genome/ before running this.

module load spack
module load fastqc

cd "$PROJECT"/data/untrimmed_fastq
fastqc *.fastq*

# Keep the reports with the results, not next to the raw data
mv ./*.zip  "$PROJECT"/results/fastqc_untrimmed_reads/
mv ./*.html "$PROJECT"/results/fastqc_untrimmed_reads/

# Unpack each report so the plain-text summaries become readable
cd "$PROJECT"/results/fastqc_untrimmed_reads
for filename in *.zip
do
    unzip -q "$filename"
done

# Collapse all 40 module results (4 files x 10 modules) into one file.
# Much faster to compare samples this way than opening four HTML reports.
cat ./*/summary.txt > "$PROJECT"/docs/fastqc_summaries.txt

echo "FastQC complete. Summary: $PROJECT/docs/fastqc_summaries.txt"
grep -c FAIL "$PROJECT"/docs/fastqc_summaries.txt || true

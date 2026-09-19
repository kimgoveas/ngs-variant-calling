# Genomic Variant Analysis: Testing for a Breast Cancer Variant

An end-to-end NGS variant-calling pipeline built in bash, testing two paired-end DNA samples for a specific breast cancer variant.

Kimberley Catherine Goveas · Bioinformatics (BIOL 550), MS Data Science · Illinois Institute of Technology · Fall 2025

---

## The problem

This was the final project for my Bioinformatics course. I was handed two paired-end DNA samples, Project A and Project B, and asked a simple-sounding question: is a specific breast cancer variant present in either one?

Each sample arrived as 3,000 read pairs of 150 bp, to be compared against an 80,000 bp reference contig. No pre-written pipeline and no detailed instructions, just the tools, a cluster, and the question. I built the whole thing at the command line on my university's HPC system.

What I found genuinely interesting about this project is that producing an answer turned out to be the easy half. Deciding whether that answer could be trusted took considerably more thought, and it's the part I'd point to first: [Validating the result](#validating-the-result).

## Pipeline

```
FASTQ ──▶ FastQC ──▶ Trimmomatic ──▶ BWA ──▶ SAMtools ──▶ bcftools ──▶ VCF
          quality     adapter &      align   sort &      mpileup &
          check       quality trim           index       call
```

| Stage | Tool | What it answers |
|---|---|---|
| Quality control | FastQC | Is the raw data good enough to use? |
| Trimming | Trimmomatic 0.39 | Can I strip adapters and bad tails without losing too much data? |
| Alignment | BWA-MEM | Where in the reference did each fragment come from? |
| Processing | SAMtools | Compress, sort by position, index for fast access |
| Variant calling | bcftools | At each position, do the reads show a real genetic difference? |
| Filtering | vcfutils.pl | Does anything fail coverage or quality thresholds? |

Scripts run in order:

```
scripts/
├── 01_setup_and_fastqc.sh      directory structure + FastQC on all 4 read files
├── 02_trimmomatic.sh           paired-end adapter and quality trimming
├── 03_bwa_align.sh             index reference, align both samples
├── 04_samtools_process.sh      SAM → BAM, sort, index
├── 05_variant_calling.sh       mpileup, call, filter
└── 06_ploidy_validation.sh     re-call at diploid to stress-test the result
```

## Results

### Read quality

Four HTML reports is four too many to read one at a time, so I collapsed every module result into a single file and compared them side by side:

```bash
cat */summary.txt > ~/final_project/docs/fastqc_summaries.txt
```

| Read file | Failures | Warnings | Per-base quality |
|---|---|---|---|
| projectA_R1 | Adapter content | — | Pass |
| projectA_R2 | — | Per-base quality, per-base content, GC content | Warn (weakest of the four) |
| projectB_R1 | Adapter content | — | Pass |
| projectB_R2 | — | Per-base content | Pass |

Adapter contamination in the forward reads was my only real failure, and it turns out that's good news rather than bad. Adapters are the synthetic handles the lab glues onto every fragment so the sequencer has something to grip. When a fragment happens to be shorter than 150 bp, the machine reads straight through the real DNA and off into the adapter. So a FAIL here doesn't mean the samples are bad. It means the trimming step I was about to run is doing something necessary.

Full output: [`docs/fastqc_summaries.txt`](docs/fastqc_summaries.txt)

### Trimming

| Sample | Input pairs | Both surviving | Dropped | Orphaned |
|---|---|---|---|---|
| Project A | 3,000 | 2,833 (94.43%) | 167 (5.57%) | 0 |
| Project B | 3,000 | 2,827 (94.23%) | 173 (5.77%) | 0 |

Around 6% loss is the sweet spot: enough to show the trimming is working, not so much that I've thrown away real data.

The column I actually care most about is the last one. Every time one read of a pair gets destroyed, its partner becomes an orphan. Still usable, but you've lost the pairing information that made paired-end sequencing worth doing. Zero orphans in both samples means every surviving fragment kept both of its ends.

### Alignment

Both samples aligned at a mean depth of about **10x** across the full 80,000 bp, at mapping quality 60. Every position was independently covered by roughly ten overlapping fragments.

That redundancy is the whole foundation of variant calling, and it clicked for me here: one read disagreeing with the reference is indistinguishable from a machine error. Ten reads agreeing is evidence. Coverage is what turns a guess into a measurement.

### Variant calling

```bash
grep -v "#" results/vcf/projectA_R_final_variants.vcf | wc -l   # 0
grep -v "#" results/vcf/projectB_R_final_variants.vcf | wc -l   # 0
```

Zero variants in both samples, which points to the variant being absent. But a zero is only as good as the method that produced it, so that wasn't where I stopped.

My submitted answers for the course deliverable are in [`docs/deliverable_answers.md`](docs/deliverable_answers.md).

## Validating the result

Here's where it got interesting.

A negative result only means something if the method was capable of finding a positive one, so I went back to the parameter I trusted least.

Variant calling needs an assumption about **ploidy**, meaning how many copies of each chromosome an organism carries. I had called with `--ploidy 1`, which assumes one copy and therefore one base at every position. Perfectly correct for bacteria, which is exactly where the workflow I'd been following came from.

But human genomes are diploid, and inherited cancer variants are usually **heterozygous**: sitting on one chromosome copy and not the other, so only about half the reads covering that position carry the variant. A haploid model has no way to represent that state. Faced with a 50/50 split, it would most likely write the whole thing off as sequencing error.

Which meant my pipeline might have been structurally blind to the exact thing I was hunting for. So I re-called both samples at `--ploidy 2`, straight from the existing BCF files. No re-alignment needed, since the pileup was already computed.

Each sample came back with exactly one candidate:

| Sample | Position | Change | QUAL | Depth | Reads supporting |
|---|---|---|---|---|---|
| Project A | 35,816 | C → A | 5.51 | 9 | 2 of 9 (22%) |
| Project B | 36,223 | A → G | 4.87 | 8 | 2 of 8 (25%) |

And then I had to decide whether to believe them. Three reasons I don't:

**1. QUAL near 5 is barely a signal.** That works out to roughly a 30% chance nothing is there at all. Calls I'd trust sit above QUAL 30, which is under 1 in 1,000. The genotype likelihoods told the same story: only 38 phred-scaled units separated "heterozygous variant" from "no variant, two sequencing errors." The caller genuinely couldn't tell the two apart.

**2. The allele balance is wrong.** A real heterozygote should turn up in about half the reads. At 8 to 9x depth that's four or five. Two supporting reads is much closer to the platform's background error rate than to a genuine het.

**3. The candidates are at different positions.** This is the one that settles it for me. A variant deliberately planted in both samples would appear at the *same* coordinate in each. One blip at 35,816 in A and an unrelated blip 400 bp away at 36,223 in B is just random error showing up in two different places, which is precisely what random error does.

Mapping quality was 60 at both positions, so the reads were confidently placed. The uncertainty was in the base call, not the alignment.

**Conclusion: the variant is not present in either sample, and that holds under both the haploid and diploid models.** I'd rather be able to say that than simply report a zero.

## Limitations

- **10x coverage is modest.** A variant present at low allele fraction, as in a heterogeneous tumour sample, could sit below the detection threshold at this depth.
- **One contig.** This says nothing about variants outside the 80,000 bp region I was given.
- **No positive control.** To *demonstrate* sensitivity rather than argue for it, I'd run a sample carrying a known variant and confirm the pipeline recovers it. That's the first thing I'd add with more time.

## Running it

```bash
# On an HPC cluster with environment modules:
module load spack
module load fastqc trimmomatic bwa samtools bcftools

bash scripts/01_setup_and_fastqc.sh
bash scripts/02_trimmomatic.sh
bash scripts/03_bwa_align.sh
bash scripts/04_samtools_process.sh
bash scripts/05_variant_calling.sh
bash scripts/06_ploidy_validation.sh
```

**A note on the data:** the FASTQ files and reference contig were provided as course materials, so I'm not redistributing them here. The scripts expect them at `data/untrimmed_fastq/` and `data/ref_genome/project_reference.fa`.

The `ILLUMINACLIP` path in `02_trimmomatic.sh` points at the adapter file on my cluster's Spack installation and will need changing elsewhere.

## Tools

bash/zsh · FastQC · Trimmomatic 0.39 · BWA · SAMtools · bcftools · vcfutils.pl · IGV

Environment: Illinois Tech HPC cluster (Rocky Linux 9, Spack modules)

# Final Deliverable Answers

## 1. FastQ Results for untrimmed reads

Untrimmed R1 (Project A):
-> Mostly PASS

Untrimmed R2 (Project A):
-> Slightly worse than A_R1
-> WARN for per base sequence quality, per base sequence content, per sequence GC content
-> Adapter Content is a PASS, so no FAILs for this read

Untrimmed R1 (Project B):
-> Mostly PASS

Untrimmed R2 (Project B):
-> Similar to B_R1 but with slightly lower quality scores
-> WARN for per base sequence content
-> Adapter Content is a PASS, so no FAILs for this read

Best per-base sequence quality:
ProjectA_R1, ProjectB_R1, and ProjectB_R2 (All show "PASS" for Per base sequence quality module)

Worst per-base sequence quality:
ProjectA_R2 (this one has a WARN on Per base sequence quality)

The tests that each sample failed:
- projectA_R1 –> FAIL: Adapter Content
- projectA_R2 –> FAIL: None (only WARNs)
- projectB_R1 –> FAIL: Adapter Content
- projectB_R2 –> FAIL: None (one WARN)

-> All other modules passed in each sample.


## 2) Trimmomatic Results

Percentage of reads discarded and kept from both samples:

Project A:
- Input Read Pairs = 3000
- Both Surviving = 2833 (94.43%)
- Forward-Only = 0 (0%), Reverse-Only = 0 (0%) 
- Dropped = 167 (5.57%)  
-> 94.43% kept, 5.57% discarded

Project B:
- Input Read Pairs = 3000
- Both Surviving = 2827 (94.23%)
- Forward-Only = 0 (0%), Reverse-Only = 0 (0%) 
- Dropped = 173 (5.77%)
-> 94.23% kept, 5.77% discarded


## 3) Variant Results

Counts of variants found:
projectA_R_final_variants.vcf = 0  
projectB_R_final_variants.vcf = 0

Is the breast-cancer variant present?
No, because both final VCFs have zero variant records (no variants passed the quality filters in the final output).

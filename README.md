# hybracter
Hybrid (and long-only) bacterial assembly pipeline for many isolates using Snakemake and [Snaketool](https://github.com/beardymcjohnface/Snaketool)

## Quick Start

`hybracter` is available to install from source only for now

```
git clone "https://github.com/gbouras13/hybracter.git"
cd hybracter/
pip install -e .
hybracter --help
hybracter run --help
```

<p align="center">
  <img src="img/hybracter.png" alt="Hybracter" height=600>
</p>

## Description

`hybracter` is designed for assembling many bacterial isolate genomes using the embarassingly parallel power of HPC and Snakemake profiles. It is designed for applications where you have a number of isolates with ONT long reads and optionally matched paired end short reads for polishing.

If you are looking for the best possible manual bacterial assembly on few isolates, definitely use [Trycyler](https://github.com/rrwick/Trycycler) - though I would recommend using [Unicycler](https://github.com/rrwick/Unicycler) or my own program [plassembler](https://github.com/gbouras13/plassembler) (built into hybracter) separately to assemble plasmids if you are especially interested in those.

In general, if you haven't, you should also read Ryan Wick's [tutorial](https://github.com/rrwick/Perfect-bacterial-genome-tutorial) and associated [paper](https://doi.org/10.1371/journal.pcbi.1010905).

If you are looking for an automated program for bacterial assembly on isolates one at a time, particuarly if you are familiar with [Shovill](https://github.com/tseemann/shovill), you can also use [Dragonflye](https://github.com/rpetit3/dragonflye). Dragonflye shares much of the same functionality as hybracter but with some differences, particularly in the way it handles the chromosome vs plasmid assembly & completeness.

For now I would recommend running hybracter on Linux machines (ideally a cluster), as medaka (ONT's long read polisher) is not supported on MacOS.

Pipeline
==========

1. Long-read QC: filtlong for quality and porechop for adapters (qc.smk)
2. Long-read only assembly with Flye (assemble.smk)
3. Combine flye assembly stats (assembly_statistics.smk)
4. Extract chromosome if over the specified minChromLength (extract_fastas.smk) - assumes haploid bacteria!

Completeness & Long Read Polishing
===========

At this point, the pipeline splits in 2 - complete vs incomplete. This is helpful for knowing that you should get your friendly local wet-lab colleague to fire up the MinION and get you some more reads for the incomplete isolates.

For "complete" assemblies, chromosomes are polished with medaka, reorient with dnaapler so it begins with dnaA gene, then polish again with medaka (long_read_polish.smk)

For incomplete assemblies, the entire assembly is simply polished with medaka (long_read_incomplete.smk).

Short Read Polishing
===========

If you have short reads the following steps will occur:

1. Polish the assembly (complete or not) with short reads with Polypolish (short_read_polish.smk and short_read_polish_incomplete.smk).

If you choose to polish with polca:

2. Polish with short reads with polca (short_read_polish.smk).

Plassembler
===========

Finally, I run [plassembler](https://github.com/gbouras13/plassembler) on hybrid assemblies

1. Use plassembler to assembly plasmids and calculate copy number (plassembler.smk).
2. Combine plassembler output for each sample into one file (combine_plassembler_info.smk).

Work in Progress
==========
* Auto-skipping plassembler for incomplete assemblies.

Input
=======

* hybracter requires an input csv file with 5 columns if running hybrid, or 3 columns if running in long-only mode
* Each row is a sample
* Column 1 is the sample name, column 2 is the long read ONT fastq file , column 3 is the minChromLength for that sample
* For hybrid, column 4 is the R1 short read fastq file, column 5 is the R2 short read fastq file.
* minChromLength is the minimum chromosome length (bp) that hybracter will consider as a "complete" chromosome for that sample. It is required to be an integer e.g. 2000000 for 2Mbp.
* No headers

e.g.

Hybrid

sample1,sample1_long_read.fastq.gz,2000000,sample1_SR_R1.fastq.gz,sample1_SR_R2.fastq.gz
sample2,sample2_long_read.fastq.gz,1500000,sample2_SR_R1.fastq.gz,sample2_SR_R2.fastq.gz

Long Only

sample1,sample1_long_read.fastq.gz,2000000

sample2,sample2_long_read.fastq.gz,1500000


Usage
=======

```
hybracter run --input <input.csv> --output <output_dir> --threads <threads>
```

hybracter will run in hybrid mode by default. To specify long-read only, specify `--long`

```
hybracter run --input <input.csv> --output <output_dir> --threads <threads> --long
```

hybracter will not use polca as a polisher by default. To use polca specify `--polca`

```
hybracter run --input <input.csv> --output <output_dir> --threads <threads> --polca
```

I would highly highly recommend running hybracter using a Snakemake profile. Please see this blog [post](https://fame.flinders.edu.au/blog/2021/08/02/snakemake-profiles-updated) for more details. I have included an example slurm profile in the profile directory, but check out this [link](https://github.com/Snakemake-Profiles) for more detail on other HPC job scheduler profiles.

```
hybracter run --input <input.csv> --output <output_dir> --threads <threads> --polca --profile profiles/hybracter
```

Assessing Quality
================

https://github.com/rrwick/Perfect-bacterial-genome-tutorial/wiki/Assessing-quality-without-a-reference

Assessing with ALE

If you have short reads, then running ALE to get an ALE score is the best option. Larger ALE scores are better, and since ALE scores are negative, 'larger' means scores with a smaller magnitude and are closer to zero.

To make this easier, we have created the ale_score.sh script (which you can find in the scripts directory of this repo). Just give it the assembly, the two Illumina read files and a thread count like this:

ale_score.sh assembly.fasta reads/illumina_1.fastq.gz reads/illumina_2.fastq.gz 16
And it will produce a file (the assembly filename with .ale appended) which contains the ALE score.

Assessing with Prodigal

If you don't have short reads, then you can run Prodigal and calculate the mean length of predicted proteins. Larger is better because assembly errors (especially indels) often create stop codons.

To make this easier, we have created the mean_prodigal_length.sh script (which you can find in the scripts directory of this repo). Just give it the assembly like this:

mean_prodigal_length.sh assembly.fasta
And it will produce a file (the assembly filename with .prod appended) which contains the mean Prodigal length
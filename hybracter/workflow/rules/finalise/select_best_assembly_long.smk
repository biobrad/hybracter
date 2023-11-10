"""
aggregate the pyrdigal mean length cds and finalise
"""


def aggregate_finalise(wildcards):
    # decision based on content of output file
    # Important: use the method open() of the returned file!
    # This way, Snakemake is able to automatically download the file if it is generated in
    # a cloud environment without a shared filesystem.
    with checkpoints.check_completeness.get(sample=wildcards.sample).output[
        0
    ].open() as f:
        if f.read().strip() == "C":  # complete
            return os.path.join(
                dir.out.ale_scores_complete, "{sample}", "pypolca.score"
            )
        else:  # incomplete
            return os.path.join(
                dir.out.ale_scores_incomplete, "{sample}", "pypolca_incomplete.score"
            )


rule dnaapler_pre_chrom:
    """
    Runs dnaapler to begin pre polished chromosome 
    In case it is chosen as best
    """
    input:
        fasta=os.path.join(dir.out.chrom_pre_polish, "{sample}_chromosome.fasta"),
    output:
        fasta=os.path.join(
            dir.out.dnaapler, "{sample}_pre_chrom", "{sample}_reoriented.fasta"
        ),
    conda:
        os.path.join(dir.env, "dnaapler.yaml")
    params:
        dir=os.path.join(dir.out.dnaapler, "{sample}_pre_chrom"),
    resources:
        mem_mb=config.resources.med.mem,
        mem=str(config.resources.med.mem) + "MB",
        time=config.resources.med.time,
    threads: config.resources.med.cpu
    benchmark:
        os.path.join(dir.out.bench, "dnaapler", "{sample}_pre_chrom.txt")
    log:
        os.path.join(dir.out.stderr, "dnaapler", "{sample}_pre_chrom.log"),
    shell:
        """
        dnaapler all -i {input.fasta} -o {params.dir} -p {wildcards.sample} -t {threads} -a nearest -f 2> {log}
        """


### from the aggregate_finalise function - so it dynamic
rule aggregate_finalise_complete:
    input:
        chrom_pre_polish_fasta=os.path.join(
            dir.out.dnaapler, "{sample}_pre_chrom", "{sample}_reoriented.fasta"
        ),
        medaka_rd_1_fasta=os.path.join(
            dir.out.intermediate_assemblies, "{sample}", "{sample}_medaka_rd_1.fasta"
        ),
        medaka_rd_2_fasta=os.path.join(
            dir.out.intermediate_assemblies, "{sample}", "{sample}_medaka_rd_2.fasta"
        ),
        plassembler_fasta=os.path.join(
            dir.out.plassembler, "{sample}", "plassembler_plasmids.fasta"
        ),
        flye_info=os.path.join(
            dir.out.assembly_statistics, "{sample}_assembly_info.txt"
        ),
        fasta=os.path.join(
            dir.out.dnaapler, "{sample}_pre_chrom", "{sample}_reoriented.fasta"
        ),
    output:
        chromosome_fasta=os.path.join(
            dir.out.final_contigs_complete, "{sample}_chromosome.fasta"
        ),
        total_fasta=os.path.join(dir.out.final_contigs_complete, "{sample}_final.fasta"),
        pyrodigal_summary=os.path.join(
            dir.out.pyrodigal_summary, "complete", "{sample}_summary.tsv"
        ),
        hybracter_summary=os.path.join(
            dir.out.final_summaries_complete, "{sample}_summary.tsv"
        ),
        per_conting_summary=os.path.join(
            dir.out.final_summaries_complete, "{sample}_per_contig_stats.tsv"
        ),
        final_plasmid_fasta=os.path.join(
            dir.out.final_contigs_complete, "{sample}_plasmid.fasta"
        ),
    params:
        complete_flag=True,
        logic=LOGIC,
    resources:
        mem_mb=config.resources.sml.mem,
        mem=str(config.resources.sml.mem) + "MB",
        time=config.resources.sml.time,
    conda:
        os.path.join(dir.env, "pyrodigal.yaml")
    threads: config.resources.med.cpu
    script:
        os.path.join(dir.scripts, "select_best_chromosome_assembly_long_complete.py")


### from the aggregate_finalise function - so it dynamic
rule aggregate_finalise_incomplete:
    input:
        pre_polish_fasta=os.path.join(dir.out.incomp_pre_polish, "{sample}.fasta"),
        medaka_fasta=os.path.join(
            dir.out.medaka_incomplete, "{sample}", "consensus.fasta"
        ),
        flye_info=os.path.join(
            dir.out.assembly_statistics, "{sample}_assembly_info.txt"
        ),
    output:
        total_fasta=os.path.join(
            dir.out.final_contigs_incomplete, "{sample}_final.fasta"
        ),
        pyrodigal_summary=os.path.join(
            dir.out.pyrodigal_summary, "incomplete", "{sample}_summary.tsv"
        ),
        hybracter_summary=os.path.join(
            dir.out.final_summaries_incomplete, "{sample}_summary.tsv"
        ),
        per_conting_summary=os.path.join(
            dir.out.final_summaries_incomplete, "{sample}_per_contig_stats.tsv"
        ),
    params:
        pre_polish_fasta=os.path.join(dir.out.incomp_pre_polish, "{sample}.fasta"),
        medaka_fasta=os.path.join(
            dir.out.medaka_incomplete, "{sample}", "consensus.fasta"
        ),
        logic=LOGIC,
    resources:
        mem_mb=config.resources.sml.mem,
        mem=str(config.resources.sml.mem) + "MB",
        time=config.resources.sml.time,
    conda:
        os.path.join(dir.env, "pyrodigal.yaml")
    threads: config.resources.sml.cpu
    script:
        os.path.join(dir.scripts, "select_best_chromosome_assembly_long_incomplete.py")

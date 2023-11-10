"""
dnaapler custom
"""


rule dnaapler_custom:
    """
    Runs dnaapler to begin  with custom db
    """
    input:
        diffs=os.path.join(
            dir.out.differences, "{sample}", "medaka_round_1_vs_pre_polish.txt"
        ),
        fasta=os.path.join(
            dir.out.intermediate_assemblies, "{sample}", "{sample}_medaka_rd_1.fasta"
        ),
    output:
        fasta=os.path.join(dir.out.dnaapler, "{sample}", "{sample}_reoriented.fasta"),
        version=os.path.join(dir.out.versions, "{sample}", "dnaapler.version"),
    conda:
        os.path.join(dir.env, "dnaapler.yaml")
    params:
        dir=os.path.join(dir.out.dnaapler, "{sample}"),
        custom_db=config.args.dnaapler_custom_db,
    resources:
        mem_mb=config.resources.med.mem,
        mem=str(config.resources.med.mem) + "MB",
        time=config.resources.med.time,
    threads: config.resources.big.cpu
    benchmark:
        os.path.join(dir.out.bench, "dnaapler", "{sample}.txt")
    log:
        os.path.join(dir.out.stderr, "dnaapler", "{sample}.log"),
    shell:
        """
        dnaapler custom -i {input.fasta} -o {params.dir} -p {wildcards.sample} -t {threads} -a nearest -c {params.custom_db} -f 2> {log}
        dnaapler --version > {output.version}
        """

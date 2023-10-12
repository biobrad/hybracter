import glob
import attrmap as ap
import attrmap.utils as au
from pathlib import Path
import os


# Concatenate Snakemake's own log file with the master log file
# log defined below
def copy_log_file():
    files = glob.glob(os.path.join(".snakemake", "log", "*.snakemake.log"))
    if not files:
        return None
    current_log = max(files, key=os.path.getmtime)
    shell("cat " + current_log + " >> " + LOG)


onsuccess:
    copy_log_file()


onerror:
    copy_log_file()


# config file
configfile: os.path.join(workflow.basedir, "../", "config", "config.yaml")


config = ap.AttrMap(config)


# directories
CHECKDB = True  # to check db installations inside directories.smk


include: os.path.join("rules", "preflight", "directories.smk")
# functions
include: os.path.join("rules", "preflight", "functions.smk")


# check db
# from functions.smk
check_db(dir.plassemblerdb)


# samples
include: os.path.join("rules", "preflight", "samples.smk")
# targets
include: os.path.join("rules", "preflight", "targets_long.smk")


### from config files
#  input as csv
INPUT = config.args.input
OUTPUT = config.args.output
LOG = os.path.join(OUTPUT, "hybracter.log")
THREADS = config.args.threads
MIN_LENGTH = config.args.min_length
MIN_QUALITY = config.args.min_quality
MEDAKA_MODEL = config.args.medakaModel
FLYE_MODEL = config.args.flyeModel

# Parse the samples and read files

# for hybracter hybrid
if config.args.single is False:
    dictReads = parseSamples(INPUT, True)  # long flag true
    SAMPLES = list(dictReads.keys())
# for hybracter hybrid-single
else:
    dictReads = {}
    dictReads[config.args.sample] = {}
    dictReads[config.args.sample]["LR"] = config.args.longreads
    dictReads[config.args.sample]["MinChromLength"] = config.args.chromosome
    SAMPLES = [config.args.sample]

##############################
# Import rules and functions
##############################

# qc and host
# depends on whehter --contaminants has been specified and --skip_qc flag activiated
if config.args.contaminants != "none":  # where --contaminants specified
    CONTAM = (
        check_host()
    )  # from functions.smk to make sure the specified file is lambda or a FASTA

    include: os.path.join("rules", "processing", "remove_contaminants_qc.smk")

else:  # where no contaminants to be removed
    if config.args.skip_qc is True:

        include: os.path.join("rules", "processing", "skip_qc.smk")

    else:

        include: os.path.join("rules", "processing", "qc.smk")


# assembly
include: os.path.join("rules", "assembly", "assemble.smk")
# extract chrom
include: os.path.join("rules", "processing", "extract_fastas.smk")
# checkpoint
# needs its own rules for long
include: os.path.join("rules", "completeness", "aggregate_long.smk")
# checkpoint here for completeness
# need long read polish files regardless
include: os.path.join("rules", "polishing", "long_read_polish.smk")
include: os.path.join("rules", "polishing", "long_read_polish_incomplete.smk")


# dnaapler or dnaapler custom
if config.args.dnaapler_custom_db == "none":  # standard - no custom

    include: os.path.join("rules", "polishing", "dnaapler.smk")

else:

    include: os.path.join("rules", "polishing", "dnaapler_custom.smk")


# plassembler  & pyrodigal
include: os.path.join("rules", "assembly", "plassembler_long.smk")
include: os.path.join("rules", "processing", "combine_plassembler_info.smk")
# finalse & pyrodigal
include: os.path.join("rules", "finalise", "select_best_assembly_long.smk")


### rule all
rule all:
    input:
        TargetFilesLong,

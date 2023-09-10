#!/usr/bin/env python3

import pandas as pd
import os
import glob


def combine_sample_plassembler(summary_dir, output):
    # read into list

    # Specify a pattern to match files (e.g., all .txt files)
    pattern = "*.txt"

    # Get a list of files that match the pattern in the directory
    summary_list = glob.glob(os.path.join(summary_dir, pattern))

    # write all the summary dfs to a list
    summaries = []

    for a in summary_list:
        # only if > 0
        if os.path.getsize(a) > 0:
            tmp_summary = pd.read_csv(a, delimiter="\t", index_col=False, header=0)
            summaries.append(tmp_summary)

    # make into combined dataframe
    total_summary_df = pd.concat(summaries, ignore_index=True)
    total_summary_df.to_csv(output, sep=",", index=False)


combine_sample_plassembler(snakemake.input.summary_dir, snakemake.output.out)

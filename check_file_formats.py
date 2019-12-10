import pandas as pd
import sys

def check_file_formats(RNAseq_file, CTCF_file):
    #check rna-seq file
    RNA_seq_data = pd.read_csv(RNAseq_file, sep="\t")
    if "gene_id" and "FPKM" not in set(RNA_seq_data.keys()):
        print("RNA-seq file hasn't nessesary fields as FPKM and gene_id", file=sys.stderr)
        sys.exit(1)

    #check CTCF file
    if CTCF_file.endswith(".gz"):  # check gzipped files
        import gzip
        temp_file = gzip.open(CTCF_file)
    else:
        temp_file = open(CTCF_file)
    Nfields = len(temp_file.readline().strip().split())
    temp_file.close()
    if Nfields<6:
        print("CTCF file has less than 6 columns", file=sys.stderr)
        sys.exit(1)


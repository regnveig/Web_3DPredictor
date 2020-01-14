import pandas as pd
import sys
import gzip
import bz2

def OpenCSVAnyway(filename, module_name, sep='\t'):
    try:
        with open(filename, 'rb') as file_check: is_gz = file_check.read(2).hex() == "1f8b"
        with open(filename, 'rb') as file_check: is_bz2 = file_check.read(3).hex() == "425a68"
    except OSError: 
        print(module_name + ": OS Error", file=sys.stderr)
        return None
    
    try:
        table = pd.read_csv(filename, sep=sep, compression=("gzip" if is_gz else "bz2" if is_bz2 else None))
    except:
        print(module_name + ": Not a CSV table", file=sys.stderr)
        return None
    
    return table

def check_file_formats(RNAseq_file, CTCF_file):

    #check rna-seq file
    
    RNA_seq_data = OpenCSVAnyway(RNAseq_file, "RNA-Seq file")
    if RNA_seq_data is None: sys.exit(1)
    
    if "gene_id" and "FPKM" not in set(RNA_seq_data.keys()):
        print("RNA-seq file does not contain necessary fields (FPKM and/or gene_id)", file=sys.stderr)
        sys.exit(1)

    #check CTCF file

    temp_file = OpenCSVAnyway(CTCF_file, "CTCF file")
    if temp_file is None: sys.exit(1)
    
    if len(temp_file.columns) < 6:
        print("CTCF file has less than 6 columns", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__": 
    check_file_formats(sys.argv[1], sys.argv[2])
    sys.exit(0)

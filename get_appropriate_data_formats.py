from pybiomart import Dataset, Server
import pandas as pd
import logging
import sys

def get_rna_format_for_3DPredictor(RNAseq_file, output_file, genome_assembly):
    RNAseq_data = pd.read_csv(RNAseq_file, sep="\t")
    gene_id_field = 'gene_id'
    RNAseq_data["Gene_ID"] = RNAseq_data[gene_id_field].apply(lambda x: x.split(".")[0])
    dataset = pd.read_csv("input/ensembl_genes/"+genome_assembly+"_ensembl_genes.txt", sep="\t")
    FinalData = pd.merge(left=RNAseq_data,right=dataset,how="inner", left_on="Gene_ID",right_on="Gene stable ID", validate="1:1")

    if len(FinalData) != len(RNAseq_data):
        logging.getLogger(__name__).warning("Some data missing in Ensembl, "+str(len(RNAseq_data)-len(FinalData)) + " out of "+str(len(RNAseq_data)))
    
    FinalData.to_csv(output_file, sep="\t",index=False)

if __name__ == "__main__": 
    try:
        get_rna_format_for_3DPredictor(sys.argv[1], sys.argv[2], sys.argv[3])
        sys.exit(0)
    except:
        sys.exit(1)

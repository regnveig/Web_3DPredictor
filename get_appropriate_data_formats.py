from pybiomart import Dataset, Server
import  pandas as pd
import logging
import sys

# RNA_seq_file = "/mnt/scratch/ws/psbelokopytova/202001051010polina_data/3DPredictor/input/K562/RNA-seq/test_rna-seqPolyA.tsvpre.txt"

def get_rna_format_for_3DPredictor(RNAseq_file, genome_assembly):
    RNAseq_data = pd.read_csv(RNAseq_file, sep="\t")
    gene_id_field = 'gene_id'
    RNAseq_data["Gene_ID"] = RNAseq_data[gene_id_field].apply(lambda x: x.split(".")[0])
    dataset = pd.read_csv("input/ensembl_genes/"+genome_assembly+"_ensembl_genes.txt", sep="\t")
    FinalData = pd.merge(left=RNAseq_data,right=dataset,how="inner", left_on="Gene_ID",right_on="Gene stable ID", validate="1:1")

    if len(FinalData) != len(RNAseq_data):
        logging.getLogger(__name__).warning("Some data missing in Ensembl, "+str(len(RNAseq_data)-len(FinalData)) + " out of "+str(len(RNAseq_data)))
    
    FinalData.to_csv("input/temp_files_for_prediction/RNAseq_pre.txt",sep="\t",index=False)

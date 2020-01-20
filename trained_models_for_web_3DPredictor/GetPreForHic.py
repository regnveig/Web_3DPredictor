import pandas as pd

predicted_contacts_file = ""
out_folder=""

def Pandas2ChrSizes(chrsizes_filename,
                    pandas_df):  # This func takes all the chromosomes from pandas object, find out their sizes and write into file
    chromosomes = pandas_df.ix[:, 0].unique()
    chrsizes_table = pd.DataFrame(columns=chromosomes)

    for i in range(len(chromosomes)):
        buf = pandas_df.loc[pandas_df['chr'] == chromosomes[i]][['contact_st', 'contact_en']]
        max1 = buf.max().max()
        chrsizes_table.at[0, chromosomes[i]] = max1

        print('Completed: {}%'.format(i * 100 // len(chromosomes)), end='\r')

    chr_list = list(chrsizes_table)

    chrsizes_file = open(chrsizes_filename, 'w')

    for j in range(len(chr_list)):
        chrsizes_file.write(chr_list[j] + '\t' + str(chrsizes_table.iloc[0][chr_list[j]]) + '\n')

    chrsizes_file.close()

def Pandas2Pre(pre_filename, pandas_df):  # This func makes pre-HiC file from the pandas object, control or data
    pre_file = open(pre_filename, 'w')
    data_rows = pandas_df.shape[0]

    pandas_df.columns = ["chr1", "start", "end", "count"]
    pandas_df['str1'] = 0
    assert len(pandas_df.loc[(pandas_df['count'] < 0.000001) & (pandas_df['count'] != 0)]) < (len(pandas_df['count']) / 10)
    pandas_df['exp'] = pandas_df['count'] * ( 1000000 )
    pandas_df['exp'] = round(pandas_df['exp']).astype(int)

    pandas_df.to_csv(pre_file, sep=" ",
                     columns=['str1', 'chr1', 'start', 'start', 'str1', 'chr1', 'end', 'end', 'exp'], header=False,
                     index=False)

    pre_file.close()

def getPrefiles(predicted_contacts_file, out_folder):
    predicted_contacts_data = pd.read_csv(predicted_contacts_file, sep="\t")
    chromsizes_filename = out_folder+"pre/chrom.sizes"
    Pandas2ChrSizes(Pandas2ChrSizes(chromsizes_filename, predicted_contacts_data))
    pre_filename = "pre/pre_data.txt"
    Pandas2Pre(pre_filename, predicted_contacts_data)



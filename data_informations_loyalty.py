import pandas as pd
import numpy as np
import os
import sys

output_dir = "./output_csv/"

def get_files_with_prefix(prefix):
    file_names = [f for f in os.listdir(output_dir) if f.startswith(prefix)]
    return sorted([os.path.join(output_dir, f) for f in file_names], key=lambda x: int(x.split('-')[1].split('.')[0]))

def main(csv_files):
    nbs = []
    for file in csv_files:
        nb = file.split('-')[1]
        if nb not in nbs:
            nbs.append(nb)
    
    # Create a DataFrame to store the statistics
    stats = pd.DataFrame(index=nbs, columns=['last_score_mean', 'last_worst_score', 'last_best_score', 'last_score_median', 'first_1_mean'])

    for nb in nbs:
        dfs = []
        for file in csv_files:
            if nb == file.split('-')[1]:
                df = pd.read_csv(file)
                dfs.append(df)

        only_last_row = []
        first_1_list = []
        for i, df in enumerate(dfs):
            only_last_row.append(df.iloc[-1])
            for index, row in df.iterrows():
                if row[1] == 1:
                    first_1_list.append(index)
                    break
            
        last_score_mean = np.mean([x[2] for x in only_last_row])
        last_worst_score = np.min([x[2] for x in only_last_row])
        last_best_score = np.max([x[2] for x in only_last_row])
        last_score_median = np.median([x[2] for x in only_last_row])
        first_1_mean = np.mean(first_1_list)

        stats.loc[nb] = [last_score_mean, last_worst_score, last_best_score, last_score_median, first_1_mean]
    
    # Save the statistics to a new CSV file
    stats.to_csv(f"./stats.csv")

if __name__ == '__main__':
    csv_files = get_files_with_prefix(sys.argv[1])

    main(csv_files)

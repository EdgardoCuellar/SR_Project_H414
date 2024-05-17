import pandas as pd
import numpy as np
import os
import sys

output_dir = "./output_csv/"

def get_files_with_prefix(prefix):
    file_names = [f for f in os.listdir(output_dir) if f.startswith(prefix)]
    return sorted([os.path.join(output_dir, f) for f in file_names], key=lambda x: int(x.split('-')[1].split('.')[0]))

def main(csv_files):
    rab_ranges = []
    omnidirectional_cameras = []
    for file in csv_files:
        omnidirectional_camera = int(file.split('-')[1])
        if omnidirectional_camera not in omnidirectional_cameras:
            omnidirectional_cameras.append(omnidirectional_camera)  
        rab_range = float(file.split('-')[2])
        if rab_range not in rab_ranges:
            rab_ranges.append(rab_range) 
    
    # Create a DataFrame to store the statistics
    stats = pd.DataFrame(index=rab_ranges, columns=omnidirectional_cameras)

    for rab_range in rab_ranges:
        for omnidirectional_camera in omnidirectional_cameras:
            dfs = []
            for file in csv_files:
                if str(rab_range) == file.split('-')[2] and str(omnidirectional_camera) == file.split('-')[1]:
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

            stats.loc[rab_range, omnidirectional_camera] = [last_score_mean, last_worst_score, last_best_score, last_score_median, first_1_mean]

    # Save the statistics to a new CSV file
    stats.to_csv(f"./stats_loyalty.csv")

if __name__ == '__main__':
    csv_files = get_files_with_prefix(sys.argv[1])

    main(csv_files)

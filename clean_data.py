import pandas as pd
import sys
import os

def get_files_with_prefix(dir_path, prefix):
    return [f for f in os.listdir(dir_path) if f.startswith(prefix)]

def main(files_prefix):
    dir_path = "./output_csv/"
    files = get_files_with_prefix(dir_path, files_prefix)

    dfs = []

    # Read each CSV file, retain first and third columns, and append to dfs list
    for file in files:
        df = pd.read_csv(dir_path+file)
        df = df.iloc[:, [0, 2]]  # Retain first and third columns
        dfs.append(df)

    merged_df = pd.concat(dfs).groupby(level=0).mean()

    # Save merged DataFrame to a new CSV file
    merged_df.to_csv("./output_final/"+files_prefix+".csv")


if __name__ == '__main__':
    files_prefix = sys.argv[1]
    main(files_prefix)
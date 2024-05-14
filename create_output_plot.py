import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
import sys

def get_files_with_prefix(dir_path, prefix):
    return [f for f in os.listdir(dir_path) if f.startswith(prefix)]

def main(file_prefix):
    output_dir = "./output_final/"

    files = get_files_with_prefix(output_dir, file_prefix)

    # create me a simple plot using the data from the files, the x-axis range is always 0-6000, and y-axis represent the scores
    # for each file, the line color is different, with the legend showing the file name
    for file in files:
        df = pd.read_csv(output_dir+file)
        plt.plot(np.arange(0, 6000, 100), df.iloc[:, 1], label=file)

    plt.title('Scores over time')
    plt.xlabel('Time')
    plt.ylabel('Score')
    plt.legend()
    plt.show()

if __name__ == '__main__':
    main(sys.argv[1])
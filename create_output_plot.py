import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
import sys

output_dir = "./output_final/"
log = False

def get_files_with_prefix(prefix):
    file_names = [f for f in os.listdir(output_dir) if f.startswith(prefix)]
    return sorted([os.path.join(output_dir, f) for f in file_names], key=lambda x: int(x.split('-')[1].split('.')[0]))

def main(file_prefix, csv_files):
    plt.figure(figsize=(10, 6))

    for file in csv_files:
        # Extract the 'nb' from the file name
        nb = file.split('-')[1].split('.')[0]
        # Read the CSV file and extract necessary data
        df = pd.read_csv(file)
        x = df[df.columns[0]] 
        y = df[df.columns[1]]  

        plt.plot(x, y, label=f"{nb} predators")

    plt.title('Predator-Prey Trap Scalability Simulation Zoomed')
    plt.xlabel('Time')
    plt.ylabel('Score')
    if log:
        plt.yscale('log')
    plt.xlim(5000, 6000)
    plt.ylim(4500, 5800)
    plt.legend()
    plt.grid(True)
    if log:
        plt.savefig(f"./output_plot/{file_prefix}_scalability_log.png", dpi=300)
    else:
        plt.savefig(f"./output_plot/{file_prefix}_scalability_zoom.png", dpi=300)

if __name__ == '__main__':
    csv_files = get_files_with_prefix(sys.argv[1])

    main(sys.argv[1], csv_files)

import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
import sys
import numpy as np

def read_and_combine_csv(file_prefix, output_dir):
    csv_files = glob.glob(os.path.join(output_dir, f"{file_prefix}*.csv"))
    return pd.concat((pd.read_csv(f, usecols=[0, 2], header=None) for f in csv_files), ignore_index=True)

def main(file_prefix, output_dir):
    # Read and combine all CSV files
    combined_data = read_and_combine_csv(file_prefix, output_dir)

    # Group by time and calculate statistics
    grouped_data = combined_data.groupby(0)[2]

    # Calculate statistics for each time point
    time = grouped_data.mean().index
    mean_score = grouped_data.mean()
    median_score = grouped_data.median()
    min_score = grouped_data.min()
    max_score = grouped_data.max()
    q25_score = grouped_data.quantile(0.25)
    q75_score = grouped_data.quantile(0.75)

    # Plot the results
    plt.figure(figsize=(10, 6))

    # Plot the distribution as a shaded area
    plt.fill_between(time, q25_score, q75_score, color='gray', alpha=0.5, label='Interquartile Range')
    plt.fill_between(time, min_score, max_score, color='gray', alpha=0.25, label='Score Range')

    # Plot the mean score
    plt.plot(time, mean_score, color='red', linewidth=2, label=f'Mean Score')

    # Plot the median score
    plt.plot(time, median_score, color='blue', linewidth=2, label=f'Median Score')

    plt.title('20 predators basic settings on 100 simulations log')
    plt.xlabel('Time')
    plt.ylabel('Score')
    plt.yscale('log')
    plt.legend()
    plt.grid(True)

    plt.savefig(f"./output_plot/{file_prefix}_score_distribution_log.png", dpi=300)

if __name__ == '__main__':
    file_prefix = sys.argv[1]
    output_dir = './output_csv/'
    main(file_prefix, output_dir)

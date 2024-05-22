import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
import sys
import matplotlib.cm as cm

output_dir = "./output_final/"
log = False

def get_files_with_prefix(prefix):
    file_names = [f for f in os.listdir(output_dir) if f.startswith(prefix)]
    return sorted([os.path.join(output_dir, f) for f in file_names], 
                  key=lambda x: (float(x.split('-')[1]), float(x.split('-')[2].split('.')[0])))

def main(file_prefix, csv_files):
    plt.figure(figsize=(10, 6))
    
    color_map = plt.get_cmap('tab10')  # Use a predefined colormap
    
    for i, file in enumerate(csv_files):
        rab_range = float(file.split('-')[2][0:-4])
        omnidirectional_camera = float(file.split('-')[1])
        
        # Read the CSV file and extract necessary data
        df = pd.read_csv(file, header=None)
        x = df[0]
        y = df[1]

        color = color_map(i % len(color_map.colors))  # Get color from colormap
        plt.plot(x, y, label=f"{rab_range} rab range, {omnidirectional_camera} omnidirectional camera", color=color)

    plt.title('Predator-Prey Trap Loyalty Simulation Zoomed')
    plt.xlabel('Time')
    plt.ylabel('Score')
    if log:
        plt.yscale('log')
    plt.xlim(5000, 6000)
    plt.ylim(4400, 5600)
    plt.legend()
    plt.grid(True)
    if log:
        plt.savefig(f"./output_plot/{file_prefix}_log.png", dpi=300)
    else:
        plt.savefig(f"./output_plot/{file_prefix}_zoom.png", dpi=300)

if __name__ == '__main__':
    csv_files = get_files_with_prefix(sys.argv[1])
    main(sys.argv[1], csv_files)

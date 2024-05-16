import pandas as pd
import matplotlib.pyplot as plt

# Read the data from the CSV file
df = pd.read_csv("./stats.csv")

# Extracting data
nb_values = df.iloc[:, 0].values
last_score_mean_values = df.iloc[:, 1].values
last_worst_score_values = df.iloc[:, 2].values
last_best_score_values = df.iloc[:, 3].values
last_score_median_values = df.iloc[:, 4].values
first_1_mean_values = df.iloc[:, 5].values

# Create a line plot
plt.figure(figsize=(10, 6))
plt.plot(nb_values, last_score_mean_values, label='Last Score Mean')
plt.plot(nb_values, last_worst_score_values, label='Last Worst Score')
plt.plot(nb_values, last_best_score_values, label='Last Best Score')
plt.plot(nb_values, last_score_median_values, label='Last Score Median')
plt.plot(nb_values, first_1_mean_values, label='First 1 Mean')
plt.title('Statistics vs nb')
plt.xlabel('nb')
plt.ylabel('Value')
plt.legend()
plt.grid(True)
plt.savefig(f"./output_plot/data_stats.png", dpi=300)

# Create a bar plot
plt.figure(figsize=(10, 6))
bar_width = 0.15
index = nb_values
plt.bar(index - 2 * bar_width, last_score_mean_values, bar_width, label='Last Score Mean')
plt.bar(index - bar_width, last_worst_score_values, bar_width, label='Last Worst Score')
plt.bar(index, last_best_score_values, bar_width, label='Last Best Score')
plt.bar(index + bar_width, last_score_median_values, bar_width, label='Last Score Median')
plt.bar(index + 2 * bar_width, first_1_mean_values, bar_width, label='First 1 Mean')
plt.title('Statistics vs nb')
plt.xlabel('nb')
plt.ylabel('Value')
plt.xticks(index, nb_values)
plt.legend()
plt.grid(True)
plt.savefig(f"./output_plot/data_stats_bar.png", dpi=300)

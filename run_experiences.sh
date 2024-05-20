#!/bin/bash

# Number of times to run the experiment
num_experiments=$1
output_name="./multiple_results/experiment_output_$2.txt"
results_sum=0

# Loop for the specified number of experiments
for ((i=1; i<=$num_experiments; i++))
do
    # Generate a random value (between 0 and 255) for the random_seed
    random_value=$((RANDOM % 255))

    # Replace the value of random_seed in line 11 of your document
    sed -i "11s/random_seed=\"[0-9]*\"/random_seed=\"$random_value\"/" predatorprey.argos

    output_name="./output_csv/$2.csv"
    sed -i "s|<loop_functions library=\".*\" label=\"predatorprey\" output=\".*\"/>|<loop_functions library=\"./build/libpredatorprey\" label=\"predatorprey\" output=\"$output_name\"/>|" predatorprey.argos


    # Run your experiment and capture the output
    experiment_output=$(argos3 -c predatorprey.argos)

    # Extract the last line of output
    second_last_line=$(echo "$experiment_output" | tail -n 2)
    line_parsed=$(echo "$second_last_line" | awk -F 'Prey trapped for a total of | time steps' '{print $2}')
    cleaned_value=$(echo "$line_parsed" | sed 's/[^0-9]*//g')
    cleaned_value=$(echo "$cleaned_value" | awk -F '0132|0132' '{print $2}')
    echo "Experiment $i: $cleaned_value"
    results_sum=$(($results_sum + $cleaned_value))
    # Save the last line of output to a file
    echo "Average: $cleaned_value" >> "$output_name"
done

# Calculate the average of the results
average=$(($results_sum / $num_experiments))
echo "Average: $average"
echo "$average" >> "$output_name"

#!/bin/bash

# Number of times to run the experiment
num_experiments=$1

# Loop for the specified number of experiments
for ((q=5; q<=30; q+=5))
do
    for ((i=1; i<=$num_experiments; i++))
    do
        # Generate a random value (between 0 and 255) for the random_seed
        random_value=$((RANDOM % 255))
        # Replace the value of random_seed in line 11 of your document
        sed -i "11s#random_seed=\"[0-9]*\"#random_seed=\"$random_value\"#" predatorprey.argos
        
        sed -i "74s#quantity=\"[0-9]*\"#quantity=\"$q\"#" predatorprey.argos

        output_name="./output_csv/$2-$q-$i.csv"
        sed -i "s|<loop_functions library=\".*\" label=\"predatorprey\" output=\".*\"/>|<loop_functions library=\"./build/libpredatorprey\" label=\"predatorprey\" output=\"$output_name\"/>|" predatorprey.argos

        # Run your experiment and capture the output
        experiment_output=$(argos3 -c predatorprey.argos)

        echo "Experiment $i: $q"
    done
done
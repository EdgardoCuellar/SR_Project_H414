#!/bin/bash

# Number of times to run the experiment
num_experiments=$1
omnidirectional_camera_aperture=52.4
rab_range=0.5

# Loop for the specified number of experiments
for ((o=0; o<=60; o+=30))
do
    for ((r=0; r<=2; r+=1))
    do
        for ((i=1; i<=$num_experiments; i++))
        do
            # Generate a random value (between 0 and 255) for the random_seed
            random_value=$((RANDOM % 255))
            # Replace the value of random_seed in line 11 of your document
            sed -i "11s#random_seed=\"[0-9]*\"#random_seed=\"$random_value\"#" predatorprey.argos
            
            # add r and rab_range
            value_r=$(awk "BEGIN {print $r + $rab_range}")
            sed -i "76s#omnidirectional_camera_aperture=\"[0-9]*\.[0-9]*\"#omnidirectional_camera_aperture=\"$value_r\"#" predatorprey.argos
            value_o=$(awk "BEGIN {print $o + $omnidirectional_camera_aperture}")
            sed -i "76s#rab_range=\"[0-9]*\.[0-9]*\"#rab_range=\"$value_o\"#" predatorprey.argos
            
            output_name="./output_csv/$2-$value_o-$value_r-$i.csv"
            sed -i "s|<loop_functions library=\".*\" label=\"predatorprey\" output=\".*\"/>|<loop_functions library=\"./build/libpredatorprey\" label=\"predatorprey\" output=\"$output_name\"/>|" predatorprey.argos

            # Run your experiment and capture the output
            experiment_output=$(argos3 -c predatorprey.argos)

            echo "Experiment $i: $q"
        done
    done
done
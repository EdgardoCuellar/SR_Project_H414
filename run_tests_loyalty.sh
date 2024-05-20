#!/bin/bash

# Number of times to run the experiment
num_experiments=$1
omnidirectional_camera_aperture=("68.2" "78.69" "82.41" "84.29" "85.43")
rab_range=("0.5" "1.0" "1.5" "2.0" "2.5")

# Loop for the specified number of experiments
for ((j=0; j<5; j+=1))
do
    for ((q=10; q<=20; q+=10))
    do
        for ((i=1; i<=$num_experiments; i++))
        do
            # Generate a random value (between 0 and 255) for the random_seed
            random_value=$((RANDOM % 255))
            # Replace the value of random_seed in line 11 of your document
            sed -i "11s#random_seed=\"[0-9]*\"#random_seed=\"$random_value\"#" predatorprey.argos
            
            sed -i "74s#quantity=\"[0-9]*\"#quantity=\"$q\"#" predatorprey.argos

            # add r and rab_range
            value_o=${omnidirectional_camera_aperture[$j]}
            sed -i "76s#omnidirectional_camera_aperture=\"[0-9]*\.[0-9]*\"#omnidirectional_camera_aperture=\"$value_o\"#" predatorprey.argos

            value_r=${rab_range[$j]}
            sed -i "76s#rab_range=\"[0-9]*\.[0-9]*\"#rab_range=\"$value_r\"#" predatorprey.argos
            
            output_name="./output_csv/$2-$q-$value_o-$value_r-$i.csv"
            sed -i "s|<loop_functions library=\".*\" label=\"predatorprey\" output=\".*\"/>|<loop_functions library=\"./build/libpredatorprey\" label=\"predatorprey\" output=\"$output_name\"/>|" predatorprey.argos

            # Run your experiment and capture the output
            experiment_output=$(argos3 -c predatorprey.argos)

            echo "Experiment $i - rab_range: $value_r, omnidirectional_camera_aperture: $value_o"
        done
    done
done
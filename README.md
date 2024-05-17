# INFO-H414 - Swarm Intelligence Final Project

## Introduction

This project explores swarm intelligence through a predator-prey system where a swarm of robots (predators) must capture an intruder (prey). The goal is to develop and test an offline decentralized algorithm for the predators to keep the prey immobile, emphasizing the advantages of cooperative swarm behavior.

## Methodology

We focus on two key aspects of swarm robotics: scalability and locality. Scalability evaluates performance changes with different swarm sizes, while locality examines the impact of communication and perception distances. Multiple simulations with varying numbers of robots and sensor ranges were conducted to find the best configurations.

## Implementation

- **Simulation Software:** [ARGoS3](https://github.com/ilpincy/argos3)
- **Tests run with:** Bash (Unix shell)
- **Language for the data:** Python 3
- **Libraries:** Matplotlib, Pandas, Numpy

## How to Run
Argos3 should be installed, python3 and the libraries mentioned above should be installed.

**Run Simulations**:
- **Parameter Testing**:
    ```bash
    ./run_experiences.sh
    ```
- **Scalability Testing**:
    ```bash
    ./run_tests.sh
    ```
- **Locality Testing**:
    ```bash
    ./run_tests_loyalty.sh
    ```

## Outputs

- **Detailes of the variables choices**: stored and explained in `multiple_results/best_settings.txt`.
- **Simulation Results**: Stored in `multiple_results` and `output_csv` folders.
- **Data cleaning**: Performed using `clear_data.py`.
- **Output Plots**: Generated using `create_output_plot.py` and `create_output_plot_loyalty.py`.
- **Data Analysis**: Performed using `data_informations.py` and `data_informations_loyalty.py`.

## Results

The results are categorized into two main aspects:

1. **Scalability**: Shows the performance of the swarm with varying numbers of robots.
2. **Locality**: Analyzes the impact of communication and perception ranges on swarm behavior.

## Conclusion

This project shows the importance of scalability and locality in swarm robotics. The devlopped algorithm allows the swarm to capture the prey efficiently, demonstrating the benefits of cooperative swarm intelligence.

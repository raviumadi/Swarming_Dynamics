# Echolocating Bat Swarm Simulation

This repository contains all simulation code and analysis tools used in the study:  
**"Swarm Cohesion in Bats Emerges from Stable Temporal Loops"**

Available at: [will be updated upon (pre)publication]

>Some of the material (`run` and `supplementary material`) are available only on the Figshare Archive: DOI [https://doi.org/10.6084/m9.figshare.29482268.v1](https://doi.org/10.6084/m9.figshare.29482268.v1) 

## Overview

I present a biologically grounded model of swarm dynamics in echolocating bats, where each agent operates asynchronously using echo-timed feedback from its nearest neighbour. The codebase includes:

- Asynchronous swarm simulation (`simulateEcholocationSwarm_async.m`)
- Single-agent biosonar control (`simulateEcholocationWings_singleStep.m`)
- Parameter grid execution scripts
- Analysis and plotting tools for visualisation and summary statistics

The model demonstrates how closed-loop sensory–motor control using echo delays alone enables stable, decentralised group coordination in dense aggregations.

## File Structure

### Simulation Core

- `simulateEcholocationSwarm_async.m`  
  Main simulation function. Models the fully asynchronous swarm using local echo-timed feedback.
  
- `simulateEcholocationWings_singleStep.m`  
  Computes biosonar loop parameters (call rate, delay, echo response) for a single agent.

### Execution Scripts

- `grid_sim_parallel_runs.m`  
  Batch runner for simulation across a grid of conditions (e.g., varying `k_r` and initial velocity). Uses `parfor` for parallel execution.

- `method_demo.m`  
  Basic method demonstration with equations - plot.

### Analysis and Visualisation

- `analyse_swarm_results.m`  
  Parses output logs and extracts collision events, behavioural statistics, and performance metrics.

- `grid_run_summary_plot.m`  
  Generates figures and heatmaps summarising condition-dependent outcomes (collision rates, velocity adaptation, etc).

- `swarm_trajectory_plot.m`  
  Visualises 3D trajectories and behaviours of agents in the swarm.

## Dependencies

- MATLAB R2021a or later
- Parallel Computing Toolbox (for parallel execution)
- May require other toolboxes depending on your version and license of MATLAB.
- Script functions are stored in `fcn`

## Running a Simulation

1. Define simulation parameters in `sim_conditions_grid.csv` or construct a parameter grid in `grid_sim_parallel_runs.m`.
2. Execute the simulation script. All output is stored as `.mat` files with condition-specific filenames.
3. Use analysis tools to extract and visualise results.

```matlab
>> grid_sim_parallel_runs
```

## Other Material

- A supplementary swarm propagation visualisation animation is included in the [figshare](10.6084/m9.figshare.29482268) repo.
- Simulation outputs in `run` are available in the [figshare](10.6084/m9.figshare.29482268) repo. (Due to size limitation in GitHub)
- `tex` folder contains LaTeX table outputs used in the preprint.

## License

This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).


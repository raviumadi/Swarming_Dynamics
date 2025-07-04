
%% This simulation run utilises the parallel computing toolbox. The process is intensive and subject to system hang if other heavy processes are running in parallel. Manage your computational resources accordingly.

clear; close all; clc;
% system('caffeinate -di &'); ensures uninterrupted run

grid = readtable('sim_conditions_grid.csv');
save_base = ''; % create your path
saveData = 1;
N = 50;
max_time = 60;
diary_filename = fullfile(save_base, ['grid_simulation_log_', datestr(now, 'yyyymmdd_HHMMSS'), '.txt']);
diary(diary_filename);
% --- Prebuild params struct array
for k = 1:height(grid)
    paramList(k).kr = grid.kr(k);
    paramList(k).initial_velocity = grid.initial_velocity(k);
    paramList(k).max_call_rate = 200;
    paramList(k).initial_call_duration = 0.010;
    paramList(k).theta = pi/4;
    paramList(k).f_wing = 12;
    paramList(k).motile = true;
    paramList(k).bandwidth = 40:90;
    paramList(k).makeAudio = false;
    paramList(k).wing_sync_mode = 'dynamic';
    paramList(k).max_wingbeat_freq = 7;
    paramList(k).theta_mode = 'fixed';
    paramList(k).min_theta = 0.1 * paramList(k).theta;
    paramList(k).initial_delta_t = 0.03;
    paramList(k).initial_sigma = 2;
end

% --- Preallocate result storage
all_swarm_out = cell(1, height(grid));
all_params = paramList;

parfor k = 1:height(grid)
    p = paramList(k);

    % Create a simulation tag for logging
    sim_tag = sprintf('[kr=%d v0=%d]', p.kr, p.initial_velocity);

    % Optional: also display this tag before running
    disp([sim_tag, ' | Starting simulation']);

    % Run simulation with tag
    all_swarm_out{k} = simulateEcholocationSwarm_async(p, N, max_time, sim_tag);
end
% --- SAVE after parfor
if saveData
    for k = 1:height(grid)
        params = all_params(k);
        swarm_out = all_swarm_out{k};
        save_name = sprintf('swarm_async_kr%d_v%d.mat', ...
                            params.kr, params.initial_velocity);
        save(fullfile(save_base, save_name), 'params', 'swarm_out');
    end
end

diary off;
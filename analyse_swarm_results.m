
%% Swarm Analysis Script
% This script processes all swarm simulation result files stored in /runs
% and generates summary tables, boxplots, and heatmaps for key metrics.

clear; clc;
figDir = '/Users/ravi/Documents/projects/swarm/manuscript/fig';
data_folder = 'runs';  % folder containing .mat files
file_list = dir(fullfile(data_folder, 'swarm_async_kr*_v*.mat'));

all_stats = [];
kr_vals = [];
v0_vals = [];

for k = 1:length(file_list)
    file_name = file_list(k).name;
    full_path = fullfile(data_folder, file_name);

    % Extract kr and v0 from filename
    tokens = regexp(file_name, 'kr(\d+)_v(\d+)', 'tokens');
    if isempty(tokens); continue; end
    kr = str2double(tokens{1}{1});
    v0 = str2double(tokens{1}{2});

    S = load(full_path);
    if isfield(S, 'swarm_out')
        swarm = S.swarm_out.swarm;
    else
        continue
    end

    %% Initialise data collectors
    call_durations = [];
    call_rates = [];
    velocities = [];
    inter_dists = [];

    N = length(swarm);
    for i = 1:N
        call_durations = [call_durations, swarm(i).history.call_duration];
        call_rates = [call_rates, swarm(i).history.call_rate];
        velocities = [velocities, abs(swarm(i).history.v)];
    end

    % Inter-bat distance wrt ref bat
    ref_idx = 1;
    ref_times = swarm(ref_idx).history.time_stamps(1:100:end);
    for iter = 1:length(ref_times)
        t_ref = ref_times(iter);
        pos_ref = swarm(ref_idx).history.position(1 + (iter-1)*100, :);
        for j = 1:N
            if j == ref_idx; continue; end
            t_j = swarm(j).history.time_stamps;
            idx_j = find(t_j <= t_ref, 1, 'last');
            if ~isempty(idx_j)
                pos_j = swarm(j).history.position(idx_j,:);
                d = norm(pos_j - pos_ref);
                inter_dists = [inter_dists, d];
            end
        end
    end

    % Summary stats
    stats.kr = kr;
    stats.v0 = v0;

    % Call duration (ms)
    stats.call_duration_mean = mean(call_durations) * 1000;
    stats.call_duration_median = median(call_durations) * 1000;
    stats.call_duration_std = std(call_durations) * 1000;

    % Call rate (Hz)
    stats.call_rate_mean = mean(call_rates);
    stats.call_rate_median = median(call_rates);
    stats.call_rate_std = std(call_rates);

    % Velocity (m/s)
    stats.velocity_mean = mean(velocities);
    stats.velocity_median = median(velocities);
    stats.velocity_std = std(velocities);

    % Inter-individual distance (m)
    stats.inter_dist_mean = mean(inter_dists);
    stats.inter_dist_median = median(inter_dists);
    stats.inter_dist_std = std(inter_dists);

    all_stats = [all_stats; stats];
    kr_vals = [kr_vals; kr];
    v0_vals = [v0_vals; v0];
end

%% Convert to table
stats_table = struct2table(all_stats);
% save('stats_table.mat', 'stats_table')
% export to latex - further format the .tex file for final inclusion
% table2latex_stats(stats_table, 'swarm_stats.tex');
%% Heatmaps
% Ensure kr_unique and v0_unique are defined
kr_unique = unique(stats_table.kr);
v0_unique = unique(stats_table.v0);
n_kr = length(kr_unique);
n_v0 = length(v0_unique);

% Initialise matrices
Z_dist = nan(n_kr, n_v0);
Z_duration = nan(n_kr, n_v0);
Z_callrate = nan(n_kr, n_v0);

% Fill in values
for i = 1:height(stats_table)
    r = find(kr_unique == stats_table.kr(i));
    c = find(v0_unique == stats_table.v0(i));
    Z_dist(r,c) = stats_table.inter_dist_mean(i);
    Z_duration(r,c) = stats_table.call_duration_mean(i);
    Z_callrate(r,c) = stats_table.call_rate_mean(i);
end

% Plot
figure('Position', [300 300 1200 400]);

all_Z = {Z_dist, Z_callrate, Z_duration};
titles = {'Mean Inter-bat Distance (m)', 'Mean Call Rate (Hz)', 'Mean Call Duration (ms)'};
clabels = {'Distance (m)', 'Rate (Hz)', 'Duration (ms)'};

for k = 1:3
    subplot(1,3,k);
    imagesc(v0_unique, kr_unique, all_Z{k});
    set(gca, 'YDir', 'normal');
    axis square;
    xticks(v0_unique);
    yticks(kr_unique);
    
    xlabel('$\mathrm{Initial~velocity~} v_0$ (m/s)', 'Interpreter','latex');
    if k == 1
        ylabel('Responsivity coefficient $k_r$', 'Interpreter','latex');
    end
    title(titles{k}, 'Interpreter','latex');
    formatLatex(gca);
    grid off;
    % Colourbar with LaTeX
    cb = colorbar;
    cb.Label.String = clabels{k};
    cb.Label.Interpreter = 'latex';
    cb.TickLabelInterpreter = 'latex';

    % Add text labels on tiles
    [nr, nc] = size(all_Z{k});
    clim = caxis;
    threshold = mean(clim);
    for i = 1:nr
        for j = 1:nc
            val = all_Z{k}(i,j);
            if ~isnan(val)
                txt_colour = 'w';
                if val > threshold
                    txt_colour = 'k';
                end
                text(v0_unique(j), kr_unique(i), sprintf('%.1f', val), ...
                    'HorizontalAlignment','center','Color', txt_colour, ...
                    'FontSize', 9, 'FontWeight','bold');
            end
        end
    end
end

sgtitle('Swarm Parameter Effects of $v_0$ and $k_r$', 'Interpreter','latex', 'FontSize', 16);
% saveFigure(gcf, figDir, 'grid_swarm_summary_heatmaps')
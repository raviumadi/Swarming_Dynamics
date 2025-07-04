%% Figure 5 in preprint
% load data
% figDir = '';
T = extractCollisionEventsFromLog('runs/grid_simulation_log_20250628_141450.txt');
%% --- Raster plot: kr vs time, color/marker by v0 ---
figure('Units', 'pixels', 'Position', [100, 100, 1200, 400]);
hold on;
v0_vals = unique(T.v0);
colors = lines(length(v0_vals));
markers = {'o','s','^','d','v','x','+','*'};

for i = 1:length(v0_vals)
    idx = T.v0 == v0_vals(i);
    scatter(T.time(idx), T.kr(idx), 60, ...
        markers{mod(i-1, length(markers))+1}, ...
        'filled', ...
        'DisplayName', sprintf('$v_0 = %d\\ \\mathrm{m/s}$', v0_vals(i)), ...
        'MarkerEdgeColor', 'k');
end

xlabel('Time (s)');
ylabel('$k_r$', 'Interpreter', 'latex');
title('Collision Risk Raster Plot');
grid on;

legend('Location','best', ...
       'Interpreter','latex', ...
       'Box','on', ...
       'FontSize',13);

hold off;
formatLatex(gca)
% saveFigure(gcf, figDir, 'coll_risk_timeplot')
%% --- Heatmap using imagesc: Collision Count + Percentage Labels ---

% Unique parameter values
kr_vals = unique(T.kr);
v0_vals = unique(T.v0);

% Prepare arrays to collect stats
kr_list = [];
v0_list = [];
collision_counts = [];
total_events = [];
collision_rates = [];

% Loop through all kr-v0 combinations
for i = 1:length(kr_vals)
    for j = 1:length(v0_vals)
        kr_val = kr_vals(i);
        v0_val = v0_vals(j);

        idx = T.kr == kr_val & T.v0 == v0_val;
        count = sum(idx);
        total = max(T.events_in_run(idx));

        if isempty(total) || isnan(total)
            total = 0;
            perc = 0;
        else
            perc = 100 * count / total;
        end

        % Store values
        kr_list(end+1) = kr_val;
        v0_list(end+1) = v0_val;
        collision_counts(end+1) = count;
        total_events(end+1) = total;
        collision_rates(end+1) = perc;
    end
end

% Create summary table
SummaryTable = table(kr_list.', v0_list.', collision_counts.', total_events.', ...
    collision_rates.', (collision_counts.' ./ total_events.') * 1e5, ...
    'VariableNames', {'kr', 'v0', 'Collisions', 'TotalEvents', ...
                      'PercentCollision', 'CollisionsPer100k'});

% Display it
disp(SummaryTable);
% save('collision_summary_table.mat', 'SummaryTable');
% export to latex
% table2latex(SummaryTable, 'collison_summary.tex')
%% --- Heatmap ---
% Create matrix for plotting
Z = reshape(SummaryTable.CollisionsPer100k, ...
            numel(kr_vals), numel(v0_vals));

% Plot using imagesc for full control
figure('Units', 'pixels', 'Position', [100, 100, 600, 500]);
imagesc(v0_vals, kr_vals, Z);  % axes: v0 on x, kr on y
set(gca, 'YDir', 'normal');    % Ensure kr increases upward
colormap(parula);               % Use colourful colormap
cb = colorbar;
cb.TickLabelInterpreter = 'latex';
cb.Label.String = "\# Events";
cb.Label.Interpreter = 'latex';
xlabel('Initial Velocity $v_0$ (m/s)');
ylabel('$k_r$');
title('Collision Rate per 100,000 Events');

% Add text annotations
for i = 1:length(kr_vals)
    for j = 1:length(v0_vals)
        val = Z(i,j);
        if ~isnan(val)
            % Choose white or black text depending on background brightness
            c = parula;  % the turbo colormap used
            color_index = round(interp1(linspace(min(Z(:)), max(Z(:)), size(c,1)), 1:size(c,1), val));
            if color_index < 1, color_index = 1; end
            if color_index > size(c,1), color_index = size(c,1); end
            bg = c(color_index,:);
            brightness = 0.299 * bg(1) + 0.587 * bg(2) + 0.114 * bg(3);
            textColor = 'black';
            if brightness < 0.5
                textColor = 'white';
            end

            text(v0_vals(j), kr_vals(i), sprintf('%.2f', val), ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'Color', textColor, 'FontSize', 14);
        end
    end
end
% Fix ticks to match actual kr and v0 values
set(gca, 'XTick', v0_vals, 'XTickLabel', string(v0_vals));
set(gca, 'YTick', kr_vals, 'YTickLabel', string(kr_vals));
formatLatex(gca)
grid off % to tirn off

% saveFigure(gcf, figDir, 'coll_risk_heatmap')
%% --- Bat–Bat raster: bat1 vs bat2, color-coded by Tb - TTC ---
figure('Units', 'pixels', 'Position', [100, 100, 600, 500]);

% Scatter plot
scatter(T.bat1, T.bat2, 60, T.delta, 'filled');
xlabel('$\mathrm{Bat~1}$', 'Interpreter', 'latex');
ylabel('$\mathrm{Bat~2}$', 'Interpreter', 'latex');
title('$T_b - \mathrm{TTC}$ Risk Margin per Bat Pair', 'Interpreter', 'latex');
% xlim([0 50])
axis equal
% ylim([0 50])
% Set color map and bar
colormap(jet);
cb = colorbar('Location', 'eastoutside');
cb.Box = 'off';
cb.Label.String = '$T_b - \mathrm{TTC}$~(ms)';
cb.Label.Interpreter = 'latex';

% Convert ticks to milliseconds
cb.Ticks = linspace(min(T.delta), max(T.delta), 6); % adjust if needed
cb.TickLabels = arrayfun(@(x) sprintf('%.0f', x*1000), cb.Ticks, 'UniformOutput', false);
cb.TickLabelInterpreter = 'latex';
% Appearance
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 12);
% axis square;
formatLatex(gca)
% saveFigure(gcf, figDir, 'interbat_raster')
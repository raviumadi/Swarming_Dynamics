%% Demo figure: swarm model with forward nearest neighbour (aligned with simulation)

rng(10); % for reproducibility

N = 10; % number of bats
initial_sigma = 0.5; % m

% Generate positions
positions = randn(N,3) * initial_sigma;
pos2D = positions(:,1:2);

% Assign heading per bat: +X with noise
headings = repmat([1 0], N, 1) + 0.1 * randn(N,2);
headings = headings ./ vecnorm(headings, 2, 2); % normalise

% Compute distances + forward NN
nearest_distance = zeros(N,1);
nearest_idx = zeros(N,1);

% Define max frontal angle in degrees
theta_max_deg = 75;
theta_max_rad = deg2rad(theta_max_deg);

for i = 1:N
    vec_to_others = pos2D - pos2D(i,:);
    distances = sqrt(sum(vec_to_others.^2, 2));
    
    % normalised vectors
    v_norm = vec_to_others ./ vecnorm(vec_to_others, 2, 2);
    h_i = headings(i,:);
    
    % angle between vectors
    dot_product = v_norm * h_i';
    angles = acos(dot_product); % in radians
    
    % select only within frontal cone
    frontal_mask = angles <= theta_max_rad;
    frontal_mask(i) = false;
    
    frontal_distances = distances;
    frontal_distances(~frontal_mask) = inf;
    
    [d_min, idx_min] = min(frontal_distances);
    
    if isinf(d_min)
        % No forward neighbour in cone — virtual obstacle
        d_min = 2 + rand() * 3;
        idx_min = 0;
    end
    
    nearest_distance(i) = d_min;
    nearest_idx(i) = idx_min;
end

% Colour map
cmap = parula(256);
dist_norm = (nearest_distance - min(nearest_distance)) / (max(nearest_distance) - min(nearest_distance));
dist_colors = cmap( round(1 + dist_norm * 255), : );

%% Plot
figure('Position', [300 300 600 600]); hold on;
axis equal
grid on
xlabel('X (m)'); ylabel('Y (m)');
title('Swarm model: Frontal nearest neighbour tracking');

% Plot bats
for i = 1:N
    plot(pos2D(i,1), pos2D(i,2), 'o', 'MarkerSize', 12, ...
        'MarkerFaceColor', dist_colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Optional: label bat number
    text(pos2D(i,1)+0.05, pos2D(i,2)+0.05, sprintf('%d',i), 'FontSize', 10);
    
    % Plot heading as arrow
    quiver(pos2D(i,1), pos2D(i,2), headings(i,1)*0.3, headings(i,2)*0.3, ...
        'Color', 'k', 'LineWidth', 1, 'MaxHeadSize', 0.5);
end

% Connect to forward nearest neighbour (arrow or dashed line)
for i = 1:N
    j = nearest_idx(i);
    
    if j > 0
        x_start = pos2D(i,1);
        y_start = pos2D(i,2);
        x_end = pos2D(j,1);
        y_end = pos2D(j,2);
        
        % Dotted line to NN
        plot([x_start, x_end], [y_start, y_end], ':', 'Color', dist_colors(i,:), 'LineWidth', 1.5);
    else
        % Optional: line to virtual obstacle
        x_start = pos2D(i,1);
        y_start = pos2D(i,2);
        obs_x = x_start + headings(i,1) * nearest_distance(i);
        obs_y = y_start + headings(i,2) * nearest_distance(i);
        
        plot([x_start, obs_x], [y_start, obs_y], '--', 'Color', dist_colors(i,:), 'LineWidth', 1);
        
        % mark obstacle
        plot(obs_x, obs_y, 'x', 'Color', dist_colors(i,:), 'MarkerSize', 8, 'LineWidth', 1.5);
    end
end

% Equations
text(-0.8,-0.2, '$T_a = \frac{2d}{c}$', 'Interpreter','latex','FontSize',14);
text(-0.8, -0.3, '$T_b = k_r T_a$', 'Interpreter','latex','FontSize',14);
text(-0.8, -0.4, '$\mathrm{IPI} = T_a + T_b$', 'Interpreter','latex','FontSize',14);

colormap(parula);
cb = colorbar;
cb.Label.String = 'Distance to nearest neighbour (m)';
cb.Label.FontSize = 12;
cb.TickLabelInterpreter = 'latex';
cb.Label.Interpreter = 'latex';

xlim([-1.1 1.1]);
ylim([-1.1 1.1]);
%
formatLatex(gca)
%% Save image
save_folder = '/Users/ravi/Documents/projects/swarm/manuscript/fig';
save_name = 'swarm_method_demo';

% Save .fig (MATLAB)
savefig(gcf, fullfile(save_folder, [save_name '.fig']));

% Save .pdf
 exportgraphics(gcf, fullfile(save_folder, [save_name '.pdf']), 'Resolution', 300)
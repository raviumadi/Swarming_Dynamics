%% Plot 3 - 2D projections of swarm trajectories (X-Y and X-Z)
figure('Position',[300 300 1200 300]); 
N = 50;
% Subplot 1: X-Y
subplot(1,2,1); hold on;
for i = 1:N
    pos = swarm_out.swarm(i).history.position;
    plot(pos(:,1), pos(:,2), '-', 'LineWidth', 1);
end
ylim([-40 40])
xlim([0 150])
xlabel('X (m)');
ylabel('Y (m)');
title('Swarm trajectories: X-Y plane');
formatLatex(gca)


% Subplot 2: X-Z
subplot(1,2,2); hold on;
for i = 1:N
    pos = swarm_out.swarm(i).history.position;
    plot(pos(:,1), pos(:,3), '-', 'LineWidth', 1);
end
ylim([-40 40])
xlim([0 150])
xlabel('X (m)');
ylabel('Z (m)');
title('Swarm trajectories: X-Z plane');
formatLatex(gca)


%% export trajectories
if saveData
    save_folder = '/Users/ravi/Documents/projects/swarm/manuscript/fig';
    save_name = 'swarm_trajectories';

    % Save as .fig (MATLAB figure)
    % savefig(gcf, fullfile(save_folder, [save_name '.fig'])); too large to
    % save.

    % Save as .pdf (vector, high quality)
    exportgraphics(gcf, fullfile(save_folder, [save_name '.pdf']), 'Resolution', 300)
end
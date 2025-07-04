function swarm_result = simulateEcholocationSwarm_async(params, N, max_time, sim_tag)
% simulateEcholocationSwarm_async - Asynchronous version with full outputs and collision risk tracking

c = 343; % Speed of sound

%% Parameters
initial_sigma = params.initial_sigma;
alignment_strength = 0.1;
damping_strength = 0.05;

if isfield(params, 'global_drive')
    global_drive = params.global_drive(:)' / norm(params.global_drive(:)');
else
    global_drive = [1 0 0];
end
global_drive_strength = 0.05;

velocity_adapt_strength = 0.02;
velocity_min = 0.8 * params.initial_velocity;
velocity_max = 1.2 * params.initial_velocity;
heading_alignment_strength = 0.1;

%% Initialise swarm
for i = 1:N
    swarm(i).position = randn(1,3) * initial_sigma;
    swarm(i).velocity = params.initial_velocity * (1 + 0.2*(rand-0.5));
    swarm(i).heading = global_drive + 0.1 * randn(1,3);
    swarm(i).heading = swarm(i).heading / norm(swarm(i).heading);
    
    swarm(i).next_event_time = 0;
    swarm(i).last_update_time = 0;
    
    swarm(i).history.time_stamps = [];
    swarm(i).history.position = [];
    swarm(i).history.Tb = [];
    swarm(i).history.TTC = [];
    swarm(i).history.call_rate = [];
    swarm(i).history.nearest_target_distance = [];
    swarm(i).history.nearest_neighbour_idx = [];
    swarm(i).history.call_duration = [];
    swarm(i).history.delta_s = [];
    swarm(i).history.delta_t = [];
    swarm(i).history.Ta = [];
    swarm(i).history.v = [];
    swarm(i).history.lambda = [];
    swarm(i).history.actual_synchrony_flag = [];
    swarm(i).history.wingbeat_phase = [];
end

%% Collision log (cooldown memory)
collision_log = zeros(N, N);

%% Collision risk tracking
collision_events = 0;
collision_times = [];

%% Main loop
t_global = 0;
event_count = 0;
last_printed_time = -1;

while t_global < max_time
    next_times = [swarm.next_event_time];
    [t_global, next_bat_idx] = min(next_times);
    
    % --- Update positions for ALL bats ---
    for i = 1:N
        dt_i = t_global - swarm(i).last_update_time;
        if dt_i > 0
            swarm(i).position = swarm(i).position + swarm(i).velocity * swarm(i).heading * dt_i;
            swarm(i).last_update_time = t_global;
            swarm(i).history.time_stamps(end+1) = t_global;
            swarm(i).history.position(end+1,:) = swarm(i).position;
        end
    end
    
    % --- Update calling bat ---
    i = next_bat_idx;
    pos = vertcat(swarm.position);
    vec_to_others = pos - swarm(i).position;
    distances = sqrt(sum(vec_to_others.^2, 2));
    dot_product = vec_to_others * swarm(i).heading';
    ahead_mask = dot_product > 0;
    ahead_mask(i) = false;
    forward_distances = distances;
    forward_distances(~ahead_mask) = inf;

    [minDist, minIdx] = min(forward_distances);
    if isinf(minDist)
        minDist = 2 + rand() * 3;
        minIdx = 0;
    end
    
    this_params = params;
    this_params.target_distance = minDist;
    this_params.initial_velocity = swarm(i).velocity;

    [bat_state, ~] = simulateEcholocationWings_singleStep(this_params);
    
    % Save call outputs
    swarm(i).history.Tb(end+1) = bat_state.Tb;
    swarm(i).history.call_rate(end+1) = 1 / bat_state.delta_t;
    swarm(i).history.nearest_target_distance(end+1) = minDist;
    swarm(i).history.nearest_neighbour_idx(end+1) = minIdx;
    Ta = (2 * minDist) / c;
    if Ta < params.kr * params.initial_call_duration
        call_duration_i = Ta / params.kr;
        call_duration_i = max(call_duration_i, 0.0005);
    else
        call_duration_i = params.initial_call_duration;
    end
    swarm(i).history.call_duration(end+1) = call_duration_i;

    swarm(i).history.delta_s(end+1) = bat_state.delta_s;
    swarm(i).history.delta_t(end+1) = bat_state.delta_t;
    swarm(i).history.Ta(end+1) = bat_state.Ta;
    % swarm(i).history.v(end+1) = bat_state.v;
    swarm(i).history.v(end+1) = swarm(i).velocity;
    swarm(i).history.lambda(end+1) = bat_state.lambda;
    swarm(i).history.actual_synchrony_flag(end+1) = bat_state.actual_synchrony_flag;
    swarm(i).history.wingbeat_phase(end+1) = bat_state.wingbeat_phase;

    % --- Heading/velocity update only for calling bat ---
    neighbours = setdiff(1:N, i);
    mean_neigh_heading = mean(vertcat(swarm(neighbours).heading), 1);
    centre_of_mass = mean(vertcat(swarm.position), 1);

    new_direction = (1 - alignment_strength) * swarm(i).heading + ...
        alignment_strength * mean_neigh_heading + ...
        damping_strength * (centre_of_mass - swarm(i).position) + ...
        global_drive_strength * global_drive;
    new_direction = new_direction / norm(new_direction);

    swarm(i).heading = (1 - heading_alignment_strength) * swarm(i).heading + ...
        heading_alignment_strength * new_direction;
    swarm(i).heading = swarm(i).heading / norm(swarm(i).heading);

    delta_v = velocity_adapt_strength * randn();
    swarm(i).velocity = swarm(i).velocity + delta_v;
    swarm(i).velocity = min(max(swarm(i).velocity, velocity_min), velocity_max);
    
    % --- Schedule next call ---
    swarm(i).next_event_time = t_global + bat_state.delta_t;

    % --- Collision check ---
    for m = 1:N
        for n = (m+1):N
            rel_pos = swarm(n).position - swarm(m).position;
            rel_vel = swarm(n).velocity * swarm(n).heading - swarm(m).velocity * swarm(m).heading;

            dist = norm(rel_pos);
            v_rel_along = - dot(rel_vel, rel_pos / dist);

            if v_rel_along > 0
                TTC = dist / v_rel_along;
            else
                TTC = inf;
            end

            if ~isempty(swarm(m).history.Tb)
                Tb_m = swarm(m).history.Tb(end);
            else
                Tb_m = params.initial_delta_t;
            end

            if ~isempty(swarm(n).history.Tb)
                Tb_n = swarm(n).history.Tb(end);
            else
                Tb_n = params.initial_delta_t;
            end

            Tb_pair = mean([Tb_m, Tb_n]);

            if TTC < Tb_pair && (t_global - collision_log(m,n)) > 0.1
                fprintf('%s | *** COLLISION RISK: bats %d-%d at t=%.3f Tb=%.6f TTC=%.6f < Tb\n', ...
                    sim_tag, m, n, t_global, Tb_pair, TTC);
                collision_log(m,n) = t_global;
                collision_log(n,m) = t_global;
                
                swarm(m).history.TTC(end+1) = TTC;
                swarm(n).history.TTC(end+1) = TTC;

                % --- Track collision event globally ---
                collision_events = collision_events + 1;
                collision_times = [collision_times, t_global];
            end
        end
    end
    
    event_count = event_count + 1;

    if floor(t_global) > last_printed_time
        last_printed_time = floor(t_global);
        disp(['Sim t = ', num2str(last_printed_time), ' s']);
    end
end

disp([sim_tag, ' | Simulation done: t_final = ', num2str(t_global,'%.2f'), ...
      ' s, total events: ', num2str(event_count)]);
disp([sim_tag, ' | Total collision events: ', num2str(collision_events)]);
swarm_result.swarm = swarm;
swarm_result.collision_events = collision_events;
swarm_result.collision_times = collision_times;

end
function [bat_state, t_step] = simulateEcholocationWings_singleStep(params)

c = 343;
Ta = 2 * params.target_distance / c;
Tb = params.kr * Ta;
ipi = Ta+Tb;

min_ipi = 1 / params.max_call_rate;
if ipi < min_ipi
    ipi = min_ipi;
end

delta_t = ipi;
delta_s = delta_t * params.initial_velocity + randn() / 10;
v = delta_s / delta_t;

f_w = 1 / delta_t;
theta = params.theta;
T_wing = 1 / f_w;
call_time = delta_t;
phi_frac = mod(call_time, T_wing) / T_wing;
phi_radians = 2 * pi * phi_frac;
wingbeat_phase = theta * sin(phi_radians);

Td = params.initial_call_duration;
Tp = 0.001;
phi_star = theta * f_w * (params.kr * Ta - Tp - Td);
synchrony_flag = phi_star <= theta;

bat_state = struct(...
    'delta_s', delta_s, ...
    'delta_t', delta_t, ...
    'Ta', Ta, ...
    'Tb', Tb, ...
    'v', v, ...
    'lambda', v / f_w, ...
    'actual_synchrony_flag', synchrony_flag, ...
    'wingbeat_phase', wingbeat_phase ...
    );

t_step = delta_t;

end
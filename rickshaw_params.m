%% rickshaw_params.m
% All the numbers that describe the electric auto-rickshaw.
% The Simulink/Simscape model reads these variables by name.

%% ---------------- Vehicle ----------------
m_vehicle    = 450;     % empty auto incl. motor and batteries (kg)
m_driver     = 70;      % driver (kg)
n_passengers = 0;       % number of passengers (0 to 3)
m_passenger  = 70;      % one passenger (kg)
m_total      = m_vehicle + m_driver + n_passengers*m_passenger;  % (kg)

A_front     = 2.0;      % frontal area (m^2)
Cd          = 0.6;      % drag coefficient (boxy shape)
Crr         = 0.015;    % rolling resistance coefficient
rho_air     = 1.2;      % air density (kg/m^3)
g           = 9.81;     % gravity (m/s^2)
road_grade  = 0;        % road slope in percent (0 = flat)
v_wind      = 0;        % wind speed (m/s), 0 = no wind
T_test      = 40;       % test torque used in step 2 (N*m)

%% ---------------- Wheel and gearbox ----------------
r_wheel     = 0.203;    % tyre radius, 4.00-8 auto tyre (m)
gear_ratio  = 7;        % motor turns 7 times per wheel turn
eta_gear    = 0.95;     % gearbox efficiency

%% ---------------- Motor ----------------
P_motor_peak = 6000;    % peak motor power (W)
T_motor_max  = 25;      % maximum motor torque (N*m)
w_motor_max  = 4500;    % maximum motor speed (rpm)
eta_motor    = 0.88;    % motor + controller efficiency
regen_on     = 1;       % 1 = regen braking ON, 0 = OFF

%% ---------------- Battery pack ----------------
n_packs      = 4;       % swappable packs in parallel
V_nom        = 51.2;    % pack voltage (V)
Ah_per_pack  = 30;      % capacity of one pack (Ah)
Q_batt       = n_packs * Ah_per_pack;   % total capacity (Ah)
E_batt_kWh   = V_nom * Q_batt / 1000;   % total energy (kWh)
SOC_init     = 1.0;     % start fully charged
R_batt       = 0.05 / n_packs;          % internal resistance (ohm)

%% ---------------- Drive cycle (city cycle modelled on India's IDC) ----------------
cycle_t  = [0 5 15 25 32 36 54 66 74 84 92 96 101 106 108];  % time (s)
cycle_v  = [0 0 25 25  0  0 42 42 20 20  0  0  15   0   0];  % target speed (km/h)
cycle_km = trapz(cycle_t, cycle_v)/3600;                     % distance per cycle (km)

%% ---------------- Driver (PI speed controller) ----------------
Kp_drv  = 10;    % torque per km/h of speed error
Ki_drv  = 2;     % removes the small steady error when cruising
SOC_min = 0.10;  % battery cut-off: the run stops at 10%

%% ---------------- Sanity checks ----------------
v_top = w_motor_max*2*pi/60 / gear_ratio * r_wheel * 3.6;
F_wheel_max = T_motor_max * gear_ratio * eta_gear / r_wheel;

fprintf('Total mass:        %.0f kg\n', m_total);
fprintf('Battery energy:    %.2f kWh (%d packs x %d Ah)\n', E_batt_kWh, n_packs, Ah_per_pack);
fprintf('Top speed (motor): %.1f km/h\n', v_top);
fprintf('Max wheel force:   %.0f N\n', F_wheel_max);
fprintf('City cycle:        %.3f km in %d s (avg %.1f km/h)\n', cycle_km, cycle_t(end), cycle_km/cycle_t(end)*3600);

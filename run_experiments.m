%% run_experiments.m
% Step 7: drive the e-auto around the city cycle until the battery reaches
% SOC_min (10%), for several scenarios, and compare the range.
%
% Run from the rickshaw folder by typing:  run_experiments
% Takes a few minutes (each run simulates several hours of driving).

clear; clc;
mdl = 'rickshaw';
load_system(mdl);
oldInit = get_param(mdl, 'InitFcn');
set_param(mdl, 'InitFcn', '');            % this script sets the parameters itself
set_param(mdl, 'StopTime', '40000');      % safety cap; the Stop block ends each run
if ~exist('results', 'dir'), mkdir('results'); end

%        scenario name     passengers  packs  regen_on
scen = { 'Baseline',            0,       4,     1
         'Regen OFF',           0,       4,     0
         '1 passenger',         1,       4,     1
         '2 passengers',        2,       4,     1
         '3 passengers',        3,       4,     1
         '3 packs',             0,       3,     1
         '2 packs',             0,       2,     1 };
n = size(scen, 1);
range_km = zeros(n, 1);  hours = zeros(n, 1);  Wh_km = zeros(n, 1);  avg_kmh = zeros(n, 1);
dist = cell(n, 1);  soc = cell(n, 1);

try
    for k = 1:n
        evalc('rickshaw_params');                      % fresh default values (silently)
        n_passengers = scen{k, 2};
        n_packs      = scen{k, 3};
        regen_on     = scen{k, 4};
        % recompute the values that depend on the inputs we just changed
        m_total    = m_vehicle + m_driver + n_passengers*m_passenger;
        Q_batt     = n_packs * Ah_per_pack;
        E_batt_kWh = V_nom * Q_batt / 1000;
        R_batt     = 0.05 / n_packs;

        fprintf('Run %d/%d  %-13s ... ', k, n, scen{k, 1});
        tic;
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        dist{k} = out.dist_km.Data(:);
        soc{k}  = out.soc_pct.Data(:);
        range_km(k) = dist{k}(end);
        hours(k)    = out.dist_km.Time(end) / 3600;
        Wh_km(k)    = (SOC_init - SOC_min) * E_batt_kWh * 1000 / range_km(k);
        avg_kmh(k)  = range_km(k) / hours(k);
        fprintf('%6.1f km  in %4.1f h of driving   (computed in %.0f s)\n', ...
                range_km(k), hours(k), toc);
        % sanity check: the driver must follow the city cycle (avg ~18 km/h)
        cyc_avg = cycle_km / cycle_t(end) * 3600;
        if abs(avg_kmh(k) - cyc_avg) > 1.5
            warning('Run "%s": average speed %.1f km/h but the cycle averages %.1f km/h. The driver did not follow the route, so this result is NOT valid.', ...
                    scen{k, 1}, avg_kmh(k), cyc_avg);
        end
    end
catch err
    set_param(mdl, 'InitFcn', oldInit);
    rethrow(err);
end
set_param(mdl, 'InitFcn', oldInit);
rickshaw_params;                                       % restore default values

%% ---------------- Results table ----------------
T = table(string(scen(:, 1)), round(range_km, 1), round(hours, 2), round(avg_kmh, 1), round(Wh_km, 1), ...
          'VariableNames', {'Scenario', 'Range_km', 'Driving_hours', 'Avg_speed_kmh', 'Wh_per_km'});
fprintf('\n');
disp(T);
writetable(T, fullfile('results', 'experiment_results.csv'));

b = range_km(1);
fprintf('\nBaseline range:   %.1f km  (%.0f Wh/km)\n', b, Wh_km(1));
fprintf('Regen adds:       %+.0f%% range compared with regen OFF\n', (b/range_km(2) - 1)*100);
fprintf('3 passengers:     %+.0f%% range compared with driver only\n', (range_km(5)/b - 1)*100);
fprintf('Each pack gives:  about %.0f km\n', b/4);

%% ---------------- Plot 1: range by scenario ----------------
f1 = figure('Color', 'w', 'Position', [100 100 760 420]);
barh(1:n, range_km, 0.6, 'FaceColor', [0.16 0.62 0.56]);
set(gca, 'YTick', 1:n, 'YTickLabel', scen(:, 1), 'YDir', 'reverse', 'FontSize', 11);
xlabel('Range on the city cycle (km)');
title('E-auto range by scenario (battery 100% \rightarrow 10%)');
for k = 1:n
    text(range_km(k) + 1, k, sprintf('%.0f km', range_km(k)), 'VerticalAlignment', 'middle');
end
grid on;  xlim([0 max(range_km)*1.15]);
exportgraphics(f1, fullfile('results', 'range_comparison.png'), 'Resolution', 150);

%% ---------------- Plot 2: SOC vs distance ----------------
f2 = figure('Color', 'w', 'Position', [100 100 760 420]);
hold on;
for k = [1 2 5 7]
    plot(dist{k}, soc{k}, 'LineWidth', 1.6, 'DisplayName', scen{k, 1});
end
yline(SOC_min*100, '--', 'cut-off', 'HandleVisibility', 'off');
xlabel('Distance (km)');  ylabel('Battery SOC (%)');
title('Battery state of charge vs distance');
legend('Location', 'northeast');  grid on;
exportgraphics(f2, fullfile('results', 'soc_vs_distance.png'), 'Resolution', 150);

%% ---------------- Plot 3: passengers and packs ----------------
f3 = figure('Color', 'w', 'Position', [100 100 900 380]);
subplot(1, 2, 1);
plot(0:3, range_km([1 3 4 5]), '-o', 'LineWidth', 1.8);  grid on;
xlabel('Passengers');  ylabel('Range (km)');  title('Effect of passengers');
subplot(1, 2, 2);
plot([2 3 4], range_km([7 6 1]), '-o', 'LineWidth', 1.8);  grid on;
xlabel('Battery packs');  ylabel('Range (km)');  title('Effect of battery packs');
exportgraphics(f3, fullfile('results', 'passengers_and_packs.png'), 'Resolution', 150);

fprintf('\nPlots and results table saved in the results folder.\n');

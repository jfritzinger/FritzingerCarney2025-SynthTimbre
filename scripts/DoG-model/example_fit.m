%% Example: Fitting Gaussian vs. Difference-of-Gaussians (DoG) Models
% This script demonstrates how to load neural data, extract spontaneous and
% driven firing rates from Synthetic Timbre (ST) stimuli, fit receptive field
% models (Gaussian vs. DoG), and visualize the resulting fits and tuning kernels.

%% =========================================================================
% 1. CONFIGURATION & CONSTANTS
% =========================================================================
LINEWIDTH = 1.5;
FS_STIM   = 100000;  % Stimulus sampling frequency (Hz)
N_REPS    = 5;       % Number of multi-starts for fmincon optimizations

% Example Unit Selection (Uncomment the unit you want to analyze)
putative_unit = 'R29_TT4_P5_N02'; 
% putative_unit = 'R24_TT2_P13_N02';
% putative_unit = 'R25_TT3_P9_N01';
% putative_unit = 'R27_TT3_P8_N01';

%% =========================================================================
% 2. LOAD DIRECTORIES & METADATA
% =========================================================================
[~, datapath, ~, ~] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';

% Load master spreadsheet containing unit details (e.g., CF)
sessions = readtable(fullfile(datapath, spreadsheet_name), ...
                     'PreserveVariableNames', true);

% Find rows matching the target unit and extract its Characteristic Frequency (CF)
unit_idx = find(cellfun(@(s) strcmp(putative_unit, s), sessions.Putative_Units));
if isempty(unit_idx)
    error('Unit %s not found in the master spreadsheet.', putative_unit);
end
CF = sessions.CF(unit_idx);

% Load the specific neural data file
mat_filename = sprintf('%s.mat', putative_unit);
load(fullfile(datapath, 'neural_data', mat_filename), 'data');

%% =========================================================================
% 3. EXTRACT PHYSIOLOGICAL RESPONSES (Spont & Driven Rates)
% =========================================================================
% Extract spontaneous activity from Rate-Intensity Function / Response Map (RM)
params_RM = data{2, 2};
data_RM   = analyzeRM(params_RM);
spont_rate = data_RM.spont;

% Extract Synthetic Timbre (ST) driven firing rates
params_ST = data(7, 2);
params_ST = params_ST(~cellfun(@isempty, params_ST)); % Filter out empty cells
data_ST   = analyzeST(params_ST, CF);
data_ST   = data_ST{1};

% Assign extracted target vectors
observed_rate = data_ST.rate;
rate_std      = data_ST.rate_std;
fpeaks        = data_ST.fpeaks;

%% =========================================================================
% 4. RECREATE STIMULUS (Single Representation for Modeling)
% =========================================================================
params_ST{1}.Fs       = FS_STIM;
params_ST{1}.physio   = 1;
params_ST{1}.mnrep    = 1;
params_ST{1}.dur      = 0.3;
params_ST{1}          = generate_ST(params_ST{1});
params_ST{1}.num_stim = size(params_ST{1}.stim, 1);

stim_matrix = params_ST{1}.stim;
num_stim    = size(stim_matrix, 1);

%% =========================================================================
% 5. OPTIMIZATION / MODEL FITTING via fmincon
% =========================================================================
fprintf('Running fmincon optimizations for %s...\n', putative_unit);

% Fit standard 5-parameter Difference-of-Gaussians model
num_dog_params = 5;
dog_params = fit_dog_model(N_REPS, CF, FS_STIM, stim_matrix, observed_rate, spont_rate, num_dog_params);

% Fit Gaussian model
gauss_params = fit_gaussian_model(N_REPS, CF, FS_STIM, stim_matrix, observed_rate, spont_rate);

% Optional: Fit 6-parameter DoG model
% dog_params6 = fit_dog_model_6param(N_REPS, CF, FS_STIM, stim_matrix, observed_rate, spont_rate);

%% =========================================================================
% 6. MODEL PREDICTIONS & STATS EVALUATION
% =========================================================================
f_axis = linspace(0, FS_STIM/2, 100000); % Frequency array for kernel generation

% Predict Firing Rates: Gaussian Model
gauss_predicted = zeros(num_stim, 1);
fc = 10^gauss_params(1);
sigma = 10^gauss_params(2);
g = gauss_params(3);
W_gauss = gaussian_model(f_axis, fc, sigma, g); % Generate filter kernel
for i = 1:num_stim
    gauss_predicted(i) = compute_firing_rate(stim_matrix(i, :), FS_STIM, W_gauss, f_axis, spont_rate);
end
gauss_r2 = calculate_adj_r_squared(observed_rate, gauss_predicted, 3);
gauss_legend_str = sprintf('Gaussian, Adj. R^2 = %0.02f', gauss_r2);

% Predict Firing Rates: DoG Model (5-param)
dog_predicted = zeros(num_stim, 1);
W_dog = dog_model(f_axis, dog_params); % Generate filter kernel
for i = 1:num_stim
    dog_predicted(i) = compute_firing_rate(stim_matrix(i, :), FS_STIM, W_dog, f_axis, spont_rate);
end
dog_r2 = calculate_adj_r_squared(observed_rate, dog_predicted, 5);
dog_legend_str = sprintf('DoG, Adj. R^2 = %0.02f', dog_r2);

%% =========================================================================
% 7. VISUALIZATION
% =========================================================================
figure('Position', [76, 482, 1062, 435])
tiledlayout(1, 2, 'TileSpacing', 'compact')

% --- Tile 1: Firing Rate Profiles vs Model Predictions ---
nexttile
hold on;

% Plot raw physiological data with Standard Error
errorbar(fpeaks./1000, observed_rate, rate_std/sqrt(params_ST{1}.nrep), ...
         'LineWidth', LINEWIDTH, 'Color', 'k', 'DisplayName', 'Observed Data');

% Plot reference lines for CF and Spontaneous rate
xline(CF/1000, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', LINEWIDTH, 'DisplayName', 'Unit CF');
yline(spont_rate, 'Color', [0.5 0.5 0.5], 'LineWidth', LINEWIDTH, 'DisplayName', 'Spont Rate');

% Plot Model Curves
plot(fpeaks./1000, gauss_predicted, 'r', 'LineWidth', 3, 'DisplayName', gauss_legend_str);
plot(fpeaks./1000, dog_predicted, 'g', 'LineWidth', LINEWIDTH, 'DisplayName', dog_legend_str);

% Format Panel
grid on;
set(gca, 'FontSize', 12)
title('Model Fits vs. Neural Responses')
ylabel('Avg. Firing Rate (spikes/s)')
xlabel('Spectral Peak Frequency (kHz)')
legend('Location', 'best')

% --- Tile 2: Receptive Field Filtering Kernels ---
nexttile
hold on;

% Plot Kernels
plot(f_axis/1000, W_gauss, 'Color', 'r', 'LineWidth', 3, 'DisplayName', 'Gaussian Kernel');
plot(f_axis/1000, W_dog, 'Color', 'g', 'LineWidth', LINEWIDTH, 'DisplayName', 'DoG Kernel');

% Format Panel
xline(CF/1000, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', LINEWIDTH, 'DisplayName', 'Unit CF');
grid on;
set(gca, 'FontSize', 12, 'XScale', 'log')
title('Estimated Frequency Tuning Kernels')
ylabel('Filter Amplitude (a.u.)')
xlabel('Frequency (kHz)')
xlim([200, 10000] / 1000)
xticks([0.1, 0.2, 0.5, 1, 2, 5, 10])
legend('Location', 'best')
%% fit_gaussian_vs_dog
clear

%% Load in spreadsheet 

[base, ~, ~, ~] = getPaths();
sheetpath = 'data/2025-manuscript/data-cleaning';
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(base, sheetpath, spreadsheet_name), 'PreserveVariableNames',true);


%% Load in data and plot
linewidth = 1.5;

% Load in data
% Example: R24_TT2_P13_N02, CF = 1150Hz, BS
putative = 'R29_TT4_P5_N02'; 
%putative = 'R24_TT2_P13_N02';
%putative = 'R25_TT3_P9_N01';
%putative = 'R27_TT3_P8_N01';

[base, datapath, savepath, ppi] = getPaths();
filename = sprintf('%s.mat', putative);
load(fullfile(datapath,'neural_data', filename)), 'data';
index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
CF = sessions.CF(index);

% RM to get spont
params_RM = data{2, 2};
data_RM = analyzeRM(params_RM);
spont = data_RM.spont;

% Synthetic timbre analysis
params = data(7, 2);
params = params(~cellfun(@isempty, params));
data_ST  = analyzeST(params, CF);
data_ST = data_ST{1};
rate = data_ST.rate;
rate_std = data_ST.rate_std;
fpeaks = data_ST.fpeaks;
rate_sm = data_ST.rates_sm;


%% Recreate stimulus (1 rep) 

% Generate stimulus 
params{1}.Fs = 100000;
params{1}.physio = 1;
params{1}.mnrep = 1;
params{1}.dur = 0.3;
params{1} = generate_ST(params{1});
params{1}.num_stim = size(params{1}.stim, 1);


%% fmincon

Fs = 100000;
observed_rate = rate;
r0 = spont;
stim = params{1}.stim;

nrep = 5;
num_params = 5;
dog_params = fit_dog_model(nrep, CF, Fs, stim, observed_rate, r0, num_params);

% nrep = 5;
% num_params = 6;
% dog_params6 = fit_dog_model_6param(nrep, CF, Fs, stim, observed_rate, r0);

nrep = 5;
gauss_params = fit_gaussian_model(nrep, CF, Fs, stim, observed_rate, r0);


%% Plot results 

% Plot data 
figure('Position',[76,482,1062,435])
tiledlayout(1, 2)
nexttile
hold on
errorbar(fpeaks./1000, rate, rate_std/sqrt(params{1}.nrep), ...
	 'linewidth', linewidth, 'color', 'k')
xline(CF/1000, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
yline(spont, 'color', [0.5 0.5 0.5], LineWidth=linewidth)

% Plot gaussian
f = linspace(0, Fs/2, 100000);
nstim = size(stim, 1);
gaus_predicted = zeros(nstim, 1);
for i = 1:nstim
	W = gaussian_model(f, gauss_params);
	gaus_predicted(i) = compute_firing_rate(stim(i, :), Fs, W, f, r0);
end
plot(fpeaks./1000, gaus_predicted, 'r', 'linewidth', 3)
gaussian_adj_r_squared = calculate_adj_r_squared(observed_rate,...
	gaus_predicted, 3);
gaus_msg = sprintf('Gaussian, R^2=%0.02f', gaussian_adj_r_squared);

% Plot DoG
f = linspace(0, Fs/2, 100000);
nstim = size(stim, 1);
dog_predicted = zeros(nstim, 1);
W = dog_model(f, dog_params);
for i = 1:nstim
	dog_predicted(i) = compute_firing_rate(stim(i, :), Fs, W, f, r0);
end
plot(fpeaks./1000, dog_predicted, 'g', 'linewidth', linewidth)
dog_adj_r_squared = calculate_adj_r_squared(observed_rate,...
	dog_predicted, 5);
dog_msg = sprintf('DoG, R^2=%0.02f', dog_adj_r_squared);

% % Plot DoG
% f = linspace(0, Fs/2, 100000);
% nstim = size(stim, 1);
% dog_predicted6 = zeros(nstim, 1);
% W = dog_model(f, dog_params6);
% for i = 1:nstim
% 	dog_predicted6(i) = compute_firing_rate(stim(i, :), Fs, W, f, r0);
% end
% plot(fpeaks./1000, dog_predicted6, 'b', 'linewidth', linewidth)
% dog_adj_r_squared = calculate_adj_r_squared(observed_rate,...
% 	dog_predicted6, 5);
% dog_msg2 = sprintf('DoG 6 param, R^2=%0.02f', dog_adj_r_squared);


% Figure params
set(gca, 'FontSize',12)
legend('', '', '', gaus_msg, dog_msg, 'Location','best')
title('Gaussian vs DoG Fits')
ylabel('Avg. Rate (sp/s)')
xlabel('Spectral Peak Freq. (kHz)')

% Plot kernels 

% Plot DoG Parameters
nexttile
hold on

Fs = 100000;
f = linspace(0, Fs/2, 100000);
W = gaussian_model(f, gauss_params);
plot(f/1000,W, 'color', 'r', 'LineWidth',3)

W2 = dog_model(f, dog_params);
plot(f/1000,W2, 'color', 'g')

% W3 = dog_model(f, dog_params6);
% plot(f/1000,W3, 'color', 'b')

% Plot labels
xline(CF/1000, '--', 'linewidth', 1.5)
title('DoG and Gaussian Kernels')
set(gca, 'fontsize', 12)
ylabel('Amplitude')
xlabel('Frequency (kHz)')
xlim([200 10000]/1000)
set(gca, 'xscale', 'log')
grid on
xticks([0.1 0.2 0.5 1 2 5 10])

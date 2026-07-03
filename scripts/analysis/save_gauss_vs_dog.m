%% save_dog_v_gaussian_fits.m
%
% Script to compute and compare Gaussian vs. Difference of Gaussians (DoG) 
% receptive field model fits across sessions.
%
% -------------------------------------------------------------------------
clear

%% 1. Load and Initialize
output_filename = 'dog_analysis.mat';

% Load in spreadsheet
[base, datapath, savepath, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames', true);

% Filter and sort active sessions by CF (column ST_63dB)
has_data = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
index = find(has_data);

CF_list = sessions.CF(has_data);
[~, order] = sort(CF_list);
num_sessions = length(CF_list);

% Preallocate overall performance metrics
R2_dog_all = NaN(1, num_sessions);
R2_gauss_all = NaN(1, num_sessions);
dog_analysis = struct(); % Initialize output tracking structure

%% 2. Processing Loop Across Neurons
for isesh = 1:num_sessions
    timerVal = tic;
    ineuron = index(order(isesh)); 
    
    % Load in data
    putative = sessions.Putative_Units{ineuron};
    CF = sessions.CF(ineuron);
    load(fullfile(datapath, 'neural_data', [putative '.mat']))
    
    % Get spontaneous rate baseline (RM)
    params_RM = data{2, 2};
    data_RM = analyzeRM(params_RM);
    spont = data_RM.spont;
    
    % Synthetic timbre analysis extraction
    params = data(7, 2);
    params = params(~cellfun(@isempty, params));
    data_ST = analyzeST(params, CF);
    data_ST = data_ST{1};
    observed_rate = data_ST.rate;
    
    % Standardize configuration and generate active stimulus parameters
    params{1}.Fs = 100000;
    params{1}.physio = 1;
    params{1}.mnrep = 1;
    params{1}.dur = 0.3;
    params{1} = generate_ST(params{1});
    params{1}.num_stim = size(params{1}.stim, 1);
    
    Fs = 100000;
    r0 = spont;
    stim = params{1}.stim;
    nstim = size(stim, 1);
    f = linspace(0, Fs/2, 100000); % Shared frequency grid 
    
    % Execute optimization pipelines
    [gaussian_params, dog_params] = fitGaussAndDoG(params, CF, Fs, observed_rate, r0);
    
    % Predict Firing Rates: Gaussian Model
    gaus_predicted = zeros(nstim, 1);
    fc = 10^gaussian_params(1);
    sigma = 10^gaussian_params(2);
    g = gaussian_params(3);
    W_gauss = gaussian_model(f, fc, sigma, g);
    for i = 1:nstim
        gaus_predicted(i) = compute_firing_rate(stim(i, :), Fs, W_gauss, f, r0);
    end
    
    % Predict Firing Rates: Difference of Gaussians (DoG) Model
    dog_predicted = zeros(nstim, 1);
    W_dog = dog_model(f, dog_params);
    for i = 1:nstim
        dog_predicted(i) = compute_firing_rate(stim(i, :), Fs, W_dog, f, r0);
    end
    
    % Calculate Adjusted R^2 values
    gaussian_adj_r_squared = calculate_adj_r_squared(observed_rate, gaus_predicted, 3);
    dog_adj_r_squared = calculate_adj_r_squared(observed_rate, dog_predicted, 6);
    
    R2_dog_all(isesh) = dog_adj_r_squared;
    R2_gauss_all(isesh) = gaussian_adj_r_squared;
    
    % Compare models using F-Test
    p_value = ftest(observed_rate, gaus_predicted, dog_predicted);
    
    % % Struct to save out all data and fits individually
    % dog_gauss_analysis.putative = putative;
    % dog_gauss_analysis.dog_predicted = dog_predicted;
    % dog_gauss_analysis.gaus_predicted = gaus_predicted;
    % dog_gauss_analysis.CF = CF;
    % dog_gauss_analysis.rate = observed_rate;
    % dog_gauss_analysis.R2_dog = dog_adj_r_squared;
    % dog_gauss_analysis.R2_gauss = gaussian_adj_r_squared;
    % dog_gauss_analysis.fpeaks = data_ST.fpeaks;
    % dog_gauss_analysis.spont = spont;
    % dog_gauss_analysis.rate_std = data_ST.rate_std;
    % dog_gauss_analysis.p_value = p_value;
    % dog_gauss_analysis.dog_params = dog_params;
    % dog_gauss_analysis.gauss_params = gaussian_params;
    % filename = [putative '.mat'];
    % save(fullfile(savepath, 'dog_model', filename), 'dog_gauss_analysis')
    
    % Package and archive combined results trace
    dog_analysis(isesh).putative = putative;
    dog_analysis(isesh).dog_predicted = dog_predicted;
    dog_analysis(isesh).gaus_predicted = gaus_predicted;
    dog_analysis(isesh).CF = CF;
    dog_analysis(isesh).rate = observed_rate;
    dog_analysis(isesh).R2_dog = dog_adj_r_squared;
    dog_analysis(isesh).R2_gauss = gaussian_adj_r_squared;
    dog_analysis(isesh).fpeaks = data_ST.fpeaks;
    dog_analysis(isesh).spont = spont;
    dog_analysis(isesh).rate_std = data_ST.rate_std;
    dog_analysis(isesh).p_value = p_value;
    dog_analysis(isesh).dog_params = dog_params;
    dog_analysis(isesh).gauss_params = gaussian_params;
    
    fprintf('%s done, %d percent done\n', putative, round(isesh/num_sessions*100))
    disp([putative ' took ' num2str(toc(timerVal)) ' seconds'])
end

%% 3. Save Master Analytics Matrix
save(fullfile(datapath, output_filename), "dog_analysis", "R2_gauss_all", "R2_dog_all")
%% save_model_predictions_ST.m
%
% Script that runs either SFIE single-cell, energy, lateral inhibition, or 
% SFIE population models for neurons with responses to synthetic timbre.
%
% Author: J. Fritzinger
% Created: 2022-09-11; Last revision: 2026-07-03
%
% -------------------------------------------------------------------------

%% =========================================================================
% 1. EXECUTION CONFIGURATION (Toggle Modes Here)
% =========================================================================
% Execution Mode: Set to true to loop through all units, or false for a single unit
run_all_units = false; 
putative_target = 'R27_TT2_P8_N04'; % Target unit if run_all_units = false

% Model Selection: Choose from: 'SFIE', 'Lat_Inh', 'Energy', or 'SFIE_pop'
model_type = 'SFIE'; 

%% =========================================================================
% 2. LOAD DIRECTORIES & METADATA
% =========================================================================
[base, datapath, savepath, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames', true);

% Identify indices containing a synthetic timbre response at any SPL level
bin200 = false(size(sessions, 1), 4);
bin200(:,1) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB);
bin200(:,2) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
bin200(:,3) = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB);
bin200(:,4) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB);

has_data = bin200(:,1) | bin200(:,2) | bin200(:,3) | bin200(:,4);
all_valid_indices = find(has_data);

% Determine the loop iterations based on Mode Selection
if run_all_units
    loop_indices = all_valid_indices;
    fprintf('Running model "%s" across ALL (%d) units...\n', model_type, length(loop_indices));
else
    target_idx = find(strcmp(sessions.Putative_Units, putative_target));
    if isempty(target_idx)
        error('Target unit %s not found in spreadsheet.', putative_target);
    end
    loop_indices = target_idx;
    fprintf('Running model "%s" on SINGLE unit: %s\n', model_type, putative_target);
end

%% =========================================================================
% 3. RUN MODEL PIPELINE
% =========================================================================
skipped_indices = {};
jj = 1;

for loop_i = 1:length(loop_indices)
    current_idx = loop_indices(loop_i);
    putative = sessions.Putative_Units{current_idx};
    CF = sessions.CF(current_idx);
    MTF_shape = sessions.MTF{current_idx};
    
    try
        timerVal2 = tic;
        
        % Load physiological data vector
        load(fullfile(datapath, 'neural_data', [putative '.mat']), 'data');
        params_ST = data(6:9, 2);
        
        % Assign Best Modulation Frequency (BMF) based on MTF shape tuning
        if strcmp(MTF_shape, 'BS')
            BMF = sessions.WMF(current_idx);
        elseif strcmp(MTF_shape, 'BE')
            BMF = sessions.BMF(current_idx);
        else
            BMF = 100;
        end
        
        % Pre-allocate storage spaces specific to chosen model architectures
        if strcmp(model_type, 'SFIE') || strcmp(model_type, 'SFIE_pop')
            AN = cell(4, 1);
            SFIE = cell(4, 1);
            SFIE_pop = cell(4, 1);
            AN_pop = cell(4, 1);
        elseif strcmp(model_type, 'Energy')
            Fs = 100000;
            gamma_param.srate = Fs;
            gamma_param.fc = CF;
            energy = cell(4, 1);
        elseif strcmp(model_type, 'Lat_Inh')
            AN_lat_inh = cell(4, 1);
            lat_inh = cell(4, 1);
        end
        
        % Loop through the 4 available Sound Pressure Levels (SPLs)
        for ispl = 1:4
            if isempty(params_ST{ispl})
                continue; % Skip if synthetic timbre wasn't recorded at this specific SPL
            end
            
            % Process physiological tuning profile baseline metrics
            data_ST = analyzeST(params_ST(ispl), CF);
            data_ST = data_ST{1};
            
            params_RM = data{2, 2};
            data_RM = analyzeRM(params_RM);
            spont = data_RM.spont;
            
            params_MTF = data{3, 2};
            data_MTF = analyzeMTF(params_MTF);
            
            % Synthesize Acoustic Waveforms/Stimuli configurations
            params_ST{ispl}.Fs = 100000;
            params_ST{ispl}.physio = 1;
            params_ST{ispl}.mnrep = 5;
            params_ST{ispl}.dur = 0.3;
            if strcmp(model_type, 'SFIE_pop')
                CFs = params_ST{ispl}.fpeaks;
                params_ST{ispl}.stp_otc = 1;
            end
            params_ST{ispl} = generate_ST(params_ST{ispl});
            params_ST{ispl}.num_stim = size(params_ST{ispl}.stim, 1);
            
            %% --- SUB-MODEL ARCHITECTURE ROUTER ---
            if strcmp(model_type, 'SFIE')
                % Model parameters
                model_params.type = 'SFIE';
                model_params.range = 2; % 1 = population model, 2 = single cell model
                model_params.species = 1; % 1 = cat, 2 = human
                model_params.BMF = BMF;
                model_params.CF_range = CF;
                model_params.num_CFs = 1;
                model_params.CFs = CF;
                model_params.nAN_fibers_per_CF = 10;
                model_params.cohc = 1; model_params.cihc = 1;
                model_params.nrep = 1; model_params.implnt = 1; model_params.noiseType = 1;
                model_params.which_IC = 1; model_params.onsetWin = 0.020; model_params.fiberType = 3;
                
                % Process AN + Single-Cell IC responses
                AN_temp = modelAN(params_ST{ispl}, model_params);
                SFIE_temp = wrapperIC(AN_temp.an_sout, params_ST{ispl}, model_params);
                
                % Reference Spontaneous Simulation
                params_RM.type = 'RM'; params_RM.dur = 0.2; params_RM.ramp_dur = 0.01; params_RM.reptim = 0.6;
                params_RM.nrep = 3; params_RM.freqs = [3000,3001, 1]; params_RM.spls = []; params_RM.binmode = 2;
                params_RM.onsetWin = 25; params_RM.mnrep = 1; params_RM.Fs = 100000;
                params_RM = generate_RM(params_RM); params_RM.num_stim = size(params_RM.stim, 1);
                AN_spont = modelAN(params_RM, model_params);
                SFIE_spont = wrapperIC(AN_spont.an_sout, params_RM, model_params);
                
                % MTF Reference Simulation
                params_MTF.type = 'MTF'; params_MTF.Fs = 100000; params_MTF.ramp_dur = 0.05; params_MTF.noise_state = 0;
                params_MTF.noise_band = [100, 10000]; params_MTF.dur = 1; params_MTF.reptim = 1.5;
                params_MTF.fms = [2, 600, 3]; params_MTF.mdepths = [0,0,1]; params_MTF.binmode = 2;
                params_MTF.No = 30; params_MTF.spl = 30; params_MTF.raised_sine = 1; params_MTF.onsetWin = 25;
                params_MTF.mnrep = 3; params_MTF = generate_MTF(params_MTF); params_MTF.num_stim = size(params_MTF.stim, 1);
                AN_MTF = modelAN(params_MTF, model_params);
                SFIE_MTF = wrapperIC(AN_MTF.an_sout, params_MTF, model_params);
                
                if strcmp(MTF_shape, 'BS') || strcmp(MTF_shape, 'BE')
                    suffix = ['_' MTF_shape];
                    [rate, rate_std] = plotST(params_ST{ispl}, SFIE_temp.(['average_ic_sout' suffix]), 0);
                    rate = rate ./ (max(rate)/max(data_ST.rate));
                    
                    SFIE{ispl}.rate = rate;
                    SFIE{ispl}.rate_std = rate_std;
                    SFIE{ispl}.fpeaks = params_ST{ispl}.fpeaks;
                    R = corrcoef(data_ST.rate, rate);
                    SFIE{ispl}.R = R(1, 2);
                    SFIE{ispl}.R2 = R(1, 2)^2;
                    SFIE{ispl}.PSTH = plotST_PSTH(params_ST{ispl}, SFIE_temp.(['ic' suffix]), 0);
                    SFIE{ispl}.spont = SFIE_spont.(['average_ic_sout' suffix]);
                    SFIE{ispl}.rmse = calculateRMSE(rate, data_ST.rate);
                    
                    [~, avBE, stdBE, MTF_shape_calc, rate_sm] = plotMTF(params_MTF, SFIE_MTF.(['average_ic_sout' suffix]), 0);
                    SFIE{ispl}.MTF_rate = avBE;
                    SFIE{ispl}.MTF_rate_std = stdBE;
                    SFIE{ispl}.MTF_shape_calc = MTF_shape_calc;
                    SFIE{ispl}.MTF_rate_sm = rate_sm;
                    R_MTF = corrcoef(data_MTF.rate, avBE);
                    SFIE{ispl}.R_MTF = R_MTF(1, 2);
                else
                    SFIE{ispl}.rate = []; SFIE{ispl}.rmse = [];
                end
                SFIE{ispl}.MTF_shape = MTF_shape;
                SFIE{ispl}.BMF = BMF;
                
                [rate, rate_std] = plotST(params_ST{ispl}, AN_temp.average_AN_sout, 0);
                AN{ispl}.rate = rate; AN{ispl}.rate_std = rate_std; AN{ispl}.fpeaks = params_ST{ispl}.fpeaks;
                R = corrcoef(data_ST.rate, rate); AN{ispl}.R = R(1, 2); AN{ispl}.R2 = R(1, 2)^2;
                AN{ispl}.PSTH = plotST_PSTH(params_ST{ispl}, AN_temp.an_sout, 0);
                
            elseif strcmp(model_type, 'Energy')
                stimulus = [params_ST{ispl}.stim zeros(size(params_ST{ispl}.stim, 1), 0.1*Fs)];
                impaired = 0;
                pin_gamma = zeros(size(stimulus, 1), Fs*params_ST{ispl}.dur + 0.1*Fs);
                for istim = 1:size(stimulus, 1)
                    pin_gamma(istim,:) = gamma_filt(stimulus(istim,:), gamma_param, impaired, 1);
                end
                pin_gamma = pin_gamma(:, 1:params_ST{ispl}.dur*Fs);
                energ_out = sqrt(mean(pin_gamma.^2, 2));
                [rate, rate_std] = plotST(params_ST{ispl}, energ_out, 0);
                R_int = corrcoef(data_ST.rate, rate);
                
                max_rate = max(data_ST.rate) - spont;
                rate = rate ./ (max(rate)/max_rate) + spont;
                
                energy{ispl}.energ_out = energ_out;
                energy{ispl}.rate = rate;
                energy{ispl}.rate_std = rate_std;
                energy{ispl}.fpeaks = params_ST{ispl}.fpeaks;
                energy{ispl}.R = R_int(1,2);
                energy{ispl}.R2 = R_int(1, 2).^2;
                energy{ispl}.rmse = calculateRMSE(rate, data_ST.rate);
                
            elseif strcmp(model_type, 'SFIE_pop')
                model_params.type = 'SFIE'; model_params.range = 1; model_params.species = 1;
                model_params.BMF = BMF; model_params.CFs = CFs; model_params.nAN_fibers_per_CF = 10;
                model_params.cohc = 1; model_params.cihc = 1; model_params.nrep = 1; model_params.implnt = 1;
                model_params.noiseType = 1; model_params.which_IC = 1; model_params.onsetWin = 0.020; model_params.fiberType = 3;
                
                AN_temp = modelAN(params_ST{ispl}, model_params);
                SFIE_temp = wrapperIC(AN_temp.an_sout, params_ST{ispl}, model_params);
                
                if strcmp(MTF_shape, 'BS') || strcmp(MTF_shape, 'BE')
                    suffix = ['_' MTF_shape];
                    SFIE_pop{ispl}.rate = mean(SFIE_temp.(['average_ic_sout' suffix]), 1);
                    SFIE_pop{ispl}.rate_std = std(SFIE_temp.(['average_ic_sout' suffix]), 1);
                    SFIE_pop{ispl}.fpeaks = SFIE_temp.CFs;
                    R_int = corrcoef(data_ST.rate, SFIE_pop{ispl}.rate);
                    SFIE_pop{ispl}.R = R_int(1,2);
                    SFIE_pop{ispl}.R2 = R_int(1, 2).^2;
                    SFIE_pop{ispl}.CFs = SFIE_temp.CFs;
                    SFIE_pop{ispl}.temporal = squeeze(mean(SFIE_temp.(['ic' suffix]), 2));
                else
                    SFIE_pop{ispl}.rate = [];
                end
                SFIE_pop{ispl}.MTF_shape = MTF_shape;
                SFIE_pop{ispl}.BMF = BMF;
                AN_pop{ispl}.rate = mean(AN_temp.average_AN_sout, 1);
                AN_pop{ispl}.rate_std = std(AN_temp.average_AN_sout, 1);
                AN_pop{ispl}.fpeaks = AN_temp.CFs;
                R_int = corrcoef(data_ST.rate, AN_pop{ispl}.rate);
                AN_pop{ispl}.R = R_int(1,2); AN_pop{ispl}.R2 = R_int(1, 2).^2;
                AN_pop{ispl}.CFs = AN_temp.CFs; AN_pop{ispl}.temporal = squeeze(mean(AN_temp.an_sout, 1));
                
            elseif strcmp(model_type, 'Lat_Inh')
                if strcmp(MTF_shape, 'BS')
                    S = 0.25; D = 0; oct_range = 0.75;
                else
                    S = 0.4; D = 0; oct_range = 0.5;
                end
                CS_params = [S S D]; BMFs = [100 100 100];
                
                model_params.type = 'Lateral Model'; model_params.range = 2; model_params.species = 1;
                model_params.num_CFs = 1; model_params.BMF = 100; model_params.nAN_fibers_per_CF = 10;
                model_params.cohc = 1; model_params.cihc = 1; model_params.nrep = 1; model_params.implnt = 1;
                model_params.noiseType = 1; model_params.which_IC = 1; model_params.onsetWin = 0.020; model_params.fiberType = 3;
                model_params.lateral_CF = [CF*2^(-1*oct_range), CF, CF*2^oct_range];
                model_params.CFs = model_params.lateral_CF; model_params.CF_range = model_params.CFs(2);
                model_params.config_type = 'BS inhibited by off-CF BS';
                
                AN_temp = modelLateralAN(params_ST{ispl}, model_params);
                latinh_temp = modelLateralSFIE_BMF(params_ST{ispl}, model_params, ...
                    AN_temp.an_sout, AN_temp.an_sout_lo, AN_temp.an_sout_hi, 'CS_params', CS_params, 'BMFs', BMFs);
                
                params_RM.type = 'RM'; params_RM.dur = 0.2; params_RM.ramp_dur = 0.01; params_RM.reptim = 0.6;
                params_RM.nrep = 1; params_RM.freqs = [3000,3001, 1]; params_RM.spls = []; params_RM.binmode = 2;
                params_RM.onsetWin = 25; params_RM.mnrep = 1; params_RM.Fs = 100000;
                params_RM = generate_RM(params_RM); params_RM.num_stim = size(params_RM.stim, 1);
                AN_spont = modelLateralAN(params_RM, model_params);
                SFIE_spont = modelLateralSFIE_BMF(params_RM, model_params, ...
                    AN_spont.an_sout, AN_spont.an_sout_lo, AN_spont.an_sout_hi, 'CS_params', CS_params, 'BMFs', BMFs);
                
                params_MTF.type = 'MTF'; params_MTF.Fs = 100000; params_MTF.ramp_dur = 0.05; params_MTF.noise_state = 0;
                params_MTF.noise_band = [100, 10000]; params_MTF.dur = 1; params_MTF.reptim = 1.5;
                params_MTF.fms = [2, 600, 3]; params_MTF.mdepths = [0,0,1]; params_MTF.binmode = 2;
                params_MTF.No = 30; params_MTF.spl = 30; params_MTF.raised_sine = 1; params_MTF.onsetWin = 25;
                params_MTF.mnrep = 3; params_MTF = generate_MTF(params_MTF); params_MTF.num_stim = size(params_MTF.stim, 1);
                AN_MTF = modelLateralAN(params_MTF, model_params);
                SFIE_MTF = modelLateralSFIE_BMF(params_MTF, model_params, ...
                    AN_MTF.an_sout, AN_MTF.an_sout_lo, AN_MTF.an_sout_hi, 'CS_params', CS_params, 'BMFs', BMFs);
                
                if strcmp(MTF_shape, 'BS') || strcmp(MTF_shape, 'BE')
                    [rate, rate_std] = plotST(params_ST{ispl}, latinh_temp.avIC, 0);
                    rate = rate ./ (max(rate)/max(data_ST.rate));
                    
                    lat_inh{ispl}.rate = rate; lat_inh{ispl}.rate_std = rate_std; lat_inh{ispl}.fpeaks = params_ST{ispl}.fpeaks;
                    R = corrcoef(data_ST.rate, rate); lat_inh{ispl}.R = R(1, 2); lat_inh{ispl}.R2 = R(1, 2)^2;
                    lat_inh{ispl}.PSTH = plotST_PSTH(params_ST{ispl}, latinh_temp.ic, 0);
                    lat_inh{ispl}.rmse = calculateRMSE(rate, data_ST.rate); lat_inh{ispl}.spont = SFIE_spont.avIC;
                    
                    [~, avBE, stdBE, MTF_shape_calc, rate_sm] = plotMTF(params_MTF, SFIE_MTF.avIC, 0);
                    lat_inh{ispl}.MTF_rate = avBE; lat_inh{ispl}.MTF_rate_std = stdBE;
                    lat_inh{ispl}.MTF_shape_calc = MTF_shape_calc; lat_inh{ispl}.MTF_rate_sm = rate_sm;
                    R_MTF = corrcoef(data_MTF.rate, avBE); lat_inh{ispl}.R_MTF = R_MTF(1, 2);
                else
                    lat_inh{ispl}.rate = [];
                end
                lat_inh{ispl}.MTF_shape = MTF_shape; lat_inh{ispl}.BMF = BMF;
                
                [rate, rate_std] = plotST(params_ST{ispl}, AN_temp.average_AN_sout, 0);
                AN_lat_inh{ispl}.rate = rate; AN_lat_inh{ispl}.rate_std = rate_std; AN_lat_inh{ispl}.fpeaks = params_ST{ispl}.fpeaks;
                R = corrcoef(data_ST.rate, rate); AN_lat_inh{ispl}.R = R(1, 2); AN_lat_inh{ispl}.R2 = R(1, 2)^2;
                AN_lat_inh{ispl}.PSTH = plotST_PSTH(params_ST{ispl}, AN_temp.an_sout, 0);
                AN_lat_inh{ispl}.spont = mean(AN_spont.average_AN_sout);
            end
        end
        
        % Report execution timer profiles
        elapsedTime = toc(timerVal2)/60;
        disp([putative ' Model (' model_type ', all levels) took ' num2str(elapsedTime) ' minutes'])
        
        % Save Model Output Arrays
        filename = [putative '_' model_type '.mat'];        
        % Determine the subfolder name based on model type
        switch model_type
            case 'Energy'
                subfolder = 'energy_model';
            case 'SFIE'
                subfolder = 'SFIE_model';
            case 'SFIE_pop'
                subfolder = 'SFIE_pop_model';
            case 'Lat_Inh'
                subfolder = 'lat_inh_model';
            otherwise
                error('Unknown model type: %s', model_type);
        end

        % Construct the full directory path and check/create it
        target_dir = fullfile(savepath, subfolder);
        if ~exist(target_dir, 'dir')
            mkdir(target_dir);
        end

        % Save the files based on model type
        switch model_type
            case 'Energy'
                save(fullfile(target_dir, filename), 'params_ST', 'energy');
            case 'SFIE'
                save(fullfile(target_dir, filename), 'params_ST', 'AN', 'SFIE', 'model_params');
            case 'SFIE_pop'
                save(fullfile(target_dir, filename), 'params_ST', 'AN_pop', 'SFIE_pop', 'model_params');
            case 'Lat_Inh'
                save(fullfile(target_dir, filename), 'params_ST', 'lat_inh', 'AN_lat_inh', 'model_params');
        end
        
    catch ME
        skipped_indices{jj} = sprintf('Model: %s, Putative: %s, Error: %s', model_type, putative, ME.message); 
        disp(['SKIPPED: ' skipped_indices{jj}])
        jj = jj + 1;
    end
end

%% --- Final Error Report Output Summary ---
if ~isempty(skipped_indices)
    fprintf('\n====== SKIPPED UNITS SUMMARY (%d total) ======\n', length(skipped_indices));
    for ii = 1:length(skipped_indices)
        disp(skipped_indices{ii})
    end
end

function rmse = calculateRMSE(predicted, actual)
    rmse = sqrt(mean((predicted - actual).^2));
end
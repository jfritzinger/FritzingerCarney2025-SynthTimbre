%% save_response_metrics.m
%
% Script to compute and save response metrics for synthetic timbre datasets.
% Options available for selecting combinations of Rate, Vector Strength (VS),
% and Spike-Distance (RIS) metrics, as well as data selection filtering.
%
% -------------------------------------------------------------------------
clear
%% 1. Selection Options
run_rate = true;   % Run traditional Rate peak-finding & thresholds
run_VS   = true;   % Run Temporal/Vector Strength peak-finding & thresholds
run_RIS  = true;   % Run Spike-Distance (RIS) metrics via SPIKY (Uses local parfor)

% Data scope choice: 'all' (loops columns 1:11) or 'ST_63dB' (loops column 2 only)
data_selection = 'all'; 

%% 2. Setup Paths & Load Spreadsheet
[base, datapath, savepath, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);

% Identify datasets containing target synthetic timbre strings ('R')
data_ind(:,1)  = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB);
data_ind(:,2)  = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
data_ind(:,3)  = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB);
data_ind(:,4)  = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB);
data_ind(:,5)  = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB_con);
data_ind(:,6)  = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB_con);
data_ind(:,7)  = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB_con);
data_ind(:,8)  = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB_con);
data_ind(:,9)  = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB_100);
data_ind(:,10) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB_100);
data_ind(:,11) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB_100);

% Dynamic configuration of active sessions and sub-loop tracking ranges
switch data_selection
    case 'ST_63dB'
        has_data = any(data_ind(:,2), 2);
        idata_range = 2;
    case 'all'
        has_data = any(data_ind, 2);
        idata_range = 1:11;
    otherwise
        error('Invalid selection for "data_selection". Use either "all" or "col2".');
end
data_index = find(has_data);
num_neurons = length(data_index);

%% 3. Initialize Output Table Structures
baseNames = ["Putative", "CF", "CF_Group", "MTF", "MTF_at200", "MTF_str", "SPL", "binmode", "F0"];
baseTypes = ["string", "double", "string", "string", "string", "double", "double", "double", "double"];

max_rows = 830; % Preallocating max expected rows

% --- Rate Table Setup ---
if run_rate
    rateNames = [baseNames, "Type", "Prom", "Width", "Lim", "Freq", "Q", "Q_log", "D_prime", "Threshold", "Thresh_Freq", "Slope_Rate"];
    rateTypes = [baseTypes, "string", "double", "double", "double", "double", "double", "double", "double", "double", "cell", "cell"]; 
    table_rate = table('Size', [max_rows, length(rateNames)], 'VariableTypes', rateTypes, 'VariableNames', rateNames);
    row_rate = 1;
end

% --- VS Table Setup ---
if run_VS
    vsNames = [baseNames, "Type", "Prom", "Width", "Lim", "Freq", "Q", "Q_log", "D_prime", "Threshold", "Thresh_Freq", "Slope_Rate"];
    vsTypes = [baseTypes, "string", "double", "double", "double", "double", "double", "double", "double", "double", "cell", "cell"]; 
    table_vs = table('Size', [max_rows, length(vsNames)], 'VariableTypes', vsTypes, 'VariableNames', vsNames);
    row_vs = 1;
end

% --- RIS Table Setup ---
if run_RIS
    risNames = [baseNames, "D_prime", "Threshold", "Thresh_Freq"];
    risTypes = [baseTypes, "double", "double", "cell"];
    table_ris = table('Size', [max_rows, length(risNames)], 'VariableTypes', risTypes, 'VariableNames', risNames);
    row_ris = 1;
end

%% 4. Processing Loop Across Neurons
for isesh = 1:num_neurons
    ineuron = data_index(isesh);
    putative = sessions.Putative_Units{ineuron};
    CF = sessions.CF(ineuron);
    MTF_shape = sessions.MTF{ineuron};
    at200 = sessions.MTF_at200{ineuron};
    
    load(fullfile(datapath, 'neural_data', [putative '.mat']))
    
    if CF < 2000,     CF_Group = 'Low';
    elseif CF < 4000, CF_Group = 'Med';
    else,             CF_Group = 'High';
    end
    
    % Analyze Modulation Transfer Function (MTF) base properties
    params_MTF = data{3, 2};
    data_MTF = struct('perc_change', NaN);
    if ~isempty(params_MTF)
        data_MTF = analyzeMTF(params_MTF);
    end
    
    for idata = idata_range
        if data_ind(ineuron, idata) == 1
            
            % Map out proper dataset index
            if ismember(idata, [1, 2, 3, 4])
                param_ST = data(5+idata, 2);
            elseif ismember(idata, [5, 6, 7, 8])
                param_ST = data(1+idata, 1);
            else
                param_ST = data(1+idata, 2);
            end
            
            spl = param_ST{1}.spl;
            data_ST = analyzeST(param_ST, CF);
            data_ST = data_ST{1};
            fpeaks = param_ST{1}.fpeaks;

            % Populate base metadata
            table_vs.Putative{row_vs}  = putative;
            table_vs.CF(row_vs)        = CF;
            table_vs.CF_Group{row_vs}  = CF_Group;
            table_vs.MTF{row_vs}       = MTF_shape;
            table_vs.MTF_at200{row_vs} = at200;
            table_vs.MTF_str(row_vs)   = data_MTF.perc_change;
            table_vs.SPL(row_vs)       = spl;
            table_vs.binmode(row_vs)   = param_ST{1}.binmode;
            table_vs.F0(row_vs)        = param_ST{1}.Delta_F;

            % --- PIPELINE A: RATE ---
            if run_rate
                [~, ~, typeR, promR, widthR, limR, ~, ~, freqR] = peakFinding(data_ST, CF, 'Rate', param_ST{1});
                [thresh_pctR, thresh_freqR, slope_rateR, d_primeR] = calculateThresholds(fpeaks, data_ST.rate, data_ST.rate_std, CF);
                
                % Populate Rate metrics
                table_rate.Type{row_rate}       = typeR;
                table_rate.Prom(row_rate)       = promR;
                table_rate.Width(row_rate)      = widthR;
                table_rate.Lim(row_rate)        = limR;
                table_rate.Freq(row_rate)       = freqR;
                table_rate.Q(row_rate)          = freqR / widthR;
                table_rate.Q_log(row_rate)      = log10(freqR / widthR);
                table_rate.D_prime(row_rate)    = d_primeR;
                table_rate.Threshold(row_rate)  = thresh_pctR;
                table_rate.Thresh_Freq{row_rate}= thresh_freqR;
                table_rate.Slope_Rate{row_rate} = slope_rateR;
                
                row_rate = row_rate + 1;
            end
            
            % --- PIPELINE B: VECTOR STRENGTH (VS) ---
            if run_VS || run_RIS
                temporal = analyzeST_Temporal(param_ST{1}, data_ST);
            end
            
            if run_VS
                [~, ~, typeV, promV, widthV, limV, ~, ~, freqV] = peakFinding(data_ST, CF, 'Temporal', param_ST{1});
                [thresh_pctV, thresh_freqV, slope_rateV, d_primeV] = calculateThresholds(fpeaks, temporal.VS_avg, temporal.VS_std, CF);          
                
                % Populate VS metrics
                table_vs.Type{row_vs}         = typeV;
                table_vs.Prom(row_vs)         = promV;
                table_vs.Width(row_vs)        = widthV;
                table_vs.Lim(row_vs)          = limV;
                table_vs.Freq(row_vs)         = freqV;
                table_vs.Q(row_vs)            = freqV / widthV;
                table_vs.Q_log(row_vs)        = log10(freqV / widthV);
                table_vs.D_prime(row_vs)      = d_primeV;
                table_vs.Threshold(row_vs)    = thresh_pctV;
                table_vs.Thresh_Freq{row_vs}  = thresh_freqV;
                table_vs.Slope_Rate{row_vs}   = slope_rateV;
                
                row_vs = row_vs + 1;
            end
            
            % --- PIPELINE C: SPIKE DISTANCE (RIS) ---
            if run_RIS
                [thresh_pct_RIS, thresh_freq_RIS, d_prime_RIS] = calculate_RIS_Metrics(param_ST, temporal, datapath, putative, CF);
                
                % Populate RIS metrics
                table_ris.D_prime(row_ris)     = max(d_prime_RIS, [], 'all');
                table_ris.Threshold(row_ris)   = thresh_pct_RIS;
                table_ris.Thresh_Freq{row_ris} = thresh_freq_RIS;
                
                row_ris = row_ris + 1;
            end
            
        end
    end
    fprintf('%s done, %d percent done\n', putative, round(isesh/num_neurons*100))
end

%% 5. Trim and Export Output Files Individually
% Export Rate Spreadsheet
if run_rate
    valid_rate = table_rate(1:row_rate-1, :);
    writetable(valid_rate, fullfile(datapath, 'peak_picking_w_thresholds_rate.xlsx'));
end

% Export VS Spreadsheet
if run_VS
    valid_vs = table_vs(1:row_vs-1, :);
    writetable(valid_vs, fullfile(datapath, 'peak_picking_w_thresholds_VS.xlsx'));
end

% Export RIS Spreadsheet
if run_RIS
    valid_ris = table_ris(1:row_ris-1, :);
    writetable(valid_ris, fullfile(datapath, 'peak_picking_w_thresholds_RIS.xlsx'));
end
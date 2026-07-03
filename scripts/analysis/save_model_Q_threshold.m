%% save_r2_table.m
%
% Script to create an excel spreadsheet with all R2 model results for each
% neuron at each level. Only for binaural stimuli. Used for
% 'plot_model_evaluations.m'.
%
%
% Author: J. Fritzinger
% Created: 2022-09-13; Last revision: 2024-09-26
%
% -------------------------------------------------------------------------
clear

% Load in spreadsheet
[base, datapath, savepath, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);
num_data = size(sessions, 1);

%%  Synthetic Timbre Data Table

% Initialize spreadsheet columns
varNames = ["Putative", "CF", "MTF", "BMF", "SPL"];
varTypes = ["string", "double", "string", "double", "double"];
est_num_rows = 429; % set to number larger than
num_cols = length(varNames);
table_size = [est_num_rows num_cols];
tables = table('Size',table_size,'VariableTypes',varTypes,'VariableNames',varNames);

% Find sessions for target synthetic timbre response
bin200(:,1) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB);
bin200(:,2) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
bin200(:,3) = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB);
bin200(:,4) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB);
isMTF = strcmp(sessions.MTF, 'BE')|strcmp(sessions.MTF, 'BS');
bin200_MTF = bin200 & isMTF;

% Add R^2 values to the spreadsheet
spls = [43, 63, 73, 83];
has_data = bin200_MTF(:,1) | bin200_MTF(:,2) | bin200_MTF(:,3) | bin200_MTF(:,4);
indices = find(has_data);
num_index = length(indices);

for imtype = 3
	ii = 1;
	for isesh = 1:num_index

		% Load in data
		putative = sessions.Putative_Units{indices(isesh)};
		CF = sessions.CF(indices(isesh));
		switch imtype
			case 1
				model_type = 'SFIE';
				load(fullfile(savepath,'SFIE_model', [putative '_SFIE.mat']), 'SFIE')
				datas_ST = SFIE;
			case 2
				model_type = 'Energy';
				load(fullfile(savepath,'energy_model', [putative '_Energy.mat']), 'energy')
				datas_ST = energy;
			case 3
				model_type = 'Lat_Inh';
				load(fullfile(savepath,'lat_inh_model', [putative '_Lat_Inh.mat']), 'lat_inh')
				datas_ST = lat_inh;
		end
		load(fullfile(datapath, 'neural_data', [putative '.mat']))

		for ispl = 1:4
			if ~isempty(datas_ST{ispl})

				% Analysis
				data_ST = datas_ST{ispl};
				param_ST = data(5+ispl, 2);

				if CF<2000
					CF_Group = 'Low';
				elseif CF>=2000 && CF<4000
					CF_Group = 'Med';
				else
					CF_Group = 'High';
				end
				if ~isempty(param_ST{1})
					data_ST.rates_sm = data_ST.rate;


					% Calculate Q for each model
					[peaks, dips, type, prom, width, lim, ~, ~, freq] = peakFinding(...
						data_ST, CF, 'Rate', param_ST{1});

					% Calculate thresholds
					fpeaks = param_ST{1}.fpeaks;
					rate = data_ST.rate;
					rate_std = data_ST.rate_std;
					[threshold_percent, threshold_freq, slope_rate, d_prime] = calculateThresholds(...
						fpeaks, rate, rate_std, CF);

					% Fill out table
					tables.Putative{ii} = sessions.Putative_Units{indices(isesh)};
					tables.Model{ii} = model_type;
					tables.CF(ii) = sessions.CF(indices(isesh));
					tables.CF_Group{ii} = CF_Group;
					tables.SPL(ii) = spls(ispl);
					tables.R(ii) = data_ST.R;
					tables.R2(ii) = data_ST.R2;
					tables.rmse(ii) = data_ST.rmse;
					tables.Width(ii) = width;
					tables.Lim(ii) = lim;
					tables.Prom(ii) = prom;
					tables.Freq(ii) = freq;
					tables.Q(ii) = freq/width;
					tables.Q_log(ii) = log10(freq/width);
					tables.D_prime(ii) = d_prime;
					tables.Threshold(ii) = threshold_percent;
					tables.Thresh_Freq{ii} = threshold_freq;
					tables.Slope_Rate{ii} = slope_rate;
					ii = ii + 1;
				end
			end
		end
		fprintf('%s done, %d percent done\n', putative, round(isesh/num_index*100))
	end

	% Save table
	writetable(tables,fullfile(savepath, ['model_' model_type '_Q_thresholds.xlsx']))
end


%% save_r2_table.m
%
% Script to create an excel spreadsheet with all R2 model results for each
% neuron at each level. Only for binaural stimuli. 
%
%
% Author: J. Fritzinger
% Created: 2022-09-13; Last revision: 2024-09-26
%
% -------------------------------------------------------------------------
clear

output_filename = 'model_st_r2_values.xlsx';

% Load in spreadsheet
[base, datapath, savepath, ppi] = getPaths();
sheetpath = 'data-cleaning';
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, sheetpath, spreadsheet_name), 'PreserveVariableNames',true);
num_data = size(sessions, 1);

%%  Synthetic Timbre Data Table

% Initialize spreadsheet columns
varNames = ["Putative", "CF", "MTF", "BMF"...
	"SPL", "SFIE_R", "SFIE_R2","SFIE_rmse",...
	"Energy_R", "Energy_R2", "Energy_rmse", ...
	"SFIE_Pop_R", "SFIE_Pop_R2", ...
	"Lat_Inh_R", "Lat_Inh_R2", "Lat_Inh_rmse", ...
	"p_s_e", "p_l_e", "p_l_s", "p_s_pop"];
varTypes = ["string", "double", "string", "double"...
	"double", "double", "double","double", ...
	"double", "double", "double", ...
	"double", "double",...
	"double", "double", "double", ...
	"double", "double", "double", "double"];
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
ii = 1;
for isesh = 1:num_index

	% Load in data
	putative = sessions.Putative_Units{indices(isesh)};
	load(fullfile(datapath,'SFIE_model', [putative '_SFIE.mat']), 'SFIE')
	load(fullfile(datapath,'energy_model', [putative '_Energy.mat']), 'energy')
	load(fullfile(datapath,'SFIE_pop_model', [putative '_SFIE_pop.mat']), 'SFIE_pop')
	load(fullfile(datapath,'lat_inh_model', [putative '_Lat_Inh.mat']), 'lat_inh')
	load(fullfile(datapath, 'neural_data', [putative '.mat']))

	for ispl = 1:4
		if ~isempty(SFIE{ispl})

			% Analysis
			sfie_temp = SFIE{ispl}.rate;
			energy_temp =  energy{ispl}.rate;
			lat_inh_temp =  lat_inh{ispl}.rate;
			sfie_pop_temp = SFIE_pop{ispl}.rate;
			params_ST = data(5+ispl, 2);
			data_ST = analyzeST(params_ST, []);
			data_ST = data_ST{1};
			rate = data_ST.rate;

			% F-test SFIE/energy
			p_s_e = ftest(rate, energy_temp, sfie_temp);

			% F-test LatInh/energy
			p_l_e = ftest(rate, energy_temp, lat_inh_temp);

			% F-test LatInh/SFIE
			p_l_s = ftest(rate, lat_inh_temp, sfie_temp);

			% F-test SFIE/population SFIE
			p_s_pop = ftest(rate, sfie_pop_temp', sfie_temp);


			% Normalize rmse to max/mean rate 
			sfie_temp = SFIE{ispl}.rmse ./ mean(rate);
			energy_rmse =  energy{ispl}.rmse ./ mean(rate);
			lat_inh_temp = lat_inh{ispl}.rmse ./ mean(rate);


			% Fill out table
			tables.Putative{ii} = sessions.Putative_Units{indices(isesh)};
			tables.CF(ii) = sessions.CF(indices(isesh));
			tables.MTF{ii} = SFIE{ispl}.MTF_shape;
			tables.BMF(ii) = SFIE{ispl}.BMF;
			tables.SPL(ii) = spls(ispl);
			tables.SFIE_R(ii) = SFIE{ispl}.R;
			tables.SFIE_R2(ii) = SFIE{ispl}.R2;
			tables.SFIE_rmse(ii) = SFIE{ispl}.rmse;
			tables.Energy_R(ii) = energy{ispl}.R;
			tables.Energy_R2(ii) = energy{ispl}.R2;
			tables.Energy_rmse(ii) = energy{ispl}.rmse;
			tables.SFIE_Pop_R(ii) = SFIE_pop{ispl}.R;
			tables.SFIE_Pop_R2(ii) = SFIE_pop{ispl}.R2;
			tables.Lat_Inh_R(ii) = lat_inh{ispl}.R;
			tables.Lat_Inh_R2(ii) = lat_inh{ispl}.R2;
			tables.Lat_Inh_rmse(ii) = lat_inh{ispl}.rmse;
			tables.p_s_e(ii) = p_s_e;
			tables.p_l_e(ii) = p_l_e;
			tables.p_l_s(ii) = p_l_s;
			tables.p_s_pop(ii) = p_s_pop;
			ii = ii + 1;
		end
	end
	fprintf('%s done, %d percent done\n', putative, round(isesh/num_index*100))
end

% Save table
writetable(tables,output_filename)



%% -------------------------------------------------------------------------

function p_value = ftest(data, prediction1, prediction2)
% Assuming you have these variables:
% data: 40x1 vector of observed data
% gaussian_prediction: 40x1 vector of Gaussian model predictions
% dog_prediction: 40x1 vector of DoG model predictions

squared_errors_A = (data - prediction1).^2;
squared_errors_B = (data - prediction2).^2;
[~, p_value, ~, ~] = ttest(squared_errors_A, squared_errors_B);

end

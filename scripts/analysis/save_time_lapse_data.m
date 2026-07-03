%% save_time_lapse_data
%
% Author: J. Fritzinger
% Created: ------; Last revision:
%
% -------------------------------------------------------------------------
clear

output_filename = 'time_lapse.xlsx';

% Load in spreadsheet
[base, datapath, savepath, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name),...
	'PreserveVariableNames',true);
num_data = size(sessions, 1);

% Initialize spreadsheet columns
varNames = ["Putative", "CF", "MTF", ...
	"SPL", "binmode", "win", "Q"];
varTypes = ["string", "double", "string", ...
	"double", "double","double", "double"];
est_num_rows = 1100; % set to number larger than
num_cols = length(varNames);
table_size = [est_num_rows num_cols];
tables = table('Size',table_size,'VariableTypes',varTypes,'VariableNames',varNames);

%% Plot each dataset 

% Find sessions for target synthetic timbre response
bin200(:,1) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB);
bin200(:,2) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
bin200(:,3) = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB);
bin200(:,4) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB);

bin200_MTF = bin200; % & isMTF;
has_data = bin200_MTF(:,1) | bin200_MTF(:,2) | bin200_MTF(:,3) | bin200_MTF(:,4);
index = find(has_data);

% Sort by CF
CF_list = sessions.CF(has_data);
[~, order] = sort(CF_list);
num_sessions = length(CF_list);

% Plot each neuron
ii = 1;
for isesh = 1:num_sessions
	ineuron = index(order(isesh)); %indices(isesh)
	if any(has_data(ineuron))

		% Load in data 
		putative = sessions.Putative_Units{ineuron};
		CF = sessions.CF(ineuron);
		MTF_shape = sessions.MTF{ineuron};
		load(fullfile(datapath,'neural_data' ,[putative '.mat']))

		% Plot synthetic timbre (raw)
		spls = [43, 63, 73, 83];
		data_colors = {'#82BB95', '#3F985C', '#03882F', '#034E1C'};
		for ispl = 1:4
			if bin200_MTF(ineuron, ispl)==1

				% Analyze data 
				param_ST = data(5+ispl, 2);
				data_ST = analyzeST(param_ST, CF);
				data_ST = data_ST{1};

				% Analyze by cutting into two sections, 50-150, 200-300ms
				[rate, rates_sm, rate_std] = analyzeSTWindow(param_ST, CF);

				% Calculate Q for each section
				win1_ST.rates_sm = rates_sm(1,:);
				win1_ST.fpeaks = data_ST.fpeaks;
				[~, ~, type, ~, width, ~, ~,~, freq] = peakFinding(win1_ST, CF, 'Rate', param_ST);
				Q(1) = freq/width;
				type_Q{1} = type;
				win2_ST.rates_sm = rates_sm(2,:);
				win2_ST.fpeaks = data_ST.fpeaks;
				[~, ~, type, ~, width, ~, ~, ~, freq] = peakFinding(win2_ST, CF, 'Rate', param_ST);
				Q(2) = freq/width;
				type_Q{2} = type;

				for jj = 1:2
					% Populate spreadsheet
					tables.Putative{ii} = putative;
					tables.CF(ii) = CF;
					tables.MTF{ii} = MTF_shape;
					tables.binmode(ii) = 2;
					tables.win(ii) = jj;
					tables.SPL(ii) = spls(ispl);
					tables.type{ii} = type_Q{jj};
					tables.Q(ii) = Q(jj);
					ii = ii+1;
				end
			end
		end
		fprintf('%s Done, %.2f percent \n', putative, isesh/num_sessions*100)
	end
end

%% Save spreadsheet 

writetable(tables,fullfile(datapath,output_filename))

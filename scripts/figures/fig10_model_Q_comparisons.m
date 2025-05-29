function fig10_model_Q_comparisons(save_fig)

%% Load in spreadsheet

[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'Data_Table.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);

%% Plot Q

figure('Position',[560,594,4.567*ppi,1.8*ppi])
legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;

h(1) = subplot(1, 3, 1);
colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980;0.9290 0.6940 0.1250;0.4940 0.1840 0.5560];
for ii = 1:4
	if ii == 1
		tables = readtable(fullfile(datapath,"peak_picking_excludeflat.xlsx"));
	elseif ii == 2
		tables = readtable(fullfile(datapath, "model_Energy_Q_thresholds.xlsx"));
	elseif ii == 3
		tables = readtable(fullfile(datapath, "model_SFIE_Q_thresholds.xlsx"));
	else
		tables = readtable(fullfile(datapath, "model_Lat_Inh_Q_thresholds.xlsx"));
	end

	spls = [43, 63, 73, 83];
	ispl = 2;

	% Get data
	islevel = tables.SPL == spls(ispl);
	index = islevel; % & isMTF;

	% Data
	CFs = tables.CF(index);
	Qs = tables.Q(index);

	% Fit linear regression line
	mdl = fitlm(log10(CFs), log10(Qs));

	% Generate x-values in log space (sorted for proper shading)
	x_log = log10(0.3:0.5:10000)';  % Create in log scale directly
	[x_log_sorted, sort_idx] = sort(x_log);

	% Get predictions with confidence intervals (log scale)
	[ypred_log, ci_log] = predict(mdl, x_log_sorted);

	% Convert back to original scale
	x_original = 10.^x_log_sorted;
	mdlfit = 10.^ypred_log;
	ci_low = 10.^ci_log(:,1);
	ci_high = 10.^ci_log(:,2);

	% Plotting
	plot(x_original/1000, mdlfit,'color', colors(ii,:), 'LineWidth', linewidth);
	hold on;
	fill([x_original/1000; flipud(x_original/1000)],...
		[ci_low; flipud(ci_high)],...
		colors(ii,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
end
xlabel('CF (kHz)')
if ispl == 1
	ylabel('Q')
end
ylim([0.35 50])
xlim([0.3 10])
set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
xticks([0 200 500 1000 2000 5000 10000]/1000)
yticks([0.2 0.5 1 2 5 10 20 50 100 200 500 1000 2000])
grid on
set(gca, 'fontsize', fontsize)
hleg = legend('Data', '', 'Energy', '', 'SFIE','',  'Broad Inh.', '',...
	'Location','northwest', 'fontsize', legsize);
hleg.ItemTokenSize = [8,8];
hleg.Position = [0.186980524203153,0.241286799620133,0.142857142857143,0.257692307692308];
hleg.Box = 'off';
ylabel('Q')
box off
title('Q vs CF')

%% Plot histogram of increase/decrease/no change

for ii = 1:4
	if ii == 1
		tables = readtable(fullfile(datapath, "peak_picking_excludeflat.xlsx"));
	elseif ii == 2
		tables = readtable(fullfile(datapath, "model_Energy_Q_thresholds.xlsx"));
	elseif ii == 3
		tables = readtable(fullfile(datapath, "model_SFIE_Q_thresholds.xlsx"));
	else
		tables = readtable(fullfile(datapath, "model_Lat_Inh_Q_thresholds.xlsx"));
	end

	% Find sessions for target synthetic timbre response
	all_neurons = tables.Putative;
	neurons = unique(all_neurons);
	num_units = size(neurons, 1);

	SPLs = [43, 63, 73, 83];
	qs = NaN(num_units, 4);
	for isesh = 1:num_units
		putative = neurons{isesh};
		isput = cellfun(@(s) strcmp(s, putative), tables.Putative);
		for ispl = 1:4
			if ii == 1
				ind = isput & tables.SPL==SPLs(ispl) & tables.F0==200 & tables.binmode==2;
			else
				ind = isput & tables.SPL==SPLs(ispl);
			end
			if any(ind)
				qs(isesh, ispl) = tables.Q(ind);
			end
		end
	end

	% Get matrix of units with 43, 63, 83 dB
	qs2 = qs(:,[1,2,4]);
	rows_with_nan = any(isnan(qs2),2);
	qs2(rows_with_nan,:) = [];
	x = [43, 63, 83];

	% Try 1: Criteria using slope
	for jj = 1:length(qs2)
		y = qs2(jj, :)';
		tbl = table(x', y, 'VariableNames', {'X', 'Q'});
		mdl = fitlm(tbl, 'Q ~ X');
		slopes(jj) = mdl.Coefficients.Estimate(2); % slope
	end
	criteria = 0.03;
	same = slopes<criteria & slopes > -1*criteria;
	decrease = slopes<-1*criteria;
	increase = slopes>criteria;

	% Create matrix of values 
	all_same(ii) = sum(same)/length(same)*100;
	all_increase(ii) = sum(increase)/length(increase)*100;
	all_decrease(ii) = sum(decrease)/length(decrease)*100;
end

h(2) = subplot(1, 3, 2);
all_Q = [all_increase; all_same; all_decrease]';
bh = bar(all_Q, 'stacked');
xticklabels({'Data', 'Energy', 'SFIE', 'Broad Inh.'})
bh(1).FaceColor = '#1b9e77'; %blue
bh(2).FaceColor = '#d95f02'; %light blue
bh(3).FaceColor = '#7570b3'; %pink
ylabel('# Neurons')
set(gca, 'fontsize', fontsize)
hleg = legend('Sharpen', 'No Change', 'Broaden', 'Location','north',...
	'numcolumns', 2, 'fontsize', legsize, 'box', 'off');
hleg.Position = [0.390577499117385,0.742307692307692,0.278115501519756,0.142307692307692];
hleg.ItemTokenSize = [8,8];
ylim([0 100])
yticks([0 25 50 75 100])
box off 
grid on
title({'Changes in Q', '', ''})

%% 

for ii = 1:4
	if ii == 1
		tables = readtable(fullfile(datapath, "peak_picking_w_thresholds.xlsx"));
	elseif ii == 2
		tables = readtable(fullfile(datapath, "model_Energy_Q_thresholds.xlsx"));
	elseif ii == 3
		tables = readtable(fullfile(datapath, "model_SFIE_Q_thresholds.xlsx"));
	else
		tables = readtable(fullfile(datapath, "model_Lat_Inh_Q_thresholds.xlsx"));
	end

	% Find sessions for target synthetic timbre response
	all_neurons = tables.Putative;
	neurons = unique(all_neurons);
	num_units = size(neurons, 1);

	SPLs = [43, 63, 73, 83];
	qs = NaN(num_units, 4);
	for isesh = 1:num_units
		putative = neurons{isesh};
		isput = cellfun(@(s) strcmp(s, putative), tables.Putative);
		for ispl = 1:4
			if ii == 1
				ind = isput & tables.SPL==SPLs(ispl) & tables.F0==200 & tables.binmode==2;
			else
				ind = isput & tables.SPL==SPLs(ispl);
			end
			if any(ind)
				qs(isesh, ispl) = tables.Threshold(ind);
			end
		end
	end

	% Get matrix of units with 43, 63, 83 dB
	qs2 = qs(:,[1,2,4]);
	rows_with_nan = any(isnan(qs2),2);
	qs2(rows_with_nan,:) = [];
	x = [43, 63, 83];

	% Try 1: Criteria using slope
	for jj = 1:length(qs2)
		y = qs2(jj, :)';
		tbl = table(x', y, 'VariableNames', {'X', 'Q'});
		mdl = fitlm(tbl, 'Q ~ X');
		slopes(jj) = mdl.Coefficients.Estimate(2); % slope
	end
	criteria = 0.03;
	same = slopes<criteria & slopes > -1*criteria;
	decrease = slopes<-1*criteria;
	increase = slopes>criteria;

	% Create matrix of values 
	all_same(ii) = sum(same)/length(same)*100;
	all_increase(ii) = sum(increase)/length(increase)*100;
	all_decrease(ii) = sum(decrease)/length(decrease)*100;
end

h(3) = subplot(1, 3, 3);
all_Q = [all_increase; all_same; all_decrease]';
bh = bar(all_Q, 'stacked');
xticklabels({'Data', 'Energy', 'SFIE', 'Broad Inh.'})
% bh(1).FaceColor = '#1b9e77';   %blue
% bh(2).FaceColor = '#d95f02'; %light blue
% bh(3).FaceColor = '#7570b3'; %pink
ylabel('%')
set(gca, 'fontsize', fontsize)
hleg = legend('Increase', 'No Change', 'Decrease', 'Location','north',...
	'numcolumns', 2, 'fontsize', legsize, 'box', 'off');
hleg.ItemTokenSize = [8,8];
hleg.Position = [0.715805462643221,0.730769230769232,0.279635258358663,0.142307692307692];
ylim([0 100])
yticks([0 25 50 75 100])
box off 
grid on
title({'Changes in Threshold', '', ''})

%% Arrange and annotate

bottom = 0.24;
left = linspace(0.08, 0.73, 3);
height = 0.62;
width = 0.24;

set(h(1), 'position', [left(1) bottom(1) width height])
set(h(2), 'position', [left(2) bottom(1) width 0.49])
set(h(3), 'position', [left(3) bottom(1) width 0.49])


%% Set annotations

left = linspace(0, 0.67, 3);
label = {'A', 'B', 'C'};
for ii = 1:3
	annotation('textbox',[left(ii) 0.98 0.0826 0.0385],'String',label{ii},...
		'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
end

%% Save figure 
if save_fig == 1
	filename = 'fig10_model_Q_comparisons';
	save_figure(filename)
end
end
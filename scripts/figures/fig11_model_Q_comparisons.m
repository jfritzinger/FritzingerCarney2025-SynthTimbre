function fig11_model_Q_comparisons(save_fig)
% FIG11_MODEL_Q_COMPARISONS Generates Figure 11 comparing data parameters against model predictions.
%
% PURPOSE:
%   This function contrasts experimental data filter characteristics (Q-factors and thresholds)
%   against the predictions of three central auditory models: Energy, SFIE, and Broad/Lateral Inhibition.
%   It plots linear regression fits of Q vs. Characteristic Frequency (CF) with 95% confidence 
%   bounds, and provides stacked percentiles tracing directional tuning adjustments (Sharpening/Broadening 
%   and Threshold sensitivities) induced across acoustic sound pressure levels.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a 3-panel horizontal model comparison figure. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up

%% Load in spreadsheet and layout properties
[~, datapath, ~, ppi] = get_paths(); 

figure('Position', [560, 594, 4.567*ppi, 1.8*ppi])
h = gobjects(3, 1);

legsize = 6;
fontsize = 7;
labelsize = 13;
linewidth = 1;

h(1) = subplot(1, 3, 1);
colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560];

%% Panel A: Plot Q vs CF Regressions
for ii = 1:4
	if ii == 1
		tables = readtable(fullfile(datapath, "LMM", "peak_picking_excludeflat.xlsx"));
	elseif ii == 2
		tables = readtable(fullfile(datapath, "model_Energy_Q_thresholds.xlsx"));
	elseif ii == 3
		tables = readtable(fullfile(datapath, "model_SFIE_Q_thresholds.xlsx"));
	else
		tables = readtable(fullfile(datapath, "model_Lat_Inh_Q_thresholds.xlsx"));
	end
	
	spls = [43, 63, 73, 83];
	ispl = 2;
	islevel = tables.SPL == spls(ispl);
	
	CFs = tables.CF(islevel);
	Qs = tables.Q(islevel);
	
	% Fit linear regression line
	mdl = fitlm(log10(CFs), log10(Qs));
	x_log = log10(0.3:0.5:10000);  
	x_log_sorted = sort(x_log);
	
	[ypred_log, ci_log] = predict(mdl, x_log_sorted');
	
	x_original = 10.^x_log_sorted';
	mdlfit = 10.^ypred_log;
	ci_low = 10.^ci_log(:, 1);
	ci_high = 10.^ci_log(:, 2);
	
	plot(x_original/1000, mdlfit, 'color', colors(ii, :), 'LineWidth', linewidth);
	hold on;
	fill([x_original/1000; flipud(x_original/1000)], [ci_low; flipud(ci_high)], ...
		colors(ii, :), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
end

xlabel('CF (kHz)')
ylabel('Q')
ylim([0.35 50])
xlim([0.3 10])
set(gca, 'XScale', 'log', 'YScale', 'log', 'fontsize', fontsize)
xticks([0 200 500 1000 2000 5000 10000]/1000)
yticks([0.2 0.5 1 2 5 10 20 50 100 200 500 1000 2000])
grid on
box off
title('Q vs CF')

hleg1 = legend('Data', '', 'Energy', '', 'SFIE', '', 'Broad Inh.', '', 'Location', 'northwest', 'fontsize', legsize);
hleg1.ItemTokenSize = [8, 8];
hleg1.Position = [0.1870, 0.2413, 0.1429, 0.2577];
hleg1.Box = 'off';

%% Panel B: Changes in Q Profile Distribution
all_same = zeros(4, 1);
all_increase = zeros(4, 1);
all_decrease = zeros(4, 1);
x_vals = [43, 63, 83];

for ii = 1:4
	if ii == 1
		tables = readtable(fullfile(datapath, "LMM", "peak_picking_excludeflat.xlsx"));
	elseif ii == 2
		tables = readtable(fullfile(datapath, "model_Energy_Q_thresholds.xlsx"));
	elseif ii == 3
		tables = readtable(fullfile(datapath, "model_SFIE_Q_thresholds.xlsx"));
	else
		tables = readtable(fullfile(datapath, "model_Lat_Inh_Q_thresholds.xlsx"));
	end
	
	neurons = unique(tables.Putative);
	num_units = size(neurons, 1);
	SPLs = [43, 63, 73, 83];
	qs = NaN(num_units, 4);
	
	for isesh = 1:num_units
		putative = neurons{isesh};
		isput = strcmp(tables.Putative, putative);
		for ispl = 1:4
			if ii == 1
				ind = isput & tables.SPL == SPLs(ispl) & tables.F0 == 200 & tables.binmode == 2;
			else
				ind = isput & tables.SPL == SPLs(ispl);
			end
			if any(ind)
				qs(isesh, ispl) = tables.Q(ind);
			end
		end
	end
	
	qs2 = qs(:, [1, 2, 4]);
	qs2(any(isnan(qs2), 2), :) = [];
	slopes = zeros(size(qs2, 1), 1);
	
    % Optimized math: Fast polyfit replaces fitlm loops
	for jj = 1:size(qs2, 1)
		p = polyfit(x_vals, qs2(jj, :), 1);
		slopes(jj) = p(1); 
	end
	
	criteria = 0.03;
	same = slopes < criteria & slopes > -criteria;
	decrease = slopes <= -criteria;
	increase = slopes >= criteria;
	
	all_same(ii) = sum(same) / length(same) * 100;
	all_increase(ii) = sum(increase) / length(same) * 100;
	all_decrease(ii) = sum(decrease) / length(same) * 100;
end

h(2) = subplot(1, 3, 2);
all_Q = [all_increase, all_same, all_decrease]; 
bh = bar(all_Q, 'stacked');

xticklabels({'Data', 'Energy', 'SFIE', 'Broad Inh.'})
bh(1).FaceColor = '#1b9e77'; 
bh(2).FaceColor = '#d95f02'; 
bh(3).FaceColor = '#7570b3'; 
ylabel('# Neurons')
ylim([0 100])
yticks(0:25:100)
set(gca, 'fontsize', fontsize)
box off 
grid on
title('Changes in Q')

hleg2 = legend('Sharpen', 'No Change', 'Broaden', 'Location', 'north', 'numcolumns', 2, 'fontsize', legsize, 'box', 'off');
hleg2.Position = [0.3905, 0.8, 0.2781, 0.1423];
hleg2.ItemTokenSize = [8, 8];

%% Panel C: Changes in Threshold Profile Distribution
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
	
	neurons = unique(tables.Putative);
	num_units = size(neurons, 1);
	SPLs = [43, 63, 73, 83];
	qs = NaN(num_units, 4);
	
	for isesh = 1:num_units
		putative = neurons{isesh};
		isput = strcmp(tables.Putative, putative);
		for ispl = 1:4
			if ii == 1
				ind = isput & tables.SPL == SPLs(ispl) & tables.F0 == 200 & tables.binmode == 2;
			else
				ind = isput & tables.SPL == SPLs(ispl);
			end
			if any(ind)
				qs(isesh, ispl) = tables.Threshold(ind);
			end
		end
	end
	
	qs2 = qs(:, [1, 2, 4]);
	qs2(any(isnan(qs2), 2), :) = [];
	slopes = zeros(size(qs2, 1), 1);
	
	for jj = 1:size(qs2, 1)
		p = polyfit(x_vals, qs2(jj, :), 1);
		slopes(jj) = p(1); 
	end
	
	criteria = 0.03;
	same = slopes < criteria & slopes > -criteria;
	decrease = slopes <= -criteria;
	increase = slopes >= criteria;
	
	all_same(ii) = sum(same) / length(same) * 100;
	all_increase(ii) = sum(increase) / length(same) * 100;
	all_decrease(ii) = sum(decrease) / length(same) * 100;
end

h(3) = subplot(1, 3, 3);
all_Threshold = [all_increase, all_same, all_decrease];
bh2 = bar(all_Threshold, 'stacked');

xticklabels({'Data', 'Energy', 'SFIE', 'Broad Inh.'})
bh2(1).FaceColor = '#1b9e77';   
bh2(2).FaceColor = '#d95f02'; 
bh2(3).FaceColor = '#7570b3'; 
ylabel('%')
ylim([0 100])
yticks(0:25:100)
set(gca, 'fontsize', fontsize)
box off 
grid on
title('Changes in Threshold')

hleg3 = legend('Increase', 'No Change', 'Decrease', 'Location', 'north', 'numcolumns', 2, 'fontsize', legsize, 'box', 'off');
hleg3.ItemTokenSize = [8, 8];
hleg3.Position = [0.7158, 0.8, 0.2796, 0.1423];

%% Coordinate Layout Adjustments
bottom_val = 0.24;
left_vals = linspace(0.08, 0.73, 3);
height_val = 0.62;
width_val = 0.24;

set(h(1), 'position', [left_vals(1) bottom_val width_val height_val])
set(h(2), 'position', [left_vals(2) bottom_val width_val 0.49])
set(h(3), 'position', [left_vals(3) bottom_val width_val 0.49])

%% Set Panel Text Annotations
annot_lefts = linspace(0, 0.67, 3);
labels = {'A', 'B', 'C'};
for ii = 1:3
	annotation('textbox', [annot_lefts(ii) 0.98 0.0826 0.0385], 'String', labels{ii}, ...
		'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
end

%% Export Figure Matrix
if save_fig == 1
	filename = 'fig11_model_Q_comparisons';
	save_figure(filename)
end
end
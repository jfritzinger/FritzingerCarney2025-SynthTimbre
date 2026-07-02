function fig7_changes_over_level(save_fig)
% FIG7_CHANGES_OVER_LEVEL Generates Figure 7 illustrating changes in tuning over level.
%
% PURPOSE:
%   This function visualizes and tracks changes in neural response tuning filters 
%   (quantified by Q-factor) as a function of acoustic presentation level (43, 63, 73, 
%   and 83 dB SPL). It categorizes and plots individual examples into groups based on 
%   their behavior ("Sharpening", "No Change", "Broadening"), applies linear regression 
%   slopes to individual cells, evaluates performance across low/med/high characteristic 
%   frequency (CF) populations, and maps tracking profiles via stacked distribution percentages.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a complex multi-panel analysis figure tracking level effects. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - analyzeRM()               : Analyzes Response Area / Rate-Intensity Matrix data
%   - smooth_rates()            : Smooths physiological vector tracks relative to CF
%   - peakFinding()             : Algorithmic categorization of peaks, dips, and proms
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up

%% Load in data
[~, datapath, ~, ppi] = get_paths(); 
tables = readtable(fullfile(datapath, "LMM", "peak_picking_excludeflat.xlsx"));
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames', true);

%% Set up figure matrix
figure('Position', [50, 50, 4.567*ppi, 6*ppi])
h = gobjects(12, 1); % Preallocate all layout graphics slots up front

legsize = 5;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;
scattersize = 12;
capsize = 2;

%% Set up and plot individual example units
plot_ind = [1, 2, 4, 5, 7, 8];
leglocations = [0.2416, 0.9097, 0.1337, 0.0601;...
	0.5456, 0.9050, 0.1337, 0.0601;...
	0.2386, 0.6620, 0.1337, 0.0601;...
	0.5638, 0.6620, 0.1337, 0.0601;...
	0.2477, 0.4143, 0.1337, 0.0601;...
	0.5668, 0.4166, 0.1337, 0.0601];

for ineuron = 1:6
	h(plot_ind(ineuron)) = subplot(4, 3, plot_ind(ineuron));
	switch ineuron
		case 1 % Sharpening
			putative = 'R27_TT3_P7_N08';
		case 2 % Sharpening
            putative = 'R27_TT3_P1_N06';
		case 3 % No Change 
			putative = 'R29_TT4_P5_N02';
		case 4 % No Change 
			putative = 'R27_TT2_P8_N02';
		case 5 % Broadening
			putative = 'R24_TT2_P13_N03';
		case 6 % Broadening
			putative = 'R24_TT2_P13_N05';
	end
    
	filename = sprintf('%s.mat', putative);
	load(fullfile(datapath, 'neural_data', filename), 'data');
	index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
	CF = sessions.CF(index);
	params = data([6,7,9], 2);
	params = params(~cellfun(@isempty, params));
	data_ST  = analyzeST(params, CF);
    
	params_RM = data{2, 2};
	data_RM = analyzeRM(params_RM);
	spont = data_RM.spont;
	num_ds = size(data_ST, 2);
	data_colors = {'#000000', '#737373', '#bdbdbd'};
    
	spls = cell2mat(cellfun(@(p) p.spl, data_ST, 'UniformOutput', false));
	[~, order] = sort(spls);
	order = fliplr(order);
	max_rate = max(cellfun(@(d) max(d.rate), data_ST));
	hold on
    
    Q = zeros(num_ds, 1);
	for ind = 1:num_ds
		rate = data_ST{order(ind)}.rate;
		rate_std = data_ST{order(ind)}.rate_std;
		rlb = data_ST{order(ind)}.rlb;
		rub = data_ST{order(ind)}.rub;
		fpeaks = data_ST{order(ind)}.fpeaks;
        
		rates_sm = smooth_rates(rate, rlb, rub, CF);
		type = 'Rate';
		errorbar(fpeaks./1000, rate, rate_std/sqrt(30), 'linestyle', ...
			'none', 'linewidth', 0.8, 'color', data_colors{ind}, 'capsize', capsize)
		plot(fpeaks./1000, rates_sm, 'LineWidth', linewidth, 'Color', data_colors{ind})
		[~, ~, ~, ~, width, ~, ~, ~, freq] = peakFinding(data_ST{order(ind)}, CF, type, []);
		Q(ind) = freq/width;
	end
	yline(spont, 'k', 'LineWidth', linewidth)
	plot_range = [params{1}.fpeaks(1) params{1}.fpeaks(end)]./1000;
	xline(CF./1000, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); 
	xlabel('Spectral Peak Freq. (kHz)')
	if ismember(ineuron, [1 3 5])
		ylabel('Avg. rate (sp/s)')
	end
	set(gca, 'Fontsize', fontsize);
	xlim(plot_range);
	grid on
    if ineuron == 2
        ylim([0 max_rate+20])
    else
        ylim([0 max_rate+10])
    end
	hLeg = legend('', sprintf('83, Q=%0.1f', Q(1)), '', sprintf('63, Q=%0.1f', Q(2)), ...
		'', sprintf('43, Q=%0.1f', Q(3)));
	hLeg.ItemTokenSize = [6, 6];
	hLeg.FontSize = legsize;
	hLeg.Box = 'off';
	hLeg.Position = leglocations(ineuron, :);
end

%% Track overall variations across population profiles
all_neurons = tables.Putative;
neurons = unique(all_neurons);
num_units = size(neurons, 1);
isbin = tables.binmode == 2;
is200 = tables.F0 == 200;
SPLs = [43, 63, 73, 83];
qs = NaN(num_units, 4);
qs_log = zeros(num_units, 4);
CF_group = cell(num_units, 1);

for isesh = 1:num_units
	putative = neurons{isesh};
	isput = strcmp(tables.Putative, putative);
	for ispl = 1:4
		ind = isput & isbin & is200 & tables.SPL == SPLs(ispl);
		if any(ind)
			qs(isesh, ispl) = tables.Q(ind);
			qs_log(isesh, ispl) = tables.Q_log(ind);
			CF_group{isesh} = tables.CF_Group{find(ind, 1)};
		end
	end
end

qs2 = qs(:, [1, 2, 4]);
rows_with_nan = any(isnan(qs2), 2);
qs2(rows_with_nan, :) = [];
CF_group(rows_with_nan) = [];
x_vals = [43, 63, 83];

% Vector-optimized slope extraction
slopes = zeros(size(qs2, 1), 1);
for ii = 1:size(qs2, 1)
    p = polyfit(x_vals, qs2(ii, :), 1);
    slopes(ii) = p(1);
end

criteria = 0.03;
same = slopes < criteria & slopes > -criteria;
decrease = slopes <= -criteria;
increase = slopes >= criteria;
spls = [43, 63, 83];
indices = [3, 6, 9];

for ii = 1:3
	if ii == 1
		values = increase;
		color = [27, 158, 119]/256;
	elseif ii == 2
		values = same;
		color = [217, 95, 2]/256;
	else
		values = decrease;
		color = [117, 112, 179]/256;
	end
	h(indices(ii)) = subplot(4, 3, indices(ii));
	hold on
	plot(spls, qs2(values, :)', 'color', color, 'LineWidth', linewidth)
	xticks(spls)
	ylabel('Q')
	xlim([40 86])
	plot(spls, mean(qs2(values, :), 1, 'omitnan'), 'k', 'LineWidth', linewidth)
	plot(spls, median(qs2(values, :), 1, 'omitnan'), ':k', 'LineWidth', linewidth)
	set(gca, 'fontsize', fontsize)
	xlabel('Level (dB SPL)')
	label = ['n=' num2str(sum(values))];
	text(0.05, 0.95, label, 'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', fontsize)
	
    hLeg = legend;
	num_lines = size(hLeg.String, 2);
    leg = cell(num_lines, 1);
	for iii = 1:num_lines
		if iii == num_lines
			leg{iii} = 'Mean';
		elseif iii == num_lines-1
			leg{iii} = 'Median';
		else
			leg{iii} = '';
		end
	end
	hLeg = legend(leg, 'FontSize', legsize);
	hLeg.ItemTokenSize = [12, 6];
	hLeg.Box = 'off';
	ylim([0 18])
end

%% Track specific regression vs CF Groups
spls = [43, 63, 73, 83];
is200 = tables.F0 == 200;

for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; 
		CFs = tables.CF(index);
		CF_groups = tables.CF_Group(index);
		Qs = tables.Q(index);
		
		h(10) = subplot(4, 3, 10);
		for igroup = 1:3
			if igroup == 1
				ind = strcmp(CF_groups, 'Low');
			elseif igroup == 2
				ind = strcmp(CF_groups, 'Med');
			else
				ind = strcmp(CF_groups, 'High');
			end
			scatter(CFs(ind)/1000, Qs(ind), scattersize, 'filled', 'MarkerEdgeColor', 'k')
			hold on
		end
        
		mdl = fitlm(log10(CFs), log10(Qs));
		x_fit = 0.3:0.5:10000;
		p_coeffs = mdl.Coefficients.Estimate;
		mdlplot = 10.^(p_coeffs(2)*log10(x_fit) + p_coeffs(1));
		plot(x_fit/1000, mdlplot, 'k', 'linewidth', linewidth);
		
		xlabel('CF (kHz)')
		ylabel('Q')
		ylim([0.35 50])
		xlim([0.3 10])
		set(gca, 'XScale', 'log', 'YScale', 'log', 'fontsize', fontsize)
		xticks([0 200 500 1000 2000 5000 10000]/1000)
		yticks([0.2 0.5 1 2 5 10 20 50 100 200 500 1000 2000])
		grid on
        
		number = Qs(~isnan(Qs));
		msg = ['n=' num2str(length(number))];
		text(0.05, 0.95, msg, 'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', legsize)
	end
end

%% Evaluation across low/med/high CF populations
CFgroup = {'Low', 'Med', 'High'};
Q_mean = zeros(3, 4);
Q_sem = zeros(3, 4);

for iCF = 1:3
	for ispl = 1:4
		islevel = tables.SPL == spls(ispl);
		isCFgroup = strcmp(CFgroup{iCF}, tables.CF_Group);
		index = islevel & isbin & is200 & isCFgroup;
		Qs = tables.Q(index);
		Q_mean(iCF, ispl) = mean(Qs, 'omitnan');
		Q_sem(iCF, ispl) = std(Qs, 'omitnan') / sqrt(sum(~isnan(Qs)));
	end
end

h(11) = subplot(4, 3, 11);
errorbar(Q_mean', Q_sem', 'LineWidth', linewidth)
xlabel('Level (dB SPL)')
xlim([0.5 4.5])
xticks(1:4)
xticklabels([43, 63, 73, 83])
ylabel('Q')
ylim([0 12])
hleg = legend('Low CF', 'Med CF', 'High CF', 'Location', 'best', ...
	'fontsize', legsize, 'position', [0.4824, 0.1757, 0.1261, 0.0601]);
hleg.ItemTokenSize = [8, 8];
hleg.Box = 'off';
set(gca, 'fontsize', fontsize)
grid on
box off

%% Stacked Percentiles mapping tuning tracking profiles
vals = zeros(3, 3);
for ii = 1:3
	if ii == 1
		values = increase;
	elseif ii == 2
		values = same;
	else
		values = decrease;
	end
	vals(ii, 1) = sum(strcmp(CF_group(values), 'Low'));
	vals(ii, 2) = sum(strcmp(CF_group(values), 'Med'));
	vals(ii, 3) = sum(strcmp(CF_group(values), 'High'));
end

vals = vals'; 
vals = vals ./ sum(vals, 2); % Standardize rows to reach sum of 1.0 (100%)

h(12) = subplot(4, 3, 12);
bh = bar(vals * 100, 'stacked');
hleg = legend('Sharpen', 'No change', 'Broaden', 'box', 'off');
hleg.ItemTokenSize = [8, 8];
hleg.Position = [0.7257, 0.1779, 0.2023, 0.0637];
ylabel('%')
xlabel('CF Group')
xticklabels({'Low', 'Med', 'High'})

bh(1).FaceColor = '#1b9e77';   
bh(2).FaceColor = '#d95f02'; 
bh(3).FaceColor = '#7570b3'; 
box off
ylim([0 100])
yticks(0:20:100)
set(gca, 'fontsize', fontsize)

%% Programmatic Layout Coordination Shift
left = [0.12 0.42 0.74]; 
bottom = [0.05 0.32 0.57 0.81];
height = 0.155;
width = 0.25;

left_rep = repmat(left, 1, 4);
bottom_rep = fliplr(reshape(repmat(bottom, 3, 1), 1, 12));

for ii = 1:9
	set(h(ii), 'Position', [left_rep(ii) bottom_rep(ii) width height])
end

left_axis = linspace(0.1, 0.75, 3);
left_axis_rep = repmat(left_axis, 1, 4);
width_axis = 0.23;
height_axis = 0.18;

for ii = 10:11
	set(h(ii), 'Position', [left_axis_rep(ii) bottom_rep(ii) width_axis height_axis])
end
set(h(12), 'Position', [left_axis_rep(12) bottom_rep(12) width_axis 0.12])

%% Subplot Title Labels and Multi-Panel Arrows
titles_y = {'Broadening', 'No Change', 'Sharpening'};
locs = linspace(0.46, 0.95, 3);
for ii = 1:3
	annotation('textbox', [0.45, locs(ii), 0.17, 0.0459], 'String', titles_y{ii}, ...
		'FontSize', titlesize, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

annot_bottom = linspace(0.225, 0.96, 4);
annot_left = linspace(0, 0.7, 3);

annotation('textbox', [0, annot_bottom(4), 0.0826, 0.0385], 'String', {'A'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
annotation('textbox', [0, annot_bottom(3), 0.0826, 0.0385], 'String', {'B'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
annotation('textbox', [0, annot_bottom(2), 0.0826, 0.0385], 'String', {'C'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
annotation('textbox', [0, annot_bottom(1), 0.0826, 0.0385], 'String', {'D'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
annotation('textbox', [annot_left(2), annot_bottom(1), 0.0826, 0.0385], 'String', {'E'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');
annotation('textbox', [annot_left(3), annot_bottom(1), 0.0826, 0.0385], 'String', {'F'}, 'FontWeight', 'bold', 'FontSize', labelsize, 'EdgeColor', 'none');

annotation("arrow", [0.2174, 0.2174], [0.9583, 0.9392], 'HeadStyle', 'plain', 'HeadLength', 3, 'HeadWidth', 3)
annotation("arrow", [0.2690, 0.2690], [0.8490, 0.8715], 'HeadStyle', 'plain', 'HeadLength', 3, 'HeadWidth', 3)
annotation("arrow", [0.5685, 0.5685], [0.7205, 0.7014], 'HeadStyle', 'plain', 'HeadLength', 3, 'HeadWidth', 3)
annotation("arrow", [0.5366, 0.5365], [0.7083, 0.6875], 'HeadStyle', 'plain', 'HeadLength', 3, 'HeadWidth', 3)

%% Save Figure
if save_fig == 1
    filename = 'fig7_changes_over_level';
	save_figure(filename)
end
end
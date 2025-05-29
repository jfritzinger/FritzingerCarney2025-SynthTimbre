function fig8_plot_thresholds(save_fig)
%% Load in data

[base, datapath, ~, ppi] = get_paths();
tables = readtable(fullfile(datapath, "peak_picking_w_thresholds.xlsx"));

spreadsheet_name = 'Data_Table.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);


%% Set up figure

figure('Position',[50,50,4.567*ppi,3*ppi])
%data_colors = {'#03882F', '#82BB95'};
data_colors = {'#000000'};
legsize = 6;
fontsize = 7;
titlesize = 8;
linewidth = 1;
labelsize = 13;
scattersize = 10;
capsize = 2;

%% Example unit

examples = {'R24_TT2_P13_N05', 'R27_TT2_P8_N02', 'R27_TT2_P8_N05', ...
	'R25_TT2_P9_N01', 'R27_TT3_P1_N08', 'R27_TT2_P7_N01', ...
	'R29_TT4_P5_N15', 'R25_TT2_P8_N02', 'R29_TT1_P3_N05'};
ineuron = 1;
h(1) = subplot(2, 9, [1 2 3]);

% Load in data
putative = examples{ineuron};
filename = sprintf('%s.mat', putative);
load(fullfile(datapath,'neural_data', filename), 'data');
index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
CF = sessions.CF(index);
MTF_shape = sessions.MTF{index};

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
rlb = data_ST.rlb;
rub = data_ST.rub;
fpeaks = data_ST.fpeaks;
spl = data_ST.spl;
rate_sm = data_ST.rates_sm;
max_rate = max(rate);

% Plot
fpeaks_re_CF = log2(fpeaks/CF);
hold on
rates_sm = smooth_rates(rate, rlb, rub, CF);
errorbar(fpeaks./1000, rate, rate_std/sqrt(params{1}.nrep), ...
	'linestyle', 'none', 'linewidth', 0.8, 'color', data_colors{1}, ...
	'CapSize',capsize)
plot(fpeaks./1000, rate, 'LineWidth',linewidth, 'Color',data_colors{1})
xline(CF/1000, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
yline(spont, 'color', [0.5 0.5 0.5], LineWidth=linewidth)

% Figure parameters
plot_range = [params{1}.fpeaks(1) params{1}.fpeaks(end)]./1000;
set(gca, 'Fontsize', fontsize)
xlim(plot_range);
grid on
ylim([0 max_rate+5])
ylabel('Avg. Rate (sp/s)')
xlabel('Spectral Peak Freq. (Hz)')
xlim([0.4 2.4])
%title('Example Unit with Threshold')

[threshold_percent, threshold_freq, slope_rate] = calculateThresholds(fpeaks, rate, rate_std, CF);
plot(threshold_freq/1000, slope_rate, 'r', 'LineWidth',1.5)
xline(threshold_freq(1)/1000, 'r')
xline(threshold_freq(2)/1000, 'r')

% Annotate
msg = sprintf('Thresh. = %0.02f%%', threshold_percent);
text(0.6, 0.95, msg, 'Units', 'normalized', ...
	'VerticalAlignment', 'top', 'FontSize',legsize)

%% Plot histogram

% Get data
spls = [43, 63, 73, 83];
is200 = tables.F0==200;
isbin = tables.binmode == 2;
islevel = tables.SPL == spls(2);
index = islevel & isbin & is200; % & isMTF;

% Data
thresholds = tables.Threshold(index);

% Plot
h(2) = subplot(2, 9, [4 5 6]);
%edges = linspace(0, 30, 16);
edges = linspace(0, 30, 31);

histogram(thresholds, edges, 'EdgeColor','k', 'FaceColor',[0.4 0.4 0.4])
xlabel('Threshold (%)')
ylabel('# Neurons')
set(gca, 'fontsize', fontsize)
%title('Histogram of Thresholds')
hold on
xline(4, 'r', 'LineWidth',linewidth)
xlim([0 30])
ylim([0 22])
box off
grid on

% Percent <4% threshold
percent = sum(thresholds<=4)/length(thresholds)*100;
hleg = legend('Neural', 'Human', 'box', 'off');
hleg.ItemTokenSize = [8,8];

%% Plot scatter of thresholds vs CF

% Get minimum thresholds
% CFs_array = linspace(200, 10000, 100);
% min_threshold = 35./CFs_array*100;

% Set up figure
h(3) = subplot(2, 9, [7 8 9]);
spls = [43, 63, 73, 83];
is200 = tables.F0==200;
isMTF = strcmp(tables.MTF, 'BE') | strcmp(tables.MTF, 'BS');

for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		CFs = tables.CF(index);
		Qs = tables.Threshold(index);
		MTFs = tables.MTF(index);
		peaks = tables.Type(index);

		% Add in units without thresholds
		Qs(isnan(Qs)) = 50;
		Qs(Qs>50) = 50;

		% Plot
		%gfig = gscatter(CFs/1000, Qs,peaks, 'filled');
		%set(gfig, 'MarkerEdgeColor', 'k');
		scatter(CFs/1000, Qs, scattersize, 'filled', 'MarkerEdgeColor','k', ...
			'MarkerFaceColor','k', 'MarkerFaceAlpha',0.5)
		hold on

		% Plot minimum thresholds based on stimuli
		%plot(CFs_array/1000, min_threshold, 'r', 'LineWidth',2)

		% Plot human threshold
		scatter(1200/1000, 4,scattersize, 'r', 'filled','markeredgecolor', 'k') %'filled')
		yline(4, 'r')

		% Plot labels
		number = Qs;
		number(isnan(number)) = [];
		%title('Thresholds vs CF')
		xlabel('CF (kHz)')
		if ispl == 1
			ylabel('Q')
		end
		ylim([0.35 50])
		xlim([0.3 10])
		set(gca, 'fontsize', fontsize)
		set(gca, 'XScale', 'log')
		set(gca, 'YScale', 'log')
		ylabel('Threshold (%)')
		xticks([0 200 500 1000 2000 5000 10000]/1000)
		yticks([0.2 0.5 1 2 5 10 20 50 70])
		yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
		grid on
		box off
		hleg = legend('Neural','Human', '', 'Location','southwest', 'box',...
			'off', 'position', [0.7705,0.5902,0.1200,0.0902]);
		hleg.ItemTokenSize = [8, 8];
	end
end

%% Thresholds over level

% Get minimum thresholds
% CFs_array = linspace(200, 10000, 100);
% min_threshold = 35./CFs_array*100;


% Set up figure
data_colors = {'#000000', '#737373', '#bdbdbd'};
h(4) = subplot(2, 9, [10 11 12]);
spls = [43, 63, 73, 83];
is200 = tables.F0==200;
isMTF = strcmp(tables.MTF, 'BE') | strcmp(tables.MTF, 'BS');
all_thresholds = NaN(4, 163);
for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = [1, 2, 4]

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		CFs = tables.CF(index);
		thresh = tables.Threshold(index);
		MTFs = tables.MTF(index);
		peaks = tables.Type(index);

		% Add in units without thresholds
		thresh(isnan(thresh)) = 100;
		thresh2 = thresh;
		thresh2(isoutlier(thresh2)) = [];

		% Put into arrays

		if ispl == 4
			all_thresholds(3,1:length(thresh)) = thresh;
			hold on
			swarmchart(ones(length(thresh2), 1)*3, thresh2, scattersize)
		else
			all_thresholds(ispl,1:length(thresh)) = thresh;
			hold on
			swarmchart(ones(length(thresh2), 1)*ispl, thresh2, scattersize)
		end

	end
end

boxplot(all_thresholds', 'OutlierSize',2)
ylim([0 50])
xlim([0.4 3.6])
ylabel('Threshold (%)')
xlabel('Level (dB SPL)')
xticklabels([43, 63, 83])
set(gca, 'fontsize', fontsize, 'yscale', 'log')
yticks([0.2 0.5 1 2 5 10 20 50 70])
yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
box off

% Kruskal Wallis for non normal data
% kruskalwallis(all_thresholds')
% [p, tbl, stats] = kruskalwallis(all_thresholds', 1:4);
% multcompare(stats, 'CType', 'dunn-sidak');

%%

% Find sessions for target synthetic timbre response
all_neurons = tables.Putative;
neurons = unique(all_neurons);
num_units = size(neurons, 1);
isbin = tables.binmode == 2;
is200 = tables.F0 == 200;

SPLs = [43, 63, 73, 83];
qs = NaN(num_units, 4);
for isesh = 1:num_units

	putative = neurons{isesh};
	isput = cellfun(@(s) strcmp(s, putative), tables.Putative);

	for ispl = 1:4
		ind = isput & isbin & is200 & tables.SPL==SPLs(ispl);
		if any(ind)
			qs(isesh, ispl) = tables.Threshold(ind);
			CF_group(isesh) = tables.CF_Group(ind);
		end
	end
end

% Get matrix of units with 43, 63, 83 dB
qs2 = qs(:,[1,2,4]);
rows_with_nan = any(isnan(qs2),2);
qs2(rows_with_nan,:) = [];
x = [43, 63, 83];

% Criteria using slope
for ii = 1:length(qs2)
	y = qs2(ii, :)';
	tbl = table(x', y, 'VariableNames', {'X', 'Q'});
	mdl = fitlm(tbl, 'Q ~ X');
	slopes(ii) = mdl.Coefficients.Estimate(2); % slope
end
criteria = 0.03;
same = slopes<criteria & slopes > -1*criteria;
decrease = slopes<-1*criteria;
increase = slopes>criteria;
spls = [43, 63, 83];


indices = [5, 6, 7];
placement = [13, 14; 15, 16; 17, 18];
for ii = 1:3
	if ii == 1
		values = increase;
		color = [27,158,119]/256;
	elseif ii == 2
		values = same;
		color = [217,95,2]/256;
	else
		values = decrease;
		color = [117,112,179]/256;
	end

	% Increase
	h(indices(ii)) = subplot(2, 9, placement(ii, 1:2));
	hold on
	plot(spls, qs2(values,:)', 'color',color , 'LineWidth',0.8)
	xticks(spls)

	xlim([37 89])
	plot(spls, mean(qs2(values,:), 'omitnan'), 'k', 'LineWidth',linewidth)
	plot(spls, median(qs2(values,:), 'omitnan'), ':k', 'LineWidth',linewidth)
	set(gca, 'fontsize', fontsize)
	if ii == 2
		xlabel('Level (dB SPL)')
	end

	label = ['n=' num2str(sum(values))];
	if ii == 1
		text(0.2, 0.95, label, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',fontsize)
	elseif ii == 2
		text(0.05, 0.95, label, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',fontsize)
	else
		text(0.65, 0.95, label, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',fontsize)
	end
	if ii == 2
		hLeg = legend;
		num_lines = size(hLeg.String,2);
		for iii = 1:num_lines
			if iii==num_lines
				leg{iii} = 'Mean';
			elseif iii == num_lines-1
				leg{iii} = 'Median';
			else
				leg{iii} = '';
			end
		end
		hLeg = legend(leg, 'FontSize',legsize, 'Position',...
			[0.615488504784518,0.289351851851852,0.139817629179331,0.085648148148148]);
		hLeg.ItemTokenSize = [15,6];
		hLeg.Box = 'off';
	end
	ylim([0 40])
	if ii == 1
		ylabel('Threshold (%)')
	else
		yticklabels([])
	end

	% % Kruskal Wallis for non normal data, increasing
	% kruskalwallis(qs2(values,:))
	% [p, tbl, stats] = kruskalwallis(qs2(values,:), 1:3);
	% multcompare(stats, 'CType', 'dunn-sidak');
end



%% Arrange and annotate

left = linspace(0.1, 0.77, 3);
width = 0.2;
height = 0.34;
for ii = 1:3
	set(h(ii), 'Position', [left(ii) 0.59 width height])
end
set(h(4), 'Position', [left(1) 0.09 width height])
width2 = 0.18;
left2 = linspace(left(2), left(3)+width-width2, 3);
set(h(5), 'Position', [left2(1) 0.09 width2 height])
set(h(6), 'Position', [left2(2) 0.09 width2 height])
set(h(7), 'Position', [left2(3) 0.09 width2 height])


% Set annotations
left = linspace(0.01, 0.68, 3);
annotation('textbox',[left(1) 0.95 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) 0.95 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3) 0.95 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(1) 0.45 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) 0.45 0.0826 0.0385],'String',{'E'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure
if save_fig == 1
	filename = 'fig8_plot_thresholds';
	save_figure(filename)
end
end

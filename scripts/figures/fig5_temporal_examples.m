function fig5_temporal_examples(save_fig)
% FIG5_PLOT_TEMPORAL_EXAMPLES Generates Figure 5 illustrating temporal phase-locking patterns.
%
% PURPOSE:
%   This function visualizes single-unit temporal dynamics across a variety of 
%   auditory neurons. It constructs multi-panel period histogram heatmaps (pcolor) 
%   mapping time-within-period against spectral peak frequencies, plots phase-locking 
%   strength via Vector Strength (VS) profiles relative to characteristic frequency (CF), 
%   and summarizes dataset distributions (Peak, Dip, Flat classifications) using a bar chart.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a complex 5x5 multi-panel heatmap and quantification plot. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - analyzeST_Temporal()      : Computes period histograms and temporal metrics
%   - smooth_rates()            : Smooths physiological vector tracks relative to CF
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up (Original framework dated for 2025 manuscript)

%% Load in spreadsheet

[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), ...
	'PreserveVariableNames',true);

%% Load in example

figure('Position',[50,50,6.6*ppi,4.8*ppi])
tiledlayout(4, 5, "TileSpacing","compact", 'TileIndexing','columnmajor')
h = gobjects(20, 1);
legsize = 6;
fontsize = 7;
labelsize = 13;

%%
ind = [1, 6, 11, 16, 2, 7, 12, 17, 3, 8, 13, 18, 4, 9, 14, 19, 5, ...
	10, 15, 20]+5;
fpeaks_re_CF = cell(20, 1);
VS = cell(20, 1);
for ii = 1:20

	switch ii
		case 1
			putative = 'R25_TT1_P8_N01'; % blurred at CF
		case 2
			putative = 'R25_TT1_P8_N02'; % blurred at CF
		case 3
			putative = 'R25_TT4_P7_N01'; % blurred at CF
		case 4
			putative = 'R29_TT4_P2_N03'; % blurred at CF
		case 5
			putative = 'R29_TT4_P2_N09'; % 2 peaks
		case 6
			putative = 'R29_TT1_P3_N02'; % 2 peaks
		case 7
			putative = 'R29_TT4_P2_N10'; % 2 peaks
		case 8
			putative = 'R29_TT1_P3_N05';
		case 9
			putative = 'R25_TT1_P8_N15'; %'R25_TT1_P8_N03'; % 2 peaks, odd
		case 10
			putative = 'R29_TT1_P2_N03'; % 2 peaks, odd
		case 11
			putative = 'R25_TT1_P8_N04'; %'R29_TT4_P2_N16'; % 2 peaks, odd
		case 12
			putative = 'R25_TT2_P9_N02'; % % 2 peaks, odd
		case 13
			putative = 'R29_TT4_P3_N04'; % multiple
		case 14
			putative = 'R29_TT3_P2_N05'; % multiple
		case 15
			putative = 'R29_TT3_P2_N04'; % multiple
		case 16
			putative = 'R25_TT3_P8_N06'; % multiple
		case 17
			putative = 'R29_TT4_P5_N02'; %'R24_TT1_P12_N01';
		case 18
			putative = 'R29_TT3_P5_N03'; % rate only
		case 19
			putative = 'R27_TT4_P8_N10';
		case 20
			putative = 'R27_TT2_P8_N05';
	end
	filename = sprintf('%s.mat', putative);
	load(fullfile(datapath,'neural_data', filename), 'data');
	index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
	CF = sessions.CF(index);

	%% Analysis

	% Synthetic timbre analysis
	params = data(7, 2);
	params = params(~cellfun(@isempty, params));
	data_ST  = analyzeST(params, CF);
	data_ST = data_ST{1};
	param = params{1};
	temporal = analyzeST_Temporal(param, data_ST);

	% Vector strength calculation
	fpeaks_re_CF{ii} = log2(param.fpeaks/CF);
	num_fpeaks = length(param.fpeaks);
	VS_smooth = smooth_rates(temporal.VS,zeros(num_fpeaks, 1),...
	 	ones(num_fpeaks, 1), CF);
	VS{ii} = VS_smooth;

	%% Plot

	% Plot as heatmap
	p_hist = temporal.p_hist;
	t = linspace(0, 5, size(p_hist,2));
	grayMap = [linspace(0, 1, 256)', linspace(0, 1, 256)',...
		linspace(0, 1, 256)'];
	grayMap = flipud(grayMap);

	h(ind(ii)) = subplot(5, 5, ind(ii));
	hh = pcolor(t, data_ST.fpeaks./1000, p_hist);
	set(hh, 'EdgeColor', 'none');
	hold on
	yline(CF/1000, 'r', 'LineWidth',2)

    % Plot harmonics 
    if ii == 5
        response = 1.379;
        xline(response, 'g')
        harm2_period = 1/400*1000;
        xline(response + harm2_period, 'g')
    elseif ii == 13
        response = 0.25;
        xline(response, 'g')
        harm4_period = 1/800*1000;
        xline(response + harm4_period, 'g')
    end

	%colorbar;
	%axis square;
	colormap(grayMap);
	xlim([0 5])
	max_rate = max(p_hist, [], "all");
	clim([0 max_rate-max_rate*0.3])
	if ismember(ii, 3)
		ylabel('                                Spectral Peak Freq. (Hz)')
	end
	xticks(0:5)
	if ismember(ii, 12)
		xlabel('Time within Period (ms)')
    elseif ismember(ii, [4, 8, 16, 20])
        xticks(0:5)
	else
		xticklabels([])
	end
	box off

	set(gca, 'fontsize', fontsize)
	if ii == 17
		hleg = legend('', 'CF', 'Location','northwest', 'fontsize', ...
			legsize, 'box', 'off');
		hleg.ItemTokenSize = [8, 8];
	end

	msg = sprintf('%d sp/s', max_rate);
	text(0.58, 1.12, msg, 'Units', 'normalized', ...
		'VerticalAlignment', 'top', 'FontSize',legsize, 'Color','r')


end

%% Plot vector strengths (then add back in later)

%index = [1:4; 5:8; 9:12; 13:16; 17:20];
index = [1, 5, 9, 13]';
for ineuron = 1:4

	% Plot
	h(ineuron) = subplot(5, 5, ineuron);
	hold on
	for ii = 1 %:4
		fpeaks_temp = fpeaks_re_CF{index(ineuron, ii)};
		VS_temp = VS{index(ineuron, ii)};
		plot(fpeaks_temp, VS_temp, 'k')
	end
	xline(0)
	xlim([-0.5 0.5])
	ylim([0 1])
	if ineuron == 3
		xlabel('Spec. Peak Freq. w.r.t. CF (oct)                                ')
	end
	if ineuron == 1
		ylabel('VS')
	end
	set(gca, 'fontsize', fontsize)
end

% Load in spreadsheet with peak information
spreadsheet_name = 'peak_picking_VS.xlsx';
table = readtable(fullfile(datapath, spreadsheet_name));
h(5) = subplot(5, 5, 5);
spl = [43, 63, 73, 83];
isBin = table.binmode == 2;
for ispl = 2
	isSPL = table.SPL == spl(ispl);
	index = isSPL  & isBin;

	num_dip = sum(cellfun(@(s) strcmp(s, 'Dip'), table.Type(index)));
	num_peak = sum(cellfun(@(s) strcmp(s, 'Peak'), table.Type(index)));
	num_flat = sum(cellfun(@(s) strcmp(s, 'Flat'), table.Type(index)));

	percent_peak = num_peak;
	percent_dip = num_dip;
	percent_flat = num_flat;
	percent_all = [percent_peak; percent_dip; percent_flat]';

	bar(percent_all, 'FaceColor','k')
	xticklabels({'Peak', 'Dip', 'Flat'})
	ylabel('# Neurons')
	ylim([0 150])
	set(gca, 'fontsize', fontsize)
end
box off 

%% Set positions

height = 0.15;
width = 0.14;
bottom = [0.845 0.605 0.4233 0.241 0.06];
left = linspace(0.07, 0.85, 5);

left = repmat(left, 1, 5);
bottom = reshape(repmat(bottom, 5, 1), 1, []);

for ii = 1:25
	if ismember(ii, 1:4)
		set(h(ii), 'Position', [left(ii) bottom(ii) width 0.12])
	elseif ii == 5
		set(h(ii), 'Position', [left(ii)+0.02 bottom(ii) 0.12 0.12])
	else
		set(h(ii), 'Position', [left(ii) bottom(ii) width height])
	end
end

% Annotations
left = linspace(0.02, 0.8, 5);

annotation('textbox',[left(1) 0.965 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(5) 0.965 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(1) 0.75 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) 0.75 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3) 0.75 0.0826 0.0385],'String',{'E'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(4) 0.75 0.0826 0.0385],'String',{'F'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(5) 0.75 0.0826 0.0385],'String',{'G'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure 

if save_fig == 1
    filename = 'fig5_temporal_examples';
	save_figure(filename)
end

end
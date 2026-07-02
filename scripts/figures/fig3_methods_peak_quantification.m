function fig3_methods_peak_quantification(save_fig)
% FIG3_METHODS_PEAK_QUANTIFICATION Generates Figure 3 demonstrating feature classification.
%
% PURPOSE:
%   This function visualizes the classification and quantification of neural response 
%   profiles into "Peak", "Dip", or "Sloping" categories from real physiology data. 
%   It plots z-scored firing rates against spectral peak frequencies, highlights the 
%   Region of Interest (ROI), applies a peak-finding algorithm, and extracts metrics 
%   like prominence windows and half-height bandwidths for manuscript methodology.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a formatted 3-panel comparative methodology plot. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - peakFinding()             : Algorithmic categorization of peaks, dips, and proms
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up

%% Load in spreadsheet 

[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);


%% Set up figure 

figure('Position',[50,50,6*ppi,1.6*ppi])
h = gobjects(3, 1);
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;
scattersize = 18;
capsize = 2;

%% Peak/Dip/Sloping Examples 
 
examples = {'R25_TT3_P9_N01', 'R27_TT3_P1_N08', 'R29_TT1_P2_N04'};
CF_color = [0.3 0.3 0.3];

for ineuron = 1:3

	% Load in examples
	putative = examples{ineuron};
	filename = sprintf('%s.mat', putative);
	load(fullfile(datapath,'neural_data', filename), 'data');
	index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
	CF = sessions.CF(index);
    
	% Analysis
	param_ST = data(7, 2);
	data_ST = analyzeST(param_ST, CF);
	data_ST = data_ST{1};

	% Z-score
	rate = zscore(data_ST.rate);
	rate_sm = zscore(data_ST.rates_sm);

	% Cut down to +/- one octave range
	hi_limit = CF*2;
	lo_limit = CF/2;
	
	% Calculate the peak/dip/flat
	[peaks, dips, ~, ~, ~, ~, bounds_freq, halfheight] = peakFinding(data_ST, CF, 'Rate', []);

	% Plots
	h(ineuron) = subplot(2, 3, ineuron);
	patch([lo_limit lo_limit hi_limit hi_limit]./1000,[-4 4 4 -4], 'r', 'FaceAlpha',0.05, 'EdgeColor', 'none');
	hold on
	plot(data_ST.fpeaks./1000,rate, 'linewidth', 0.9, 'Color',"#0072BD");
	errorbar(data_ST.fpeaks./1000,rate, zscore(data_ST.rate_std)/sqrt(30),...
		'linewidth', 0.9, 'Color','k', 'CapSize',capsize); %"#0072BD");
	plot(data_ST.fpeaks./1000,rate_sm, 'linewidth', linewidth,'Color','k');
	ylim([-4 4])

	scatter(peaks.locs./1000, peaks.pks,scattersize,  'filled', 'r')
	scatter(dips.locs./1000, -1*dips.pks, scattersize, 'filled', 'r')
	if ineuron == 1
		line([bounds_freq(1)/1000, bounds_freq(2)/1000], [halfheight, halfheight], 'Color', 'g', 'LineWidth', linewidth);
		line([peaks.locs peaks.locs]./1000, [peaks.pks-0.75 peaks.pks], 'Color', 'r', 'LineWidth', linewidth);
		xline(CF./1000, '--', 'Color',CF_color, 'linewidth', linewidth)
		hleg = legend('ROI', '', 'Data', 'Smoothed', 'Ref. Value', '', 'Bandwidth', ...
 			'+/- 0.75', 'CF', 'Location','northeastoutside');
		hleg.ItemTokenSize = [12, 8];
	elseif ineuron == 2
		line([dips.locs dips.locs]./1000, -1*[dips.pks-0.75 dips.pks], 'Color', 'r', 'LineWidth', linewidth);
		line([bounds_freq(1)/1000, bounds_freq(2)/1000], [halfheight, halfheight], 'Color', 'g', 'LineWidth', linewidth);
		xline(CF./1000, '--', 'Color',CF_color, 'linewidth', linewidth)
	else
		xline(CF./1000, '--', 'Color',CF_color, 'linewidth', linewidth)
	end

	plot_range = [param_ST{1}.fpeaks(1) param_ST{1}.fpeaks(end)]./1000;
	
	xlim(plot_range)
	set(gca, 'fontsize', fontsize)
	if ineuron == 1
		ylabel('Z-score')
		title('Peak', 'fontsize', titlesize)
	elseif ineuron == 2
		yticklabels([])
		title('Dip', 'fontsize', titlesize)
		xlabel('Spectral Peak Freq. (kHz)')
	else 
		yticklabels([])
		title('Sloping', 'fontsize', titlesize)
	end
	grid on
end

%% Arrange and annotate 

left = repmat(linspace(0.07, 0.6, 3), 1, 2);
bottom = 0.17;
height = 0.7;

for ii = 1:3
	set(h(ii), 'position', [left(ii) bottom 0.21 height])
end
set(hleg, 'Position', [0.844510314761978,0.461977186311787,0.125,0.41254752851711])

% Add labels 
annotation('textbox',[left(1)-0.06 0.95 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2)-0.04 0.95 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3)-0.04 0.95 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure 

if save_fig == 1
    filename = 'fig3_methods_peak_quantification';
	save_figure(filename)
end

end
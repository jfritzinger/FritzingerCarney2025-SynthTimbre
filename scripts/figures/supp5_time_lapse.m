function supp5_time_lapse(save_fig)
% FIG_S4_TIME_LAPSE_RESULTS Generates Supplementary Figure S4 evaluating receptive field temporal changes.
%
% PURPOSE:
%   This function quantifies temporal modifications in neural frequency resolution over time
%   by partitioning responses into transient (50–150 ms) versus steady-state (200–300 ms) windows. 
%   It traces single-unit firing rate tracking examples undergoing sharpening, broadening, or 
%   stable tuning configurations, and contextualizes these trajectories against population metrics 
%   categorized by stimulus pressure level and baseline classification shape (BE, BS, Hybrid, Flat).
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a 3x3 multi-panel time-lapse tracking summary. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeRM()               : Analyzes Response Area / Rate-Intensity Matrix data
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - analyzeSTWindow()         : Sections spikes into discrete temporal analysis bins
%   - peakFinding()             : Extracts bandwidth parameters and centers from rate profiles
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up (Original framework dated for 2025 manuscript)

%% Load in spreadsheet

[~, datapath, ~, ppi] = get_paths();
tables = readtable(fullfile(datapath,"time_lapse.xlsx"));
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);

%% Set up figure

figure('position', [519,299,9*ppi,7*ppi])
h = gobjects(9, 1);
fontsize = 12;
legsize = 8;
labelsize = 24;
titlesize = 16;

%% 3 Examples
CF_color = [0.4 0.4 0.4];
sub_index = [1 4 7];
for ineuron = 1:3

	switch ineuron
		case 1 % Sharpening
			putative = 'R27_TT3_P8_N01';
		case 2 % No change
			putative = 'R24_TT2_P13_N05';
		case 3 % Broadening
			putative = 'R27_TT2_P8_N05';
	end
	ispl = 2;

	% Load in data
	filename = sprintf('%s.mat', putative);
	load(fullfile(datapath,'neural_data', filename), 'data');
	index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
	CF = sessions.CF(index);

	param_ST = data(5+ispl, 2);
	data_ST = analyzeST(param_ST, CF);
	data_ST = data_ST{1};

	% Analyze by cutting into two sections, 50-150, 200-300ms
	[rate, rates_sm, rate_std] = analyzeSTWindow(param_ST, CF);

	% Calculate Q for each section
	win1_ST.rates_sm = rates_sm(1,:);
	win1_ST.fpeaks = data_ST.fpeaks;
	[~, ~, ~, ~, width, ~, ~,~, freq] = peakFinding(win1_ST, CF, 'Rate', param_ST);
	Q(1) = freq/width;
	win2_ST.rates_sm = rates_sm(2,:);
	win2_ST.fpeaks = data_ST.fpeaks;
	[~, ~, ~, ~, width, ~, ~, ~, freq] = peakFinding(win2_ST, CF, 'Rate', param_ST);
	Q(2) = freq/width;

	% Plot rates!
	h(sub_index(ineuron)) = subplot(3, 3, sub_index(ineuron));
	hold on
	errorbar(data_ST.fpeaks,rate(1,:), rate_std(1,:)/sqrt(30), ...
		'LineStyle','none', 'Color',"#0072BD");
	plot(data_ST.fpeaks,rates_sm(1,:), 'linewidth', 1.5, 'Color',"#0072BD");
	errorbar(data_ST.fpeaks,rate(2,:), rate_std(2,:)/sqrt(30), ...
		'LineStyle','none', 'Color',"#D95319");
	plot(data_ST.fpeaks,rates_sm(2,:), 'linewidth', 1.5, 'Color',"#D95319");
	%legend('50-150 ms', '', '200-300 ms', '', 'Location','best')

	plot_range = [param_ST{1}.fpeaks(1) param_ST{1}.fpeaks(end)];
	xline(CF, '--', 'Color',CF_color, 'linewidth', 1.5)
	xlim(plot_range)
	xlabel('Frequency (Hz)')
	ylabel('Avg. Rate (sp/s)')
	box on
	grid on
	set(gca, 'fontsize', fontsize)

	hLeg = legend('', sprintf('50-100 ms, Q=%0.1f', Q(1)), '',...
		sprintf('200-300 ms, Q=%0.1f', Q(2)));
	hLeg.ItemTokenSize = [6,6];
	hLeg.FontSize = legsize;
	hLeg.Box = 'off';
	hLeg.Location = "best";
	box off
end


%% How many change 

linewidth = 1;

islevel = tables.SPL == 63;
qs2 = [tables.Q1(islevel) tables.Q2(islevel)];
rows_with_nan = any(isnan(qs2),2);
qs2(rows_with_nan,:) = [];

index = [2, 5, 8];
diff_Q = qs2(:,2) - qs2(:,1);
criteria = 1;
same = diff_Q<criteria & diff_Q > -1*diff_Q;
decrease = diff_Q<-1*criteria;
increase = diff_Q>criteria;
win = 1:2;
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
	h(index(ii)) = subplot(3, 3, index(ii));
	hold on
	plot(win, qs2(values,:)', 'color',color , 'LineWidth',linewidth)
	xticks(win)
	ylabel('Q')
	xlim([0.8 2.2])
	xticks(1:2)
	xticklabels({'50-150', '200-300'})
	plot(win, mean(qs2(values,:), 'omitnan'), 'k', 'LineWidth',2)
	plot(win, median(qs2(values,:), 'omitnan'), ':k', 'LineWidth',2)
	set(gca, 'fontsize', fontsize)
	xlabel('Window (ms)')

	label = ['n=' num2str(sum(values))];
	text(0.05, 0.95, label, 'Units', 'normalized', ...
		'VerticalAlignment', 'top', 'FontSize',fontsize)
	ylim([0 20])

end


%% Analyze and plot 

islevel = tables.SPL == 63;
CFs = tables.CF(islevel);
isBE = strcmp(tables.MTF(islevel), 'BE');
isBS = strcmp(tables.MTF(islevel), 'BS');
qs2 = [tables.Q1(islevel) tables.Q2(islevel)];
rows_with_nan = any(isnan(qs2),2);
qs2(rows_with_nan,:) = [];
CFs(rows_with_nan,:) = [];
isBE(rows_with_nan,:) = [];
isBS(rows_with_nan,:) = [];

diff_Q = qs2(:,2) - qs2(:,1);

h(3) = subplot(3, 3, 3);
scatter(CFs(isBE)/1000, diff_Q(isBE), 18, 'filled', 'MarkerEdgeColor','k')
hold on
scatter(CFs(isBS)/1000, diff_Q(isBS), 18, 'filled', 'MarkerEdgeColor','k')
yline(0)
ylabel('Q_2_0_0 - Q_5_0')
xlabel('CF')
legend('BE', 'BS', 'Location','best')
set(gca, 'XScale','log')
xticks([0.2 0.5 1 2 5 10])
ylim([-6.2 10])
grid on

%% Q changes with level & window 
clear Q 

spls = [43, 63, 73, 83];
isbin = tables.binmode == 2; % | tables.binmode == 1;
Q = zeros(2, 4);
Q_sem = zeros(2, 4);
for ispl = 1:4

	% Get data
	islevel = tables.SPL == spls(ispl);
	index = islevel & isbin;

	% Data
	Q1 = tables.Q1(index);
	Q2 = tables.Q2(index);
	Q(:, ispl) = [mean(Q1, 'omitnan') mean(Q2, 'omitnan')];
	Q_sem(:, ispl) = [std(Q1, 'omitnan')/sqrt(length(Q1)) std(Q2, 'omitnan')/sqrt(length(Q2))];
end
h(6) = subplot(3, 3, 6);
errorbar(Q', Q_sem', 'LineWidth',2)
xlabel('Level (dB SPL)')
xlim([0.5 4.5])
xticks(1:4)
xticklabels([43, 63, 73, 83])
ylabel('Q')
ylim([0 11])
legend('50-150 ms','200-300 ms', 'Location','best')
set(gca, 'fontsize', fontsize)
grid on
box off

%% Q changes with MTF & window 

isBE = strcmp(tables.MTF, 'BE');
isBS = strcmp(tables.MTF, 'BS');
isH = contains(tables.MTF, 'H');
isF = strcmp(tables.MTF, 'F');
Q_all2 = zeros(2, 4);
Q_sem2 = zeros(2, 4);
for iwin = 1:2

	% Get data
	if iwin == 1
		tables.Q = tables.Q1;
	else
		tables.Q = tables.Q2;
	end

	% Data
	Q_all2(iwin,:) = [mean(tables.Q(isBE), 'omitnan') mean(tables.Q(isBS), 'omitnan') ...
		mean(tables.Q(isH), 'omitnan') mean(tables.Q(isF), 'omitnan')];
	Q_sem2(iwin,:) = [std(tables.Q(isBE), 'omitnan')/sqrt(length(tables.Q(isBE)))...
		std(tables.Q(isBS), 'omitnan')/sqrt(length(tables.Q(isBS)))...
		std(tables.Q(isH), 'omitnan')/sqrt(length(tables.Q(isH)))...
		std(tables.Q(isF), 'omitnan')/sqrt(length(tables.Q(isF)))];
end

% Plot
h(9) = subplot(3, 3, 9);
hold on
errorbar(Q_all2', Q_sem2', 'LineWidth',2)
xticks(1:4)
xticklabels({'BE', 'BS', 'Hybrid', 'Flat'})
xlim([0.5 4.5])
ylim([0 9])
ylabel('Q')
xlabel('MTF Type')
legend('50-150 ms','200-300 ms', 'Location','best')
set(gca, 'fontsize', fontsize)
grid on

%% Arrange plots 

left = [0.1 0.4 0.75];
bottom = [0.75 0.41 0.07];
height = 0.19;
width = 0.23;

row = reshape(repmat(1:3, 3, 1), 9, 1);
col = repmat(1:3, 1, 3);
for ii = 1:9
	irow = row(ii);
	icol = col(ii);
	set(h(ii), 'position', [left(icol) bottom(irow) width height])
end

% Annotations
x = 0.34;
annotation('textbox',[0.29 0.945 0.15 0.051],'String',{'Sharpening'},...
	'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');
annotation('textbox',[0.29 0.945-x 0.15 0.051],'String',{'No Change'},...
	'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');
annotation('textbox',[0.29 0.945-2*x 0.15 0.051],'String',{'Broadening'},...
	'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');

% Labels 
labels = {'A', 'B', 'C'};
labels2 = {'D', 'E', 'F'};
labelbottom = fliplr(linspace(0.28, 0.96, 3));
for ii = 1:3
	annotation('textbox',[0.02 labelbottom(ii) 0.071 0.044],...
		'String',labels{ii},'FontWeight','bold','FontSize',labelsize,...
		'EdgeColor','none');
	annotation('textbox',[0.69 labelbottom(ii) 0.071 0.044],...
		'String',labels2{ii},'FontWeight','bold','FontSize',labelsize,...
		'EdgeColor','none');
end

%% Save figure 

if save_fig == 1
	filename = 'fig_s5_time_lapse';
	save_figure(filename)
end

end
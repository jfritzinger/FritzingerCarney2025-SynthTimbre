function fig7_changes_over_level(save_figs)

%% Load in data

[~, datapath, ~, ppi] = get_paths();
tables = readtable(fullfile(datapath, "peak_picking_excludeflat.xlsx"));
spreadsheet_name = 'Data_Table.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), ...
	'PreserveVariableNames',true);


%% Set up figure 

figure('Position',[50,50,4.567*ppi,6*ppi])
legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;
scattersize = 12;
capsize = 2;

%% Set up and plot examples 

plot_ind = [1, 2, 4, 5, 7, 8];
leglocations = [0.241651098615259,0.909722222222222,0.133738601823708,0.060185185185185;...
	0.545604093267954,0.905092592592592,0.133738601823708,0.060185185185185;...
	0.238609958065907,0.662037037037037,0.133738601823708,0.060185185185185;...
	0.563850936564064,0.662037037037037,0.133738601823708,0.060185185185185;...
	0.247733379713962,0.414351851851852,0.133738601823708,0.060185185185185;...
	0.566892077113415,0.416666666666666,0.133738601823708,0.060185185185185];
for ineuron = 1:6

	h(plot_ind(ineuron)) = subplot(4, 3, plot_ind(ineuron));

	switch ineuron
		case 1 % Sharpening
			putative = 'R27_TT3_P7_N08';
		case 2 % Sharpening
			putative = 'R27_TT3_P7_N14';
		case 3 % No Change 
			putative = 'R29_TT4_P5_N02';
		case 4 % No Change 
			putative = 'R27_TT2_P8_N02';
			% okay: 'R24_TT2_P13_N02'; 'R24_TT2_P13_N06';
		case 5 % Broadening
			putative = 'R24_TT2_P13_N03';
		case 6 % Broadening
			putative = 'R24_TT2_P13_N05';
	end

	% Load in data
	filename = sprintf('%s.mat', putative);
	load(fullfile(datapath,'neural_data', filename), 'data');
	index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
	CF = sessions.CF(index);

	params = data([6,7,9], 2);
	params = params(~cellfun(@isempty, params));
	data_ST  = analyzeST(params, CF);

	% RM to get spont
	params_RM = data{2, 2};
	data_RM = analyzeRM(params_RM);
	spont = data_RM.spont;

	num_ds = size(data_ST, 2);
	%data_colors = {'#034E1C', '#03882F', '#82BB95'};
	data_colors = {'#000000', '#737373', '#bdbdbd'};

	% Sort
	spls = cell2mat(cellfun(@(p) p.spl, data_ST, 'UniformOutput',false));
	[~, order] = sort(spls);
	order = fliplr(order);
	max_rate = max(cellfun(@(d) max(d.rate), data_ST));
	hold on
	label_ind = 1;
	for ind = 1:num_ds

		rate = data_ST{order(ind)}.rate;
		rate_std = data_ST{order(ind)}.rate_std;
		rlb = data_ST{order(ind)}.rlb;
		rub = data_ST{order(ind)}.rub;
		fpeaks = data_ST{order(ind)}.fpeaks;
		spl = data_ST{order(ind)}.spl;
		rate_sm = data_ST{order(ind)}.rates_sm;

		% Plot
		rates_sm = smooth_rates(rate, rlb, rub, CF);
		type = 'Rate';
		errorbar(fpeaks./1000, rate, rate_std/sqrt(30), 'linestyle', ...
			'none', 'linewidth', 0.8, 'color', data_colors{ind}, 'capsize', capsize)
		%plot(fpeaks./1000, rate, 'LineWidth',linewidth, 'Color',data_colors{:,ind})
		plot(fpeaks./1000, rates_sm, 'LineWidth',linewidth, 'Color',data_colors{:,ind})
		[peaks, dips, type, prom, width, lim, ~, ~, freq] = peakFinding(...
			data_ST{order(ind)}, CF, type, []);
		Q(ind) = freq/width;
	end
	yline(spont, 'k', LineWidth=linewidth)
	plot_range = [params{1}.fpeaks(1) params{1}.fpeaks(end)]./1000;
	xline(CF./1000, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
	xlabel('Spectral Peak Freq. (kHz)')
	if ismember(ineuron, [1 3 5])
		ylabel('Avg. rate (sp/s)')
	end
	set(gca, 'Fontsize', fontsize);
	xlim(plot_range);
	grid on

	hLeg = legend('', sprintf('83, Q=%0.1f', Q(1)), '', sprintf('63, Q=%0.1f', Q(2)), ...
		'', sprintf('43, Q=%0.1f', Q(3)));
	hLeg.ItemTokenSize = [6,6];
	hLeg.FontSize = legsize;
	hLeg.Box = 'off';
	hLeg.Position = leglocations(ineuron,:);
end


%% Plot overall

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
			qs(isesh, ispl) = tables.Q(ind);
			qs_log(isesh, ispl) = tables.Q_log(ind);
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

indices = [3, 6, 9];
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
	h(indices(ii)) = subplot(4, 3, indices(ii));
	hold on
	plot(spls, qs2(values,:)', 'color',color, 'LineWidth',linewidth)
	xticks(spls)
	ylabel('Q')
	xlim([40 86])
	plot(spls, mean(qs2(values,:), 'omitnan'), 'k', 'LineWidth',linewidth)
	plot(spls, median(qs2(values,:), 'omitnan'), ':k', 'LineWidth',linewidth)
	set(gca, 'fontsize', fontsize)
	xlabel('Level (dB SPL)')

	label = ['n=' num2str(sum(values))];
	text(0.05, 0.95, label, 'Units', 'normalized', ...
		'VerticalAlignment', 'top', 'FontSize',fontsize)
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
	hLeg = legend(leg, 'FontSize',legsize);
	hLeg.ItemTokenSize = [12,6];
	hLeg.Box = 'off';
	ylim([0 18])

	% % Kruskal Wallis for non normal data, increasing
	% kruskalwallis(qs2(values,:))
	% [p, tbl, stats] = kruskalwallis(qs2(values,:), 1:3);
	% multcompare(stats, 'CType', 'dunn-sidak');

end

%% Stats 

% % Kruskal Wallis for non normal data, all data
% kruskalwallis(qs2)
% [p, tbl, stats] = kruskalwallis(qs2, 1:3);
% multcompare(stats, 'CType', 'dunn-sidak');

%% 

spls = [43, 63, 73, 83];
is200 = tables.F0 == 200;
for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		CFs = tables.CF(index);
		CF_groups = tables.CF_Group(index);
		Qs = tables.Q(index);
		MTFs = tables.MTF(index);

		% Plot
		h(10) = subplot(4, 3, 10);
		for igroup = 1:3
			if igroup == 1
				ind = strcmp(CF_groups, 'Low');
				Q_sub = Qs(ind);
				CFs_sub = CFs(ind);
			elseif igroup == 2
				ind = strcmp(CF_groups, 'Med');
				Q_sub = Qs(ind);
				CFs_sub = CFs(ind);
			else
				ind = strcmp(CF_groups, 'High');
				Q_sub = Qs(ind);
				CFs_sub = CFs(ind);
			end
			%gscatter(CFs/1000, Qs, MTFs, 'filled')
			scatter(CFs_sub/1000, Q_sub, scattersize, 'filled', 'MarkerEdgeColor','k')
			hold on
		end

		% Fit linear regression line
		mdl = fitlm(log10(CFs), log10(Qs));
		x = 0.3:0.5:10000;
		p(1) = mdl.Coefficients.Estimate(2,1);
		p(2) = mdl.Coefficients.Estimate(1,1);
		p(3) = mdl.Coefficients.pValue(2);
		p(4) = mdl.Rsquared.Ordinary;
		mdlfit(ibin, ispl,:) = 10.^(p(1)*log10(x)+p(2));
		mdlplot = squeeze(mdlfit(ibin, ispl, :));
		plot(x/1000, mdlplot, 'k', 'linewidth', linewidth);

		% Plot labels 
		number = Qs;
		number(isnan(number)) = [];
		xlabel('CF (kHz)')
		ylabel('Q')
		ylim([0.35 50])
		xlim([0.3 10])
		set(gca, 'XScale', 'log', 'YScale', 'log')
		xticks([0 200 500 1000 2000 5000 10000]/1000)
		yticks([0.2 0.5 1 2 5 10 20 50 100 200 500 1000 2000])
		grid on
		set(gca, 'fontsize', fontsize)
		msg = ['n=' num2str(length(number))];
		text(0.05, 0.95, msg, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',legsize)
	end
end

%% Significant interactions between level and CF grouping 

is200 = tables.F0 == 200;
spls = [43, 63, 73, 83];
isbin = tables.binmode == 2; % | tables.binmode == 1;
CFgroup = {'Low', 'Med', 'High'};
for iCF = 1:3
	for ispl = 1:4

		% Get data
		islevel = tables.SPL == spls(ispl);
		isCFgroup = strcmp(CFgroup{iCF}, tables.CF_Group);
		index = islevel & isbin & is200 & isCFgroup;

		% Data
		CFs = tables.CF(index);
		Qs = tables.Q(index);
		Q(iCF, ispl) = mean(Qs);
		Q_sem(iCF, ispl) = std(Qs)/sqrt(length(Qs));
	end
end

h(11) = subplot(4, 3, 11);
errorbar(Q', Q_sem', 'LineWidth',linewidth)
%xlabel('CF Group')
xlabel('Level (dB SPL)')
xlim([0.5 4.5])
xticks(1:4)
%xticklabels({'Low', 'Med', 'High'})
xticklabels([43, 63, 73, 83])
ylabel('Q')
ylim([0 12])
%legend('43 dB SPL', '63 dB SPL', '73 dB SPL', '83 dB SPL', 'Location','best')
hleg = legend('Low CF', 'Med CF', 'High CF', 'Location','best',...
	'fontsize',legsize, 'position', [0.4824,0.1757,0.1261,0.0601]);
hleg.ItemTokenSize = [8, 8];
hleg.Box = 'off';
set(gca, 'fontsize', fontsize)
grid on
box off

%% Histogram figure 

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
			qs(isesh, ispl) = tables.Q(ind);
			qs_log(isesh, ispl) = tables.Q_log(ind);
			CF_group(isesh) = tables.CF_Group(ind);
		end
	end
end

% Get matrix of units with 43, 63, 83 dB 
qs2 = qs(:,[1,2,4]);
rows_with_nan = any(isnan(qs2),2);
qs2(rows_with_nan,:) = [];
CF_group(rows_with_nan) = [];
x = [43, 63, 83];

% Try 1: Criteria using slope
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

indices = [3, 6, 9];
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

	% Find how many for each 
	low = sum(strcmp(CF_group(values), 'Low'));
	med = sum(strcmp(CF_group(values), 'Med'));
	high = sum(strcmp(CF_group(values), 'High'));

	% Put into matrix
	vals(ii,:) = [low med high];

end
vals = vals';
vals = vals./sum(vals, 2);

h(12) = subplot(4, 3, 12);
bh = bar(vals*100, 'stacked');
hleg = legend('Sharpen', 'No change', 'Broaden', 'box', 'off');
hleg.ItemTokenSize = [8, 8];
hleg.Position = [0.725670870541414,0.177945188097198,0.202256944444444,0.063657407407407];

ylabel('%')
xlabel('CF Group')
xticklabels({'Low', 'Med', 'High'})
bh(1).FaceColor = '#1b9e77';   %blue
bh(2).FaceColor = '#d95f02'; %light blue
bh(3).FaceColor = '#7570b3'; %pink
box off
ylim([0 100])
yticks(0:20:100)
set(gca, 'fontsize', fontsize)


%% Arrange figure 

left = [0.12 0.42 0.74]; %linspace(0.12, 0.74, 3);
bottom = [0.05 0.32 0.57 0.81];
height = 0.155;
width = 0.25;

left = repmat(left, 1, 4);
bottom = repmat(bottom, 3, 1);
bottom = fliplr(reshape(bottom, 1, 12));

for ii = 1:9
	set(h(ii), 'Position', [left(ii) bottom(ii) width height])
end

left = linspace(0.1, 0.75, 3);
left = repmat(left, 1, 4);
width = 0.23;
height = 0.18;
for ii = 10:11
	set(h(ii), 'Position', [left(ii) bottom(ii) width height])
end
set(h(12), 'Position', [left(12) bottom(12) width 0.12])

%%

% Annotations
titles_y = { 'Broadening','No Change','Sharpening'};
locs = linspace(0.46, 0.95, 3);
for ii = 1:3
	annotation('textbox',[0.45 locs(ii) 0.17 0.0459],...
		'String',titles_y{ii},...
		'FontSize',titlesize,'EdgeColor','none', ...
		'HorizontalAlignment', 'center', 'FontWeight','bold');
end

bottom = linspace(0.225, 0.96, 4);
left = linspace(0, 0.7, 3);
annotation('textbox',[0 bottom(4) 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0 bottom(3) 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0 bottom(2) 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0 bottom(1) 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) bottom(1) 0.0826 0.0385],'String',{'E'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3) bottom(1) 0.0826 0.0385],'String',{'F'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');


%% Save figure 
if save_figs == 1
	filename = 'fig7_changed_over_level';
	save_figure(filename)
end
end
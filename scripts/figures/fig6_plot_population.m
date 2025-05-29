function fig6_plot_population(save_figs)

% Load in spreadsheet
[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'Data_Table.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);
num_data = size(sessions, 1);

% Load in spreadsheet with peak information
spreadsheet_name = 'peak_picking.xlsx';
table = readtable(fullfile(datapath, spreadsheet_name));
tables = readtable(fullfile(datapath, "peak_picking_excludeflat.xlsx"));

%% Set up figure
figure('position', [50,50,4.567*ppi,6.5*ppi])
backgroundcolor =  [0.8 0.8 0.8];
legsize = 6;
fontsize = 7;
titlesize = 8;
linewidth = 1;
labelsize = 13;
capsize = 2;
scattersize = 15;

%% Plot imagesc of all BS responses sorted by CF

spl = [43, 63, 73, 83];
spls = {'43', '63', '73', '83'};
ispl = 2;
MTF_types = {'BS', 'BE', 'H', 'F'};
types = {'Peak', 'Dip', 'Flat'};

for iMTF = 1:3 % iMTF = 1:4

	% Find peaks and dips from table
	isspl = table.SPL == spl(ispl);
	ispeak = strcmp(table.Type, types{iMTF});
	is200 = table.F0 == 200;
	isbin = table.binmode == 2;
	isall = isspl &  ispeak & is200 & isbin;
	putatives = table.Putative(isall);
	peak_freqs = table.Freq(isall);
	num_index = size(putatives, 1);

	CFs = table.CF(isall);
	CF_names = cell(num_index, 1);
	if iMTF == 1
		array_z1 = NaN(num_index,10000);
	elseif iMTF == 2
		array_z2 = NaN(num_index,10000);
	elseif iMTF == 3
		array_z3 = NaN(num_index,10000);
	else
		array_z4 = NaN(num_index,10000);
	end

	for isesh = 1:num_index

		% Load in session
		putative = putatives{isesh};
		CF = CFs(isesh);
		peak_freq = peak_freqs(isesh);
		load(fullfile(datapath, 'neural_data', [putative '.mat']))
		params_ST = data(5+ispl, 2);
		CF_names{isesh} = [num2str(round(CFs(isesh))) ' Hz'];

		% Analysis
		data_ST = analyzeST(params_ST, CF);
		data_ST = data_ST{1};
		params_RM = data{2,2};
		data_RM = analyzeRM(params_RM);
		spont = data_RM.spont;

		% General analysis
		rate = data_ST.rates_sm;
		rate = rate - spont;
		fpeaks = data_ST.fpeaks;

		%fpeaks_re_CF = log2(fpeaks/CF);
		if iMTF == 1 || iMTF == 2
			fpeaks_re_CF = log2(fpeaks/peak_freq);
		else
			fpeaks_re_CF = log2(fpeaks/CF);
		end

		% Align by CF (approximately)
		f = linspace(-3, 3, 10000);
		[~, f_ind(1)] = min(abs(fpeaks_re_CF(2)-f));
		[~, f_ind(2)] = min(abs(fpeaks_re_CF(end)-f)); % find indices
		f_interp = linspace(f(f_ind(1)),f(f_ind(2)), f_ind(2)-f_ind(1));

		% Interpolate & get z-score
		r_interp = interp1(fpeaks_re_CF, rate,f_interp, 'spline');
		z_rate = zscore(r_interp);
		%z_rate = r_interp;

		if iMTF == 1
			array_z1(isesh, f_ind(1):f_ind(2)-1) = z_rate;
			CFs1 = CFs;
		elseif iMTF == 2
			array_z2(isesh, f_ind(1):f_ind(2)-1) = z_rate;
			CFs2 = CFs;
		elseif iMTF == 3
			array_z3(isesh, f_ind(1):f_ind(2)-1) = z_rate;
			CFs3 = CFs;
		else
			array_z4(isesh, f_ind(1):f_ind(2)-1) = z_rate;
			CFs4 = CFs;
		end
	end
end


%% Plot

types = {'Peak', 'Dip', 'Slope'};
for ii = 1:3

	% Order by CF
	if ii == 1
		[~, max_ind] = sort(CFs1);
		CF_order = array_z1(max_ind,:);
	elseif ii == 2
		[~, max_ind] = sort(CFs2);
		CF_order = array_z2(max_ind,:);
	else
		[~, max_ind] = sort(CFs3);
		CF_order = array_z3(max_ind,:);
	end

	% Plot images
	if ii == 1
		h(1) = subplot(5, 3, [1 4 7 10]);
	elseif ii == 2
		h(3) = subplot(5, 3, 2);
	else
		h(5) = subplot(5, 3, 8);
	end
	hh = imagesc(f, 1:size(CF_order, 1), CF_order);
	xline(0, 'k')
	set(hh, 'AlphaData', ~isnan(CF_order))
	set(gca,'color',backgroundcolor);
	if ispl == 1
		ylabel('Neuron Number', 'Color','w')
	end

	yticklabels([])
	xlim([-1 1])
	xticks([-1 0 1])
	clim([-2.2 2.7])
	xticklabels([])
	set(gca, 'fontsize', fontsize)
	title(types{ii}, 'fontsize', titlesize)
	if ii == 1
		a = colorbar('position', [0.258496946694888,0.194444444444451,0.01824684329611,0.131530769230791]);
		a.Label.String = 'Z-score';
	end

	% Plot overlayed responses
	if ii == 1
		h(2) = subplot(5, 3, 13);
	elseif ii == 2
		h(4) = subplot(5, 3, 5);
	else
		h(6) = subplot(5, 3, 11);
	end
	%nexttile
	hold on
	for iii = 1:size(CF_order, 1)
		patch([f,NaN],[CF_order(iii,:),NaN],'w','EdgeColor','k','LineWidth',linewidth,'EdgeAlpha',0.2);
	end
	if ii == 1
		xlabel({'Spectral Peak Freq';'w.r.t. Peak (Oct.)'})
	elseif ii == 2
		xlabel({'Spectral Peak Freq';'w.r.t. Dip (Oct.)'})
	else
		xlabel({'Spectral Peak Freq';'w.r.t. CF (Oct.)'})
	end
	xline(0, 'k')
	yline(0, 'k')
	xlim([-1 1])
	ylim([-2.2 2.7])
	ylabel('Z-score')
	set(gca, 'fontsize', fontsize)
	box off


end

%% Plot histogram
spl = [43, 63, 73, 83];
types = {'Slope', 'Peak', 'Dip'};
isBin = table.binmode == 2;
ispl = 2;
isSPL = table.SPL == spl(ispl);
for iMTF = 1:4

	if iMTF == 1
		MTF_target = 'BS';
		isMTF = strcmp(table.MTF, MTF_target);
	elseif iMTF == 2
		MTF_target = 'BE';
		isMTF = strcmp(table.MTF, MTF_target);
	elseif iMTF == 3
		MTF_target = 'Hybrid';
		isMTF = contains(table.MTF, 'H');
	else
		MTF_target = 'F';
		isMTF = strcmp(table.MTF, MTF_target);
	end
	index = isSPL & isMTF & isBin;

	num_dip = sum(cellfun(@(s) strcmp(s, 'Dip'), table.Type(index)));
	num_peak = sum(cellfun(@(s) strcmp(s, 'Peak'), table.Type(index)));
	num_flat = sum(cellfun(@(s) strcmp(s, 'Flat'), table.Type(index)));
	all = sum([num_peak num_dip num_flat]);

	percent_peak(iMTF) = num_peak/all*100;
	percent_dip(iMTF) = num_dip/all*100;
	percent_flat(iMTF) = num_flat/all*100;
end
percent_all = [percent_peak; percent_dip; percent_flat]';

h(7) = subplot(5, 3, 14);
bar(percent_all, 'stacked')
xticklabels({'BS', 'BE', 'Hybrid', 'Flat'})
hleg = legend('Peak', 'Dip', 'Slope', 'Location','northwest', ...
	'numcolumns', 2, 'box', 'off', 'position', [0.3829,0.2670,0.2097,0.0416]);
hleg.ItemTokenSize = [8,8];
ylabel('% Neurons')
xlabel('MTF Type')
ylim([0 100])
yticks(0:20:100)
set(gca, 'fontsize', fontsize)
box off

%% Add in other plots


h(8) = subplot(5, 3, 3);
is200 = tables.F0 == 200;
isPeak = strcmp(tables.Type, 'Peak');
isDip = strcmp(tables.Type, 'Dip');
isSPL = tables.SPL==63;

% Get data
isbin = tables.binmode == 2;
q_peak = tables.Q(isbin & is200 & isPeak & isSPL);
q_dip = tables.Q(isbin & is200 & isDip & isSPL);
q_dip(length(q_dip)+1:length(q_peak)) = NaN;

% Plot
hold on
boxplot([q_peak, q_dip])
swarmchart(ones(length(q_peak), 1)*1, q_peak, scattersize)
swarmchart(ones(length(q_dip), 1)*2, q_dip, scattersize)
xticks(1:2)
xticklabels({'Peak', 'Dip'})
xlim([0.5 2.5])
ylim([0 12])
ylabel('Q')
set(gca, 'fontsize', fontsize)
grid on
box off

% Stats
[~,p] = ttest2(q_peak,q_dip(~isnan(q_dip)),'Vartype','unequal');


%% MTF change vs Q

h(9) = subplot(5, 3, 6);
ispeak = strcmp(tables.Type, 'Peak');
isdip = strcmp(tables.Type, 'Dip');
isflat = strcmp(tables.Type, 'Slope');
signed_Q = tables.Q;
signed_Q(isdip) = signed_Q(isdip) * -1;
signed_Q(isflat) = 0;
signed_MTF = tables.MTF_str;

isbin = tables.binmode == 2;
is200 = tables.F0 == 200;
spls = [43, 63, 73, 83];
for ispl = 2

	% Get data
	islevel = tables.SPL == spls(ispl);
	index = islevel & isbin & is200;
	isBE = strcmp(tables.MTF(index), 'BE');
	isBS = strcmp(tables.MTF(index), 'BS');
	isH = contains(tables.MTF(index), 'H');

	% Data
	CFs = tables.CF(index);
	Qs = tables.Q(index);
	MTFs = tables.MTF(index);
	MTF_str = signed_MTF(index);

	mdl = fitlm(MTF_str(isBS), Qs(isBS));
	x = 0:0.05:1;
	p(1) = mdl.Coefficients.Estimate(2,1);
	p(2) = mdl.Coefficients.Estimate(1,1);
	p(3) = mdl.Coefficients.pValue(2);
	p(4) = mdl.Rsquared.Ordinary;
	% mdlfit = p(1)*x+p(2);
	% plot(x, mdlfit, 'k');

	% Plot
	hold on
	scatter(MTF_str(isBS), Qs(isBS), scattersize, 'filled', 'MarkerEdgeColor','k')
	scatter(MTF_str(isBE), Qs(isBE), scattersize, 'filled', 'MarkerEdgeColor','k')
	%scatter(MTF_str(isH), Qs(isH), 'filled', 'MarkerEdgeColor','k')
	xline(0)
	yline(0)
	grid on
	ylabel('Q')
	xlabel('MTF % Change')
	hleg = legend(['BS, n=' num2str(length(Qs(isBS)))],...
		['BE, n=' num2str(length(Qs(isBE)))],'fontsize', legsize, ...
		'position', [0.85,0.689,0.133,0.039], 'Box','off');
	hleg.ItemTokenSize = [8, 8];
	set(gca, 'fontsize', fontsize)
end
box off

%%

h(10) = subplot(5, 3, 9);
is200 = tables.F0 == 200;
isBE = strcmp(tables.MTF, 'BE');
isBS = strcmp(tables.MTF, 'BS');
isH = contains(tables.MTF, 'H');
isF = strcmp(tables.MTF, 'F');
for ibin = 1:2

	% Get data
	isbin = tables.binmode == ibin;
	ind_BE = isbin & is200 & isBE;
	ind_BS = isbin & is200 & isBS;
	ind_H = isbin & is200 & isH;
	ind_F = isbin & is200 & isF;

	% Data
	Q_all2(ibin,:) = [mean(tables.Q(ind_BE)) mean(tables.Q(ind_BS)) ...
		mean(tables.Q(ind_H)) mean(tables.Q(ind_F))];
	Q_sem2(ibin,:) = [std(tables.Q(ind_BE))/sqrt(length(tables.Q(ind_BE)))...
		std(tables.Q(ind_BS))/sqrt(length(tables.Q(ind_BS)))...
		std(tables.Q(ind_H))/sqrt(length(tables.Q(ind_H)))...
		std(tables.Q(ind_F))/sqrt(length(tables.Q(ind_F)))];
end

% Plot
hold on
errorbar(Q_all2(1,:), Q_sem2(1,:), 'LineWidth',linewidth, 'Color','#1b9e77')
errorbar(Q_all2(2,:), Q_sem2(2,:), 'LineWidth',linewidth, 'Color','#d95f02')

xticks(1:4)
xticklabels({'BE', 'BS', 'Hybrid', 'Flat'})
xlim([0.5 4.5])
ylim([0 6.5])
ylabel('Q')
xlabel('MTF Type')
hleg = legend('Contra', 'Diotic', 'Location','best', 'fontsize', legsize,...
	'box', 'off');
hleg.ItemTokenSize = [8, 8];
set(gca, 'fontsize', fontsize)
grid on

%%
% For units that have contra and binaural recordings, which
% increase/decrease in Q from contra to binaural?

h(11) = subplot(5, 3, 15);
is200 = tables.F0 == 200;
isPut = unique(tables.Putative);
BS_change = [];
BE_change = [];
H_change = [];
F_change = [];
isSPL = tables.SPL == 63;
for iput = 1:length(isPut)

	% Get data
	isput = strcmp(tables.Putative, isPut{iput});
	isbin = tables.binmode == 2 & is200 & isput & isSPL;
	iscontra = tables.binmode == 1 & is200 & isput & isSPL;

	if any(isbin) && any(iscontra)

		%q_change = [mean(tables.Q(iscontra)) mean(tables.Q(isbin))];
		q_change = sign(mean(tables.Q(isbin)) - mean(tables.Q(iscontra)));
		MTF_type = unique(tables.MTF(isbin));
		if strcmp(MTF_type, 'BS')
			BS_change = [BS_change; q_change];
		elseif strcmp(MTF_type, 'BE')
			BE_change = [BE_change; q_change];
		elseif contains(MTF_type, 'H')
			H_change = [H_change; q_change];
		else
			F_change = [F_change; q_change];
		end
	end
end
bin_change1 = [sum(BE_change==-1) sum(BE_change==1)]./length(BE_change)*100;
bin_change2 = [sum(BS_change<=0) sum(BS_change==1)]./length(BS_change)*100;
bin_change3 = [sum(H_change==-1) sum(H_change==1)]./length(H_change)*100;
bin_change4 = [sum(F_change==-1) sum(F_change==1)]./length(F_change)*100;
bin_change = [bin_change1;bin_change2;bin_change3;bin_change4];

% Plot
hold on
bars = bar(bin_change, 'stacked');
bars(1).FaceColor = '#1b9e77';   %blue
bars(2).FaceColor = '#d95f02'; %light blue

xticks(1:4)
xticklabels({'BE', 'BS', 'Hybrid', 'Flat'})
xlim([0.5 4.5])
ylim([0 100])
yticks([0 25 50 75 100])
ylabel('Percent (%)')
xlabel('MTF Type')
hleg = legend('Contra Q > Diotic Q', 'Diotic Q > Contra Q', 'Location','north',...
	'fontsize', legsize, 'NumColumns', 1, 'box', 'off', 'position', ...
	[0.711246200607903,0.217948717948719,0.218844984802432,0.039529914529915]);
hleg.ItemTokenSize = [8, 8];
set(gca, 'fontsize', fontsize)
grid on

%% Rearrange
left = [0.06 0.41 0.75];
bottom = linspace(0.08, 0.8, 5);
width = 0.22;
height = 0.1;

set(h(1), 'position', [left(1) 0.19 width 0.78])
set(h(2), 'position', [left(1) bottom(1) width height])

set(h(3), 'position', [left(2) 0.84 width 0.13])
set(h(4), 'position', [left(2) 0.73 width height])

set(h(5), 'position', [left(2) 0.5 width 0.12])
set(h(6), 'position', [left(2) 0.4 width height])

set(h(7), 'position', [left(2) bottom(1) width 0.18])

%bottom = linspace(bottom(1), 0.8, 4);
bottom = [0.08 0.33 0.57 0.8];
height = 0.16;
width = 0.22;
set(h(8), 'position', [left(3) bottom(4) width height])
set(h(9), 'position', [left(3) bottom(3) width height])
set(h(10), 'position', [left(3) bottom(2) width height])
set(h(11), 'position', [left(3) bottom(1) width 0.135])

%% Add labels
annotation('textbox',[0.0 0.96 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.34 0.96 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.34 0.62 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.34 0.3 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
bottom = linspace(0.24, 0.96, 4);
annotation('textbox',[0.67 bottom(4) 0.0826 0.0385],'String',{'E'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.67 bottom(3) 0.0826 0.0385],'String',{'F'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.67 bottom(2) 0.0826 0.0385],'String',{'G'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.67 bottom(1) 0.0826 0.0385],'String',{'H'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure
if save_figs == 1
	filename = 'fig6_plot_population';
	save_figure(filename)
end
end
function fig9_model_examples(save_fig)

%% Create figure

[~, datapath, ~, ppi] = get_paths();
figure('Position',[50,50,5.8*ppi,4.1*ppi])

legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;
scattersize = 16;
capsize = 2;
h = gobjects(12, 1);

%% Load in examples and plot

for ii = 1:6
	switch ii
		case 1 % BS Good
			putative = 'R24_TT2_P13_N05';
			CF = 1326;
			MTF_shape = 'BS';
		case 2 % BS Bad
			putative = 'R27_TT4_P8_N10';
			CF = 4652;
			MTF_shape = 'BS';
			% putative = 'R25_TT4_P7_N01';
			% CF = 1516;
		case 3 % Inhibition areas
			putative = 'R29_TT4_P5_N02';
			CF = 758;
			MTF_shape = 'BS';
			% putative = 'R24_TT2_P13_N02';
			% CF = 1150;
		case 4 % Hook
			putative = 'R29_TT3_P5_N07';
			CF = 1320;
			MTF_shape = 'BS';
			% putative = 'R25_TT3_P9_N01';
			% CF = 865;
		case 5 % BE Okay
			putative = 'R27_TT2_P8_N05';
			CF = 5278;
			MTF_shape = 'BE';
		case 6 % BE Bad
			putative = 'R29_TT1_P2_N04';
			CF = 5949;
			MTF_shape = 'BE';
	end
	ispl = 2;

	% Load in data
	load(fullfile(datapath, 'neural_data', [putative '.mat']), 'data')

	% Load in model data
	load(fullfile(datapath,'model-SFIE', [putative '_SFIE.mat']), 'SFIE')
	load(fullfile(datapath,'model-energy', [putative '_Energy.mat']), 'energy')
	load(fullfile(datapath,'model-lat-inh', [putative '_Lat_Inh.mat']), 'lat_inh')

	% Get spont rate
	param_RM = data(2,2);
	data_RM = analyzeRM(param_RM{1});

	% Plot synthetic timbre (raw)
	h(ii) = subplot(3, 4, ii);
	param_ST = data(5+ispl, 2);
	if isempty(param_ST{1})
		continue
	end
	data_ST = analyzeST(param_ST, CF);
	data_ST = data_ST{1};

	% Z-score
	rate = data_ST.rate; %zscore(data_ST.rate);
	rate_sm = data_ST.rates_sm; %zscore(data_ST.rates_sm);
	hold on
	errorbar(data_ST.fpeaks,rate, data_ST.rate_std/sqrt(param_ST{1}.nrep),...
		'linewidth', 0.8, 'Color','k', 'LineStyle','none', 'CapSize',capsize);
	plot(data_ST.fpeaks,rate_sm, 'linewidth', linewidth,'Color','k');
	yline(data_RM.spont, 'k')

	% Normalize and plot models
	%plot(data_ST.fpeaks, zscore(energy{ispl}.rate), 'LineWidth',linewidth, 'Color','#4634F1')
	%plot(data_ST.fpeaks, zscore(SFIE{ispl}.rate), 'LineWidth',linewidth, 'Color','#009E73')
	%plot(data_ST.fpeaks, zscore(lat_inh{ispl}.rate), 'LineWidth',linewidth, 'Color','#D55E00')

	% Scale models
	spont = data_RM.spont;
	max_rate = max(rate_sm);
	energy_rate = energy{ispl}.rate .* (max_rate/max(energy{ispl}.rate));
	SFIE_rate = SFIE{ispl}.rate .* (max_rate/max(SFIE{ispl}.rate));
	lat_inh_rate = lat_inh{ispl}.rate .* (max_rate/max(lat_inh{ispl}.rate));

	% Plot
	plot(data_ST.fpeaks, energy_rate, 'LineWidth',linewidth, 'Color','#4634F1')
	plot(data_ST.fpeaks, SFIE_rate, 'LineWidth',linewidth, 'Color','#009E73')
	plot(data_ST.fpeaks, lat_inh_rate, 'LineWidth',linewidth, 'Color','#D55E00')

	% Annotate SFIE model R^2
	% message = sprintf('R^2 SFIE = %.02f', SFIE{ispl}.R2);
	% text(0.05, 0.25, message, 'Units', 'normalized', ...
	% 	'VerticalAlignment', 'top', 'FontSize',legsize, 'Color',...
	% 	'#009E73')
	% % Annotate energy model R^2
	% message = sprintf('R^2 Energy = %.02f', energy{ispl}.R2);
	% text(0.05, 0.15, message, 'Units', 'normalized', ...
	% 	'VerticalAlignment', 'top', 'FontSize',legsize, 'Color',...
	% 	'#4634F1')
	% % Annotate lateral inhibition model R^2
	% message = sprintf('R^2 Broad inh = %.02f', lat_inh{ispl}.R2);
	% text(0.05, 0.35, message, 'Units', 'normalized', ...
	% 	'VerticalAlignment', 'top', 'FontSize',legsize, 'Color',...
	% 	'#D55E00')

	% Plot parameters
	plot_range = [param_ST{1}.fpeaks(1) param_ST{1}.fpeaks(end)];
	xline(CF, '--', 'Color',[0.7 0.7 0.7], 'linewidth', linewidth+1)
	xlim(plot_range)
	if ii == 1
		xticks([3200 3600 4000 4400 4800]);
	end
	ticks = xticks;
	xticklabels(ticks./1000)
	if ii == 5 || ii == 6
		xlabel('Spec. Peak Freq. (kHz)')
	end
	if ii == 1 || ii == 3 || ii == 5
		ylabel('Rate (sp/s)')
	end
	ylim([0 max_rate+max_rate*0.15])
	set(gca, 'fontsize', fontsize)
	grid on

	% BE/BS labels
	if ii == 6
		text(0.15, 0.95, MTF_shape, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',legsize)
	else
		text(0.05, 0.95, MTF_shape, 'Units', 'normalized', ...
			'VerticalAlignment', 'top', 'FontSize',legsize)
	end

	if ii == 1
		hLeg = legend('Data', '', 'Spont', 'Energy', 'SFIE', 'Broad Inh.', 'CF', 'Location',...
			'northoutside', 'FontSize',legsize, 'NumColumns', 2, 'box', 'off');
		hLeg.ItemTokenSize = [12, 12];
	end

end

%%

% Load in spreadsheet
spreadsheet_name = 'model_r2_values_ST2.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);
num_data = size(sessions, 1);
subplot_numbers = [7, 10];
isSPL = sessions.SPL == 63;
for ii = 1:2

	isBS = strcmp(sessions.MTF, 'BS');
	isBE = strcmp(sessions.MTF, 'BE');
	if ii == 1
		%isnotsig = sessions.p_s_e>0.05;
		x_R2 = sessions.Energy_R(isBS & isSPL);
		x_R22 = sessions.Energy_R(isBE & isSPL);

		y_R2 = sessions.SFIE_R(isBS & isSPL);
		y_R22 = sessions.SFIE_R(isBE & isSPL);
	elseif ii == 2

		%isnotsig = sessions.p_l_e>0.05;
		x_R2 = sessions.Energy_R(isBS & isSPL);
		x_R22 = sessions.Energy_R(isBE & isSPL);

		y_R2 = sessions.Lat_Inh_R(isBS & isSPL);
		y_R22 = sessions.Lat_Inh_R(isBE & isSPL);
	else

		%isnotsig = sessions.p_l_s>0.05;
		x_R2 = sessions.SFIE_R(isBS &isSPL);
		x_R22 = sessions.SFIE_R(isBE & isSPL);

		y_R2 = sessions.Lat_Inh_R(isBS & isSPL);
		y_R22 = sessions.Lat_Inh_R(isBE & isSPL);
	end

	h(subplot_numbers(1, ii)) = subplot(3, 4, subplot_numbers(1, ii)); % [1 4 7 10 13 16]
	hold on
	scatter(x_R2, y_R2, scattersize, 'filled', 'MarkerEdgeColor','k', "MarkerFaceAlpha",0.7)
	scatter(x_R22, y_R22, scattersize, 'filled', 'MarkerEdgeColor','k', ...
		'MarkerFaceColor',"#D95319", "MarkerFaceAlpha",0.7)
	%scatter(x_non, y_non, 'MarkerEdgeColor','k')
	plot([-1 1], [-1 1], 'k')
	xticklabels([])
	yticklabels([])
	set(gca, 'fontsize', fontsize)
	yline(0)
	xline(0)
	if ii == 2
		hleg = legend('BS', 'BE', '', '', 'location', 'south', 'box', 'off');
		hleg.ItemTokenSize = [8, 8];
		hleg.Position = [0.9122,0.1618,0.0626,0.0661];
	end

	% Create distribution plot for the X-axis (horizontal)
	edges = linspace(-1, 1, 20);
	h(subplot_numbers(1, ii)+1) = subplot(3, 4, subplot_numbers(1, ii)+1);
	histogram(x_R2,edges, 'Orientation', 'vertical', 'EdgeColor', 'k');
	hold on
	histogram(x_R22,edges, 'Orientation', 'vertical', 'EdgeColor', 'k', 'FaceColor', "#D95319");
	xlim([-1 1])
	xlabel('Energy R')
	set(gca, 'fontsize', fontsize)
	xticks(-1:0.5:1)
	xline(0, 'k')
	yticks([])
	box off

	% Create distribution plot for the Y-axis (vertical) below the scatter plot
	edges = linspace(-1, 1, 20);
	h(subplot_numbers(1, ii)+2) = subplot(3, 4, subplot_numbers(1, ii)+2);
	histogram(y_R2,edges, 'Orientation', 'horizontal', 'EdgeColor', 'k');
	hold on
	histogram(y_R22,edges, 'Orientation', 'horizontal', 'EdgeColor', 'k', 'FaceColor', "#D95319");
	ylim([-1 1])
	if ii == 1
		ylabel('SFIE R')
	else
		ylabel('Broad Inhibition R')
	end
	set(gca, 'fontsize', fontsize)
	yticks(-1:0.5:1)
	yline(0, 'k')
	xticks([])
	box off
end

%% Number of neurons.....

% Neurons that have all three model predictions R^2 > 0.85. Out of 127
num_good = sum(sessions.Energy_R2 > 0.4 & sessions.SFIE_R2 > 0.4 & ...
	sessions.Lat_Inh_R2 > 0.4 & sessions.SPL == 63);

% All units with model predictions < 0.4
num_bad = sum(sessions.Energy_R2 < 0.4 & sessions.SFIE_R2 < 0.4 & ...
	sessions.Lat_Inh_R2 < 0.4 & sessions.SPL == 63);

% Number of broad-inhibition model better than other models
num_inh = sum(sessions.Lat_Inh_R2 > sessions.Energy_R2 & ...
	sessions.Lat_Inh_R2 > sessions.SFIE_R2 & sessions.SPL == 63);

%% Arrange

left = [0.08 0.33];
bottom = linspace(0.07, 0.68, 3);
height = 0.22;
width = 0.19;

set(h(1), 'Position', [left(1) bottom(3) width height])
set(h(2), 'Position', [left(2) bottom(3) width height])
set(h(3), 'Position', [left(1) bottom(2) width height])
set(h(4), 'Position', [left(2) bottom(2) width height])
set(h(5), 'Position', [left(1) bottom(1) width height])
set(h(6), 'Position', [left(2) bottom(1) width height])

% Annotate
left = [0.01 0.275];
bottom = linspace(0.32, 0.91, 3);
annotation('textbox',[left(1) 0.97 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) bottom(3) 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(1) bottom(2) 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) bottom(2) 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(1) bottom(1) 0.0826 0.0385],'String',{'E'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) bottom(1) 0.0826 0.0385],'String',{'F'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%%
% Arrange plots
all_fig_positions = ...
	[0.68,0.15,0.29,0.32;...
	0.68,0.64,0.29,0.32]; % left bottom width height

subplot_numbers = [10, 7];
for ipos = 1:2
	fig_position = all_fig_positions(ipos,:);
	nb_position = [fig_position(1),fig_position(2)-0.08,fig_position(3),0.06];
	wb_position = [fig_position(1)-0.06,fig_position(2),0.05,fig_position(4)];
	set(h(subplot_numbers(ipos)), 'Position', fig_position)
	set(h(subplot_numbers(ipos)+1), 'Position', nb_position)
	set(h(subplot_numbers(ipos)+2), 'Position', wb_position)
end

% Annotate
labels = {'G', 'H',};
labelbottom = [0.95 0.48];
for ii = 1:2
	annotation('textbox',[0.55 labelbottom(ii) 0.071 0.058],...
		'String',labels{ii},'FontWeight','bold','FontSize',labelsize,...
		'EdgeColor','none');
end

%% Save figure
if save_fig == 1
	filename = 'fig9_model_examples';
	save_figure(filename)
end
end
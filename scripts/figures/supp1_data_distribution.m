function supp1_data_distribution(save_fig)
% J. Fritzinger, updated 12/15/23
%
% This script loads in the putative neurons spreadsheet and plots the MTF
% distribution, BMF distribution, WMF distribution, hybrid BMF/WMF
% distribution, and CF distribution for all neurons

%% Load in spreadsheet

[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'Data_Table.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), 'PreserveVariableNames',true);
num_units = size(sessions, 1);

%% Set up figure

figure('Position',[50,50,6.9*ppi,1.5*ppi])
tiledlayout(1, 4, 'Padding','compact')
legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;

%% Only get sessions with synthetic timbre

synth(:,1) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB);
synth(:,2) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB);
synth(:,3) = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB);
synth(:,4) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB);

% synth(:,5) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB_100);
% synth(:,6) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB_100);
% synth(:,8) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB_100);

synth(:,5) = cellfun(@(s) contains(s, 'R'), sessions.ST_43dB_con);
synth(:,6) = cellfun(@(s) contains(s, 'R'), sessions.ST_63dB_con);
synth(:,7) = cellfun(@(s) contains(s, 'R'), sessions.ST_73dB_con);
synth(:,8) = cellfun(@(s) contains(s, 'R'), sessions.ST_83dB_con);

any_synth = any(synth(:,1:8), 2);
table = sessions(any_synth, :);

% Output num units
fprintf('Synth timbre total: %d\n', sum(any_synth))
fprintf('Synth timbre @ 200 Hz, 43 dB SPL: %d\n', sum(synth(:,1)))
fprintf('Synth timbre @ 200 Hz, 63 dB SPL: %d\n', sum(synth(:,2)))
fprintf('Synth timbre @ 200 Hz, 73 dB SPL: %d\n', sum(synth(:,3)))
fprintf('Synth timbre @ 200 Hz, 83 dB SPL: %d\n', sum(synth(:,4)))
fprintf('Synth timbre @ 200 Hz contra, 43 dB SPL: %d\n', sum(synth(:,5)))
fprintf('Synth timbre @ 200 Hz contra, 63 dB SPL: %d\n', sum(synth(:,6)))
fprintf('Synth timbre @ 200 Hz contra, 73 dB SPL: %d\n', sum(synth(:,7)))
fprintf('Synth timbre @ 200 Hz contra, 83 dB SPL: %d\n', sum(synth(:,8)))

%% Get CFs for each putative neuron

% WBTIN Diotic
CFs = table.CF;
edges = [0 500 1000 2000 4000 8000 13000];
names = categorical({'<0.5', '0.5-1', '1-2', '2-4', '4-8', '8+'});
names = reordercats(names,{'<0.5', '0.5-1', '1-2', '2-4', '4-8', '8+'});
CF = CFs;
CF(CF==0) = [];
[N, edges1] = histcounts(CF, edges);

% Plot
nexttile
bar(names,N,'FaceColor', 'k', 'EdgeColor','k');
grid on
ylabel('# Neurons')
xlabel('CF (kHz)')
set(gca, 'FontSize', fontsize)
title('CF Distribution', 'fontsize', titlesize)
ylim([0 80])

for ii = 1:6
	fprintf('CF = %s: %d\n', names(ii), N(ii))
end
fprintf('Min CF = %d Hz\n', min(CFs))
fprintf('Max CF = %d Hz\n', round(max(CFs)))
fprintf('Median CF = %d Hz\n', round(median(CFs)))

%% Get MTFs for each putative neuron

MTFs = table.MTF;
num_sesh = length(MTFs);
MTF_type = zeros(num_sesh,1);
for isesh = 1:num_sesh
	MTF_shape = MTFs{isesh};
	if contains(MTF_shape, 'H')
		MTF_type(isesh) = 3;
	elseif strcmp(MTF_shape, 'BE')
		MTF_type(isesh) = 1;
	elseif strcmp(MTF_shape, 'BS')
		MTF_type(isesh) = 2;
	else % Flat
		MTF_type(isesh) = 4;
	end
end
MTF_names = categorical({'BE','BS','Hybrid','Flat'});
MTF_names = reordercats(MTF_names,{'BE','BS','Hybrid','Flat'});
num_BE = sum(MTF_type==1);
num_BS = sum(MTF_type==2);
num_H = sum(MTF_type==3);
num_n = sum(MTF_type==4);
num_types = [num_BE num_BS num_H num_n];

% Plot
nexttile
bar(MTF_names,num_types, 'black');
set(gca, 'FontSize', fontsize)
title('MTF Type', 'FontSize',titlesize)
grid on
ylabel('# Neurons')
%ylim([0 110])

for ii = 1:4
	fprintf('MTF = %s: %d, %0.2f%%\n', MTF_names(ii), num_types(ii), ...
		num_types(ii)/sum(any_synth)*100)
end

%% BMFs

% Get BMFs/WMFs
BE_MTFs = strcmp(table.MTF, 'BE');
BMFs = table.BMF(BE_MTFs);
BMFs(isnan(BMFs)) = [];

edges = [0.2 2 4 8 16 32 64 128 254 512 1028];
edges2 = zeros(10, 1);
for iedge = 1:10
	edges2(iedge) = sqrt(edges(iedge)*edges(iedge+1));
end

% BMFs
nexttile
histogram(BMFs, edges2,'FaceColor', '#0072BD', 'EdgeColor','k')
hold on
xline(exp(median(log(BMFs(BMFs~=0)))), 'k', 'LineWidth',1.5)
xticks([2 4 8 16 32 64 128 254 512])
set(gca, 'FontSize', fontsize)
title('BE BMFs', 'fontsize', titlesize)
set(gca, 'XScale', 'log');
xlabel('BMF (Hz)')
ylabel('# Neurons')

fprintf('Min BMF = %d Hz\n', min(BMFs))
fprintf('Max BMF = %d Hz\n', round(max(BMFs)))
fprintf('Median BMF = %d Hz\n', round(median(BMFs)))

%% WMFs

BS_MTFs = strcmp(table.MTF, 'BS');
WMFs = table.WMF(BS_MTFs);
WMFs(isnan(WMFs)) = [];

nexttile
histogram(WMFs, edges2,'FaceColor', '#D95319', 'EdgeColor','k')
hold on
ylabel('# Neurons')
xline(exp(median(log(WMFs(WMFs~=0)))), 'k', 'LineWidth',1.5)
set(gca, 'FontSize', fontsize)
xticks([2 4 8 16 32 64 128 254 512])
set(gca, 'XScale', 'log');
xlabel('WMF (Hz)')
title('BS WMFs', 'fontsize', titlesize)

fprintf('Min WMF = %d Hz\n', min(WMFs))
fprintf('Max WMF = %d Hz\n', round(max(WMFs)))
fprintf('Median WMF = %d Hz\n', round(median(WMFs)))

%% Annotations

left = linspace(0.01, 0.73, 4);
annotation('textbox',[left(1) 0.96 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) 0.96 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3) 0.96 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(4) 0.96 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure
if save_fig == 1
	filename = 'figS1_data_distribution';
	save_figure(filename)
end
end
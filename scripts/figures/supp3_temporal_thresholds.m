function supp3_temporal_thresholds(save_fig)
% SUPP_TEMPORAL_THRESHOLDS Generates Supplementary Figure evaluating temporal VS thresholds.
%
% PURPOSE:
%   This function compares neural thresholds computed from temporal vector strength (VS)
%   against traditional average firing rate thresholds. It analyzes threshold metrics as a
%   function of characteristic frequency (CF) alongside a direct cell-by-cell scatter 
%   cross-comparison (Rate vs. VS) across multiple data cleaning regimes, evaluating performance 
%   relative to a 4% human psychophysical benchmark.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a 2x2 multi-panel threshold comparison figure. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up (Original framework dated for 2025 manuscript)

%% Load in data 

[~, datapath, ~, ppi] = get_paths();
tables_VS = readtable(fullfile(datapath, "st_response_metrics_VS.xlsx"));
tables = readtable(fullfile(datapath, "st_response_metrics_rate.xlsx"));

%% Set up figure 
figure('Position',[50,50,4*ppi,4*ppi])
fontsize = 7;
labelsize = 13;
scattersize = 10; 

%%

% Set up figure 
subplot(2, 2, 1);
spls = [43, 63, 73, 83];
is200 = tables.F0==200;

for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		CFs = tables_VS.CF(index);
		Qs = tables_VS.Threshold(index);

		% Add in units without thresholds
		Qs(isnan(Qs)) = 100;
		Qs(Qs>100) = 100;

		% Plot
		scatter(CFs/1000, Qs, scattersize, 'filled', 'MarkerEdgeColor','k', ...
			'MarkerFaceColor','k', 'MarkerFaceAlpha',0.5)
		hold on

		% Plot human threshold
		scatter(1200/1000, 4,scattersize, 'r', 'filled','markeredgecolor', 'k') %'filled')
		yline(4, 'r')

		% Plot labels 
		xlabel('CF (kHz)')
		if ispl == 1
			ylabel('Q')
		end
		ylim([0.35 100])
		xlim([0.3 10])
		set(gca, 'fontsize', fontsize)
		set(gca, 'XScale', 'log')
		set(gca, 'YScale', 'log')
		ylabel('Threshold from VS (%)')
		xticks([0 200 500 1000 2000 5000 10000]/1000)
		yticks([0.2 0.5 1 2 5 10 20 50 100])
		yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '50', '>100'})
		grid on
		box off
		hleg = legend('Neural','Human', '', 'Location','southwest', 'box',...
			'off');
		hleg.ItemTokenSize = [8, 8];
	end
end

%% 

subplot(2, 2, 2);
spls = [43, 63, 73, 83];
is200 = tables.F0==200;

for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		Qs = tables.Threshold(index);
        Qs_VS = tables_VS.Threshold(index);

		% Add in units without thresholds
		Qs(isnan(Qs)) = 50;
		Qs(Qs>50) = 50;
        Qs_VS(isnan(Qs_VS)) = 50;
        Qs_VS(Qs_VS>50) = 50;

		% Plot
		scatter(Qs, Qs_VS, scattersize, 'filled', 'MarkerEdgeColor','k', ...
			'MarkerFaceColor','k', 'MarkerFaceAlpha',0.5)
		hold on
        plot([0.35 50], [0.35 50], 'k')

		% Plot labels 
		xlabel('Threshold from Rate (%)')
		if ispl == 1
			ylabel('Q')
		end
		ylim([0.35 50])
		xlim([0.35 50])
		set(gca, 'fontsize', fontsize)
		set(gca, 'XScale', 'log')
		set(gca, 'YScale', 'log')
		ylabel('Threshold from VS (%)')
		xticks([0.2 0.5 1 2 5 10 20 50 70])
		yticks([0.2 0.5 1 2 5 10 20 50 70])
		yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
        xticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
		grid on
		box off
		hleg.ItemTokenSize = [8, 8];
	end
end

% % Stats 
% above_50 = sum(Qs_VS==50)/length(Qs_VS);
% better_than_rate = sum(Qs_VS>Qs);
% perc_better = better_than_rate/length(Qs_VS);
% near_human =  sum(Qs_VS<6)/length(Qs_VS);

%% 

tables_RIS = readtable(fullfile(datapath, "st_response_metrics_RIS.xlsx"));

% Set up figure 
subplot(2, 2, 3);
for ibin = 2
	isbin = tables_RIS.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables_RIS.SPL == spls(ispl);
		index = islevel & isbin; % & isMTF;

		% Data
		CFs = tables_RIS.CF(index);
		Qs = tables_RIS.Threshold_Real(index);

		% Add in units without thresholds
		Qs(isnan(Qs)) = 100;
		Qs(Qs>100) = 100;

		% Plot
		scatter(CFs/1000, Qs, scattersize, 'filled', 'MarkerEdgeColor','k', ...
			'MarkerFaceColor','k', 'MarkerFaceAlpha',0.5)
		hold on

		% Plot human threshold
		scatter(1200/1000, 4,scattersize, 'r', 'filled','markeredgecolor', 'k') %'filled')
		yline(4, 'r')

		% Plot labels 
		xlabel('CF (kHz)')
		if ispl == 1
			ylabel('Q')
		end
		ylim([0.35 100])
		xlim([0.3 10])
		set(gca, 'fontsize', fontsize)
		set(gca, 'XScale', 'log')
		set(gca, 'YScale', 'log')
		ylabel('Threshold from RIS (%)')
		xticks([0 200 500 1000 2000 5000 10000]/1000)
		yticks([0.2 0.5 1 2 5 10 20 50 100])
		yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '50', '>100'})
		grid on
		box off
		hleg = legend('Neural','Human', '', 'Location','southwest', 'box',...
			'off');
		hleg.ItemTokenSize = [8, 8];
	end
end

%% 

subplot(2, 2, 4);
spls = [43, 63, 73, 83];
is200 = tables.F0==200;
for ibin = 2
	isbin = tables.binmode == ibin;
	for ispl = 2

		% Get data
		islevel = tables.SPL == spls(ispl);
		index = islevel & isbin & is200; % & isMTF;

		% Data
		Qs = tables.Threshold(index);
        Qs_VS = tables_RIS.Threshold_Real;

		% Add in units without thresholds
		Qs(isnan(Qs)) = 50;
		Qs(Qs>50) = 50;
        Qs_VS(isnan(Qs_VS)) = 50;
        Qs_VS(Qs_VS>50) = 50;

		% Plot
		scatter(Qs, Qs_VS, scattersize, 'filled', 'MarkerEdgeColor','k', ...
			'MarkerFaceColor','k', 'MarkerFaceAlpha',0.5)
		hold on
        plot([0.35 50], [0.35 50], 'k')

		% Plot labels 
		xlabel('Threshold from Rate (%)')
		if ispl == 1
			ylabel('Q')
		end
		ylim([0.35 50])
		xlim([0.35 50])
		set(gca, 'fontsize', fontsize)
		set(gca, 'XScale', 'log')
		set(gca, 'YScale', 'log')
		ylabel('Threshold from RIS (%)')
		xticks([0.2 0.5 1 2 5 10 20 50 70])
		yticks([0.2 0.5 1 2 5 10 20 50 70])
		yticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
        xticklabels({'0.2', '0.5', '1', '2', '5', '10', '20', '>50'})
		grid on
		box off
		hleg.ItemTokenSize = [8, 8];
	end
end

% % Stats 
% above_50 = sum(Qs_VS==50)/length(Qs_VS);
% better_than_rate = sum(Qs_VS<Qs);
% perc_better = better_than_rate/length(Qs_VS);
% near_human =  sum(Qs_VS<6)/length(Qs_VS);

%% Annotate 

annotation('textbox',[0.01 0.97 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 0.97 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.01 0.48 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 0.48 0.0826 0.0385],'String',{'D'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure

if save_fig == 1
	filename = 'fig_s3_temporal_thresholds';
	save_figure(filename)
end

end
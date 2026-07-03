function [PSTH] = plotST_PSTH(param, model_response, iplot)

[fpeaks,~,fpeaksi] = unique([param.mlist.fpeak].');
num_fpeaks = length(fpeaks);
dur = param.dur/1000; % stimulus duration in seconds.
model_response = squeeze(model_response);

% Rasters
reps = zeros(num_fpeaks,1);
for j1 = 1:num_fpeaks
	j = fpeaksi(:,1) == j1;
	reps(j) = (1:sum(j)).';
end

for j1 = 1:num_fpeaks
	k = find(fpeaksi == j1);
	PSTH(j1,:) = mean(model_response(k,:), 1);
end

% Plot rasters in a stack of full-width axes.
if iplot == 1
	x = linspace(0, size(model_response,2)/stim_params.Fs, size(model_response,2));
	num_plots = num_fpeaks;

	ny = num_plots;
	axi = 0;
	figure('Renderer', 'painters', 'Position', [10 10 800 400])
	set(gcf,'color','w');
	for j1 = 1:num_fpeaks

		ax = axes('Units','normalized',...
			'Position',[0.13 0.11+0.815*axi/ny 0.775 0.815/ny],...
			'FontSize',6);
		axi = axi + 1;

		iplot(ax, x, model_response(k,:))
		set(ax,'XLim',[0 dur*1.1])
		ax.FontSize = 6;
		ax.TickLength = [0 0];
		if axi > 1
			ax.XTickLabel = '';
		else
			xlabel('Spike time (ms)','FontSize',8)
		end
		text(0,0,sprintf('%.3g Hz     ',fms(j1)),...
			'HorizontalAlignment','right',...
			'VerticalAlignment','bottom',...
			'FontSize',8)
	end
end
end
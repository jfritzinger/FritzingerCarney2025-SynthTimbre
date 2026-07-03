function [rate, rate_std] = plotST(param, model_response, plot)
% Plots the spectral centroid cluster
% J. Fritzinger, updated 3/2/2022

xlabels = param.fpeaks(1):param.Delta_F:param.fpeaks(end);
plot_range = [param.fpeaks(1) param.fpeaks(end)];

[fpeaks,~,fpeaksi] = unique([param.mlist.fpeak].');
num_fpeaks = length(fpeaks);
dur = param.dur/1000; % stimulus duration in seconds.

rate_size = [num_fpeaks,1];
[rate,rate_std] = accumstats({fpeaksi},model_response, rate_size);

if plot == 1
	% Plot
	hold on
	errorbar(fpeaks,rate,rate_std/(sqrt(param.mnrep)),'LineWidth',1.5);

	% Label figure & set
	xlabel('Frequency (Hz)')
	ylabel('Spike rate (sp/s)')
	set(gca,'FontSize',10, 'XTick', xlabels)
	xlim(plot_range);
	grid on
	axis_set = axis;
	axis_set(3) = 0;
	axis(axis_set);
end

end
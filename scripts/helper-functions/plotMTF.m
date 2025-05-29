function [fig, avBE, stdBE, MTF_shape, rate_sm] = plotMTF(stim_params, model, plot_on)
% plotMTF plots average rate MTF for model responses 
%   Average rate response for model response to modulated noise. 
%
% Inputs:
%    stim_params - params for MTF
%	 model - model response
%	 plot_on - 1 = plot, 0 = no plot
%
% Outputs:
%    fig - Average rate plot
%    rate - average rate response (5x3, num_spls x num_binmodes)
%	 rate_std - standard deviation of rates (5x3, num_spls x num_binmodes)
%
% Other m-files required: accumstats
%
% Author: J. Fritzinger, adapted from cell_characterization
% Created: ------; Last revision: 2024-12-12
%
% -------------------------------------------------------------------------

[fms,~,fmi] = unique(double([stim_params.mlist.fm]).');
num_mod_freqs = length(fms);
all_mod_depths = double([stim_params.mlist.mdepth]).';
all_mod_depths(all_mod_depths < -80) = max(all_mod_depths);
[~,~,mdi] = unique(all_mod_depths);
num_depths = length(stim_params.all_mdepths);
rate_size = [num_mod_freqs, num_depths];

% Plot model
if ~isempty(model)
	[avBE,stdBE,~,rlb, rub] = accumstats({fmi,mdi},model, rate_size);
	[~,~,MTF_shape, ~, ~] = MTFclassification(model,fms, fmi);
    rate_sm = smooth_rates(avBE,rlb,rub, []);

	if plot_on == 1
		fig = figure;
		hold on
		line([1 stim_params.all_fms(end)], [1 1]*avBE(1),'Color',[0.4 0.4 0.4], 'linewidth', 1.5);
		errorbar(stim_params.all_fms,avBE, stdBE,'.');
		line(stim_params.all_fms,avBE,'Color','k', 'Marker','.', 'MarkerSize',5, 'MarkerFaceColor','w');
		%plot(data.fms,rate_sm,'-b', 'LineWidth', 1)
		hold off
		% Label the plots
		xtick = [1 2 5 20 50 100 200 500];
		xlim(xtick([1 end]))
		xlabel('Modulation Freq (Hz)')
		ylabel('Avg. Rate (sp/s)')
		set(gca,'XTick',xtick,'XScale', 'log')
		legend('Unmodulated', 'Location','best')
		grid on
		axis_set = axis;
		axis_set(3) = 0;
		axis(axis_set);
	else
		fig = [];
	end
end

end
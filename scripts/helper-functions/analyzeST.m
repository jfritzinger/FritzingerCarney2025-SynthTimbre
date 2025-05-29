function data = analyzeST(params, CF)
%
% Function that takes in the synthetic timbre parameters and raw data and
% outputs a struct containing the processed average rates, temporal
% analysis, half-height BW, and more. 
%
%
% Author: J. Fritzinger
% Created: -----------; Last revision: 2024-10-21
%
% -------------------------------------------------------------------------

num_DSIDs = length(params);
for ind = 1:num_DSIDs
	param = params{ind};
	ds = param.dsid;
	this_ds = param.stims.dsid == ds;
	cluster = param.cluster;

	[fpeaks,~,fpeaksi] = unique([param.list.fpeak].');
	num_fpeaks = length(fpeaks);
	dur = param.dur/1000; % stimulus duration in seconds.

	rate_size = [num_fpeaks,1];
	spike_rates = cluster.num_spikes_delayed(this_ds)/...
		(dur - param.onsetWin/1000); % Uses the onset window from post_process

	if length(fpeaksi) == length(spike_rates)
		[rate,rate_std,~, rlb, rub] = accumstats({fpeaksi},spike_rates, rate_size);
		rates_sm = smooth_rates(rate, rlb, rub, CF);

		%[widths(ind,:), lims(ind,:)] = findHalfHeightWidth(fpeaks, rate, 0);
		%[widths_sm(ind,:), lims_sm(ind,:)] = findHalfHeightWidth(fpeaks, rates_sm, 0);
		
	else
		rate = [];
		rate_std = [];
		fpeaks = [];
		rates_sm = [];
		%width(ind) = 0;
		rub = [];
		rlb = [];
	end

	% Calculate predictable variance per No
	rate_matrix = zeros([param.nrep, num_fpeaks]);
	x = reshape(spike_rates, [num_fpeaks, param.nrep])';
	list_fi = reshape(fpeaksi, [num_fpeaks, param.nrep])';
	for irep = 1:param.nrep
		x_onerep = x(irep, :);
		fi_onerep = list_fi(irep,:);
		for j2 = 1:num_fpeaks
			k = fi_onerep == j2;
			rate_matrix(irep, j2) = x_onerep(k);
		end
	end
	[V_p, ~,~] = predictableVariance(rate_matrix, fpeaks);

	% Calculate PSTH
	stim_set = find(param.stims.dsid == ds);
	these_spikes = ismember(cluster.abs_stim_num,stim_set);
	t_spike_rel = cluster.t_spike_rel(these_spikes);
	rel_id = cluster.rel_id(these_spikes);
	[fpeaksis,order] = sort(fpeaksi);
	num_stim = length(fpeaksi);
	reps = zeros(num_stim,1);
	rep = zeros(num_stim,1);
	for ii = 1:num_fpeaks
		j = fpeaksis == ii;
		reps(j) = (1:sum(j))';
	end
	rep(order) = reps;
	for iii = 1:num_fpeaks
		j = fpeaksi == iii;
		xx = t_spike_rel(ismember(rel_id,find(j)));
		yy = rep(rel_id(ismember(rel_id,find(j))));
		spike_times{iii} = xx;  % save an array of spike times to a cell for all repetition of the stimulus
		spike_reps{iii} = yy;  % these tell you the rep for each spike time
	end

	% Create struct that contains processed data
	data{ind}.rate = rate;
	data{ind}.rate_std = rate_std;
	data{ind}.fpeaks = fpeaks;
	data{ind}.rates_sm = rates_sm;
	%data{ind}.widths = widths(ind,:);
	%data{ind}.widths_sm = widths_sm(ind,:);
	%data{ind}.lims = lims(ind,:);
	%data{ind}.lims_sm = lims_sm(ind,:);
	data{ind}.rub = rub;
	data{ind}.rlb = rlb;
	data{ind}.spl = param.spl;
	data{ind}.V_p = V_p;
	data{ind}.spike_times = spike_times;
	data{ind}.spike_reps = spike_reps;
end


end
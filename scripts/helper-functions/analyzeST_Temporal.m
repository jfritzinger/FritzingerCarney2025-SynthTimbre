function temporal = analyzeST_Temporal(param, data_ST)

num_fpeaks = length(param.fpeaks);
for i_fpeak = 1:num_fpeaks

	% Calculate rasters
	x = data_ST.spike_times{i_fpeak};
	y = data_ST.spike_reps{i_fpeak};
	valid = x<0.3e6;
	x = x(valid);
	y = y(valid);

	% PSTH and smoothed PSTH
	edges = linspace(0, 300000,501);
	[PSTH, t] = histcounts(x, edges);
	PSTH_smooth = smooth(PSTH);

	% Calculate period histogram
	% Cut off onset 
	freq = 200; % Stimulus frequency in Hz
	period = 1000 / freq; % Period in ms
	num_bins = 30; % Number of bins for histogram
	wrapped_times = mod(x/1000, period); % Wrap spike times to one period
	edges = linspace(0, period, num_bins+1); % Bin edges
	counts = histcounts(wrapped_times, edges); % Create histogram

	% Normalize counts to get firing rate (spikes/sec)
	% bin_width = period / num_bins; % Bin width in ms
	% firing_rate = counts / (30 * bin_width / 1000); % Normalize by trials and bin width

	% Example spike times (300 ms window, 200 Hz stimulus)
	spike_times = x/1000;

	% Exclude 50ms onset
    ind_exclude = spike_times<50;
	spike_times(spike_times<50) = [];
    rep_y = y(~ind_exclude);

	% Calculate vector strength
	period = 1000 / freq;
	phases = 2 * pi * mod(spike_times, period) / period;
	VS = abs(mean(exp(1i * phases)));
	if ~isempty(phases)
		p_value = circ_rtest(phases); % Rayleigh statistic (P < 0.01) %%%%%%%%%%%%%%%%%%%%%% commended out for cluster
	else
		p_value = NaN;
	end
	%vectors = exp(-1i*2*pi*200*spike_times/1000); % same equation
	%sync(j) = abs(mean(vectors)); % same equation

    % Calculate vector strength for each repetition 
    period = 1000 / freq;
    for i_rep = 1:param.nrep
        rep = rep_y==i_rep;
    	phases = 2 * pi * mod(spike_times(rep), period) / period;
    	VS_all(i_rep) = abs(mean(exp(1i * phases)));
    end
    temporal.VS_avg(i_fpeak) = mean(VS_all);
    temporal.VS_std(i_fpeak) = std(VS_all);

	period = 1000 / 400;
	phases = 2 * pi * mod(spike_times, period) / period;
	VS_400 = abs(mean(exp(1i * phases)));

	% Calculate phase locking to harmonics 
	for iharm = 1:10
		harm = freq+freq*(iharm-1);
		period = 1000 / harm; % Get period of each harmonic
		phases = 2 * pi * (mod(spike_times, period) / period);
		VS_harms(iharm) = abs(mean(exp(1i * phases)));
		if ~isempty(phases)
			p_value_harms(iharm) = circ_rtest(phases); % Rayleigh statistic (P < 0.01) %%%%%%%%%%%%%%%%%%%%%% commented out for cluster
		else
			p_value_harms(iharm) = NaN;
		end
		harms(iharm) = harm;
	end

	% Save outputs
	temporal.x{i_fpeak} = x;
	temporal.y{i_fpeak} = y;
	temporal.t = t/1000;
	temporal.PSTH(i_fpeak,:) = PSTH;
	temporal.PSTH_smooth(i_fpeak,:) = PSTH_smooth;
	temporal.p_hist(i_fpeak,:) = counts;
	temporal.t_hist = edges;
	temporal.VS(i_fpeak) = VS;
	temporal.VS_p(i_fpeak) = p_value;
	temporal.VS_400(i_fpeak) = VS_400;
	temporal.VS_harms(i_fpeak,:) = VS_harms;
	temporal.harms(i_fpeak,:) = harms;
	temporal.VS_p_harms(i_fpeak,:) = p_value_harms;
end

end
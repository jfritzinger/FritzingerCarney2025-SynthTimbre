function [rate, rates_sm, rate_std] = analyzeSTWindow(params, CF)

% Process data
param = params{1};
cluster = param.cluster;
ds = param.dsid;
stim = param.stims;

%
[fpeaks,~,fi] = unique([param.list.fpeak].');
num_fpeaks = length(fpeaks);

% Process spike timing 
stim_time_bins = [stim.times;[-1 2]*stim.times(end-1:end)];
[~,abs_stim_num] = histc(cluster.t_spike,stim_time_bins);
valid = abs_stim_num ~= 0;
t_spike_rel = zeros(size(cluster.t_spike));
t_spike_rel(valid) = cluster.t_spike(valid) - stim.times(abs_stim_num(valid));
rel_id = abs_stim_num;
rep = cell2mat({param.list.rep})';

% Bins
win_start = [50 200];
win_end = [150 300];
num_win = 2;

% Sort
for iwin = 1:num_win
	avg_rate_win = zeros(num_fpeaks, 1);
	std_rate_win = zeros(num_fpeaks, 1);
	for j2 = 1:num_fpeaks
		k = find(fi == j2);
		x = t_spike_rel(ismember(rel_id,k));
		y = rep(rel_id(ismember(rel_id,k)));
		x = x/1000; % ms
		win_y = y(x>win_start(iwin) & x<win_end(iwin));
		rate_win = histcounts(win_y,param.nrep);
		avg_rate_win(j2) = mean(rate_win)/0.05;
		std_rate_win(j2) = std(rate_win/0.05);
		lb(j2) = min(rate_win)/0.05;
		ub(j2) = max(rate_win)/0.05;

	end

	% Smooth
	rate(iwin, :) = avg_rate_win;
	rates_sm(iwin, :) = smooth_rates(avg_rate_win, lb, ub, CF);
	rate_std(iwin, :) = std_rate_win;
end

end
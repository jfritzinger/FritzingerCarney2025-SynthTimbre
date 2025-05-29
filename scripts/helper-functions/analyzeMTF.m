function data = analyzeMTF(param)

% Analysis
this_ds = param.stims.dsid==param.dsid;

if param.dur > 10
	dur = param.dur/1000; % stimulus duration in seconds.
else
	dur = param.dur;
end

all_mod_depths = double([param.list.mdepth]).';
all_mod_depths(all_mod_depths < -80) = max(all_mod_depths);
[~,~,mdi] = unique(all_mod_depths);
[fms,~,fmi] = unique(double([param.list.fm]).');
if fms(1) == 0
	fms(1) = 1.2;
end

num_mod_freqs = length(fms);
num_depths = length(param.all_mdepths);
map_size = [num_mod_freqs, num_depths];

spike_rates = param.cluster.num_spikes_delayed(this_ds)/...
	(dur - param.onsetWin/1000);

if length(fmi)==length(spike_rates)
	[rate,rate_std, ~, rlb, rub] = accumstats({fmi},spike_rates, map_size);
	%rlb = rate - rate_std;
	%rub = rate + rate_std;
	rate_sm = smooth_rates(rate, rlb, rub, []);
	%rate_sm2 = smooth(rate);
	%rate_sm = fit(fms,rate,'spline');
	[BMF,WMF,MTF_shape, at_100, at_200] = MTFclassification(spike_rates,fms, fmi);
end

% Option 1: Slope 
% slope = diff(rate_sm(2:end)) ./ diff(log10(fms(2:end)));
% [~, ind] = max(abs(slope));
% if rate(ind)-rate(1)>0
% 	max_slope = abs(slope(ind));
% else
% 	max_slope = -1*abs(slope(ind)); 
% end

% Option 2: Z-score 
% rate_z = (rate(2:end) - rate(1))./std(rate(2:end));
% [~, ind2] = max(abs(rate_z));
% rate_diff = rate_z(ind2);

% Option 3: Index
%mod_index = max(abs((rate - rate(1))./(rate+ rate(1))));

% Option 4: Percentage 
% percent_change = (rate_sm-rate_sm(1))/rate_sm(1);
% max_change = max(abs(percent_change));

% Option 5: Percentage 
if strcmp(MTF_shape, 'BE')
	[~, ind] = max(rate_sm(2:end));
elseif strcmp(MTF_shape, 'BS')
	[~, ind] = min(rate_sm(2:end));
else
	rate_zero = rate_sm - rate_sm(1);
	[~, ind] = max(abs(rate_zero(2:end)));
end
max_rate = rate_sm(ind+1);
unmod = rate_sm(1);
max_change = (unmod - max_rate) / (unmod + max_rate);


data.fms = fms;
data.rate = rate;
data.rate_std = rate_std;
data.rlb = rlb;
data.rub = rub;
data.BMF = BMF;
data.WMF = WMF;
data.MTF_shape = MTF_shape;
data.at_100 = at_100;
data.at_200 = at_200;
data.rate_sm = rate_sm;
%data.max_slope = max_slope;
%data.slope_ind = [ind+1 ind+2];
%data.rate_diff = rate_diff;
%data.mod_index = mod_index;
data.perc_change = max_change;

end

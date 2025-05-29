function [peaks, dips, type, prom, width, lim, bounds_freq, ...
	halfheight, freq] = peakFinding(data_ST, CF, type, param)

if strcmp(type, 'Rate') % Z-score rate
	rate_sm = zscore(data_ST.rates_sm);
else % z-score VS
	temporal = analyzeST_Temporal(param, data_ST);
	num_fpeaks = length(param.fpeaks);
	rate_sm = zscore(smooth_rates(temporal.VS,zeros(num_fpeaks, 1),...
					ones(num_fpeaks, 1), CF));
end

% Cut down to +/- one octave range
hi_limit = CF*2;
lo_limit = CF/2;
indices = data_ST.fpeaks > lo_limit & data_ST.fpeaks < hi_limit;
fpeaks = data_ST.fpeaks(indices);
rates = rate_sm(indices);

% Find peak
[pks,locs,peak_w,peak_p] = findpeaks(rates,...
	fpeaks,'MinPeakProminence',0.25);

% Set peak outputs 
peaks.pks = pks;
peaks.locs = locs;
peaks.w = peak_w;
peaks.p = peak_p;

% Find dip
inv_rates = -1*rates;
[pks,locs,dip_w,dip_p] = findpeaks(inv_rates, ...
	fpeaks, 'MinPeakProminence',0.25);

% Set dip outputs 
dips.pks = pks;
dips.locs = locs;
dips.w = dip_w;
dips.p = dip_p;

% Find if peak/dip/flat near CF
if ~isempty(peaks.pks) && ~isempty(dips.pks)
	[~, index1] = min(abs(dips.locs-CF));
	[~, index2] = min(abs(peaks.locs-CF));
	closest = [dips.locs(index1) peaks.locs(index2)];
	[~, ind] = min(abs(closest-CF));
	if ind == 1
		type = 'Dip';
		prom = dips.p(index1);
		freq = dips.locs(index1);
		[width, lim, bounds_freq, halfheight] = findHalfHeightWidth2(data_ST.fpeaks, rate_sm.*-1, CF, freq, 0);
		halfheight = -1*halfheight;
		
	elseif ind == 2
		type = 'Peak';
		prom = peaks.p(index2);
		freq = peaks.locs(index2);
		[width, lim, bounds_freq, halfheight] = findHalfHeightWidth2(data_ST.fpeaks, rate_sm, CF, freq,0);
	end
elseif ~isempty(peaks.pks)
	type = 'Peak';
	[~, index] = min(abs(peaks.locs-CF));
	freq = peaks.locs(index);
	prom = peaks.p(index);
	[width, lim, bounds_freq, halfheight] = findHalfHeightWidth2(data_ST.fpeaks, rate_sm, CF,freq, 0);

elseif ~isempty(dips.pks)
	type = 'Dip';
	[~, index] = min(abs(dips.locs-CF));
	freq = dips.locs(index);
	prom = dips.p(index);
	[width, lim, bounds_freq, halfheight] = findHalfHeightWidth2(data_ST.fpeaks, rate_sm.*-1, CF,freq, 0);
	halfheight = -1*halfheight;
else
	type = 'Flat';
	width = 0;
	lim = NaN;
	prom = 0;
	bounds_freq = [0,0];
	halfheight = 0;
	freq = 0;
end

end
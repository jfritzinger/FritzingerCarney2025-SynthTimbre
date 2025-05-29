function [width, lim, bounds_freq, halfHeight] = findHalfHeightWidth2(fpeaks, rate, CF, peak_loc, plot_on)
%
% Function that calculates the bandwidth of a synthetic timbre average rate
% plot for 50%, 25%, and 10% below the peak rate. 
%
%
% Author: J. Fritzinger
% Created: -----; Last revision: 2024-10-21
%
% ------------------------------------------------------------------------- 

% Interpolate 
fpeaks_interp = logspace(log10(fpeaks(1)), log10(fpeaks(end)), 100000); % new fpeaks array
rate_interp = interp1(fpeaks,rate,fpeaks_interp,'linear'); % interpolates rate
min_rate = min(rate_interp);

% Find peak within +/- 1 octave of CF 
% hi_limit = CF*2;
% lo_limit = CF/2;
% indices = fpeaks_interp > lo_limit & fpeaks_interp < hi_limit;
% rates = rate_interp(indices);
% freqs = fpeaks_interp(indices);
% [max_rate, ind] = max(rates);
% freq_max = freqs(ind);
%peak_ind = find(freq_max == fpeaks_interp);
[~, peak_ind] = min(abs(peak_loc-fpeaks_interp));
max_rate = rate_interp(peak_ind);

%%%%%%%%%%%%%% 25% from 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%halfHeight = max_rate*0.75;

%%%%%%%%%%%%%% z units below peak %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
halfHeight = max_rate-0.75;

%%%%%%%%%%%%%% 25% below peak referenced to min value %%%%%%%%%%%%%%%
%halfHeight = ((max_rate-min_rate)*0.75)-abs(min_rate);

%%%%%%%%%%%%%% Algorithm %%%%%%%%%%%%%%%
zeroed = rate_interp-halfHeight;
x = diff(sign(zeroed));
indx = find(x~=0);

ind_above = find(indx>peak_ind, 1, 'first'); % Find high freq edge
if isempty(ind_above)
    x1 = fpeaks_interp(end);
else
    x1 = fpeaks_interp(indx(ind_above));
end
    
ind_below = find(indx<peak_ind, 1, 'last'); % Find low freq edge 
if isempty(ind_below)
    x2 = fpeaks_interp(1);
else
    x2 = fpeaks_interp(indx(ind_below));
end
width = x1 - x2; % Compute the full width, half max.
if isempty(ind_below) || isempty(ind_above)
	lim = 1;
else
	lim = 0;
end
bounds_freq = [x1, x2];


%%%%%%%%%%%%%%% PLOT %%%%%%%%%%%%%
if plot_on == 1
    hold on
    yline(0)
    plot(fpeaks_interp/1000, rate_interp,'LineWidth', 1.5)
    yline(halfHeight, 'Color', 'g', 'LineWidth', 1.5);
	scatter(fpeaks_interp(peak_ind)/1000, max_rate, 'r', 'LineWidth',1.5)
	line([x1/1000, x1/1000], [0, rate_interp(indx(ind_above))], 'Color', 'r', 'LineWidth', 1.5);
    line([x2/1000, x2/1000], [0, rate_interp(indx(ind_below))], 'Color', 'r', 'LineWidth', 1.5);
	xline(CF/1000, '--')
	caption = sprintf('Full Width, Half Max = %.2f', width);
    title(caption);
	xlabel('Tone Freq. (kHz)')
	ylabel('Avg. Spike (sp/s)')
	xlim([fpeaks_interp(1)/1000 fpeaks_interp(end)/1000])
	box on
	grid on
end

end
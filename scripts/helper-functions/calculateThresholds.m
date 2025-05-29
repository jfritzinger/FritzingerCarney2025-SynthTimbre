function [threshold_percent, threshold, slope_rate, d_prime] = ...
	calculateThresholds(fpeaks, rate, rate_std, CF)

% Interpolate data to get finer sampling resolution
fpeaks_new = linspace(fpeaks(1), fpeaks(end), 600);
rate_new = interp1(fpeaks, rate, fpeaks_new, 'linear');
rate_std_new = interp1(fpeaks, rate_std, fpeaks_new, 'linear');

% Calculate threshold 
threshold_criterion = 1;
threshold_percent = NaN;
threshold = NaN;
slope_rate = NaN;
d_prime = NaN;
flag = 0;
for ii = 1:500
	for i = 1:length(fpeaks_new)-ii
		mean1 = rate_new(i);
		mean2 = rate_new(i+ii);
		std1 = rate_std_new(i);
		std2 = rate_std_new(i+ii);

		d_prime = abs(mean2 - mean1) / sqrt((std1^2 + std2^2) / 2);

		if d_prime >= threshold_criterion
			threshold = fpeaks_new([i, i+ii]);
			freq_diff = diff(threshold);
			fpeak_mid = threshold(1) + freq_diff/2;
			threshold_percent = freq_diff/fpeak_mid*100;
			slope_rate = [mean1 mean2];
			fprintf('d'' = %.2f\n', d_prime);
			disp(['Threshold = ' num2str(threshold_percent) '%'])
			flag = 1;
			break
		end
	end
	if flag == 1
		break
	end

end
end
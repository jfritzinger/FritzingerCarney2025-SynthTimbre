function [R2, avModel, stdModel, ratio, max_all] = modelTimbreSTRF(param, data_STRF, data, type)
% Function that uses STRF to predict responses to WBTIN
% J. Fritzinger, created 7/10/23

% Get STRF data 
STRF_mat = data_STRF.H2ex_strf-data_STRF.H2in_strf;
f = data_STRF.f;
f(f>16000) = [];
STRF_mat(length(f)+1:end, :) = [];

% Recreate stimulus
param.physio = 1;
[param] = generate_ST(param);

% Calculate the spectrogram of a stimulus
if type == 1
	windowLength = 200; %50; % Length of the analysis window (in samples)
	noverlap = 199; %49; % Overlap size between consecutive windows (in samples)
elseif type == 2
	windowLength = 50; % Length of the analysis window (in samples)
	noverlap = 49; % Overlap size between consecutive windows (in samples)
else
	windowLength = 200; %50; % Length of the analysis window (in samples)
	noverlap = 100; %49; % Overlap size between consecutive windows (in samples)
end
nfft = 960; % Length of the FFT

% Convolve STRF and the stimulus
num_stim = size(param.stim, 1);
all_avg_rate = zeros(1, num_stim);
for istim = 1:num_stim

	% Plot the spectrogram of a stimulus
	[S,freq, ~] = spectrogram(param.stim(istim, :), windowLength, noverlap, nfft, param.Fs);
	freq(freq>16000) = [];
	S(length(freq)+1:end, :) = [];
	S = abs(S);

	% Plot 

	% Convolve
	for ifreq = 1:length(freq)
		signal = S(ifreq,:);
		filter = STRF_mat(ifreq,:);
		conv1 = conv(signal, filter, 'same');
		convolution_result(ifreq,:) = conv1;
	end

	% Get PSTH & average rate
	psth = sum(convolution_result, 1);
	avg_rate = mean(psth);
	all_avg_rate(istim) = avg_rate;
end

[fpeaks,~,fi] = unique([param.mlist.fpeak].');
num_fpeaks = length(fpeaks);

rate_size = [num_fpeaks,1];
[avModel,stdModel,~,~] = accumstats({fi},all_avg_rate, rate_size);

% Model
max_rate = max(data.rate);
max_rate_m = max(avModel);
ratio =  max_rate/max_rate_m;
max_all = max([max_rate, max((avModel.*ratio))]);

% Measure prediction accuracy
R_int = corrcoef(avModel,data.rate);
R2 = R_int(1, 2).^2;

end

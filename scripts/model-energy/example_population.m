%% example_population.m
%
% Script that runs a basic energy model for a population response to a tone
% in wideband noise. 
%
% Author: J. Fritzinger
% Created: 2022-10-30; Last revision: 2024-10-30
%
% -------------------------------------------------------------------------
clear 

%% Generate Stimuli
CF = 1500;

% WB_noise
param.type = 'WB_noise';
param.version = 5;
param.fpeak_mid = CF;
param.ramp_dur = 0.01;
param.dur = 0.3;
param.reptim = 0.6;
param.CF = CF;
param.stp_oct = 0; % Set to 0 for single stimulus
param.bandwidth = 4;
param.No = 40;
param.SNR = [20 30 40]; %[20 30 40];
param.range = 3;
param.nrep = 20;
param.binmode = 2;
param.onsetWin = 25;
param.physio = 0;
param.Fs = 100000;
param.mnrep = 1; % 20
param = generate_WBTIN(param);

% NB_noise 
% param.SPEC_slide_type = 'NB_noise';
% param.ramp_dur = 0.01;
% param.dur =  0.300; %
% param.reptim = 0.600; % 50% duty cycle
% param.fpeak_mid = CF; % Estimated CF
% param.stp_otc = 0; % 6; % steps per octave, Set to 0 for single stimulus
% param.bandwidth = 0.333; % bandwidth in octaves
% param.No = 43; % No (dB SPL)
% param.SNRNo = [-inf 30 40]; % TIN SNR w.r.t. No, for tone at CF (-inf is no tone)
% param.mnrep = 1;
% param.physio = 0;
% param.Fs = 100000;
% param.CF = CF;
% [param] = generate_NBnoise(param);


%% Filter

CFs = logspace(log10(500), log10(5500), 100);
Fs = param.Fs;
stimulus = [param.stim zeros(size(param.stim,1),0.1*Fs)];
clear mdB;
gamma_param.srate = Fs;
tvals = (1:length(stimulus))/Fs;
gamma_IF_reg = zeros(length(CFs),length(tvals));
impaired = 0; % 0 = not impaired; 1 = 'impaired'


for iCF = 1:length(CFs)
	pin_gamma = zeros(size(stimulus, 1), Fs*param.dur+0.1*Fs);

	for istim = 1:size(stimulus, 1)
		gamma_param.fc = CFs(iCF); % CF
		pin_gamma(istim,:) = gamma_filt(stimulus(istim,:),gamma_param,impaired, 1);
		% [~,peak_indices_gamma] = findpeaks(diff(pin_gamma(istim,:))); % Find intervals between zero-crossings
		% % gamma_IF_irreg = (1./diff(peak_indices_gamma/Fs)) - CFs(iCF); % save IF RELATIVE to CF << for plotting
		% gamma_IF_irreg = 1./diff(peak_indices_gamma/Fs); % save IF RELATIVE to CF
		% %%%%%%%%%%subplot(4,1,4); plot(peak_indices_gamma(2:end)/Fs,gamma_IF,'r'); xlim([0 dur])
		% irreg_vals = peak_indices_gamma(2:end)/Fs; % irregularly spaced time values
		% gamma_IF_reg = interp1(irreg_vals,gamma_IF_irreg,tvals,'spline'); % Interpolate to get equally spaced points
		% gamma_Fm_reg = Fs * diff( gamma_IF_reg); % Convert IF estimate to Fm estimate (dF/dt)
		% gamma_Fm_reg_norm = Fs * diff( gamma_IF_reg)/CFs(iCF); % dF/dt, normalized by CF

		% Analysis
		y2 = fft(stimulus(istim,:));
		m = abs(y2);
		mdB = 20*log10(m);
		f = (0:length(y2)-1)*Fs/length(y2);
		mdB(mdB<0) = 0;
		f(f>Fs/2) = [];
		mdB = mdB(1:length(f));

		% % Plot
		% figure
		% tiledlayout(1, 2)
		% nexttile
		% semilogx(f,mdB);
		% xlim([50 10000])
		% %ylim([0 40])
		% grid on
		% set(gca, 'XScale', 'log')
		% xlabel('Frequency (Hz)')
		% ylabel('Magnitude (dB SPL)')
		% xticks([100 200 500 1000 2000 5000 10000 20000])
		% box on
		% title('Stimulus Spectrum')
		% 
		% % Analysis
		% y2 = fft(pin_gamma(istim,:));
		% m = abs(y2);
		% mdB_gamma = 20*log10(m);
		% f = (0:length(y2)-1)*Fs/length(y2);
		% mdB_gamma(mdB_gamma<0) = 0;
		% f(f>Fs/2) = [];
		% mag_dB(istim,:) = mdB_gamma(1:length(f));
		% 
		% % Plot
		% nexttile;
		% semilogx(f,mag_dB(istim,:));
		% xlim([50 10000])
		% %ylim([0 70])
		% grid on
		% set(gca, 'XScale', 'log')
		% xlabel('Frequency (Hz)')
		% ylabel('Magnitude (dB SPL)')
		% xticks([100 200 500 1000 2000 5000 10000 20000])
		% box on
		% title('Gamma Filtered')

	end
	pin_gamma = pin_gamma(:,1:param.dur*Fs);
	rms_filt(iCF, :) = sqrt(mean(pin_gamma.^2,2));
end

%% Plot population

figure;
tiledlayout(2, 1)

% Plot Spectrum
nexttile
y2 = fft(stimulus(istim,:));
m = abs(y2);
mdB = 20*log10(m);
f = (0:length(y2)-1)*Fs/length(y2);
mdB(mdB<0) = 0;
f(f>Fs/2) = [];
mdB = mdB(1:length(f));
semilogx(f,mdB);
xlim([500 5000])
%ylim([0 60])
grid on
set(gca, 'XScale', 'log')
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB SPL)')
xticks([100 200 500 1000 2000 5000 10000 20000])
set(gca, 'fontsize', 12)
title('WB-TIN Stimulus Spectrum')
box on

% Plot Energy Response
nexttile
hold on
plot(CFs, rms_filt(:, 4), 'LineWidth',2);
plot(CFs, rms_filt(:, 5), 'LineWidth',2);
plot(CFs, rms_filt(:, 6), 'LineWidth',2);
plot(CFs, rms_filt(:,1),'Color','k', 'linewidth', 1, 'LineStyle','--');
xlim([CFs(1) CFs(end)]);
set(gca, 'XScale', 'log');
ylabel('RMS','fontsize',12)
title('WB-TIN, Gammatone Filterbank','fontsize', 12)
xlabel('Frequency (Hz)')
xlim([500 5000])
xticks([100 200 500 1000 2000 5000 10000 20000])
set(gca, 'fontsize', 12)
legend({'SNR = 20', 'SNR = 30', 'SNR = 40', 'Noise Alone'})
box on
grid on
hold off

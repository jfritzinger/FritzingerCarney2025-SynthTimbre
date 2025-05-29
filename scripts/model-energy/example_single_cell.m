%% example_single_cell.m
%
% Script that runs a basic energy model for a single CF response to tones
% in wideband noise (thesis stimuli)
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
param.stp_oct = 6; % Set to 0 for single stimulus
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


%% Filter

CFs = CF;
%CFs = logspace(log10(500), log10(5500), 100);
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


%% Plot single-cell

% Analysis
[SNRs,~,si] = unique([param.mlist.SNR].');
num_SNRs = length(SNRs);

[fpeaks,~,fi] = unique([param.mlist.fpeak].');
num_fpeaks = length(fpeaks);

rate_size = [num_fpeaks,num_SNRs];
[avBE,stdBE,~,~] = accumstats({fi,si},rms_filt, rate_size);
freqs = repmat(fpeaks, 1, length(SNRs));

% Plot 
figure;
hold on
errorbar(freqs/1000,avBE,stdBE, 'LineWidth',2);
yline(mean(avBE(1)),'Color','k', 'LineWidth',2);
xline(param.CF/1000, '--', 'Color', [0.5 0.5 0.5], 'LineWidth',2);
hold off
xlabel('Tone Frequency (kHz)')
ylabel('RMS')
set(gca, 'XScale', 'log');
grid on
box on
xlim([param.fpeaks(2) param.fpeaks(end)]/1000);
xlim([841 3000]./1000)
axis_set = axis;
axis_set(3) = 0;
axis(axis_set);
set(gca, 'fontsize', 12)
title('NB-TIN Single-Cell Gammatone Filter')

for ii = 1:num_SNRs
    leg{ii,:} = [num2str(round(SNRs(ii),1)) ' dB SNR'];
end
leg{ii+1, :} = 'Noise Alone';
leg{ii+2,:} = 'CF';
hLegend = legend(leg, 'location', 'best', 'Fontsize', 12);
hLegend.ItemTokenSize = [8,8];


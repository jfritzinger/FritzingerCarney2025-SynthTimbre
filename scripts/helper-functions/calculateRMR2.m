function [R2_temp, BF_spl, rate_RM_temp] = calculateRMR2(params_ST, data_ST, data_RM)

% Find BF nearest to WBTIN overall level
overall_spl = params_ST.spl;
[~,iBF] = min(abs(data_RM.SPL-overall_spl));
BF_spl = data_RM.SPL(iBF);

% Interpolate RM rate
rate_ST = data_ST.rate;
fpeaks = data_ST.fpeaks;
freqs_interp = logspace(log10(fpeaks(1)), log10(fpeaks(end)), 50);
rate_interp_ST = interp1(fpeaks,rate_ST,freqs_interp,'pchip'); % interpolates rate


rate_RM = data_RM.rates(:,iBF);
freqs_mid = logspace(log10(data_RM.freqs(1)), log10(data_RM.freqs(end)), 10000);
rate_mid_RM = interp1(data_RM.freqs,rate_RM,freqs_mid,'pchip'); % interpolates rate

% Uses interpolated WB-TIN
[~, starting] = min(abs(freqs_mid-freqs_interp(1)));
[~, ending] = min(abs(freqs_mid-freqs_interp(end)));
rate_interp_RM = interp1(freqs_mid(starting:ending),rate_mid_RM(starting:ending),freqs_interp,'pchip'); % interpolates rate

% Calculate correlation coefficient & variance explained
R_int = corrcoef(rate_interp_RM,rate_interp_ST);
R2 = R_int(1, 2).^2;

% Uses raw WB-TIN
[~, starting] = min(abs(freqs_mid-fpeaks(1)));
[~, ending] = min(abs(freqs_mid-fpeaks(end)));
rate_RM_temp = interp1(freqs_mid(starting:ending),rate_mid_RM(starting:ending),fpeaks, 'pchip');

% Calculate correlation coefficient & variance explained
R_int = corrcoef(rate_RM_temp,rate_ST);
R2_temp = R_int(1, 2).^2;

%% Plot 
% 
% figure
% plot(fpeaks, rate_ST)
% hold on
% plot(data_RM.freqs, rate_RM)
% plot(fpeaks, rate_RM_temp)


end
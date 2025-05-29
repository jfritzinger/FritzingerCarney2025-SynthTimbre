function [filtered, erbCF] = gamma_filt(unfiltered,stim,impaired, species)
% Code to call the gammatone filter
% Created 6/26/02 LHC, modified by davidson 03/18/03
% 4th-order gammatone filter, based on Human filter ERBs from Glasberg & Moore
% cf = center frequency of filter (Hz)
% fs = smaplign rate (samples/sec)
% impaired = 0 if "healthy" or a factor by which bandwidth will be
% broadened, for "impairment" (e.g. is this is set = to 2, the bandwidth of
% the gammatone filter will be doubled w.r.t healthy).

cf = stim.fc;
fs = stim.srate;
% The folowing line specifies Glasberg & Moore style erb's
erbCF = 24.7 * (4.37 * cf/1000 + 1);
if impaired ~= 0
	erbCF = impaired*erbCF; % quick 'impairment'
end

% For cat & Shera values - these are expressions from model_IHC.c c-code:
if species == 1 % Cat Q10 values
    Q10 = 10^(0.4708 * log10(cf / 1e3) + 0.4664);
elseif species == 2 % Human Q10 values from Shera et al. (PNAS 2002)
    Q10 = (cf / 1000)^0.3 * 12.7 * 0.505 + 0.2085;
elseif species == 3 % Human Q10 values from Glasberg & Moore (Hear. Res. 1990)
    Q10 = cf / 24.7 / (4.37 * (cf / 1000) + 1) * 0.505 + 0.2085;
end
erbCF = cf / Q10;

%This converts ERB to a gammatone tau, based on Patterson's
%conversion between Roex and gammatone
tau = 1./(2.*pi * 1.019 * erbCF);

%This calls the fileter in the function gammatone.m
[b1,a1] = gammatone(tau,4,cf,fs);
filtered = filter(b1,a1,unfiltered);

end

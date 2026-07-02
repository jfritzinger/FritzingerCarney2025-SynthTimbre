function R = calcVS(params, spike_hist, fs)
t = linspace(0, 0.25, fs*0.25);
f = 200;
onsetwin = 0.05; % ms
for ii = 1:100
	r = spike_hist(ii, onsetwin*fs:params.dur*fs-1);
	R(ii) = abs(1/sum(r) * sum(r .* exp(1i * 2*pi * f .* t)));
end
end
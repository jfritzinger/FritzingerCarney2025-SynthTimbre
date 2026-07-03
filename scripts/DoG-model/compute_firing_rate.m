function r = compute_firing_rate(stim, Fs, W, f, r0)
% Function to compute firing rate

N = length(stim);
X = fft(stim);
P = abs(X/N).^2;
P = P(1:N/2+1);
P(2:end-1) = 2*P(2:end-1);

f_signal = (0:(N/2))*Fs/N;
P_interp = interp1(f_signal, P, f, 'linear', 0);

r = sum(W .* P_interp) + r0;
r = max(r, 0); % Half-wave rectification

end
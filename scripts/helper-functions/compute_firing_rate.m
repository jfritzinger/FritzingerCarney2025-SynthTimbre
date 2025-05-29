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

	% figure; hold on
	% plot(f, P_interp)
	% plot(f, W)
	% ylim([0 0.0006])
	% xlim([0 2000])
	% disp(['Max P_interp: ', num2str(max(P_interp))]);
    % disp(['Max W: ', num2str(max(W))]);
    % disp(['Sum of W * P_interp: ', num2str(sum(W .* P_interp))]);
end
function W = dog_model(fpeaks, params)

% Difference of Gaussians (DoG) model

	% excGauss = ge * exp(-(f - fc).^2 / (2 * sigma_e^2));
	% inhGauss = gi * exp(-(f - fc).^2 / (2 * sigma_i^2));
    % W = excGauss - inhGauss;

	% Set Parameters
	if length(params)==6
		s_exc = params(1)*1000;
		s_inh = params(2)*1000;
		sigma_exc = 10^params(3);
		sigma_inh = 10^params(4);
		CF_exc = 10^params(5);
		CF_inh = 10^params(6);
		gauss_exc = normpdf(fpeaks, CF_exc, sigma_exc);
		gauss_inh = normpdf(fpeaks, CF_inh, sigma_inh);
		gauss_exc = s_exc*(gauss_exc./max(gauss_exc));
		gauss_inh = s_inh*(gauss_inh./max(gauss_inh));
		W = gauss_exc - gauss_inh;
	else
		s_exc = params(1)*1000;
		s_inh = params(2)*1000;
		sigma_exc = 10^params(3);
		sigma_inh = 10^params(4);
		CF = 10^params(5);
		gauss_exc = normpdf(fpeaks, CF, sigma_exc);
		gauss_inh = normpdf(fpeaks, CF, sigma_inh);
		gauss_exc = s_exc*(gauss_exc./max(gauss_exc));
		gauss_inh = s_inh*(gauss_inh./max(gauss_inh));
		W = gauss_exc - gauss_inh;
	end

	% Plot to test 
	% figure
	% plot(gauss_exc)
	% hold on
	% plot(-1*gauss_inh)
	% plot(W)
	% xlim([0 10000])
end
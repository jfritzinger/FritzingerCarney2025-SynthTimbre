function W = gaussian_model(f, params)
% Create Gaussian function

fc = 10^params(1);
sigma = 10^params(2);
g = params(3)*1000;
W = g * exp(-(f - fc).^2 / (2 * sigma^2));

end


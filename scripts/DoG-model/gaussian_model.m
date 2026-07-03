function W = gaussian_model(f, fc, sigma, g)
% Create Gaussian function

W = g * exp(-(f - fc).^2 / (2 * sigma^2));
end


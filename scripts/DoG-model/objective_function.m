function distance = objective_function(params, model, Fs, stim, observed_rate, r0, type)

f = linspace(0, Fs/2, 100000);
if strcmp(model, 'gaussian')
    fc = 10^params(1);
    sigma = 10^params(2);
    g = params(3);
    W = gaussian_model(f, fc, sigma, g);
else % DoG model
    W = dog_model(f, params);
end

nstim = size(stim, 1);
predicted_rate = zeros(nstim, 1);
for i = 1:nstim
    predicted_rate(i) = compute_firing_rate(stim(i, :), Fs, W, f, r0);
end

if type == 1 % Distance
    distance = sum(abs(predicted_rate - observed_rate)); % City-block distance
else % MSE
    distance = 1/length(observed_rate) * sum((observed_rate - predicted_rate).^2); % Compute the mean of the squared errors
end

end
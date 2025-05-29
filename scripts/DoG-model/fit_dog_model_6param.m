function dog_params = fit_dog_model_6param(nrep, CF, Fs, stim, observed_rate, r0)
% Fit Difference of Gaussians (DoG) model with modularized code
% Inputs:
%   nrep           - Number of repetitions for optimization
%   log_CF         - Logarithmic center frequency
%   Fs             - Sampling frequency
%   stim           - Stimulus data
%   observed_rate  - Observed rate data
%   r0             - Baseline firing rate
%
% Output:
%   dog_params     - Optimized DoG model parameters

% Timer to measure execution time
timerVal = tic;

% Convert CF to logarithmic scale
log_CF = log10(CF); 

% Define parameter bounds
param_bounds = struct( ...
	'lb', [0.1, 0.1, 1, 1, log_CF-1, log_CF-1], ...
	'ub', [10, 10, 3, 3, log_CF+1, log_CF+1]);


best_fval = Inf; % Initialize best objective function value
for istarts = 1:nrep

	% Randomize initial parameters
	init_guess = param_bounds.lb(1:4) + ...
		(param_bounds.ub(1:4) - param_bounds.lb(1:4)) .* rand(1, 4);
	init_guess_CF = [log_CF, log_CF];
	dog_init = [init_guess, init_guess_CF];

	% Perform optimization using fmincon
	options = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
		'TolX', 1e-15, 'MaxFunEvals', 10^15, ...
		'MaxIterations', 400, 'ConstraintTolerance', 1e-6, ...
		'StepTolerance', 1e-6, 'Display', 'off', ...
		'PlotFcn', {'optimplotfval', 'optimplotx'});

	[dog_params_iter, fval] = fmincon(@(p) ...
		objective_function(p, 'dog', Fs, stim, observed_rate, r0, 'dog'), ...
		dog_init, [], [], [], [], param_bounds.lb, param_bounds.ub, [], options);

	% Update best parameters if current fval is better
	if fval < best_fval
		best_x = dog_params_iter;
		best_fval = fval;
	end
end

%dog_params = best_x; % Return the best parameters
dog_params = best_x;
disp(['Model took ' num2str(toc(timerVal)) ' seconds']);
end



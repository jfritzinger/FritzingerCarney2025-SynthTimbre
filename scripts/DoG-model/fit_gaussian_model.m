function gaussian_params = fit_gaussian_model(nrep, CF, Fs, stim, observed_rate, r0)
% Fit Gaussian model with modularized code
% Inputs:
%   nrep           - Number of repetitions for optimization
%   CF             - Center frequency (not logarithmic)
%   Fs             - Sampling frequency
%   stim           - Stimulus data
%   observed_rate  - Observed rate data
%   r0             - Baseline firing rate
%   type           - Type of model (e.g., 'gaussian')
%
% Output:
%   gaussian_params - Optimized Gaussian model parameters

% Timer to measure execution time
timerVal = tic;

log_CF = log10(CF); % Convert CF to logarithmic scale

% Define parameter bounds and initial guess generator
param_bounds = struct( ...
	'lb', [log_CF-1, 1, 0], ...       % Lower bounds [log_CF, sigma, gain]
	'ub', [log_CF+1, 4, 10] ...      % Upper bounds [log_CF, sigma, gain]
	);

best_fval = Inf; % Initialize best objective function value
for istarts = 1:nrep

	% Generate random initial guesses for first four parameters (g_exc, g_inh, s_exc, s_inh)
	init_guess_S_sig = param_bounds.lb(2:3) + (param_bounds.ub(2:3) - param_bounds.lb(2:3)) .* rand(1, 2);
	init_guess = [log_CF, init_guess_S_sig];

	% Perform optimization using fmincon
	options = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
		'TolX', 1e-10, 'MaxFunEvals', 10^10, ...
		'MaxIterations', 500, 'ConstraintTolerance', 1e-6, ...
		'StepTolerance', 1e-6, 'Display', 'off', ...
		'PlotFcn', {'optimplotfval', 'optimplotx'});

	[gaussian_params_iter, fval] = fmincon(@(p) ...
		objective_function(p, 'gaussian', Fs, stim, observed_rate, r0, 'gaussian'), ...
		init_guess, [], [], [], [], param_bounds.lb, param_bounds.ub, [], options);

	% Update best parameters if current fval is better
	if fval < best_fval
		best_x = gaussian_params_iter;
		best_fval = fval;
	end
end

gaussian_params = best_x; % Return the best parameters

disp(['Gaussian model took ' num2str(toc(timerVal)) ' seconds']);
end
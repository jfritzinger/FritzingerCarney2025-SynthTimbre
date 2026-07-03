function dog_params = fit_dog_model(nrep, CF, Fs, stim, observed_rate, r0, speed)
% Fit Difference of Gaussians (DoG) model with modularized code
% Inputs:
%   nrep           - Number of repetitions for optimization (only used in
%					 fast option
%   CF			   - CF of the neuron 
%   Fs             - Sampling frequency
%   stim           - Stimulus data
%   observed_rate  - Observed rate data
%   r0             - Spontaneous rate
%	speed		   - 'fast' or 'slow', 'fast' repeats fit with random
%					 parameters nrep times, 'slow' uses global search to 
%					 find the global minimum. 'Slow' takes a long time 
%					(504 seconds vs 94 seconds, for example. 
%
% Output:
%   dog_params     - Optimized DoG model parameters
% 
% J. Fritzinger, updated 4/11/25

% Timer to measure execution time
timerVal = tic;

% Convert CF to logarithmic scale
log_CF = log10(CF);

% Define parameter bounds
param_bounds = struct(...
	'lb', [0.1, 0.1, 1.2, 1.2, log_CF-0.3], ...
	'ub', [50, 50, 4, 4, log_CF+0.3]);

if strcmp(speed, 'slow')
	%% Global search to find optimal minimum

	% Randomize initial parameters
	init_guess = param_bounds.lb(1:4) + ...
		(param_bounds.ub(1:4) - param_bounds.lb(1:4)) .* rand(1, 4);
	dog_init = [init_guess, log_CF];

	% Define the problem (same as above)
	opts = optimoptions('fmincon', 'Algorithm', 'interior-point', 'Display', 'off'); %, ...
		%'PlotFcn', {'optimplotfval', 'optimplotx'});

	problem = createOptimProblem('fmincon', 'objective', ...
		@(p) objective_function(p, 'dog', Fs, stim, observed_rate, r0, 'dog'), 'x0', dog_init, ...
		'lb', param_bounds.lb, 'ub', param_bounds.ub, 'options', opts);

	% Run GlobalSearch
	gs = GlobalSearch;
	[x, fval] = run(gs, problem);
	disp(['Global minimum: ', num2str(fval)]);
	disp(['Optimal solution: ', mat2str(x)]);
	dog_params = x;
	disp(['Model took ' num2str(toc(timerVal)) ' seconds']);

else
	%% Search to find minimum, but may not be global - is faster though!

	best_fval = Inf; % Initialize best objective function value
	for istarts = 1:nrep

		% Randomize initial parameters
		init_guess = param_bounds.lb(1:4) + ...
			(param_bounds.ub(1:4) - param_bounds.lb(1:4)) .* rand(1, 4);
		dog_init = [init_guess, log_CF];

		% Perform optimization using fmincon
		options = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
			'TolX', 1e-6, 'MaxFunEvals', 10^6, ...
			'MaxIterations', 400, 'ConstraintTolerance', 1e-6, ...
			'StepTolerance', 1e-6, 'Display', 'off'); %, ...
			%'PlotFcn', {'optimplotfval', 'optimplotx'});

		[dog_params_iter, fval] = fmincon(@(p) ...
			objective_function(p, 'dog', Fs, stim, observed_rate, r0, 'dog'), ...
			dog_init, [], [], [], [], param_bounds.lb, param_bounds.ub, [], options);

		% Update best parameters if current fval is better
		if fval < best_fval
			best_x1 = dog_params_iter;
			best_fval = fval;
		end
	end

	% Perform optimization using fmincon
	best_fval = Inf; % Initialize best objective function value
	dog_init = best_x1;
	options = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
		'TolX', 1e-16, 'MaxFunEvals', 10^16, ...
		'MaxIterations', 400, 'ConstraintTolerance', 1e-16, ...
		'StepTolerance', 1e-16, 'Display', 'off'); %, ...
		%'PlotFcn', {'optimplotfval', 'optimplotx'});

	[dog_params_iter, fval] = fmincon(@(p) ...
		objective_function(p, 'dog', Fs, stim, observed_rate, r0, 'dog'), ...
		dog_init, [], [], [], [], param_bounds.lb, param_bounds.ub, [], options);

	% Update best parameters if current fval is better
	if fval < best_fval
		best_x = dog_params_iter;
		best_fval = fval;
	end
	dog_params = best_x; % Return the best parameters
	disp(['Model took ' num2str(toc(timerVal)) ' seconds']);
end
end



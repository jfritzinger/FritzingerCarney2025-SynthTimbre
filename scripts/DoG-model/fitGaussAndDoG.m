function [gaussian_params, dog_params, dog_params2] = fitGaussAndDoG(params, CF, Fs, observed_rate, r0)
% FITGAUSSANDDOG Fits Gaussian and Difference-of-Gaussians (DoG) receptive
% field models to observed neural firing rates using a multi-start fmincon approach.
%
% INPUTS:
%   params        - Cell array containing stimulus details (params{1}.stim)
%   CF            - Characteristic Frequency of the neuron
%   Fs            - Sampling frequency
%   observed_rate - The target neural firing rate to fit against
%   r0            - Baseline/spontaneous firing rate
%
% OUTPUTS:
%   gaussian_params - Optimized parameters for the Gaussian model [center, sigma, gain]
%   dog_params      - Optimized parameters for DoG Model 1 (independent CFs)
%   dog_params2     - Optimized parameters for DoG Model 2 (shared CF)

% --- Initialization & Setup ---
error_type = 2; % 1: Distance-based error, 2: Mean Squared Error (MSE)
stim = params{1}.stim;
log_CF = log10(CF);
timerVal = tic;

% =========================================================================
% 1. FIT GAUSSIAN MODEL (15 multi-starts)
% =========================================================================
best_fval = Inf;
best_gauss_x = [];

% Define optimization options outside the loop to prevent overhead
gauss_options = optimoptions('fmincon', 'Algorithm', 'sqp', ...
    'TolX', 1e-10, 'MaxFunEvals', 10^10, 'MaxIterations', 500, ...
    'ConstraintTolerance', 1e-10, 'StepTolerance', 1e-10, 'Display', 'off');

for istarts = 1:15
    % Randomize initial guesses within realistic bounds
    s_init = 1 + (4 - 1) * rand(1);
    g_init = 1000 * rand(1);

    init = [log_CF, s_init, g_init];  % [Center (log_CF), Sigma, Gain]
    lb   = [log_CF-1, 1,    0];       % Lower bounds
    ub   = [log_CF+1, 4,    Inf];     % Upper bounds

    [gaussian_params, fval] = fmincon(@(p) ...
        objective_function(p, 'gaussian', Fs, stim, observed_rate, r0, error_type), ...
        init, [], [], [], [], lb, ub, [], gauss_options);

    % Track the global minimum across starts
    if fval < best_fval
        best_gauss_x = gaussian_params;
        best_fval = fval;
    end
end
gaussian_params = best_gauss_x;


% =========================================================================
% 2. FIT DOG MODEL 1 - Independent CFs (15 multi-starts)
% =========================================================================
best_fval = Inf;
best_dog_x = [];

dog_options = optimoptions('fmincon', 'Algorithm', 'sqp', ...
    'TolX', 1e-15, 'MaxFunEvals', 10^15, 'MaxIterations', 800, ...
    'ConstraintTolerance', 1e-15, 'StepTolerance', 1e-15, 'Display', 'off');

for istarts = 1:15
    % Randomize initial weights and widths
    g_exc_init = 100 + (100000 - 100) * rand(1);
    g_inh_init = 100 + (100000 - 100) * rand(1);
    s_exc_init = 1 + (4 - 1) * rand(1);
    s_inh_init = 1 + (4 - 1) * rand(1);

    % Vector: [g_exc, g_inh, s_exc, s_inh, CF_exc, CF_inh]
    dog_init = [g_exc_init, g_inh_init, s_exc_init, s_inh_init, log_CF, log_CF];
    dog_lb   = [100,        100,        1,          1,          log_CF-1, log_CF-1];
    dog_ub   = [100000,     100000,     4,          4,          log_CF+1, log_CF+1];

    [dog_params, fval] = fmincon(@(p) ...
        objective_function(p, 'dog', Fs, stim, observed_rate, r0, error_type), ...
        dog_init, [], [], [], [], dog_lb, dog_ub, [], dog_options);

    if fval < best_fval
        best_dog_x = dog_params;
        best_fval = fval;
    end
end
dog_params = best_dog_x;

disp(['Gaussian & DoG Model 1 optimization took ', num2str(toc(timerVal)), ' seconds.'])


% =========================================================================
% 3. FIT DOG MODEL 2 - Shared CF (50 multi-starts)
% =========================================================================
best_fval = Inf;
best_dog2_x = [];
timerVal2 = tic; % Reset timer specifically for the second model profile

for istarts = 1:50
    g_exc_init = 100 + (100000 - 100) * rand(1);
    g_inh_init = 100 + (100000 - 100) * rand(1);
    s_exc_init = 1 + (4 - 1) * rand(1);
    s_inh_init = 1 + (4 - 1) * rand(1);

    % Vector: [g_exc, g_inh, s_exc, s_inh, Shared_CF]
    % Note: Ensure your 'objective_function' natively handles 5 parameters for this variation.
    dog_init = [g_exc_init, g_inh_init, s_exc_init, s_inh_init, log_CF];
    dog_lb   = [100,        100,        1,          1,          log_CF-1];
    dog_ub   = [100000,     100000,     4,          4,          log_CF+1];

    [dog_params2, fval] = fmincon(@(p) ...
        objective_function(p, 'dog', Fs, stim, observed_rate, r0, error_type), ...
        dog_init, [], [], [], [], dog_lb, dog_ub, [], dog_options);

    if fval < best_fval
        best_dog2_x = dog_params2;
        best_fval = fval;
    end
end
dog_params2 = best_dog2_x;

disp(['DoG Model 2 optimization took ', num2str(toc(timerVal2)), ' seconds.'])

end
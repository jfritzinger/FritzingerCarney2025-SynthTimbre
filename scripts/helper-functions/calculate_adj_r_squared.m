function adj_r_squared = calculate_adj_r_squared(observed, predicted, n_params)
% Adjusted R^2 function

    n = length(observed);
    SSE = sum((observed - predicted).^2);
    SST = sum((observed - mean(observed)).^2);
    adj_r_squared = 1 - (SSE / (n - n_params - 1)) / (SST / (n - 1));
end

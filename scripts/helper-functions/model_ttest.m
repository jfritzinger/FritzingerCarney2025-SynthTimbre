function p_value = model_ttest(data, prediction1, prediction2)
% Assuming you have these variables:
% data: 40x1 vector of observed data
% gaussian_prediction: 40x1 vector of Gaussian model predictions
% dog_prediction: 40x1 vector of DoG model predictions

%mse_A = immse(data, prediction1);
%mse_B = immse(data, prediction2);
squared_errors_A = (data - prediction1).^2;
squared_errors_B = (data - prediction2).^2;
[~, p_value, ~, ~] = ttest(squared_errors_A, squared_errors_B);

end
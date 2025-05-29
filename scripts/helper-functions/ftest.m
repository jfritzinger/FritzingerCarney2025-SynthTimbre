function p_value = ftest(data, prediction1, prediction2)
% Assuming you have these variables:
% data: 40x1 vector of observed data
% gaussian_prediction: 40x1 vector of Gaussian model predictions
% dog_prediction: 40x1 vector of DoG model predictions

% Calculate RSS
RSS_gaussian = sum((data - prediction1).^2);
RSS_dog = sum((data - prediction2).^2);

% Degrees of freedom
df_gaussian = length(data) - 3;
df_dog = length(data) - 6;

% Calculate F-statistic
F = ((RSS_gaussian - RSS_dog) / (df_gaussian - df_dog)) / (RSS_dog / df_dog);

% Compute p-value
p_value = 1 - fcdf(F, df_gaussian - df_dog, df_dog);

% Display results
% fprintf('F-statistic: %.4f\n', F);
% fprintf('p-value: %.4e\n', p_value);

end
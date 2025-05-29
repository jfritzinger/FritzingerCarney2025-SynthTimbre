function [V_p, V_p2, V_p3] = predictableVariance(rate_matrix, fpeaks)

%% Predictable variance 
% J. Fritzinger, created 7/18/23

%% Method 1:
% Ahumada 1971, first-half last-half correlation
% Take even/odd reps and correlate them

num_reps = size(rate_matrix, 1);

odd = rate_matrix(1:2:num_reps, :);
rate_odd = mean(odd, 1);

even = rate_matrix(2:2:num_reps, :);
rate_even = mean(even, 1);

r12 = corrcoef(rate_even, rate_odd);
r12 = abs(r12(2, 1));
V_p = r12 / (r12 + 0.5*(1-r12));


%% Method 2: ANOVA 
% SNR and tone frequency are categorical variables 

fpeaks = fpeaks(:,1)';
[~,tbl,~] = anova1(rate_matrix, fpeaks, "off");
SSE = tbl{3,2};
SSR = tbl{2,2};
SST = tbl{4,2};
MSR = tbl{2,4};
MSE = tbl{3,4};

V_p3 = 1-(SSR/SST);
V_p2 = (MSR-MSE)/MSR;


end
function [threshold_percent, threshold, d_prime_val] = calculate_SPIKE_Thresholds(fpeaks, RI_S_dist, reps)
num_f = length(fpeaks);

% 1. FORCE SYMMETRY (Fixes the "half-zeros" issue)
RI_S_dist = RI_S_dist' + RI_S_dist;

% 2. Calculate TRUE Noise and Signal
mean_dist_matrix = zeros(num_f, num_f);
std_within = zeros(1, num_f);

for i = 1:num_f
    idx1 = (i-1)*reps + (1:reps);

    % Extract the WITHIN-frequency block
    within_block = RI_S_dist(idx1, idx1);
    unique_within_dists = within_block(triu(true(reps), 1));

    % This is your ACTUAL noise floor 
    mean_dist_matrix(i,i) = mean(unique_within_dists, 'omitnan');
    std_within(i) = std(unique_within_dists, 'omitnan');

    for j = i+1:num_f
        idx2 = (j-1)*reps + (1:reps);
        between_block = RI_S_dist(idx1, idx2);
        val = mean(between_block(:), 'omitnan');
        mean_dist_matrix(i,j) = val;
        mean_dist_matrix(j,i) = val; % Mirror it
    end
end

% 3. INTERPOLATE (Now using 600 points of VALID data)
fpeaks_new = linspace(fpeaks(1), fpeaks(end), 600);
[X, Y] = meshgrid(fpeaks, fpeaks);
[Xq, Yq] = meshgrid(fpeaks_new, fpeaks_new);

dist_interp = interp2(X, Y, mean_dist_matrix, Xq, Yq, 'linear');
std_interp = interp1(fpeaks, std_within, fpeaks_new, 'linear');

% 4. SEARCH (d' must be relative to the interpolated diagonal)
threshold_percent = NaN;
threshold = NaN;
threshold_criterion = 1;
flag = 0;
for ii = 1:500 % Delta
    for i = 1:length(fpeaks_new) - ii
        mu_noise = dist_interp(i, i);      % Internal Jitter Frequency A
        mu_signal = dist_interp(i, i+ii);  % Distance between A and B

        s_pooled = sqrt((std_interp(i)^2 + std_interp(i+ii)^2) / 2);

        % d' is the INCREASE in distance relative to jitter
        d_prime_val = (mu_signal - mu_noise) / s_pooled;

        if d_prime_val >= threshold_criterion
            threshold = fpeaks_new([i, i+ii]);
            threshold_percent = (diff(threshold) / mean(threshold)) * 100;
            disp(['SPIKE Threshold = ' num2str(threshold_percent) '%'])

            % Plot grid and std deviation
            num_f = length(fpeaks);
            [X, Y] = meshgrid(1:num_f, 1:num_f);
            std_matrix = zeros(num_f, num_f);
            for jj = 1:num_f
                for j = 1:num_f
                    std_matrix(jj,j) = sqrt((std_within(jj)^2 + std_within(j)^2) / 2);
                end
            end
            Z_mean = mean_dist_matrix;
            Z_upper = Z_mean + std_matrix;
            Z_lower = Z_mean - std_matrix;
            figure('Color', 'w');
            hold on;
            surf(X, Y, Z_lower, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', ...
                'FaceAlpha', 0.2, 'HandleVisibility', 'off');
            surf(X, Y, Z_upper, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', ...
                'FaceAlpha', 0.2, 'DisplayName', 'Pooled Jitter (\pm1 STD)');
            s = surf(X, Y, Z_mean, 'EdgeColor', 'none', 'FaceAlpha', 0.8, 'DisplayName', 'Mean SPIKE Distance');
            colormap(jet);
            colorbar;
            view(45, 30); % Set a good perspective angle
            grid on;
            axis tight;
            xlabel('Frequency Index i');
            ylabel('Frequency Index j');
            zlabel('SPIKE Distance');
            title('3D SPIKE-Distance with Pooled Uncertainty Envelope');
            legend('Location', 'northeast');

            flag = 1; break;
        end
    end
    if flag == 1, break; end
end
end


function [threshold_percent, threshold_freq, d_prime] = calculate_RIS_Metrics(param_ST, temporal, datapath, putative, CF)
    kk = 1;
    nfpeaks = length(param_ST{1}.fpeaks);
    nrep = param_ST{1}.nrep;
    rearr_trains = cell(1, nfpeaks * nrep);
    
    for iii = 1:nfpeaks
        rep = temporal.y{iii};
        spike_times = temporal.x{iii}/1000;
        for jj = 1:nrep
            ind_target = rep == jj;
            rearr_trains{kk} = spike_times(ind_target);
            kk = kk+1;
        end
    end

    num_trains = length(rearr_trains);
    total_pairs = num_trains * (num_trains - 1) / 2;
    dist_results = zeros(1, total_pairs);
    idx1_list = zeros(1, total_pairs);
    idx2_list = zeros(1, total_pairs);

    count = 1;
    for i = 1:(num_trains-1)
        for j = (i+1):num_trains
            idx1_list(count) = i;
            idx2_list(count) = j;
            count = count + 1;
        end
    end

    % Uses standard local multicore acceleration if parallel pool is active
    parfor p = 1:total_pairs
        i = idx1_list(p); j = idx2_list(p);
        train1 = rearr_trains{i}; train2 = rearr_trains{j};

        spikes = zeros(2, max([length(train2), length(train1)]));
        spikes(1, 1:length(train1)) = train1;
        spikes(2, 1:length(train2)) = train2;

        para = struct('tmin', 0, 'tmax', 300, 'dts', 1, 'select_measures', [0 0 1 0 0 0 0 0]);
        [spikes_proc, para_proc, ret] = SPIKY_check_spikes_parallel(spikes, para);

        if ret == 0
            try
                SPIKY_loop_results = SPIKY_loop_f_distances(spikes_proc, para_proc);
                dist_results(p) = SPIKY_loop_results.RI_SPIKE.matrix(1, 2);
            catch
                dist_results(p) = 0;
            end
        else
            dist_results(p) = 0;
        end
    end

    RI_S_dist = zeros(num_trains, num_trains);
    for p = 1:total_pairs
        RI_S_dist(idx1_list(p), idx2_list(p)) = dist_results(p);
    end

    savefile = fullfile(datapath, 'RIS_thresholds', [putative '_RIS.mat']);
    save(savefile, 'RI_S_dist', 'putative', 'param_ST', 'CF');

    [threshold_percent, threshold_freq, d_prime] = calculate_SPIKE_Thresholds(param_ST{1}.fpeaks, RI_S_dist, nrep);
end
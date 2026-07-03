function [spikes, d_para, ret] = SPIKY_check_spikes_parallel(spikes, d_para)
    ret = 0;
    % Since we are passing spikes and d_para directly, we skip the 
    % file-loading and GUI-interaction logic for speed and parallel safety.
    
    if ~isfield(d_para,'dts'), d_para.dts=[]; end
    if ~isfield(d_para,'tmin'), d_para.tmin=[]; end

    % Standard SPIKY conversion
    spikes = SPIKY_f_convert_matrix(spikes, d_para.dts, d_para.tmin);
    
    sizes = cellfun(@size, spikes, 'un', 0);
    mindim = cellfun(@min, sizes, 'un', 0);
    if (prod([mindim{:}]) == 1)
        spikes(cellfun('size', spikes, 1) > 1) = cellfun(@transpose, spikes(cellfun('size', spikes, 1) > 1), 'un', 0);
    end

    if ~isfield(d_para,'dts') || isempty(d_para.dts)
        d_para.dts = SPIKY_f_get_dt(unique([spikes{:}])');
    end
    
    if ~isfield(d_para,'max_total_spikes') || isempty(d_para.max_total_spikes)
        d_para.max_total_spikes = 100000;
    end

    % Adjust limits
    dummy = 0;
    if ~isfield(d_para,'tmin') || isempty(d_para.tmin), d_para.tmin = min([spikes{:}]); dummy = dummy + 1; end
    if ~isfield(d_para,'tmax') || isempty(d_para.tmax), d_para.tmax = max([spikes{:}]); dummy = dummy + 2; end
    if dummy == 3
        d_para.tmin = d_para.tmin - 0.001 * (d_para.tmax - d_para.tmin);
        d_para.tmax = d_para.tmax + 0.001 * (d_para.tmax - d_para.tmin);
    end

    d_para.tmin = round(d_para.tmin / d_para.dts) * d_para.dts;
    d_para.tmax = round(d_para.tmax / d_para.dts) * d_para.dts;

    % Filter spikes to limits
    for trac = 1:length(spikes)
        if ~isempty(d_para.tmin)
            spikes{trac} = spikes{trac}(spikes{trac} >= d_para.tmin - 1e-14);
        end
        if ~isempty(d_para.tmax)
            spikes{trac} = spikes{trac}(spikes{trac} <= d_para.tmax + 1e-14);
        end
        if ~isempty(d_para.dts)
            spikes{trac} = unique(round(spikes{trac} / d_para.dts) * d_para.dts);
        end
    end

    d_para.num_all_trains = length(spikes);
    d_para.num_trains = d_para.num_all_trains;
    d_para.preselect_trains = 1:d_para.num_trains;

    % Parallel-safe error checking (no msgbox)
    if d_para.num_trains < 2 || d_para.tmin >= d_para.tmax
        ret = 1;
        return;
    end

    num_spikes_count = cellfun('length', spikes);
    d_para.num_total_spikes = sum(num_spikes_count);
end
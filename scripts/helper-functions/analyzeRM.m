function data  = analyzeRM(params)

this_ds = params.stims.dsid==params.dsid;

[spls,~,si] = unique(double([params.list.spl]).');
num_spls = length(spls);
[freqs,~,fi] = unique(double([params.list.freq]).');
num_freqs = length(freqs);

rate_size = [num_freqs,num_spls];
num_spikes = params.cluster.num_spikes_peri(this_ds);
spike_rates = num_spikes*1000/params.dur; % spikes/sec

if length(si) == length(spike_rates)
    [rates,~,~,~] = accumstats({fi,si},spike_rates, rate_size);
	spont = mean(rates(:,1));  
end

data.rates = rates;
data.spont = spont;
data.freqs = freqs;
data.SPL = spls;

end
function data = analyzeSTRF(param)

if param.dur < 10
	dur = param.dur;
else
	dur = param.dur/1000; % stimulus duration in seconds.
end
cluster = param.cluster;

% Regenerate noise
fs = param.stims.fs;
xpts = floor(dur*fs);
b_bp = fir1(5000,param.bw/(fs/2));
gate = tukeywin(xpts,2*param.ramp_dur/dur); %raised cosine ramps
sc = 20e-6 * power(10,param.spl/20);

for iseed = 1:length(param.seed)
	rng(param.seed(iseed));
	noise = randn(xpts,1);
	noise = conv(noise,b_bp,'same');
	noise_mat(:,iseed) = noise*sc/rms(noise).*gate;
end

[noises,~,noisei] = unique(double([param.list.ind]).'); % noise IDs for reproducible noises
num_noises = length(noises);

% This method uses smoothed spike time
win = 0.02;
T_pts = win*fs;
h0 = zeros(1,num_noises);
h1 = zeros(num_noises,T_pts);
h2 = zeros(num_noises,T_pts,T_pts);
stim_mx = zeros(T_pts,xpts - T_pts);
window = gausswin(ceil(1e-3*fs),1.5); % 3 std


for istim = 1:num_noises
	stimi = noise_mat(:,istim).';

	bin_width = 1/fs*1e6; % convert to microsec
	stim_time_ind = find([param.list.ind] == istim);
	stim_time_onset = param.stims.times(stim_time_ind);
	stim_time_offset = stim_time_onset+dur*1e6;
	psth_edges = 0:bin_width:dur*1e6;
	spktrains = zeros(length(psth_edges),length(stim_time_ind));
	for itime = 1:length(stim_time_ind)
		spk_ind_this = find(cluster.t_spike >= stim_time_onset(itime) & ...
			cluster.t_spike <= stim_time_offset(itime));
		spk_time = cluster.t_spike(spk_ind_this) - stim_time_onset(itime);
		spktrains(:,itime) = histc(spk_time,psth_edges);
	end
	response = sum(spktrains,2).';
	response = conv(response(T_pts + 1:end-1),window,'same');

	for T = 0:T_pts - 1
		stim_mx(T + 1,:) = stimi((T_pts + 1:end) - T);
	end
	h0(istim) = mean(response);
	h1(istim,:) = response*stim_mx';
	h2(istim,:,:) = bsxfun(@times,response - mean(response),stim_mx)*stim_mx';
end

H0 = mean(h0);
H1 = mean(h1)./sc./length(response);
H2 = reshape(mean(h2),T_pts,T_pts)./(2*sc.^2)./length(response);

fn = fs/2;

tlims = [0 T_pts/fs];
t = (0:T_pts - 1)/fs;
f = fn*linspace(0,1,T_pts/2 + 1);

% Process kernels and plot
[U,S,V] = svd(H2);
k = sign(diag(U).*diag(V)).*diag(S);	% weights for the singular vectors (see Lewis et al. 2002)
negInd = find(k<0);						% column indices of the negatively-weighted singular vectors
posInd = find(k>=0);					% column indices of the positively weighted singular vectors
U = repmat(abs(k'),T_pts,1).*U;			% The weighted vectors
U_fft = 2*abs(fft(U)/T_pts);
U_fft = U_fft(1:T_pts/2 + 1,:);
H2ex = U(:,posInd)*V(:,posInd)';
H2in = U(:,negInd)*V(:,negInd)';
H2 = H2ex + H2in;
env = abs(hilbert(U));

negInd2 = negInd(1:4);
posInd2 = posInd(1:4);

H1_fft = 2*abs(fft(H1)/T_pts);
H1_fft = H1_fft(1:T_pts/2 + 1);

H2ex_strf = 2*abs(fft(H2ex)/T_pts);
H2ex_strf = H2ex_strf(1:T_pts/2 + 1,:);
H2ex_strf_null = median(reshape(H2ex_strf(:,t<0.0025),1,[]));
H2ex_strf = H2ex_strf - H2ex_strf_null;

H2in_strf = 2*abs(fft(H2in)/T_pts);
H2in_strf = H2in_strf(1:T_pts/2 + 1,:);
H2in_strf_null = median(reshape(H2in_strf(:,t<0.0025),1,[]));
H2in_strf = H2in_strf - H2in_strf_null;

clims_strf = max(max(abs([H2ex_strf,H2in_strf])))*[-1 1];

% Get x limits
pos_max = [db(U_fft(:,posInd2)) db(U_fft(:,negInd2))];
yaxes_lim = -40 + max(max(db(U_fft)));
[ind, ~] = find(pos_max > yaxes_lim);
max_ind = max(ind);
f_max = f(max_ind);
flims = [0 f_max+50];

% Create struct that contains processed data
data.t = t;
data.f = f;
data.H2ex_strf = H2ex_strf;
data.H2in_strf = H2in_strf;
data.clims_strf = clims_strf;
data.tlims = tlims;
data.flims = flims;
data.strf = H2ex_strf-H2in_strf;
data.U = U;
data.S = S;
data.V = V;
data.H0 = H0;
data.H1 = H1;
data.H2 = H2;
data.T_pts = T_pts;
data.fs = fs;

end

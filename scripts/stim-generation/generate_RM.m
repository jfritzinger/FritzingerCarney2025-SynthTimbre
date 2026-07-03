function params = generate_RM(params)
% Response map function 

%% Calculate stimulus frequencies
freq_lo = params.freqs(1);
freq_hi = params.freqs(2);
steps_per_octave = params.freqs(3);
i = 1;
freq = freq_lo;
while freq < freq_hi
	all_freqs(i) = freq;
	freq = freq * 2^(1/steps_per_octave); % next freq
	i = i+1;
end
nfreqs = length(all_freqs);
fm = 0;


%% Calculate stimulus SPLs
if isempty(params.spls)
	all_spls = sort([-inf]);
else
	tspls = params.spls(1):params.spls(3):params.spls(2);
	all_spls = sort([-inf params.spls(1):params.spls(3):params.spls(2)]);
end
nspls = length(all_spls);
nstim = nspls * nfreqs;

%% Create the Stimulus Gating function
npts = floor(params.dur*params.Fs);
gate = tukeywin(npts,2*params.ramp_dur/params.dur); %raised cosine ramps
t = (0:1:npts-1)/params.Fs;
modulator = 0.5+0.5*sin(2*pi*fm*t');               % coded added for option of AM tones

%% Generate stimuli for all presentations
params.stimuli = zeros(nstim*params.mnrep, npts);
presentation = 0;

stimuli = zeros(params.mnrep*nstim, npts);
for irep = 1:params.mnrep
	rng('shuffle'); %For each rep, create random sequence of stimuli
	stim_list = randperm(nstim);
	for istim = 1:nstim
		presentation = presentation + 1;
		
		ispl = mod(stim_list(istim)-1,nspls)+1;   % the "-1" makes sure that list of SPLS starts with low value, and "+1" starts values at 1 instead of 0
		spl = all_spls(ispl);
		ifreq = ceil((stim_list(istim))/nspls);
		freq = all_freqs(ifreq);
		
		am_stim = cos(2*pi*freq*t') .* modulator;                     % tone with AM
		desired_rms_Pa = (10^(spl/20))*20e-6;                         % Desired RMS amplitude of stimuli in Pa
		stimulus = am_stim * desired_rms_Pa / rms(am_stim);           % AM tone in Pa
		stimuli(presentation,:) = stimulus.*gate;                                    % Gated, amplitude-modulated tone waveform in Pa

		params.mlist(presentation).freq = freq;
		params.mlist(presentation).ifreq = ifreq;
		params.mlist(presentation).spl = spl;
		params.mlist(presentation).ispl = ispl;
		params.mlist(presentation).rep = irep;
	end
end
params.stim = stimuli;

%% Reshape matrix  of stimuli and pass to naq program
%stimuli = reshape(stimuli,[size(stimuli,1), 1, size(stimuli,2)]);

end                                                     % Return to DCP


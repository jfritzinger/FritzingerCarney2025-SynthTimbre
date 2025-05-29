function [params] = generate_ST(params)
% Generates the sliding spectral centroid stimulus for population model or
% single cell model, slightly different than the physiology stimulus
% because it doesn't have 'reps'
% J. Fritzinger, updated 8/8/23
%
% Inputs: params.Fs: sampling rate
%         params.fpeak_mid: spectral centroid
%         params.Delta_F: fundamental frequency, default = 200Hz
%         params.dur: duration (s), default = 0.3s
%         params.ramp_dur: ramp duration (s), default = 0.02s
%         params.steps: number of steps, this is the number of total stimuli that
%         will be created. Choose steps = 1 to produce one stimulus cenetered 
%         at fpeak_mid for a population response. Default = 41
%         params.spl: overall stimulus level (dB), default = 73dB SPL
%         params.g: slope (dB/oct), default = 24


params.type = 'SPEC_slide';
params.SPEC_slide_type = 'Spectral_Centroid';
%params.version = 1; % 7/15/2020 LHC (from Jo's psycho code)
%params.version = 2; % 9/10/20 JBF, fixed harmonic placement & increased range
%params.version = 3; % 9/29/20 JBF, fixed sliding & fixed erroring out at low CFs
%params.version = 4; % 11/4/20 JBF, fixed sliding stimuli, added G and span as parameters
params.version = 5; % 2/17/2022 JBF, added calibration limit input, prior the band was [100 3*CF+extendFreq=50]

% Find frequency sliding limits 
freq_lo = params.fpeak_mid - (params.num_harms-1)/2 * params.Delta_F; % three components below (try 2.5 7/30/20 LHC)
freq_hi = params.fpeak_mid + (params.num_harms-1)/2 * params.Delta_F; % three components above ( ditto )
if freq_lo < 200 % limited to 200 Hz on upper end
	freq_lo = 200;
end
if freq_hi > 20000 % limited to 20 kHz on upper end
	freq_hi = 20000;
end

% Calculate array of swept (center or edge) frequencies
if params.stp_otc == 1
    params.fpeaks = params.fpeak_mid;
else
    params.fpeaks = linspace(freq_lo,freq_hi,params.stp_otc); %freq_lo * 2.^((0:nfreqs)/steps_per_octave);
end 

% Calculates number of stimuli to be played, just for diplaying the time
% requirement estimation
nstim = length(params.fpeaks);

% Estimate time required for this DSID
%time_required = nstim*params.mnrep*params.reptim/60;  % in minutes
%disp(['This will take ' num2str(time_required) ' min']);

% Create the Stimulus Gating function
fs = params.Fs;
npts = floor(params.dur*fs);
gate = tukeywin(npts,2*params.ramp_dur/params.dur); %raised cosine ramps

% Generate stimuli for all presentations
params.stim = zeros(nstim*params.mnrep, npts);
presentation = 0; %this value is used as an index for storing a stumulus presentation in the 3rd dimenstion of 'stimuli'

if params.physio == 1
	rng(params.seed)
else
	rng('shuffle') % create a random seed
	rand_state = rng; % store it in the "seed field", a field of the random # generator
	params.seed = rand_state.Seed; % save this "basic" seed that will be used for waveform generation
end

for irep = 1:params.mnrep
	%stim_list = randperm(nstim); % randomize stimuli for each rep
	stim_list = 1:params.stp_otc;

	% Create stimuli for each rep (irep) and each stimulus (istim)
	for istim = 1:nstim
		presentation = presentation + 1;

		% Set the RNG seed to stored "basic" value, and add a # to change it from rep to rep
		rng(params.seed + presentation); % is it true that we don't use random numbers after this point?

		% Compute one stimulus waveform.
		this_fpeak = params.fpeaks(stim_list(istim)); % Get peak freq for this presentation

		% Compute fixed set of scalars for central stimulus to obtain spectral envelope & desired stimdB dB SPL
		harmonics = params.Delta_F:params.Delta_F:10000; % component freqs for the central stimulus, when this_fpeak = CF
		num_harmonics = length(harmonics);
		npts = params.dur * fs; % # pts in stimulus
		t = (0:(npts-1))/fs; % time vector
		component_scales_linear = 10.^(-1*abs(log2(harmonics/params.fpeak_mid)*params.g)/20); % one set of scales for the center triangle, i.e. when this_fpeak = CF
		interval = zeros(1,npts);
		for iharm = 1:num_harmonics
			comp_freq = harmonics(iharm);
			component = component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
			interval = interval + component;          %Add component to interval
		end
		Level_scale = 20e-6*10.^(params.spl/20) * (1/rms(interval)); % overall lienar scalar to bring this centered stimulus up to stimdB
		component_scales_linear = Level_scale * component_scales_linear; % include dB scaling into the set of harmonic component scalars


		stim = spectral_centroid(this_fpeak,params.Delta_F, params.fpeak_mid, params.dur, fs, component_scales_linear);


		% Apply ramps.
		stim = stim.*gate;
		params.stim(presentation,:) = stim;

		% Save parameters for each presentation
		params.mlist(presentation).fpeak = this_fpeak;
		params.mlist(presentation).rep = irep;
		params.mlist(presentation).irand = stim_list(istim);

	end
end


end

%%%%%%%%%%%%%%%%%%%% SPECTRAL_CENTROID %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function interval = spectral_centroid(this_fpeak, Delta_F, Fc, dur, Fs, component_scales_linear)
% Creates the spectral centroid stimulus (triangular spectrum, peak at this_fpeak)
% Based on Allen & Oxenham 2014
% L. Carney, J. Fritzinger

% Time vectors
npts = dur * Fs; % # pts in stimulus
t = (0:(npts-1))/Fs; % time vector
interval = zeros(1,length(t));
harmonics = Delta_F:Delta_F:10000; % component freqs for the central stimulus, when this_fpeak = CF
num_harmonics = length(harmonics);

% Make the stimulus for this_fpeak
shift = this_fpeak - Fc; % a negative values for low fpeaks; 0 at center; positive for high fpeaks
for iharm = 1:num_harmonics
	comp_freq = (harmonics(iharm) + shift);
	if comp_freq > 75 % Hz; make sure we don't include comps outside calibrated range (Note: because we'll lop off components, then scale to, say, 70 dB SPL overall - the comp amps will change whenever one component is eliminated.
		interval = interval + component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
	end
end
interval = interval';

% V. 2
% %t
% npts = dur * Fs; % # pts in stimulus
% t = (0:(npts-1))/Fs; % time vector
% interval = zeros(1,length(t));
%
% %prepare loop
% start_F = this_fpeak - Delta_F * (ceil(this_fpeak/Delta_F) - 1) + mod(fpeak_mid, Delta_F);
% if start_F == 0
%     start_F = 200;
% end
% multiplier = 0;
% while multiplier*Delta_F+start_F <= 10000
%     %Make components using f0
%     component = sin(2*pi*(Delta_F*multiplier+start_F)*t);
%
%     %Scale all components
%     additional_scaling = -1*abs(log2((Delta_F*multiplier+start_F)/this_fpeak))*24; %Number of octaves away from sc, times reduction in amplitude per octave.
%     component2 = 20e-6 * 10.^((stimdB + additional_scaling)/20) * component/rms(component); %Will be scaled again below to get correct overall level.
%
%     %Add to interval
%     interval = interval + component2;
%
%     %Increment
%     multiplier = multiplier + 1;
% end
%
% %Scale again to get overall level instead of per component - ratios
% %should be the same.
% contra_stim = 20e-6 * 10.^(stimdB/20) * interval/rms(interval);
% contra_stim = contra_stim';
% %Gate interval
% %t1 = tukeywin((Fs*dur),2*rampdur/dur);
% %contra_stim = t1'.* interval;


% V. 1
% % Generate_single_formant - Lyzenga & Horst's triangular spectrum (from
% D. Schwarz code) v. 1 & 2
% %    dur = duration in seconds  (0.5 s)  << set above
% %    ramdur = 0.02 (s) << set above, and ramp applied outside of stimulus loop
% %    F0 = fundamental freq. in Hertz  (200 Hz)
% F0 = Delta_F; % << these components should all 'slide';
% %    CF = spectral centroid (1200) >> "this_fpeak"
% CF = this_fpeak; % peak freq of spectral controid stimulus
% %    stimdB = desired SPL of composite waveform (dB SPL) (70 dB SPL)
% %    G = slope of triangle edges in dB/octave (24)
% G = 24;
%
% F_max = 10000; % max frequency component to include
% Pref = 20e-6; % 20 micropascals
% %F_min = F0;
% f_low = this_fpeak - Delta_F * (ceil(this_fpeak/Delta_F) - 1) + mod(fpeak_mid, Delta_F); % lowest freq component - start at center and go down to minumal cpoment in steps of Delta_F
%
% % Calculate intercepts at which signal is at 10000 Hz.
% max_rel_level = -G*log2(F_max/CF);
% min_rel_level = -G*log2(f_low/CF);
% %tri_x = log2([F_min CF F_max]);
% tri_x = log2([f_low CF F_max]);
% tri_y = [stimdB - min_rel_level, stimdB, stimdB + max_rel_level];
%
% % Generate time vector.
% t = (0:1/Fs:dur)';
% t(end) = [];
%
% %harm_num = ceil(F_min/F0):floor(F_max/F0);
% %f_harm = harm_num*F0;  %  NEED to have these slide!
%
% comp_freqs = f_low:Delta_F:F_max; % frequency comps, centered at this_fpeak, spaced by Delta_F
%
% log2_comp_freqs = log2(comp_freqs);
% SPLs = interp1(tri_x,tri_y,log2_comp_freqs);
% amp = sqrt(2)*Pref*10.^(SPLs/20); % This converts dB SPL to peak amplitude in Pascals
%
% sin_matrix = sin(t*(2*pi*comp_freqs)); % zero phase (Cos phase? is this right?)
%
% % Multiply each col of sin_matrix by appropriate amplitude, add up the
% % columns, and multiply by ramp envelope.
% contra_stim = sin_matrix * amp';
% contra_stim = Pref * 10.^(stimdB/20) * contra_stim / rms(contra_stim); % scale overall RMS level into desired pascals
% %stim = stim .* tukeywin(length(stim),2*rampdur/dur); % apply ramp
end
%%%%%%%%%%%%%%%%%%%%% END OF SPECTRAL_CENTROID FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

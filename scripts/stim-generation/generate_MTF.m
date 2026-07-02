function [params] = generate_MTF(params)
% Modulation transfer function with band-limited noise carrier, for use with National Insturments hardware and naq program

%% Calculate stimulus modulation depths
dur = params.dur; % s
params.all_mdepths = params.mdepths(1):params.mdepths(3):params.mdepths(2);
nmdepths = length(params.all_mdepths);

%% Calculate stimulus modulation frequencies
fm_lo = params.fms(1);
fm_hi = params.fms(2);
steps_per_octave = params.fms(3);
i = 1;
fm = fm_lo;
while fm < fm_hi
    all_fms(i) = fm;
    fm = fm * 2^(1/steps_per_octave); % next freq
    i = i+1;
end
if nmdepths == 1    % MTF at single mdepth
    all_fms_fig = [1.2 all_fms]; % Was a BUG: adding 2 Hz was trying to plot 0 Hz on log axis with the old setup
    params.all_fms = [0 all_fms];            % Add 0 Hz modulation frequency
end
nfms = length(params.all_fms);


%% Estimate time required for this DSID
nstim = nfms * nmdepths;
%time_required = nstim * params.nrep * params.reptim/60; %what is reptim
%disp(['This will take ' num2str(time_required) ' min']);

%% Create the Stimulus Gating function

npts = floor(dur*params.Fs);
gate = tukeywin(npts,2*params.ramp_dur/dur); %raised cosine ramps
t = (0:1:npts-1)/params.Fs;

%% Construct filters
fn = params.Fs/2;
b_bp = fir1(4000,params.noise_band/fn);         % 1. Bandpass filter
params.stim_filters.b_bp = b_bp;

%% Begin calculating noise carrier
noise_spl = params.No+10*log10(params.Fs/2); % SPL with desired spectrum level 
% use fs as bandwidth but will filtered later to get the correct overall level
noise_rms = 10^(noise_spl/20)*20e-6;                % RMS amplitude
if params.noise_state == 0                          % Frozen noise; random noise is handled in the stim loop
    rng(0);
    BBN_Pa = noise_rms*randn(npts,1);               % White noise (BW: 0 - fn) with appropriate spectrum level
    BBN_Pa_band = conv(BBN_Pa,b_bp,'same');         % Band-limited noise of appropriate spectrum level
    pre_mod_rms = rms(BBN_Pa_band);                 % RMS amplitude of noise waveform prior to modulation (target RMS)
end


%% Generate stimuli for all presentations
presentation = 0;

for irep = 1:params.mnrep
    rng('shuffle');                               % For each rep, create random sequence of stimuli
    stim_list = randperm(nstim);
    for istim = 1:nstim
        presentation = presentation + 1;
        
        imdepth = mod(stim_list(istim),nmdepths)+1;             % "+1" starts values at 1 instead of 0
        mdepth = params.all_mdepths(imdepth);
        ifm = ceil((stim_list(istim))/nmdepths);
        fm = params.all_fms(ifm);
        
        % Finish calculating noise carrier waveform
        if params.noise_state == 0                              % Frozen noise carrier
            seed = 0;
        elseif params.noise_state == 1                          % Random noise
            seed=rng;
            BBN_Pa = noise_rms*randn(npts,1);                   % White noise (BW: 0 - fn) with appropriate spectrum level
            BBN_Pa_band = conv(BBN_Pa,b_bp,'same');             % Band-limited noise of appropriate spectrum level
            pre_mod_rms = rms(BBN_Pa_band);                     % RMS amplitude of noise waveform prior to modulation
        end
        
        % Calculate modulator tone
        if mdepth <= -33
            m = 0;                                              % Replace "-35 dB modulation" with an unmodulated stimulus
        else
            m = 10^(mdepth/20);                                 % Convert mdepth in dB into m
        end
        modulator = m*sin(2*pi*fm*t');
        
        % Modulate the noise carrier
        if params.raised_sine == 1
           am_stim = (1 + modulator) .* BBN_Pa_band; % version before 1/2/20 (note that peak of modulator is 2, but wave is normalized to desired RMS below.
        else  % for raised_sine > 1, must have modulator amplitude < 1 (so only do this for mdepth = 0, i.e. 100% modulation)
            % NOTE: don't use raised_sine ~= 1 unless mdepth = 0 dB                
            am_stim = (((1 + modulator)/2) .^ params.raised_sine) .* BBN_Pa_band;  % fixed on 1/20/20 LHC                
        end
        post_mod_rms = rms(am_stim);
        stimulus = am_stim * pre_mod_rms / post_mod_rms;       % Scale RMS back to pre-mod RMS (i.e. the desired No)
        params.stim(presentation,:) = stimulus.*gate;                             % Gated, amplitude-modulated noise waveform in Pa
              
        params.mlist(presentation).fm = fm;
        params.mlist(presentation).ifm = ifm;
        params.mlist(presentation).mdepth = mdepth;
        params.mlist(presentation).imdepth = imdepth;
        params.mlist(presentation).noise_seed = seed;
        params.mlist(presentation).rep = irep;
           
    end
end

end
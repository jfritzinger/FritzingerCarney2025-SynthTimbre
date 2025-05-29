%% Example code for SFIE + lateral inhibition model 
%
% Script that runs an example MTF stimulus through the lateral AN and 
% lateral SFIE code 
%
% Other files required: modelLateralAN.m, modelLateralSFIE.m, 
%						modelLateralSFIE_BMF.m
%
% Author: J. Fritzinger
% Created: 2024-10-10; Last revision: 2024-10-10
%
% -------------------------------------------------------------------------

%% Create stimulus 
% Uses and MTF stimulus 

% MTFN parameters
params.type = 'typMTFN';
params.Fs = 100000;
params.ramp_dur = 0.05;
params.noise_state = 0;
params.noise_band = [100, 10000];
params.dur = 1;
params.reptim = 1.5;
params.fms = [2, 600, 3];
params.mdepths = [0,0,1];
params.binmode = 2;
params.No = 30;
params.spl = 30;
params.raised_sine = 1;
params.onsetWin = 25;
params.mnrep = 3; % number of model repetitions 
params = generate_MTF(params);
params.num_stim = size(params.stim, 1);

%% Set model parameters 

% Parameters for the lateral inhibition strength, delay, and CF range 
paramS = 0.5; % Strength of off-CF inhibition (recommend 0.3-0.5)
paramCF = 1; % CF of off-CF inhibitory pathways, octaves (recommend 0.5-1)
paramD = 0; % Off-CF inhibition delay, ms (has little effect on responses)
CF = 2000;

% AN model parameters 
model_params.range = 2; % 1 = population model, 2 = single cell model
model_params.species = 1; % 1 = cat, 2 = human
model_params.nAN_fibers_per_CF = 10;
model_params.cohc = 1; % (0-1 where 1 is normal)
model_params.cihc = 1; % (0-1 where 1 is normal)
model_params.nrep = 1; % how many times to run the AN model
model_params.fiberType = 3; % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
model_params.implnt = 1; % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
model_params.noiseType = 1; % 0 = fixed fGn, 1 = variable fGn) - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
model_params.CFs = [CF*2^(-1*paramCF), CF, CF*2^paramCF];
model_params.onsetWin = 0.020; % exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050

% IC model parameters 
model_params.type = 'Lateral Model';
model_params.config_type = 'BS inhibited by off-CF BS';
model_params.BMF = [100 100 100];
lm_params = [paramS paramS paramD];


%% Run model 

% Runs AN lateral code 
AN = modelLateralAN(params, model_params);

% Runs lateral model SFIE code: simple version using 100 Hz BMFs 
% lateral_model = modelLateralSFIE(params, model_params, AN.an_sout, ...
% 	AN.an_sout_lo, AN.an_sout_hi,'CS_params', lm_params);

% Runs lateral model SFIE code: varying BMF parameters
model_params.BMF = [80 100 80];
lateral_model = modelLateralSFIE_BMF(params, model_params, AN.an_sout, ...
	AN.an_sout_lo, AN.an_sout_hi,'CS_params', lm_params, 'BMFs', model_params.BMF);

%% Example output analysis for MTF stimulus 

[fig, avIC, stdIC] = plotMTF(params, lateral_model.avIC, 1);


%% ----------------------------- FUNCTIONS --------------------------------
% Functions for MTF stimulus creation and analysis

function [params] = generate_MTF(params)
% Modulation transfer function with band-limited noise carrier, 
% for use with National Insturments hardware and naq program
% Adapted from DAQ files

% Calculate stimulus modulation depths
dur = params.dur; % s
params.all_mdepths = params.mdepths(1):params.mdepths(3):params.mdepths(2);
nmdepths = length(params.all_mdepths);

% Calculate stimulus modulation frequencies
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


% Estimate time required for this DSID
nstim = nfms * nmdepths;

% Create the Stimulus Gating function
npts = floor(dur*params.Fs);
gate = tukeywin(npts,2*params.ramp_dur/dur); %raised cosine ramps
t = (0:1:npts-1)/params.Fs;

% Construct filters
fn = params.Fs/2;
b_bp = fir1(4000,params.noise_band/fn);         % 1. Bandpass filter
params.stim_filters.b_bp = b_bp;

% Begin calculating noise carrier
noise_spl = params.No+10*log10(params.Fs/2); % SPL with desired spectrum level 
% use fs as bandwidth but will filtered later to get the correct overall level
noise_rms = 10^(noise_spl/20)*20e-6;                % RMS amplitude
if params.noise_state == 0                          % Frozen noise; random noise is handled in the stim loop
    rng(0);
    BBN_Pa = noise_rms*randn(npts,1);               % White noise (BW: 0 - fn) with appropriate spectrum level
    BBN_Pa_band = conv(BBN_Pa,b_bp,'same');         % Band-limited noise of appropriate spectrum level
    pre_mod_rms = rms(BBN_Pa_band);                 % RMS amplitude of noise waveform prior to modulation (target RMS)
end

% Generate stimuli for all presentations
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

% -------------------------------------------------------------------------

function [fig, avBE, stdBE] = plotMTF(stim_params, model, plot_on)

% Analysis 
[fms,~,fmi] = unique(double([stim_params.mlist.fm]).');
num_mod_freqs = length(fms);
all_mod_depths = double([stim_params.mlist.mdepth]).';
all_mod_depths(all_mod_depths < -80) = max(all_mod_depths);
[~,~,mdi] = unique(all_mod_depths);
num_depths = length(stim_params.all_mdepths);
rate_size = [num_mod_freqs, num_depths];

% Plot model
[avBE,stdBE,~,~] = accumstats({fmi,mdi},model, rate_size);
if plot_on == 1
	fig = figure;
	hold on
	line([1 stim_params.all_fms(end)], [1 1]*avBE(1),'Color',[0.4 0.4 0.4], 'linewidth', 1.5);
	errorbar(stim_params.all_fms,avBE, stdBE,'.');
	line(stim_params.all_fms,avBE,'Color','k', 'Marker','.', 'MarkerSize',5, 'MarkerFaceColor','w');
	%plot(data.fms,rate_sm,'-b', 'LineWidth', 1)
	hold off
	% Label the plots
	xtick = [1 2 5 20 50 100 200 500];
	xlim(xtick([1 end]))
	xlabel('Modulation Freq (Hz)')
	ylabel('Avg. Rate (sp/s)')
	set(gca,'XTick',xtick,'XScale', 'log')
	legend('Unmodulated', 'Location','best')
	grid on
	axis_set = axis;
	axis_set(3) = 0;
	axis(axis_set);
else
	fig = [];
end
end

% -------------------------------------------------------------------------

function supp4_model_temporal(save_fig)
% FIG_S4_MODEL_TEMPORAL Generates Supplementary Figure S3 demonstrating model temporal period histograms.
%
% PURPOSE:
%   This function simulates auditory nerve and inferior colliculus responses to synthetic 
%   timbre tokens to analyze the sub-millisecond temporal period profiles generated across 
%   three standard computational configurations: Same-Frequency Inhibition-Excitation (SFIE), 
%   Broad/Lateral Inhibition, and traditional front-end Energy frameworks. It constructs 
%   steady-state matrix heatmaps illustrating cycle-by-cycle response phase-locking 
%   relative to the stimulus fundamental frequency (200 Hz) across both Band-Enhanced (BE) 
%   and Band-Suppressed (BS) sub-types.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a 3x2 multi-panel temporal heatmap simulation layout. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - generate_ST()             : Synthesizes synthetic timbre acoustic sound waves
%   - modelAN()                 : Simulates auditory nerve fiber spike trains
%   - wrapperIC()               : Computes inferior colliculus neural responses via the SFIE model
%   - modelLateralAN()          : Evaluates multi-channel lateral auditory nerve arrays
%   - modelLateralSFIE()        : Implements off-frequency inhibitory matrix interaction profiles
%   - gamma_filt()              : Passes waveforms through a baseline Gammatone auditory filter bank
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up (Original framework dated for 2025 manuscript)

%% Parameters
CF = 1200;

% Stimulus parameters
params.fpeak_mid = 1200;
params.Delta_F = 200;
params.num_harms = 11;
params.stp_otc = 41;
params.Fs = 100000;
params.mnrep = 1;
params.physio = 0;
params.dur = 0.3;
params.ramp_dur = 0.02;
params.spl = 70;
params.g = 24;
params = generate_ST(params);
params.num_stim = size(params.stim, 1);
fs = params.Fs;

%% Model

for imodel = 1:3
	if imodel == 1 % SFIE

		% Model parameters
		model_params.type = 'SFIE';
		model_params.range = 2; % 1 = population model, 2 = single cell model
		model_params.species = 1; % 1 = cat, 2 = human
		model_params.BMF = 100;
		model_params.CF_range = 1200;
		model_params.num_CFs = 1;
		model_params.CFs = 1200;
		model_params.nAN_fibers_per_CF = 5;
		model_params.cohc = 1; % (0-1 where 1 is normal)
		model_params.cihc = 1; % (0-1 where 1 is normal)
		model_params.nrep = 10; % how many times to run the AN model
		model_params.implnt = 1; % 0 = approximate model, 1=exact powerlaw
		% implementation(See Zilany etal., 2009)
		model_params.noiseType = 1; % 0 = fixed fGn, 1 = variable fGn) -
		% this is the 'noise' associated with spont. activity of AN fibers -
		% see Zilany et al., 2009. "0" lets you "freeze" it.
		model_params.which_IC = 1; % 2 = ModFilt; 1 = SFIE model
		model_params.onsetWin = 0.020; % exclusion of onset response, e.g. to
		% omit 1st 50 ms, use 0.050
		model_params.fiberType = 3; % AN fiber type. (1 = low SR, 2 = medium
		% SR, 3 = high SR)
		model_params.Fs = 100000;

		% Model
		AN_HSR = modelAN(params, model_params); % HSR for IC input
		SFIE = wrapperIC(AN_HSR.an_sout, params, model_params); % SFIE output

	elseif imodel == 2 % Broad inhibition
        latinh = cell(1, 2);
		for iMTF = 1:2
			if iMTF == 1
				S = 0.4; % BE
				D = 0; % BE
				oct_range = 0.5; % BE
			else
				S = 0.25; % BS
				D = 0; % BS
				oct_range = 0.75; % BS
			end
			%	Model parameters
			model_params.type = 'Lateral Model';
			model_params.range = 2; % 1 = population model, 2 = single cell model
			model_params.species = 1; % 1 = cat, 2 = human
			model_params.BMF = 100;
			model_params.num_CFs = 1;
			model_params.nAN_fibers_per_CF = 10;
			model_params.cohc = 1; % (0-1 where 1 is normal)
			model_params.cihc = 1; % (0-1 where 1 is normal)
			model_params.nrep = 1; % how many times to run the AN model
			model_params.implnt = 1; % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
			model_params.noiseType = 1; % 0 = fixed fGn, 1 = variable fGn) - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
			model_params.which_IC = 1; % 2 = ModFilt; 1 = SFIE model
			model_params.onsetWin = 0.020; % exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
			model_params.fiberType = 3; % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
			model_params.lateral_CF = [CF*2^(-1*oct_range), CF, CF*2^oct_range];
			model_params.CFs = model_params.lateral_CF;
			model_params.CF_range = model_params.CFs(2);

			% Lateral model parameters
			model_params.config_type = 'BS inhibited by off-CF BS';
			lm_params = [S S D];

			% Run model
			AN_temp = modelLateralAN(params, model_params);
			latinh{iMTF} = modelLateralSFIE(params, model_params,...
				AN_temp.an_sout, AN_temp.an_sout_lo, AN_temp.an_sout_hi,...
				'CS_params', lm_params);
		end

	else % Energy

		gamma_param.srate = params.Fs;
		gamma_param.fc = CF;
		stimulus = [params.stim zeros(size(params.stim,1),0.1*params.Fs)];
		impaired = 0; % 0 = not impaired; 1 = 'impaired'
		pin_gamma = zeros(size(stimulus, 1), params.Fs*params.dur+0.1*params.Fs);

		for istim = 1:size(stimulus, 1)
			pin_gamma(istim,:) = gamma_filt(stimulus(istim,:),gamma_param,impaired, 1);
		end
		pin_gamma = pin_gamma(:,1:params.dur*params.Fs);
		energ_out = sqrt(mean(pin_gamma.^2,2));
		energy.energ_out = energ_out;
		energy.pin_gamma = pin_gamma;
	end
end


%% Create heatmaps for BE and BS

[~, ~, ~, ppi] = get_paths();
figure('Position',[50,50,3.33*ppi,4*ppi])
h = gobjects(5, 1);
fontsize = 7;
titlesize = 8;
labelsize = 13;

index = [1, 2; 3, 4; 5, 6];
for imodel = 1:3

	fpeaks = params.fpeaks;
	num_fpeaks = length(fpeaks);

	for ii = 1:2

		if imodel == 1 && ii == 1
			spike_hist = squeeze(SFIE.ic_BE);
		elseif imodel == 1 && ii == 2
			spike_hist = squeeze(SFIE.ic_BS);
		elseif imodel == 2 && ii == 1
			spike_hist = squeeze(latinh{1}.ic);
		elseif imodel == 2 && ii == 2
			spike_hist = squeeze(latinh{2}.ic);
		elseif ii == 1
			spike_hist = energy.pin_gamma;
		else
			continue
		end

		if ii == 1
			name = 'BE';
		else
			name = 'BS';
		end

		% Calculate period histogram
		h(index(imodel, ii)) = subplot(3, 2, index(imodel, ii));
		max_rate = max(spike_hist, [], 'all')/2;
		onsetwin = 0.05;
		hold on
        avg = zeros(num_fpeaks, 500);
		for j = 1:num_fpeaks

			% Plot PSTHs
			spike_wo_onset = spike_hist(j, onsetwin*fs:params.dur*fs-1);
			freq = 200; % Stimulus frequency in Hz
			period = 1 / freq; % Period in ms
			samples_per_period = fs*period;

			period_hist = reshape(spike_wo_onset, samples_per_period,[]);
			avg(j,1:500) = mean(period_hist, 2)';
			t_period = linspace(0, period, fs*period);

		end
		grayMap = [linspace(0, 1, 256)', linspace(0, 1, 256)', linspace(0, 1, 256)'];
		grayMap = flipud(grayMap);


		hh = pcolor(t_period, fpeaks./1000, avg);
		set(hh, 'EdgeColor', 'none');
		hold on
		yline(CF/1000, 'r', 'LineWidth',2)
		colormap(grayMap);
		box on
		yticks(linspace(max_rate/2, max_rate*100-max_rate/2, 100))
		set(gca, 'YScale', 'log')
		ylim([fpeaks(1) fpeaks(end)]/1000)
		yticks([0.1 0.2 0.5 1 2 5 10])
		xlim([0 75])
		if ii == 1
			ylabel('CFs (kHz)')
		end
		xlim([0 0.005])
		xticks(0:0.001:0.005)
		xticklabels(0:5)
		xlabel('Period (ms)')
		grid on
		if imodel == 1 || imodel == 2
			title(name)
		else
			title('No MTF')
		end
		set(gca, 'fontsize',fontsize)
		if imodel == 3 || ii == 2
			c = colorbar;
			c.Label.String = 'Rate (sp/s)';
		end
	end
end

%% Arrange and annotate figure 

left = [0.18 0.55];
bottom = linspace(0.08, 0.73, 3);
height = 0.22;
width = 0.3;
set(h(1), 'Position', [left(1) bottom(3) width height])
set(h(2), 'Position', [left(2) bottom(3) width height])
set(h(3), 'Position', [left(1) bottom(2) width height])
set(h(4), 'Position', [left(2) bottom(2) width height])
set(h(5), 'Position', [left(1) bottom(1) width height])

%% Annotate 
bottom = linspace(0.31, 0.97, 3);
annotation('textbox',[0.02 bottom(3) 0.0826 0.0385],'String',{'A'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.02 bottom(2) 0.0826 0.0385],'String',{'B'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.02 bottom(1) 0.0826 0.0385],'String',{'C'},...
	'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');


% Annotate model labels
annotation('textbox',[0.1 0.79 0.086 0.053],'String','SFIE',...
	'Rotation',90,'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');
annotation('textbox',[0.1 0.43 0.25 0.053],'String',{'Broad Inh.'},...
	'Rotation',90,'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');
annotation('textbox',[0.1 0.13 0.10 0.053],'String',{'Energy'},...
	'Rotation',90,'FontWeight','bold','FontSize',titlesize,'EdgeColor','none');



%% Save figure

if save_fig == 1
	filename = 'fig_s4_model_temporal';
	save_figure(filename)
end

end
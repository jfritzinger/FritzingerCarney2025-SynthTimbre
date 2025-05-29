function fig2_stimulus(save_fig)
% Synthetic timbre stimulus, sliding in the frequency spectrum
% J. Fritzinger, 8/27/24

%% Set up figure

[~, ~, savepath, ppi] = get_paths();
figure('Position',[50,50,3.2*ppi,1.3*ppi]);
h(1) = subplot(1, 1, 1);
colors = {'#000000', '#bdbdbd'};
CF_color = '#3690c0';
fontsize = 7;
titlesize = 8;
linewidth = 1;

%% Create Stimulus & plot 

% Parameters
params.Fs = 100000;
params.F0 = 200; % fundamental frequency 
params.Fc = 1400; % peak harmonic frequency 
params.dur = 0.3; % duration
params.ramp_dur = 0.02; % ramp duration
params.stimdB = 70; % overall level
params.G = 24; % slope, in dB/oct 
%params.fpeaks = [850 1100 1400 1700 2050];
params.fpeaks = [900 1400 2250];
params.mnrep = 1;

% Calculates number of stimuli to be played
nstim = length(params.fpeaks);

% Create the Stimulus Gating function
fs = params.Fs;
npts = floor(params.dur*fs);
gate = tukeywin(npts,2*params.ramp_dur/params.dur); %raised cosine ramps

% Generate stimuli for all presentations
params.stim = zeros(nstim*params.mnrep, npts);
presentation = 0; %this value is used as an index for storing a stumulus presentation in the 3rd dimenstion of 'stimuli'

hold on
line([params.Fc params.Fc], [0 100], 'LineWidth', 2,'LineStyle', ':', 'Color', CF_color);

% Create stimuli for each rep (irep) and each stimulus (istim)
for istim = 1:nstim
	presentation = presentation + 1;

	% Compute one stimulus waveform.
	this_fpeak = params.fpeaks(istim); % Get peak freq for this presentation

	% Compute fixed set of scalars for central stimulus to obtain spectral envelope & desired stimdB dB SPL
	harmonics = params.F0:params.F0:10000; % component freqs for the central stimulus, when this_fpeak = CF
	num_harmonics = length(harmonics);
	npts = params.dur * fs; % # pts in stimulus
	t = (0:(npts-1))/fs; % time vector
	component_scales_linear = 10.^(-1*abs(log2(harmonics/params.Fc)*params.G)/20); % one set of scales for the center triangle, i.e. when this_fpeak = CF
	interval = zeros(1,npts);
	for iharm = 1:num_harmonics
		comp_freq = harmonics(iharm);
		component = component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
		interval = interval + component;          %Add component to interval
	end
	Level_scale = 20e-6*10.^(params.stimdB/20) * (1/rms(interval)); % overall lienar scalar to bring this centered stimulus up to stimdB
	component_scales_linear = Level_scale * component_scales_linear; % include dB scaling into the set of harmonic component scalars

	% Time vectors
	npts = params.dur * fs; % # pts in stimulus
	t = (0:(npts-1))/fs; % time vector
	interval = zeros(1,length(t));
	harmonics = params.F0:params.F0:10000; % component freqs for the central stimulus, when this_fpeak = CF
	num_harmonics = length(harmonics);

	% Make the stimulus for this_fpeak
	shift = this_fpeak - params.Fc; % a negative values for low fpeaks; 0 at center; positive for high fpeaks
	for iharm = 1:num_harmonics
		comp_freq = (harmonics(iharm) + shift);
		if comp_freq > 75 % Hz; make sure we don't include comps outside calibrated range (Note: because we'll lop off components, then scale to, say, 70 dB SPL overall - the comp amps will change whenever one component is eliminated.
			interval = interval + component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
			int_single = component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
		else
			int_single = 0;
		end
		shifted_harms(iharm) = comp_freq;

		% Plot each stimulus
		y = fft(int_single);
		mdB = 20*log10(abs(y));
		if sum(y)==0
			level(iharm) = NaN;
		else
			level(iharm) = findpeaks(mdB(1:length(mdB)/2), 'MinPeakProminence',200);
		end

		% Plot harmonics
		if istim == 2
			stem(shifted_harms(iharm), level(iharm), 'Marker', 'none', 'LineWidth', ...
				linewidth, 'Color', colors{1});
		else
			stem(shifted_harms(iharm), level(iharm), 'Marker', 'none', 'LineWidth', ...
			linewidth, 'Color', colors{2});
		end
	end

	if istim == 2
		plot(shifted_harms, level, 'LineWidth', linewidth, 'Color', colors{1});
	else
		plot(shifted_harms, level, 'LineWidth', linewidth, 'Color', colors{2});
	end

end
ylim([0 70])
ylabel('Magnitude (dB SPL)')
xLabel = xlabel('Frequency (Hz)', 'HorizontalAlignment','right');

xlim([180 3500])
xticks(params.Fc)
xticklabels([])
box on

% Move the xlabel to the bottom right corner
ax = gca; 
xLabel.Position(1) = ax.XLim(2); % Set x-position to the right edge
xLabel.Position(2) = ax.YLim(1); % Set y-position to the bottom
xLabel.Position(2) = ax.YLim(1) - 0.02 * diff(ax.YLim);
set(h(1), 'Position', [0.13, 0.14, 0.80 0.76])

set(gca, 'FontSize', fontsize)
title('Synthetic Timbre Stimulus', 'FontSize',titlesize)

% Create arrow
annotation('arrow',[0.46 0.61],[0.84 0.84], 'linewidth', linewidth, ...
	'HeadLength',2, 'HeadWidth',2, 'HeadStyle','plain');
annotation('arrow',[0.39 0.23],[0.84 0.84], 'linewidth', linewidth, ...
	'HeadLength',2, 'HeadWidth',2, 'HeadStyle','plain');

% Label CF
annotation('textbox',[0.385 0.0198 0.0625 0.106],'String',{'CF'},...
	'FontSize',fontsize,'FitBoxToText','off','EdgeColor','none', 'Color',CF_color);

%% Save figure
if save_fig == 1
	filename = 'fig2_stimulus';
	save_figure(filename)
end

end
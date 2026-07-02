function fig1_hypothesis_SFIE(save_fig)
% FIG1_HYPOTHESIS_SFIE Generates Figure 1 illustrating the SFIE model hypothesis.
%
% PURPOSE:
%   This function simulates and plots the transformation of a complex synthetic 
%   timbre stimulus along the ascending auditory pathway using the Same-Frequency 
%   Inhibition and Excitation (SFIE) model. It visualizes the stimulus spectrum, 
%   auditory nerve (AN) average rates, AN temporal fluctuation profiles, and 
%   Inferior Colliculus (IC) Band-Extended (BE) and Band-Suppressed (BS) responses.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a formatted multi-panel figure. Saves to disk if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - generate_ST()             : Generates synthetic timbre stimulus
%   - generate_MTF()            : Generates modulation transfer function stimulus
%   - modelAN()                 : Simulates auditory nerve fiber responses
%   - wrapperIC()               : Simulates Inferior Colliculus responses
%   - model_IHC()               : Zilany et al. Inner Hair Cell model
%   - model_Synapse()           : Zilany et al. Auditory Nerve Synapse model
%   - calcVS()                  : Computes vector strength (envelope synchronization)
%   - findHalfHeightWidth2()    : Custom analysis for peak/notch bandwidths
%   - plotMTF()                 : Custom function to extract and format MTF data
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 1/16/24

%% Set up figure

[~, ~, ~, ppi] = get_paths();
figure('Position',[50,50,4.567*ppi,5*ppi])
h = gobjects(9, 1);

legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;

%% Stimulus Generation
CF = 1200;

% Stimulus parameters
params{1}.fpeak_mid = 1200;
params{1}.Delta_F = 200;
params{1}.num_harms = 11;
params{1}.stp_otc = 1;
params{1}.Fs = 100000;
params{1}.mnrep = 1;
params{1}.physio = 0;
params{1}.dur = 0.3;
params{1}.ramp_dur = 0.02;
params{1}.spl = 70;
params{1}.g = 24;
params{1} = generate_ST(params{1});
params{1}.num_stim = size(params{1}.stim, 1);

% Stimu lus Parameters and Generation
params{2}.type = 'typMTFN';
params{2}.ramp_dur = 0.05;
params{2}.noise_state = 0;
params{2}.noise_band = [100, 10000];
params{2}.dur = 1; %1; % s
params{2}.reptim = 1.5;
params{2}.fms = [2, 600, 3]; % fm_lo, fm_hi, steps per octave
params{2}.mdepths = [0,0,1];
params{2}.binmode = 2;
params{2}.No = 30;
params{2}.spl = 30;
params{2}.all_mdepths = 0;
params{2}.Fs = 100000;
params{2}.nrep = 1;
params{2}.mnrep = 5;
params{2}.raised_sine = 1;
params{2} = generate_MTF(params{2});
params{2}.num_stim = size(params{2}.stim, 1);

%% Run SFIE model

% Run population synth timbre model
model_params.type = 'SFIE';
model_params.range = 2; % 1 = population model, 2 = single cell model
model_params.species = 1; % 1 = cat, 2 = human (4 = rabbit)
model_params.BMF = 100;
model_params.CF_range = [125 10000];
model_params.num_CFs = 100;
model_params.CFs = logspace(log10(125), log10(10000), 100);
model_params.nAN_fibers_per_CF = 5;
model_params.cohc = 1; % (0-1 where 1 is normal)
model_params.cihc = 1; % (0-1 where 1 is normal)
model_params.nrep = 5; % how many times to run the AN model
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
AN_HSR{1} = modelAN(params{1}, model_params); % HSR for IC input
SFIE{1} = wrapperIC(AN_HSR{1}.an_sout, params{1}, model_params); % SFIE output

% Run single-neuron SFIE MTF model
model_params.range = 2; % 1 = population model, 2 = single cell model
model_params.CF_range = 1200;
model_params.num_CFs = 1;
model_params.CFs = 1200;
model_params.nrep = 1; % how many times to run the AN model
AN_HSR{2} = modelAN(params{2}, model_params); % HSR for IC input
SFIE{2} = wrapperIC(AN_HSR{2}.an_sout, params{2}, model_params); % SFIE output

%% Run broad inhibition models
%
% % Run synth timbre models
% for ii = 1:2
% 	if ii == 1 % BS
% 		% model_params.lm_params = [0.25 0.25 0];
% 		% oct_range = 0.75;
% 		% model_params.BMF = [100 100 100];
% 		model_params.lm_params = [0.19 0 0.001];
% 		oct_range = 0.5;
% 		model_params.BMF = [300 38 10];
% 	else % BE
% 		% model_params.lm_params = [0.4 0.4 0];
% 		% oct_range = 0.5;
% 		% model_params.BMF = [100 100 100];
% 		model_params.lm_params = [1 0.28 0.001];
% 		oct_range = 0.625;
% 		model_params.BMF = [87 164 111];
% 	end
%
% 	% Model parameters
% 	model_params.type = 'LateralInhibition';
% 	model_params.range = 1; % 1 = population model, 2 = single cell model
% 	model_params.species = 1; % 1 = cat, 2 = human
%
% 	model_params.nAN_fibers_per_CF = 5;
% 	model_params.cohc = 1; % (0-1 where 1 is normal)
% 	model_params.cihc = 1; % (0-1 where 1 is normal)
% 	model_params.nrep = 1; % how many times to run the AN model
% 	model_params.implnt = 1; % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
% 	model_params.noiseType = 1; % 0 = fixed fGn, 1 = variable fGn) - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
% 	model_params.which_IC = 1; % 2 = ModFilt; 1 = SFIE model
% 	model_params.onsetWin = 0.020; % exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
% 	model_params.fiberType = 3; % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
% 	model_params.CFs = logspace(log10(220), log10(10000), 100);
% 	model_params.CF_range = [200 10000];
% 	model_params.num_CFs = 100;
% 	model_params.lateral_CFs = [model_params.CFs*2^(-1*oct_range); model_params.CFs; model_params.CFs*2^oct_range]';
%
% 	% Lateral model parameters
% 	model_params.config_type = 'BS inhibited by off-CF BS';
%
% 	% Run model
% 	AN_HSR{1} = modelLateralAN(params{1}, model_params);
% 	SFIE_temp = wrapperIC(AN_HSR{1}, params{1}, model_params);
% 	% SFIE = modelLateralSFIE(params{1}, model_params,...
% 	% 	AN_HSR.an_sout, AN_HSR.an_sout_lo, AN_HSR.an_sout_hi,...
% 	% 	'CS_params', lm_params);
%
% 	AN_HSR{1}.average_AN_sout = [AN_HSR{1}.average_AN_sout_lo; AN_HSR{1}.average_AN_sout; AN_HSR{1}.average_AN_sout_hi];
% 	if ii == 1
% 		SFIE{1}.average_ic_sout_BS = SFIE_temp.average_ic;
% 		SFIE{1}.ic_BS = SFIE_temp.ic;
% 	else
% 		SFIE{1}.average_ic_sout_BE = SFIE_temp.average_ic;
% 		SFIE{1}.ic_BE = SFIE_temp.ic;
% 	end
%  end
%
% %% Run MTF Models
%
% for ii = 1:2
% 	if ii == 1 % BS
% 		% model_params.lm_params = [0.25 0.25 0];
% 		% oct_range = 0.75;
% 		% model_params.BMF = [100 100 100];
% 		model_params.lm_params = [0.19 0 0.001];
% 		oct_range = 0.5;
% 		model_params.BMF = [300 38 10];
% 	else % BE
% 		% model_params.lm_params = [0.4 0.4 0];
% 		% oct_range = 0.5;
% 		% model_params.BMF = [100 100 100];
% 		model_params.lm_params = [1 0.28 0.001];
% 		oct_range = 0.625;
% 		model_params.BMF = [87 164 111];
% 	end
%
% 	% Model parameters
% 	model_params.type = 'Lateral Model';
% 	model_params.range = 2; % 1 = population model, 2 = single cell model
% 	model_params.species = 1; % 1 = cat, 2 = human
% 	model_params.num_CFs = 1;
% 	model_params.nAN_fibers_per_CF = 5;
% 	model_params.cohc = 1; % (0-1 where 1 is normal)
% 	model_params.cihc = 1; % (0-1 where 1 is normal)
% 	model_params.nrep = 1; % how many times to run the AN model
% 	model_params.implnt = 1; % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
% 	model_params.noiseType = 1; % 0 = fixed fGn, 1 = variable fGn) - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
% 	model_params.which_IC = 1; % 2 = ModFilt; 1 = SFIE model
% 	model_params.onsetWin = 0.020; % exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
% 	model_params.fiberType = 3; % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
% 	model_params.CFs = CF;
% 	model_params.lateral_CFs = [CF*2^(-1*oct_range), CF, CF*2^oct_range];
% 	model_params.CF_range = CF;
%
% 	% Lateral model parameters
% 	model_params.config_type = 'BS inhibited by off-CF BS';
%
%
% 	% Run model
% 	AN_HSR{2} = modelLateralAN(params{2}, model_params);
% 	SFIE_temp = modelLateralSFIE_BMF(params{2}, model_params,...
% 		AN_HSR{2}.an_sout, AN_HSR{2}.an_sout_lo, AN_HSR{2}.an_sout_hi,...
% 		'CS_params', model_params.lm_params,'BMFs', model_params.BMF);
% 	if ii == 1
% 		SFIE{2}.average_ic_sout_BS = SFIE_temp.avIC;
% 	else
% 		SFIE{2}.average_ic_sout_BE = SFIE_temp.avIC;
% 	end
% end


%% Save / load models
%
% save(fullfile(datapath, 'Hypothesis_broadinh_rabbit.mat'), 'AN_HSR', 'SFIE', 'params', 'model_params')
% % filename = 'Hypothesis_broadinh_cat.mat';
% % load(fullfile(datapath, filename), 'AN_HSR', 'SFIE', 'params', 'model_params')
% filename = 'fig1_hypothesis_broadinh_rabbit';

%% Plot temporal

CFs = AN_HSR{1}.CFs;

% Figure parameters
CF_list = [875 1200 1550];
start_time = 0.1; % s - for plotting
start  = start_time * params{1}.Fs;
stop_time = 0.115; % s
stop = stop_time * params{1}.Fs;
iplot = 0; % step thru CFs within each panel

for CF_plot = CF_list  % for TIN response to 1000 Hz tone
    iplot = iplot + 1;

    % AN model responses
    vihc = model_IHC(params{1}.stim,CF_plot,model_params.nrep,1/params{1}.Fs,...
        params{1}.dur*1.2,model_params.cohc,model_params.cihc,model_params.species);
    [an_sout,~,~] = model_Synapse(vihc,CF_plot,model_params.nrep,1/params{1}.Fs,...
        model_params.fiberType,model_params.noiseType,model_params.implnt);

    % Plot AN Temporal
    t = (1:length(an_sout))/params{1}.Fs; % time vector for plots

    h(iplot) = subplot(5, 5, 11+iplot);
    hold on
    set(gca,'fontsize',14, 'xtick',[100 125 150], 'YDir', 'reverse')

    % Duplicate the AN responses for Fluctuation profile plot
    plot(an_sout(start:stop), t(start:stop)*1e3,'Color', '#44AA99',...
        'linewidth',linewidth)
    [peaks_vals,peak_locations] = findpeaks(an_sout(start:stop),params{1}.Fs,...
        'MinPeakProminence',100);
    plot(peaks_vals, (peak_locations + start_time)*1e3,'Color', '#117733',...
        'linewidth',linewidth) % add envelope

    ylim([start_time*1e3, stop_time*1e3])
    xlim([0 1000]); % freq

    if iplot == 1
        ylabel('Time (ms)')
        yticks([100 115])
        yticklabels([100 115])
    elseif iplot == 2
        yticks([100 115])
        yticklabels([])
    else
        yticks([100 115])
        yticklabels([])
    end
    set(gca,'fontsize',fontsize)
    xticks([0 1000])
    grid on
end

%% Plot stimulus

plot_range = [300 6000];
ticks = [200 500 1000 2000 5000];

% Stimulus Creation
h(4) = subplot(5,5,1:5);
hold on
harmonics = params{1}.Delta_F:params{1}.Delta_F:10000;
num_harmonics = length(harmonics);
npts = params{1}.dur * params{1}.Fs; % # pts in stimulus
t = (0:(npts-1))/params{1}.Fs; % time vector
component_scales_linear = 10.^(-1*abs(log2(harmonics/params{1}.fpeak_mid)*...
    params{1}.g)/20);
stimulus = zeros(1,npts);
for iharm = 1:num_harmonics
    comp_freq = harmonics(iharm);
    component = component_scales_linear(iharm) * sin(2*pi*comp_freq*t);
    stimulus = stimulus + component;          %Add component to interval
end
Level_scale = 20e-6*10.^(params{1}.spl/20) * (1/rms(stimulus));
component_scales_linear = Level_scale * component_scales_linear;

% Now, make the stimulus for this_fpeak
xline(CF, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
xline(CF_list(1), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
xline(CF_list(3), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);

level = zeros(num_harmonics, 1);
for iharm = 1:num_harmonics
    stim = component_scales_linear(iharm) * sin(2*pi*harmonics(iharm)*t);

    % Plot each stimulus
    y = fft(stim);
    mdB = 20*log10(abs(y));
    level(iharm) = findpeaks(mdB(1:length(mdB)/2), 'MinPeakProminence',200);
    stem(harmonics(iharm), level(iharm), 'Marker', 'none', 'LineWidth', ...
        linewidth, 'Color', '#882255');
end

% Plot envelope of stimulus
plot(harmonics, level, 'LineWidth', linewidth, 'Color', '#882255', 'LineStyle', ':');
set(gca,'fontsize',fontsize)
ylabel('Level (dB SPL)')
ylim([0 70])
grid on
set(gca, 'XScale', 'log')
hold off
xlim(plot_range)
xticks(ticks)
xLabel = xlabel('Freq. (Hz)');
xLabel.Position(1) = h(4).XLim(2); % Set x-position to the right edge

%% AN Plot
h(5) = subplot(5, 5, 6:10);
avAN = AN_HSR{1}.average_AN_sout;

hold on
plot(CFs, avAN, 'linewidth', linewidth, 'color', '#117733');
set(gca,'fontsize',fontsize)
grid on
set(gca, 'XScale', 'log')
xlim(plot_range)
ylim([0 300])
xticks(ticks)
xline(CF, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
xline(CF_list(1), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
xline(CF_list(3), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
xLabel = xlabel('CF (Hz)');
ylabel('Avg. Rate (sp/s)')
xLabel.Position(1) = h(5).XLim(2); % Set x-position to the right edge

%% IC BE Plot
h(6) = subplot(5, 5, 17:20);
avBE = SFIE{1}.average_ic_sout_BE;

fs = params{1}.Fs;
spike_hist = squeeze(SFIE{1}.ic_BE(:,1,:));
VS = calcVS(params{1}, spike_hist, fs);
yyaxis right
plot(CFs, VS, 'linewidth', linewidth, 'Color','#d95f02')
ylabel('Sync to 200 Hz                            ')

yyaxis left
hold on
plot(CFs, avBE, 'linewidth', linewidth, 'color', 'k'); %[0, 0.4470, 0.7410]);
set(gca,'fontsize',fontsize)
grid on
set(gca, 'XScale', 'log')
xlim(plot_range)
ylim([0 50])
xticks(ticks)
yticks([0 25 50])
xticklabels([])
xline(CF, '--', 'Color', [0.4 0.4 0.4], 'linewidth',linewidth); % Add CF line
xline(CF_list(1), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
xline(CF_list(3), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
ax = gca;
ax.YAxis(1).Color = 'k';

%% IC BS Plot
h(7) = subplot(5, 5, 22:25);
avBS = SFIE{1}.average_ic_sout_BS;

% IC temporal plot
fs = params{1}.Fs;
spike_hist = squeeze(SFIE{1}.ic_BS(:,1,:));
%spike_hist = mean(SFIE{1}.ic_BS, 2);
%spike_hist = squeeze(spike_hist);

VS = calcVS(params{1}, spike_hist, fs);
yyaxis right
plot(CFs, VS, 'linewidth', linewidth, 'Color','#d95f02')

yyaxis left
hold on
plot(CFs, avBS, 'linewidth', linewidth, 'color', 'k'); %[0, 0.4470, 0.7410]);
set(gca,'fontsize',fontsize)
grid on
set(gca, 'XScale', 'log')
xlim(plot_range)
ylim([0 50])
xticks(ticks)
yticks([0 25 50])
xLabel = xlabel('CF (Hz)');
xline(CF, '--', 'Color', [0.4 0.4 0.4], 'linewidth', linewidth); % Add CF line
xline(CF_list(1), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
xline(CF_list(3), ':','Color', [0.4 0.4 0.4], 'linewidth', linewidth);
h(7).YAxis(1).Color = 'k';
xLabel.Position(1) = h(7).XLim(2); % Set x-position to the right edge

%% Plot MTFs

for ineuron = 1:2

    if ineuron == 1
        h(8) = subplot(5, 5, 16);
        model = SFIE{2}.average_ic_sout_BE;
    else
        h(9) = subplot(5, 5, 21);
        model = SFIE{2}.average_ic_sout_BS;
    end
    [~, avBE, ~] = plotMTF(params{2}, model, 0);
    hold on
    line([1 params{2}.all_fms(end)], [1 1]*avBE(1),'Color',[0.4 0.4 0.4], ...
        'LineWidth', linewidth);
    plot(params{2}.all_fms,smooth(avBE),'-k', 'LineWidth', linewidth) % smoothed MTF
    hold off
    xtick = [1 2 5 10 20 50 100 200 500];
    xlim(xtick([1 end]))
    set(gca,'XTick',xtick,'XScale', 'log')
    grid on
    set(gca,'FontSize',fontsize)
    yticklabels([])
    if ineuron == 1
        %ylim([22 32])
        %ylim([6.5 11])
        ylabel('Avg. Rate (sp/s)                         ')
        hLegend = legend('Unmod.', 'Location','northwest', 'EdgeColor',...
            'none', 'box', 'off', 'fontsize', legsize);
        hLegend.ItemTokenSize = [12,8];
        title('MTF')
        xticklabels([])
    else
        %ylim([18 24])
        %ylim([16 30])
        xticklabels([])
        xlabel('Mod. Freq.')
    end
end

%% Move positions

bottom = fliplr(linspace(0.07, 0.83, 5));
bottom(3) = 0.43;
bottom(4) = 0.23;
height = 0.135;

set(h(4), 'Position',[0.27 bottom(1) 0.655 height]);
set(h(5), 'Position',[0.27 bottom(2) 0.655 height]);

set(h(1), 'Position',[0.35 bottom(3) 0.13 height]);
set(h(2), 'Position',[0.52 bottom(3) 0.13 height]);
set(h(3), 'Position',[0.69 bottom(3) 0.13 height]);

set(h(8), 'Position',[0.11 bottom(4) 0.123 height]);
set(h(6), 'Position',[0.27 bottom(4) 0.655 height]);

set(h(9), 'Position',[0.11 bottom(5) 0.123 height]);
set(h(7), 'Position',[0.27 bottom(5) 0.655 height]);

%% Labels / Annotations / Positions

annotation('textbox',[0.27 0.84 0.15 0.1], 'String','Stimulus',...
    'FontSize',titlesize,'EdgeColor','none', 'Rotation',90, ...
    'FitBoxToText','off', 'FontWeight','bold');
annotation('textbox', [0.27 0.66 0.15 0.1],'String','AN Rate',...
    'FontSize',titlesize,'FitBoxToText','off',...
    'EdgeColor','none', 'Rotation',90, 'FontWeight','bold');
annotation('textbox',[0.27 0.43 0.2 0.1],'String','AN Temporal',...
    'FontSize',titlesize,'FitBoxToText','off',...
    'EdgeColor','none', 'Rotation',90, 'FontWeight','bold');
annotation('textbox',[0.14 0.11 0.15 0.1],'String','IC BS',...
    'FontSize',titlesize, 'FontWeight','bold',...
    'FitBoxToText','off','EdgeColor','none', 'Rotation',90);
annotation('textbox',[0.14 0.27 0.15 0.1],'String','IC BE',...
    'FontSize',titlesize,'FitBoxToText','off',...
    'EdgeColor','none', 'Rotation',90, 'FontWeight','bold');

% Create lines
annotation('line',[0.412 0.505],[0.43 0.361],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle',':');
annotation('line',[0.412 0.50],[0.566 0.637],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle',':');

annotation('line',[0.735 0.630],[0.43 0.361],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle',':');
annotation('line',[0.735 0.630],[0.566 0.637],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle',':');

annotation('line',[0.573 0.573],[0.566 0.637],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle','--');
annotation('line',[0.573 0.573],[0.43 0.361],'Color',[0.4 0.4 0.4],...
    'LineWidth',linewidth,'LineStyle','--');

% Set annotations
annotation('textbox',[0.11 bottom(1)+0.135 0.0826 0.0385],'String',{'A'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.11 bottom(2)+0.135 0.0826 0.0385],'String',{'B'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.11 bottom(3)+0.135 0.0826 0.0385],'String',{'C'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0 bottom(4)+0.135 0.0826 0.0385],'String',{'D'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0 bottom(5)+0.135 0.0826 0.0385],'String',{'E'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');


%% Save figure

if save_fig == 1
    filename = 'fig1_hypothesis_SFIE';
    save_figure(filename)
end

end
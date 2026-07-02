function supp2_temporal_harms(save_fig)
% FIG_S2_TEMPORAL_HARMS Generates Supplementary Figure S2 evaluating temporal phase-locking.
%
% PURPOSE:
%   This function visualizes the temporal phase-locking characteristics of twenty
%   representative single neurons responding to synthetic timbre stimulus tokens. It evaluates
%   harmonic synchrony across multiple frequency channels by computing localized Vector Strength
%   (VS) indices over the fundamental frequency components and individual harmonic nodes.
%   Statistically significant phase-locking bounds are isolated ($p < 0.01$) and mapped using
%   synchronized spectrotemporal matrix heatmap overlays relative to each cell's characteristic
%   frequency (CF).
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a 4x5 column-major array matrix showing phase-locking metrics. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - analyzeST_Temporal()      : Extracts localized temporal synchrony and Fourier vector bounds
%   - smooth_rates()            : Smooths physiological vector tracks relative to CF
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up (Original framework dated for 2025 manuscript)

%% Load in spreadsheet

[~, datapath, ~, ppi] = get_paths();
spreadsheet_name = 'PutativeTable.xlsx';
sessions = readtable(fullfile(datapath, spreadsheet_name), ...
    'PreserveVariableNames',true);

%% Load in example

figure('Position',[50,50,6.6*ppi,4.2*ppi])
tiledlayout(4, 5, "TileSpacing","compact", 'TileIndexing','columnmajor')
labelsize = 13;
h = gobjects(20, 1);

%%

fpeaks_re_CF = cell(20,1);
VS = cell(20,1);
ind = [1, 6, 11, 16, 2, 7, 12, 17, 3, 8, 13, 18, 4, 9, 14, 19, 5, ...
    10, 15, 20];
for ii = 1:20

    switch ii
        case 1
            putative = 'R25_TT1_P8_N01'; % blurred at CF
        case 2
            putative = 'R25_TT1_P8_N02'; % blurred at CF
        case 3
            putative = 'R25_TT4_P7_N01'; % blurred at CF
        case 4
            putative = 'R29_TT4_P2_N03'; % blurred at CF
        case 5
            putative = 'R29_TT4_P2_N09'; % 2 peaks
        case 6
            putative = 'R29_TT1_P3_N02'; % 2 peaks
        case 7
            putative = 'R29_TT4_P2_N10'; % 2 peaks
        case 8
            putative = 'R29_TT1_P3_N05';
        case 9
            putative = 'R25_TT1_P8_N15'; %'R25_TT1_P8_N03'; % 2 peaks, odd
        case 10
            putative = 'R29_TT1_P2_N03'; % 2 peaks, odd
        case 11
            putative = 'R25_TT1_P8_N04'; %'R29_TT4_P2_N16'; % 2 peaks, odd
        case 12
            putative = 'R25_TT2_P9_N02'; % % 2 peaks, odd
        case 13
            putative = 'R29_TT4_P3_N04'; % multiple
        case 14
            putative = 'R29_TT3_P2_N05'; % multiple
        case 15
            putative = 'R29_TT3_P2_N04'; % multiple
        case 16
            putative = 'R25_TT3_P8_N06'; % multiple
        case 17
            putative = 'R29_TT4_P5_N02'; %'R24_TT1_P12_N01';
        case 18
            putative = 'R29_TT3_P5_N03'; % rate only
        case 19
            putative = 'R27_TT4_P8_N10';
        case 20
            putative = 'R27_TT2_P8_N05';
    end
    filename = sprintf('%s.mat', putative);
    load(fullfile(datapath,'neural_data', filename), 'data');
    index = find(cellfun(@(s) strcmp(putative, s), sessions.Putative_Units));
    CF = sessions.CF(index);

    %% Analysis

    % Synthetic timbre analysis
    params = data(7, 2);
    params = params(~cellfun(@isempty, params));
    data_ST  = analyzeST(params, CF);
    data_ST = data_ST{1};
    param = params{1};
    temporal = analyzeST_Temporal(param, data_ST);

    % Vector strength calculation
    fpeaks_re_CF{ii} = log2(param.fpeaks/CF);
    num_fpeaks = length(param.fpeaks);
    VS_smooth = smooth_rates(temporal.VS,zeros(num_fpeaks, 1),...
        ones(num_fpeaks, 1), CF);
    VS{ii} = VS_smooth;

    %% Plot

    h(ind(ii)) = subplot(4, 5, ind(ii));
    VS_harms2 =flipud(temporal.VS_harms);
    p_vals =flipud(temporal.VS_p_harms);
    sig = p_vals<0.01;
    VS_harms2(~sig) = NaN;
    imagesc(1:10, data_ST.fpeaks./1000, VS_harms2);
    hold on
    yline(CF/1000, 'r', 'LineWidth',2)
    xlim([0.51 10.51])
    clim([0 1])

    if ii == 12
        xlabel('Harmonic Number')
    end

    if ~ismember(ii, [4, 8, 12, 16, 20])
        xticklabels([])
    end

    if ii == 17
        c = colorbar;
        c.Label.String = 'Vector Strength';
    end

    if ismember(ii, 3)
        ylabel('                                Spectral Peak Freq. (Hz)')
    end


end

%% Set positions

height = 0.17;
width = 0.13;
bottom = fliplr(linspace(0.08, 0.75, 4));
left = linspace(0.075, 0.77, 5);

left = repmat(left, 1, 5);
bottom = reshape(repmat(bottom, 5, 1), 1, []);

for ii = 1:20
    set(h(ii), 'Position', [left(ii) bottom(ii) width height])
end

% Annotations
left = linspace(0.03, 0.74, 5);

annotation('textbox',[left(1) 0.95 0.0826 0.0385],'String',{'A'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(2) 0.95 0.0826 0.0385],'String',{'B'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(3) 0.95 0.0826 0.0385],'String',{'C'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(4) 0.95 0.0826 0.0385],'String',{'D'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[left(5) 0.95 0.0826 0.0385],'String',{'E'},...
    'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Save figure

if save_fig == 1
    filename = 'fig_s2_temporal_harms';
    save_figure(filename)
end

end
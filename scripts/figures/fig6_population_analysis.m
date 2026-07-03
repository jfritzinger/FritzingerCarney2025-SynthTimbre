function fig6_population_analysis(save_fig)
% FIG6_POPULATION_ANALYSIS Generates Figure 6 showing dataset-wide population analysis.
%
% PURPOSE:
%   This function produces a comprehensive population summary from large-scale neural
%   recordings. It generates an aligned colormap landscape (imagesc) of z-scored physiological
%   profiles sorted by characteristic frequency (CF), highlights overlapping response curves,
%   and visualizes statistical changes across acoustic criteria. It compiles stacked bar
%   charts and comparative line tracks summarizing distribution percentiles and Q-factor metrics
%   across Modulation Transfer Function (MTF) types (BE, BS, Hybrid, Flat) and binaural states.
%
% INPUTS:
%   save_fig - Binary flag (1 = save figure to disk, 0 = display only)
%
% OUTPUTS:
%   Generates a complex multi-panel population summary figure. Saves if save_fig = 1.
%
% DEPENDENCIES / EXTERNAL FUNCTIONS CALLED:
%   - getPaths()                : Custom path configuration script
%   - analyzeST()               : Analyzes synthetic timbre neural data structure
%   - analyzeRM()               : Analyzes Response Area / Rate-Intensity Matrix data
%   - save_figure()             : Custom figure export script
%
% AUTHOR: J. Fritzinger
% UPDATED: 2026 Repository Clean-up

%% Setup parameters and data loading
[~, datapath, ~, ppi] = get_paths(); 
spreadsheet_name = 'st_response_metrics_rate.xlsx';
table_data = readtable(fullfile(datapath, spreadsheet_name));

figure('position', [50, 50, 3.2*ppi, 7.5*ppi])
h = gobjects(9, 1);
backgroundcolor = [0.8 0.8 0.8];
legsize = 6;
fontsize = 7;
titlesize = 8;
linewidth = 1;
labelsize = 13;

spl = [43, 63, 73, 83];
ispl = 2;
types = {'Peak', 'Dip', 'Flat'};

% Track data across profiles using a unified cell array structure
array_z = cell(3, 1);
CFs_stored = cell(3, 1);

%% Process profiles sorted by CF
for iMTF = 1:3
    isspl = table_data.SPL == spl(ispl);
    ispeak = strcmp(table_data.Type, types{iMTF});
    is200 = table_data.F0 == 200;
    isbin = table_data.binmode == 2;
    isall = isspl & ispeak & is200 & isbin;
    
    putatives = table_data.Putative(isall);
    peak_freqs = table_data.Freq(isall);
    num_index = size(putatives, 1);
    CFs = table_data.CF(isall);
    current_z_mat = NaN(num_index, 10000);
    
    for isesh = 1:num_index
        putative = putatives{isesh};
        CF = CFs(isesh);
        peak_freq = peak_freqs(isesh);
        
        load(fullfile(datapath, 'neural_data', [putative '.mat']), 'data');
        params_ST = data(5+ispl, 2);
        data_ST = analyzeST(params_ST, CF);
        data_ST = data_ST{1};
        
        params_RM = data{2,2};
        data_RM = analyzeRM(params_RM);
        spont = data_RM.spont;
        rate = data_ST.rates_sm - spont;
        fpeaks = data_ST.fpeaks;
        
        if iMTF == 1 || iMTF == 2
            fpeaks_re_CF = log2(fpeaks/peak_freq);
        else
            fpeaks_re_CF = log2(fpeaks/CF);
        end
        
        f = linspace(-3, 3, 10000);
        [~, f_ind_start] = min(abs(fpeaks_re_CF(2)-f));
        [~, f_ind_end] = min(abs(fpeaks_re_CF(end)-f));
        
        f_interp = linspace(f(f_ind_start), f(f_ind_end), f_ind_end - f_ind_start);
        r_interp = interp1(fpeaks_re_CF, rate, f_interp, 'spline');
        z_rate = zscore(r_interp);
        current_z_mat(isesh, f_ind_start:f_ind_end-1) = z_rate;
    end
    array_z{iMTF} = current_z_mat;
    CFs_stored{iMTF} = CFs;
end

%% Plot Landscaping Visualizations
plot_types = {'Peak', 'Dip', 'Slope'};
f = linspace(-3, 3, 10000);

for ii = 1:3
    [~, max_ind] = sort(CFs_stored{ii});
    CF_order = array_z{ii}(max_ind, :);
    
    if ii == 1
        h(1) = subplot(5, 3, [1 4 7 10]);
    elseif ii == 2
        h(3) = subplot(5, 3, 2);
    else
        h(5) = subplot(5, 3, 8);
    end
    
    hh = imagesc(f, 1:size(CF_order, 1), CF_order);
    xline(0, 'k')
    set(hh, 'AlphaData', ~isnan(CF_order))
    set(gca, 'color', backgroundcolor);
    yticklabels([])
    xlim([-1 1])
    xticks([-1 0 1])
    clim([-2.2 2.7])
    xticklabels([])
    set(gca, 'fontsize', fontsize)
    title(plot_types{ii}, 'fontsize', titlesize)
    
    if ii == 1
        a = colorbar('position', [0.0879, 0.1458, 0.0163, 0.1315]);
        a.Label.String = 'Z-score';
    end
    
    if ii == 1
        h(2) = subplot(5, 3, 13);
    elseif ii == 2
        h(4) = subplot(5, 3, 5);
    else
        h(6) = subplot(5, 3, 11);
    end
    
    hold on
    for iii = 1:size(CF_order, 1)
        patch([f, NaN], [CF_order(iii, :), NaN], 'w', 'EdgeColor', 'k', 'LineWidth', linewidth, 'EdgeAlpha', 0.2);
    end
    
    if ii == 1
        xlabel({'Spectral Peak Freq'; 'w.r.t. Peak (Oct.)'})
    elseif ii == 2
        xlabel({'Spectral Peak Freq'; 'w.r.t. Dip (Oct.)'})
    else
        xlabel({'Spectral Peak Freq'; 'w.r.t. CF (Oct.)'})
    end
    xline(0, 'k')
    yline(0, 'k')
    xlim([-1 1])
    ylim([-2.2 2.7])
    ylabel('Z-score')
    set(gca, 'fontsize', fontsize)
    box off
end

%% Plot stacked bar percentage distribution
isBin = table_data.binmode == 2;
isSPL = table_data.SPL == spl(ispl);
percent_peak = zeros(4, 1);
percent_dip = zeros(4, 1);
percent_flat = zeros(4, 1);

for iMTF = 1:4
    if iMTF == 1
        isMTF = strcmp(table_data.MTF, 'BS');
    elseif iMTF == 2
        isMTF = strcmp(table_data.MTF, 'BE');
    elseif iMTF == 3
        isMTF = contains(table_data.MTF, 'H');
    else
        isMTF = strcmp(table_data.MTF, 'F');
    end
    
    index = isSPL & isMTF & isBin;
    num_dip = sum(strcmp(table_data.Type(index), 'Dip'));
    num_peak = sum(strcmp(table_data.Type(index), 'Peak'));
    num_flat = sum(strcmp(table_data.Type(index), 'Flat'));
    
    total_neurons = sum([num_peak num_dip num_flat]);
    if total_neurons > 0
        percent_peak(iMTF) = num_peak / total_neurons * 100;
        percent_dip(iMTF) = num_dip / total_neurons * 100;
        percent_flat(iMTF) = num_flat / total_neurons * 100;
    end
end

% Corrected structural matrix initialization to eliminate empty graphics indices
percent_all = [percent_peak, percent_dip, percent_flat];
h(7) = subplot(5, 3, 14);
bar(percent_all, 'stacked')
xticklabels({'BS', 'BE', 'Hybrid', 'Flat'})

hleg1 = legend('Peak', 'Dip', 'Slope', 'Location', 'northwest', ...
    'numcolumns', 3, 'box', 'off', 'position', [0.5500, 0.4386, 0.4669, 0.025]);
hleg1.ItemTokenSize = [8,8];
ylabel('% Neurons')
xlabel('MTF Type')
ylim([0 100])
yticks(0:20:100)
set(gca, 'fontsize', fontsize)
box off

%% Q-factor metrics across sub-regimes

tables = readtable(fullfile(datapath, "LMM", "st_response_metrics_rate_excludeflat.xlsx"));
h(8) = subplot(5, 3, 9);
is200 = tables.F0 == 200;
isBE = strcmp(tables.MTF, 'BE');
isBS = strcmp(tables.MTF, 'BS');
isH = contains(tables.MTF, 'H');
isF = strcmp(tables.MTF, 'F');
Q_all2 = zeros(2, 4);
Q_sem2 = zeros(2, 4);

for ibin = 1:2
    isbin = tables.binmode == ibin;
    ind_BE = isbin & is200 & isBE;
    ind_BS = isbin & is200 & isBS;
    ind_H = isbin & is200 & isH;
    ind_F = isbin & is200 & isF;
    
    Q_all2(ibin, :) = [mean(tables.Q(ind_BE), 'omitnan') mean(tables.Q(ind_BS), 'omitnan') ...
                       mean(tables.Q(ind_H), 'omitnan') mean(tables.Q(ind_F), 'omitnan')];
    Q_sem2(ibin, :) = [std(tables.Q(ind_BE), 'omitnan')/sqrt(sum(~isnan(tables.Q(ind_BE))))...
                       std(tables.Q(ind_BS), 'omitnan')/sqrt(sum(~isnan(tables.Q(ind_BS))))...
                       std(tables.Q(ind_H), 'omitnan')/sqrt(sum(~isnan(tables.Q(ind_H))))...
                       std(tables.Q(ind_F), 'omitnan')/sqrt(sum(~isnan(tables.Q(ind_F))))];
end

hold on
errorbar(Q_all2(1, :), Q_sem2(1, :), 'LineWidth', linewidth, 'Color', '#1b9e77')
errorbar(Q_all2(2, :), Q_sem2(2, :), 'LineWidth', linewidth, 'Color', '#d95f02')
xticks(1:4)
xticklabels({'BE', 'BS', 'Hybrid', 'Flat'})
xlim([0.5 4.5])
ylim([0 6.5])
ylabel('Q')
xlabel('MTF Type')
hleg2 = legend('Contra', 'Diotic', 'Location', 'best', 'fontsize', legsize, 'box', 'off');
hleg2.ItemTokenSize = [8, 8];
set(gca, 'fontsize', fontsize)
grid on

%% Contra vs. Diotic Q-changes
h(9) = subplot(5, 3, 15);
is200 = tables.F0 == 200;
isPut = unique(tables.Putative);
BS_change = []; BE_change = []; H_change = []; F_change = [];
isSPL = tables.SPL == 63;

for iput = 1:length(isPut)
    isput_match = strcmp(tables.Putative, isPut{iput});
    isbin = tables.binmode == 2 & is200 & isput_match & isSPL;
    iscontra = tables.binmode == 1 & is200 & isput_match & isSPL;
    
    if any(isbin) && any(iscontra)
        q_change = sign(mean(tables.Q(isbin), 'omitnan') - mean(tables.Q(iscontra), 'omitnan'));
        MTF_type = unique(tables.MTF(isbin));
        if strcmp(MTF_type, 'BS')
            BS_change = [BS_change; q_change]; 
        elseif strcmp(MTF_type, 'BE')
            BE_change = [BE_change; q_change];
        elseif contains(MTF_type, 'H')
            H_change = [H_change; q_change]; 
        else
            F_change = [F_change; q_change]; 
        end
    end
end

bin_change1 = [sum(BE_change==-1) sum(BE_change==1)]./length(BE_change)*100;
bin_change2 = [sum(BS_change<=0) sum(BS_change==1)]./length(BS_change)*100;
bin_change3 = [sum(H_change==-1) sum(H_change==1)]./length(H_change)*100;
bin_change4 = [sum(F_change==-1) sum(F_change==1)]./length(F_change)*100;
bin_change = [bin_change1; bin_change2; bin_change3; bin_change4];

hold on
bars = bar(bin_change, 'stacked');
bars(1).FaceColor = '#1b9e77';
bars(2).FaceColor = '#d95f02';

xticks(1:4)
xticklabels({'BE', 'BS', 'Hybrid', 'Flat'})
xlim([0.5 4.5])
ylim([0 100])
yticks([0 25 50 75 100])
ylabel('Percent (%)')
xlabel('MTF Type')

hleg3 = legend('Contra Q > Diotic Q', 'Diotic Q > Contra Q', 'Location', 'north',...
    'fontsize', legsize, 'NumColumns', 1, 'box', 'off', 'position', ...
    [0.5657, 0.1275, 0.3163, 0.0395]);
hleg3.ItemTokenSize = [8, 8];
set(gca, 'fontsize', fontsize)
grid on

%% Explicit Multi-panel Coordinate Shifts
left = [0.08 0.57];
bottom = [0.05, 0.22, 0.36, 0.53, 0.625, 0.78, 0.87];
width = 0.36;
height = 0.08;

set(h(1), 'position', [left(1) 0.14 width 0.83])
set(h(2), 'position', [left(1) bottom(1) width height])
set(h(3), 'position', [left(2) bottom(7) width 0.1])
set(h(4), 'position', [left(2) bottom(6) width 0.09])
set(h(5), 'position', [left(2) bottom(5) width height])
set(h(6), 'position', [left(2) bottom(4) width 0.09])
set(h(7), 'position', [left(2) bottom(3) width height])
set(h(8), 'position', [left(2) bottom(2) width height])
set(h(9), 'position', [left(2) bottom(1) width height])

% Group Layout Annotations
lbl_bottom = bottom + height;
annotation('textbox',[0.0 lbl_bottom(7) 0.0826 0.0385],'String',{'A'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 lbl_bottom(7) 0.0826 0.0385],'String',{'B'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 lbl_bottom(5) 0.0826 0.0385],'String',{'C'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 lbl_bottom(3) 0.0826 0.0385],'String',{'D'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 lbl_bottom(2) 0.0826 0.0385],'String',{'E'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
annotation('textbox',[0.47 lbl_bottom(1) 0.0826 0.0385],'String',{'F'},'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');

%% Export Figure
if save_fig == 1
    filename = 'fig6_population_analysis';
    save_figure(filename)
end
end
function fig11_dog_analysis_plots(save_fig)

%% Load in fits  

[~, datapath, ~, ppi] = get_paths();
load(fullfile(datapath, 'dog_analysis.mat'), "R2_gauss_all", "R2_dog_all", "dog_analysis")
%addpath('/Users/jfritzinger/Projects/shared-models/DoG-model', '-begin')

%% Plot example fit 

fig = figure('Position',[50,50,3.356*ppi,3.2*ppi]);
tiledlayout(2, 2, 'Padding','compact')
legsize = 6;
fontsize = 7;
titlesize = 8;
labelsize = 13;
linewidth = 1;
scattersize = 12;
tokensize = [9, 4];

%% Plot example


putative = 'R24_TT2_P13_N02';
% putative = 'R27_TT3_P8_N01';
ind = cellfun(@(d) strcmp(d, putative), {dog_analysis.putative});

% Load in to get spont rate
load(fullfile(datapath, 'neural_data', [putative '.mat']))
params_RM = data{2, 2};
data_RM = analyzeRM(params_RM);
spont = data_RM.spont;

% Plot 
nexttile
hold on
errorbar(dog_analysis(ind).fpeaks/1000, dog_analysis(ind).rate, ...
	dog_analysis(ind).rate_std/sqrt(20), 'k','LineWidth',linewidth, ...
	'CapSize',2);
plot(dog_analysis(ind).fpeaks/1000, dog_analysis(ind).dog_predicted, ...
	'LineWidth',linewidth, 'color', 'b');
plot(dog_analysis(ind).fpeaks/1000, dog_analysis(ind).gaus_predicted,...
	'LineWidth',linewidth, 'color', '#1b9e77');
xline(dog_analysis(ind).CF/1000, ':', 'LineWidth',linewidth)
yline(spont, 'k')
ylabel('Avg. Rate (sp/s)')
xlabel('Spectral Peak Freq. (kHz)')
set(gca, 'fontSize', fontsize)
hleg = legend('Data', 'DoG', 'Gaussian', 'CF', 'Spont', 'fontsize', ...
	legsize, 'numcolumns', 2, 'location', 'north', 'box', 'off');
hleg.ItemTokenSize = tokensize;
grid on
xlim([dog_analysis(ind).fpeaks(1) dog_analysis(ind).fpeaks(end)]/1000)
ylim([0 76])

%% Plot filters 

% Plot DoG Parameters
nexttile
DOGparams = dog_analysis(ind).dog_params;
W = dog_model(dog_analysis(ind).fpeaks, DOGparams);
hold on
plot(dog_analysis(ind).fpeaks/1000,W, 'color', 'b', 'linewidth', linewidth)

Fs = 100000;
Gparams = dog_analysis(ind).gauss_params;
f = linspace(0, Fs/2, 100000);
W = gaussian_model(f, Gparams);
hold on
plot(f/1000,W, 'color', '#1b9e77', 'linewidth', linewidth)
xline(dog_analysis(ind).CF/1000, ':', 'linewidth', linewidth)

% Plot labels
set(gca, 'fontsize', fontsize)
ylabel('Amplitude')
xlabel('Frequency (kHz)')
xlim([dog_analysis(ind).fpeaks(1) dog_analysis(ind).fpeaks(end)]/1000)
set(gca, 'xscale', 'log')
grid on
xticks([0.1 0.2 0.5 1 2 5])
hleg = legend('DoG Kernel', 'Gaussian\newlineKernel', 'CF', 'fontsize',...
	legsize, 'location', 'northwest', 'box', 'off');
hleg.ItemTokenSize = tokensize;

%% Plot adjusted R^2 values 

sig = [dog_analysis.p_value]<0.05;
notsig = [dog_analysis.p_value]>0.05;

nexttile
scatter(R2_gauss_all(sig), R2_dog_all(sig),scattersize, 'filled',...
	'MarkerEdgeColor','k', 'MarkerFaceAlpha',0.6, 'MarkerFaceColor','b')
hold on
scatter(R2_gauss_all(notsig), R2_dog_all(notsig), scattersize, 'filled',...
	'MarkerEdgeColor','k', 'MarkerFaceAlpha',0.6, 'MarkerFaceColor',[0.4 0.4 0.4])
xlim([0 1])
ylim([0 1])
xticks([0 0.2 0.4 0.6 0.8 1])
yticks(0:0.2:1)
grid on
plot([0 1], [0 1], 'k', 'linewidth', linewidth)
xlabel('Gaussian Adjusted R^2')
ylabel('DoG Adjusted R^2')
set(gca, 'fontSize', fontsize)
msg = sprintf('%d sig.', sum(sig));
msg2 = sprintf('%d not sig.', sum(notsig));
legend(msg, msg2, 'Location','southeast', 'fontsize', legsize, 'box',...
	'off', 'position', [0.297973778307509,0.108506944444444,0.116299043911867,0.099784116698924])


%% Plot DoG parameter values 

% Get good fits
good_fit = [dog_analysis.R2_dog]>0.5;

% Plot 
all_dog_params = [dog_analysis(good_fit).dog_params];
all_dog_params = reshape(all_dog_params, 5,[])'; % 6 for OG, 5 for new
CFs = [dog_analysis(good_fit).CF];

% Un-log CF_exc, CF_inh
CF_exc = 10.^all_dog_params(:,5);
s_exc = 10.^all_dog_params(:,3);
s_inh = 10.^all_dog_params(:,4);
g_exc = all_dog_params(:,1);
g_inh = all_dog_params(:,2);

% Scatter plot of ratio of inhibition to excitation sigma and strengths 
ratio_sigma = log10(s_inh./s_exc);
ratio_g = log10(g_inh./g_exc);
nexttile
hold on
scatter(ratio_sigma, ratio_g, scattersize, 'filled', 'MarkerEdgeColor','k', 'MarkerFaceAlpha',0.5)
xline(0)
yline(0)
xlabel('Log BW Ratio (\sigma_i_n_h/\sigma_e_x_c)')
ylabel('Log Str Ratio (g_i_n_h/g_e_x_c)')
grid on
xlim([-2.1 2.3])
ylim([-1.5 1.5])
set(gca, 'fontsize', fontsize)

% Number of units in each quadrant
q1 = sum(ratio_sigma>0 & ratio_g>0);
q2 = sum(ratio_sigma<0 & ratio_g>0);
q3 = sum(ratio_sigma<0 & ratio_g<0);
q4 = sum(ratio_sigma>0 & ratio_g<0);

xL=xlim(gca);
yL=ylim(gca);
text(gca, 0.95*xL(1),0.99*yL(2),sprintf('n=%d', q2),...
	'HorizontalAlignment','left','VerticalAlignment','top', 'FontSize',legsize)
text(gca, 0.95*xL(2),0.99*yL(2),sprintf('n=%d', q1),...
	'HorizontalAlignment','right','VerticalAlignment','top', 'FontSize',legsize)
text(gca, 0.95*xL(1),0.99*yL(1),sprintf('n=%d', q3),...
	'HorizontalAlignment','left','VerticalAlignment','bottom', 'FontSize',legsize)
text(gca, 0.95*xL(2),0.99*yL(1),sprintf('n=%d', q4),...
	'HorizontalAlignment','right','VerticalAlignment','bottom', 'FontSize',legsize)


%% Annotate 

% Set annotations
left = [0.001 0.47 0.001 0.47];
bottom = [0.98 0.98 0.49 0.49];
label = {'A', 'B', 'C', 'D'};
for ii = 1:4
	annotation('textbox',[left(ii) bottom(ii) 0.0826 0.0385],'String',label{ii},...
		'FontWeight','bold','FontSize',labelsize,'EdgeColor','none');
end

%% Save figure 
if save_fig == 1
	filename = 'fig11_dog_analysis_plots';
	save_figure(filename)
end
end
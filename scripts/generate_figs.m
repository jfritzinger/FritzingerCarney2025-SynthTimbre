function generate_figs(fig_num)
% Generate manuscript figures and schematics
%   Generates specified figure for manuscript publication. Saves figures
%   automatically when save_fig flag is enabled.
%
%   Inputs:
%       fig_num - Figure identifier (numeric or string). Examples:
%                 - 3 or 'Fig. 3' for main figures
%                 - 'Fig. S1' for supplementary figures
%
%   Usage examples:
%       generate_figs(1)          % Generate Figure 1
%       generate_figs('Fig. 3')   % Generate Figure 3
%       generate_figs('Fig. S1')  % Generate Supplementary Figure 1
%
%   Path configuration:
%       Update base paths in getPathsWBTIN() or modify addpath commands
%       below to match your local directory structure.



% ======================== PATH CONFIGURATION =========================

% Modify get_paths() to set your local directories
[base, ~, ~, ~] = get_paths();

% Add helper functions to path
addpath(fullfile(base, 'scripts'), '-end')
addpath(fullfile(base, 'scripts', 'figures'), '-end')
addpath(fullfile(base, 'scripts', 'helper-functions'), '-end')
addpath(fullfile(base, 'scripts', 'stim-generation'), '-end')
addpath(fullfile(base, 'scripts', 'model-SFIE'), '-end'); 
addpath(fullfile(base, 'scripts', 'UR_EAR_2022a'), '-end'); 
addpath(fullfile(base, 'scripts', 'UR_EAR_2022a', 'source'), '-end'); 
addpath(fullfile(base, 'scripts', 'DoG-model'), '-end'); 
addpath(fullfile(base, 'scripts', 'model-energy'), '-end'); 
addpath(fullfile(base, 'scripts', 'model-lat-inh'), '-end'); 
% addpath(fullfile(base, 'scripts', 'analysis'), '-end'); 

% =====================================================================


% Convert numeric inputs to standardized figure strings
if isnumeric(fig_num)
    fig_str = ['Fig. ' num2str(fig_num)];
elseif ischar(fig_num) || isstring(fig_num)
    num = str2double(fig_num);
    if ~isnan(num)
        fig_str = ['Fig. ' num2str(num)];
    else
        fig_str = fig_num;
    end
else
    error('Invalid input type for fig_num. Must be numeric or string.');
end

% Plot manuscript figures
save_fig = 1;
switch fig_str
	case 'Fig. 1' 
		fig1_hypothesis(save_fig)
	case 'Fig. 2'
		fig2_stimulus(save_fig)
	case 'Fig. 3' 
		fig3_methods_peak_quantification(save_fig)
	case 'Fig. 4' 
		fig4_single_unit_examples(save_fig)
	case 'Fig. 5' 
		fig5_plot_temporal_examples(save_fig)
	case 'Fig. 6' 
		fig6_plot_population(save_fig)
	case 'Fig. 7' 
		fig7_changes_over_level(save_fig)
	case 'Fig. 8' 
		fig8_plot_thresholds(save_fig)
	case 'Fig. 9' 
		fig9_model_examples(save_fig)
	case 'Fig. 10' 
		fig10_model_Q_comparisons(save_fig)
	case 'Fig. 11' 
		fig11_dog_analysis_plots(save_fig)
	case 'Fig. S1' 
		supp1_data_distribution(save_fig)
	case 'Fig. S2' 
		supp2_model_temporal(save_fig)
	case 'Fig. S3'
		supp3_time_lapse_results(save_fig) 
	otherwise
		error(['Invalid figure identifier: %s \n' ...
			'Supported formats: 1-11 or ''Fig. 1''-''Fig. 11''\n' ...
			'Supplementary: ''Fig. S1''-''Fig. S6'''], fig_str)
end



end
function [base, datapath, savepath, ppi] = get_paths()


% ======================== PATH CONFIGURATION =========================

% Set your local directory
%base = 'YOUR/PATH/HERE';

% OR 
directory = pwd;
projectName = 'FritzingerCarney2025-Timbre';

idx = strfind(directory, projectName);
if ~isempty(idx)
    base = directory(1:idx(end) + length(projectName) - 1);
else
    error('Project folder name not found in path.');
end


% =====================================================================


% Basic paths for loading data and saving data
datapath = fullfile(base, 'data');
savepath = fullfile(base, 'figures');

% Setting figure sizes and font 
ppi = get(0, 'ScreenPixelsPerInch');
set(0,'DefaultAxesFontName', 'Arial')
set(0, 'defaultfigurecolor', 'w')

end
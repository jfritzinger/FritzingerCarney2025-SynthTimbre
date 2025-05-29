function [img, images] = addToPutativePDF(cluster, params, rabbit, images, fig)
import mlreportgen.dom.*

% Set figure size
if iscell(params)
	param = params{1}; % If multiple, plots only the first instance
else
	param = params;
end
num_DSIDs = length(params);
type = param.type;
switch param.type
	case 'char_spl'
		values = [2.6 2];
		param.binmode = 2;
	case 'char_ITD'
		values = [3 2.2];
		param.binmode = 2;
	case 'char_ILD'
		values = [3 2.2];
		param.binmode = 2;
	case 'typMTFN'
		values = [2.4 2];
	case 'Natural_Timbre'
		type = param.plot_type;
		if strcmp(param.plot_type, 'NatTimbre')
			values = [7.5 1.25*num_DSIDs]; % avg rate
		elseif strcmp(param.plot_type, 'NTrasters')
			values = [8.5 param.max_plots*0.2+0.2]; % rasters
		elseif strcmp(param.plot_type, 'NTperiodpsth')
			values = [8.5 param.max_plots*0.2+0.2]; % rasters
		elseif strcmp(param.plot_type, 'NTpsth')
			values = [8.5 param.max_plots*0.2+0.2]; % rasters
		end
	case 'type=RM'
		type = 'RM';
		values = [];
	case 'SCHR'
		values = [7.5 3];
	case 'STRF'
		values = [6 2];
		type = param.plot_type;
	case 'RVF'
		values = [3 2];
	case 'SPEC_slide'
		type = param.plot_type;
		switch param.SPEC_slide_type
			case 'Spectral_Centroid'
				if strcmp(param.plot_type, 'SC')
					values = [8 1.75]; % avg rate
				elseif strcmp(param.plot_type, 'SCwindowed') ||...
						strcmp(param.plot_type, 'SCwindowedsmu')
					if param.num_plots <= 4
						values = [7.5 3.7]; % SC windowed
					else
						values = [7.5 7.2]; % SC windowed
					end
				elseif strcmp(param.plot_type, 'SCrasters')
					values = [8.5 param.max_plots*0.25+0.4]; % rasters
				elseif strcmp(param.plot_type, 'SCpsth')
					values = [8.5 param.max_plots*0.25+0.4]; % rasters
				elseif strcmp(param.plot_type, 'SCperiodpsth')
					values = [10 param.max_plots*0.25+0.4]; % rasters
				elseif strcmp(param.plot_type, 'STsmoothed')
					values = [10 param.num_plots*0.25+0.4]; % rasters
				elseif strcmp(param.plot_type, 'STneuro')
					values = [7.5 2.5*ceil(param.num_plots/3)]; % 
				elseif strcmp(param.plot_type, 'SCSTRF')
					values = [7.5 2.5];
				end
			case 'Tone_Complex'
				values = [7.5 3];
		end
end

if ~strcmp(param.type, 'type=RM')
	changeFigureSize(values)
end


% Add the plot to the document
if ismac
	temppath = '/Users/jfritzinger/Documents/MATLAB/Temp_PDF';
else
	temppath = 'C:\Users\jfritzinger\Documents\MATLAB\Temp_PDF';
end
name = sprintf('%s_%s_TT%d_N%d_%d_%d.svg', type, rabbit, cluster.tetrode, cluster.neuron, param.dsid, param.binmode);
tempfilepath = fullfile(temppath, name);
print(fig, tempfilepath, '-dsvg');
img = Image(tempfilepath);
delete(fig) %delete plot figure window
images = [images {img}];

end

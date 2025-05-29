function model_output = modelLateralAN(stim_params, model_params)
% Function to run a lateral AN model without efferents
%
% Inputs:
%   stim_params - Struct containing stimulus and/or stimulus parameters.
%   Struct has stimulus specific fields. This struct needs to have at least:
%       .stim - Matrix that contains stimuli to be presented (num_stim x
%       stim)
%       .Fs - Sampling frequency
%       .dur - Duration of stimulus
%       .num_stim - Number of stimuli to be presented
%
%   model_params - Struct containing IC model params specific to this type
%   of model
%       .range - 1 = population model, 2 = single cell model
%       .species - 1 = cat, 2 = human
%       .BMF - best modulation frequency
%       .nAN_fibers_per_CF -
%       .cohc - OHC function (0-1 where 1 is normal), modifies gain
%       .cihc - IHC function (0-1 where 1 is normal), modifies threshold &
%       capture level
%       .nrep - number of repetitions
%       .fiberType - AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
%       .implnt - 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
%       .noiseType - 0 = fixed fGn, 1 = variable fGn - this is the 'noise' associated 
%		with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
%       .onsetWin - exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
%		.CFs - 3x1 array of the low, on, and high CFs to model. 
%
% Outputs:
%   model_output - Struct containing AN and IC modeling outputs
%       .an_sout - PSTH of AN fibers, on CF
%       .an_sout_hi - PSTH of AN fibers, above CF
%       .an_sout_lo - PSTH of AN fibers, below CF
%       .average_AN_sout - average rate response of AN fibers, on CF
%       .average_AN_sout_hi - average rate response of AN fibers, above CF
%       .average_AN_sout_lo - average rate response of AN fibers, below CF
%       .CFs - CF range used
%
% Other files required: model_IHC, model_Synapse, ffGn_ur_ear
%
% Author: J. Fritzinger
% Created: 2023-08-28; Last revision: 2024-10-10
%
% -------------------------------------------------------------------------


% Set up CF & BMF
onsetWin = model_params.onsetWin;
Fs = stim_params.Fs;
rng('default');     % added to accommodate older versions of Matlab, in cases
% for which rng has previously been run
rng('shuffle');     % seed the random number generator using time of day
BMF = repmat(model_params.BMF, 1, length(model_params.CFs));
[~, num_below_100] = find(model_params.CFs<100);
if num_below_100 > 0
	for CF_ind = 1:num_below_100(end)
		BMF(CF_ind) = model_params.CFs(CF_ind)/4;
	end
end
onset_num = onsetWin * Fs; % Calculates first point to be used in response
dur = length(stim_params.stim(1,:))/stim_params.Fs; % duration of waveform in sec

% Extract necessary parameters
num_stim = stim_params.num_stim;
num_CFs = 1; % number of on-CF frequencies, only set up for one currently
num_fibers = model_params.nAN_fibers_per_CF;
num_loops = num_stim * num_CFs;
Fs = stim_params.Fs;

% Preallocate output arrays
an_sout = zeros(num_loops, num_fibers, stim_params.dur*1.2*Fs);
an_sout_hi = zeros(num_loops, num_fibers, stim_params.dur*1.2*Fs);
an_sout_lo = zeros(num_loops, num_fibers, stim_params.dur*1.2*Fs);

% Prepare input data for each iteration
stim_index = reshape(repmat(1:num_stim, [1, num_CFs]), [num_loops, 1]);
CF_index = reshape(repmat(1:num_CFs, [num_stim, 1]), [num_loops, 1]);

% Create a cell array of input structures for each model iteration
inputs = arrayfun(@(i) struct('stimulus', stim_params.stim(stim_index(i), :), ...
	'CFs', model_params.CFs(CF_index(i), :), ...
	'nrep', model_params.nrep, ...
	'Fs', Fs, ...
	'dur', dur, ...
	'cohc', model_params.cohc, ...
	'cihc', model_params.cihc, ...
	'species', model_params.species, ...
	'fiberType', model_params.fiberType, ...
	'noiseType', model_params.noiseType, ...
	'implnt', model_params.implnt), ...
	1:num_loops, 'UniformOutput', false);

% Run the parfor loop
parfor i = 1:num_loops
    [an_sout(i, :, :), an_sout_lo(i, :, :), an_sout_hi(i, :, :)] = ...
		process_iteration(inputs{i}, num_fibers);
end

% Model output
an_sout = squeeze(mean(an_sout, 2)); % average over number of fibers
an_sout_hi = squeeze(mean(an_sout_hi, 2)); % average over number of fibers
an_sout_lo = squeeze(mean(an_sout_lo, 2)); % average over number of fibers

if num_loops == 1
	avg_an = mean(an_sout(onset_num:end));
	avg_an_lo = mean(an_sout_lo(onset_num:end));
	avg_an_hi = mean(an_sout_hi(onset_num:end));
else
	avg_an = mean(an_sout(:,onset_num:end), 2);
	avg_an_lo = mean(an_sout_lo(:,onset_num:end),2);
	avg_an_hi = mean(an_sout_hi(:,onset_num:end),2);
end

% PSTHs - makes the save file very large
model_output.an_sout = reshape(an_sout, num_stim, num_CFs,[]);
model_output.an_sout_hi = reshape(an_sout_hi, num_stim, num_CFs,[]);
model_output.an_sout_lo = reshape(an_sout_lo, num_stim, num_CFs,[]);

% Average rates
model_output.average_AN_sout = reshape(avg_an, [num_stim, num_CFs]);
model_output.average_AN_sout_hi = reshape(avg_an_hi, [num_stim, num_CFs]);
model_output.average_AN_sout_lo = reshape(avg_an_lo, [num_stim, num_CFs]);
model_output.CFs = model_params.CFs;

end

%% FUNCTIONS 

function [sout, sout_lo, sout_hi] = process_iteration(input, num_fibers)
% Processes each iteration of the model

% On-CF AN
vihc = model_IHC(input.stimulus, input.CFs(2), input.nrep, 1/input.Fs,...
	input.dur*1.2, input.cohc, input.cihc, input.species);
sout = zeros(num_fibers, input.dur*1.2*input.Fs);
for iAN = 1:num_fibers
	[sout(iAN, :), ~, ~] = model_Synapse(vihc, input.CFs(2), input.nrep,...
		1/input.Fs, input.fiberType, input.noiseType, input.implnt);
end

% Below-CF AN
vihc = model_IHC(input.stimulus, input.CFs(1), input.nrep, 1/input.Fs,...
	input.dur*1.2, input.cohc, input.cihc, input.species);
sout_lo = zeros(num_fibers, input.dur*1.2*input.Fs);
for iAN = 1:num_fibers
	[sout_lo(iAN, :), ~, ~] = model_Synapse(vihc, input.CFs(1), input.nrep,...
		1/input.Fs, input.fiberType, input.noiseType, input.implnt);
end

% Above-CF AN
vihc = model_IHC(input.stimulus, input.CFs(3), input.nrep, 1/input.Fs,...
	input.dur*1.2, input.cohc, input.cihc, input.species);
sout_hi = zeros(num_fibers, input.dur*1.2*input.Fs);
for iAN = 1:num_fibers
	[sout_hi(iAN, :), ~, ~] = model_Synapse(vihc, input.CFs(3), input.nrep,...
		1/input.Fs, input.fiberType, input.noiseType, input.implnt);
end
end

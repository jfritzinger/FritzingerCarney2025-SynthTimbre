function [model_output] = modelAN(stim_params, model_params)
% Function to run AN model without efferents, calls UR_EAR_2022a
% J. Fritzinger, updated 6/22/22
%
% Inputs:
%   stim_params: Struct containing stimulus and/or stimulus parameters.
%   Struct has stimulus specific fields. This struct needs to have at least:
%       .stim: Matrix that contains stimuli to be presented (num_stim x
%       stim)
%       .Fs: Sampling frequency
%       .dur: Duration of stimulus
%       .num_stim: Number of stimuli to be presented
%
%   model_params: Struct containing IC model params specific to this type
%   of model
%       .type: 2 = ModFilt; 1 = SFIE model; could add lateral
%       .range: 1 = population model, 2 = single cell model
%       .species: 1 = cat, 2 = human
%       .BMF: best modulation frequency
%       .CFs: All CFs to include 
%       .nAN_fibers_per_CF:
%       .cohc: OHC function (0-1 where 1 is normal), modifies gain
%       .cihc: IHC function (0-1 where 1 is normal), modifies threshold &
%       capture level
%       .nrep:
%       .fiberType: AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
%       .implnt: 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
%       .noiseType: 0 = fixed fGn, 1 = variable fGn - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
%       inhibition here,
%       .onsetWin: exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
%
% Outputs:
%   model_output: Struct containing AN and IC modeling outputs
%       .an_sout: average rate response of AN fibers
%

% Set up CF & BMF
onsetWin = model_params.onsetWin;
Fs = stim_params.Fs;
rng('default');     % added to accommodate older versions of Matlab, in cases for which rng has previously been run
rng('shuffle');     % seed the random number generator using time of day
BMF = repmat(model_params.BMF, 1, length(model_params.CFs));
[~, num_below_100] = find(model_params.CFs<100);
if num_below_100 > 0
	for CF_ind = 1:num_below_100(end)
		BMF(CF_ind) = model_params.CFs(CF_ind)/4;
	end
end
onset_num = onsetWin * Fs; % Calculates first point to be used in response

% AN Model
% Loop through CFs
num_stim = stim_params.num_stim;
num_CFs = length(model_params.CFs);
num_fibers = model_params.nAN_fibers_per_CF;
num_loops = num_stim*num_CFs;
an_sout_all = zeros(num_loops, num_fibers, stim_params.dur*1.2*Fs);
stim_index = reshape(repmat(1:num_stim,[1,num_CFs]), [num_loops,1]);
CF_index = reshape(repmat(1:num_CFs,[num_stim,1]), [num_loops,1]);
for ind = 1:num_loops

	% Get correct stimulus & CD
	istim = stim_index(ind);
	iCF = CF_index(ind);
	
	% Set up and run the simulation
	stimulus = stim_params.stim(istim,:);
	CF = model_params.CFs(iCF);
	vihc = model_IHC(stimulus,CF,model_params.nrep,1/Fs,...
		stim_params.dur*1.2,model_params.cohc,model_params.cihc,...
		model_params.species);
	parfor ifiber = 1:num_fibers
		[an_sout_all(ind, ifiber, :),~,~] = model_Synapse(vihc,CF,model_params.nrep,...
			1/Fs,model_params.fiberType,model_params.noiseType,...
			model_params.implnt); % an_sout is the auditory-nerve synapse output - a rate vs. time function that could be used to drive a spike generator
	end
end

% Model output
an_sout = squeeze(mean(an_sout_all, 2)); % average over number of fibers
if num_loops == 1
	avg_an = mean(an_sout(onset_num:end));
else
	avg_an = mean(an_sout(:, onset_num:end), 2);
end
model_output.an_sout = reshape(an_sout, num_stim, num_CFs,[]);
model_output.average_AN_sout = reshape(avg_an, [num_stim, num_CFs]);
model_output.CFs = model_params.CFs;


end
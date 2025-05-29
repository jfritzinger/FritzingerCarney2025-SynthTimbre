function model_output = wrapperIC(an_sout, stim_params, model_params)
% Function to run different types of IC models, 
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
%       .CFs: Array of CFs to test
%       .nAN_fibers_per_CF:
%       .cohc: OHC function (0-1 where 1 is normal), modifies gain
%       .cihc: IHC function (0-1 where 1 is normal), modifies threshold &
%       capture level
%       .nrep:
%       .fiberType: AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
%       .implnt: 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
%       .noiseType: 0 = fixed fGn, 1 = variable fGn - this is the 'noise' associated with spont. activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
%       .onsetWin: exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050
%
% Outputs:
%   model_output: Struct containing AN and IC modeling outputs
%       .average_ic_sout_BE: average rate response for BE cell
%       .average_ic_sout_BS: average rate response for BS cell
%       .ic_BS: temporal BS responses for each stimulus

% Set up CF & BMF
onsetWin = model_params.onsetWin;
Fs = stim_params.Fs;
rng('default');     % added to accommodate older versions of Matlab, in cases for which rng has previously been run
rng('shuffle');     % seed the random number generator using time of day
CFs = model_params.CFs; % set range and resolution of CFs here
model_output.CFs = CFs;
BMF = repmat(model_params.BMF, 1, length(CFs));
[~, num_below_100] = find(CFs<100);
if num_below_100 > 0
	for CF_ind = 1:num_below_100(end)
		BMF(CF_ind) = CFs(CF_ind)/4;
	end
end
onset_num = onsetWin * Fs; % Calculates first point to be used in response

% SFIE Model
num_stim = stim_params.num_stim;
num_CFs = length(CFs);
for istim = 1:num_stim
	for iCF = 1:num_CFs
		switch model_params.type
			case 'SFIE' % Monaural SFIE
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				[ic_sout_BE,ic_sout_BS,~] = SFIE_BE_BS_BMF(this_an_sout, BMF(iCF), Fs);
				model_output.average_ic_sout_BE(istim,iCF) = mean(ic_sout_BE(onset_num:end));      % averages the bandpass response
				model_output.average_ic_sout_BS(istim,iCF) = mean(ic_sout_BS(onset_num:end));
				model_output.ic_BS(iCF,istim,:) = ic_sout_BS;
				model_output.ic_BE(iCF,istim,:) = ic_sout_BE;
			case 'BE'
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				[ic_sout_BE,~,~] = SFIE_Hybrid_BMF(this_an_sout, BMF(iCF), Fs);
				model_output.avIC(istim,iCF) = mean(ic_sout_BE(onset_num:end));
				model_output.ic(iCF,istim,:) = ic_sout_BE;
			case 'BS'
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				[~,ic_sout_BS,~] = SFIE_Hybrid_BMF(this_an_sout, BMF(iCF), Fs);
				model_output.avIC(istim,iCF) = mean(ic_sout_BS(onset_num:end));
				model_output.ic(iCF,istim,:) = ic_sout_BS;
			case 'Hybrid'
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				[~,~,ic_sout_hybrid] = SFIE_Hybrid_BMF(this_an_sout, BMF(iCF), Fs);
				model_output.avIC(istim,iCF) = mean(ic_sout_hybrid(onset_num:end));
				model_output.ic(iCF,istim,:) = ic_sout_hybrid;
			case 'Monaural' % Monaural Simple Filter
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				ic_sout_BE = unitgain_bpFilter(this_an_sout,BMF(iCF),params.Fs);  % Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMF's
				model_output.average_ic_sout_BE(istim,iCF) = mean(ic_sout_BE(onset_num:end)); % averages the bandpass response over the stimulus duration
			case 'LateralInhibition' % Lateral inhibition model
				an_sout_on = squeeze(an_sout.an_sout(:,iCF, :));
				an_sout_lo = squeeze(an_sout.an_sout_lo(:,iCF, :));
				an_sout_hi = squeeze(an_sout.an_sout_hi(:,iCF, :));
				model_output = modelLateralSFIE(stim_params, model_params, ...
					an_sout_on, an_sout_lo, an_sout_hi, 'CS_params', model_params.CS_param);
			case 'Simple BS'
				this_an_sout = squeeze(an_sout(istim,iCF, :))';
				[ic_sout_BS] = SFIE_BS(this_an_sout, BMF(iCF), Fs, 'Plot', 0);
				model_output.avIC(istim,iCF) = mean(ic_sout_BS(onset_num:end));
				model_output.ic(iCF,istim,:) = ic_sout_BS;
		end
	end % CF loop
end % nstim loop
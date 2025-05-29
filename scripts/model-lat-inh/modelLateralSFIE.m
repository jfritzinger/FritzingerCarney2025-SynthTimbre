 function model_output = modelLateralSFIE(stim_params, model_params,...
	 an_sout, an_sout_lo, an_sout_hi, args)
% Runs the broad inhibition model with a standard BMF of 100 Hz for all
% neurons
% Returns the average rates and stds for BE and BS lateral SFIE models.
% Option to choose from six model configurations. 
%
% Inputs:
%	stim_params - stimulus parameters, specifics in modelLateralAN.m
%	model_params - struct that contains parameters for model, including:
%		.onsetWin - onset window for analysis 
%		.BMF - BMF of the neuron
%		.config_type - six options: 
%			'BE inhibited by off-CF CN' 
%			'BS inhibited by off-CF CN' 
%			'BE inhibited by off-CF BE' 
%			'BE inhibited by off-CF BS' 
%			'BS inhibited by off-CF BS' 
%			'BS inhibited by off-CF BE'
%	an_sout - an_sout on-CF response from lateral AN model
%	an_sout_lo - an_sout below CF response from lateral AN model
%	an_sout_hi - an_sout above CF response from lateral AN model
%	args -  
%		CS params - [strength_lo strength_hi delay] default is [0.35, 0.35, 0]
% Outputs:
%   model_output - Struct containing IC modeling outputs
%		.ic - temporal response for target cell
%		.avIC - average rate response for target cell
%		.stdIC - standard deviation for target cell response
%		.avBE_lo - average rate for low-CF BE cell
%		.avBE_hi - average rate for high-CF BE cell
%		.avBE_on - average rate for on-CF BE cell (no off-CF inhibition)
%		.avBS_lo - average rate for low-CF BS cell
%		.avBS_hi - average rate for high-CF BS cell
%		.avBS_on - average rate for on-CF BS cell (no off-CF inhibition)
%       NOTE: Can uncomment lines 245-250 to add temporal reponses for all
%       on- and off-CF temporal responses. 
%
% Other m-files required: get_alpha_norm
%
% Author: J. Fritzinger, adapted from UR_EAR
% Created: 2022-06-05; Last revision: 2024-10-10
%
% -------------------------------------------------------------------------


%% Set arguments and defaults
arguments
	stim_params = [];
	model_params = [];
	an_sout = [];
	an_sout_lo = [];
	an_sout_hi = [];
	args.CS_params = [0.35, 0.35, 0]; % Default parameter values
end

%% Parameters 

Fs = stim_params.Fs;
onsetWin = model_params.onsetWin;
onset_num = onsetWin * Fs; % Calculates first point to be used in response

% CN MODEL PARAMETERS:
tau_ex_cn = 0.5e-3;     % CN exc time consant
tau_inh_cn = 2.0e-3;    % CN inh time constant
inh_str_cn = 0.6;       % re: excitatory strength == 1
afamp_cn = 1.5;         % alpha function area --> changes RATE of output cell
cn_delay = 1.0e-3;      % "disynaptic inhibition delay" (all ANFs excitatory)

% IC MODEL PARAMETERS:
% Fitted parameters
str_inh_lo = args.CS_params(1);
str_inh_hi = args.CS_params(2);
ic_delay_offCF = args.CS_params(3);

% BMF-dependent SFIE parameters
tau_ex_ic = 1/(10*model_params.BMF); 		% Time constant excitation in seconds
tau_inh_ic = tau_ex_ic*1.5;		% Time constant inhibition in seconds
ic_delay_inh = tau_ex_ic*2;% Delay of inhibition in seconds
afamp_ic = 1;             % alpha function area --> changes RATE of output IC BE cell
inh_str_ic = 0.9; % inhibitory strength

% BS parameters
inh_str_bs = 4;
tau_inh_bs = tau_inh_ic; %1.0e-3; % relatively long inhibition, from BE to BS
ic_delay_bs = 1.0e-3;  % Delay from BE to BS cell (local)
Aex = 0.5; %0.3; % Rate Scalar for BS cell; note that this is effectively multiplied by afamp_ic (for Table in eNeuro)

% Make arrays of zeros for all delays
cn_delay_array = zeros(1,Fs*cn_delay);
ic_delay_inh_array = zeros(1,floor(Fs*ic_delay_inh));
ic_delay_offCF_array = zeros(1,floor(Fs*ic_delay_offCF));
ic_delay_bs_array = zeros(1,floor(Fs*ic_delay_bs));

numreps = 1; %number of runs
ICresp = zeros(numreps,stim_params.num_stim);
BEICresp_lo = zeros(numreps,stim_params.num_stim);
BEICresp_hi = zeros(numreps,stim_params.num_stim);
BEICresp_on = zeros(numreps,stim_params.num_stim);
BSICresp_lo = zeros(numreps,stim_params.num_stim);
BSICresp_hi = zeros(numreps,stim_params.num_stim);
BSICresp_on = zeros(numreps,stim_params.num_stim);

config_type = model_params.config_type;
for j = 1:numreps %for multiple runs

	% Runs each stimulus presentation
	for n = 1:stim_params.num_stim
	%for n = 1:stim_params.num_stim

		%% Cochlear nucleus cell model
		% See Nelson & Carney 2004

		% Generate alpha functions for exc & inh
		[B1, A1] = get_alpha_norm(tau_ex_cn, Fs, 1);
		[B2, A2] = get_alpha_norm(tau_inh_cn, Fs, 1);
		%plotAlphaFunctions(A1, B1, A2, B2, Fs, 'CN')

		%ON-CF CN model:
		% Generate frequency-domain equivalent of alpha functions
		cn_ex_vals = afamp_cn*(1/Fs)*(filter(B1, A1, [an_sout(n,:)]));
		cn_inh_vals = afamp_cn*inh_str_cn*(1/Fs)*(filter(B2, A2,[an_sout(n,:)]));
		cn_ex = [cn_ex_vals cn_delay_array ic_delay_inh_array  ic_delay_offCF_array ic_delay_bs_array];
		cn_inh = [cn_delay_array  cn_inh_vals ic_delay_inh_array ic_delay_offCF_array ic_delay_bs_array];
		cn_sout = ((cn_ex-cn_inh) + abs(cn_ex-cn_inh))/2;   % subtract inhibition from excitation and half-wave-rectify
		%plotIntermediateModelSteps(stim_params, n, Fs, cn_ex, cn_inh, cn_sout, 'On-CN')

		% OFF-CF (low) CN model:
		cn_ex_vals = afamp_cn*(1/Fs)*(filter(B1, A1, [an_sout_lo(n,:)]));
		cn_inh_vals = afamp_cn*inh_str_cn*(1/Fs)*(filter(B2, A2,[an_sout_lo(n,:)]));
		cn_ex = [cn_ex_vals cn_delay_array ic_delay_inh_array  ic_delay_offCF_array ic_delay_bs_array];
		cn_inh = [cn_delay_array  cn_inh_vals ic_delay_inh_array ic_delay_offCF_array ic_delay_bs_array];
		cn_sout_lo = ((cn_ex-cn_inh) + abs(cn_ex-cn_inh))/2;   % subtract inhibition from excitation and half-wave-rectify
		%plotIntermediateModelSteps(stim_params, n, Fs, cn_ex, cn_inh, cn_sout_lo, 'Low-CN')

		% OFF-CF (high) CN model:
		cn_ex_vals = afamp_cn*(1/Fs)*(filter(B1, A1, [an_sout_hi(n,:)]));
		cn_inh_vals = afamp_cn*inh_str_cn*(1/Fs)*(filter(B2, A2,[an_sout_hi(n,:)]));
		cn_ex = [cn_ex_vals cn_delay_array ic_delay_inh_array  ic_delay_offCF_array ic_delay_bs_array];
		cn_inh = [cn_delay_array  cn_inh_vals ic_delay_inh_array ic_delay_offCF_array ic_delay_bs_array];
		cn_sout_hi = ((cn_ex-cn_inh) + abs(cn_ex-cn_inh))/2;   % subtract inhibition from excitation and half-wave-rectify
		%plotIntermediateModelSteps(stim_params, n, Fs, cn_ex, cn_inh, cn_sout_hi, 'High-CN')


		%% Band-enhanced cell model
		% See Nelson & Carney 2004
		
		% Generate BE alpha functions 
		[B3, A3] = get_alpha_norm(tau_ex_ic, Fs, 1);
		[B4, A4] = get_alpha_norm(tau_inh_ic, Fs, 1);
		%plotAlphaFunctions(A3, B3, A4, B4, Fs, 'BE')

		% Calculate on-CF BE cell
		ic_ex_on_vals = afamp_ic*(1/Fs)*(filter(B3, A3, cn_sout));
		ic_inh_on_vals = afamp_ic*inh_str_ic*(1/Fs)*(filter(B4, A4, cn_sout));
		ic_ex_on = ic_ex_on_vals;
		ic_inh_on = [ic_delay_inh_array ic_inh_on_vals(1:end-length(ic_delay_inh_array))];
		ic_on_BE = (ic_ex_on-ic_inh_on + abs(ic_ex_on-ic_inh_on))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_ex_on, ic_inh_on, ic_on_BE, 'On-BE')

		% Calculate delayed high-CF BE cell
		ic_ex_hi_vals = afamp_ic*(1/Fs)*(filter(B3, A3, cn_sout_hi));
		ic_inh_hi_vals = afamp_ic*inh_str_ic*(1/Fs)*(filter(B4, A4, cn_sout_hi));
		ic_ex_hi = ic_ex_hi_vals;
		ic_inh_hi = [ic_delay_inh_array ic_inh_hi_vals(1:end-length(ic_delay_inh_array))];
		ic_hi_BE = (ic_ex_hi-ic_inh_hi+abs(ic_ex_hi-ic_inh_hi))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_ex_hi, ic_inh_hi, ic_hi_BE, 'High-BE')

		% Calculate delayed high-CF BE cell 
		ic_ex_lo_vals = afamp_ic*(1/Fs)*(filter(B3, A3, cn_sout_lo));
		ic_inh_lo_vals = afamp_ic*inh_str_ic*(1/Fs)*(filter(B4, A4, cn_sout_lo));
		ic_ex_lo = ic_ex_lo_vals;
		ic_inh_lo = [ic_delay_inh_array ic_inh_lo_vals(1:end-length(ic_delay_inh_array))];
		ic_lo_BE = (ic_ex_lo-ic_inh_lo+abs(ic_ex_lo-ic_inh_lo))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_ex_lo, ic_inh_lo, ic_lo_BE, 'Low-BE')

		%%  Band-suppressed cell model
		% See Carney et al., 2015

		% Generate BS alpha function
		[B5, A5] = get_alpha_norm(tau_inh_bs, Fs, 1);
		%plotAlphaFunctions(A3, B3, A5, B5, Fs, 'BS')

		% Calculate on-CF BS cell 
		ic_bs_inh_vals = Aex*inh_str_bs*(1/Fs)*(filter(B5, A5,ic_on_BE));
		ic_bs_ex = Aex * ic_ex_on;
		ic_bs_inh = [ic_delay_bs_array ic_bs_inh_vals(1:end-length(ic_delay_bs_array))];
		ic_BS_on = ic_bs_ex-ic_bs_inh;
		ic_on_BS = (ic_BS_on + abs(ic_BS_on))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_bs_ex, ic_bs_inh, ic_on_BS, 'On-BS')

		% Calculate high-CF BS cell 
		ic_bs_inh_vals = Aex*inh_str_bs*(1/Fs)*(filter(B5, A5,ic_hi_BE));
		ic_bs_ex_hi = Aex * ic_ex_hi;
		ic_bs_inh_hi = [ic_delay_bs_array ic_bs_inh_vals(1:end-length(ic_delay_bs_array))];
		ic_hi_BS = (ic_bs_ex_hi-ic_bs_inh_hi + abs(ic_bs_ex_hi-ic_bs_inh_hi))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_bs_ex_hi, ic_bs_inh_hi, ic_hi_BS, 'High-BS')

		% Calculate low-CF BS cell 
		ic_bs_inh_vals = Aex*inh_str_bs*(1/Fs)*(filter(B5, A5,ic_lo_BE));
		ic_bs_ex_lo = Aex * ic_ex_lo;
		ic_bs_inh_lo = [ic_delay_bs_array ic_bs_inh_vals(1:end-length(ic_delay_bs_array))];
		ic_lo_BS = (ic_bs_ex_lo-ic_bs_inh_lo + abs(ic_bs_ex_lo-ic_bs_inh_lo))/2; % half-wave rectified
		%plotIntermediateModelSteps(stim_params, n, Fs, ic_bs_ex_lo, ic_bs_inh_lo, ic_lo_BS, 'Low-BS')

		%% Off-CF Inhibition calculations 

		if endsWith(config_type, 'CN')
			input_inh_hi = cn_sout_hi;
			input_inh_lo = cn_sout_lo;
		elseif endsWith(config_type, 'BE')
			input_inh_hi = ic_hi_BE;
			input_inh_lo = ic_lo_BE;
		elseif endsWith(config_type, 'BS')
			input_inh_hi = ic_hi_BS;
			input_inh_lo = ic_lo_BS;
		end

		% Calculate input for off-CF inhibition, high and low
		ic_inh_hi_vals = afamp_ic*str_inh_hi*(1/Fs)*(filter(B4, A4, input_inh_hi));
		ic_inh_lo_vals = afamp_ic*str_inh_lo*(1/Fs)*(filter(B4, A4, input_inh_lo));
		ic_inh_hi = [ic_delay_offCF_array ic_inh_hi_vals(1:end-length(ic_delay_offCF_array))];
		ic_inh_lo = [ic_delay_offCF_array ic_inh_lo_vals(1:end-length(ic_delay_offCF_array))];


		%% IC BE output

		% Six different configurations
		switch config_type
			case 'BE inhibited by off-CF CN' % BE - CN_low - CN_high
				ic = ic_ex_on - ic_inh_on - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params, n,ic_ex_on, ic_inh_on,ic_inh_lo,ic_inh_hi,ic, Fs)
			case 'BS inhibited by off-CF CN' % BS - CN_low - CN_high 
				ic = ic_bs_ex - ic_bs_inh - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params, n,ic_bs_ex,ic_bs_inh,ic_inh_lo, ic_inh_hi,ic, Fs)
			case 'BE inhibited by off-CF BE' % BE - BE_low - BE_high
				ic = ic_ex_on - ic_inh_on - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params, n,ic_ex_on,ic_inh_on,ic_inh_lo,ic_inh_hi,ic, Fs)
			case 'BE inhibited by off-CF BS' % BE - BS_low - BS_high
				ic = ic_ex_on - ic_inh_on - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params, n,ic_ex_on,ic_inh_on,ic_inh_lo,ic_inh_hi,ic, Fs)
			case 'BS inhibited by off-CF BS' % BS - BS_low - BS_high
				ic = ic_bs_ex - ic_bs_inh - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params,n, ic_bs_ex,ic_bs_inh,ic_inh_lo,ic_inh_hi,ic, Fs)
			case 'BS inhibited by off-CF BE' % BS - BE_low - BE_high
				ic = ic_bs_ex - ic_bs_inh - ic_inh_hi - ic_inh_lo;
				%plotIntermediateConfigurations(stim_params,n, ic_bs_ex,ic_bs_inh,ic_inh_lo,ic_inh_hi,ic, Fs)
		end
		ic = (ic + abs(ic))/2; % half-wave rectified

		%% Adding responses to output struct

		ICresp(j,n) = mean(ic(onset_num:end)); % average IC response for each run

		BEICresp_lo(j,n) = mean(ic_lo_BE(onset_num:end));
		BEICresp_hi(j,n) = mean(ic_hi_BE(onset_num:end));
		BEICresp_on(j,n) = mean(ic_on_BE(onset_num:end));
		BSICresp_lo(j,n) = mean(ic_lo_BS(onset_num:end));
		BSICresp_hi(j,n) = mean(ic_hi_BS(onset_num:end));
		BSICresp_on(j,n) = mean(ic_on_BS(onset_num:end));

		model_output.ic(1, n,:) = ic;
		%model_output.ic_high_BE(1, n,:) = ic_hi_BE;
		%model_output.ic_low_BE(1, n,:) = ic_lo_BE;
		%model_output.ic_on_BE(1, n,:) = ic_on_BE;
		%model_output.ic_high_BS(1, n,:) = ic_hi_BS;
		%model_output.ic_low_BS(1, n,:) = ic_lo_BS;
		%model_output.ic_on_BS(1, n,:) = ic_on_BS;
	end
end

% Get average and standard deviation of results from multiple runs
model_output.avIC=mean(ICresp,1);
model_output.stdIC=std(ICresp,0,1);
model_output.avBE_lo = mean(BEICresp_lo,1);
model_output.avBE_hi = mean(BEICresp_hi,1);
model_output.avBE_on = mean(BEICresp_on,1);
model_output.avBS_lo = mean(BSICresp_lo,1);
model_output.avBS_hi = mean(BSICresp_hi,1);
model_output.avBS_on = mean(BSICresp_on,1);
end
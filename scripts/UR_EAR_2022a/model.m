function [vihc_out,an_pop_out,an_pop_plot_out,BE_out,BS_out,CN_out] = ...
	model(DQ,Which_AN,Which_IC,stimulus,Fs,CF_range,RsFs,thisBMF,CF,nrep,T,...
	dur,dur2,cohc,cihc,ag_fs,ag_dbloss,CF_num,species,fiberType,noiseType,...
	implnt,fiber_num,n)

switch Which_AN
	case 1
		% Using ANModel_2014 (2-step process)
		vihc = model_IHC(stimulus,CF,nrep,T,dur2,cohc,cihc,species);
		% use version of model_IHC that returns BM response (ChirpFilter only)
		% [vihc,bm] = model_IHC_BM(stimulus,CF,nrep,T,dur2,cohc,cihc,species);
		% Save output waveform into matrices.
		vihc_out = resample(vihc,RsFs,Fs);
		% BM_pop_out = resample(bm,RsFs,Fs);
		
		% an is the auditory-nerve synapse output - a rate vs. time
		% function that could be used to drive a spike generator.
		% [an_sout,~,~] = model_Synapse(vihc,CF,nrep,T,fiberType,noiseType,implnt);
		
		an_sum = 0;
		for fi = 1:fiber_num
			[temp,~,~] = model_Synapse(vihc,CF,nrep,T,fiberType,noiseType,implnt);
			an_sum = an_sum + temp;
		end
		an = an_sum/fiber_num;
		
		% Save synapse output waveform into a matrix.
		an_pop_out = resample(an,RsFs,Fs);
		an_pop_plot_out = [];
		
	case 2
		vihc = model_IHC_BEZ2018(stimulus,CF,nrep,T,dur2,cohc,cihc,species);
		vihc_out = resample(vihc,RsFs,Fs);
		
		[psth,neurogram_ft] = generate_neurogram_UREAR2(stimulus,Fs,species,...
			ag_fs,ag_dbloss,CF_num,dur,n,fiber_num,CF_range,fiberType);
		
		an = (100000*psth)/fiber_num;
		an_pop_out = resample(an,RsFs,Fs);
		an_pop_plot_out = neurogram_ft;
		
end
switch Which_IC
	case 1 % Monaural SFIE
		[ic_sout_BE,ic_sout_BS,cn_sout_contra] = SFIE_BE_BS_BMF(an,thisBMF,Fs);
		BE_out = resample(ic_sout_BE,RsFs,Fs);
		BS_out = resample(ic_sout_BS,RsFs,Fs);
		CN_out = cn_sout_contra;
		
	case 2 % Monaural Simple Filter
		% Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMFs.
		ic_sout_BE = unitgain_bpFilter(an,thisBMF,Fs);
		BE_out = resample(ic_sout_BE,RsFs,Fs);
		BS_out = [];
		CN_out = [];
		
end

% Send message to DataQueue to update progress bar.
send(DQ,1);

end

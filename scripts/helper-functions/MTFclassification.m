function [BMF,WMF,MTF_shape, at_100, at_200] = MTFclassification(spike_rates, fms, fmi)
% Classifies MTF into BE, BS, Hybrid, and Flat
% J. Fritzinger, 3/14/23

% Inputs:
%   spike_rates: raw rates (e.g. spike_rates = num_spikes_skiponset(this_ds)/(dur -
%   onset_window_ms/1000))
%   fms: modulation frequencies 
%   fmi: presentation order of modulation frequencies

% Classification Rules:
%   BE: If two modulation frequency rates are statistically significantly 
%       larger than the unmodulated rate in a BE region. A BE region is a
%       group of modulation frequencies not interrupted by a statistically
%       significant rate below the unmodulated rate. 
%   BS: If two modulation frequency rates are statistically significantly 
%       smaller than the unmodulated rate in a BS region. A BS region is a
%       group of modulation frequencies not interrupted by a statistically
%       significant rate above the unmodulated rate. 
%   Hybrid: If both conditions for BE and BS are met
%   Flat: If neither condition for BE or BS is met

%% Get all rates 
num_mod_freqs = length(fms);
reps = length(fmi)/num_mod_freqs;
raw_rates = zeros(num_mod_freqs, reps);
for j = 1:num_mod_freqs
    raw_rates(j, :) = spike_rates(j==fmi);
end

%% Test null hypothesis
% Find rates that are significantly different than unmodulated rate

p = zeros(num_mod_freqs, 1);
for f_ind = 1:num_mod_freqs
    [~,p(f_ind),~,~] = ttest(raw_rates(f_ind, :),raw_rates(1,:));
end
sig_ind = p<0.05;
non_sig = ~sig_ind;
mean_rates = mean(raw_rates,2);
unmodrate = mean_rates(1);

%% Determine BE condition

upper_ind = mean_rates>unmodrate; % All mod freqs greater than unmodulated
sig_above = sig_ind & upper_ind; % Significant mod freqs above unmodulated rate

% Find regions of consecutive mod freqs above ummodulated, including nonsig
% We want to find how many mod freqs are 'consecutive' before being broken by a
% significantly different mod freq rate below the unmodulated rate. 
test_BE = sig_above | non_sig;
num_consec = find([true;diff(test_BE)~=0;true]); 
consec = zeros(num_mod_freqs, 1);
consec(num_consec(1:end-1)) = diff(num_consec);
num_BE = consec((consec & test_BE)>0); % Number of mod freqs in each BE region 

% In the regions of consecutive possible BE mod freqs, find how many points are
% significantly BE
num_regions = length(num_BE);
region_ind = find(consec & (consec & test_BE)>0); % Index of BE region 'start'
BE_num_sig = zeros(num_regions, 1);
for ind = 1:num_regions
   BE_num_sig(ind) = sum(sig_above(region_ind(ind):region_ind(ind)+num_BE(ind)-1));
end

% If 2 points in a BE region are significantly BE, then condition is met
if max(BE_num_sig) >= 2
    BE_cond = 1;
else
    BE_cond = 0;
end

%% Determine BS condition

lower_ind = mean_rates<unmodrate; % All mod freqs greater than unmodulated
sig_below = sig_ind & lower_ind; % Significant mod freqs above unmodulated rate

% Find regions of consecutive mod freqs below ummodulated, including nonsig
% We want to find how many mod freqs are 'consecutive' before being broken by a
% significantly different mod freq rate above the unmodulated rate. 
test_BS = sig_below | non_sig;
num_consec = find([true;diff(test_BS)~=0;true]); 
consec = zeros(num_mod_freqs, 1);
consec(num_consec(1:end-1)) = diff(num_consec);
num_BS = consec((consec & test_BS)>0); % Number of mod freqs in each BE region 

% In the regions of consecutive possible BS mod freqs, find how many points are
% significantly BS
num_regions = length(num_BS);
region_ind = find(consec & (consec & test_BS)>0); % Index of BS region 'start'
BS_num_sig = zeros(num_regions, 1);
for ind = 1:num_regions
   BS_num_sig(ind) = sum(sig_below(region_ind(ind):region_ind(ind)+num_BS(ind)-1));
end

% If 2 points in a BS region are significantly BS, then condition is met
if max(BS_num_sig) >= 2
    BS_cond = 1;
else
    BS_cond = 0;
end

%% Check if neuron passes criteria for BE and/or BS and set MTF type

if BE_cond == 1 && BS_cond == 1
    MTF_shape = 'H';
elseif BE_cond == 1
    MTF_shape = 'BE';
elseif BS_cond == 1
    MTF_shape = 'BS';
elseif BE_cond == 0 && BS_cond == 0
    MTF_shape = 'F';
	at_100 = NaN;
	at_200 = NaN;
end

%% Find WMF/BMF, from PWM

switch MTF_shape
	case 'BE'
		% Code below by DMS.
		pp = spline(log2(fms(2:end)),mean_rates(2:end));
		[~,logfmax] = fnmin(fncmb(pp,-1)); %-1 inverts MTF, so min can be identified
		BMF = 2.^logfmax;
        WMF = NaN;
		at_100 = NaN;
		% Add if neuron is BE or BS at 200Hz
		[~,closestIndex] = min(abs(fms(:, 1)-200)); % find datapoint closest to 100Hz 
		rate_change = mean_rates(closestIndex) - mean_rates(1); % determine if rate is > or < unmodulated rate
		if rate_change > 0 && p(closestIndex)<0.05
			at_200 = 'BE';
		elseif rate_change < 0 && p(closestIndex)<0.05
			at_200 = 'BS';
		else
			at_200 = 'F';
		end
    case 'BS'
        %PWM edit to allow "WMF" for BS cells
        pp = spline(log2(fms(2:end)),mean_rates(2:end));
		[~,logfmax] = fnmin(fncmb(pp,1)); %scale by +1 (no need to invert for BS)
		WMF = 2.^logfmax;
        BMF = NaN;
		at_100 = NaN;
		% Add if neuron is BE or BS at 200Hz
		[~,closestIndex] = min(abs(fms(:, 1)-200)); % find datapoint closest to 100Hz 
		rate_change = mean_rates(closestIndex) - mean_rates(1); % determine if rate is > or < unmodulated rate
		if rate_change > 0 && p(closestIndex)<0.05
			at_200 = 'BE';
		elseif rate_change < 0 && p(closestIndex)<0.05
			at_200 = 'BS';
		else
			at_200 = 'F';
		end
    case 'H'
        pp = spline(log2(fms(2:end)),mean_rates(2:end));
		[~,logfmax] = fnmin(fncmb(pp,-1)); %-1 inverts MTF, so min can be identified
		BMF = 2.^logfmax;
        [~,logfmin] = fnmin(fncmb(pp,1)); %scale by +1 (no need to invert for BS)
		WMF = 2.^logfmin;
        
        %split hybrid classification in to H (BE-BS) or H (BS-BE), where 
        %H (BE-BS) has a peak followed by a dip, and
        %H (BS-BE) has a dip followed by a peak
        if BMF < WMF
            MTF_shape = 'H (BE-BS)';
        elseif BMF > WMF
            MTF_shape = 'H (BS-BE)';
		end
	
		% Add if neuron is BE or BS at 100Hz
		[~,closestIndex] = min(abs(fms(:, 1)-100)); % find datapoint closest to 100Hz 
		rate_change = mean_rates(closestIndex) - mean_rates(1); % determine if rate is > or < unmodulated rate
		if rate_change > 0
			at_100 = 'BE';
		elseif rate_change < 0
			at_100 = 'BS';
		else
			at_100 = 'F';
		end

		% Add if neuron is BE or BS at 200Hz
		[~,closestIndex] = min(abs(fms(:, 1)-200)); % find datapoint closest to 100Hz 
		rate_change = mean_rates(closestIndex) - mean_rates(1); % determine if rate is > or < unmodulated rate
		if rate_change > 0 && p(closestIndex)<0.05
			at_200 = 'BE';
		elseif rate_change < 0 && p(closestIndex)<0.05
			at_200 = 'BS';
		else
			at_200 = 'F';
		end
	case 'F'
		% Add if neuron is BE or BS at 200Hz
		[~,closestIndex] = min(abs(fms(:, 1)-200)); % find datapoint closest to 100Hz 
		rate_change = mean_rates(closestIndex) - mean_rates(1); % determine if rate is > or < unmodulated rate
		if rate_change > 0 && p(closestIndex)<0.05
			at_200 = 'BE';
		elseif rate_change < 0 && p(closestIndex)<0.05
			at_200 = 'BS';
		else
			at_200 = 'F';
		end
		BMF = NaN; % was 0 (DMS)
        WMF = NaN;

	otherwise
		BMF = NaN; % was 0 (DMS)
        WMF = NaN;
end

end


% %% MTF Classification Code
% % rate is from accumstats function
% function [BMF,WMF,MTF_shape] = MTFclassification(rate,fms)
% %MTFclassification
% 
% % Author: Afagh Farhadi
% % Date: 10 June 2021
% 
% %using criteron from Kim et al. (2020) - two contiguous points must be 20%
% %greater/less than the unmodulated rate
% 
% %edited by PWM on 8/6/21 to include WMF and more specific hybrid
% %classification
% 
% [maxrate,Indexmax] = max(rate);
% [minrate,Indexmin] = min(rate);
% % Unmodulated rate for new datasets is rate(1)
% % for older dataset we have to get this from moddepth dataset.
% unmodrate = rate(1);
% 
% %%defining upperbound for BE and lowerbound for BE
% %lower and upper bounds are the mod-freqs just below and above the peak
% %frequency
% 
% if Indexmax == length(rate)
% 	upperboundBE = maxrate;
% else
% 	upperboundBE = rate(Indexmax+1);
% end
% if Indexmax == 1
% 	lowerboundBE= rate(1);
% else
% 	lowerboundBE= rate(Indexmax-1);
% end
% 
% %%defining upperbond for BS and lowerbond for BS
% 
% 
% if Indexmin == length(rate)
% 	upperboundBS = minrate;
% else
% 	upperboundBS = rate(Indexmin+1);
% end
% 
% 
% if Indexmin == 1
% 	lowerboundBS = rate(1);
% else
% 	lowerboundBS = rate(Indexmin-1);
% end
% 
% 
% % C is the Criteria (In the Kim et al. paper)
% c = 1.2;
% 
% if maxrate < 5
% 	MTF_shape = 'NR';    % not responsive cell
% else % check other classes
% 	% check the first condition for BE
% 	if maxrate >= c*unmodrate && ...
% 			(lowerboundBE >= c*unmodrate || upperboundBE >= c*unmodrate)
% 		BE1 = 1;
% 	else
% 		BE1 = 0;
% 	end
% 	% check the Second condition for BE
% 	outband = find(rate < (1/c)*unmodrate);
% 	if length(outband) <= 1
% 		BE2 = 1;
% 	else
% 		BE2 = 0;
% 	end
% 	
% 	%check if both conditions are met
% 	if BE1 == 1 && BE2 == 1
% 		BE = 1;
% 		MTF_shape = 'BE';
% 	else
% 		BE = 0;
% 	end
% 	
% 	if minrate < (1/c)*unmodrate && ...
% 			(lowerboundBS < (1/c)*unmodrate || upperboundBS < (1/c)*unmodrate)
% 		BS1 = 1;
% 	else
% 		BS1 = 0;
% 	end
% 	
% 	
% 	outband_BS = find(rate > c*unmodrate);
% 	if length(outband_BS) <= 1
% 		BS2 = 1;
% 	else
% 		BS2 = 0;
% 	end
% 	if BS1 == 1 && BS2 == 1 % bug fixed (DMS), was "BS2 == 1 && BS2 == 1"
% 		BS = 1;
% 		MTF_shape = 'BS';
% 	else
% 		BS = 0;
% 	end
% 	if BE1 == 1 && BS1 == 1
% 		hybrid = 1;
% 		MTF_shape = 'H';
% 	else
% 		hybrid = 0;
% 	end
% 	if BE2 == 1 && BS2 == 1
% 		flat = 1;
% 		MTF_shape = 'F';
% 	else
% 		flat = 0;
% 	end
% 	if flat == 0 && hybrid == 0 && BS == 0 && BE == 0
% 		MTF_shape = 'N';
% 	end
% end
% 
% switch MTF_shape
% 	case 'BE'
%         %BMF = fms(Indexpeak);
% 		% Code below by DMS.
% 		pp = spline(log2(fms(2:end)),rate(2:end));
% 		[~,logfmax] = fnmin(fncmb(pp,-1)); %-1 inverts MTF, so min can be identified
% 		BMF = 2.^logfmax;
%         WMF = NaN;
%         %if a "BE" neuron has a BMF at the highest fm, then it cannot be
%         %classified as "BE" and is instead a HP (PM, 9/3/21)
%         if Indexmax == length(fms)
%             MTF_shape = 'HP';
%             BMF = NaN;
%         end
%     case 'BS'
%         %PWM edit to allow "WMF" for BS cells
%         pp = spline(log2(fms(2:end)),rate(2:end));
% 		[~,logfmax] = fnmin(fncmb(pp,1)); %scale by +1 (no need to invert for BS)
% 		WMF = 2.^logfmax;
%         BMF = NaN;
%          %if a "BS" neuron has a BMF at the highest fm, then it cannot be
%         %classified as "BS" and is instead a LP (PM, 9/3/21)
%         if Indexmin == length(fms)
%             MTF_shape = 'LP';
%             WMF = NaN;
%         end
%     case 'H'
%         pp = spline(log2(fms(2:end)),rate(2:end));
% 		[~,logfmax] = fnmin(fncmb(pp,-1)); %-1 inverts MTF, so min can be identified
% 		BMF = 2.^logfmax;
%         [~,logfmin] = fnmin(fncmb(pp,1)); %scale by +1 (no need to invert for BS)
% 		WMF = 2.^logfmin;
%         
%         %split hybrid classification in to H (BE-BS) or H (BS-BE), where 
%         %H (BE-BS) has a peak followed by a dip, and
%         %H (BS-BE) has a dip followed by a peak
%         if BMF < WMF
%             MTF_shape = 'H (BE-BS)';
%         elseif BMF > WMF
%             MTF_shape = 'H (BS-BE)';
%         end
%         %make sure we don't say the BMF/WMF is simply the max fm
%         if Indexmax == length(fms)
%             BMF = NaN;
%         elseif Indexmin == length(fms)
%             WMF = NaN;
%         end
% 	otherwise
% 		BMF = NaN; % was 0 (DMS)
%         WMF = NaN;
% end
% 
% end

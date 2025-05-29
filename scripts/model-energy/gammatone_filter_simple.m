function filtered = gammatone_filter_simple(input_waveform,cf,fs,impaired)
% 4th-order gammatone filter, based on Human filter ERBs from Glasberg & Moore 
% cf = center frequency of filter (Hz)
% fs = sampling rate (samples/sec)
% impaired = 0 if "healthy" or a factor by which bandwidth will be
% broadened, for "impairment" (e.g. is this is set = to 2, the bandwidth of
% the gammatone filter will be doubled w.r.t healthy).

    % The folowing line specifies Glasberg & Moore style erb's 
    erbCF = 24.7 * (4.37 * cf/1000 + 1);
  if impaired ~= 0
      erbCF = impaired*erbCF; % quick 'impairment'
  end
  
  
%   % For cat & Shera values - these are expressions from model_IHC.c c-code:
%   if (species==1) /* cat Q10 values */
%   {
%     Q10 = pow(10,0.4708*log10(cf/1e3)+0.4664);
%   }
%   if (species==2) /* human Q10 values from Shera et al. (PNAS 2002) */
%   {
%     Q10 = pow((cf/1000),0.3)*12.7*0.505+0.2085;
%   }
%   if (species==3) /* human Q10 values from Glasberg & Moore (Hear. Res. 1990) */
%   {
%     Q10 = cf/24.7/(4.37*(cf/1000)+1)*0.505+0.2085;
%   }
%   bw     = cf/Q10;
%   
  
    %This converts ERB to a gammatone tau, based on Patterson's
    %conversion between Roex and gammatone
    tau = 1./(2.*pi * 1.019 * erbCF);

    %This calls the fileter in the function gammatone.m
    [b1,a1] = gammatone(tau,4,cf,fs);
    filtered = filter(b1,a1,input_waveform);

end

%this is the function to get gammatone filter
%the gain is ~1 when w=w_cf
%
% To use this function, you needn't set the Fs very high(because
% it is bilinear, so just above 2*band is enough and then you may
% need to upsampling the result if you  want to pass the result
% through the synapse ( the synapse dynamics need high sampling rate
%
%Using bilinear transform/Impinvar transform !!!
%function [Numd,Dend] = gammatone(tau,order,cf,Fs) //cf, Fs in Hz
%
function [B,A] = gammatone(tau,order,cf,Fs)

    w_cf = 2*pi*cf;
    a1 = [tau 1-1i*tau*w_cf];
    a2 = [tau 1+1i*tau*w_cf];
    a1res = [1];
    a2res = [1];

    for i = 1:order,
      a1res = conv(a1res,a1);
      a2res = conv(a2res,a2);
    end;

    num = a1res+a2res;
    den = conv(a1res,a2res);
    num = [zeros(1,length(den)-length(num)) num];
    [B,A] = impinvar(real(num),real(den),Fs);
end

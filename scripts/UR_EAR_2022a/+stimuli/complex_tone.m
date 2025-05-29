function [pin]=complex_tone(dur, rampdur,f0,ncomponents,filter_type,Wn_freq,include_fundmntl,stimdB,Fs)
%% Parameters - Complex tone (harmonic complex)

%dur is total duration of stimulus (s) (not same as Moore's dur)
%rampdur is duration of on or off ramp (s)
%f0 is fundamental frequency
%ncomponents is the number of components (including the fundamental, whether or not it is ultimately present)
%filter_type: 0=none,1=lowpass,2=highpass,3=bandpass,4=bandreject
%Wn_freq is the cutoff frequency or frequencies of the filter specified.
%include_fundmntl: 1 for include, 0 for omit
%stimdB is the level of the stimulus
%Fs is the sampling freq in Hz

%Other parameters for generating tones
compnt_step = 1; %Ratio between included components: 1 for every harmonic, 2 for every odd harmonic
rand_phase = false; %Change to true if random starting phases are desired for each component of the complex tone

%Allocate time vector
N = round(Fs*dur);
t = (0:N-1)/Fs;

%Other parameters and error messages for filters
order = 5000; %order of fir1 filter
switch length(Wn_freq)
    case 1
        switch filter_type
            case 0
            case 1
            case 2
            case 3
                error('In order to make the requested bandpass filter, Wn_freq must be of length 2')
            case 4
                error('In order to make the requested band-reject filter, Wn_freq must be of length 2')
        end
        fCo = Wn_freq; %Cutoff frequency for high and lowpass filters
        fCo_rel_nyq = fCo/(Fs/2); %Express fCo as a percentage of Nyquist rate (this is the type of input the filter syntax requires)
    case 2
        switch filter_type
            case 0
            case 1
                error('In order to make the requested low-pass filter, input only one frequency for Wn_freq')
            case 2
                error('In order to make the requested high-pass filter, input only one frequency for Wn_freq')
            case 3
            case 4
        end
        Lower = Wn_freq(1); %Cutoff frequencies for bandpass and bandreject filters
        Upper = Wn_freq(2);
        Wn1=Lower/(Fs/2);
        Wn2=Upper/(Fs/2);
end

%% Determine frequencies to generate
int_multiplier = 1:compnt_step:ncomponents; 
freq_array = int_multiplier*f0;

%% Omit fundamental if instructed
if ~include_fundmntl
	freq_array(1) = [];
end

% Compute the phases.
if rand_phase
	phase = 2*pi*rand(length(freq_array),1);
else
	phase = zeros(length(freq_array),1);
end
% Compute the sum of the harmonics.
pin = sum(cos(2*pi*freq_array(:).*t + phase),1);
% If the line above fails, comment it out and uncomment the line below.
% pin = sum(cos(bsxfun(@plus,bsxfun(@times,2*pi*freq_array(:),t),phase)),1);

% Optional filters to apply to complex tone
switch filter_type
	case 0 %none
	case 1 %lowpass
		b = fir1(order,fCo_rel_nyq,'low');
		pin = conv(pin,b,'same');
	case 2 %highpass
		b = fir1(order,fCo_rel_nyq,'high');
		pin = conv(pin,b,'same');
	case 3 %bandpass
		b = fir1(order,[Wn1,Wn2],'bandpass');
		pin = conv(pin,b,'same');
	case 4 %band reject
		b = fir1(order,[Wn1,Wn2],'stop');
		pin = conv(pin,b,'same');
end

%% Gate and scale final complex tone
pin = tukeywin(length(pin), 2*rampdur/dur)' .* pin; % apply on/off ramps
pin = 20e-6 * 10.^(stimdB/20) * pin/rms(pin); % scale signal into Pascals

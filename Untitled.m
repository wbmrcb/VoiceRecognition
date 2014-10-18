%% Defining section
% Define system parameters
framesize = 8000;       % Framesize (samples)
Fs = 8000;            % Sampling Frequency (Hz)
power_thr = 0.1;

% Setup data acquisition from sound card
ai = analoginput('winsound');
addchannel(ai, 1);

% Configure the analog input object.
set(ai, 'SampleRate', Fs);
set(ai, 'SamplesPerTrigger', framesize);
set(ai, 'TriggerRepeat',inf);
set(ai, 'TriggerType', 'immediate');

% Start acquisition
start(ai);

disp('Recording started.');

% Acquire new input samples
[newdata,time] = getdata(ai,ai.SamplesPerTrigger);
% Do some processing on newdata

% Stop acquisition
stop(ai);

disp('Recording stoped.');

%% Play again and plot

player = audioplayer(newdata, Fs);
play(player);

subplot(3,3,1);
plot(time,newdata);
zoom on;
title('Captured sound');
xlabel('Time in seconds.');

%% Filtering
% Define system parameters
seglength = 160;                    % Length of frames
overlap = seglength/2;              % # of samples to overlap
stepsize = seglength - overlap;     % Frame step size
nframes = length(newdata)/stepsize-1;

% Initialize Variables
samp1 = 1; samp2 = seglength; %Initialize frame start and end

signal_power = 0;

for i = 1:nframes
    % Get current frame for analysis
    frame = newdata(samp1:samp2);
    
    new_sum =  sum(frame.^2);
    signal_power = [signal_power; new_sum];
    
    if new_sum < power_thr
        for k = samp1:samp2
            newdata(k) = 0;
        end
    end
    
    % Do some analysis
    % Step up to next frame of speech
    samp1 = samp1 + stepsize;
    samp2 = samp2 + stepsize;
end

newdata = nonzeros(newdata);

%% plot power
subplot(3,3,2);
plot(signal_power);


%% plot filtered
subplot(3,3,3);
plot(newdata);
zoom on;
title('Filtered sound');
xlabel('Time in seconds.');

%% Analysis plots
order = 12;
nfft = 512;
subplot(3,3,4);
hold on;
py = pyulear(newdata,order,nfft,Fs);
mel = melcepst(newdata, 8000);


hold on
options = statset('Display','final');


%Number of Gaussian component densities
M = 1;
gmmmodel = gmdistribution.fit(mel, M, 'Options', options);

[P, log_like] = posterior(gmmmodel,newdata);

% Disconnect/Cleanup
delete(ai);
clear ai;
clear all;
clc;

%% AM Synchronous Demodulator
% Hardware Requirements
% Nooelec NESDR SMArt
% Nooelec Ham It Up Upconverter
% Antenna

% Operation
% First the receiver will receiver SamplesPerFrame samples
% Then the signal will pass through a lowpass filter to filter out
% unwanted neighboring singals.
% The absolute value of the signal is then taken
% Next the signal is downsampled to an operating sampling rate of 45 kHz
% The output is then pushed through the audio device.

%% Settings
% General
f = 1140e3;
hamOffset  = 125e6;
fc = f + hamOffset;
EnableTunerAGC = false;
TunerGain = 60;
OutputDataType = 'double';
SamplesPerFrame = 4096;

D = 5;

%Setting up RTL-SDR
rx = comm.SDRRTLReceiver('CenterFrequency',fc,...
    'EnableTunerAGC',EnableTunerAGC,...
    'TunerGain',TunerGain,...
    'OutputDataType',OutputDataType,...
    'SamplesPerFrame',SamplesPerFrame);

%Setting up Architecture(s)
lpf = firpm(50,[0 5e3 6e3 (240e3/2)]/(240e3/2), [1 1 0 0], [1 1], 20); %TODO: MATCH THE LOWPASS FILTER TO THE ONE IMPLEMENTED IN SIMULINK...
dcblock = firpm(50,[0 500 1e3 (48e3/2)]/(48e3/2), [0 0 1 1], [1 1], 20);
audioPlayer = audioDeviceWriter('Driver','WASAPI','SampleRate',48e3);

%% AM Synchronous Demodulation
while(true)
    %Receive 4096 samples from SDR
    rxdata = rx();
    rxdata = rxdata*10;
    
    %Pass Signal through lowpass filter
    lowpassSignal = conv2(rxdata,lpf,'same');
    
    %Take the magnitude of the complex signal
    absSignal = abs(lowpassSignal);
    
    %Take the square root of the magnitude
    sqrtSignal = sqrt(absSignal);
    
    %Downsample to sample frequency of 48kHz (D = 5)
    decimateSignal = decimate(absSignal,D,'fir');

    %Pass signal through DC blocker
    output = conv2(decimateSignal,dcblock,'same');
    
    %Output to audio device writer
    audioPlayer(output);

end















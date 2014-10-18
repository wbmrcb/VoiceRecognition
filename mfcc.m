%% MFCC Function
% MFCC
%
% Inputs: s contains the signal to analize
% fs is the sampling rate of the signal
%
% Output: r contains the transformed signal

function r = mfcc(s, fs)
m = 100;
n = 256;
frame=blockFrames(s, fs, m, n);
m = melfb(20, n, fs);
n2 = 1 + floor(n / 2);
z = m * abs(frame(1:n2, :)).^2;
r = dct(log(z));
end
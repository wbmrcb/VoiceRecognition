%% Comparing function
% input : voice data
% output : matching text string
function f = new(newdata, Fs)
disp('Comparing');

fileNames = {'on.wav', 'off.wav', 'high.wav', 'low.wav'};
sound = {'on', 'off', 'high', 'low'};
fileData = {0, 0, 0, 0};
mfccData = {0, 0, 0, 0};
vqData = {0, 0, 0, 0};
distM = {0, 0, 0, 0};
distances = {0, 0, 0, 0};
minDist = Inf;
distIndex = 0;
threshold = 8; 
vqpoints = 16;

%----- code for speaker recognition -------
disp('MFCC cofficients computation');
mfccN = mfcc(newdata,Fs);
vqN = vqlbg(mfccN,vqpoints);

for i = 1:4
    [fileData{i}, Fs] = wavread(fileNames{i});  % Read file data
    mfccData{i} = mfcc(fileData{i},Fs); % Compute MFCC
    vqData{i} = vqlbg(mfccData{i},vqpoints);  % Compute Vector Quantization
    distM{i} = disteu(mfccData{i}, vqN);% Distances matrix
    distances{i} = sum(min(distM{i},[],2)) / size(distM{i},1);  % distances
    str = fprintf('Distance to %s  \t', sound{i});
    disp(num2str(distances{i}));
    if distances{i} < minDist
        minDist = distances{i};
        distIndex = i;
    end
end

if minDist > threshold
    disp('No match found');
else
    str = sprintf('Best matching sound : %s', sound{distIndex});
    disp(str);
end

if false
    hold on
    plot(ctrOn(5, :), ctrOn(6, :), 'xr')
    plot(dtrOn(5, :), dtrOn(6, :), 'vr')
    
    plot(ctrOff(5, :), ctrOff(6, :), 'xg')
    plot(dtrOff(5, :), dtrOff(6, :), 'vg')
    
    plot(ctrHigh(5, :), ctrHigh(6, :), 'xb')
    plot(ctrHigh(5, :), ctrHigh(6, :), 'vb')
    
    plot(ctrLow(5, :), ctrLow(6, :), 'xy')
    plot(ctrLow(5, :), ctrLow(6, :), 'vy')
    
    plot(ctrN(5, :), ctrN(6, :), 'xk')
    plot(dtrN(5, :), dtrN(6, :), 'vk')
    
    xlabel('5th Dimension');
    ylabel('6th Dimension');
    title('2D plot of accoustic vectors');
end

f = sound{distIndex};
end
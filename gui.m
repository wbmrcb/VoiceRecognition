function varargout = gui(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_OpeningFcn, ...
    'gui_OutputFcn',  @gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code

% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

set(handles.lblStatus,'String','Loading...');

% Defining & Initialization of globals
global Fs; % Sampling Frequency (Hz)
Fs = 8000;
global SoundC;
global listen;
listen = false; % Do not start analyzing

global g; % grid on/off
g = true;

global fileNames;
global sound;
global fileData;
global mfccData;
global vqData;
global distM;
global distances;
global threshold;
global vqpoints;

fileNames = {'on.wav', 'off.wav', 'high.wav', 'low.wav'};
sound = {'on', 'off', 'high', 'low'};
fileData = {0, 0, 0, 0};
mfccData = {0, 0, 0, 0};
vqData = {0, 0, 0, 0};
distM = {0, 0, 0, 0};
distances = {0, 0, 0, 0};
threshold = 9;  % Recognition threshold
vqpoints = 16;

for i = 1:4
    [fileData{i}, Fs] = wavread(fileNames{i});  % Read file data
    mfccData{i} = mfcc(fileData{i},Fs); % Compute MFCC
    vqData{i} = vqlbg(mfccData{i},vqpoints);  % Compute Vector Quantization
end

% Setup data acquisition from sound card
SoundC = analoginput('winsound');
chan = addchannel(SoundC,1);
duration = 0.5; % Half second capture time
set(SoundC,'SampleRate',Fs);
ActualRate = get(SoundC,'SampleRate');
set(SoundC,'SamplesPerTrigger',ActualRate*duration);
set(SoundC,'TriggerChannel',chan);
set(SoundC,'TriggerType','Software');
set(SoundC,'TriggerCondition','Rising');
set(SoundC,'TriggerConditionValue',0.3); % Signal level threshold
set(SoundC,'TriggerDelayUnits','Samples');
set(SoundC,'TriggerDelay',-1000); % Pretrigger samples (1/8s)

set(handles.lblStatus,'String','Done !');
pause(0.5);
set(handles.lblStatus,'String','Press start to listen !');

%% --- Executes on button press in btnStart.
function btnStart_Callback(hObject, eventdata, handles)
% Serial Communication
comStr = get(handles.uSerialPort,'String'); % Get serial port
s = serial(comStr); % Change the port in GUI
set(s,'BaudRate',9600);
global listen;
listen = not(listen); % change state
try
    if listen
        fopen(s);
    end
catch e
    set(handles.lblStatus,'String','Check serial port string');
    return;
end

global SoundC;
global newdata;
global Fs;
global sound;
global mfccData;
global distM;
global distances;
global threshold;
global vqpoints

set(handles.lblStatus,'String','Listening !');
set(handles.btnStart,'String','Stop');

%% Loop after pressing start
while listen
    try
        start(SoundC);
        wait(SoundC,Inf);
        [newdata,time] = getdata(SoundC,4000);
        stop(SoundC);
    catch e
        % Not trowing exception
        break;
    end

    plot(handles.axesPlot,time,newdata);
    xlabel('Time (s)');
    ylabel('Signal Level (V)');
    grid(handles.axesPlot, 'on');
    
    % Analysis
    disp('_____Analysis_____');
    
    disp('MFCC computation');
    mfccN = mfcc(newdata,Fs);
    vqN = vqlbg(mfccN,vqpoints);
    
    minDist = Inf;
    distIndex = 0;
    
    %% Generate MFCC, VQ and Compare
    for i = 1:4
        distM{i} = disteu(mfccData{i}, vqN);% Distances matrix
        distances{i} = sum(min(distM{i},[],2)) / size(distM{i},1);  % distances
        str = fprintf('Distance to %s  \t', sound{i});
        disp(num2str(distances{i}));
        if distances{i} < minDist
            minDist = distances{i};
            distIndex = i;
        end
    end
    
    %% Filter with threshold
    threshold = get(handles.uThreshold,'String');
    threshold = str2num(threshold);
    if minDist > threshold
        disp('No match found');
    else
        str = sprintf('Best matching sound : %s', sound{distIndex});
        disp(str);
        set(handles.lblStatus,'String',str);
        %% Serial Communication
        %comStr = get(handles.uSerialPort,'String'); % Get serial port
        try
            fwrite(s,num2str(distIndex)); % Sending condition
            %fclose(s);
            %delete(s);
            %clear s;
            str = sprintf('Command %s sent', num2str(distIndex));
            disp(str);
            set(handles.lOut,'String',upper(sound{distIndex}));
            pause(1);
            set(handles.lOut,'String',' '); 
        catch e
            set(handles.lblStatus,'String','Check serial port string');
        end
    end
end
fclose(s);
stop(SoundC);
set(handles.lblStatus,'String','Stopped !');
set(handles.btnStart,'String','Start');

%% --- Executes on button press in btnGrid.
function btnGrid_Callback(hObject, eventdata, handles)
global g;
if g == true
    g = false;
    grid(handles.axesPlot, 'on');
else
    g = true;
    grid(handles.axesPlot, 'off');
end

%% --- Executes on button press in btnClr.
function btnClr_Callback(hObject, eventdata, handles)
global newdata;
newdata = 0;
set(handles.lblStatus,'String','Cleared !');
cla(handles.axesPlot,'reset');


%% --- Executes during object creation, after setting all properties.
function uSerialPort_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% --- Executes when user attempts to close gui.
function gui_CloseRequestFcn(hObject, eventdata, handles)
global SoundC;
stop(SoundC);
delete(hObject);


%% --- Executes on button press in recOn.
function recOn_Callback(hObject, eventdata, handles)
global SoundC;
global Fs;
try
    start(SoundC);
    set(handles.lblStatus,'String','Waiting for input.');
    wait(SoundC,Inf);
    [newdata,time] = getdata(SoundC,4000);
    stop(SoundC);
    set(handles.lblStatus,'String','Recording stoped.');
    plot(time,newdata);
    grid(handles.axesPlot, 'on');
    player = audioplayer(newdata, 8000);
    play(player);
    pause(1);
    choice = questdlg('Would you like to save ?', ...
        'Confirmation', ...
        'Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'
            wavwrite(newdata,Fs,'on.wav');
            set(handles.lblStatus,'String','Saved !');
        case 'No'
            set(handles.lblStatus,'String',' ');
    end
catch e
    set(handles.lblStatus,'String','Listening in progress...');
end

%% --- Executes on button press in recOff.
function recOff_Callback(hObject, eventdata, handles)
global SoundC;
global Fs;
try
    start(SoundC);
    set(handles.lblStatus,'String','Waiting for input.');
    wait(SoundC,Inf);
    [newdata,time] = getdata(SoundC,4000);
    stop(SoundC);
    set(handles.lblStatus,'String','Recording stoped.');
    plot(time,newdata);
    grid(handles.axesPlot, 'on');
    player = audioplayer(newdata, 8000);
    play(player);
    pause(1);
    choice = questdlg('Would you like to save ?', ...
        'Confirmation', ...
        'Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'
            wavwrite(newdata,Fs,'off.wav');
            set(handles.lblStatus,'String','Saved !');
        case 'No'
            set(handles.lblStatus,'String',' ');
    end
catch e
    set(handles.lblStatus,'String','Listening in progress...');
end

%% --- Executes on button press in recHigh.
function recHigh_Callback(hObject, eventdata, handles)
global SoundC;
global Fs;
try
    start(SoundC);
    set(handles.lblStatus,'String','Waiting for input.');
    wait(SoundC,Inf);
    [newdata,time] = getdata(SoundC,4000);
    stop(SoundC);
    set(handles.lblStatus,'String','Recording stoped.');
    plot(time,newdata);
    grid(handles.axesPlot, 'on');
    player = audioplayer(newdata, 8000);
    play(player);
    pause(1);
    choice = questdlg('Would you like to save ?', ...
        'Confirmation', ...
        'Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'
            wavwrite(newdata,Fs,'high.wav');
            set(handles.lblStatus,'String','Saved !');
        case 'No'
            set(handles.lblStatus,'String',' ');
    end
catch e
    set(handles.lblStatus,'String','Listening in progress...');
end

%% --- Executes on button press in recLow.
function recLow_Callback(hObject, eventdata, handles)
global SoundC;
global Fs;
try
    start(SoundC);
    set(handles.lblStatus,'String','Waiting for input.');
    wait(SoundC,Inf);
    [newdata,time] = getdata(SoundC,4000);
    stop(SoundC);
    set(handles.lblStatus,'String','Recording stoped.');
    plot(time,newdata);
    grid(handles.axesPlot, 'on');
    player = audioplayer(newdata, 8000);
    play(player);
    pause(1);
    choice = questdlg('Would you like to save ?', ...
        'Confirmation', ...
        'Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'
            wavwrite(newdata,Fs,'low.wav');
            set(handles.lblStatus,'String','Saved !');
        case 'No'
            set(handles.lblStatus,'String',' ');
    end
catch e
    set(handles.lblStatus,'String','Listening in progress...');
end

%% --- Executes on button press in playOn.
function playOn_Callback(hObject, eventdata, handles)
[newdata, Fs] = wavread('on.wav');
player = audioplayer(newdata, Fs);
play(player);
pause(1);


%% --- Executes on button press in playOff.
function playOff_Callback(hObject, eventdata, handles)
[newdata, Fs] = wavread('off.wav');
player = audioplayer(newdata, Fs);
play(player);
pause(1);

%% --- Executes on button press in playHigh.
function playHigh_Callback(hObject, eventdata, handles)
[newdata, Fs] = wavread('high.wav');
player = audioplayer(newdata, Fs);
play(player);
pause(1);

%% --- Executes on button press in playLow.
function playLow_Callback(hObject, eventdata, handles)
[newdata, Fs] = wavread('low.wav');
player = audioplayer(newdata, Fs);
play(player);
pause(1);



function uThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to uThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of uThreshold as text
%        str2double(get(hObject,'String')) returns contents of uThreshold as a double


% --- Executes during object creation, after setting all properties.
function uThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function uSerialPort_Callback(hObject, eventdata, handles)
% hObject    handle to uSerialPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of uSerialPort as text
%        str2double(get(hObject,'String')) returns contents of uSerialPort as a double


% --- Executes on button press in btnPlay.
function btnPlay_Callback(hObject, eventdata, handles)
global newdata;
global Fs;
try
    player = audioplayer(newdata, Fs);
    play(player);
    pause(1);
catch e
    % No exception thrown
end
%--------------------------------------------------------------------------

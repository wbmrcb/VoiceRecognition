% Serial Communication
s = serial('COM4'); % Change the port in GUI
set(s,'BaudRate',9600);
global listen;
listen = not(listen); % change state
try
    if listen
        disp('Opening Srial port');
        fopen(s);
    end
catch e
    disp('Check serial port string');
    return;
end
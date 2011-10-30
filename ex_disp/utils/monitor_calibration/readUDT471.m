%function lumVals = readUDT471(grayval, nvals, interval)
%
% This function shows the "grayval" and then for nvals readings with
% interval seconds between them it reads the value on the photometer.
% Useful for measuring the time course over which the CRT warms up.
%
% Currently this is setup to run on a Mac with a Keyspan USB to serial
% adapter. If a different adapter or platform is used the code to open the
% serial port would need to be changed.
%

function lumVals = readUDT471(grayval, nvals, interval)

delete(instrfind)

out = serial('/dev/cu.KeySerial1');
fopen(out);

Screen('LoadNormalizedGammaTable',0);

w = Screen('OpenWindow',0);
Screen(w,'FillRect',0);

Screen('Flip',w);

lumVals = cell(length(nvals),1);

for i = 1:3;
    pause(0.25);
    beep
end

for I=1:nvals
    Screen(w,'FillRect',grayval);
    Screen('DrawText',w,num2str(I),100,100);
    Screen('Flip',w);
       
    pause(interval);
    
    fprintf(out,'r');
    lumVals{I} = fgetl(out)
end

delete(instrfind);

sca

lumVals = cellfun(@pullOutNumber,lumVals);

end

function n = pullOutNumber(s)

s = s(3:strfind(s,'cd/m2')-1);

switch s(end)
    case ' '
        n = str2double(s);
    case 'm'
        n = str2double(s(1:end-1))/1000;
    case 'k'
        n = str2double(s(1:end-1))*1000;
    case 'u' % this one is likely wrong
        n = str2double(s(1:end-1))/10000;
    otherwise
        disp('Problem');
end

end
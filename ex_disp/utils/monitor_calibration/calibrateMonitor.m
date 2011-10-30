%function calibVals = calibrateMonitor(vals,color)
%
% This function will display different gray levels on the screen and
% communicate with a UDT 471 photometer over the serial port to read
% luminance values. It returns the list of luminance values (in cd/m^2)
% associated with the grayscale values that were passed in.
%
% The input "vals" should be a list of luminance values from 0 to 255 to be
% displayed.
%
% The input "color" can be 'gray', 'red', 'green', or 'blue' (default is
% gray if no parameter is passed), and this determines the color to be
% calibrated. If 'other' is used, 
%
% e.g., lum = calibrateMonitors(0:255,'gray');
%
% NOTE: If the program hangs there's a good chance that your photometer is
% not powered on, which will cause the serial port calls to hang.
%

function calibVals = calibrateMonitor(vals,color)

if (nargin < 2)
    color = 'gray';
end

delete(instrfind)

out = serial('/dev/cu.KeySerial1');
fopen(out);

Screen('LoadNormalizedGammaTable',0);

w = Screen('OpenWindow',0);
Screen(w,'FillRect',0);

Screen('Flip',w);

calibVals = cell(length(vals),1);

for i = 1:3;
    pause(1);
    beep
end

pad = zeros(1,length(vals));
if (strcmp(color,'gray'))
    rgbvals = [vals;vals;vals];
elseif (strcmp(color,'red'))
    rgbvals = [vals;pad;pad];
elseif (strcmp(color,'green'))
    rgbvals = [pad;vals;pad];
elseif (strcmp(color,'blue'))
    rgbvals = [pad;pad;vals];
elseif (strcmp(color,'other'))
    rgbvals = vals;
    if (size(rgbvals,1) ~= 3)
        error('vals must be a 3xN list of RGB values')
    end
end

for i = 1:length(vals)
%    Screen(w,'FillRect',vals(i),[5 100 200 200]);
    Screen(w,'FillRect',rgbvals(:,i));
    Screen('DrawText',w,num2str(rgbvals(:,i)'),100,100);
    Screen('Flip',w);
       
    pause(5);
    
    fprintf(out,'r');
    calibVals{i} = fgetl(out);
end

delete(instrfind);

sca

calibVals = cellfun(@pullOutNumber,calibVals);

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
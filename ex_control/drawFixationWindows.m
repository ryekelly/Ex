function drawFixationWindows(fixX,fixY,r,varargin)
% function drawFixationWindows(fixX,fixY,r)
% function drawFixationWindows(fixX,fixY,r,winColors)
% 
% ex helper function. draws the fixation windows to the screen. used by
% functions like waitForFixation, waitForMS, and waitForSlave, since they
% require the fixation window parameters as input.
%
% If a fourth argument, winColors, should be a N x 3 matrix where N is the
% number of windows (and the 3 values are the RGB window colors from
% 0-255). If only one RGB value is given, it applies to all windows. If
% winColors argument is not provided, the windows are yellow by default.
%
% fixX, fixY and r can be vectors for multiple windows
%
%Modified 28Mar2012 by Adam Snyder to support multiple windows (and colors)

global calibration wins;
   
    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
    Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);

    if nargin > 0
        fixY = -fixY; %flip y coordinate because PTB's native coordinate space has negative up, but Ex uses negative down. -ACS13Mar2012
        numWindows = unique([length(fixX) length(fixY) length(r)]); 
        assert(numel(numWindows)==1,'Fixation window parameters X, Y and R must be same size');
        if nargin > 3
            winColors = varargin{1};
            if size(winColors,1)>1
                assert(size(winColors,1)==numWindows,'If more than one color is provided then number of colors must equal the number of windows');
            else
                winColors = repmat(winColors(:)',numWindows,1);
            end;
        else
            winColors = repmat([255 255 0],numWindows,1);
        end;                
        for i = 1:numWindows
            fixationWindow = r(i).*[-1 -1; -1 1; 1 1; 1 -1] + repmat([fixX(i) fixY(i)],4,1); 

            Screen('FramePoly',wins.eye,winColors(i,:),fixationWindow.*repmat(wins.pixelsPerPixel,4,1)+repmat(wins.midE,4,1));
            vPoints(:,1) = [fixationWindow ones(size(fixationWindow,1),1)] * calibration{5};
            vPoints(:,2) = [bsxfun(@times,fixationWindow,[1 -1]) ones(size(fixationWindow,1),1)] * calibration{6};
            Screen('FramePoly',wins.voltage,winColors(i,:),vPoints);
        end;
    end
end
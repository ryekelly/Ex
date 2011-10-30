function drawFixationWindows(fixX,fixY,r)
% function drawFixationWindows(fixX,fixY,r)
% 
% ex helper function. draws the fixation windows to the screen. used by
% functions like waitForFixation, waitForMS, and waitForSlave, since they
% require the fixation window parameters as input.

global calibration wins;

    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
    Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);

    if nargin > 0
        fixationWindow = [-r -r; -r r; r r; r -r] + repmat([fixX fixY],4,1);
    
        Screen('FramePoly',wins.eye,[255 255 0],fixationWindow.*repmat(wins.pixelsPerPixel,4,1)+repmat(wins.midE,4,1));
        vPoints(:,1) = [fixationWindow ones(size(fixationWindow,1),1)] * calibration{5};
        vPoints(:,2) = [fixationWindow ones(size(fixationWindow,1),1)] * calibration{6};
        Screen('FramePoly',wins.voltage,[255 255 0],vPoints);
    end
end
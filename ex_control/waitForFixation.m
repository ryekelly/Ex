function choice = waitForFixation(waitTime,fixX,fixY,r,varargin)
% function choice = waitForFixation(waitTime,fixX,fixY,r)
% function choice = waitForFixation(waitTime,fixX,fixY,r,winColors)
% 
% ex trial helper function: looks for eye positions within a window,
% returning either when the eye enters the window or when time expires
%
% waitTime: time before function failure (in ms)
% fixX, fixY: in pixels, the offset of the fixation from (0,0)
% r: in pixels, the radius of the fixation window
% winColors: If specified, provides a list of colors (N x 3) for the
% fixation windows drawn on the user screen
%
%
% returns a value "choice" that indicates the window that was fixated, or 
% 0 if no window was fixated.

% Revised 24Feb2012 by Adam Snyder (adam@adamcsnyder.com) --based on an
% existing Ex function.
%
% Revised 23Oct2012 -ACS

global calibration aio;

assert(nargin>=4,'waitForFixationChoice must have fixation windows specified');

numWindows = unique([length(fixX) length(fixY) size(r,2)]);
assert(numel(numWindows)==1,'Fixation window parameters X, Y and R must be same size');
if nargin > 4
    winColors = varargin{1};
else
    winColors = [255 255 0];
end;
drawFixationWindows(fixX,fixY,r,winColors);

thisStart = tic;

choice = -1;

while 1
    d = get(aio,'UserData');
    eyePos(1,1) = [d(end,:) 1] * calibration{3};
    eyePos(1,2) = [d(end,:) 1] * calibration{4};
    
    for i = 1:numWindows
        relEyePos = eyePos - [fixX(i) fixY(i)];
        
        if gazeIsInWindow(relEyePos,r(:,i));
            choice = i;
            break;
        end
        
        t2 = toc(thisStart);
        if t2*1000 > waitTime
            choice = 0;
            break;
        end
        
        if keyboardEvents()
            choice = 0;
            break;
        end
        
        drawnow;
    end;
    if choice>-1, break; end;
end

drawFixationWindows()

end

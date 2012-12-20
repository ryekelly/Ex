function trialSuccess = waitForMS(t,fixX,fixY,r,varargin)
% function success = waitForMS(waitTime,fixX,fixY,r)
% 
% ex trial helper function: waits for t ms, checking to ensure that the eye
% remains within the fixation window.  If time expires, trialSuccess = 1, 
% but if fixation is broken first, trialSuccess returns 0
%
% waitTime: time to maintain fixation (in ms)
% fixX, fixY: in pixels, the offset of the fixation from (0,0)
% r: in pixels, the radius of the fixation window
    
global calibration aio;

    if nargin > 4
        winColors = varargin{1};
    else
        winColors = [255 255 0];
    end;
    if nargin >= 4
        drawFixationWindows(fixX,fixY,r,winColors);
    elseif nargin ~=1
        error('waitForMs can have exactly 1, 4 or 5 input arguments');
    end
    
    trialSuccess = 1;
    tic;
        
    if nargin >= 4         
        while toc * 1000 < t
            d = get(aio,'UserData');
            eyePos(1,1) = [d(end,:) 1] * calibration{3};
            eyePos(1,2) = [d(end,:) 1] * calibration{4};

            eyePos = eyePos - [fixX fixY];

            if ~gazeIsInWindow(eyePos,r);
                trialSuccess = 0;
                break;
            end

            if keyboardEvents()
                trialSuccess = 0;
                break;
            end

            drawnow;
        end
    else
        while toc * 1000 < t
            if keyboardEvents()
                trialSuccess = 0;
                break;
            end
        end
    end
    
    if nargin > 2
        drawFixationWindows()
    end
end
function trialSuccess = waitForMS(t,fixX,fixY,r)
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
    
    if nargin > 2
        drawFixationWindows(fixX,fixY,r);
    end
    
    trialSuccess = 1;
    tic;
        
    if nargin > 2           
        while toc * 1000 < t
            d = get(aio,'UserData');
            eyePos(1,1) = [d(end,:) 1] * calibration{3};
            eyePos(1,2) = [d(end,:) 1] * calibration{4};

            eyePos = eyePos - [fixX fixY];

            if eyePos(1) < -r || eyePos(1) > r || eyePos(2) < -r || eyePos(2) > r
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
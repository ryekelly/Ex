function trialSuccess = waitForSlave(fixX,fixY,r)
% function trialSuccess = waitForSlave(fixX,fixY,r)
% 
% ex trial helper function: waits for a message from the slave, checking 
% to ensure that the eye remains within the fixation window.  If the slave 
% responds, trialSuccess = 1, but if fixation is broken first, trialSuccess 
% returns 0
%
% fixX, fixY: in pixels, the offset of the fixation from (0,0)
% r: in pixels, the radius of the fixation window

global calibration aio out;
    
    drawFixationWindows(fixX,fixY,r);
    
    trialSuccess = 1;
    while get(out,'BytesAvailable') == 0                
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
    
    drawFixationWindows();
end

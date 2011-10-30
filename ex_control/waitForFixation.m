function success = waitForFixation(waitTime,fixX,fixY,r)
% function success = waitForFixation(waitTime,fixX,fixY,r)
% 
% ex trial helper function: looks for eye positions within a window,
% returning either when the eye enters the window or when time expires
%
% waitTime: time before function failure (in ms)
% fixX, fixY: in pixels, the offset of the fixation from (0,0)
% r: in pixels, the radius of the fixation window

    global calibration aio;

    drawFixationWindows(fixX,fixY,r);
    
    tic;

    success = 1;

    while 1
        d = get(aio,'UserData');
        eyePos(1,1) = [d(end,:) 1] * calibration{3};
        eyePos(1,2) = [d(end,:) 1] * calibration{4};

        eyePos = eyePos - [fixX fixY];
        
        if eyePos(1) > -r && eyePos(1) < r && eyePos(2) > -r && eyePos(2) < r
            break;
        end

        t2 = toc;
        if t2*1000 > waitTime
            success = 0;
            break;
        end
        
        if keyboardEvents()        
            success = 0;
            break;
        end        
        
        drawnow;
    end
    
    drawFixationWindows()
end

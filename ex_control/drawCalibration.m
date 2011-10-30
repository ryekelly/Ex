function drawCalibration(n)
% function drawCalibration(n)
%
% used by the calibration procedure.  Draws up to n dots on the control
% screen.

global wins calibration;
            
    for i = 1:n
        pt = calibration{2}(i,:);
        Screen('FillOval',wins.voltageBG,[0 0 255],[pt - wins.calibDotSize pt + wins.calibDotSize]);
    end
end

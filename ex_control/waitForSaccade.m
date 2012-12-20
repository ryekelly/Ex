function detectSaccades(varargin)

%Notes: this function is in development. Right now, varargin isn't doing
%anything and all the parameters are being hard-coded below. Later the
%argument handling will be implemented. -ACS 25Oct2012

global aio calibration;

threshold = 10; %in degrees/sec

startTime = tic;
while toc(startTime)<=waitTime
    
    period = get(aio,'AveragePeriod'); %use the average sampling period as an estimate
    pt = get(aio,'UserData'); %get position data from aio timer object    
    posPx(:,1) = padarray(pt,[0 1],1,'post')*calibration{3}; %convert native units to screen pixels
    posPx(:,2) = padarray(pt,[0 1],1,'post')*calibration{4}; %convert native units to screen pixels
    posDeg = pix2deg(posPx);
    z = complex(posDeg(:,1),imag(posDeg(:,2))); %complex-valued representation of eye position
    dz = abs(diff(z)); %magnitude of first derivative of eye position
    dzdt = dz./period; %first derivative of eye position with respect to sampling period (velocity)
    d2zdt2 = diff(dzdt); %second derivative of eye position with respect to sampling period (acceleration)
    
    if mean(dzdt(end-10:end))>threshold
        fprintf('SACCADE');
        break;
    end;
    
end

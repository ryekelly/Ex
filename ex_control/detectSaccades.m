function [isSaccade, posPx] = detectSaccades(varargin)

%Notes: this function is in development. Right now, varargin isn't doing
%anything and all the parameters are being hard-coded below. Later the
%argument handling will be implemented. -ACS 25Oct2012

global aio eyeHistory calibration trialData wins traceColor;

velocThresh = 10; %in degrees/sec
smoothSize = 5; %number of samples in a boxcar filter applied to isSaccade vector
% accelThresh = 100;

% minMagnitude = 0.2; %in degrees
% isSaccade = false;
% drawSaccades = true;

period = get(aio,'AveragePeriod'); %use the average sampling period as an estimate
pt = eyeHistory; 
posPx(:,1) = padarray(pt,[0 1],1,'post')*calibration{3}; %convert native units to screen pixels
posPx(:,2) = -(padarray(pt,[0 1],1,'post')*calibration{4}); %convert native units to screen pixels
posDeg = pix2deg(posPx); %convert pixels to degrees
z = complex(posDeg(:,1),imag(posDeg(:,2))); %complex-valued representation of eye position
dz = abs(diff(z)); %magnitude of first derivative of eye position (pre-pend zero to maintain size)
dzdt = dz./period; %first derivative of eye position with respect to sampling period (velocity)
d2zdt2 = diff(dzdt); %second derivative of eye position with respect to sampling period (acceleration)
dzdt = [0;dzdt]; %append zero to keep same length as position
d2zdt2 = [0;0;d2zdt2]; %append 2 zeros to keep same length as position

isSaccade = dzdt>velocThresh;
if numel(isSaccade)>3*smoothSize %avoids an error
    b = ones(1,smoothSize)./smoothSize;
    isSaccade = logical(round(filtfilt(b,smoothSize,double(isSaccade))));
end;

if isSaccade(end), traceColor = [0 255 255]; else traceColor = [255 0 0]; end; %this isn't working too well right now --meant to be for drawing on the control screen... -ACS

%% scraps:
 
% saccadeVertices = diff([isSaccade;0]);
% saccadeEnds = find(sign(saccadeVertices)<0);
% saccadeStarts = find(sign(saccadeVertices)>0);
% if ~isempty(saccadeEnds)&&~isempty(saccadeStarts)
%     saccadeStarts(saccadeStarts>saccadeEnds(end))=[];
%     saccadeEnds(saccadeEnds<saccadeStarts(1))=[];
%     saccades = [saccadeStarts saccadeEnds];
%     saccadeMagnitudes = abs(z(saccadeEnds)-z(saccadeStarts));
%     saccades(saccadeMagnitudes<minMagnitude) = [];
% end;

% saccadeEndpoints = logical([0; abs(sign(diff(isSaccade)))]);
% % try    
%     if drawSaccades&&sum(saccadeEndpoints)>1
%         endpoints = posPx(saccadeEndpoints,:);
%         endpoints(:,2) = -endpoints(:,2); % flip Y coordinate
%         endpoints = bsxfun(@times,endpoints,wins.pixelsPerPixel);
%         endpoints = bsxfun(@plus,endpoints,wins.midE);
%         Screen('DrawLines',wins.eye,endpoints',1,[0 255 255]);
%         Screen('CopyWindow',wins.eye,wins.w,[0 0 wins.eyeSize(3:4)-wins.eyeSize(1:2)],wins.eyeSize);
%         Screen('Flip',wins.w,0,0,1);
%     end;
    
%     trialData{9} = sprintf('Velocity: % 8.2f deg/sec',dzdt(end));
%     if isSaccade(end)
%         trialData{10} = 'SACCADE!';
%     else
%         trialData{10} = '';
%     end;
%     drawTrialData;
% catch
% end



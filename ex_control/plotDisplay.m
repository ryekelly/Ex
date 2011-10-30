function plotDisplay(obj, ~)
%function plotDisplay(obj, event)
%
% called by a timer initiated by runex. plots the current eye position on
% the screen.  

global calibration wins aio test;

r = 5;

aioV = get(aio, 'UserData');
set(aio,'UserData',aioV(end,:));

%aioV = [get(obj,'UserData'); aioV];

aioEyes = zeros(size(aioV,1),2);

if length(calibration) > 3
    aioEyes(:,1) = [aioV ones(size(aioV,1),1)] * calibration{3};
    aioEyes(:,2) = [aioV ones(size(aioV,1),1)] * calibration{4};
end
   
aioEyes = aioEyes .* repmat(wins.pixelsPerPixel,size(aioEyes,1),1) + repmat(wins.midE,size(aioEyes,1),1);

set(obj,'UserData',aioV(end,:));

mid = aioV(2:end-1,:)';
aioV = [aioV(1,:)' reshape(repmat(mid,2,1),2,size(mid,2)*2) aioV(end,:)'];
mid = aioEyes(2:end-1,:)';
aioEyes = [aioEyes(1,:)' reshape(repmat(mid,2,1),2,size(mid,2)*2) aioEyes(end,:)'];

Screen('DrawLines',wins.voltage,aioV,1,[255 0 0]);
Screen('CopyWindow',wins.voltage,wins.w,[0 0 wins.voltageSize(3:4)-wins.voltageSize(1:2)],wins.voltageSize);
Screen('FillOval',wins.w,[255 255 255],[aioV(:,end)' - r aioV(:,end)' + r]+[wins.voltageSize(1:2) wins.voltageSize(1:2)]);

Screen('DrawLines',wins.eye,aioEyes,1,[255 0 0]);
Screen('CopyWindow',wins.eye,wins.w,[0 0 wins.eyeSize(3:4)-wins.eyeSize(1:2)],wins.eyeSize);
Screen('FillOval',wins.w,[255 255 255],[aioEyes(:,end)' - r aioEyes(:,end)' + r]+[wins.eyeSize(1:2) wins.eyeSize(1:2)]);

Screen('CopyWindow',wins.info,wins.w,[0 0 wins.infoSize(3:4)-wins.infoSize(1:2)],wins.infoSize);
Screen('CopyWindow',wins.hist,wins.w,[0 0 wins.histSize(3:4)-wins.histSize(1:2)],wins.histSize);

Screen('Flip',wins.w,0,0,1);
   

end
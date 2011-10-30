function setWindowBackground(w)
% function setWindowBackground(w)
% draws a cross hairs on an arbitrary window.  needs to be called whenever
% the voltage or eye window is redrawn with calibration dots

    gray=(WhiteIndex(0)+BlackIndex(0))/2;

    [width height] = Screen('WindowSize',w);
    
    Screen(w,'FillRect',gray);
    Screen(w,'DrawLine',[255 255 255],0,height/2,width,height/2);
    Screen(w,'DrawLine',[255 255 255],width/2,0,width/2,height);
end

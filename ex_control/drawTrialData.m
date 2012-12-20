function drawTrialData
% function drawTrialData
%
% simply writes the current trialData to the screen. used by runex and can
% be used within an ex file

global trialData wins;
    
    x = 0;
    y = 0;
    textSize = 14; lineSpacing = 1.8;
    gray=(WhiteIndex(0)+BlackIndex(0))/2;
        
    Screen(wins.info,'FillRect',gray);
    Screen('TextSize',wins.info,textSize);
    for i = 1:length(trialData)
        Screen('DrawText',wins.info,trialData{i},x,y);
        y = y + lineSpacing.*textSize;
    end
end

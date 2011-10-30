function drawTrialData
% function drawTrialData
%
% simply writes the current trialData to the screen. used by runex and can
% be used within an ex file

global trialData wins;
    
    x = 0;
    y = 0;
    
    gray=(WhiteIndex(0)+BlackIndex(0))/2;
        
    Screen(wins.info,'FillRect',gray);
    
    for i = 1:length(trialData)
        Screen('DrawText',wins.info,trialData{i},x,y);
        y = y + 50;
    end
end

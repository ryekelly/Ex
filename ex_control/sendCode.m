function sendCode(code)
% function sendCode(code)
%
% simply calls digCode, assuming that the sendingCodes flag is set.

    global params thisTrialCodes trialTic

    if params.sendingCodes
        digCode(code);        
    end
    
    thisTrialCodes(end+1,:) = [code toc(trialTic)];
end

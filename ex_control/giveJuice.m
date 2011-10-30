function giveJuice
% function giveJuice
% 
% provides a reward.  uses juiceX and juiceTTLDuration to determine the
% value of reward.

global params;
    
    if params.rewarding            
        reward(params.juiceTTLDuration);
    
        for i = 2:params.juiceX
            pause(params.juiceInterval/1000); % wait for the next rewards
            reward(params.juiceTTLDuration);
        end
    end
end

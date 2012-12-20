function giveJuice(juiceX,juiceInterval,juiceTTLDuration)
% function giveJuice(juiceX,juiceInterval,juiceTTLDuration)
% 
% provides a reward.  uses juiceX and juiceTTLDuration to determine the
% value of reward. If no arguments are provided for either one, uses the 
% global params values.
%
% juiceX - number of juice rewards
% juiceInterval - time in ms between rewards
% juiceTTLDuration - if on computer control, ms length of juice reward (set
%     to 1 ms if not on computer control)


global params;
    
if params.rewarding
    if (nargin < 3)
        juiceTTLDuration = params.juiceTTLDuration;
    end
    if (nargin < 2)
        juiceInterval = params.juiceInterval;
    end
    if (nargin < 1)
        juiceX = params.juiceX;
    end
    
    reward(juiceTTLDuration);
    
    for i = 2:juiceX
        pause(juiceInterval/1000); % wait for the next reward
        reward(juiceTTLDuration);
    end
end

end

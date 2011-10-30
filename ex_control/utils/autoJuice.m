function autoJuice(interval,nRewards)
% function autoJuice(interval,nRewards)
%  interval: in seconds
%  nRewards: total number of rewards (all single juice)

for i = 1:nRewards
    reward
    pause(interval); % wait 150 ms before the 2nd reward
end

function plotEyes(obj, ~)
%function plotEyes(obj, event)
%
% called by a timer initiated by runex. gets the current eye position on
% the screen.  only used in monkey mode.

global wins; % eyes params;

pt = samp;

%%%% MATT if you want to smooth the last 10 points do this
% pt = mean(samp(10));

pt = pt .* wins.pixelsPerMV + wins.midV;

set(obj,'UserData',[get(obj,'UserData');pt]);

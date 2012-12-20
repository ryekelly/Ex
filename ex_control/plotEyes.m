function plotEyes(obj, ~)
%function plotEyes(obj, event)
%
% called by a timer initiated by runex. gets the current eye position on
% the screen.  only used in monkey mode.

global wins params eyeHistory;

%pt = samp;

%%%% MATT if you want to smooth the last X points do this
pt = mean(samp(params.eyeSmoothing),1);

pt = pt .* wins.pixelsPerMV + wins.midV;

pt(2) = wins.voltageDim(4) - pt(2); % flip Y coordinate

eyeHistory = [eyeHistory;pt];

set(obj,'UserData',[get(obj,'UserData');pt]);

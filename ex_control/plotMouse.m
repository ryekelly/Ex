function plotMouse(obj, ~)
%
% called by a timer initiated by runex. gets the current eye position on
% the screen.  only used in mouse mode.

global test eyeHistory

[x y] = GetMouse;
eyeHistory = [eyeHistory;x y];
set(obj,'UserData',[get(obj,'UserData');x y]);

end
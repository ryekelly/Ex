% Calibrate gray, red, blue, and green. Make sure to warm up the monitor
% first (minimum 1 hr).

clear all
lv = calibrateMonitor(0:255,'gray')
rv = calibrateMonitor(0:255,'red')
bv = calibrateMonitor(0:255,'blue')
gv = calibrateMonitor(0:255,'green')
save lumvals.mat


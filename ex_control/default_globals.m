%%% GLOBAL PARAMETERS FILE

% Subject ID for file-saving purposes
params.SubjectID = 'WileE';
% params.SubjectID = 'BooBoo';

%%%% Settings for debugging/demo
params.getEyes = 1; % 1 for using monkey eye movements, 0 for mouse
params.sendingCodes = 1; % 1 for sending digital codes, 0 for none
params.rewarding = 1; % 1 for providing rewards, 0 for none
params.getSpikes = 0; % 1 to bring in spikes from analog input, 0 to not
params.writeFile = 1; % 1 to write trial data to file, 0 to not
%
params.controlIP = '192.168.1.11'; % IP address of control computer
params.displayIP = '192.168.1.10'; % IP address of display computer
params.screenDistance = 36; % distance from eye to screen in cm
params.pixPerCM = 27.03; % pixels per centimeter of screen
% fixation window (pixels)
params.fixWinRad = 20; %20  -use a column vector (e.g., [20;20]) for a rectangular (or square) window -first element is half-width and second element is half-height)
% target window (pixels)
params.targWinRad = 40; %35
%calibration params

%%
params.extent = 250; % spacing of calibration dots in pixels
params.calibX = [-1 0 1] * params.extent;
params.calibY = [1 0 -1] * params.extent;
% juice-related params
params.juiceX = 1; % number of times juice is repeated
params.juiceInterval = 150; % in ms
params.juiceTTLDuration = 1; % in ms, must be >= 1 to give juice
% parameters for displaying online histogram
params.histogramSamples = 5000;
params.spikeThreshold = 1;
params.histTickSpacing = 250;
% used by plotEyes to smooth eye movements - currently just a mean of last
% 'n' data points
params.eyeSmoothing = 10; % must be >=1
params.drawSaccades = true;
% Number of Stimuli per fixation (ex_blah.m must be updated to support
% this). Look at ex_activefixation.m for an example
% params.nStimPerFix = 5; %Moved this to XML control. Added default to runex. -ACS 24Oct2012

%screen parameters
wins.voltageSize = [0 0 500 500];
wins.eyeSize = [613 0 1279 500];
wins.infoSize = [100 550 1000 900];
wins.histSize = [1000 550 1200 700];
wins.screenNumber=0;
% size of dot on eye movement screen
wins.calibDotSize = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 DIGITAL CODES LIST (0-255)            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% General instructions for codes
% 0-255: standard trial codes
% 256-511: ascii text
% 1000-32000: custom user code range - use these for exfile-specific codes
% 32768-65535: condition numbers
codes = struct();

% trial boundaries
codes.START_TRIAL = 1;
codes.END_TRIAL = 255;

% stimulus / trial event codes
codes.FIX_ON = 2 ;
codes.FIX_OFF = 3 ;
codes.FIX_MOVE = 4 ;
codes.REWARD = 5 ;
%
codes.STIM_ON = 10 ;
codes.STIM1_ON = 11 ;
codes.STIM2_ON = 12 ;
codes.STIM3_ON = 13 ;
codes.STIM4_ON = 14 ;
codes.STIM5_ON = 15 ;
codes.STIM6_ON = 16 ;
codes.STIM7_ON = 17 ;
codes.STIM8_ON = 18 ;
codes.STIM9_ON = 19 ;
codes.STIM10_ON = 20 ;
codes.STIM_OFF = 40 ;
codes.STIM1_OFF = 41 ;
codes.STIM2_OFF = 42 ;
codes.STIM3_OFF = 43 ;
codes.STIM4_OFF = 44 ;
codes.STIM5_OFF = 45 ;
codes.STIM6_OFF = 46 ;
codes.STIM7_OFF = 47 ;
codes.STIM8_OFF = 48 ;
codes.STIM9_OFF = 49 ;
codes.STIM10_OFF = 50 ;
codes.TARG_ON = 70 ;
codes.TARG1_ON = 71 ;
codes.TARG2_ON = 72 ;
codes.TARG3_ON = 73 ;
codes.TARG4_ON = 74 ;
codes.TARG5_ON = 75 ;
codes.TARG6_ON = 76 ;
codes.TARG7_ON = 77 ;
codes.TARG8_ON = 78 ;
codes.TARG9_ON = 79 ;
codes.TARG10_ON = 80 ;
codes.TARG_OFF = 100 ;
codes.TARG1_OFF = 101 ;
codes.TARG2_OFF = 102 ;
codes.TARG3_OFF = 103 ;
codes.TARG4_OFF = 104 ;
codes.TARG5_OFF = 105 ;
codes.TARG6_OFF = 106 ;
codes.TARG7_OFF = 107 ;
codes.TARG8_OFF = 108 ;
codes.TARG9_OFF = 109 ;
codes.TARG10_OFF = 110 ;
codes.USTIM_ON = 130 ;
codes.USTIM_OFF = 131 ;

% behavior codes
codes.FIXATE  = 140 ;	% attained fixation 
codes.SACCADE = 141 ;	% initiated saccade

% trial outcome codes
codes.CORRECT = 150 ;	% Independent of whether reward is given
codes.IGNORED = 151 ;	% Never fixated or started trial
codes.BROKE_FIX = 152 ; % Left fixation before trial complete
codes.WRONG_TARG = 153 ; % Chose wrong target
codes.BROKE_TARG = 154 ; % Left target fixation before required time
codes.MISSED = 155 ;	% for a detection task
codes.FALSEALARM = 156 ;
codes.NO_CHOICE = 157 ;	% saccade to non-target / failure to leave fix window
codes.WITHHOLD = 158 ; %correctly-withheld response

%%
% retry.CORRECT = 0 ;	% Independent of whether reward is given
% retry.IGNORED = 1 ;	% Never fixated or started trial
% retry.BROKE_FIX = 1 ; % Left fixation before trial complete
% retry.WRONG_TARG = 0 ; % Chose wrong target
% retry.BROKE_TARG = 1 ; % Left target fixation before required time
% retry.MISSED = 0 ;	% for a detection task
% retry.FALSEALARM = 0 ;
% retry.NO_CHOICE = 0 ;	% saccade to non-target / failure to leave fix window
% retry.WITHHOLD = 0 ; %correctly-withheld response
% retry.SACCADE = 0;
% touch bar / lever / button press codes would go here

% OLD CODES
% codes for sending over digital port
%codes = struct();
%codes.START_TRIAL = 1;
%codes.END_TRIAL = 2;
%codes.FIX_ON = 5;
%codes.FIX_OFF = 6;
%codes.STIM_ON = 7;
%codes.STIM_OFF = 8;
%codes.FIX_MOVE = 9;
%codes.FIX_CAUGHT = 10;
%codes.CONDITION = 15;
%codes.JUICE = 18;
%codes.REWARD = 19;
%codes.START_HISTOGRAM = 50;
%codes.ALIGN_HISTOGRAM = 51;
%codes.STOP_HISTOGRAM = 52;
% codes.NOFIXATION
% codes.BROKEFIXATION (during the stimulus)
% codes.DIDNTGETTOTARGET
% codes.LEFTTARGETEARLY
% codes.WRONGTARGET
% codes.CORRECTTARGET
% general ABORT code?


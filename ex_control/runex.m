function runex(xmlFile,repeats,outfile,~)
% function runex(xmlFile,repeats,outfile,demoMode)
%
% main Ex function. 
%
% xmlFile: the xml file name for the desired experiment
% repeats (optional): the number of blocks to run. overrides the variable
%   'rpts' in the xml file
% outfile: if present, the full list of digital codes sent is written to
%    this filename
% demoMode: if present, runs in mouse mode with no rewarding or digital codes
%
%
% Modified:
%
% 2012/10/22 by Matt Smith - enables support for automatic output
% file naming. Also fixes the path issues.
%
%

%Screen('Preference', 'SkipSyncTests', 1);

% make sure behav and allCodes are empty to start (it will get loaded later
% if you specify an outfile)

%#ok<*FNDSB> %ignore chidings about logical indexing -ACS

clear global behav;
clear global allCodes;

global aio eyeHistory;
global trialSpikes trialCodes thisTrialCodes trialTic allCodes;
global trialMessage trialData;
global wins params codes calibration stats;
global behav;

% Change to the C:\Ex_local directory to start the program. If this
% directory doesn't exist, you have problems. Ex should not be run from
% within the C:\Ex directory
cd('C:\Ex_local');

% Check that there are 'ex', 'xml' and 'data' subdirectories
if (exist('ex','dir') ~= 7)
    error('Could not find EX subdirectory. Current directory is: %s',pwd);
else
    addpath('ex');
end

if (exist('xml','dir') ~= 7)
    error('Could not find XML subdirectory. Current directory is: %s',pwd);
else
    addpath('xml');
end

if (exist('data','dir') ~= 7)
    error('Could not find DATA subdirectory. Current directory is: %s',pwd);
else
    addpath('data');
end

tic
try
    [expt eParams eRand] = readExperiment(['xml/' xmlFile]);
    eParams.xmlFile = xmlFile;
catch 
    fprintf('Error reading xml file: %s',xmlFile);
    return;
end

%eParams defaults: -ACS 23Oct2012
if ~isfield(eParams,'nStimPerFix'),eParams.nStimPerFix=1;end;
if ~isfield(eParams,'blockRandomize'),eParams.blockRandomize=true;end;
if ~isfield(eParams,'conditionFrequency'),eParams.conditionFrequency='uniform';end;
if ~isfield(eParams,'numBlocksPerRandomization'),eParams.numBlocksPerRandomization=1;end;
if ~isfield(eParams,'exFileControl'),eParams.exFileControl='no';end;
if ~isfield(eParams,'badTrialHandling'),eParams.badTrialHandling='reshuffle';end; %options are 'noRetry','immediateRetry','reshuffle','endOfBlock'

%retry defaults: -ACS 19Dec2012
%By default, the condition is retried for every outcome except 'correct',
%'withhold' (assuming that means a correct withhold), ans 'saccade' (e.g.,
%for a microstim paradigm). Each field of 'retry' should be the name of a
%field in the 'codes' global variable that is used as a result code by the
%ex files. -ACS
retry = struct('CORRECT',       0,...
               'IGNORED',       1,...
               'BROKE_FIX',     1,...
               'WRONG_TARG',    1,...
               'BROKE_TARG',    1,...
               'MISSED',        1,...
               'FALSEALARM',    1,...
               'NO_CHOICE',     1,...
               'WITHHOLD',      0,...
               'SACCADE',       0);
allFields = fieldnames(eParams);
retryFields = cellfun(@cell2mat,regexp(allFields,'(?<=retry_)\w*','match'),'uniformoutput',0);
isRetryField = ~cellfun(@isempty,retryFields);
retryFields = retryFields(isRetryField);
for fx = 1:numel(retryFields)
    retry.(retryFields{fx}) = eParams.(retryFields{fx});
end;

% initialize variables for storing spikes, codes and behavior data
trialSpikes = cell(length(expt),1);
trialCodes = cell(length(expt),1);
for i = 1:length(expt)
    trialSpikes{i} = cell(0);
    trialCodes{i} = cell(0);
end
allCodes = cell(0); % for storing the all the trial codes and results
behav = struct(); % behav is a struct for user data to be written by the ex-files

wins = struct();

% Load global variables
globals;

availableOutcomes = fieldnames(retry);
stats = zeros(numel(availableOutcomes),1);

% now, prompt for monkey ID
if isfield(params,'SubjectID')
    disp(['Current Subject ID = ',params.SubjectID]);
    yorn = 'q'; %initialize
    while ~ismember(lower(yorn(1)),{'y','n'})
        yorn = input('Is that correct (y/n)','s');
        if (strcmp(yorn(1),'n'))
            disp('Please set the correct value for params.SubjectID in globals.m');
            return;
        elseif (strcmp(yorn(1),'y'))
            disp('Continuing with runex ...')
        else
            beep
            fprintf('Reply ''y'' or ''n''\n');
        end
    end;
else
    disp('Please set a value for params.SubjectID in globals.m');
end

% define default outfile name
[~,xmlname,~] = fileparts(xmlFile);
defaultoutfile=[params.SubjectID,'_',datestr(now, 'yyyy.mmm.DD.HH.MM.SS'),'_',xmlname,'.mat'];

if nargin > 2 % outfile is specified at the command line
    if ~ischar(outfile)
        if outfile == 0
            params.writeFile = 0;
            outfile = defaultoutfile;
        elseif outfile == 1
            params.writeFile = 1;
            outfile = defaultoutfile;
        else
            error('Must specify 0 or 1 for outfile flag.');
        end
    else % user specified an outfile name at the command
        params.writeFile = 1;
        % check if file exists
        if exist(outfile,'file')
            load(outfile);
            % do error-checking here to check this wasn't wrong .mat file
            warning('*** Output file exists, so it was loaded and will be appended. ***');
        end
    end
else %nothing specified for the outfile
    outfile = defaultoutfile;
end

if nargin > 3
    params.getEyes = 0;
    params.sendingCodes = 0;
    params.rewarding = 0;
    params.getSpikes = 0;
    params.writeFile = 0;
end

ListenChar(2);
delete(timerfindall)

%daqreset;
FlushEvents;

% load stored calibration file
if params.getEyes==0
    load mouseModeCalibration;
else
    load calibration;
end;
% This makes sure that the calibration values are stored with the
% data (via the sendStruct call)
params.calibPixX = calibration{1}(:,1)';
params.calibPixY = calibration{1}(:,2)';
params.calibVoltX = calibration{2}(:,1)';
params.calibVoltY = calibration{2}(:,2)';

ordering = [];
eyeHistory = [];
currentBlock = 1;
AssertOpenGL;

delete(instrfind);

% Connect to serial device on COM1
%out = udp(params.ipAddress,'RemotePort',8866,'LocalPort',8844);
%fopen(out);
%local_ip = char(java.net.InetAddress.getLocalHost.getHostAddress);
matlabUDP('open',params.controlIP,params.displayIP, 4243)
% Find the values of black and white
white=WhiteIndex(wins.screenNumber);
black=BlackIndex(wins.screenNumber);
gray=(white+black)/2;
if round(gray)==white
	gray=black;
end

trialData = cell(4,1);
if params.getEyes
    if params.writeFile
        [~,outfilename,outfileext] = fileparts(outfile);
        trialData{1} = [xmlFile ', Filename: ' outfilename outfileext];
    else
        trialData{1} = xmlFile;
    end
    load calibration
    samp;
else
    if params.writeFile
        [~,outfilename,outfileext] = fileparts(outfile);
        trialData{1} = [xmlFile ' (MOUSE MODE), Filename: ' outfilename outfileext];
    else
        trialData{1} = [xmlFile ' (MOUSE MODE)'];
    end
    load mouseModeCalibration
end
trialData{2} = '';
trialData{3} = '';
trialData{4} = '(s)timulus, (c)alibrate, e(x)it';
lastLine = 15;
for lx = numel(trialData)+1:lastLine
    trialData{lx} = '';
end;
      
% Open a double buffered fullscreen window and draw a gray background 
% to front and back buffers:
wins.w = Screen('OpenWindow',wins.screenNumber, gray);
wins.voltageDim = [0 0 wins.voltageSize(3:4)-wins.voltageSize(1:2)];
wins.eyeDim = [0 0 wins.eyeSize(3:4)-wins.eyeSize(1:2)];
wins.infoDim = [0 0 wins.infoSize(3:4)-wins.infoSize(1:2)];
wins.histDim = [0 0 wins.histSize(3:4)-wins.histSize(1:2)];
[wins.voltage vRect] = Screen('OpenOffscreenWindow',wins.w,gray,wins.voltageDim);
wins.voltageBG = Screen('OpenOffscreenWindow',wins.w,gray,wins.voltageDim);
wins.eye = Screen('OpenOffscreenWindow',wins.w,gray,wins.eyeDim);
[wins.eyeBG  eRect] = Screen('OpenOffscreenWindow',wins.w,gray,wins.eyeDim);
wins.info = Screen('OpenOffscreenWindow',wins.w,gray,wins.infoDim);
wins.hist = Screen('OpenOffscreenWindow',wins.w,gray,wins.histDim);

wins.pixelsPerMV = [vRect(3) vRect(4)]/20;
wins.pixelsPerPixel = [eRect(3) eRect(4)]./[1024 768];

%draw voltage plot
wins.midV = [vRect(3)/2 vRect(4)/2];
wins.midE = [eRect(3)/2 eRect(4)/2];

setWindowBackground(wins.voltageBG);
setWindowBackground(wins.eyeBG);

Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);

% could resize font
% oldTextSize=Screen('TextSize', windowPtr [,textSize]);

%midScreen = [screenRect(3)/2 screenRect(4)/2];

aio = timer;
aio.ExecutionMode = 'fixedSpacing';
aio.UserData = zeros(2,2);
aio.Period = .006; % grabbing the eye position every 6 ms
if params.getEyes
    aio.TimerFcn = {@plotEyes};
else
    aio.TimerFcn = {@plotMouse};
end
start(aio);

plotter = timer;
plotter.ExecutionMode = 'fixedSpacing';
plotter.UserData = zeros(2,2);
plotter.Period = .016; % plot the eye position every 30 ms
plotter.TimerFcn = {@plotDisplay};
start(plotter);

drawCalibration(9);
Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);

drawTrialData();

if nargin > 1
    eParams.rpts = repeats;
end

msg('bg_color %s',eParams.bgColor);

while 1 
    c = GetChar;
    FlushEvents;
    
    if c == 'c'
        trialData{4} = 'Calibrating...(g)ood position, (b)ack up, (q)uit, (j)uice, no( )reward';
        drawTrialData();

        setWindowBackground(wins.voltageBG);
        Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);

        x = params.calibX;
        y = params.calibY;
        
        [posX posY] = meshgrid(x,y);
        posX = posX';
        posY = posY';
        posX = posX(:);
        posY = posY(:);
        
        pt = 1;
        
        while pt <= length(posX) + 1
            if pt > length(posX)
                matlabUDP('send', 'all_off');
                trialData{4} = '(f)inished calibration, (b)ack up, (q)uit, (j)uice';
                drawTrialData();

                c = GetChar;

                while (c == 'j' || c == 'c')
                    if c == 'j'
                        giveJuice;
                    elseif c == 'c'
                        Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
                        Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);                    
                    end                            
                    c = GetChar;                        
                end
                
                if c == 'q'
                    load calibration;

                    setWindowBackground(wins.voltageBG);
                    drawCalibration(9);
                    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);

                    break;
                end
                
                if c == 'f'
                    break;
                elseif c == 'b'
                    setWindowBackground(wins.voltageBG);

                    pt = max(1,pt - 1);
                    drawCalibration(pt-1);

                    trialData{4} = 'Calibrating...(g)ood position, (b)ack up, (q)uit, (j)uice, no( )reward';
                    drawTrialData();

                    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
                end      
                
            else            
                matlabUDP('send', sprintf('set 1 oval 0 %i %i %i 0 0 255',[posX(pt),posY(pt),wins.calibDotSize]));
                matlabUDP('send', 'all_on');
                                
                c = GetChar;
                while (c == 'j' || c == 'c')
                    if c == 'j'
                        giveJuice;
                    elseif c == 'c'
                        Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
                        Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);                    
                    end                            
                    c = GetChar;                        
                end

                if c == 'q'
                    load calibration;

                    setWindowBackground(wins.voltageBG);
                    drawCalibration(9);
                    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);

                    break;
                end
                
                if c == 'g'
                    d = get(aio,'UserData');

                    calibration{1}(pt,:) = [posX(pt) posY(pt)];
                    calibration{2}(pt,:) = d(end,:);

                    drawCalibration(pt);
                    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
                    
                    pt = pt + 1;
                    
                    giveJuice();
                elseif c == 'b'  
                    setWindowBackground(wins.voltageBG);

                    pt = max(1,pt - 1);
                    drawCalibration(pt-1);

                    Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
                end          
                
                if c == ' ' % flash the dot off for 0.25 seconds
                    matlabUDP('send', 'obj_off 1');
                    pause(.25);
                    matlabUDP('send', 'obj_on 1');
                end
            end
        end
        
        % This makes sure that the calibration values are stored with the
        % data (via the sendStruct call)
        params.calibPixX = calibration{1}(:,1)';
        params.calibPixY = calibration{1}(:,2)';
        params.calibVoltX = calibration{2}(:,1)';
        params.calibVoltY = calibration{2}(:,2)';
        % do the linear regression of Pixels vs. Voltage
        calibration{3} = regress(calibration{1}(:,1), [calibration{2} ones(size(calibration{2},1),1)]);
        calibration{4} = regress(calibration{1}(:,2), [calibration{2} ones(size(calibration{2},1),1)]);
        calibration{5} = regress(calibration{2}(:,1), [calibration{1} ones(size(calibration{1},1),1)]);
        calibration{6} = regress(calibration{2}(:,2), [calibration{1} ones(size(calibration{1},1),1)]);

        save calibration calibration;
        
        trialData{4} = '(s)timulus, (c)alibrate, e(x)it';
        drawTrialData();

        matlabUDP('send', 'all_off');            
    elseif c == 'x'
        break;
    elseif c == '1' || c == '2' || c == '3' || c == '4' || c =='5' || c == '6' || c == '7' 
        params.juiceX = str2double(c);
    elseif c == 'j'
        giveJuice();
    elseif c == 'm'
        % toggle between mouse mode and monkey mode - not fully working
        if params.getEyes
            params.getEyes = 0;
            try
                samp(-4);
            catch
                fprintf('Hangs at line 426'); %for debugging
            end;
            aio.TimerFcn = {@plotMouse};
            if params.writeFile
                [~,outfilename,outfileext] = fileparts(outfile);
                trialData{1} = [xmlFile ' (MOUSE MODE), Filename: ' outfilename outfileext];
            else
                trialData{1} = [xmlFile ' (MOUSE MODE)'];
            end
            drawTrialData();
            load mouseModeCalibration
            setWindowBackground(wins.voltageBG);
            drawCalibration(size(calibration{2},1));
            Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
        else
            params.getEyes = 1;
            samp;
            aio.TimerFcn = {@plotEyes};
            if params.writeFile
                [~,outfilename,outfileext] = fileparts(outfile);
                trialData{1} = [xmlFile ', Filename: ' outfilename outfileext];
            else
                trialData{1} = xmlFile;
            end
            drawTrialData();
            load calibration
            setWindowBackground(wins.voltageBG);
            drawCalibration(size(calibration{2},1));
            Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
        end
    elseif c == 'l'
        Screen('CopyWindow',wins.voltageBG,wins.voltage,wins.voltageDim,wins.voltageDim);
        Screen('CopyWindow',wins.eyeBG,wins.eye,wins.eyeDim,wins.eyeDim);                    
    elseif c == 's'
        % set the background color here
        msg('bg_color %s',eParams.bgColor);
        msgAndWait('ack');

        % get some basic info from the slave about display properties
        msg('framerate');
        params.slaveFrameTime = str2double(waitFor());        
        msg('resolution');
        tstr = waitFor();
        ts = textscan(tstr,'');
        params.slaveWidth = ts{1};
        params.slaveHeight = ts{2};
        params.slavePixelSize = ts{3};
        params.slaveHz = ts{4};

        % now tell the display the screenDistance and pixPerCM
        msg('screen %f %f',[params.screenDistance, params.pixPerCM]);

        % send the eParams and params here, since we don't need 
        % them every trial. use catStruct so duplicate names produce an
        % error. use try/catch so errors exit gracefully.

        % set the trialTic here and initialize thisTrialCodes so that this 
        % first sendStruct call has valid times and stores the codes
        % properly. the flag keeps us from resetting the tic below for just
        % this one trial
        trialTic = tic;
        thisTrialCodes = [];
        resetTicFlag = 0;

        try
            sendStruct(catstruct(eParams,params,'sorted'));        
        catch ME
            Screen('CloseAll');
            throw(ME);
        end
        
        matlabUDP('send', 'stim');
        
        trialMessage = 0;

        if currentBlock > eParams.rpts
            currentBlock = 1;
        end
        
        for j = currentBlock:eParams.rpts
            
            ordering = createOrdering(expt,...
                'blockRandomize',eParams.blockRandomize,...
                'conditionFrequency',eParams.conditionFrequency,...
                'numBlocksPerRandomization',eParams.numBlocksPerRandomization,...
                'exFileControl',eParams.exFileControl); %-ACS 23Oct2012
            if any(ordering<0), ordering = []; break; end; %#ok<NASGU> %break loop for any ordering less than zero (e.g., from EX file control) -ACS 23Oct2012
            trialCounter = 1;
            
            while ~isempty(ordering)
                if any(ordering<0), ordering = []; break; end; %#ok<NASGU>
                eyeHistory = eyeHistory(end,:); %reset eye history -ACS 25Oct2012
                cnd = ordering(1:min(eParams.nStimPerFix,numel(ordering)));
                
                %drawHistogram(cnd);
                % only set the trialTic for trials that aren't immediately
                % following the 's' command
                if resetTicFlag
                    trialTic = tic;
                    thisTrialCodes = [];
                else
                    resetTicFlag = 1;
                end
                
                trialData{2} = sprintf('Block %i/%i',j,eParams.rpts);
                trialData{3} = [sprintf('Trial %i/%i, condition(s) ',trialCounter,length(expt)) sprintf('%i ',cnd)];
                trialData{4} = 'Running stimulus...(q)uit';
                drawTrialData();
                
                % setup the allCodes struct for this trial
                allCodes{end+1} = struct();
                % This value should be as close as possible to the time
                % that code 1 is sent, thus allowing us to recreate global
                % time.
                allCodes{end}.startTime = datestr(now,'HH.MM.SS.FFF');
                                
                % e needs to be a cell array or struct array  *****
                e = expt(cnd);
                fn = fieldnames(eRand);
                for e_indx = 1:length(e)
                    for i = 1:length(fn)                    
                        fieldName = fn{i};                    
                        val = eRand.(fieldName);
                        val = val(randi(length(val)));
                        e{e_indx}.(fieldName) = val;
                    end;
                end;
                e = cell2mat(e);
                
                sendCode(codes.START_TRIAL);   

                % send the trial parameters here, before adding
                % eParams to e (because eParams were sent already) 
                % loop over nstim
                for I =1:numel(cnd);
                    sendCode(cnd(I)+32768); % send condition # in 32769-65535 range
                    sendStruct(e(I));
                end;
                
                % use a try/catch here in case there are duplicate names in
                % e and eParams
                e = num2cell(e);
                for I = 1:numel(e)
                    try
                        e{I} = catstruct(e{I},eParams);
                    catch ME
                        disp('Error combining e and eParams: duplicate field name');
                        Screen('CloseAll');
                        throw(ME);
                    end
                end;
                e = cell2mat(e);
                try
                    histStart();
                    previousTrialCount = trialCounter;
                    trialResult = eval([e(1).exFileName '(e)']);
                    
                    trialResult(trialResult==1) = codes.CORRECT; %for backwards compatibility -ACS 23Oct2012
                    trialResult(trialResult==2) = codes.BROKE_FIX; %for backwards compatibility
                    trialResult(trialResult==3) = codes.IGNORED; %for backwards compatibility
                    trialResultStrings = exDecode(trialResult(:));
                    for ox = 1:numel(availableOutcomes) %new scoring -ACS 23Oct2012
                        if retry.(availableOutcomes{ox}),
                            stats(ox) = stats(ox)+any(ismember(trialResultStrings,availableOutcomes{ox})); %only count these once per fix
                        else
                            stats(ox) = stats(ox)+sum(ismember(trialResultStrings,availableOutcomes{ox})); %sum these per fix
                        end;
                        nOutcomesPerLine = 5;
                        currentLine = 5+floor((ox-1)/nOutcomesPerLine);
                        if mod(ox,nOutcomesPerLine)==1
                            trialData{currentLine}=sprintf('%i %s',stats(ox),availableOutcomes{ox});
                        else 
                            trialData{currentLine} = [trialData{currentLine} sprintf(', %i %s',stats(ox),availableOutcomes{ox})];
                        end;
                    end;                     
                catch err
                    trialData{5} = 'Error in ex file, quit to diagnose.';
                    trialResult = 0;
                    trialMessage = -1;
                    drawTrialData();
                    disp(['************ ERROR: ' err.message ' **********']);
                    for i = 1:length(err.stack)
                        disp(sprintf('%s %s %s %i',repmat(' ',i,1),err.stack(i).file,err.stack(i).name,err.stack(i).line));
                    end
                    beep;
                end
               
                msg('all_off');
                msgAndWait('rem_all');
                
                if trialMessage>-1
                    checked = false(size(cnd));
                    for ox = 1:numel(trialResultStrings)
                        checked(ox) = ~retry.(trialResultStrings{ox});
                    end;
                    if any(checked)
                        trialCounter = trialCounter+sum(checked);
                        for cx = 1:numel(cnd)      %Not sure this is functioning in the intended way yet... -ACS
                            trialCodes{cnd(cx)}{end+1} = thisTrialCodes;
                        end;
                    end;
                    switch eParams.badTrialHandling %added 23Oct2012 -ACS
                        case 'noRetry' %don't retry bad trials
                            ordering(1:numel(cnd)) = []; %just erase the current cnd from ordering and don't look back...
                        case 'immediateRetry'
                            ordering(find(checked)) = []; %tick off the good trials and feed back the ordering as is. This option really only makes sense if nStimPerFix==1.
                        case 'reshuffle'
                            ordering(find(checked)) = []; %tick off the good trials
                            ordering = ordering(randperm(numel(ordering))); %reshuffle the remaining conditions
                        case 'endOfBlock'
                            needsRetried = ordering(find(~checked)); %trials that haven't been checked off
                            ordering = [ordering(numel(cnd)+1:end) needsRetried]; %take the conditions that haven't been attempted yet, and add the conditions needing another try to the end
                        otherwise
                            trialData{5} = 'Unrecognized option for badTrialHandling, quit to diagnose.';
                            trialResult = 0;
                            trialMessage = -1;
                            drawTrialData();
                            beep;
                    end;
                end;
                sendCode(codes.END_TRIAL);
                               
                % Global history of trial codes
                %
                % NOTE: These codes are all referenced relative to the time
                % of the trial start (code '1') because of the first line
                % below. The "global time" for the start of each trial is 
                % stored in allCodes.startTime
                thisTrialCodes(:,2) = thisTrialCodes(:,2) - thisTrialCodes(find(thisTrialCodes(:,1)==1,1,'first'),2);                
                allCodes{end}.cnd = cnd;
                allCodes{end}.trialResult = trialResult;
                allCodes{end}.codes = thisTrialCodes;
                
                % Write allCodes to a file to keep track of data on Ex side
                % Can use the behav struct to keep track of behavior if you
                % like. Contents of behav are user-defined in ex-functions
                if params.writeFile
                    save(['data/',outfile],'allCodes','behav');
                end
                
                if trialMessage == -1
                    break;
                end
            end

            if trialMessage == -1
                currentBlock = j;
                break;
            end       
            currentBlock = currentBlock + 1;
        end
        matlabUDP('send', 'q');        
        trialData{4} = '(s)timulus, (c)alibrate, e(x)it';
        drawTrialData();
    end
end
stop(plotter);
stop(aio);
Screen('CloseAll');
clear aio;
clear plotter;

matlabUDP('close');

ListenChar(0);

% stop sampling analog inputs and free memory
if params.getEyes
    samp(-4);
end

end

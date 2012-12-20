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
clear global behav;
clear global allCodes;

global aio;
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
    error(sprintf('Could not find EX subdirectory. Current directory is: %s',pwd));
else
    addpath('ex');
end

if (exist('xml','dir') ~= 7)
    error(sprintf('Could not find XML subdirectory. Current directory is: %s',pwd));
else
    addpath('xml');
end

if (exist('data','dir') ~= 7)
    error(sprintf('Could not find DATA subdirectory. Current directory is: %s',pwd));
else
    addpath('data');
end

tic
try
    [expt eParams eRand] = readExperiment(['xml/' xmlFile]);
    eParams.xmlFile = xmlFile;
catch
    disp(sprintf('Error reading xml file: %s',xmlFile));
    return;
end

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
stats = zeros(3,1);

% Load global variables
globals;

% now, prompt for monkey ID
if isfield(params,'SubjectID')
    disp(['Current Subject ID = ',params.SubjectID]);
    yorn = input('Is that correct (y/n)','s');
    if (strcmp(yorn,'n'))
        disp('Please set the correct value for params.SubjectID in globals.m');
        return;
    elseif (strcmp(yorn,'y'))
        disp('Continuing with runex ...')
    else
        error('Must reply with y or n');
    end
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
load calibration;
% This makes sure that the calibration values are stored with the
% data (via the sendStruct call)
params.calibPixX = calibration{1}(:,1)';
params.calibPixY = calibration{1}(:,2)';
params.calibVoltX = calibration{2}(:,1)';
params.calibVoltY = calibration{2}(:,2)';

ordering = [];
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
    samp;
else
    if params.writeFile
        [~,outfilename,outfileext] = fileparts(outfile);
        trialData{1} = [xmlFile ' (MOUSE MODE), Filename: ' outfilename outfileext];
    else
        trialData{1} = [xmlFile ' (MOUSE MODE)'];
    end
end
trialData{2} = '';
trialData{3} = '';
trialData{4} = '(s)timulus, (c)alibrate, e(x)it';
trialData{5} = '';
      
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
            samp(-4);
            aio.TimerFcn = {@plotMouse};
            if params.writeFile
                [~,outfilename,outfileext] = fileparts(outfile);
                trialData{1} = [xmlFile ' (MOUSE MODE), Filename: ' outfilename outfileext];
            else
                trialData{1} = [xmlFile ' (MOUSE MODE)'];
            end
            drawTrialData();
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
            ordering = 1:length(expt);
        end
        
        for j = currentBlock:eParams.rpts
            if isempty(ordering)                         
                ordering = 1:length(expt);
            end
            
            while ~isempty(ordering)
                % params.nStimPerFix=3;
                
                % updated to use randperm to grab > 1
                currentTrial = randperm(numel(ordering));
                currentTrial = currentTrial(1:min(params.nStimPerFix,numel(ordering)));
                
                cnd = ordering(currentTrial);
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
                trialData{3} = [sprintf('Trial %i/%i, condition(s) ',length(expt)-length(ordering)+1,length(expt)) sprintf('%i ',cnd)];
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
                    trialResult = eval([e(1).exFileName '(e)']);
                    %New way of scoring (any bad or abort during the
                    %sequence only counts once.
                    stats(1) = stats(1)+sum(trialResult==1);
                    stats(2) = stats(2)+any(trialResult==2);
                    stats(3) = stats(3)+any(trialResult==3);
                    trialData{5} = sprintf('%i good, %i bad, %i abort',stats);
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
                
                % change to deal with multiple conditions                
                if any(trialResult == 1)
%                     sendCode(codes.REWARD);
%                     giveJuice();
                    ordering(currentTrial(trialResult(1:numel(e))==1)) = [];
                    sendCode(codes.END_TRIAL);
                    for cx = 1:numel(cnd)      %I don't think this is functioning in the intended way yet... -ACS              
                        trialCodes{cnd(cx)}{end+1} = thisTrialCodes;
                    end;
                    histCompile(cnd); %<---- known problem here... ACS 17Sep2012
                else
                    sendCode(codes.END_TRIAL);
                end
                
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
function result = ex_fixAndStimStaircase(e)
% ex file: ex_fixAndStimStaircase - Adam C. Snyder adam@adamcsnyder.com
%
% (needs documented. -ACS)
%

    global params codes behav allCodes trialData; %#ok<NUSED>  %added trial data here so it can be updated with stimulation information
    
    numRuns = 20;
    
    %SAFETY PRECAUTIONS:
    if e.vOut>15||e.trainDuration>0.3||e.pulseDuration>0.0005
        error('EXCEPTIONALLY INTENSE MICROSTIM SETTINGS REQUESTED. CHECK SETTINGS.');
    end;
    
    % check if the field exists, if not set it to defaults
    if ~isfield(behav,'s88xIsInitialized')
        s88x_prepForStim;
        behav.s88xIsInitialized=true;
    end
    if ~isfield(behav,'stimHistory')
        behav.stimHistory.vOut =  e.vOut;
        behav.stimHistory.pulseDuration = e.pulseDuration;
        behav.stimHistory.trainDuration = e.trainDuration;
        behav.stimHistory.cnd = behav.ordering;
    else %check here if the staircasing is done
        cndHistory = [behav.stimHistory.cnd];
        trialData{8} = ['Condition history:' sprintf('% d',flipud(cndHistory(:)))]; %Display condition history
        isSloped = [true diff(cndHistory)~=0];
        cndHistory = cndHistory(isSloped); %cut out any 'flat-tops'
        %find the peaks and troughs:
        peaks = [0 diff(cndHistory,2) 0]==-2;
        troughs = [0 diff(cndHistory,2) 0]==2;
        if sum(peaks)+sum(troughs)-2<numRuns, 
            %Do nothing --not enough runs yet
        else
            %figure the threshold condition, assuming fixed and linearly-
            %spaced steps --more complicated methods can be done by
            %accessing the 'behav' variable for this function.
            peakInds = find(peaks); peakInds(1) = []; %throw out first peak
            troughInds = find(troughs); troughInds(1) = []; %throw out first trough
            threshold = mean(cndHistory(union(peakInds,troughInds)));
            msgStr = sprintf('Condition number estimate for threshold: %.2f',threshold);
            fprintf('\n%s\n',msgStr);
            trialData{9} = 'STAIRCASE COMPLETED.';
            trialData{10} = msgStr;
            behav.ordering = -1; %stop signal for runex
            result = codes.CORRECT;
            return
        end; 
    end
    
    pause(e.preTrialPause./1000);
    
    expt = evalin('caller','expt'); %get the variable 'expt' from runex, to make sure that we don't try to pass back an invalid condition for the next trial. Do it now so we don't slow things down later when timing counts. 24Oct2012 -ACS
       
    result = codes.IGNORED; %initialize the result as ignored. It will be updated as needed. 22Oct2012 -ACS
    
    % obj 1 is fix spot, obj 2 is stimulus, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msg('diode 1');    
    
    msgAndWait('ack');
    
    histStart();
    
    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);

    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixWinRad)
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        %result starts as ignored by default. 22Oct2012 -ACS      
        return;
    end
    sendCode(codes.FIXATE);
    
    result = codes.BROKE_FIX; %indicate that the subject at least got this far... 24Oct2012 -ACS
    
    if ~waitForMS(e.preStimFix,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        return;
    end
    
    histAlign();

    % microstim each trial
    %Set trial data (on control screen. 22Oct2012 -ACS):
    try
        trialData{9} = sprintf('Stimulating: voltage = %.2fV, pulse duration = %.2es...',e.vOut,e.pulseDuration);
        trialData{10} = sprintf('...train duration = %.3fs',e.trainDuration);
    catch %#ok<CTCH>
        %do nothing: don't punt if there's only some problem with the
        %trialData stuff (e.g., index out of range due to an old
        %version of runex.
    end;
    %Set stimulation settings (added 22Oct2012 -ACS):
    s88x_setSettings(1,'vout',e.vOut,'pulseduration',e.pulseDuration,'trainduration',e.trainDuration);
    s88x_setSettings(2,'vout',e.vOut,'pulseduration',e.pulseDuration,'pulsedelay',e.pulseDuration,'trainduration',e.trainDuration);
    sendCode(codes.USTIM_ON);
    microStim(1); %trigger stimulation using TTL.
    sendCode(codes.USTIM_OFF);
    % generate a tone with every microstim
    if e.toneWithStim %made this a conditional, since now sounds play in the rig by default. 22Oct2012 -ACS
        fs=44100;
        t=0:1/fs:.12;
        y=sin(440*2*pi*t);
        y=y.*hann(length(y))';
        sound(y,fs);
    end;
    result = codes.CORRECT; %set result to correct for successful stimulation regardless of trial outcome so that the condition becomes 'checked off' in runex
    
    %record stimulation history:
    currentTrialNum = numel(behav.stimHistory)+1;
    behav.stimHistory(currentTrialNum).vOut =  e.vOut;
    behav.stimHistory(currentTrialNum).pulseDuration = e.pulseDuration;
    behav.stimHistory(currentTrialNum).trainDuration = e.trainDuration;
    behav.stimHistory(currentTrialNum).cnd = behav.ordering;
    
    drawTrialData();
    
    %I think this next 'waitFor' is the key piece to know if the
    %stimulation evoke a saccade or not (-ACS):
    deepPink = [255 20 147];
    if ~waitForMS(e.postStimCheckTime,e.fixX,e.fixY,params.fixWinRad,deepPink)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        behav.ordering = behav.ordering-1; %evoked, so step down.
        if behav.ordering < 1, behav.ordering = 1; end;
        return;
    else
        behav.ordering = behav.ordering+1; %didn't evoke, so step up.
        if behav.ordering > numel(expt), behav.ordering = numel(expt); end;
    end        
    %Note, since I imported the 'expt' variable, this could potentially be
    %made smarter, but a simple step ought to work for now. 24Oct2012 -ACS

    if ~waitForMS(e.extraPostStimFixTime,e.fixX,e.fixY,params.fixWinRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
    end      
    
    % choose a target location randomly around a circle
    theta = deg2rad(-1 * e.saccadeDir);
    newX = round(e.saccadeLength * cos(theta));
    newY = round(e.saccadeLength * sin(theta));

    % turn off stimulus and turn on target
    msgAndWait('set 1 oval 0 %i %i %i %i %i %i',[newX newY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    sendCode(codes.FIX_MOVE);
    
    histStop();

    % detect saccade here - we're just going to count the time leaving the
    % fixation window as the saccade but it would be better to actually
    % analyze the eye movements.
    %
    % One weird thing here is it doesn't move the target window (on the
    % controls screen) until you leave the fixation window. Doesn't matter
    % to monkey, but a little harder for the human controlling the
    % computer. Maybe we can fix this when we implement a saccade-detection
    % function.
    %
    if (e.saccadeInitiate > 0) % in case you don't want to have a saccade
        if waitForMS(e.saccadeInitiate,e.fixX,e.fixY,params.fixWinRad)
            % didn't leave fixation window
            sendCode(codes.NO_CHOICE);
            msgAndWait('all_off');
            sendCode(codes.FIX_OFF);
            return;
        end        
        sendCode(codes.SACCADE);
    end
    
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targWinRad)
        % didn't reach target
        sendCode(codes.NO_CHOICE);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        return;
    end
    
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targWinRad)
        % didn't stay on target long enough
        sendCode(codes.BROKE_TARG)
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        return;
    end
    
    sendCode(codes.FIXATE);
    sendCode(codes.CORRECT);
    sendCode(codes.FIX_OFF);
    sendCode(codes.REWARD);
    giveJuice();
    msgAndWait('all_off');
    
    result = 1;
    
        
        

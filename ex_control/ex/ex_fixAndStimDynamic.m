function result = ex_fixAndStimStaircase(e)
% ex file: ex_fixAndStim
%
% Fixation task with microstimulation on every other trial
%
% XML REQUIREMENTS
% runline: a list of strings which correspond to other parameter names.
%   This list of names is used to construct the custom set command to the
%   slave
% NAMES: all the parameters listed in runline
% type: the type of stimulus (e.g. fef_dots,oval,etc)
% timeToFix: the number of ms to wait for initial fixation
% saccadeInitiate: maximum time allowed to leave fixation window
% saccadeTime: maximum time allowed to reach target
% preStimFix: time after fixation pt onset before stim onset
% stayOnTarget: time after reaching target that subject must stay in window
% saccadeLength: distance of target from fixation
% noFixTimeout: time after breaking fixation before next trial can begin
% fixX, fixY, fixRad: fixation spot location in X and Y as well as RGB
%   color
% saccadeDir: angle of target to fixation, usually set with a random
%
% Last modified:
% 2012/03/21 by Matt Smith
%
%

    global params codes behav allCodes trialData; %#ok<NUSED>  %added trial data here so it can be updated with stimulation information
    
    %Check here if staircase criteria are met:
    %(NEEDS DONE)
    
    % check if the field exists, if not set it to defaults
    if ~isfield(behav,'s88xIsInitialized')
        s88x_initialize;
        behav.s88xIsInitialized=true;
    end
    if ~isfield(behav,'stimHistory')
        behav.stimHistory.vOut =  e.vOut;
        behav.stimHistory.pulseDuration = e.pulseDuration;
        behav.stimHistory.trainDuration = e.trainDuration;
    end
       
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
    result = CORRECT; %set result to correct for successful stimulation regardless of trial outcome so that the condition becomes 'checked off' in runex
    
    %record stimulation history:
    behav.stimHistory(end+1).vOut =  e.vOut;
    behav.stimHistory(end+1).pulseDuration = e.pulseDuration;
    behav.stimHistory(end+1).trainDuration = e.trainDuration;
    
    drawTrialData();
    
    %I think this next 'waitFor' is the key piece to know if the
    %stimulation evoke a saccade or not (-ACS):
    if ~waitForMS(e.fixDuration,e.fixX,e.fixY,params.fixWinRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        return;
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

    % only set this flag back to 1 if you complete a correct unstimulated
    % trial
    if (ustimflag == 0 && behav.microStimNextTrial == 0)
        behav.microStimNextTrial = 1;
    end
    
    sendCode(codes.FIXATE);
    sendCode(codes.CORRECT);
    sendCode(codes.FIX_OFF);
    sendCode(codes.REWARD);
    giveJuice();
    result = 1;
    
        
        

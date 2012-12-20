function result = ex_fixAndStim(e)
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
% 2012/10/22 by Matt Smith - added e=e(1);
% 2012/11/15 by Matt Smith - modified from old fixAndStim to now turn off
% fix pt before stim, reward at stim, and also used XML parameter to have
% random time to stim. This is the new default fixAndStim
%

    global params codes behav allCodes;
    
    e = e(1); %in case more than one 'trial' is passed at a time...

    % check if the field exists, if not set it to zero
    if ~isfield(behav,'microStimNextTrial')
        behav.microStimNextTrial = 0;
    end
    
    % obj 1 is fix spot, obj 2 is stimulus, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msg(['diode 1']);    
    
    msgAndWait('ack');
    
    histStart();
    
    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);

    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixWinRad)
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = codes.IGNORED;        
        return;
    end
    sendCode(codes.FIXATE);

    if ~waitForMS(e.preStimFix,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = codes.BROKE_FIX;
        return;
    end

    msgAndWait('obj_off 1'); % turn off fixation point before microstim
    sendCode(codes.FIX_OFF);
    if ~waitForMS(e.waitForStim,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation briefly before microstim starts
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        waitForMS(e.noFixTimeout);
        result = codes.BROKE_FIX;
        return;
    end

    histAlign();

    % On even trials, microstim
    ustimflag = 0;
    deepPink = [255 20 147];
    fixColor = [255 255 0];
    if (e.microStimDur > 0)
        if (behav.microStimNextTrial == 1)
            ustimflag = 1;
            fixColor = deepPink;
            behav.microStimNextTrial = 0;
            sendCode(codes.USTIM_ON);
            microStim(e.microStimDur);
            sendCode(codes.USTIM_OFF);
            if (e.toneWithStim)
                % generate a tone if desired
                fs=44100;
                t=0:1/fs:.12;
                y=sin(440*2*pi*t);
                y=y.*hann(length(y))';
                sound(y,fs);
            end
%        else
%            behav.microStimNextTrial = 0;
        end
    end

    % reward him after microstim whether he maintains fixation or not
    sendCode(codes.REWARD);
    sendCode(codes.CORRECT);
    result = codes.CORRECT;
    giveJuice();
    
    if ustimflag
        % look for saccade after microstim only
        if ~waitForMS(e.sacCheckTime,e.fixX,e.fixY,params.fixWinRad,fixColor)
            result = codes.SACCADE;
            sendCode(codes.SACCADE);
        end
    end
    
    histStop();

    % only set this flag back to 1 if you complete a correct unstimulated
    % trial
    if (ustimflag == 0 & behav.microStimNextTrial == 0)
        behav.microStimNextTrial = 1;
    end
    
    % a little extra time to make sure trials aren't too close together
    pause(e.postTrialWait/1000);
    

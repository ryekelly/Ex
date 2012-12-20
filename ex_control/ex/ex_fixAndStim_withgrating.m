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
%
%

    global params codes behav allCodes;
    
    e = e(1); %in case more than one 'trial' is passed at a time...

    % check if the field exists, if not set it to zero
    if ~isfield(behav,'microStimNextTrial')
        behav.microStimNextTrial = 0;
    end
    
    % obj 1 is fix spot, obj 2 is stimulus, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msg('set 2 grating %i %i %f %f %f %i %i %i %f',[e.stimLength e.orientation e.phase e.spatial e.temporal e.centerx e.centery e.radius e.contrast]);
    msg(['diode 2']);    
    
    msgAndWait('ack');
    
    histStart();
    
    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);

    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixWinRad)
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 3;        
        return;
    end
    sendCode(codes.FIXATE);
    
    if ~waitForMS(e.preStimFix,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end
    
    histAlign();

    if (e.microStimDur > 0)
        if (e.microstim == 1)
            sendCode(codes.USTIM_ON);
            microStim(e.microStimDur);
            sendCode(codes.USTIM_OFF);
            % generate a tone with every microstim
%            fs=44100;
%            t=0:1/fs:.12;
%            y=sin(440*2*pi*t);
%            y=y.*hann(length(y))';
%            sound(y,fs);
        end
    end
    
    msgAndWait('obj_on 2');
    sendCode(codes.STIM_ON);
    
    if ~waitForSlave(e.fixX,e.fixY,params.fixWinRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.STIM_OFF);
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end
    
    % choose a target location randomly around a circle
    theta = deg2rad(-1 * e.saccadeDir);
    newX = round(e.saccadeLength * cos(theta));
    newY = round(e.saccadeLength * sin(theta));

    % turn off stimulus and turn on target
    msgAndWait('queue_begin');
    msg('obj_off 2');
    msgAndWait('set 1 oval 0 %i %i %i %i %i %i',[newX newY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msgAndWait('queue_end');
    sendCode(codes.STIM_OFF);
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
            result = 2;
            return;
        end
        
        sendCode(codes.SACCADE);
    end
    
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targWinRad)
        % didn't reach target
        sendCode(codes.NO_CHOICE);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end
    
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targWinRad)
        % didn't stay on target long enough
        sendCode(codes.BROKE_TARG)
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end

    sendCode(codes.FIXATE);
    sendCode(codes.CORRECT);
    sendCode(codes.FIX_OFF);
    sendCode(codes.REWARD);
    giveJuice();
    result = 1;

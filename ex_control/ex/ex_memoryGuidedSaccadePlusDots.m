function result = ex_memoryGuidedSaccadePlusDots(e)
% ex file: ex_memoryGuidedSaccadePlusDots
%
% File for FEF experiment where we show dots for a revcor during the
% memory-guided saccade task
%
% XML REQUIREMENTS
% angle: angle of the target dot from the fixation point 0-360
% distance: the distance of the target in pixels from the fixation point
% size: the size of the target in pixels
% targetColor: a 3 element [R G B] vector for the target color
% timeToFix: time in ms for initial fixation
% noFixTimeout: timeout punishment for aborted trial (ms)
% targetOnsetDelay: time after fixation before target appears
% fixDuration: length of initial fixation required
% targetDuration: duration that target is on screen. set to 0 for fix only
%   task
% postTargetBlank: blank period after target appears but before dot movie
% stayOnTarget: length of target fixation required
% saccadeInitiate: maximum time allowed to leave fixation window
% saccadeTime: maximum time allowed to reach target
%
% seed: the fefdots seed to use
% ndots: the number of dots
% dotsize: the size of the dots
% dwell: the number of refreshes for each dot frame
% centerx: the x offset for the dot field
% centery: the y offset for the dot field
% xradius: the x width of the dot field
% yradius: the y height of the dot field
% colorFEF: 3 element vector for the FEF dots colors [R G B]
%
% Last modified:
% 2012/01/17 by Matt Smith
%
%

    global params codes behav;
    
    objID = 3;
    
    result = 0;
    
    % take radius and angle and figure out x/y for saccade direction
    theta = deg2rad(-1 * e.angle);
    newX = round(e.distance*cos(theta));
    newY = round(e.distance*sin(theta));
        
    waitRemainder = e.fixDuration - (e.targetOnsetDelay + e.targetDuration + e.postTargetBlank);
    numFrames = ceil(waitRemainder*params.slaveHz/1000);

    % obj 1 is fix pt, obj 2 is target, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msg('set 2 oval 0 %i %i %i %i %i %i',[newX newY e.size e.targetColor(1) e.targetColor(2) e.targetColor(3)]);
    msg('set 3 fef_dots %i %i %i %i %i %i %i %i %i %i %i %i',[numFrames e.seed e.ndots e.dotsize e.dwell e.centerx e.centery e.xradius e.yradius e.colorFEF]);
    msg(['diode ' num2str(objID)]);    
    
    %drawFixationWindows(fixX,fixY,params.fixWinRad);

    msgAndWait('ack');
    histStart();

    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);
    
    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixWinRad);
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end

    if ~waitForMS(e.targetOnsetDelay,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end
    
    % set targetDuration to 0 if you want fixation only task
    % need to also set distance to 0 and angle to a single value
    if (e.targetDuration > 0)
        % target turns on
        msgAndWait('obj_on 2');
        sendCode(codes.TARG_ON);
        
        if ~waitForMS(e.targetDuration,e.fixX,e.fixY,params.fixWinRad)
            % didn't hold fixation during target display
            sendCode(codes.BROKE_FIX);
            msgAndWait('all_off');
            sendCode(codes.TARG_OFF);
            sendCode(codes.FIX_OFF);
            waitForMS(e.noFixTimeout);
            result = 2;
            return;
        end
    else
        %%%%%%%%
        % this is extra code to show stimulus without any saccade if you
        % want a fixation only task
        %%%%%%%
        
        % turn on dot movie
        msgAndWait('obj_on 3');
        sendCode(codes.STIM_ON);
        
        if ~waitForMS(e.fixDuration,e.fixX,e.fixY,params.fixWinRad)
            % didn't hold fixation during stimulus
            sendCode(codes.BROKE_FIX);
            msgAndWait('all_off');
            sendCode(codes.FIX_OFF);
            waitForMS(e.noFixTimeout);
            result = 2;
            return;
        end
        
        % turn off dots and fix point
        msgAndWait('queue_begin');
        msg('obj_off 3');
        msg('obj_off 1');
        msgAndWait('queue_end');
        sendCode(codes.STIM_OFF);
        sendCode(codes.FIX_OFF);
        
        sendCode(codes.CORRECT);
        result = 1;
        
        histStop();
        return;
    end

    % turn saccade target off
    msgAndWait('obj_off 2'); % if targetDuration is zero, this is unecessary
    sendCode(codes.TARG_OFF);
    
    if ~waitForMS(e.postTargetBlank,e.fixX,e.fixY,params.fixWinRad)
        % didn't hold fixation during period after target offset
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 2;
        return;
    end
    
    % turn on dot movie
    msgAndWait('obj_on 3');
    sendCode(codes.STIM_ON);

    if ~waitForMS(waitRemainder,e.fixX,e.fixY,params.fixWinRad)
        % didn't hold fixation during period after target offset
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 2;
        return;
    end
    
    % turn off dots and fix point
    msgAndWait('queue_begin');
    msg('obj_off 3');
    msg('obj_off 1');
    msgAndWait('queue_end');
    sendCode(codes.STIM_OFF);
    sendCode(codes.FIX_OFF);
    
    %drawFixationWindows(newX,newY,params.targWinRad);

    % detect saccade here - we're just going to count the time leaving the
    % fixation window as the saccade but it would be better to actually
    % analyze the eye movements.
    if waitForMS(e.saccadeInitiate,e.fixX,e.fixY,params.fixWinRad)
        % didn't leave fixation window
        sendCode(codes.NO_CHOICE);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end

    sendCode(codes.SACCADE);
    
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
        sendCode(codes.BROKE_TARG);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end

    sendCode(codes.FIXATE);
    sendCode(codes.CORRECT);
    result = 1;
    
    histStop();    
   
 
    

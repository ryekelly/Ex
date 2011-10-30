function result = ex_SaccadeTask(e)
% ex file: ex_saccadeTask
%
% General file for memory and visually guided saccade tasks 
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
% targetDuration: duration that target is on screen
% stayOnTarget: length of target fixation required
% saccadeTime: maximum time allowed to reach target

    global params codes behav;
    
    objID = 2;
    
    result = 0;
    
    % take radius and angle and figure out x/y
    % also pass in color too
    theta = deg2rad(-1 * e.angle);
    newX = round(e.distance*cos(theta));
    newY = round(e.distance*sin(theta));
   
    % obj 1 is fix pt, obj 2 is target, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad e.fixColor(1) e.fixColor(2) e.fixColor(3)]);
    msg('set 2 oval 0 %i %i %i %i %i %i',[newX newY e.size e.targetColor(1) e.targetColor(2) e.targetColor(3)]);
    msg(['diode ' num2str(objID)]);    
    
    msgAndWait('ack');
    histStart();

    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);
    
    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixRad);
        % failed to achieve fixation
        sendCode(codes.IGNORED)
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end

    if ~waitForMS(e.targetOnsetDelay,e.fixX,e.fixY,params.fixRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end
    
    % Decision point - is this VisGuided, Delay-VisGuided, or Mem-Guided
    if (e.targetOnsetDelay == e.fixDuration)
        % Visually Guided Saccade
        % sendCode(2001?); % send code specific to this stimulus type
        histAlign();
        % turn fix pt off and target on simultaneously
        msg('queue_begin');
        msg('obj_on 2');
        msg('obj_off 1'); 
        msgAndWait('queue_end');
        sendCode(codes.FIX_OFF);
        sendCode(codes.STIM_ON);
    elseif ((e.targetOnsetDelay + e.targetDuration) < e.fixDuration)
        % Memory Guided Saccade
        % sendCode(2001?); % send code specific to this stimulus type
        msgAndWait('obj_on 2');
        sendCode(codes.STIM_ON);
        histAlign();

        if ~waitForMS(e.targetDuration,e.fixX,e.fixY,params.fixRad)
            % didn't hold fixation during target display
            sendCode(codes.BROKE_FIX);
            msgAndWait('all_off');
            sendCode(codes.STIM_OFF);
            sendCode(codes.FIX_OFF);
            waitForMS(e.noFixTimeout);
            result = 2;
            return;
        end

        msgAndWait('obj_off 2');
        sendCode(codes.STIM_OFF);
        
        waitRemainder = e.fixDuration - (e.targetOnsetDelay + e.targetDuration);
        if ~waitForMS(waitRemainder,e.fixX,e.fixY,params.fixRad)
            % didn't hold fixation during period after target offset
            sendCode(codes.BROKE_FIX);
            msgAndWait('all_off');
            sendCode(codes.FIX_OFF);
            waitForMS(e.noFixTimeout);
            result = 2;
            return;
        end
        
        sendCode(codes.FIX_OFF);
        msgAndWait('obj_off 1'); 
    elseif (((e.targetOnsetDelay + e.targetDuration) > e.fixDuration) && (e.targetOnsetDelay < e.fixDuration))
        % Delayed Visually Guided Saccade
        % sendCode(2001?); % send code specific to this stimulus type
        msgAndWait('obj_on 2');
        sendCode(codes.STIM_ON);
        histAlign();

        waitRemainder = e.fixDuration - e.targetOnsetDelay;
        if ~waitForMS(waitRemainder,e.fixX,e.fixY,params.fixRad)
            % didn't hold fixation during target display
            sendCode(codes.BROKE_FIX);
            msgAndWait('all_off');
            sendCode(codes.STIM_OFF);
            sendCode(codes.FIX_OFF);
            waitForMS(e.noFixTimeout);
            result = 2;
            return;
        end
        
        sendCode(codes.FIX_OFF);
        msgAndWait('obj_off 1'); 
    else
        warning('Condition not valid');
        %%% fill this in?
        return;
    end
    
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targetRad)
        % didn't reach target
        sendCode(codes.NO_CHOICE)
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end
    
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targetRad)
        % didn't stay on target long enough
        sendCode(codes.BROKE_TARG);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end

    result = 1;
    sendCode(codes.FIXATE);
    % this should be correct code
    
    sendCode(codes.STIM_OFF);
    
    histStop();
    % send code all off?
    
    

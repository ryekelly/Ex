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

    global params codes;
    
    fixX = 0;
    fixY = 0;
    fixPtRad = 5;   
       
    objID = 2;
    
    result = 0;
    
    % take radius and angle and figure out x/y
    % also pass in color too
    
    theta = deg2rad(-1 * e.angle);
    newX = round(e.distance*cos(theta));
    newY = round(e.distance*sin(theta));
   
    msg('set 1 oval 0 %i %i %i 0 0 255',[fixX fixY fixPtRad]);
    msg('set 2 oval 0 %i %i %i %i %i %i',[newX newY e.size e.targetColor(1) e.targetColor(2) e.targetColor(3)]);
    msg(['diode ' num2str(objID)]);    
    
    msgAndWait('ack');
    histStart();
    sendCode(codes.FIX_ON);
    msgAndWait('obj_on 1');
    
    if ~waitForFixation(e.timeToFix,fixX,fixY,params.fixRad);
        % failed to acheive fixation
        sendCode(codes.FIX_OFF);
        msg('all_off');
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end

    % error code here should be broke fixation
    if ~waitForMS(e.targetOnsetDelay,fixX,fixY,params.fixRad)
        sendCode(codes.FIX_OFF);
        result = 3;
        %sendCode(codes.BROKEFIX); % ???
        return;
    end
    
    % Decision point - is this VisGuided, Delay-VisGuided, or Mem-Guided
    if (e.targetOnsetDelay == e.fixDuration)
        % Visually Guided Saccade
        sendCode(codes.STIM_ON);
        msgAndWait('obj_on 2');
        
        histAlign();

        sendCode(codes.FIX_OFF);
        msgAndWait('obj_off 1'); 
        % NOTE: should happen on same frame as stim on? how would i do that?
    elseif ((e.targetOnsetDelay + e.targetDuration) < e.fixDuration)
        % Memory Guided Saccade
        sendCode(codes.STIM_ON);
        msgAndWait('obj_on 2');

        histAlign();

        if ~waitForMS(e.targetDuration,fixX,fixY,params.fixRad)
            sendCode(codes.FIX_OFF);
            % should be sending different code - error
            result = 2;
            return;
        end

        sendCode(codes.STIM_OFF);
        msgAndWait('obj_off 2');
        
        waitRemainder = e.fixDuration - (e.targetOnsetDelay + e.targetDuration);
        if ~waitForMS(waitRemainder,fixX,fixY,params.fixRad)
            sendCode(codes.FIX_OFF);
            % should be sending different code - error
            result = 2;
            return;
        end
        
        sendCode(codes.FIX_OFF);
        msgAndWait('obj_off 1'); 
    elseif (((e.targetOnsetDelay + e.targetDuration) > e.fixDuration) && (e.targetOnsetDelay < e.fixDuration))
        % Delayed Visually Guided Saccade
        sendCode(codes.STIM_ON);
        msgAndWait('obj_on 2');
        
        histAlign();

        waitRemainder = e.fixDuration - e.targetOnsetDelay;
        if ~waitForMS(waitRemainder,fixX,fixY,params.fixRad)
            sendCode(codes.FIX_OFF);
            % should be sending different code - error
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
    
    % reach target window
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targetRad)
        sendCode(codes.FIX_OFF);
        % should be sending different code - error not reaching target
        result = 2;
        return;
    end
    
    % stay in target window
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targetRad)
        sendCode(codes.FIX_OFF);
        % should send left target early code
        result = 2;
        return;
    end

    result = 1;
    sendCode(codes.FIX_CAUGHT);
    % this should be correct code
    
    sendCode(codes.STIM_OFF);
    
    histStop();
    % send code all off?
    
    

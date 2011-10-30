function result = ex_memoryGuidedSaccadePlusDots(e)
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

    global params codes behav;
    
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
        
    waitRemainder = e.fixDuration - (e.targetOnsetDelay + e.targetDuration);
    numFrames = ceil(waitRemainder*1000/params.slaveHz);
    
    msg('set 1 oval 0 %i %i %i 0 0 255',[fixX fixY fixPtRad]);
    msg('set 2 oval 0 %i %i %i %i %i %i',[newX newY e.size e.targetColor(1) e.targetColor(2) e.targetColor(3)]);
    msg('set 3 fef_dots %i %i %i %i %i %i %i %i %i %i %i %i',[numFrames e.seed e.ndots e.dotsize e.dwell e.centerx e.centery e.xradius e.yradius e.colorFEF]);
    
    msg(['diode ' num2str(objID)]);    
    
    drawFixationWindows(fixX,fixY,params.fixRad);

    msgAndWait('ack');
    
    sendCode(codes.FIX_ON);
    % fixation turns on
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
    
    sendCode(codes.STIM_ON);
    % target turns on
    msgAndWait('obj_on 2');

    if ~waitForMS(e.targetDuration,fixX,fixY,params.fixRad)
        sendCode(codes.FIX_OFF);
        % should be sending different code - error
        result = 2;
        return;
    end

    sendCode(codes.STIM_OFF);
    % target turns off
    msgAndWait('obj_off 2');

    msg('obj_on 3');
    
    if ~waitForMS(waitRemainder,fixX,fixY,params.fixRad)
        sendCode(codes.FIX_OFF);
        % should be sending different code - error
        result = 2;
        return;
    end
    
    msg('obj_off 3');
        
    sendCode(codes.FIX_OFF);
    msgAndWait('obj_off 1'); 
    drawFixationWindows(newX,newY,params.targetRad);

    % monkey needs to make the saccade now
    
    % reach target window
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targetRad)
        sendCode(codes.FIX_OFF);
        % should be sending different code - error not reaching target
        result = 2;
        return;
    end

    % monkey needs to stay in window
    
    % stay in target window
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targetRad)
        sendCode(codes.FIX_OFF);
        % should send left target early code
        result = 2;
        return;
    end

    result = 1;
    sendCode(codes.FIXATE);
    % this should be correct code
    
    sendCode(codes.STIM_OFF);
    % send code all off?
    
    

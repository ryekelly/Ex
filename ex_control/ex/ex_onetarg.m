function result = ex_onetarg(e)
% ex file: ex_activeFixation
%
% Active fixation tasks for any stimuli
%
% XML REQUIREMENTS
% runline: a list of strings which correspond to other parameter names.
%   This list of names is used to construct the custom set command to the
%   slave
% NAMES: all the parameters listed in runline
% type: the type of stimulus (e.g. fef_dots,oval,etc)
% timeToFix: the number of ms to wait for initial fixation
% saccadeTime: the maximum number of ms to wait for a saccade after
%   presentation of the stimulus

    global params codes behav;
    
    % move this to XML along with fix pt color
    %fixX = 0;
    %fixY = 0;
    fixX=round(e.fixXjump*e.fixXpos);
    fixY=round(e.fixYjump*e.fixYpos);
    fixPtRad = 5;   
     
    % this automatically generates the stimulus command, as long as there
    % is a runline variable in the e struct.
    runLine = e.runline;
    runString = '';
    while ~isempty(runLine)
        [tok runLine] = strtok(runLine);
        
        while ~isempty(tok)
            [thisTok tok] = strtok(tok,',');
            
            runString = [runString num2str(eval(['e.' thisTok]))];
        end
        
        runString = [runString ' '];
    end
    runString = [e.type ' ' runString(1:end-1)];

    objID = 2;
    
    % obj 1 is fix spot, obj 2 is stimulus, diode attached to obj 2
    msg('set 1 oval 0 %i %i %i 255 0 0',[fixX fixY fixPtRad]);
    msg(['set ' num2str(objID) ' ' runString]);
    msg(['diode ' num2str(objID)]);    
    
    msgAndWait('ack');
    
    histStart();
    
    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);

    if ~waitForFixation(e.timeToFix,fixX,fixY,params.fixRad)
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        sendCode(codes.FIX_OFF);
        msg('all_off');
        waitForMS(e.timeoutMS);
        result = 3;        
        return;

    end
    
    if ~waitForMS(e.preStimFix,fixX,fixY,params.fixRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        sendCode(codes.FIX_OFF);
        result = 3;
        return;
    end
    
    msgAndWait('obj_on 2');
    sendCode(codes.STIM_ON);

    histAlign();
    
    if ~waitForSlave(fixX,fixY,params.fixRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        sendCode(codes.STIM_OFF);
        sendCode(codes.FIX_OFF);
        result = 3;
        return;
    end        
        
    % choose a target location randomly around a circle
    %theta = e.saccadeDir;
    %newX = round(3*params.fixRad*cos(theta))
    %newY = round(3*params.fixRad*sin(theta));
    %newX = round(e.saccadeLength * cos(e.saccadeDir));
    %newY = round(e.saccadeLength * sin(e.saccadeDir));
    newX = round(e.centerx);
    newY = round(e.centery);

    histStop();

    % turn off stimulus and turn on target
    msgAndWait('queue_begin');
    msg('obj_off 2');
    msg('set 1 oval 0 %i %i %i 255 0 0',[newX newY fixPtRad]);
    msgAndWait('queue_end');
    sendCode(codes.STIM_OFF);
    sendCode(codes.FIX_MOVE);
    
    if ~waitForFixation(e.saccadeTime,newX,newY,params.targetRad)
        % didn't reach target
        sendCode(codes.NO_CHOICE);
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end
    if ~waitForMS(e.stayOnTarget,newX,newY,params.targetRad)
        % didn't stay on target long enough
        sendCode(codes.BROKE_TARG)
        sendCode(codes.FIX_OFF);
        result = 2;
        return;
    end

    sendCode(codes.FIXATE);
    sendCode(codes.CORRECT);
    sendCode(codes.FIX_OFF);
    result = 1;

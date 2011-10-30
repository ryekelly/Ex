function result = ex_activeFixation(e)
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

    global params codes;
    
    fixX = 0;
    fixY = 0;
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
    
    msg('set 1 oval 0 %i %i %i 0 0 255',[fixX fixY fixPtRad]);
    msg(['set ' num2str(objID) ' ' runString]);
    msg(['diode ' num2str(objID)]);    
    
    msgAndWait('ack');
    
    sendCode(codes.FIX_ON);
    
    histStart();
    
    msgAndWait('obj_on 1');

    if ~waitForFixation(e.timeToFix,fixX,fixY,params.fixRad)
        % failed to acheive fixation
        sendCode(codes.FIX_OFF);
        result = 3;        
        return;
    end
        
    sendCode(codes.STIM_ON);
    msgAndWait('obj_on 2');

    histAlign();
    
    if ~waitForSlave(fixX,fixY,params.fixRad)
        % failed to keep fixation
        sendCode(codes.FIX_OFF);
        result = 3;
        return;
    end        
        
    sendCode(codes.STIM_OFF);
        
    theta = rand(1)*360;
    newX = round(3*params.fixRad*cos(theta));
    newY = round(3*params.fixRad*sin(theta));

    histStop();
    
    sendCode(codes.FIX_MOVE);
    msgAndWait('set 1 oval 0 %i %i %i 0 0 255',[newX newY fixPtRad]);
    %msgAndWait('set 1 oval 0 %i %i %i 0 0 255',[0 0 fixPtRad]);

    if ~waitForFixation(e.saccadeTime,newX,newY,params.targetRad)
        result = 2;
        return;
    end
    if ~waitForMS(150,newX,newY,params.targetRad)
        result = 2;
        return;
    end

    sendCode(codes.FIX_CAUGHT);
    sendCode(codes.FIX_OFF);

    result = 1;

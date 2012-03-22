function result = ex_driftchoice(e)
% ex file: ex_driftchoice

    global params codes behav allCodes;
     
    %initialize behavior-related stuff:
    if ~isfield(behav,'score')||~isfield(behav,'targAmp')||~isfield(behav,'targPickHistory')
        behav.score = []; 
        behav.targAmp = sort(e.startTargAmp,'ascend');
        behav.targPickHistory = [];
        behav.trialNum = [];
        behav.RT = [];
    end; 
    
    %Constant stuff:
    frameMsec = params.slaveFrameTime*1000;
    stimulusDuration = e.stimulusDuration;
    targetDuration = e.targetDuration;
    minShortTargetOnset = e.minShortTargetOnset;
    maxShortTargetOnset = e.maxShortTargetOnset;
    minLongTargetOnset = maxShortTargetOnset;
    maxLongTargetOnset = stimulusDuration-targetDuration;
    shortLongTrialProportion = e.shortLongTrialProportion;
    cueDuration = e.cueDuration;
    cueWin = @hann;
    cueFs = 44100;
    cueFreq = e.cueFreq;
    startColors = [e.startColor1;e.startColor2];
    endColors = [e.endColor1;e.endColor2];
    orientations = [e.orientation1,e.orientation2];
    
    %Variable stuff:
    targetObject = abs(((1-e.isValid)*3)-e.cue);
    isShortTrial = rand<=shortLongTrialProportion;
    if isShortTrial
        targetOnset = randi(maxShortTargetOnset-minShortTargetOnset)+minShortTargetOnset;
    else
        targetOnset = randi(maxLongTargetOnset-minLongTargetOnset)+minLongTargetOnset;
    end;
    targetPeak = targetOnset+round(targetDuration./2); %frames
    targetEnd = targetOnset+targetDuration;

    targAmpPick = e.targAmpPick;
    targAmp = behav.targAmp(targAmpPick)*e.temporal;
    
    switch e.cueMap
        case 1 %spatial cue
            colorPick = [e.colorPick 3-e.colorPick];
            targColors = [startColors(colorPick(1),:);endColors(colorPick(1),:)];
            distColors = [startColors(colorPick(2),:);endColors(colorPick(2),:)];
            posPick = (1-targetObject)*2+1;
            targX = e.centerx*posPick;
            targY = e.centery*posPick;
            distX = -e.centerx*posPick;
            distY = -e.centery*posPick;
        case 2 %featural cue
            targColors = [startColors(targetObject,:);endColors(targetObject,:)];
            distColors = [startColors(3-targetObject,:);endColors(3-targetObject,:)];
            posPick = e.posPick;
            targX = e.centerx*posPick;
            targY = e.centery*posPick;
            distX = -e.centerx*posPick;
            distY = -e.centery*posPick;
        otherwise
            error('driftchoice:unknownCueMap','unknown cue mapping');
    end;
    orientations = orientations(randperm(numel(orientations))); %randomize orientations (write this out?)

    msgAndWait('set 5 rgbgrating %i %f %f %f %f %i %i %i %f %i %i %i %i %i %i %i %f %i %i %i',...
        [stimulusDuration  orientations(1) e.phase e.spatial e.temporal targX targY e.radius e.contrast targColors(:)' e.cmapReso,...
        targAmp  targetOnset targetPeak targetEnd]);
    msgAndWait('set 6 rgbgrating %i %f %f %f %f %i %i %i %f %i %i %i %i %i %i %i %f %i %i %i',...
        [stimulusDuration  orientations(2) e.phase e.spatial e.temporal distX distY e.radius e.contrast distColors(:)' e.cmapReso,...
        e.temporal targetOnset targetPeak targetEnd]);

    msgAndWait('set 1 oval 0 %i %i %i %i %i %i',[e.fixX e.fixY e.fixRad 255 255 0]); %constant central fixation (yellow)
    if e.showHoles
        msgAndWait('set 2 oval 0 %i %i %i %i %i %i',[targX targY e.fixRad e.helpFixColor]); %target fixation (blue)
        msgAndWait('set 3 oval 0 %i %i %i %i %i %i',[targX targY e.fixRad 127 127 127]); %'hole' in target grating
        msgAndWait('set 4 oval 0 %i %i %i %i %i %i',[distX distY e.fixRad 127 127 127]); %'hole' in distracter grating
    end;
    msg('diode 5');     
    
    msgAndWait('ack');
    
    histStart();
    
    msgAndWait('obj_on 1');
    sendCode(codes.FIX_ON);    

    if ~waitForFixation(e.timeToFix,e.fixX,e.fixY,params.fixWinRad)
        % failed to achieve fixation
        sendCode(codes.IGNORED);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;        
        return;
    end
    
    if ~waitForMS(e.preStimFix,e.fixX,e.fixY,params.fixWinRad)
        % hold fixation before stimulus comes on
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end
    
    %the cue:
    if cueDuration>0
        timebase = 0:1/cueFs:cueDuration;
        cueSound = feval(cueWin,numel(timebase))'.*sin(2.*pi.*cueFreq(e.cue).*timebase);
        sound(cueSound,cueFs);
    end;

    if ~waitForMS(e.cueTargetInterval,e.fixX,e.fixY,params.fixWinRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.STIM_OFF);
        sendCode(codes.FIX_OFF);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    end   
    
    %intro
    msgAndWait('queue_begin');
    msg('obj_on 5');
    msg('obj_on 6');
    if e.showHoles
        msg('obj_on 4');
        msg('obj_on 3');
    end;
    msgAndWait('queue_end');
    sendCode(codes.STIM_ON);
           
    histAlign();
        
    hitFlag = false;
    winColors = [0,255,0;255,0,0];
    %require hold fixation until target onset:
    if ~waitForMS(targetOnset.*frameMsec,e.fixX,e.fixY,params.fixWinRad)
        % failed to keep fixation
        sendCode(codes.BROKE_FIX);
        msgAndWait('all_off');
        sendCode(codes.STIM_OFF);
        sendCode(codes.FIX_OFF);
        behav.score(end+1) = nan;
        behav.trialNum(end+1) = length(allCodes);
        behav.RT(end+1) = nan;
        adjustTarget(e,targAmpPick);
        waitForMS(e.noFixTimeout);
        result = 3;
        return;
    else
        sendCode(codes.TARG_ON);
        targOnTime = tic;
    end;
    
    if e.showHoles
        choiceWin = waitForFixationChoice((targetPeak-targetOnset).*frameMsec,[targX distX],[targY distY],params.targWinRad.*[1 1],winColors); %note that target window is always '1'
        switch choiceWin
            case 1 %saccade to target
                if ~waitForMS(e.stayOnTarget,targX,targY,params.targWinRad) %require to stay on for a while, in case the eye 'accidentally' travels through target window
                    % failed to keep fixation
                    sendCode(codes.BROKE_FIX);
                    msgAndWait('all_off');
                    sendCode(codes.STIM_OFF);
                    sendCode(codes.FIX_OFF);
                    behav.score(end+1) = nan;
                    behav.trialNum(end+1) = length(allCodes);
                    behav.RT(end+1) = nan;
                    adjustTarget(e,targAmpPick);
                    waitForMS(e.noFixTimeout);
                    result = 2;
                    return;
                end;
                hitFlag = true;
                sendCode(codes.CORRECT);
                behav.score(end+1) = 1;
                behav.trialNum(end+1) = length(allCodes);
                behav.RT(end+1) = toc(targOnTime);
            case 2 %saccade to distracter
                sendCode(codes.WRONG_TARG); %change this to a new code for a wrong choice
                msgAndWait('all_off');
                sendCode(codes.STIM_OFF); 
                sendCode(codes.FIX_OFF);
                behav.score(end+1) = 0;
                behav.trialNum(end+1) = length(allCodes);
                behav.RT(end+1) = nan;
                adjustTarget(e,targAmpPick);
                result = 2; %change the result code to indicate a wrong choice
    %             fprintf('\nIncorrect Choice'); %for debug purposes
                return;
            otherwise
                %do nothing (yet)
        end;
        msg('obj_on 2');
        sendCode(codes.FIX_MOVE);
    end    
    
    if ~hitFlag
        choiceWin = waitForFixationChoice((stimulusDuration-targetOnset).*frameMsec,[targX distX],[targY distY],params.targWinRad.*[1 1],winColors(1:2,:)); %note that target window is always '1'
        %     fprintf('\nChoice:%i, Target:%i',choiceWin,targetObject); %debugging feedback
        switch choiceWin
            case 0
                % didn't reach target or distracter
                sendCode(codes.NO_CHOICE);
                msgAndWait('all_off');
                sendCode(codes.STIM_OFF);
                sendCode(codes.FIX_OFF);
                behav.score(end+1) = nan;
                behav.trialNum(end+1) = length(allCodes);
                behav.RT(end+1) = nan;
                adjustTarget(e,targAmpPick);
                result = 2;
                return;
            case 1 %the target window
                if ~waitForMS(e.stayOnTarget,targX,targY,params.targWinRad) %require to stay on for a while, in case the eye 'accidentally' travels through target window
                    % failed to keep fixation
                    sendCode(codes.BROKE_FIX);
                    msgAndWait('all_off');
                    sendCode(codes.STIM_OFF);
                    sendCode(codes.FIX_OFF);
                    behav.score(end+1) = nan;
                    behav.trialNum(end+1) = length(allCodes);
                    behav.RT(end+1) = nan;
                    adjustTarget(e,targAmpPick);
                    waitForMS(e.noFixTimeout);
                    result = 2;
                    return;
                end;
                sendCode(codes.CORRECT);
                behav.score(end+1) = 1;
                behav.trialNum(end+1) = length(allCodes);
                behav.RT(end+1) = toc(targOnTime);
            otherwise
                % incorrect choice
                %for a wrong choice, immediately score it, so that the subject
                %can't then switch to the other stimulus.
                sendCode(codes.WRONG_TARG); %change this to a new code for a wrong choice
                msgAndWait('all_off');
                sendCode(codes.STIM_OFF);
                sendCode(codes.FIX_OFF);
                behav.score(end+1) = 0;
                behav.trialNum(end+1) = length(allCodes);
                behav.RT(end+1) = nan;
                adjustTarget(e,targAmpPick);
                result = 2; %change the result code to indicate a wrong choice
                return;
        end;
    end;
         
    % turn off stimulus
    msgAndWait('all_off');
    sendCode(codes.STIM_OFF); 
    sendCode(codes.FIX_OFF);
    histStop();
                   
    adjustTarget(e,targAmpPick);
    result = 1;
    
function adjustTarget(e,targAmpPick)
    %Adjust target amplitude based on behavior (and update on-screen
    %score):
    global trialData behav
    behav.targPickHistory(end+1) = targAmpPick;
    if ~e.showHoles %don't adjust if you're just giving the subject the answer
%         display(behav.targPickHistory);
%         display(targAmpPick);
        if sum(~isnan(behav.score(behav.targPickHistory==targAmpPick)))>=e.numAdjustTrials %if there are enough 'completed' trials
            trialSubset = behav.score(behav.targPickHistory==targAmpPick&~isnan(behav.score));
            score = mean(trialSubset(end-e.numAdjustTrials+1:end)); 
%             fprintf('\nScore for adjustment: %f',score);
            if score<min(e.behavLimits) %if the score is below the accepted range
                if targAmpPick==1&&behav.targAmp(1)>=e.targAmpStep
                    behav.targAmp(1)=behav.targAmp(1)-e.targAmpStep; %make the 'slow' target slower (down to zero)
                elseif targAmpPick==2
                    behav.targAmp(2)=behav.targAmp(2)+e.targAmpStep; %make the fast target faster
                end;
            elseif score>max(e.behavLimits) %if the score is above the accepted range
                if targAmpPick==1&&behav.targAmp(1)<1-(2*e.targAmpStep)
                    behav.targAmp(1)=behav.targAmp(1)+e.targAmpStep; %make the slow target faster
                elseif targAmpPick==2&&behav.targAmp(2)>=1+(2*e.targAmpStep)
                    behav.targAmp(2)=behav.targAmp(2)-e.targAmpStep; %make the fast target slower (down to 1+e.targAmpStep)
                end;
            end;
        end;
    end;
    trialData{6} = sprintf('Hits: %d, Incorrects: %d (%.1f%%), Other: %d',sum(behav.score==1&~isnan(behav.score)),sum(behav.score==0&~isnan(behav.score)),nanmean(behav.score)*100,sum(isnan(behav.score)));
    trialData{7} = sprintf('Target amplitudes: %.2f, %.2f',behav.targAmp);
%     trialData{7} = ['RTs (ms): ' sprintf('%4.1f, ',fliplr(behav.RT(~isnan(behav.RT))*1000))];

function drawHistogram(cnd)
% function drawHistogram
%
% using trialSpikes, draws the histogram for condition cnd to the screen

global trialSpikes wins params

    gray=(WhiteIndex(0)+BlackIndex(0))/2;
        
    Screen(wins.hist,'FillRect',gray);
    
    validSpikes = cell2mat(trialSpikes{cnd}');
        
    [h h_x] = hist(validSpikes,wins.histDim(3));
    h = [1:length(h); h];
    h = h(:,h(2,:)~=0);

    [~,alignX] = min(abs(h_x));
    
    if ~isempty(h)
        h = reshape(repmat(h,2,1),2,size(h,2)*2);
        h(2,1:2:end) = 0;
        h(2,2:2:end) = floor((wins.histDim(4)-25)*h(2,2:2:end)/max(h(2,2:2:end)));
        h(2,:) = wins.histDim(4) - h(2,:);
        Screen('DrawLines',wins.hist,h);
    end

    for i = 1:10
        tri = length(trialSpikes{cnd}) - i + 1;
        if tri < 1
            break
        end
        h = hist(trialSpikes{cnd}{tri},h_x);
        h = find(h);
        if ~isempty(h)
            h = reshape(repmat(h,2,1),1,length(h)*2);
            h = [h; zeros(1,length(h))+i-1];
            h(2,2:2:end) = h(2,2:2:end)+1;
            Screen('DrawLines',wins.hist,h);
        end
    end
    
    Screen('DrawLine',wins.hist,255,0,wins.histDim(4)-1,wins.histDim(3),wins.histDim(4)-1);
    Screen('DrawLine',wins.hist,[255 0 0],alignX,25,alignX,wins.histDim(4)-1);
    
    tickLocationsHigh = params.histTickSpacing:params.histTickSpacing:max(h_x);
    tickLocationsLow = -(params.histTickSpacing:params.histTickSpacing:max(-h_x));
    tickLocations = [fliplr(tickLocationsLow) tickLocationsHigh];
    
    if ~isempty(tickLocations)
        for i = 1:length(tickLocations)
            [~, tickLocations(i)] = min(abs(h_x-tickLocations(i)));
        end
        
        ticks = reshape(repmat(tickLocations,2,1),1,length(tickLocations)*2);
        ticks = [ticks; zeros(1,length(ticks))+wins.histDim(4)-1];
        ticks(2,2:2:end) = ticks(2,2:2:end)-5;
    
        Screen('DrawLines',wins.hist,ticks,1,[255 255 255]);
    end
end
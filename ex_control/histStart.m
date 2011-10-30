function histStart()
% function histStart
% Simply calls samp(-3) to set the histogram start time.

    global params

    if params.getSpikes
        samp(-3);
    end
end

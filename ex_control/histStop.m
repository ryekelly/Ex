function histStop()
% function histStop
% Simply calls samp(-1) to set the histogram stop time.

    global params

    if params.getSpikes
        samp(-1);
    end
end

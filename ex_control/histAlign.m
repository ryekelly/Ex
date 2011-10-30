function histAlign()
% function histAlign
% Simply calls samp(-2) to set the align time.

    global params

    if params.getSpikes
        samp(-2);
    end
end

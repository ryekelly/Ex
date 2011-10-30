function histCompile(cnd)
% function histCompile(cnd)
% This calls samp(0) to collect the input spikes. It sets the next element in 
% trialSpikes{cnd} to the list of spike times.  Negative times precede the
% align code.
% cnd: the condition number

    global trialSpikes params

    if params.getSpikes
        [sp align] = samp(0);

        trialSpikes{cnd}{end+1} = find(diff(sp>params.spikeThreshold)==1) - align;
    end
end

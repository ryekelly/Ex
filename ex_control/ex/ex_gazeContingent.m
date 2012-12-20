function result = ex_gazeContingent(e)

    global wins
    
    r=5;
    while 1
        pt = samp .* wins.pixelsPerMV + wins.midV;

        pt(2) = wins.voltageDim(4) - pt(2); % flip Y coordinate

        % obj 1 is fix spot
        msg('set 1 oval 0 %i %i %i %i %i %i',[round(pt) r 255 0 0]);
        msg('obj_on 1');
    end;
    result = 2;

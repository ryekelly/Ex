function result = ex_codetest(e)

    t = tic;
    while toc(t)<10
        detectSaccades;
    end;
    
    result = 1;
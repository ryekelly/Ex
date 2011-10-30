function shouldBreak = keyboardEvents()
    global trialMessage;

    shouldBreak = 0;
    
    if CharAvail        
        c = GetChar;
        if c == 'j'
            sendCode(18);
            giveJuice();
        elseif c == 'q'
            trialMessage = -1;
            shouldBreak = 1;
        end
    end
    
end    

function error_code = msgAndWait(m,args)
% function msg(msg,args)
% ex helper function, sends a message to the slave and then waits for a
% response from the slave
%
% msg: a string message
% args: if present, the msg variable can use % replacement like fprintf and
%   these are the arguments
%
% examples:
% > msg('obj_on 3');
% > msg('obj_on %i',3);

sent_id = -1;

if nargin > 1
    sent_id = msg(m,args);
else
    sent_id = msg(m);
end

[rcvd error_code] = waitFor(sent_id);

if error_code > 0
    if error_code == 1
        error('MSG:TIMEOUT',sprintf('Timeout. Sent message id: %i', sent_id));
    elseif error_code == 2
        error('MSG:BAD_ID', sprintf('Missed some messages before id: %i', sent_id));        
    end   
end
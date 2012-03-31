function sent_id = msg(m,args)
% function msg(msg,args)
% ex helper function, sends a message to the slave and then moves on
%
% msg: a string message
% args: if present, the msg variable can use % replacement like fprintf and
%   these are the arguments
%
% examples:
% > msg('obj_on 3');
% > msg('obj_on %i',3);

global out last_sent_msg debug;

last_sent_msg = last_sent_msg + 1;

s = '';
if nargin > 1
    s = sprintf(['%i ' m], [last_sent_msg args]);
else
    s = sprintf(['%i ' m], last_sent_msg);
end

if debug
    disp(sprintf('Sent: %s', s))
end
fprintf(out, s);

sent_id = last_sent_msg;

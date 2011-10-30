function s = waitFor(m)
% function waitFor(m)
%
% just waits for any input from the slave, and then returns.
global out;

while 1
    if get(out,'BytesAvailable') > 0
        s = fgetl(out);

        if nargin > 0
            if strcmp(s,m)
                break;
            end
        else
            break;
        end
    end
end
    
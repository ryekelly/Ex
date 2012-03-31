function [s error_code] = waitFor(id)
% function waitFor(m)
%
% just waits for any input from the slave, and then returns.
global out last_received_msg debug timeout;

error_code = 0;

start_time = toc;

while toc - start_time < timeout
    if get(out,'BytesAvailable') > 0
        s = fgetl(out);
        if debug
            disp(sprintf('Rcvd: %s', s));
        end
        [id_str s] = strtok(s);
        id_received = str2double(id_str);
        if id_received ~= last_received_msg + 1
            error_code = 2;
        end
        last_received_msg = id_received;
        
        if nargin > 0
            if id == id_received
                return;
            end
        else
            return;
        end
    end
end

s = '';
error_code = 1;
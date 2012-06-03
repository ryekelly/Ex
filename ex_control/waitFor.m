function s = waitFor()
% function waitFor(m)
%
% just waits for any input from the slave, and then returns.
global debug;

while 1
  if matlabUDP('check')
    s = matlabUDP('receive');
    if debug
      fprintf('Rcvd: %s', s);
    end
    break;
  end
end
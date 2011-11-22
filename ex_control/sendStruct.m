%function sendStruct(s)
%
% Send a struct as ascii over the digital port using digCode.m
%
%
function sendStruct(s)

fields = fieldnames(s);

for i = 1:length(fields)
    val = num2str(s.(fields{i}));
    % Ryan's original
    %m = double([fields{i} '=' val])*256;
    %digCode([m 256]);
    m = double([fields{i} '=' val])+256;
    digCode(m);
end

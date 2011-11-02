function sendStruct(s)

fields = fieldnames(s);

for i = 1:length(fields)
    val = num2str(s.(fields{i}));
    m = double([fields{i} '=' val])*256;
    digCode([m 256]);
end
function [m params randoms] = readExperiment(xmlFile)
% function [m params randoms] = readExperiment(xmlFile)
%
% reads an xml file and returns the 3 sets of parameters:
% conditions: parameters that are tied to condition number
% params: parameters that are fixed
% randoms: parameters that vary randomly on every trial, but are not tied
%   to condition

params = struct();
randoms = struct();

x = xml2struct(xmlFile);
x = removeBlanks(x);
m = cell(0);
id = 1;

mainAtt = struct2cell(x.Attributes);
params.rpts = str2num(cell2mat(mainAtt(2,strcmp('repeats',mainAtt(1,:)))));
params.exFileName = cell2mat(mainAtt(2,strcmp('ex',mainAtt(1,:))));
params.bgColor = cell2mat(mainAtt(2,strcmp('bgColor',mainAtt(1,:))));

for i = 1:length(x.Children)
    node = x.Children(i);
    if strcmp(node.Name,'conditions')
        c = node.Children;
                 
        pVal = cell(length(c),1);
        pName = cell(length(c),1);
        pData = cell(length(c),1);

        for i = 1:length(c)
            if strcmp(c(i).Name,'grouped');
                for j = 1:length(c(i).Children)
                    pName{i}{j} = c(i).Children(j).Name;
                    pDat{i}{j} = eval(c(i).Children(j).Children.Data);
                end
                pVal{i} = 1:length(pDat{i}{1});
            else
                pName{i} = c(i).Name;
                pDat{i} = eval(c(i).Children(1).Data);
                pVal{i} = 1:length(pDat{i});
            end     
        end

        ndGridCmd = '[';
        for i = 1:length(pVal)
            ndGridCmd = sprintf('%sp{%i} ',ndGridCmd,i);
        end
        ndGridCmd = [ndGridCmd(1:end-1) '] = ndgrid('];
        for i = 1:length(pVal)
            ndGridCmd = sprintf('%spVal{%i},',ndGridCmd,i);
        end
        ndGridCmd = [ndGridCmd(1:end-1) ');'];
  
        p = cell(length(pVal),1);
        eval(ndGridCmd);

        for i = 1:length(p{1}(:))
            for j = 1:length(node.Attributes)
                eval(sprintf('m{id}.%s = node.Attributes(j).Value;',node.Attributes(j).Name));
            end
            
            
            for j = 1:length(pVal)
                if iscell(pName{j})
                    for k = 1:length(pName{j})
                        % WORK HERE
                        eval(sprintf('m{id}.%s = pDat{j}{k}(p{j}(i));',pName{j}{k}));
                    end
                else
                    eval(sprintf('m{id}.%s = pDat{j}(p{j}(i));',pName{j}));
                end
            end
            id = id + 1;
        end
        
    elseif strcmp(node.Name,'params')
        for i = 1:length(node.Children)
            thisParam = node.Children(i);
            paramName = thisParam.Name;
            paramData = thisParam.Children.Data;
            paramDataNum = str2num(paramData);
            if ~isempty(paramDataNum)
                paramData = paramDataNum;
            end
            eval(sprintf('params.%s = paramData;',paramName));
        end
    else
        for i = 1:length(node.Children)
            thisParam = node.Children(i);
            paramName = thisParam.Name;
            paramData = thisParam.Children.Data;
            paramDataNum = str2num(paramData);
            if ~isempty(paramDataNum)
                paramData = paramDataNum;
            end
            eval(sprintf('randoms.%s = paramData;',paramName));
        end
    end       
end

end
    
function x = removeBlanks(x)
    keep = ones(length(x.Children),1);
    for i = 1:length(x.Children)
        if strcmp(x.Children(i).Name,'#text') &  all(isspace(x.Children(i).Data))
            keep(i) = 0;
        else
            x.Children(i) = removeBlanks(x.Children(i));
        end
    end
    
    x.Children = x.Children(find(keep));
end

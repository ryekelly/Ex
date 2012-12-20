function [decoded, times] = exDecode(codeIn)
%To decode ex codes into something resembling English. adam@adamcsnyder.com
%23Apr2012
    globals; times = [];
    if isa(codeIn,'struct')&&isfield(codeIn,'codes') %added to make it easier to work with allCodes variables output by Ex -ACS 24AUG2012
        codeIn = codeIn.codes;
    end;
    if sum(size(codeIn)>1)>1
        times = codeIn(:,2);
    end;
    codeIn = codeIn(:,1);    
    codeNames = fieldnames(codes);
    codeNums = cell2mat(struct2cell(codes));
    nameInds = cell2mat(cellfun(@find,cellfun(@eq,repmat({codeNums},size(codeIn)),num2cell(codeIn),'uniformoutput',0),'uniformoutput',0));
    try
        times = times(ismember(codeIn,codeNums));
    catch %#ok<CTCH>
        times = [];
    end;
    decoded = codeNames(nameInds);

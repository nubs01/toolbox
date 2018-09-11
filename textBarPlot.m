function out = textBarPlot(dat,varargin)
    % out = textBarPlot(data,varargin) makes a character array depicting the bar plot. 
    % NAME-VALUE Pairs
    % barChar
    % blankChar

    barChar = ' + ';
    blankChar = '   ';
    sepChar = '|';

    assignVars(varargin)

    out = repmat({blankChar},max(dat),numel(dat));
    for k=1:numel(dat)
        out(end-dat(k)+1:end,k) = {barChar};
    end
    out = cell2mat(out);

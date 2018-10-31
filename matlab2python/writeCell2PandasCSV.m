function writeCell2PandasCSV(outFile,data,varargin)
    % writeCell2PandasCSV(outFile,data,varargin) writes data in cell array to a
    % csv in a format that can be easily read into a pandas dataframe in python
    % NAME-VALUE Pairs:
    % headers   : cell vector of string headers for columns
    % precision : number of digits after the decimal to keep for numbers

    headers = {};
    precision = 3;
    append = 0;

    assignVars(varargin)

    nRows = size(data,1);
    nCols = size(data,2);

    if ~append
        fid = fopen(outFile,'w');
    else
        fid = fopen(outFile,'a');
    end
    if ~isempty(headers)
        idx = ~cellfun(@ischar,headers);
        if any(idx)
            headers(idx) = cellfun(@num2str,headers(idx),'UniformOutput',false);
        end
        headStr = sprintf(',%s',headers{:});
        headStr = headStr(2:end);
        fprintf(fid,headStr);
        fprintf(fid,'\n');
    end

    for k=1:nRows
        rowStr = '';
        for l=1:nCols
            tmp = data{k,l};
            if isnumeric(tmp)
                tmp = sprintf(['%0.' num2str(precision) 'f'],tmp);
            end
            rowStr = [rowStr ',' tmp];
        end
        rowStr = rowStr(2:end);
        fprintf(fid,[rowStr '\n']);
    end
    fclose(fid);

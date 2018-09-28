function out = get_data_path(pathName,varargin)
    % Retruns the path associated with pathName in data_paths.json (must be in
    % the matlab search path)
    % can override data_paths.json by specifying pathFile

    pathFile = 'data_paths.json';
    animID = '';
    if nargin==2
        animID = varargin{1};
        varargin = {};
    end

    assignVars(varargin)

    outStruct = jsondecode(fileread(pathFile));
    if isfield(outStruct,pathName)
        out = outStruct.(pathName);
        if ~isempty(animID)
            tmp = dir([out filesep '*' animID '*']);
            if ~isempty(tmp)
                out = [out filesep tmp.name];
            else
                out = [];
            end
        end
    else
        out = [];
    end

    if ~isempty(out)
        out = strrep(out,'/',filesep);
        out = strrep(out,[filesep filesep],filesep);
    end

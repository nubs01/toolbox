function varargout = stateValidationGUI(varargin)
    % stateMat = stateValidationGUI(dataStruct,,varargin)
    % dataStruct: struct array with element for each epoch
    %   - Animal ID
    %   - Day
    %   - Epoch
    %   - epoch_type
    %   - riptet list
    %   - cwt specgram for each riptet (cell array) (frequency (rows) x time (cols))
    %   - cwt time
    %   - cwt frequency
    %   - emg power
    %   - emg time
    %   - velocity
    %   - velocity time
    %   - state matrix ( start time | end time | state (number))
    % Name-Value Pairs
    % stateColors (rgb matrix)  if not provided, colors will be automatically chosen
    % stateNames (cell array) if not provided states will be {'REM','NREM','Rest','Active','Artifact'} or numbered
    % bandNames (cellArray) - default {'Delta','Theta',Sigma'}
    % bandFreqs (cell array of [start_freq end_freq]) - default {[1 4],[5 10],[11 14]}
    % displaySize - number of seconds to display in time plots (default 600)
    % TODO: Change point plotting and pointClick to plot all at once and deal
    % with functionality via windowButtonUpFcn
% STATEVALIDATIONGUI MATLAB code for stateValidationGUI.fig
%      STATEVALIDATIONGUI, by itself, creates a new STATEVALIDATIONGUI or raises the existing
%      singleton*.
%
%      H = STATEVALIDATIONGUI returns the handle to a new STATEVALIDATIONGUI or the handle to
%      the existing singleton*.
%
%      STATEVALIDATIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STATEVALIDATIONGUI.M with the given input arguments.
%
%      STATEVALIDATIONGUI('Property','Value',...) creates a new STATEVALIDATIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before stateValidationGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to stateValidationGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help stateValidationGUI

% Last Modified by GUIDE v2.5 10-Aug-2018 13:01:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @stateValidationGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @stateValidationGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before stateValidationGUI is made visible.
function stateValidationGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to stateValidationGUI (see VARARGIN)


% Choose default command line output for stateValidationGUI
handles.output = varargin{1}.state_mat;

% Update handles structure
guidata(hObject, handles);
if numel(varargin)==1
    init(varargin{1},handles)
else
    init(varargin{1},handles,varargin(2:end))
end
% UIWAIT makes stateValidationGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

function init(inputData,handles,varargin)
    setappdata(handles.figure1,'InputData',inputData)
    stateNames = {'REM','NREM','Rest','Active','Transition','Artifact'};
    bandFreqs = {[1 4],[5 10],[11 14]};
    bandNames = {'Theta','Delta','Sigma'};
    stateColors = [0 1 1;... % REM
                    0 0 1;... %NREM
                    1 0 1;... %Rest
                    1 0 0;... %Active
                    0 1 0;... %Transition
                    .85 .33 .1]; %Artifact

    displaySize = 300; % Size of time window to display (seconds)

    set(handles.winSize_edit,'String','30')
    setappdata(handles.figure1,'init_varargin',varargin)
    assignVars(varargin)

    set(handles.transition_push,'ForegroundColor',[0 1 0])
    set(handles.title_text,'String',sprintf('%s Day %02i Epoch %02i: %s',inputData.animal,inputData.day,inputData.epoch,inputData.epoch_type))
    setappdata(handles.figure1,'stateNames',stateNames)
    setappdata(handles.figure1,'stateColors',stateColors)
    setappdata(handles.figure1,'bandNames',bandNames)
    setappdata(handles.figure1,'bandFreqs',bandFreqs)
    setappdata(handles.figure1,'displaySize',displaySize)
    setappdata(handles.figure1,'currentIdx',1)
    setappdata(handles.figure1,'episodeEdgeHandles',[])
    setappdata(handles.figure1,'lightEdges',[])
    setappdata(handles.figure1,'pointHandles',[])
    setappdata(handles.figure1,'scatter_x',[])
    setappdata(handles.figure1,'scatter_y',[])
    setappdata(handles.figure1,'scatter_time',[])
    setappdata(handles.figure1,'scatter_states',[])
    setappdata(handles.figure1,'patchHandles',[])
    setappdata(handles.figure1,'pointHighlight',[])
    setappdata(handles.figure1,'currentStateMat',inputData.state_mat)
    setappdata(handles.figure1,'winSize',str2double(get(handles.winSize_edit,'String')))
    setappdata(handles.figure1,'movingLine',[])
    setappdata(handles.figure1,'movingLineNum',1)
    setappdata(handles.figure1,'breakActive',0)
    setappdata(handles.figure1,'breakLine',[])
    set(handles.episode_radio,'Value',1)
    set(handles.ep_edit,'String','1')
    tetList = arrayfun(@(x) sprintf('Tet %02i',x),inputData.riptets,'UniformOutput',false);
    set(handles.tet_pop,'String',tetList,'Value',1)
    set(handles.set_push,'Visible','off')
    set(handles.winSize_edit,'Enable','off')
    set(handles.break_push,'Enable','on')
    set(handles.change_panel,'Visible','on')
    set(handles.nav_panel,'Visible','on')
    set(handles.edit_panel,'Visible','on')
    

    plotMovementData(handles)
    updateStateColoring(handles)
    plotSpectrogram(handles)
    plotScatter(handles)
    makeWindowLines(handles)
    updateStats(handles)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    uiresume(handles.figure1)


% --- Outputs from this function are returned to the command line.
function varargout = stateValidationGUI_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = getappdata(handles.figure1,'currentStateMat');
    delete(handles.figure1);


% --- Executes on selection change in y_pop.
function y_pop_Callback(hObject, eventdata, handles)
    % hObject    handle to y_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    plotScatter(handles)

% --- Executes during object creation, after setting all properties.
function y_pop_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to y_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on selection change in tet_pop.
function tet_pop_Callback(hObject, eventdata, handles)
    % hObject    handle to tet_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    plotSpectrogram(handles)
    plotScatter(handles)


% --- Executes during object creation, after setting all properties.
function tet_pop_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to tet_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on selection change in x_pop.
function x_pop_Callback(hObject, eventdata, handles)
    % hObject    handle to x_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    plotScatter(handles)

% --- Executes during object creation, after setting all properties.
function x_pop_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to x_pop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in break_push.
function break_push_Callback(hObject, eventdata, handles)
    % hObject    handle to break_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    scatterTime = getappdata(handles.figure1,'scatter_time');
    idx = getappdata(handles.figure1,'currentIdx');
    xx = mean(scatterTime(idx,:));
    axes(handles.ep_ax)
    hold on
    yl = get(handles.ep_ax,'YLim');
    ph = plot([xx xx],yl,'k-','LineWidth',2);
    set(ph,'ButtonDownFcn',@(src,event)stateValidationGUI('border_press_Callback',src,event,guidata(src),3))
    setappdata(handles.figure1,'breakLine',ph)
    setappdata(handles.figure1,'breakActive',1)
    set(handles.nav_panel,'Visible','off')
    set(handles.change_panel,'Visible','off')
    set(handles.set_push,'Visible','on','Enable','on')
    set(handles.break_push,'Enable','off')
    set(handles.epoch_panel,'Visible','off')


% --- Executes on button press in set_push.
function set_push_Callback(hObject, eventdata, handles)
    % hObject    handle to set_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    L = getappdata(handles.figure1,'breakLine');
    newX = get(L,'XData');
    newX = newX(1);
    stateMat = getappdata(handles.figure1,'currentStateMat');
    epEnd = find(stateMat(:,1)<=newX & stateMat(:,2)>=newX);
    if epEnd<size(stateMat,1)
        SM = [stateMat(1:epEnd,:);newX stateMat(epEnd,2) stateMat(epEnd,3);stateMat(epEnd+1:end,:)];
    else
        SM = [stateMat(1:epEnd,:);newX statemat(epEnd,2) stateMat(epEnd,3)];
    end
    SM(epEnd,2) = newX;
    setappdata(handles.figure1,'currentStateMat',SM)

    delete(L)
    set(handles.set_push,'Visible','off')
    set(handles.break_push,'Enable','on')
    set(handles.change_panel,'Visible','on')
    setappdata(handles.figure1,'breakActive',0)
    setappdata(handles.figure1,'breakLine',[])
    set(handles.nav_panel,'Visible','on')
    set(handles.epoch_panel,'Visible','on')

    plotScatter(handles)
    makeWindowLines(handles)
    updateStateColoring(handles)


% --- Executes on button press in reset_push.
function reset_push_Callback(hObject, eventdata, handles)
    % hObject    handle to reset_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    inputData = getappdata(handles.figure1,'InputData');
    setappdata(handles.figure1,'currentStateMat',inputData.state_mat)
    updateStateColoring(handles)


% --- Executes on button press in done_push.
function done_push_Callback(hObject, eventdata, handles)
    % hObject    handle to done_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.figure1)


function ep_edit_Callback(hObject, eventdata, handles)
    % hObject    handle to ep_edit (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    epNum = str2double(get(hObject,'String'));
    scatterTime = getappdata(handles.figure1,'scatter_time');
    if isempty(epNum) || epNum<=0 || epNum>size(scatterTime,1)
        set(hObject,'String',getappdata(handles.figure1,'currentIdx'))
        errordlg('Please input a valid number')
        return;
    end
    setappdata(handles.figure1,'currentIdx',epNum)
    setCurrentWindow(handles)


% --- Executes during object creation, after setting all properties.
function ep_edit_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ep_edit (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in next_push.
function next_push_Callback(hObject, eventdata, handles)
    % hObject    handle to next_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    epIdx = getappdata(handles.figure1,'currentIdx');
    sT = getappdata(handles.figure1,'scatter_time');
    if epIdx<size(sT,1)
        epIdx = epIdx+1;
    end
    setappdata(handles.figure1,'currentIdx',epIdx)
    setCurrentPoint(handles)


% --- Executes on button press in prev_push.
function prev_push_Callback(hObject, eventdata, handles)
    % hObject    handle to prev_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    epIdx = getappdata(handles.figure1,'currentIdx');
    if epIdx>1
        epIdx = epIdx-1;
    end
    setappdata(handles.figure1,'currentIdx',epIdx)
    setCurrentPoint(handles)

% --- Executes on button press in nrem_push.
function nrem_push_Callback(hObject, eventdata, handles)
    % hObject    handle to nrem_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'NREM'));
    changeCurrentState(handles,newState)


% --- Executes on button press in rest_push.
function rest_push_Callback(hObject, eventdata, handles)
    % hObject    handle to rest_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'Rest'));
    changeCurrentState(handles,newState)


% --- Executes on button press in move_push.
function move_push_Callback(hObject, eventdata, handles)
    % hObject    handle to move_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'Active'));
    changeCurrentState(handles,newState)


% --- Executes on button press in art_push.
function art_push_Callback(hObject, eventdata, handles)
    % hObject    handle to art_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'Artifact'));
    changeCurrentState(handles,newState)


% --- Executes on button press in rem_push.
function rem_push_Callback(hObject, eventdata, handles)
    % hObject    handle to rem_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'REM'));
    changeCurrentState(handles,newState)

function changeCurrentState(handles,newState)
    idx = getappdata(handles.figure1,'currentIdx');
    stateMat = getappdata(handles.figure1,'currentStateMat');
    stateColors = getappdata(handles.figure1,'stateColors');
    sh = getappdata(handles.figure1,'patchHandles');
    set(sh(idx),'FaceColor',stateColors(newState,:))
    stateMat(idx,3) = newState;
    stateMat = stitchStates(stateMat);
    setappdata(handles.figure1,'currentStateMat',stateMat);
    makeWindowLines(handles)
    plotScatter(handles)
    updateStats(handles)

% Plot scatter plot
function  plotScatter(handles)
    ph = getappdata(handles.figure1,'pointHighlight');
    if ~isempty(ph)
        delete(ph)
    end
    inputData = getappdata(handles.figure1,'InputData');
    ph = getappdata(handles.figure1,'pointHandles');
    stateMat = getappdata(handles.figure1,'currentStateMat');
    SC = getappdata(handles.figure1,'stateColors');
    if ~isempty(ph)
        delete(ph)
    end
    xOpts = get(handles.x_pop,'String');
    xIdx = get(handles.x_pop,'Value');
    xStr = xOpts{xIdx};
    yOpts = get(handles.y_pop,'String');
    yIdx = get(handles.y_pop,'Value');
    yStr = yOpts{yIdx};

    [xVec,xTime] = getDataVector(handles,inputData,xStr);
    [yVec,yTime] = getDataVector(handles,inputData,yStr);

    % Bin data according to episode or window
    if get(handles.episode_radio,'Value')==1
        scatterTime = stateMat(:,1:2);
        scatterStates = stateMat(:,3);
    else
        scatterTime = getappdata(handles.figure1,'scatter_time');
        scatterStates = zeros(size(scatterTime,1),1);
        for k=1:size(scatterTime,1)
            tmp = find(stateMat(:,1)<=scatterTime(k,1) & stateMat(:,2)>=scatterTime(k,2));
            if isempty(tmp)
                scatterStates(k) = 5;
            else
                scatterStates(k) = stateMat(tmp,3);
            end
        end
    end
    scatterX = zeros(size(scatterTime,1),1);
    scatterY = zeros(size(scatterTime,1),1);
    scatterColors = SC(scatterStates,:);
    for k=1:size(scatterTime,1)
        a = xTime>=scatterTime(k,1) & xTime<=scatterTime(k,2);
        b = yTime>=scatterTime(k,1) & yTime<=scatterTime(k,2);
        if strcmpi(xStr,'emg variance')
            scatterX(k) = var(xVec(a));
        else
            scatterX(k) = mean(xVec(a));
        end
        if strcmpi(yStr,'emg variance')
            scatterY(k) = var(yVec(b));
        else
            scatterY(k) = mean(yVec(b));
        end
    end
    axes(handles.scatter_ax)
    ph = scatter(scatterX,scatterY,15,scatterColors,'filled');
    set(ph,'MarkerFaceAlpha',.5,'ButtonDownFcn',@(src,event)stateValidationGUI('point_click_Callback',src,event,guidata(src)));
    drawnow;
    % Highlight current point
    currIdx = getappdata(handles.figure1,'currentIdx');
    if isempty(currIdx) || currIdx>size(scatterTime,1)
        setappdata(handles.figure1,'currentIdx',1);
    end
    
    setappdata(handles.figure1,'pointHighlight',[])
    setappdata(handles.figure1,'pointHighlight',[])
    setappdata(handles.figure1,'pointHandles',ph)
    setappdata(handles.figure1,'scatter_x',scatterX)
    setappdata(handles.figure1,'scatter_y',scatterY)
    setappdata(handles.figure1,'scatter_time',scatterTime)
    setappdata(handles.figure1,'scatter_states',scatterStates)
    set(handles.total_text,'String',['/  ' num2str(size(scatterTime,1))])
    setCurrentPoint(handles)


% Function to return the correct data for a given pop choice
function [datVec,datTime] = getDataVector(handles,dat,str)
    datVec = [];
    datTime = [];
    bandNames = getappdata(handles.figure1,'bandNames');
    bandFreqs = getappdata(handles.figure1,'bandFreqs');
    tIdx = find(strcmpi(bandNames,'theta'));
    dIdx = find(strcmpi(bandNames,'delta'));
    sIdx = find(strcmpi(bandNames,'sigma'));
    tetIdx = get(handles.tet_pop,'Value');
    specDat = dat.specgram{tetIdx};
    switch lower(str)
        case 'velocity'
            datVec = dat.velocity;
            datTime = dat.vel_time;
        case 'theta/(delta+sigma)'
            if isempty(tIdx) || isempty(dIdx) || isempty(sIdx)
                error('Missing Band Information')
                % TODO: Reset to old option
            end 
            t = getBandPower(specDat,dat.spec_freq,bandFreqs{tIdx});
            d = getBandPower(specDat,dat.spec_freq,bandFreqs{dIdx});
            s = getBandPower(specDat,dat.spec_freq,bandFreqs{sIdx});
            datVec = t./(d+s);
            datTime = dat.spec_time;
        case {'emg power','emg variance'}
            datVec = dat.emg_power;
            datTime = dat.emg_time;
        case 'delta/theta'
            t = getBandPower(specDat,dat.spec_freq,bandFreqs{tIdx});
            d = getBandPower(specDat,dat.spec_freq,bandFreqs{dIdx});
            datVec = d./t;
            datTime = dat.spec_time;
        otherwise % band power or band variance
            str1 = strsplit(str,' ');
            idx = find(strcmpi(bandNames,str1{1}));
            if strcmpi(str1{2},'power')
                datVec = getBandPower(specDat,dat.spec_freq,bandFreqs{idx});
            elseif strcmpi(str1{2},'variance')
                datVec = getBandVariance(specDat,dat.spec_freq,bandFreqs{idx});
            else
                error('Invalid Option')
            end
            datTime = dat.spec_time;
    end


% Function returns band power 
function out = getBandPower(specDat,specFreq,bandFreq)
    a = specFreq>=bandFreq(1) & specFreq<=bandFreq(2);
    out = mean(specDat(a,:));

% Function returns band variance
function out = getBandVariance(specDat,specFreq,bandFreq)
    a = specFreq>=bandFreq(1) & specFreq<=bandFreq(2);
    out = var(specDat(a,:));
    

% react to clicking on a point in the scatter plot
function point_click_Callback(hObject,eventdata,handles)
    if ~getappdata(handles.figure1,'breakActive')
        cp = get(handles.scatter_ax,'CurrentPoint');
        cx = cp(1,1);
        cy = cp(1,2);
        xx = getappdata(handles.figure1,'scatter_x');
        yy = getappdata(handles.figure1,'scatter_y');
        dists = arrayfun(@(x,y) sqrt((x-cx)^2+(y-cy)^2),xx,yy);
        [~,k] = min(dists);
        fprintf('Clicked Point %i at [%0.2f,%0.2f]\n',k,cx,cy)
        setappdata(handles.figure1,'currentIdx',k)
        setappdata(handles.figure1,'pointClicked',1)
        setCurrentPoint(handles)
    end
    
function setCurrentPoint(handles)
    idx = getappdata(handles.figure1,'currentIdx');
    ph = getappdata(handles.figure1,'pointHandles');
    oph = getappdata(handles.figure1,'pointHighlight');
    SC = getappdata(handles.figure1,'stateColors');
    scatterStates = getappdata(handles.figure1,'scatter_states');
    scatterX = getappdata(handles.figure1,'scatter_x');
    scatterY = getappdata(handles.figure1,'scatter_y');
    if ~isempty(oph) && ishandle(oph)
        delete(oph)
    end
    axes(handles.scatter_ax)
    hold on
    oph = plot(scatterX(idx),scatterY(idx),'k.','MarkerSize',25,'Color',SC(scatterStates(idx),:));
    setappdata(handles.figure1,'pointHighlight',oph)
    set(handles.ep_edit,'String',num2str(idx))
    setCurrentWindow(handles)

% react to clicking a line
function border_press_Callback(hObject,eventdata,handles,edgeNum)
    if getappdata(handles.figure1,'breakActive') && edgeNum~=3
        return;
    end
    setappdata(handles.figure1,'movingLine',hObject)
    setappdata(handles.figure1,'movingLineNum',edgeNum)

% update statistics box
function updateStats(handles)
    stateMat = getappdata(handles.figure1,'currentStateMat');
    stateNames = getappdata(handles.figure1,'stateNames');
    stateTimes = zeros(numel(stateNames),1);
    epNum = zeros(numel(stateNames),1);
    for k=1:numel(stateNames)
        idx = stateMat(:,3)==k;
        stateTimes(k) = sum(diff(stateMat(idx,1:2),1,2));
        epNum(k) = sum(idx);
    end
    A = cellstr(char(stateNames'));
    B = cellstr(char(num2str(fix(stateTimes))));
    C = cellstr(char(num2str(epNum)));
    statStr = strcat({' : '},B,{' s ('},C,{' ep)'});
    statStr = [char(A) char(statStr)];
    set(handles.stat_text,'String',statStr)


% update movement plot
function plotMovementData(handles)
    fprintf('Plotting Movement Data...\n')
    dat = getappdata(handles.figure1,'InputData');
    ph = getappdata(handles.figure1,'movement_handles');
    delete(ph)
    vel = dat.velocity;
    velT = dat.vel_time;
    emg = dat.emg_power;
    emgT = dat.emg_time;
    ph = gobjects(2,1);
    axes(handles.ep_ax)
    yyaxis left
    ph(1) = plot(velT,vel,'LineWidth',2);
    ylim([-1 30])
    ylabel('Velocity (cm/s)')
    ylabel('Time (s)')
    yyaxis right
    ph(2) = plot(emgT,emg,'LineWidth',2);
    ylabel('EMG Amplitude (Z)')
    ylim([-2 7])
    yyaxis left


% update state coloring
function updateStateColoring(handles)
    fprintf('Plotting State Patches...\n')
    patchHandles = getappdata(handles.figure1,'patchHandles');
    if ~isempty(patchHandles)
        delete(patchHandles)
    end
    axes(handles.ep_ax)
    yyaxis left
    stateMat = getappdata(handles.figure1,'currentStateMat');
    stateColors = getappdata(handles.figure1,'stateColors');
    ph = createColoredBackgroundPatches(stateMat(:,1:2),stateMat(:,3),stateColors);
    setappdata(handles.figure1,'patchHandles',ph)

% Plot/Update CWT pspectrogram
function plotSpectrogram(handles)
    fprintf('Plotting Spectrogram...\n')
    dat = getappdata(handles.figure1,'InputData');
    tetIdx = get(handles.tet_pop,'Value');
    S = dat.specgram{tetIdx};
    [~,maxZero] = max(sum(S<0));
    specFreq = dat.spec_freq;
    specFreq = specFreq(S(:,maxZero)>0);
    S = S(S(:,maxZero)>0,:);
    lPSD = 10*log10(S);
    zlPSD = zscore(lPSD,0,2);
    fzlPSD = imgaussfilt(zlPSD,2);
    axes(handles.spec_ax)
    imagesc(dat.spec_time,specFreq,fzlPSD)
    set(gca,'ydir','normal')
    if ~isempty(which('magma'))
        colormap(magma)
    else
        colormap(jet)
    end
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')


% update window edges
function makeWindowLines(handles)
    fprintf('Plotting Window Lines...\n')
    set(handles.figure1,'pointer','watch')
    sT = getappdata(handles.figure1,'scatter_time');
    ph = getappdata(handles.figure1,'lightEdges');
    if ~isempty(ph)
        delete(ph);
        drawnow;
    end
    ph = gobjects(1,2);
    ylA = get(handles.ep_ax,'YLim');
    ylB = get(handles.spec_ax,'YLim');
    axes(handles.ep_ax)
    hold on
    ph(1) = plot(sT(1:end-1,2),ones(size(sT,1)-1,1)*ylA(1),'k^','LineWidth',2);
    axes(handles.spec_ax)
    hold on
    ph(2) = plot(sT(1:end-1,2),ones(size(sT,1)-1,1)*ylB(1),'k^','LineWidth',2);
    setappdata(handles.figure1,'lightEdges',ph);
    set(handles.figure1,'pointer','arrow')


% Move plots to current window
function setCurrentWindow(handles)
    tMat = getappdata(handles.figure1,'scatter_time');
    idx = getappdata(handles.figure1,'currentIdx');
    dispSize = getappdata(handles.figure1,'displaySize');
    if abs(diff(tMat(idx,:)))>=dispSize
        xlim = tMat(idx,:) + [-60 60]; % show 1  minute on each side of episode
    else
        xlim = mean(tMat(idx,:)) + [-.5 .5]*dispSize;
    end
    set(handles.ep_ax,'XLim',xlim)
    set(handles.spec_ax,'XLim',xlim)

    % Make moving thick lines for adjusting episodes
    eh = getappdata(handles.figure1,'episodeEdgeHandles');
    if ~isempty(eh)
        delete(eh)
    end
    ph = gobjects(2,1);
    if get(handles.episode_radio,'Value')==1
        yl = get(handles.ep_ax,'YLim');
        axes(handles.ep_ax)
        hold on
        ph(1) = plot([1 1]*tMat(idx,1),yl,'k-','LineWidth',2,'ButtonDownFcn',@(src,event)stateValidationGUI('border_press_Callback',src,event,guidata(src),1));
        ph(2) = plot([1 1]*tMat(idx,2),yl,'k-','LineWidth',2,'ButtonDownFcn',@(src,event)stateValidationGUI('border_press_Callback',src,event,guidata(src),2));
    else
        yl = get(handles.ep_ax,'Ylim');
        axes(handles.ep_ax)
        hold on
        ph = plot(tMat(idx,:),[1 1]*yl(1),'r^','LineWidth',3);
    end
    setappdata(handles.figure1,'episodeEdgeHandles',ph)


% --------------------------------------------------------------------
function open_menu_Callback(hObject, eventdata, handles)
% hObject    handle to open_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Use animal_database to pull up list of animals, days and epochs to choose
% from, then load the data from  those
dbPath = '~/Projects/rn_Schizophrenia_Project/metadata/animal_metadata.mat';
if ~exist(dbPath,'file')
    [a,b] = uigetfile('*.mat','Select Animal Database');
    dbPath = [b a];
end
animDB = load(dbPath);
animDB = animDB.animDB;
animals = {animDB.animal};
tmp = ListSelectGUI(animals,'Choose Animal');
anim = animals(tmp);
recDat = anim.recording_data;
if isempty(recDat)
    msgbox('No Recording Data for animal')
    return;
end
days = arrayfun(@(x) sprintf('Day %02i',x),[recDat.day],'UniformOutput',false);
tmp2 = ListSelectGUI(days,'Choose Recording Day');
rD = recDat(tmp2);
epoStruct = rD.epochs;
epoLabels = cellfun(@(x,y) sprintf('%02i: %s',x,y),num2cell([epoStruct.epoch]),{epoStruct.epoch_type},'UniformOutput',false);
tmp3 = ListSelectGUI(epoLabels,'Choose Epoch');
%TODO: Add load functionality
dat = getStateValidationData(anim.animal,tmp2,tmp3);
init(dat,handles,getappdata(handles.figure1,'init_varargin'))

function winSize_edit_Callback(hObject, eventdata, handles)
    % hObject    handle to winSize_edit (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    winStr = get(hObject,'String');
    winSize = str2double(winStr);
    if isempty(winSize)
        errordlg('Please enter a valid number for window size in seconds')
        set(hObject,'String',num2str(getappdata(handles.figure1,'winSize')))
        return;
    end
    setappdata(handles.figure1,'winSize',winSize)
    makeWindowLines(handles)
    plotScatter(handles)


% --- Executes during object creation, after setting all properties.
function winSize_edit_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to winSize_edit (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in episode_radio.
function episode_radio_Callback(hObject, eventdata, handles)
    % hObject    handle to episode_radio (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    set(handles.winSize_edit,'enable','off')
    set(handles.edit_panel,'Visible','on')
    stateMat = getappdata(handles.figure1,'currentStateMat');
    idx = getappdata(handles.figure1,'currentIdx');
    tMat = getappdata(handles.figure1,'scatter_time');
    setappdata(handles.figure1,'scatter_time',stateMat(:,1:2))
    tNow = mean(tMat(idx,:));
    tmp = find(stateMat(:,1)<=tNow & stateMat(:,2)>=tNow);
    setappdata(handles.figure1,'currentIdx',tmp)
    set(handles.ep_edit,'String',num2str(tmp))
    set(handles.total_text,'String',['/  ' num2str(size(stateMat,1))])
    makeWindowLines(handles)
    plotScatter(handles)



% --- Executes on button press in window_radio.
function window_radio_Callback(hObject, eventdata, handles)
    % hObject    handle to window_radio (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    set(handles.winSize_edit,'enable','on')
    set(handles.edit_panel,'visible','off')
    inputData = getappdata(handles.figure1,'InputData');
    idx = getappdata(handles.figure1,'currentIdx');
    tMat = getappdata(handles.figure1,'scatter_time');
    tNow = mean(tMat(idx,:));
    winSize = getappdata(handles.figure1,'winSize');
    tStart = inputData.spec_time(1);
    tEnd = inputData.spec_time(end);
    scatterTime = [(tStart:winSize:tEnd-winSize)' (tStart+winSize:winSize:tEnd)'];
    setappdata(handles.figure1,'scatter_time',scatterTime);
    tmp = find(scatterTime(:,1)<=tNow & scatterTime(:,2)>=tNow);
    setappdata(handles.figure1,'currentIdx',tmp);
    set(handles.ep_edit,'String',num2str(tmp));
    set(handles.total_text,'String',['/  ' num2str(size(scatterTime,1))])

    makeWindowLines(handles)
    plotScatter(handles)



% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    L = getappdata(handles.figure1,'movingLine');
    if isempty(L)
        return;
    end
    cp = get(gca,'CurrentPoint');
    inDat = getappdata(handles.figure1,'InputData');
    emgTime = inDat.emg_time;
    if cp(1,1)<=emgTime(1)
        lineX = emgTime(1);
    elseif cp(1,1)>=emgTime(end)
        lineX = emgTime(end);
    else
        lineX = cp(1,1);
    end
    set(L,'XData',[lineX lineX])


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    N = getappdata(handles.figure1,'movingLineNum');
    L = getappdata(handles.figure1,'movingLine');
    PC = getappdata(handles.figure1,'pointClicked');
    if PC
        setappdata(handles.figure1,'pointClicked',0)
        return;
    end
    if isempty(L) || get(handles.episode_radio,'Value')~=1
        return;
    end
    stateMat = getappdata(handles.figure1,'currentStateMat');
    idx = getappdata(handles.figure1,'currentIdx');
    newX = get(L,'XData');
    newX = newX(1);
    epEnd = find(stateMat(:,1)<=newX & stateMat(:,2)>=newX);
    if N==1
        stateMat(epEnd,2) = newX;
        stateMat(idx,1) = newX;
        if idx-epEnd>1
            stateMat(epEnd+1:idx-1,:) = [];
        end
    elseif N==2
        stateMat(epEnd,1) = newX;
        stateMat(idx,2) = newX;
        if epEnd-idx>1
            stateMat(idx+1:epEnd-1,:) = [];
        end
    elseif N==3 % create new episode break
        setappdata(handles.figure1,'movingLine',[])
        return;
    end
    stateMat = stitchStates(stateMat);
    setappdata(handles.figure1,'currentStateMat',stateMat)
    setappdata(handles.figure1,'movingLine',[])
    drawnow;
    updateStateColoring(handles)
    plotScatter(handles)
    makeWindowLines(handles)
    updateStats(handles)


% --- Executes on button press in transition_push.
function transition_push_Callback(hObject, eventdata, handles)
    % hObject    handle to transition_push (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    newState = find(strcmpi(getappdata(handles.figure1,'stateNames'),'Transition'));
    changeCurrentState(handles,newState)


function stateMat = stitchStates(stateMat)
    idx = find(stateMat(1:end-1,2)==stateMat(2:end,1) & stateMat(1:end-1,3)==stateMat(2:end,3));
    SM = stateMat;
    for k=numel(idx):-1:1
        SM(idx(k),2) = SM(idx(k)+1,2);
        SM(idx(k)+1,:) = [];
    end
    stateMat = SM;
    %setappdata(handles.figure1,'currentStateMat',stateMat)
    %updateStateColoring(handles)
    %plotScatter(handles)
    %makeWindowLines(handles)
    %updateStats(handles)

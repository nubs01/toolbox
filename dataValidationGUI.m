function varargout = dataValidationGUI(varargin)
    % dataValidationGUI(X,Y,validationIdx,winSize) if Y is a multicolumn matrix
    % then each column will be plotted on its own line (as with
    % stackedTracePlot). validationIdx should be a 2-colun matrix with start
    % and end times (in units of X) of the periods to be accepted or rejected.
    % winSize is in units of X. This will return validationIdx minus any
    % rejected periods. Primarily designed to be used to validate automatically
    % detected artifacts in EEG data. 
% DATAVALIDATIONGUI MATLAB code for dataValidationGUI.fig
%      DATAVALIDATIONGUI, by itself, creates a new DATAVALIDATIONGUI or raises the existing
%      singleton*.
%
%      H = DATAVALIDATIONGUI returns the handle to a new DATAVALIDATIONGUI or the handle to
%      the existing singleton*.
%
%      DATAVALIDATIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATAVALIDATIONGUI.M with the given input arguments.
%
%      DATAVALIDATIONGUI('Property','Value',...) creates a new DATAVALIDATIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dataValidationGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dataValidationGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dataValidationGUI

% Last Modified by GUIDE v2.5 02-Jul-2018 14:24:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dataValidationGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @dataValidationGUI_OutputFcn, ...
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


% --- Executes just before dataValidationGUI is made visible.
function dataValidationGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dataValidationGUI (see VARARGIN)

XDat = varargin{1};
YDat = varargin{2};
valTimes = varargin{3};
winSize = varargin{4};
nVal = size(valTimes,1);

setappdata(hObject,'XDat',XDat)
setappdata(hObject,'YDat',YDat)
setappdata(hObject,'valTimes',valTimes)
setappdata(hObject,'winSize',winSize)
setappdata(hObject,'nVal',nVal)
setappdata(hObject,'currVal',1)
setappdata(hObject,'backupValTimes',valTimes)
setappdata(hObject,'highlightH',[])
setappdata(hObject,'plotH',[])

plotTraces(handles)
plotHighlight(handles)
centerPlot(handles)

% Set up steps & loc_edit & loc_text
% Backup data for undo and reset
set(handles.loc_edit,'String',1)
set(handles.loc_text,'String',['/  ' num2str(nVal))

% Choose default command line output for dataValidationGUI
handles.output = valTimes;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes dataValidationGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = dataValidationGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in prev_push.
function prev_push_Callback(hObject, eventdata, handles)
% hObject    handle to prev_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in next_push.
function next_push_Callback(hObject, eventdata, handles)
% hObject    handle to next_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function loc_edit_Callback(hObject, eventdata, handles)
% hObject    handle to loc_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of loc_edit as text
%        str2double(get(hObject,'String')) returns contents of loc_edit as a double


% --- Executes during object creation, after setting all properties.
function loc_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loc_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reject_push.
function reject_push_Callback(hObject, eventdata, handles)
% hObject    handle to reject_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in done_push.
function done_push_Callback(hObject, eventdata, handles)
% hObject    handle to done_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in undo_push.
function undo_push_Callback(hObject, eventdata, handles)
% hObject    handle to undo_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reset_push.
function reset_push_Callback(hObject, eventdata, handles)
% hObject    handle to reset_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%


function plotTraces(handles)
    X = getappdata(handles.figure1,'XDat');
    Y = getappdata(handles.figure1,'YDat');

    if all(size(Y)>1)
        Y2 = Y./(max(max(abs(Y)))) + (0:2:(size(Y,2)-1)*2;
    else
        Y2 = Y;
    end
    setappdata(handles.figure1,'Y2',Y2)
    plotH = plot(handles.plot_ax,X,Y2,'k','LineWidth',2);
    setappdata(handles.figure1,'plotH',plotH)

function plotHighlight(handles)
    prevH = getappdata(handles.figure1,'highlightH');
    if ~isempty(prevH)
        delete(prevH)
    end
    vT = getappdata(handles.figure1,'valTimes');
    X = getappdata(handles.figure1,'XDat');
    Y = getappdata(handles.figure1,'YDat');
    h = [];
    for l=1:size(vT,1)
        axes(handles.plot_ax)
        hold on
        a = find(X>=vT(l,1),1,'first');
        b = find(X<=vT(l,2),1,'last');
        tmp = plot(X(a:b),Y(a:b,:),'r','LineWidth',2);
        h = [h tmp];
    end
    setappdata(handles.figure1,'highlightH',h)

function centerPlot(handles)
    n = getappdata(handles.figure1,'currVal');
    vT = getappdata(handles.figure1,'valTimes');
    X = getappdata(handles.figure1,'XDat');
    v = vT(n,:);
    wS = getappdata(handles.figure1,'winSize');
    if diff(v) >= wS
        set(handles.plot_ax,'XLim',v+[-1 1])
    else
        v2 = mean(v) + [-winSize winSize]/2;
        set(handles.plot_ax,'XLim',v2)
    end




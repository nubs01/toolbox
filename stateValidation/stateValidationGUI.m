function varargout = stateValidationGUI(varargin)
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

% Last Modified by GUIDE v2.5 19-Jul-2018 12:57:51

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
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes stateValidationGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


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
varargout{1} = handles.output;


% --- Executes on selection change in y_pop.
function y_pop_Callback(hObject, eventdata, handles)
% hObject    handle to y_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns y_pop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from y_pop


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

% Hints: contents = cellstr(get(hObject,'String')) returns tet_pop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tet_pop


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

% Hints: contents = cellstr(get(hObject,'String')) returns x_pop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from x_pop


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


% --- Executes on button press in set_push.
function set_push_Callback(hObject, eventdata, handles)
% hObject    handle to set_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reset_push.
function reset_push_Callback(hObject, eventdata, handles)
% hObject    handle to reset_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in done_push.
function done_push_Callback(hObject, eventdata, handles)
% hObject    handle to done_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function ep_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ep_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ep_edit as text
%        str2double(get(hObject,'String')) returns contents of ep_edit as a double


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


% --- Executes on button press in prev_push.
function prev_push_Callback(hObject, eventdata, handles)
% hObject    handle to prev_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in nrem_push.
function nrem_push_Callback(hObject, eventdata, handles)
% hObject    handle to nrem_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rest_push.
function rest_push_Callback(hObject, eventdata, handles)
% hObject    handle to rest_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in move_push.
function move_push_Callback(hObject, eventdata, handles)
% hObject    handle to move_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in art_push.
function art_push_Callback(hObject, eventdata, handles)
% hObject    handle to art_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rem_push.
function rem_push_Callback(hObject, eventdata, handles)
% hObject    handle to rem_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Plot scatter plot
function  plot_scatter(handles)

% react to clicking on a point in the scatter plot
function point_push_Callback(hObject,handles)

% react to clicking a line
function border_buttonDown_Callback(hObject,handles)

% react to sliding a line
function border_mouseMove_Callback(hObject,handles)

% react to letting go of a line
function border_buttonUp_Ballback(hObject,handles)

% update statistics box
function updateStats(handles)


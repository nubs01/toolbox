function h = addFigureStepper(fig,X,winSize,stepSize)
% Shirks xlim of a figure to winSize and adds next and prev push buttons to
% step thorugh a large dataset. Default stepSize is 1 window, but can be
% changed. winSize and stepSize are in units of X
if ~exist('stepSize','var')
    stepSize = winSize;
end
setappdata(fig,'currentX',X(1))
setappdata(fig,'stepSize',stepSize)
setappdata(fig,'winSize',winSize)
setappdata(fig,'xMax',X(end))
setappdata(fig,'xMin',X(1))


nextPush = uicontrol(fig,'style','pushbutton','string','>>','Units','pixels','Position',[60 10 40 20],'Callback',@figStepper_nextPush_Callback);
prevPush = uicontrol(fig,'style','pushbutton','string','<<','Units','pixels','Position',[10 10 40 20],'Callback',@figStepper_prevPush_Callback);
set(gca,'XLim',[X(1) X(1)+winSize])
h = {nextPush,prevPush};


function figStepper_nextPush_Callback(hObject,eventdata)
    currX = getappdata(hObject.Parent,'currentX');
    step = getappdata(hObject.Parent,'stepSize');
    winSize = getappdata(hObject.Parent,'winSize');
    xMax = getappdata(hObject.Parent,'xMax');
    newX = [currX+step currX+step+winSize-1];
    if ~all(newX<=xMax)
        newX = [xMax-winSize+1 xMax];
    end
    set(gca,'XLim',newX)
    setappdata(hObject.Parent,'currentX',newX(1))
    
function figStepper_prevPush_Callback(hObject,eventdata)
    currX = getappdata(hObject.Parent,'currentX');
    step = getappdata(hObject.Parent,'stepSize');
    winSize = getappdata(hObject.Parent,'winSize');
    xMin = getappdata(hObject.Parent,'xMin');
    newX = [currX-step currX-step+winSize-1];
    if ~all(newX>=xMin)
        newX = [xMin xMin+winSize-1];
    end
    set(gca,'XLim',newX)
    setappdata(hObject.Parent,'currentX',newX(1))
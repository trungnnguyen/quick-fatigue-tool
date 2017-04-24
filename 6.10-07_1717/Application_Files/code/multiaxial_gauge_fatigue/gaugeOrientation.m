function varargout = gaugeOrientation(varargin)
%GAUGEORIENTATION    QFT functions for Multiaxial Gauge Fatigue.
%   These functions contain methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   GAUGEORIENTATION is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also multiaxialAnalysis, multiaxialPostProcess,
%   multiaxialPreProcess, materialOptions, MultiaxialFatigue.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.2 Multiaxial Gauge Fatigue
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 12-Apr-2017 12:25:20 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gaugeOrientation_OpeningFcn, ...
                   'gui_OutputFcn',  @gaugeOrientation_OutputFcn, ...
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


% --- Executes just before gaugeOrientation is made visible.
function gaugeOrientation_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gaugeOrientation (see VARARGIN)

% Position the GUI in the centre of the screen
movegui(hObject, 'center')

% Choose default command line output for gaugeOrientation
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gaugeOrientation wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Load the tips icon
[a,~]=imread('icoR_bulb.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_diagram, 'CData', g);

% Restore panel state
if isappdata(0, 'gaugeOrientation_rButton_rectangular') == 1.0
    set(handles.rButton_rectangular, 'value', getappdata(0, 'gaugeOrientation_rButton_rectangular'))
    set(handles.rButton_delta, 'value', getappdata(0, 'gaugeOrientation_rButton_delta'))
    set(handles.rButton_user, 'value', getappdata(0, 'gaugeOrientation_rButton_user'))
    
    set(handles.edit_alpha, 'string', getappdata(0, 'gaugeOrientation_edit_alpha'))
    set(handles.edit_beta, 'string', getappdata(0, 'gaugeOrientation_edit_beta'))
    set(handles.edit_gamma, 'string', getappdata(0, 'gaugeOrientation_edit_gamma'))
end

if get(handles.rButton_user, 'value') == 1.0
    set(handles.text_alpha, 'enable', 'on')
    set(handles.text_beta, 'enable', 'on')
    set(handles.text_gamma, 'enable', 'on')
    set(handles.edit_alpha, 'enable', 'on')
    set(handles.edit_beta, 'enable', 'on')
    set(handles.edit_gamma, 'enable', 'on')
    set(handles.text_unitsAlpha, 'enable', 'on')
    set(handles.text_unitsBeta, 'enable', 'on')
    set(handles.text_unitsGamma, 'enable', 'on')
end


% --- Outputs from this function are returned to the command line.
function varargout = gaugeOrientation_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~) %#ok<*DEFNU>
close gaugeOrientation


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

% Initialize the error variable
error = 0.0;

% Check the validity of the angles
if get(handles.rButton_user, 'value') == 1.0
    alpha = str2double(get(handles.edit_alpha, 'string'));
    
    if isempty(get(handles.edit_alpha, 'string')) == 1.0
        error = 1.0;
        errorMessage = 'Please specify a value of Alpha.';
    elseif (isnumeric(alpha) == 0.0) || (isinf(alpha) == 1.0) || (isnan(alpha) == 1.0)
        error = 1.0;
        errorMessage = 'An invalid Alpha value was specified.';
    elseif (alpha < 0.0) || (alpha >= 180.0)
        error = 1.0;
        errorMessage = 'Alpha must be in the range (0 <= Alpha < 180).';
    end
    
    if error == 1.0
        errordlg(errorMessage, 'Quick Fatigue Tool')
        uiwait
        enable(handles)
        return
    end
    
    beta = str2double(get(handles.edit_beta, 'string'));
    
    if isempty(get(handles.edit_beta, 'string')) == 1.0
        error = 1.0;
        errorMessage = 'Please specify a value of Beta.';
    elseif (isnumeric(beta) == 0.0) || (isinf(beta) == 1.0) || (isnan(beta) == 1.0)
        error = 1.0;
        errorMessage = 'An invalid Beta value was specified.';
    elseif (beta <= 0.0) || (beta >= 180.0)
        error = 1.0;
        errorMessage = 'Beta must be in the range (0 < Beta < 180).';
    end
    
    if error == 1.0
        errordlg(errorMessage, 'Quick Fatigue Tool')
        uiwait
        enable(handles)
        return
    end
    
    gamma = str2double(get(handles.edit_gamma, 'string'));
    
    if isempty(get(handles.edit_gamma, 'string')) == 1.0
        error = 1.0;
        errorMessage = 'Please specify a value of Gamma.';
    elseif (isnumeric(gamma) == 0.0) || (isinf(gamma) == 1.0) || (isnan(gamma) == 1.0)
        error = 1.0;
        errorMessage = 'An invalid Gamma value was specified.';
    elseif (gamma <= 0.0) || (gamma >= 180.0)
        error = 1.0;
        errorMessage = 'Gamma must be in the range (0 < Gamma < 180).';
    end
    
    if (alpha + beta + gamma) > 360.0
        error = 1.0;
        errorMessage = 'The total angle (Alpha + Beta + Gamma) must not exceed 360 degrees.';
    end
    
    if error == 1.0
        errordlg(errorMessage, 'Quick Fatigue Tool')
        uiwait
        enable(handles)
        return
    end
    
    setappdata(0, 'multiaxialFatigue_alpha', alpha)
    setappdata(0, 'multiaxialFatigue_beta', beta)
    setappdata(0, 'multiaxialFatigue_gamma', gamma)
elseif get(handles.rButton_rectangular, 'value') == 1.0
    setappdata(0, 'multiaxialFatigue_alpha', 0.0)
    setappdata(0, 'multiaxialFatigue_beta', 45.0)
    setappdata(0, 'multiaxialFatigue_gamma', 45.0)
else
    setappdata(0, 'multiaxialFatigue_alpha', 30.0)
    setappdata(0, 'multiaxialFatigue_beta', 60.0)
    setappdata(0, 'multiaxialFatigue_gamma', 60.0)
end

% Save the GUI state
setappdata(0, 'gaugeOrientation_rButton_rectangular', get(handles.rButton_rectangular, 'value'))
setappdata(0, 'gaugeOrientation_rButton_delta', get(handles.rButton_delta, 'value'))
setappdata(0, 'gaugeOrientation_rButton_user', get(handles.rButton_user, 'value'))

setappdata(0, 'gaugeOrientation_edit_alpha', get(handles.edit_alpha, 'string'))
setappdata(0, 'gaugeOrientation_edit_beta', get(handles.edit_beta, 'string'))
setappdata(0, 'gaugeOrientation_edit_gamma', get(handles.edit_gamma, 'string'))

close gaugeOrientation



function edit_gamma_Callback(~, ~, ~)
% hObject    handle to edit_gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gamma as text
%        str2double(get(hObject,'String')) returns contents of edit_gamma as a double


% --- Executes during object creation, after setting all properties.
function edit_gamma_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_beta_Callback(~, ~, ~)
% hObject    handle to edit_beta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_beta as text
%        str2double(get(hObject,'String')) returns contents of edit_beta as a double


% --- Executes during object creation, after setting all properties.
function edit_beta_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_beta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_alpha_Callback(~, ~, ~)
% hObject    handle to edit_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_alpha as text
%        str2double(get(hObject,'String')) returns contents of edit_alpha as a double


% --- Executes during object creation, after setting all properties.
function edit_alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_diagram.
function pButton_diagram_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

if get(handles.rButton_rectangular, 'value') == 1.0
    setappdata(0, 'gaugeDiagram', 1.0)
elseif get(handles.rButton_delta, 'value') == 1.0
    setappdata(0, 'gaugeDiagram', 2.0)
else
    setappdata(0, 'gaugeDiagram', 3.0)
end

RosetteDiagram
uiwait

% Re-enable the GUI
enable(handles)


function blank(handles)
set(handles.rButton_rectangular, 'enable', 'off')
set(handles.rButton_delta, 'enable', 'off')
set(handles.rButton_user, 'enable', 'off')
set(handles.pButton_diagram, 'enable', 'off')

set(handles.text_alpha, 'enable', 'off')
set(handles.text_beta, 'enable', 'off')
set(handles.text_gamma, 'enable', 'off')
set(handles.edit_alpha, 'enable', 'off')
set(handles.edit_beta, 'enable', 'off')
set(handles.edit_gamma, 'enable', 'off')
set(handles.text_unitsAlpha, 'enable', 'off')
set(handles.text_unitsBeta, 'enable', 'off')
set(handles.text_unitsGamma, 'enable', 'off')

set(handles.pButton_ok, 'enable', 'off')
set(handles.pButton_cancel, 'enable', 'off')


function enable(handles)
set(handles.rButton_rectangular, 'enable', 'on')
set(handles.rButton_delta, 'enable', 'on')
set(handles.rButton_user, 'enable', 'on')
set(handles.pButton_diagram, 'enable', 'on')

if get(handles.rButton_user, 'value') == 1.0
    set(handles.text_alpha, 'enable', 'on')
    set(handles.text_beta, 'enable', 'on')
    set(handles.text_gamma, 'enable', 'on')
    set(handles.edit_alpha, 'enable', 'on')
    set(handles.edit_beta, 'enable', 'on')
    set(handles.edit_gamma, 'enable', 'on')
    set(handles.text_unitsAlpha, 'enable', 'on')
    set(handles.text_unitsBeta, 'enable', 'on')
    set(handles.text_unitsGamma, 'enable', 'on')
end

set(handles.pButton_ok, 'enable', 'on')
set(handles.pButton_cancel, 'enable', 'on')


% --- Executes when selected object is changed in panel_layout.
function panel_layout_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_rectangular'
        set(handles.text_alpha, 'enable', 'off')
        set(handles.text_beta, 'enable', 'off')
        set(handles.text_gamma, 'enable', 'off')
        set(handles.edit_alpha, 'enable', 'off')
        set(handles.edit_beta, 'enable', 'off')
        set(handles.edit_gamma, 'enable', 'off')
        set(handles.text_unitsAlpha, 'enable', 'off')
        set(handles.text_unitsBeta, 'enable', 'off')
        set(handles.text_unitsGamma, 'enable', 'off')
    case 'rButton_delta'
        set(handles.text_alpha, 'enable', 'off')
        set(handles.text_beta, 'enable', 'off')
        set(handles.text_gamma, 'enable', 'off')
        set(handles.edit_alpha, 'enable', 'off')
        set(handles.edit_beta, 'enable', 'off')
        set(handles.edit_gamma, 'enable', 'off')
        set(handles.text_unitsAlpha, 'enable', 'off')
        set(handles.text_unitsBeta, 'enable', 'off')
        set(handles.text_unitsGamma, 'enable', 'off')
    case 'rButton_user'
        set(handles.text_alpha, 'enable', 'on')
        set(handles.text_beta, 'enable', 'on')
        set(handles.text_gamma, 'enable', 'on')
        set(handles.edit_alpha, 'enable', 'on')
        set(handles.edit_beta, 'enable', 'on')
        set(handles.edit_gamma, 'enable', 'on')
        set(handles.text_unitsAlpha, 'enable', 'on')
        set(handles.text_unitsBeta, 'enable', 'on')
        set(handles.text_unitsGamma, 'enable', 'on')
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

function varargout = kSolution(varargin)%#ok<*DEFNU>
%KSOLUTION    QFT functions to derive normal stress sensitivity
%constant.
%   These functions derive the normal stress sensitivity constant (k) based
%   on material parameters.
%   
%   KSOLUTION is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also evaluateMaterial, MaterialManager, UserMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%      6.4 Findley's Method
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @kSolution_OpeningFcn, ...
                   'gui_OutputFcn',  @kSolution_OutputFcn, ...
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


% --- Executes just before kSolution is made visible.
function kSolution_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to kSolution (see VARARGIN)

clc

% Choose default command line output for kSolution
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% Define SIMULIA blue color
blue = [177/255, 206/255, 237/255];
grey = [241/255, 241/255, 241/255];
setappdata(0, 'simulia_blue', blue)
setappdata(0, 'grey', grey)

% Restore panel state
if isappdata(0, 'k_solution_model')
    set(handles.pMenu_solution, 'value', getappdata(0, 'k_solution_model'))
    
    switch getappdata(0, 'k_solution_model')
        case 1
        case 2
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'on', 'BackgroundColor', 'White')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
        case 3
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
        case 4
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'on');    set(handles.edit_uts, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_uts, 'enable', 'on')
        case 5
            set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
            set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
            set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
            set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    end
end

if isappdata(0, 'k_solution_r')
    set(handles.edit_r, 'string', getappdata(0, 'k_solution_r'))
end
if isappdata(0, 'k_solution_fi')
    set(handles.edit_fi, 'string', getappdata(0, 'k_solution_fi'))
end
if isappdata(0, 'k_solution_t')
    set(handles.edit_t, 'string', getappdata(0, 'k_solution_t'))
end
if isappdata(0, 'k_solution_uts') && get(handles.pMenu_solution, 'value') == 4
    set(handles.edit_uts, 'string', getappdata(0, 'k_solution_uts'))
end

% UIWAIT makes kSolution wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = kSolution_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in pMenu_solution.
function pMenu_solution_Callback(hObject, ~, handles)
blue = getappdata(0, 'simulia_blue');
grey = getappdata(0, 'grey');
switch get(hObject, 'Value')
    case 1 % Default
        set(handles.text_r, 'enable', 'off');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', grey)
        set(handles.text_fi, 'enable', 'off');    set(handles.edit_fi, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_fi, 'enable', 'off')
        set(handles.text_t, 'enable', 'off');    set(handles.edit_t, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_t, 'enable', 'off')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 2 % General formula
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'on', 'BackgroundColor', 'White')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 3 % Dang van
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
    case 4 % Sines
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'on');    set(handles.edit_uts, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_uts, 'enable', 'on')
        
        set(handles.edit_uts, 'string', getappdata(0, 'k_solution_uts'))
    case 5 % Crossland
        set(handles.text_r, 'enable', 'on');    set(handles.edit_r, 'enable', 'inactive', 'BackgroundColor', blue, 'String', '-1')
        set(handles.text_fi, 'enable', 'on');    set(handles.edit_fi, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_fi, 'enable', 'on')
        set(handles.text_t, 'enable', 'on');    set(handles.edit_t, 'enable', 'on', 'BackgroundColor', 'White');  set(handles.text_units_t, 'enable', 'on')
        set(handles.text_uts, 'enable', 'off');    set(handles.edit_uts, 'enable', 'inactive', 'BackgroundColor', grey);  set(handles.text_units_uts, 'enable', 'off')
end


% --- Executes during object creation, after setting all properties.
function pMenu_solution_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_solution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_r_Callback(~, ~, ~)
% hObject    handle to edit_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_r as text
%        str2double(get(hObject,'String')) returns contents of edit_r as a double


% --- Executes during object creation, after setting all properties.
function edit_r_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_fi_Callback(~, ~, ~)
% hObject    handle to edit_fi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fi as text
%        str2double(get(hObject,'String')) returns contents of edit_fi as a double


% --- Executes during object creation, after setting all properties.
function edit_fi_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_fi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_t_Callback(~, ~, ~)
% hObject    handle to edit_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_t as text
%        str2double(get(hObject,'String')) returns contents of edit_t as a double


% --- Executes during object creation, after setting all properties.
function edit_t_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_uts_Callback(~, ~, ~)
% hObject    handle to edit_uts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_uts as text
%        str2double(get(hObject,'String')) returns contents of edit_uts as a double


% --- Executes during object creation, after setting all properties.
function edit_uts_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_uts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_fMinus1_Callback(~, ~, ~)
% hObject    handle to edit_fMinus1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fMinus1 as text
%        str2double(get(hObject,'String')) returns contents of edit_fMinus1 as a double


% --- Executes during object creation, after setting all properties.
function edit_fMinus1_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_fMinus1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_solve.
function pButton_solve_Callback(hObject, eventdata, handles)
set(handles.pButton_solve, 'enable', 'off');

% Check validity of inputs
error = 0.0;

if strcmpi(get(handles.edit_r, 'enable'), 'on')
    r = str2double(get(handles.edit_r, 'String'));
    
    if isnumeric(r) == 0.0
        error = 1.0;
    elseif isnan(r) || isinf(r) || isempty(r)
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_fi, 'enable'), 'on')
    fi = str2double(get(handles.edit_fi, 'String'));
    
    if isnumeric(fi) == 0.0
        error = 1.0;
    elseif isnan(fi) || isinf(fi) || isempty(fi)
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_uts, 'enable'), 'on')
    uts = str2double(get(handles.edit_uts, 'String'));
    
    if isnumeric(uts) == 0.0
        error = 1.0;
    elseif isnan(uts) || isinf(uts) || isempty(uts)
        error = 1.0;
    end
end
if strcmpi(get(handles.edit_t, 'enable'), 'on')
    t = str2double(get(handles.edit_t, 'String'));
    
    if isnumeric(t) == 0.0
        error = 1.0;
    elseif isnan(t) || isinf(t) || isempty(t)
        error = 1.0;
    end
end

if error == 1.0
    errordlg('One or more inputs contain a syntax error.', 'Quick Fatigue Tool')
    uiwait
    set(handles.pButton_solve, 'enable', 'on')
    return
end

% Disable the GUI
disableGUI(hObject, eventdata, handles)

pause(1e-6)

% Solve for k
switch get(handles.pMenu_solution, 'Value')
    case 1.0
        % Save panel state
        setappdata(0, 'k_solution_model', get(handles.pMenu_solution, 'value'))
        setappdata(0, 'k_solution_r', get(handles.edit_r, 'string'))
        setappdata(0, 'k_solution_fi', get(handles.edit_fi, 'string'))
        setappdata(0, 'k_solution_t', get(handles.edit_t, 'string'))
        setappdata(0, 'k_solution_uts', get(handles.edit_uts, 'string'))
        
        setappdata(0, 'k_solution', 0.2857)
        setappdata(0, 'updateKValue', 1)
        close kSolution
        return
    case 2.0
        syms k
        eqn = (fi/t) == (2*sqrt(1 + k^2))/(sqrt(((2*k)/(1-r))^2 + 1) + ((2*k)/(1-r)));
        solk = eval(solve(eqn, k)); clc
    case 3.0
        solk = ((3*t)/(fi)) - (3/2);
    case 4.0
        solk = ((3*t*(uts + fi))/(uts*fi)) - sqrt(6);
    case 5.0
        solk = ((3*t)/(fi)) - sqrt(3);
end

if isempty(solk) == 1.0
    errordlg('An explicit solution for the specified properties could not be found.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enableGUI(hObject, eventdata, handles)
    
    return
elseif isreal(solk) == 0.0
    errordlg('The calculated solution is complex.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enableGUI(hObject, eventdata, handles)
    
    return
elseif isnan(solk) == 1.0
    errordlg('The calculated solution is NaN.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enableGUI(hObject, eventdata, handles)
    
    return
elseif isinf(solk) == 1.0
    errordlg('The calculated solution is infinite.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enableGUI(hObject, eventdata, handles)
    
    return
elseif solk < 0.0
    errordlg('The calculated solution is negative.', 'Quick Fatigue Tool')
    
    uiwait
    % Enable the GUI
    enableGUI(hObject, eventdata, handles)
    
    return
else
    % Save panel state
    setappdata(0, 'k_solution_model', get(handles.pMenu_solution, 'value'))
    setappdata(0, 'k_solution_r', get(handles.edit_r, 'string'))
    setappdata(0, 'k_solution_fi', get(handles.edit_fi, 'string'))
    setappdata(0, 'k_solution_t', get(handles.edit_t, 'string'))
    setappdata(0, 'k_solution_uts', get(handles.edit_uts, 'string'))
    
    setappdata(0, 'k_solution', solk)
    setappdata(0, 'updateKValue', 1.0)
    close kSolution
end

function disableGUI(~, ~, handles)
set(handles.text_model, 'enable', 'off');
set(handles.text_r, 'enable', 'off');
set(handles.text_fi, 'enable', 'off');
set(handles.text_t, 'enable', 'off');
set(handles.text_uts, 'enable', 'off');
set(handles.edit_r, 'enable', 'off');
set(handles.edit_fi, 'enable', 'off');
set(handles.edit_t, 'enable', 'off');
set(handles.edit_uts, 'enable', 'off');
set(handles.text_units_fi, 'enable', 'off');
set(handles.text_units_t, 'enable', 'off');
set(handles.text_units_uts, 'enable', 'off');
set(handles.pMenu_solution, 'enable', 'off');
set(handles.pButton_close, 'enable', 'off');


function enableGUI(~, ~, handles)
set(handles.pButton_solve, 'enable', 'on');
set(handles.text_model, 'enable', 'on');
set(handles.pButton_close, 'enable', 'on');
set(handles.pMenu_solution, 'enable', 'on');

switch get(handles.pMenu_solution, 'value');
    case 2.0
        set(handles.text_r, 'enable', 'on');
        set(handles.text_fi, 'enable', 'on');
        set(handles.text_t, 'enable', 'on');
        
        set(handles.edit_r, 'enable', 'on');
        set(handles.edit_fi, 'enable', 'on');
        set(handles.edit_t, 'enable', 'on');
        
        set(handles.text_units_fi, 'enable', 'on');
        set(handles.text_units_t, 'enable', 'on');
    case 3.0
        set(handles.text_r, 'enable', 'on');
        set(handles.text_fi, 'enable', 'on');
        set(handles.text_t, 'enable', 'on');
        
        set(handles.edit_r, 'enable', 'inactive');
        set(handles.edit_fi, 'enable', 'on');
        set(handles.edit_t, 'enable', 'on');
        
        set(handles.text_units_fi, 'enable', 'on');
        set(handles.text_units_t, 'enable', 'on');
    case 4.0
        set(handles.text_r, 'enable', 'on');
        set(handles.text_fi, 'enable', 'on');
        set(handles.text_t, 'enable', 'on');
        set(handles.text_uts, 'enable', 'on');
        
        set(handles.edit_r, 'enable', 'inactive');
        set(handles.edit_fi, 'enable', 'on');
        set(handles.edit_t, 'enable', 'on');
        set(handles.edit_uts, 'enable', 'on');
        
        set(handles.text_units_fi, 'enable', 'on');
        set(handles.text_units_t, 'enable', 'on');
        set(handles.text_units_uts, 'enable', 'on');
    case 5.0
        set(handles.text_r, 'enable', 'on');
        set(handles.text_fi, 'enable', 'on');
        set(handles.text_t, 'enable', 'on');
        
        set(handles.edit_r, 'enable', 'inactive');
        set(handles.edit_fi, 'enable', 'on');
        set(handles.edit_t, 'enable', 'on');
        
        set(handles.text_units_fi, 'enable', 'on');
        set(handles.text_units_t, 'enable', 'on');
end


% --- Executes on button press in pButton_close.
function pButton_close_Callback(~, ~, ~)
close kSolution
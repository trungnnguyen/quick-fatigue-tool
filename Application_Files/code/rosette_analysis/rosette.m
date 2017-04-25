function varargout = rosette(varargin)%#ok<*DEFNU>
%ROSETTE    QFT functions for Rosette Analysis.
%   These functions are used to call and operate the Rosette Analysis
%   application.
%   
%   ROSETTE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also rosetteTools.
%
%   Reference section in Quick Fatigue Tool User Guide
%      A3.3 Rosette Analysis
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rosette_OpeningFcn, ...
                   'gui_OutputFcn',  @rosette_OutputFcn, ...
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


% --- Executes just before rosette is made visible.
function rosette_OpeningFcn(hObject, ~, handles, varargin)
% This function has no pMenu_resultsType args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rosette (see VARARGIN)
movegui(hObject, 'center')

% Choose default command line pMenu_resultsType for rosette
handles.pMenu_resultsType = hObject;

% Clear the command window
clc

% Update handles structure
guidata(hObject, handles);

% Load the tips icon
[a,~]=imread('icoR_bulb.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_showDiagram, 'CData', g);

% UIWAIT makes rosette wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Load the panel state
if isappdata(0, 'rosette_edit_gaugeA') == 1.0
    set(handles.edit_gaugeA, 'string', getappdata(0, 'rosette_edit_gaugeA'))
    set(handles.edit_gaugeB, 'string', getappdata(0, 'rosette_edit_gaugeB'))
    set(handles.edit_gaugeC, 'string', getappdata(0, 'rosette_edit_gaugeC'))
    
    set(handles.edit_alpha, 'string', getappdata(0, 'rosette_edit_alpha'))
    set(handles.edit_beta, 'string', getappdata(0, 'rosette_edit_beta'))
    set(handles.edit_gamma, 'string', getappdata(0, 'rosette_edit_gamma'))
    
    set(handles.edit_E, 'string', getappdata(0, 'rosette_edit_E'))
    set(handles.edit_poisson, 'string', getappdata(0, 'rosette_edit_poisson'))
    
    check_outputLocation = getappdata(0, 'rosette_check_outputLocation');
    set(handles.check_outputLocation, 'value', check_outputLocation)
    
    if check_outputLocation == 1.0
        set(handles.edit_outputLocation, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.edit_outputLocation, 'string', getappdata(0, 'rosette_edit_outputLocation'))
        set(handles.pButton_outputLocation, 'enable', 'on')
    end
    set(handles.check_referenceStrain, 'value', getappdata(0, 'rosette_check_referenceStrain'))
    set(handles.check_referenceOrientation, 'value', getappdata(0, 'rosette_check_referenceOrientation'))
end

setappdata(0, 'rosette_pMenu_outputType', 1.0)

%% Check screen resolution
if isappdata(0, 'checkScreenResolution') == 0.0
    resolution = get(0, 'Screensize');
    if (resolution(3.0) ~= 1920.0) || (resolution(4.0) ~= 1080.0)
        msg1 = sprintf('Your screen resolution is set to %.0fx%.0f. This app will only display correctly at 1920x1080. ', resolution(3.0), resolution(4.0));
        msg2 = sprintf('Text scaling must also be set to "Medium" (125%%) from the control panel:\n\n');
        msg3 = 'Control Panel\Appearance and Personalization\Display';
        uiwait(warndlg([msg1, msg2, msg3], 'Quick Fatigue Tool', 'modal'));
    end
    setappdata(0, 'checkScreenResolution', 1.0)
end


% --- Outputs from this function are returned to the command line.
function varargout = rosette_OutputFcn(~, ~, handles) 
% varargout  cell array for returning pMenu_resultsType args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line pMenu_resultsType from handles structure
varargout{1} = handles.pMenu_resultsType;


% --- Executes on button press in pButton_start.
function pButton_start_Callback(~, ~, handles)
rosetteTools.blank(handles)
pause(1e-6)

warning('off', 'all')

%% Verify inputs
[alpha, beta, gamma, E, v, outputLocation, gaugeA, gaugeB, gaugeC, error, errorMessage] = rosetteTools.verifyInput(handles);

if error == 1.0
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    rosetteTools.show(handles)
    warning('on', 'all')
    return
end

%% Calculate E1 and E2:
referenceStrain = get(handles.check_referenceStrain, 'value');
referenceOrientation = get(handles.check_referenceOrientation, 'value');

[E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, error, errorMessage] = rosetteTools.processGauges(gaugeA, gaugeB, gaugeC, alpha, beta, gamma, E, v, referenceStrain, referenceOrientation);

if error == 1.0
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    rosetteTools.show(handles)
    warning('on', 'all')
    return
end

%% Export the result:
[error, errorMessage] = rosetteTools.writeData(E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, referenceStrain, referenceOrientation, outputLocation);

if error == 1.0
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    rosetteTools.show(handles)
    warning('on', 'all')
    return
end

%% Notify the user:
if ispc == 1.0
    response = questdlg(sprintf('Gauge results have been written to ''%s''', outputLocation), 'Quick Fatigue Tool', 'Open results folder', 'Close', 'Open results folder');
    switch response
        case 'Open results folder'
            winopen(outputLocation);
        otherwise
    end
else
    msgbox(sprintf('Gauge results have been written to ''%s''', outputLocation), 'Quick Fatigue Tool')
end

%% Cleanup
warning('on', 'all')
close rosette


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close rosette


% --- Executes on button press in pButton_gaugeA.
function pButton_gaugeA_Callback(~, ~, handles)
% Blank the GUI
rosetteTools.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseInput') == 1.0
    startPath_gauge = getappdata(0, 'panel_browseInput');
else
    startPath_gauge = [pwd, '\Data\gauge'];
end

if ispc == 1.0
    [file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for Gauge A',...
        startPath_gauge);
else
    [file, path, ~] = uigetfile('*.txt', 'Strain Data for Gauge A');
end

if isequal(file,0) || isequal(path,0)
    % User cancelled operation
else
    set(handles.edit_gaugeA, 'string', [path, file])
    
    setappdata(0,'panel_browseInput', path)
end

% Re-enable the GUI
rosetteTools.show(handles)


% --- Executes on button press in pButton_gaugeB.
function pButton_gaugeB_Callback(~, ~, handles)
% Blank the GUI
rosetteTools.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseInput') == 1.0
    startPath_gauge = getappdata(0, 'panel_browseInput');
else
    startPath_gauge = pwd;
end

if ispc == 1.0
    [file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for Gauge B',...
        startPath_gauge);
else
    [file, path, ~] = uigetfile('*.txt', 'Strain Data for Gauge B');
end

if isequal(file,0) || isequal(path,0)
    % User cancelled operation
else
    set(handles.edit_gaugeB, 'string', [path, file])
    
    setappdata(0,'panel_browseInput', path)
end

% Re-enable the GUI
rosetteTools.show(handles)


% --- Executes on button press in pButton_gaugeC.
function pButton_gaugeC_Callback(~, ~, handles)
% Blank the GUI
rosetteTools.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseInput') == 1.0
    startPath_gauge = getappdata(0, 'panel_browseInput');
else
    startPath_gauge = pwd;
end

if ispc == 1.0
    [file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for Gauge C',...
        startPath_gauge);
else
    [file, path, ~] = uigetfile('*.txt', 'Strain Data for Gauge C');
end

if isequal(file,0) || isequal(path,0)
    % User cancelled operation
else
    set(handles.edit_gaugeC, 'string', [path, file])
    
    setappdata(0,'panel_browseInput', path)
end

% Re-enable the GUI
rosetteTools.show(handles)



function edit_gaugeA_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_gaugeA_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gaugeA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_gaugeB_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_gaugeB_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gaugeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_gaugeC_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_gaugeC_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gaugeC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_E_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_E_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_E (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_poisson_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_poisson_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_poisson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_outputLocation.
function check_outputLocation_Callback(hObject, ~, handles)
if get(hObject, 'value')
    set(handles.edit_outputLocation, 'enable', 'on')
    set(handles.edit_outputLocation, 'backgroundcolor', 'white')
    set(handles.edit_outputLocation, 'string', pwd)
    set(handles.pButton_outputLocation, 'enable', 'on')
    
    setappdata(0, 'exportRosette', 1)
else
    set(handles.edit_outputLocation, 'enable', 'inactive')
    set(handles.edit_outputLocation, 'backgroundcolor', [177/255, 206/255, 237/255])
    set(handles.edit_outputLocation, 'string', 'Default project output directory')
    set(handles.pButton_outputLocation, 'enable', 'off')
    
    setappdata(0, 'exportRosette', 0)
end


function edit_outputLocation_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function edit_outputLocation_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_outputLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_outputLocation.
function pButton_outputLocation_Callback(~, ~, handles)
% Blank the GUI
rosetteTools.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseOutput') == 1.0
    startPath_output = getappdata(0, 'panel_browseOutput');
else
    if exist([pwd, '/Project/output'], 'dir') == 7.0
        startPath_output = [pwd, '/Project/output'];
    else
        startPath_output = pwd;
    end
end

outputDirectory = uigetdir(startPath_output, 'Output Directory');

if isequal(outputDirectory, 0.0)
    % User cancelled operation
else
    set(handles.edit_outputLocation, 'string', outputDirectory)
    
    % Save the directory
    setappdata(0, 'panel_browseOutput', outputDirectory)
end

% Re-enable the GUI
rosetteTools.show(handles)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
setappdata(0, 'rosette_edit_gaugeA', get(handles.edit_gaugeA, 'string'))
setappdata(0, 'rosette_edit_gaugeB', get(handles.edit_gaugeB, 'string'))
setappdata(0, 'rosette_edit_gaugeC', get(handles.edit_gaugeC, 'string'))

setappdata(0, 'rosette_edit_alpha', get(handles.edit_alpha, 'string'))
setappdata(0, 'rosette_edit_beta', get(handles.edit_beta, 'string'))
setappdata(0, 'rosette_edit_gamma', get(handles.edit_gamma, 'string'))

setappdata(0, 'rosette_edit_E', get(handles.edit_E, 'string'))
setappdata(0, 'rosette_edit_poisson', get(handles.edit_poisson, 'string'))

setappdata(0, 'rosette_check_outputLocation', get(handles.check_outputLocation, 'value'))
setappdata(0, 'rosette_edit_outputLocation', get(handles.edit_outputLocation, 'string'))
setappdata(0, 'rosette_check_referenceStrain', get(handles.check_referenceStrain, 'value'))
setappdata(0, 'rosette_check_referenceOrientation', get(handles.check_referenceOrientation, 'value'))

delete(hObject);


% --- Executes on button press in pButton_showDiagram.
function pButton_showDiagram_Callback(~, ~, handles)
setappdata(0, 'gaugeDiagram', 3.0)

rosetteTools.blank(handles)

RosetteDiagram
uiwait

rosetteTools.show(handles)



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


% --- Executes on selection change in pMenu_outputType.
function pMenu_outputType_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.text_E, 'enable', 'off')
    set(handles.edit_E, 'enable', 'off')
    set(handles.text_eUnits, 'enable', 'off')
    set(handles.text_poisson, 'enable', 'off')
    set(handles.edit_poisson, 'enable', 'off')
    
    set(handles.check_referenceStrain, 'string', 'Include reference strains')
else
    set(handles.text_E, 'enable', 'on')
    set(handles.edit_E, 'enable', 'on')
    set(handles.text_eUnits, 'enable', 'on')
    set(handles.text_poisson, 'enable', 'on')
    set(handles.edit_poisson, 'enable', 'on')
    
    set(handles.check_referenceStrain, 'string', 'Include reference stresses and strains')
end
setappdata(0, 'rosette_pMenu_outputType', get(hObject, 'value'))


% --- Executes during object creation, after setting all properties.
function pMenu_outputType_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_outputType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_referenceStrain.
function check_referenceStrain_Callback(~, ~, ~)
% hObject    handle to check_referenceStrain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_referenceStrain


% --- Executes on button press in check_referenceOrientation.
function check_referenceOrientation_Callback(~, ~, ~)
% hObject    handle to check_referenceOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_referenceOrientation

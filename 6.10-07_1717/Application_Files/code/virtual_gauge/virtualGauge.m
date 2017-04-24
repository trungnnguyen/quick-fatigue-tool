function varargout = virtualGauge(varargin)
%VIRTUALGAUGE    QFT functions for Virtual Strain Gauge.
%   These functions are used to call and operate the Virtual Strain Gauge
%   application.
%   
%   VIRTUALGAUGE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also virtualGaugeUtils, RosetteDiagram.
%
%   Reference section in Quick Fatigue Tool User Guide
%      A3.4 Virtual Strain Gauge
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @virtualGauge_OpeningFcn, ...
                   'gui_OutputFcn',  @virtualGauge_OutputFcn, ...
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


% --- Executes just before virtualGauge is made visible.
function virtualGauge_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to virtualGauge (see VARARGIN)
clc
movegui(hObject, 'center')

% Choose default command line output for virtualGauge
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes virtualGauge wait for user response (see UIRESUME)
% uiwait(handles.figure1);

approot = [getenv('USERPROFILE'), '\Documents\MATLAB\Apps\Export Tool'];

if exist(approot, 'dir')
    addpath(approot)
end

% Load the tips icon
[a,~]=imread('icoR_bulb.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_showDiagram, 'CData', g);

% Load the panel state
if isappdata(0, 'panel_virtual_gauge_editTensor') == 1.0
    set(handles.edit_tensor, 'string', getappdata(0, 'panel_virtual_gauge_editTensor'))
    set(handles.rButton_rows, 'value', getappdata(0, 'panel_virtual_gauge_radioButton_rows'))
    set(handles.rButton_cols, 'value', getappdata(0, 'panel_virtual_gauge_radioButton_cols'))
    
    set(handles.check_alpha, 'value', getappdata(0, 'panel_virtual_gauge_check_alpha'))
    
    if getappdata(0, 'panel_virtual_gauge_radiobutton_45') == 1.0
        set(handles.radiobutton_45, 'value', 1.0)
    elseif getappdata(0, 'panel_virtual_gauge_radiobutton_60') == 1.0
        set(handles.radiobutton_60, 'value', 1.0)
    else
        set(handles.radiobutton_arbitrary, 'value', 1.0)
        
        set(handles.check_alpha, 'enable', 'on')
        set(handles.text_beta, 'enable', 'on')
        set(handles.text_gamma, 'enable', 'on')
        set(handles.edit_beta, 'enable', 'on')
        set(handles.edit_gamma, 'enable', 'on')
        set(handles.text_betaUnits, 'enable', 'on')
        set(handles.text_gammaUnits, 'enable', 'on')
        
        if get(handles.check_alpha, 'value') == 1.0
            set(handles.text_alphaUnits, 'enable', 'on')
            set(handles.edit_alpha, 'backgroundColor', 'white', 'enable', 'on')
        else
            set(handles.edit_alpha, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
        end
    end
    
    set(handles.edit_alpha, 'string', getappdata(0, 'panel_virtual_gauge_edit_alpha'))
    set(handles.edit_beta, 'string', getappdata(0, 'panel_virtual_gauge_edit_beta'))
    set(handles.edit_gamma, 'string', getappdata(0, 'panel_virtual_gauge_edit_gamma'))
    
    set(handles.check_resultsLocation, 'value', getappdata(0, 'panel_virtual_gauge_check_resultsLocation'))
    if get(handles.check_resultsLocation, 'value') == 1.0
        set(handles.edit_output, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.edit_output, 'string', getappdata(0, 'panel_virtual_gauge_edit_output'))
        set(handles.pButton_browseOutput, 'enable', 'on')
    end
end

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
function varargout = virtualGauge_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_alpha_Callback(~, ~, ~) %#ok<*DEFNU>
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



function edit_tensor_Callback(~, ~, ~)
% hObject    handle to edit_tensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tensor as text
%        str2double(get(hObject,'String')) returns contents of edit_tensor as a double


% --- Executes during object creation, after setting all properties.
function edit_tensor_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_tensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_browseInput.
function pButton_browseInput_Callback(~, ~, handles)
% Blank the GUI
virtualGaugeUtils.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseInput') == 1.0
    startPath_gauge = getappdata(0, 'panel_browseInput');
else
    startPath_gauge = pwd;
end

% Get the file
if ispc == 1.0
    [file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Tensor Data',...
        startPath_gauge);
else
    [file, path, ~] = uigetfile('*.txt', 'Strain Tensor Data');
end

    
if isequal(file, 0.0) || isequal(path, 0.0)
    % User cancelled operation
else
    set(handles.edit_tensor, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_browseInput', path)
end

% Re-enable the GUI
virtualGaugeUtils.enable(handles)


% --- Executes on button press in pButton_close.
function pButton_close_Callback(~, ~, ~)
close virtualGauge


% --- Executes on button press in pButton_start.
function pButton_start_Callback(~, ~, handles)
virtualGaugeUtils.blank(handles)

%% Verify the inputs
[alpha, beta, gamma, outputLocation, E11, E22, E12, error, errorMessage] = virtualGaugeUtils.verifyInput(handles);

if error == 1.0
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    virtualGaugeUtils.enable(handles)
    
    return
end

%% Calculate the gauge data
[gaugeA, gaugeB, gaugeC] = virtualGaugeUtils.synthesizeGauges(E11, E22, E12, alpha, beta, gamma);

%% Write results to file
[error, errorMessage] = virtualGaugeUtils.writeGaugeData(gaugeA, gaugeB, gaugeC, outputLocation);

if error == 1.0
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    virtualGaugeUtils.enable(handles)
    
    return
end

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

close virtualGauge

% --- Executes when selected object is changed in uipanel_rosetteLayout.
function uipanel_rosetteLayout_SelectionChangeFcn(~, eventdata, handles)

% Get the tag of the selected radio button
switch get(eventdata.NewValue,'Tag')
    case 'radiobutton_45'
        set(handles.check_alpha, 'enable', 'off')
        set(handles.text_beta, 'enable', 'off')
        set(handles.text_gamma, 'enable', 'off')
        
        set(handles.edit_alpha, 'enable', 'off')
        set(handles.edit_beta, 'enable', 'off')
        set(handles.edit_gamma, 'enable', 'off')
        
        set(handles.text_alphaUnits, 'enable', 'off')
        set(handles.text_betaUnits, 'enable', 'off')
        set(handles.text_gammaUnits, 'enable', 'off')
    case 'radiobutton_60'
        set(handles.check_alpha, 'enable', 'off')
        set(handles.text_beta, 'enable', 'off')
        set(handles.text_gamma, 'enable', 'off')
        
        set(handles.edit_alpha, 'enable', 'off')
        set(handles.edit_beta, 'enable', 'off')
        set(handles.edit_gamma, 'enable', 'off')
        
        set(handles.text_alphaUnits, 'enable', 'off')
        set(handles.text_betaUnits, 'enable', 'off')
        set(handles.text_gammaUnits, 'enable', 'off')
    case 'radiobutton_arbitrary'
        set(handles.check_alpha, 'enable', 'on')
        set(handles.text_beta, 'enable', 'on')
        set(handles.text_gamma, 'enable', 'on')
        
        if get(handles.check_alpha, 'value') == 1.0
            set(handles.text_alphaUnits, 'enable', 'on')
            set(handles.edit_alpha, 'enable', 'on', 'backgroundColor', 'white')
        else
            set(handles.edit_alpha, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
        end
        
        set(handles.edit_beta, 'enable', 'on')
        set(handles.edit_gamma, 'enable', 'on')
        
        set(handles.text_betaUnits, 'enable', 'on')
        set(handles.text_gammaUnits, 'enable', 'on')
end


% --- Executes on button press in check_alpha.
function check_alpha_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.text_alphaUnits, 'enable', 'on')
    set(handles.edit_alpha, 'enable', 'on', 'backgroundColor', 'white')
else
    set(handles.text_alphaUnits, 'enable', 'off')
    set(handles.edit_alpha, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
end


function edit_output_Callback(~, ~, ~)
% hObject    handle to edit_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_output as text
%        str2double(get(hObject,'String')) returns contents of edit_output as a double


% --- Executes during object creation, after setting all properties.
function edit_output_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_browseOutput.
function pButton_browseOutput_Callback(~, ~, handles)
% Blank the GUI
virtualGaugeUtils.blank(handles)

% Define the start path
if isappdata(0, 'panel_browseOutput') == 1.0
    startPath_output = getappdata(0, 'panel_browseOutput');
else
    if exist([pwd, '/Data/gauge'], 'dir') == 7.0
        startPath_output = [pwd, '/Data/gauge'];
    else
        startPath_output = pwd;
    end
end

outputDirectory = uigetdir(startPath_output, 'Output Directory');

if isequal(outputDirectory, 0.0)
    % User cancelled operation
else
    set(handles.edit_output, 'string', outputDirectory)
    
    % Save the directory
    setappdata(0, 'panel_browseOutput', outputDirectory)
end

% Re-enable the GUI
virtualGaugeUtils.enable(handles)


% --- Executes on button press in pButton_showDiagram.
function pButton_showDiagram_Callback(~, ~, handles)
% Blank the GUI
virtualGaugeUtils.blank(handles)

if get(handles.radiobutton_45, 'value') == 1.0
    setappdata(0, 'gaugeDiagram', 1.0)
elseif get(handles.radiobutton_60, 'value') == 1.0
    setappdata(0, 'gaugeDiagram', 2.0)
else
    setappdata(0, 'gaugeDiagram', 3.0)
end

RosetteDiagram
uiwait

% Re-enable the GUI
virtualGaugeUtils.enable(handles)


% --- Executes on button press in check_resultsLocation.
function check_resultsLocation_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.edit_output, 'enable', 'on', 'backgroundColor', 'white')
    set(handles.edit_output, 'string', [pwd, '\Data\gauge'])
    set(handles.pButton_browseOutput, 'enable', 'on')
else
    set(handles.edit_output, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
    set(handles.edit_output, 'string', 'Default gauge directory')
    set(handles.pButton_browseOutput, 'enable', 'off')
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
%% Save the panel state
setappdata(0, 'panel_virtual_gauge_editTensor', get(handles.edit_tensor, 'string'))
setappdata(0, 'panel_virtual_gauge_radioButton_rows', get(handles.rButton_rows, 'value'))
setappdata(0, 'panel_virtual_gauge_radioButton_cols', get(handles.rButton_cols, 'value'))

setappdata(0, 'panel_virtual_gauge_radiobutton_45', get(handles.radiobutton_45, 'value'))
setappdata(0, 'panel_virtual_gauge_radiobutton_60', get(handles.radiobutton_60, 'value'))

setappdata(0, 'panel_virtual_gauge_check_alpha', get(handles.check_alpha, 'value'))
setappdata(0, 'panel_virtual_gauge_edit_alpha', get(handles.edit_alpha, 'string'))
setappdata(0, 'panel_virtual_gauge_edit_beta', get(handles.edit_beta, 'string'))
setappdata(0, 'panel_virtual_gauge_edit_gamma', get(handles.edit_gamma, 'string'))

setappdata(0, 'panel_virtual_gauge_check_resultsLocation', get(handles.check_resultsLocation, 'value'))
setappdata(0, 'panel_virtual_gauge_edit_output', get(handles.edit_output, 'string'))

delete(hObject);


% --- Executes on button press in rButton_rows.
function rButton_rows_Callback(~, ~, handles)
if get(handles.rButton_rows, 'value') == 1.0
    set(handles.rButton_cols, 'value', 0.0)
else
    set(handles.rButton_rows, 'value', 1.0)
end


% --- Executes on button press in rButton_cols.
function rButton_cols_Callback(~, ~, handles)
if get(handles.rButton_cols, 'value') == 1.0
    set(handles.rButton_rows, 'value', 0.0)
else
    set(handles.rButton_cols, 'value', 1.0)
end

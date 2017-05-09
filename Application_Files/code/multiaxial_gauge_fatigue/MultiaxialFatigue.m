function varargout = MultiaxialFatigue(varargin)%#ok<*DEFNU>
%MULTIAXIALFATIGUE    QFT functions for Multiaxial Gauge Fatigue
%   These functions are used to call and operate the Multiaxial Gauge
%   Fatigue application.
%   
%   MULTIAXIALFATIGUE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also multiaxialAnalysis, multiaxialPostProcess,
%   multiaxialPreProcess, gaugeOrientation, materialOptions.
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
                   'gui_OpeningFcn', @MultiaxialFatigue_OpeningFcn, ...
                   'gui_OutputFcn',  @MultiaxialFatigue_OutputFcn, ...
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


% --- Executes just before MultiaxialFatigue is made visible.
function MultiaxialFatigue_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MultiaxialFatigue (see VARARGIN)

% Position the GUI in the centre of the screen
movegui(hObject, 'center')

% Clear the command window
clc

% Choose default command line output for MultiaxialFatigue
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MultiaxialFatigue wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Load the orientation icon
[a,~]=imread('orientation.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_gaugeOrientation, 'CData', g);

% Load the panel state
if isappdata(0, 'panel_multiaxialFatigue_edit_gauge_0') == 1.0
    % Gauge definition
    set(handles.edit_gauge_0, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_gauge_0'))
    set(handles.edit_gauge_45, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_gauge_45'))
    set(handles.edit_gauge_90, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_gauge_90'))
    
    set(handles.pMenu_units, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_units'))
    if getappdata(0, 'panel_multiaxialFatigue_pMenu_units') == 3.0
        set(handles.text_conversionFactor, 'enable', 'on')
        set(handles.edit_conversionFactor, 'enable', 'on')
    end
    set(handles.edit_conversionFactor, 'string', getappdata(0, 'panel_multiaxialFatigue_conversion_factor'))
    
    % Material
    material = getappdata(0, 'panel_multiaxialFatigue_edit_material');
    if isempty(material) == 0.0
        [~, material, ~] = fileparts(material);
        if exist(['Data/material/local/', material, '.mat'], 'file') == 2.0
            % Use a previously selected material
            set(handles.edit_material, 'string', material)
        else
            % Use the first material in the /local directory if it exists
            userMaterial = dir('Data/material/local/*.mat');
            
            if isempty(userMaterial) == 0.0
                userMaterial(1.0).name(end-3:end) = [];
                set(handles.edit_material, 'string', userMaterial(1.0).name)
            else
                set(handles.edit_material, 'string', [])
            end
        end
    else
        % Use the first material in the /local directory if it exists
        userMaterial = dir('Data/material/local/*.mat');
        
        if isempty(userMaterial) == 0.0
            userMaterial(1.0).name(end-3:end) = [];
            set(handles.edit_material, 'string', userMaterial(1.0).name)
        else
            set(handles.edit_material, 'string', [])
        end
    end
    
    % Algorithm/MSC
    if getappdata(0, 'panel_multiaxialFatigue_rButton_algorithm_ps') == 0.0
        set(handles.rButton_algorithm_bm, 'value', 1.0)
    else
        set(handles.rButton_algorithm_ps, 'value', 1.0)
    end
    
    if getappdata(0, 'panel_multiaxialFatigue_rButton_msc_none') == 1.0
        set(handles.rButton_msc_none, 'value', 1.0)
    elseif getappdata(0, 'panel_multiaxialFatigue_rButton_msc_morrow') == 1.0
        set(handles.rButton_msc_morrow, 'value', 1.0)
    elseif getappdata(0, 'panel_multiaxialFatigue_rButton_msc_user') == 1.0
        set(handles.rButton_msc_user, 'value', 1.0)
        set(handles.text_msc_user, 'enable', 'on')
        set(handles.edit_msc_user, 'enable', 'on')
        set(handles.pButton_msc_user, 'enable', 'on')
        set(handles.check_ucs, 'enable', 'on')
        set(handles.edit_ucs, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_ucs'))
        if getappdata(0, 'panel_multiaxialFatigue_check_ucs') == 1.0
            set(handles.edit_ucs, 'enable', 'on', 'backgroundColor', 'white')
            set(handles.text_mpa, 'enable', 'on')
        end
    end
    
    if getappdata(0, 'panel_multiaxialFatigue_check_ucs') == 1.0
        set(handles.check_ucs, 'value', 1.0)
        set(handles.edit_ucs, 'backgroundColor', 'white')
        set(handles.text_mpa, 'enable', 'on')
    end
        
    set(handles.edit_msc_user, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_msc_user'))
    
    if isempty(getappdata(0, 'panel_multiaxialFatigue_edit_precision')) == 0.0
        set(handles.edit_precision, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_precision'))
    else
        set(handles.edit_precision, 'string', 18.0)
    end
    
    % Surface finish
    if getappdata(0, 'panel_multiaxialFatigue_rButton_kt_list') == 0.0
        % Surface finish as a value
        stringList = {'Niemann-Winter-Cast-Iron-Lamellar-Graphite.ktx',...
            'Niemann-Winter-Cast-Iron-Nodular-Graphite.ktx',...
            'Niemann-Winter-Cast-Steel.ktx',...
            'Niemann-Winter-Malleable-Cast-Iron.ktx',...
            'Niemann-Winter-Rolled-Steel.ktx',...
            'Corroded in tap water.ktx',...
            'Corroded in salt water.ktx'};
        set(handles.pMenu_kt_list, 'string', stringList)
    else
        % Surface finish from list
        switch getappdata(0, 'panel_multiaxialFatigue_pMenu_kt_list')
            case 1.0
                set(handles.pMenu_surfaceFinish, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_surfaceFinish'))
            case 2.0
                stringList = {'Mirror Polished',...
                    'Fine-ground or commercially polished',...
                    'Machined',...
                    'Hot-rolled',...
                    'As forged',...
                    'Corroded in tap water',...
                    'Corroded in salt water'};
                set(handles.pMenu_surfaceFinish, 'string', stringList)
                set(handles.pMenu_surfaceFinish, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_surfaceFinish'))
            case 3.0
                stringList = {'AA = 1 uins',...
                    'AA = 2 uins',...
                    'AA = 4 uins',...
                    'AA = 8 uins',...
                    'AA = 16 uins',...
                    'AA = 32 uins',...
                    'AA = 83 uins',...
                    'AA = 125 uins',...
                    'AA = 250 uins',...
                    'AA = 500 uins',...
                    'AA = 1000 uins',...
                    'AA = 2000 uins'};
                set(handles.pMenu_surfaceFinish, 'string', stringList)
                set(handles.pMenu_surfaceFinish, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_surfaceFinish'))
        end
    end
    
    if getappdata(0, 'panel_multiaxialFatigue_check_kt_direct') == 1.0
        set(handles.check_kt_direct, 'value', 1.0)
        set(handles.text_KtEq, 'enable', 'on')
        set(handles.edit_kt, 'enable', 'on')
        set(handles.text_defineSurfaceFinish, 'enable', 'off')
        set(handles.rButton_kt_list, 'enable', 'off')
        set(handles.rButton_kt_value, 'enable', 'off')
        set(handles.text_RzEq, 'enable', 'off')
        set(handles.text_microns, 'enable', 'off')
        set(handles.text_definitionFile, 'enable', 'off')
        set(handles.pMenu_kt_list, 'enable', 'off')
        set(handles.text_surfaceFinish, 'enable', 'off')
        set(handles.pMenu_surfaceFinish, 'enable', 'off')
    else
        if getappdata(0, 'panel_multiaxialFatigue_rButton_kt_list') == 0.0
            set(handles.text_RzEq, 'enable', 'on')
            set(handles.text_microns, 'enable', 'on')
            set(handles.edit_rz, 'enable', 'on')
            set(handles.text_surfaceFinish, 'enable', 'off')
            set(handles.pMenu_surfaceFinish, 'enable', 'off')
            set(handles.pMenu_surfaceFinish, 'value', 1.0)
            set(handles.pMenu_surfaceFinish, 'string', 'N/A')
        end
    end
    
    if getappdata(0, 'panel_multiaxialFatigue_rButton_kt_list') == 0.0
        set(handles.rButton_kt_value, 'value', 1.0)
    end
    set(handles.edit_rz, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_rz'))
    set(handles.pMenu_kt_list, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_kt_list'))
    set(handles.pMenu_surfaceFinish, 'value', getappdata(0, 'panel_multiaxialFatigue_pMenu_surfaceFinish'))
    set(handles.edit_kt, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_kt'))
    
    % Output directory
    if getappdata(0, 'panel_multiaxialFatigue_check_location') == 1.0
        set(handles.edit_location, 'backgroundColor', 'white')
        set(handles.edit_location, 'enable', 'on')
        set(handles.pButton_location, 'enable', 'on')
        set(handles.check_location, 'value', 1.0)
        
        if isappdata(0, 'panel_multiaxialFatigue_edit_location') == 1.0
            set(handles.edit_location, 'string', getappdata(0, 'panel_multiaxialFatigue_edit_location'))
        else
            if exist([pwd, '/Project/output'], 'dir') == 7.0
                set(handles.edit_location, 'string', [pwd, 'Project\output'])
            else
                set(handles.edit_location, 'string', pwd)
            end
        end
    else
        set(handles.edit_location, 'enable', 'inactive')
        set(handles.pButton_location, 'enable', 'off')
        set(handles.check_location, 'value', 0.0)
        set(handles.edit_location, 'backgroundColor', [177/255, 206/255, 237/255])
        
        set(handles.edit_location, 'string', 'Default project output directory')
    end
end

%% Initialize the strain gauge orientation
if isappdata(0, 'multiaxialFatigue_alpha') == 0.0
    setappdata(0, 'multiaxialFatigue_alpha', 0.0)
    setappdata(0, 'multiaxialFatigue_beta', 45.0)
    setappdata(0, 'multiaxialFatigue_gamma', 45.0)
end

%% Initialize the material options
if isappdata(0, 'multiaxialFatigue_ndCompression') == 0.0
    setappdata(0, 'multiaxialFatigue_enduranceScaleFactor', 0.25)
    setappdata(0, 'multiaxialFatigue_cyclesToRecover', 50.0)
    setappdata(0, 'multiaxialFatigue_ndCompression', 0.0)
    setappdata(0, 'multiaxialFatigue_outOfPlane', 0.0)
    setappdata(0, 'multiaxialFatigue_ndEndurance', 0.0)
    setappdata(0, 'multiaxialFatigue_modifyEnduranceLimit', 1.0)
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
function varargout = MultiaxialFatigue_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_gauge_0_Callback(~, ~, ~)
% hObject    handle to edit_gauge_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_0 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_0 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_0_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gauge_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_gauge_45_Callback(~, ~, ~)
% hObject    handle to edit_gauge_45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_45 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_45 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_45_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gauge_45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_gauge_90_Callback(~, ~, ~)
% hObject    handle to edit_gauge_90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gauge_90 as text
%        str2double(get(hObject,'String')) returns contents of edit_gauge_90 as a double


% --- Executes during object creation, after setting all properties.
function edit_gauge_90_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_gauge_90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_gauge_0_path.
function pButton_gauge_0_path_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_gauge_path') == 1.0
    startPath_gauge = getappdata(0, 'panel_multiaxialFatigue_gauge_path');
else
    startPath_gauge = [pwd, '/Data/gauge'];
end

% Get the file
[file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for 0 Degrees',...
        startPath_gauge);
    
if isequal(file, 0.0) || isequal(path, 0.0)
    % User cancelled operation
else
    set(handles.edit_gauge_0, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_multiaxialFatigue_gauge_path', path)
end

% Re-enable the GUI
multiaxialPreProcess.enable(handles)


% --- Executes on button press in pButton_gauge_45_path.
function pButton_gauge_45_path_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_gauge_path') == 1.0
    startPath_gauge = getappdata(0, 'panel_multiaxialFatigue_gauge_path');
else
    startPath_gauge = [pwd, '/Data/gauge'];
end

% Get the file
[file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for 45 Degrees',...
        startPath_gauge);
    
if isequal(file, 0.0) || isequal(path, 0.0)
    % User cancelled operation
else
    set(handles.edit_gauge_45, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_multiaxialFatigue_gauge_path', path)
end

% Re-enable the GUI
multiaxialPreProcess.enable(handles)


% --- Executes on button press in pButton_gauge_90_path.
function pButton_gauge_90_path_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_gauge_path') == 1.0
    startPath_gauge = getappdata(0, 'panel_multiaxialFatigue_gauge_path');
else
    startPath_gauge = [pwd, '/Data/gauge'];
end

% Get the file
[file, path, ~] = uigetfile({'*.txt','Text File (*.txt)';...
        '*.dat','Data File (*.dat)';...
        '*.*',  'All Files (*.*)'}, 'Strain Data for 90 Degrees',...
        startPath_gauge);
    
if isequal(file, 0.0) || isequal(path, 0.0)
    % User cancelled operation
else
    set(handles.edit_gauge_90, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_multiaxialFatigue_gauge_path', path)
end

% Re-enable the GUI
multiaxialPreProcess.enable(handles)


% --- Executes on selection change in pMenu_units.
function pMenu_units_Callback(hObject, ~, handles)
if get(hObject, 'value') == 3.0
    set(handles.text_conversionFactor, 'enable', 'on')
    set(handles.edit_conversionFactor, 'enable', 'on')
else
    set(handles.text_conversionFactor, 'enable', 'off')
    set(handles.edit_conversionFactor, 'enable', 'off')
end


% --- Executes during object creation, after setting all properties.
function pMenu_units_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_units (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close MultiaxialFatigue


% --- Executes on button press in pButton_analyse.
function pButton_analyse_Callback(~, ~, handles)

%% Clear the command window
clc; warning('off', 'all')

%% Start the timer
tic

%% Blank the GUI
multiaxialPreProcess.blank(handles)
pause(1e-6)

%% Get the criterion for fully-compressive cycles
ndCompression = getappdata(0, 'multiaxialFatigue_ndCompression');

%% Get the out-of-plane variable
outOfPlane = getappdata(0, 'multiaxialFatigue_outOfPlane');

%% Check the conversion factor definition
if get(handles.pMenu_units, 'value') == 3.0
    [conversionFactorError, conversionFactor] = multiaxialPreProcess.checkConversionFactor(handles);
    
    if conversionFactorError == 1.0
        %% Re-enable the GUI
        multiaxialPreProcess.enable(handles)
        warning('on', 'all')
        return
    end
end

%% Prescan the file selection
[e0, e45, e90, timeHistory0, timeHistory45, timeHistory90, error] = multiaxialPreProcess.preScanFile(handles);

if error == 1.0
    %% Re-enable the GUI
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
end

%% Get the mean stress correction for the analysis
if get(handles.rButton_msc_none, 'value') == 1.0
    msCorrection = 0.0;
elseif get(handles.rButton_msc_morrow, 'value') == 1.0
    msCorrection = 1.0;
elseif get(handles.rButton_msc_user, 'value') == 1.0
    msCorrection = get(handles.edit_msc_user, 'string');
    
    mscError = multiaxialPreProcess.getUserMSC(handles, msCorrection);
    
    if mscError == 1.0
        %% Re-enable the GUI
        multiaxialPreProcess.enable(handles)
        warning('on', 'all')
        return
    else
        msCorrection = 2.0;
    end
end

%% Read the material file
error = multiaxialPreProcess.preScanMaterial(handles, msCorrection);

if error == 1.0;
    %% Re-enable the GUI
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
end

%% Initialise material variables
Sf = getappdata(0, 'Sf');
b = getappdata(0, 'b');
Ef = getappdata(0, 'Ef');
c = getappdata(0, 'c');
cael = getappdata(0, 'cael');
E = getappdata(0, 'E');
kp = getappdata(0, 'kp');
np = getappdata(0, 'np');
uts = getappdata(0, 'uts');
if isempty(getappdata(0, 'ucs')) == 1.0
    ucs = uts;
else
    ucs = getappdata(0, 'ucs');
end

% Life values for E-N curve
Nf = linspace(1.0, cael, 1e2);

%% Get the algorithm for the analysis
algorithmValue = get(handles.rButton_algorithm_ps, 'value');
if algorithmValue == 1.0
    algorithm = 1.0;
else
    algorithm = 2.0;
end

%% Get the step size and plane precision
planePrecision = str2double(get(handles.edit_precision, 'string'));

% Check the user precision value
if isnan(planePrecision) == 1.0 || isinf(planePrecision) == 1.0 || isreal(planePrecision) == 0.0
    errordlg('An invalid number of planes was specified.', 'Quick Fatigue Tool')
    uiwait
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
elseif planePrecision < 1.0
    errordlg('At least one plane is required for critical plane analysis.', 'Quick Fatigue Tool')
    uiwait
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
elseif planePrecision > 1000.0
    planePrecision = 1000.0;
end
planePrecision = ceil(planePrecision);

step = 180.0/planePrecision;
planePrecision = planePrecision + 1.0; % Account for zero degree plane

%% Read the surface finish definition
ktError = multiaxialPreProcess.preScanKt(handles);

if ktError == 1.0
    %% Re-enable the GUI
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
end

%% Verify the output directory
[error, path] = multiaxialPreProcess.checkOutput(get(handles.check_location, 'value'), get(handles.edit_location, 'string'));

if error == 1.0
    try
        rmdir(path)
    catch
    end
    errordlg('The results location cannot be empty.', 'Quick Fatigue Tool')
    uiwait
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
elseif error == 2.0
    try
        rmdir(path)
    catch
    end
    errordlg('The specified output file path could not be created. Check that the drive location exists.', 'Quick Fatigue Tool')
    uiwait
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
end

%% Calculate Kt factors for each value of Nf if applicable
if getappdata(0, 'kt') ~= 1.0
    ktn = zeros(1.0, length(Nf));
    for ktIndex = 1:length(Nf)
        ktn(ktIndex) = analysis.getKtn(Nf(ktIndex));
    end
else
    ktn = ones(1.0, length(Nf));
end

%% Convert the strain gauge data units if necessary
if get(handles.pMenu_units, 'value') == 2.0
    e0 = e0*1e-6;
    e45 = e45*1e-6;
    e90 = e90*1e-6;
elseif get(handles.pMenu_units, 'value') == 3.0
    e0 = e0*conversionFactor;
    e45 = e45*conversionFactor;
    e90 = e90*conversionFactor;
end

%% Convert strain gauge components into principal strain
[Exx, Eyy, Ezz, timeHistoryE11, timeHistoryE22, timeHistoryE33, error, errorMessage]...
    = multiaxialPreProcess.gauge2principal(e0, e45, e90, timeHistory0,...
    timeHistory45, timeHistory90);

if error == 1.0
    try
        rmdir(path)
    catch
    end
    errordlg(errorMessage, 'Quick Fatigue Tool')
    uiwait
    multiaxialPreProcess.enable(handles)
    warning('on', 'all')
    return
end

%{
    If mean stress correction and plasticity correction is enabled, convert
    the principal strain tensor to the principal stress tensor
%}
if msCorrection > 0.0
    [S11, trueStressCurveBuffer_1, trueStrainCurveBuffer_1] =...
        multiaxialPreProcess.getPrincipalStress(Exx, E, kp, np);
    [S22, trueStressCurveBuffer_2, trueStrainCurveBuffer_2] =...
        multiaxialPreProcess.getPrincipalStress(Eyy, E, kp, np);
    [S33, trueStressCurveBuffer_3, trueStrainCurveBuffer_3] =...
        multiaxialPreProcess.getPrincipalStress(Ezz, E, kp, np);
    
    % Make sure the signals are the same length
    lengths = [length(S11), length(S22), length(S33)];
    signalLength = max(lengths);
    L1 = signalLength - lengths(1.0);
    L2 = signalLength - lengths(2.0);
    L3 = signalLength - lengths(3.0);
    
    if lengths(1.0) < signalLength
        S11 = [S11, zeros(1.0, L1)];
        Exx = [Exx, zeros(1.0, L1)];
        timeHistoryE11 = [timeHistoryE11, linspace(timeHistoryE11(end), timeHistoryE11(end), L1)];
    end
    if lengths(2.0) < signalLength
        S22 = [S22, zeros(1.0, L2)];
        Eyy = [Eyy, zeros(1.0, L2)];
        timeHistoryE22 = [timeHistoryE22, linspace(timeHistoryE22(end), timeHistoryE22(end), L2)];
    end
    if outOfPlane == 1.0
        if lengths(3.0) < signalLength
            S33 = [S33, zeros(1.0, L3)];
            Ezz = [Ezz, zeros(1.0, L3)];
            timeHistoryE33 = [timeHistoryE33, linspace(timeHistoryE33(end), timeHistoryE33(end), L3)];
        end
    else
        if lengths(3.0) < signalLength
            S33 = [S33, zeros(1.0, L3)];
            Ezz = [Ezz, zeros(1.0, L3)];
            timeHistoryE33 = linspace(0.0, timeHistoryE33(end), signalLength);
        end
    end
    
    % Save the stress and strain curve buffers into the appdata
    setappdata(0, 'trueStressCurveBuffer_1', trueStressCurveBuffer_1)
    setappdata(0, 'trueStrainCurveBuffer_1', trueStrainCurveBuffer_1)
    setappdata(0, 'trueStressCurveBuffer_2', trueStressCurveBuffer_2)
    setappdata(0, 'trueStrainCurveBuffer_2', trueStrainCurveBuffer_2)
    setappdata(0, 'trueStressCurveBuffer_3', trueStressCurveBuffer_3)
    setappdata(0, 'trueStrainCurveBuffer_3', trueStrainCurveBuffer_3)
else
    % Make sure the signals are the same length
    lengths = [length(Exx), length(Eyy), length(Ezz)];
    signalLength = max(lengths);
    L1 = signalLength - lengths(1.0);
    L2 = signalLength - lengths(2.0);
    L3 = signalLength - lengths(3.0);
    
    if lengths(1.0) < signalLength
        Exx = [Exx, zeros(1.0, L1)];
        timeHistoryE11 = [timeHistoryE11, linspace(timeHistoryE11(end), timeHistoryE11(end), L1)];
    end
    if lengths(2.0) < signalLength
        Eyy = [Eyy, zeros(1.0, L2)];
        timeHistoryE22 = [timeHistoryE22, linspace(timeHistoryE22(end), timeHistoryE22(end), L2)];
    end
    if outOfPlane == 1.0
        if lengths(3.0) < signalLength
            Ezz = [Ezz, zeros(1.0, L3)];
            timeHistoryE33 = [timeHistoryE33, linspace(timeHistoryE33(end), timeHistoryE33(end), L3)];
        end
    else
        if lengths(3.0) < signalLength
            Ezz = [Ezz, zeros(1.0, L3)];
            timeHistoryE33 = linspace(0.0, timeHistoryE33(end), signalLength);
        end
    end
    
    S11 = 0.0;
    S22 = 0.0;
    S33 = 0.0;
end

% Sign convention
signConvention = 1.0;

%% Re-correlate the signal
%{
    When the gauge signals were converted to principal stress, they were
    peak-picked in order to facilitate the strain-stress conversion. As a
    result, it is possible that the time points in the principal strain
    singals no longer correlate. Re-interpolate each signal so that they
    share the same time points once more
%}

if msCorrection > 0.0
    % Correlate the strains
    [~, ~, ~, Exx, Eyy, Ezz] =...
        multiaxialPreProcess.getCorrelatedSignal(timeHistoryE11,...
        timeHistoryE22, timeHistoryE33, Exx, Eyy, Ezz);
    
    % Correlate the stresses
    [timeHistoryE11, timeHistoryE22, timeHistoryE33, S11, S22, S33] =...
        multiaxialPreProcess.getCorrelatedSignal(timeHistoryE11,...
        timeHistoryE22, timeHistoryE33, S11, S22, S33);
else
    % Correlate the strains
    [timeHistoryE11, timeHistoryE22, timeHistoryE33, Exx, Eyy, Ezz] =...
        multiaxialPreProcess.getCorrelatedSignal(timeHistoryE11,...
        timeHistoryE22, timeHistoryE33, Exx, Eyy, Ezz);
end

% Populate the shear components
signalLength = length(Exx);

Exy = zeros(1.0, signalLength);
Exz = zeros(1.0, signalLength);
Eyz = zeros(1.0, signalLength);

S12 = zeros(1.0, signalLength);
S13 = zeros(1.0, signalLength);
S23 = zeros(1.0, signalLength);

%% Correct Ezz/S33 if out-of-plane strains are ignored
if outOfPlane == 0.0
    lengths = [length(Exx), length(Ezz)];
    if length(Ezz) > length(Exx)
        diff = lengths(2.0) - lengths(1.0);
        Ezz((end - diff) + 1.0:end) = [];
        
        if msCorrection > 0.0
            S33((end - diff) + 1.0:end) = [];
        end
    else
        diff = lengths(1.0) - lengths(2.0);
        Ezz = [Ezz, zeros(1.0, diff)];
        
        if msCorrection > 0.0
            S33 = [S33, zeros(1.0, diff)];
        end
    end
end

%% Get the fatigue limit
multiaxialPreProcess.getFatigueLimit(algorithm)

%% Analyse the signal
if msCorrection > 0.0
    if algorithm == 1.0
        [life, phiC, thetaC, cyclesOnCP] =...
            multiaxialAnalysis.CP_PS_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
            Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
            signalLength, planePrecision, step, S11, S22, S33, S12, S13,...
            S23, ndCompression);
    else
        [life, phiC, thetaC, cyclesOnCP] =...
            multiaxialAnalysis.CP_BM_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
            Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
            signalLength, planePrecision, step, signConvention, S11, S22,...
            S33, S12, S13, S23, ndCompression);
    end
else
    if algorithm == 1.0
        [life, phiC, thetaC, cyclesOnCP] =...
            multiaxialAnalysis.CP_PS(Exx, Eyy, Ezz, Exy, Exz, Eyz, uts,...
            ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection, signalLength,...
            planePrecision, step, ndCompression);
    else
        [life, phiC, thetaC, cyclesOnCP] =...
            multiaxialAnalysis.CP_BM(Exx, Eyy, Ezz, Exy, Exz, Eyz, uts,...
            ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection, signalLength,...
            planePrecision, step, signConvention, ndCompression);
    end
end

%% Critical plane output
if msCorrection > 0.0
    if algorithm == 1.0
        multiaxialAnalysis.worstItemAnalysis_PS_NONLINEAR(Exx, Eyy, Ezz,...
            Exy, Exz, Eyz, phiC, thetaC, signalLength, msCorrection,...
            planePrecision, step, signConvention, uts, ucs, Sf, b, Ef, c,...
            E, Nf, ktn, S11, S22, S33, S12, S13, S23, ndCompression)
    else
        multiaxialAnalysis.worstItemAnalysis_SBBM_NONLINEAR(Exx, Eyy, Ezz,...
            Exy, Exz, Eyz, phiC, thetaC, signalLength, msCorrection,...
            planePrecision, step, signConvention, uts, ucs, Sf, b, Ef, c,...
            E, Nf, ktn, S11, S22, S33, S12, S13, S23, ndCompression)
    end
else
    if algorithm == 1.0
        multiaxialAnalysis.worstItemAnalysis_PS(Exx, Eyy, Ezz, Exy, Exz,...
            Eyz, phiC, thetaC, signalLength, msCorrection, planePrecision,...
            step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
            ndCompression)
    else
        multiaxialAnalysis.worstItemAnalysis_SBBM(Exx, Eyy, Ezz, Exy, Exz,...
            Eyz, phiC, thetaC, signalLength, msCorrection, planePrecision,...
            step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
            ndCompression)
    end
end

%% Stop the timer
analysisTime = toc;

%% Write MATLAB figures
multiaxialPostProcess.outputFigures(step, thetaC, signalLength, Exx, Eyy,...
    Ezz, S11, S22, S33, msCorrection, timeHistoryE11, timeHistoryE22, timeHistoryE33)

%% Export tables
multiaxialPostProcess.outputTables(step, phiC, Exx, Eyy, Ezz, S11, S22,...
    S33, signalLength, msCorrection)

%% Write results to output file
multiaxialPostProcess.outputLog(handles, phiC, thetaC, cyclesOnCP, life,....
    cael, analysisTime)

%% Report the life in a message box
message1 = sprintf('Analysis complete.\n\n');
message2 = sprintf('Critical Plane Orientation:\nPHI = %.0f degrees\nTHETA = %.0f degrees\n\n', phiC, thetaC);
message3 = sprintf('Number of cycles: %.0f\n\n', cyclesOnCP);
if life > 0.5*cael
    message4 = sprintf('Life-Repeats: No damage');
elseif life <= 1.0
    message4 = sprintf('Life-Repeats: No life');
else
    message4 = sprintf('Life-Repeats: %.0f', life);
end
if getappdata(0, 'multiaxialGaugeFatigue_unableOutput') == 1.0
    message5 = sprintf('\n\nGauge results were not written to file.');
else
    message5 = sprintf('\n\nGauge results have been written to ''%s''', getappdata(0, 'outputPath'));
end
rmappdata(0, 'multiaxialGaugeFatigue_unableOutput')

if ispc == 1.0
    response = questdlg([message1, message2, message3, message4, message5], 'Quick Fatigue Tool', 'Open results folder', 'Close', 'Open results folder');
    switch response
        case 'Open results folder'
            winopen(getappdata(0, 'outputPath'));
        otherwise
    end
else
    msgbox([message1, message2, message3, message4, message5], 'Quick Fatigue Tool');
end

warning('on', 'all')
close MultiaxialFatigue


function edit_location_Callback(~, ~, ~)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_location as text
%        str2double(get(hObject,'String')) returns contents of edit_location as a double


% --- Executes during object creation, after setting all properties.
function edit_location_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_location.
function check_location_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_location, 'backgroundColor', [177/255, 206/255, 237/255])
        set(handles.edit_location, 'string', 'Default project output directory')
        set(handles.edit_location, 'enable', 'inactive')
        set(handles.pButton_location, 'enable', 'off')
    case 1.0
        set(handles.edit_location, 'backgroundColor', 'white')
        set(handles.edit_location, 'enable', 'on')
        set(handles.pButton_location, 'enable', 'on')
        
        if exist([pwd, '/Project/output'], 'dir') == 7.0
            set(handles.edit_location, 'string', [pwd, '/Project/output'])
        else
            set(handles.edit_location, 'string', pwd)
        end
end



function edit_material_Callback(~, ~, ~)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_material as text
%        str2double(get(hObject,'String')) returns contents of edit_material as a double


% --- Executes during object creation, after setting all properties.
function edit_material_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_material (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_createMaterial.
function pButton_createMaterial_Callback(~, ~, handles)
multiaxialPreProcess.blank(handles)

setappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager', 1.0)
UserMaterial
uiwait

multiaxialPreProcess.enable(handles)

rmappdata(0, 'multiaxial_gauge_fatigue_skip_material_manager')

material = getappdata(0, 'material_for_multiaxial_gauge_fatigue');

if isempty(material) == 0.0
    set(handles.edit_material, 'string', getappdata(0, 'material_for_multiaxial_gauge_fatigue'))
end

if isappdata(0, 'material_for_multiaxial_gauge_fatigue') == 1.0
    rmappdata(0, 'material_for_multiaxial_gauge_fatigue')
end


function edit_kt_Callback(~, ~, ~)
% hObject    handle to edit_kt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_kt as text
%        str2double(get(hObject,'String')) returns contents of edit_kt as a double


% --- Executes during object creation, after setting all properties.
function edit_kt_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_kt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_kt_list.
function pMenu_kt_list_Callback(hObject, ~, handles)
if get(handles.rButton_kt_list, 'value') == 1.0
    switch get(hObject, 'value')
        case 1.0
            stringList = {'Mirror Polished - Ra <= 0.25um',...
                '0.25 < Ra <= 0.6um',...
                '0.6 < Ra <= 1.6um',...
                '1.6 < Ra <= 4um',...
                'Fine Machined - 4 < Ra <= 16um',...
                'Machined - 16 < Ra <= 40um',...
                'Precision Forging - 40 < Ra <= 75um',...
                '75um < Ra'};
        case 2.0
            stringList = {'Mirror Polished',...
                'Fine-ground or commercially polished',...
                'Machined',...
                'Hot-rolled',...
                'As forged',...
                'Corroded in tap water',...
                'Corroded in salt water'};
        case 3.0
            stringList = {'AA = 1 uins',...
                'AA = 2 uins',...
                'AA = 4 uins',...
                'AA = 8 uins',...
                'AA = 16 uins',...
                'AA = 32 uins',...
                'AA = 83 uins',...
                'AA = 125 uins',...
                'AA = 250 uins',...
                'AA = 500 uins',...
                'AA = 1000 uins',...
                'AA = 2000 uins'};
    end
    set(handles.pMenu_surfaceFinish, 'value', 1.0)
    set(handles.pMenu_surfaceFinish, 'string', stringList)
end


% --- Executes during object creation, after setting all properties.
function pMenu_kt_list_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_kt_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_surfaceFinish.
function pMenu_surfaceFinish_Callback(~, ~, ~)
% hObject    handle to pMenu_surfaceFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_surfaceFinish contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_surfaceFinish


% --- Executes during object creation, after setting all properties.
function pMenu_surfaceFinish_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_surfaceFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in panel_algorithm.
function panel_algorithm_SelectionChangeFcn(~, ~, ~)
% hObject    handle to the selected object in panel_algorithm 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in panel_msc.
function panel_msc_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_msc_user'
        set(handles.text_msc_user, 'enable', 'on')
        set(handles.edit_msc_user, 'enable', 'on')
        set(handles.pButton_msc_user, 'enable', 'on')
        set(handles.check_ucs, 'enable', 'on')
        if get(handles.check_ucs, 'value') == 1.0
            set(handles.edit_ucs, 'enable', 'on')
        end
    case 'rButton_msc_morrow'
        set(handles.text_msc_user, 'enable', 'off')
        set(handles.edit_msc_user, 'enable', 'off')
        set(handles.pButton_msc_user, 'enable', 'off')
        set(handles.check_ucs, 'enable', 'off')
        set(handles.edit_ucs, 'enable', 'inactive')
    otherwise
        set(handles.text_msc_user, 'enable', 'off')
        set(handles.edit_msc_user, 'enable', 'off')
        set(handles.pButton_msc_user, 'enable', 'off')
        set(handles.check_ucs, 'enable', 'off')
        set(handles.edit_ucs, 'enable', 'inactive')
end


% --- Executes when selected object is changed in panel_kt.
function panel_kt_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'tag')
    case 'rButton_kt_value'
        set(handles.text_RzEq, 'enable', 'on')
        set(handles.text_microns, 'enable', 'on')
        set(handles.edit_rz, 'enable', 'on')
        set(handles.text_definitionFile, 'enable', 'on')
        set(handles.pMenu_kt_list, 'enable', 'on')
        set(handles.text_surfaceFinish, 'enable', 'off')
        set(handles.pMenu_surfaceFinish, 'enable', 'off')
        set(handles.text_KtEq, 'enable', 'off')
        set(handles.edit_kt, 'enable', 'off')
        
        stringList = {'Niemann-Winter-Cast-Iron-Lamellar-Graphite.ktx',...
            'Niemann-Winter-Cast-Iron-Nodular-Graphite.ktx',...
            'Niemann-Winter-Cast-Steel.ktx',...
            'Niemann-Winter-Malleable-Cast-Iron.ktx',...
            'Niemann-Winter-Rolled-Steel.ktx',...
            'Corroded in tap water.ktx',...
            'Corroded in salt water.ktx'};
        set(handles.pMenu_kt_list, 'string', stringList)
        set(handles.pMenu_surfaceFinish, 'value', 1.0)
        set(handles.pMenu_surfaceFinish, 'string', 'N/A')
    case 'rButton_kt_list'
        set(handles.pMenu_kt_list, 'value', 1.0)
        set(handles.pMenu_surfaceFinish, 'value', 1.0)
        
        set(handles.text_RzEq, 'enable', 'off')
        set(handles.text_microns, 'enable', 'off')
        set(handles.edit_rz, 'enable', 'off')
        set(handles.text_definitionFile, 'enable', 'on')
        set(handles.pMenu_kt_list, 'enable', 'on')
        set(handles.text_surfaceFinish, 'enable', 'on')
        set(handles.pMenu_surfaceFinish, 'enable', 'on')
        set(handles.text_KtEq, 'enable', 'off')
        set(handles.edit_kt, 'enable', 'off')

        stringList = {'default.kt',...
            'juvinall-1967.kt',...
            'rcjohnson-1973.kt'};
        set(handles.pMenu_kt_list, 'string', stringList)
        
        stringList = {'Mirror Polished - Ra <= 0.25um',...
            '0.25 < Ra <= 0.6um',...
            '0.6 < Ra <= 1.6um',...
            '1.6 < Ra <= 4um',...
            'Fine Machined - 4 < Ra <= 16um',...
            'Machined - 16 < Ra <= 40um',...
            'Precision Forging - 40 < Ra <= 75um',...
            '75um < Ra'};
        set(handles.pMenu_surfaceFinish, 'string', stringList)
end


% --- Executes on button press in pButton_browseMaterial.
function pButton_browseMaterial_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_material_path') == 1.0
    startPath_material = getappdata(0, 'panel_multiaxialFatigue_material_path');
else
    startPath_material = [pwd, '/Data/material/local'];
end

[materialName, path, ~] = uigetfile({'*.mat','MAT-Files (*.mat)'},...
    'Material File', startPath_material);

if isequal(materialName, 0) || isequal(path, 0)
    % User cancelled operation
    % Re-enable the GUI
    multiaxialPreProcess.enable(handles)
else
    % Re-enable the GUI
    multiaxialPreProcess.enable(handles)
    
    setappdata(0, 'gauge_material', [path, materialName])
    
    materialName(end-3: end) = [];
    set(handles.edit_material, 'string', materialName)
    set(handles.edit_material, 'fontWeight', 'normal')
    
    % Save the file path
    setappdata(0, 'panel_multiaxialFatigue_material_path', path)
    setappdata(0, 'panel_multiaxialFatigue_edit_material', materialName)
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
%% Save the panel state
setappdata(0, 'panel_multiaxialFatigue_edit_gauge_0', get(handles.edit_gauge_0, 'string'))
setappdata(0, 'panel_multiaxialFatigue_edit_gauge_45', get(handles.edit_gauge_45, 'string'))
setappdata(0, 'panel_multiaxialFatigue_edit_gauge_90', get(handles.edit_gauge_90, 'string'))
setappdata(0, 'panel_multiaxialFatigue_pMenu_units', get(handles.pMenu_units, 'value'))
setappdata(0, 'panel_multiaxialFatigue_conversion_factor', get(handles.edit_conversionFactor, 'string'))

setappdata(0, 'panel_multiaxialFatigue_edit_material', get(handles.edit_material, 'string'))

setappdata(0, 'panel_multiaxialFatigue_rButton_algorithm_ps', get(handles.rButton_algorithm_ps, 'value'))

setappdata(0, 'panel_multiaxialFatigue_rButton_msc_none', get(handles.rButton_msc_none, 'value'))
setappdata(0, 'panel_multiaxialFatigue_rButton_msc_morrow', get(handles.rButton_msc_morrow, 'value'))
setappdata(0, 'panel_multiaxialFatigue_rButton_msc_user', get(handles.rButton_msc_user, 'value'))
setappdata(0, 'panel_multiaxialFatigue_check_ucs', get(handles.check_ucs, 'value'))
setappdata(0, 'panel_multiaxialFatigue_edit_ucs', get(handles.edit_ucs, 'string'))

setappdata(0, 'panel_multiaxialFatigue_edit_msc_user', get(handles.edit_msc_user, 'string'))
setappdata(0, 'panel_multiaxialFatigue_edit_precision', get(handles.edit_precision, 'string'))

setappdata(0, 'panel_multiaxialFatigue_rButton_kt_list', get(handles.rButton_kt_list, 'value'))
setappdata(0, 'panel_multiaxialFatigue_edit_rz', get(handles.edit_rz, 'string'))
setappdata(0, 'panel_multiaxialFatigue_edit_kt', get(handles.edit_rz, 'string'))
setappdata(0, 'panel_multiaxialFatigue_pMenu_kt_list', get(handles.pMenu_kt_list, 'value'))
setappdata(0, 'panel_multiaxialFatigue_pMenu_surfaceFinish', get(handles.pMenu_surfaceFinish, 'value'))
setappdata(0, 'panel_multiaxialFatigue_check_kt_direct', get(handles.check_kt_direct, 'value'))
setappdata(0, 'panel_multiaxialFatigue_edit_kt', get(handles.edit_kt, 'string'))

setappdata(0, 'panel_multiaxialFatigue_check_location', get(handles.check_location, 'value'))
setappdata(0, 'panel_multiaxialFatigue_edit_location', get(handles.edit_location, 'string'))

delete(hObject);


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(~, ~, handles)
%% Gauge Definition
set(handles.edit_gauge_0, 'string', [])
set(handles.edit_gauge_45, 'string', [])
set(handles.edit_gauge_90, 'string', [])
set(handles.pMenu_units, 'value', 1.0)
setappdata(0, 'panel_multiaxialFatigue_gauge_path', [pwd, '/Data/gauge'])
set(handles.text_conversionFactor, 'enable', 'off')
set(handles.edit_conversionFactor, 'enable', 'off')
set(handles.edit_conversionFactor, 'string', [])

%% Gauge Orientation
setappdata(0, 'multiaxialFatigue_alpha', 0.0)
setappdata(0, 'multiaxialFatigue_beta', 45.0)
setappdata(0, 'multiaxialFatigue_gamma', 45.0)

setappdata(0, 'gaugeOrientation_rButton_rectangular', 1.0)
setappdata(0, 'gaugeOrientation_rButton_delta', 0.0)
setappdata(0, 'gaugeOrientation_rButton_user', 0.0)

setappdata(0, 'gaugeOrientation_edit_alpha', '0')
setappdata(0, 'gaugeOrientation_edit_beta', '45')
setappdata(0, 'gaugeOrientation_edit_gamma', '45')

%% Material Options
setappdata(0, 'multiaxialFatigue_enduranceScaleFactor', 0.25)
setappdata(0, 'multiaxialFatigue_cyclesToRecover', 50.0)
setappdata(0, 'multiaxialFatigue_ndCompression', 0.0)
setappdata(0, 'multiaxialFatigue_outOfPlane', 0.0)
setappdata(0, 'multiaxialFatigue_ndEndurance', 0.0)
setappdata(0, 'multiaxialFatigue_modifyEnduranceLimit', 1.0)

setappdata(0, 'materialOptions_check_ndCompression', 0.0)
setappdata(0, 'materialOptions_check_outOfPlane', 0.0)

setappdata(0, 'materialOptions_check_ndEndurance',0.0)
setappdata(0, 'materialOptions_check_modifyEnduranceLimit', 0.0)

setappdata(0, 'materialOptions_rButton_defaultControls', 1.0)
setappdata(0, 'materialOptions_rButton_userControls', 0.0)

setappdata(0, 'materialOptions_edit_enduranceScaleFactor', '')
setappdata(0, 'materialOptions_edit_cyclesToRecover', '')

%% Material Definition
material = getappdata(0, 'panel_multiaxialFatigue_edit_material');
if isempty(material) == 0.0
    [~, material, ~] = fileparts(material);
    if exist(['Data/material/local/', material, '.mat'], 'file') == 2.0
        % Use a previously selected material
        set(handles.edit_material, 'string', material)
    else
        % Use the first material in the /local directory if it exists
        userMaterial = dir('Data/material/local/*.mat');
        
        if isempty(userMaterial) == 0.0
            userMaterial(1.0).name(end-3:end) = [];
            set(handles.edit_material, 'string', userMaterial(1.0).name)
        else
            set(handles.edit_material, 'string', [])
        end
    end
else
    userMaterial = dir('Data/material/local/*.mat');
    
    if isempty(userMaterial) == 0.0
        userMaterial(1.0).name(end-3:end) = [];
        set(handles.edit_material, 'string', userMaterial(1.0).name)
    else
        set(handles.edit_material, 'string', [])
    end
end

if isappdata(0, 'gauge_material')
    rmappdata(0, 'gauge_material')
end
setappdata(0, 'panel_multiaxialFatigue_material_path', [pwd, '/Data/material/local'])

%% Analysis Definition
set(handles.rButton_algorithm_bm, 'value', 1.0)
set(handles.edit_precision, 'string', 18.0)
set(handles.rButton_msc_morrow, 'value', 1.0)
set(handles.text_msc_user, 'enable', 'off')
set(handles.edit_msc_user, 'enable', 'off')
set(handles.edit_msc_user, 'string', [])
set(handles.pButton_msc_user, 'enable', 'off')
set(handles.check_ucs, 'enable', 'off', 'value', 0.0)
set(handles.edit_ucs, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255], 'string', [])
set(handles.text_mpa, 'enable', 'off')
setappdata(0, 'panel_multiaxialFatigue_msc_path', [pwd, '/Data/msc'])
set(handles.text_defineSurfaceFinish, 'enable', 'on')
set(handles.rButton_kt_list, 'value', 1.0)
set(handles.rButton_kt_list, 'enable', 'on')
set(handles.rButton_kt_value, 'enable', 'on')
set(handles.text_RzEq, 'enable', 'off')
set(handles.text_microns, 'enable', 'off')
set(handles.edit_rz, 'enable', 'off', 'string', [])
set(handles.text_definitionFile, 'enable', 'on')
set(handles.pMenu_kt_list, 'enable', 'on')
set(handles.text_surfaceFinish, 'enable', 'on')
set(handles.pMenu_surfaceFinish, 'enable', 'on')
set(handles.text_KtEq, 'enable', 'off')
set(handles.edit_kt, 'enable', 'off', 'string', '1.0')
set(handles.check_kt_direct, 'value', 0.0)
set(handles.edit_kt, 'backgroundColor', 'white')
set(handles.pMenu_kt_list, 'value', 1.0)
stringList = {'default.kt',...
    'juvinall-1967.kt',...
    'rcjohnson-1973.kt'};
set(handles.pMenu_kt_list, 'string', stringList)
stringList = {'Mirror Polished - Ra <= 0.25um',...
    '0.25 < Ra <= 0.6um',...
    '0.6 < Ra <= 1.6um',...
    '1.6 < Ra <= 4um',...
    'Fine Machined - 4 < Ra <= 16um',...
    'Machined - 16 < Ra <= 40um',...
    'Precision Forging - 40 < Ra <= 75um',...
    '75um < Ra'};
set(handles.pMenu_surfaceFinish, 'string', stringList, 'value', 1.0)

%% Output Definition
set(handles.check_location, 'value', 0.0)
set(handles.edit_location, 'backgroundColor', [177/255, 206/255, 237/255])
set(handles.edit_location, 'string', 'Default project output directory')
set(handles.edit_location, 'enable', 'inactive')
set(handles.pButton_location, 'enable', 'off')
if exist([pwd, '/Project/output'], 'dir') == 7.0
    setappdata(0, 'panel_multiaxialFatigue_output_path', [pwd, 'Project/output'])
else
    setappdata(0, 'panel_multiaxialFatigue_output_path', pwd)
end


% --- Executes on button press in pButton_location.
function pButton_location_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_output_path') == 1.0
    startPath_output = getappdata(0, 'panel_multiaxialFatigue_output_path');
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
    set(handles.edit_location, 'string', outputDirectory)
    
    % Save the directory
    setappdata(0, 'panel_multiaxialFatigue_output_path', outputDirectory)
end

% Re-enable the GUI
multiaxialPreProcess.enable(handles)


% --- Executes on button press in pButton_msc_user.
function pButton_msc_user_Callback(~, ~, handles)
% Blank the GUI
multiaxialPreProcess.blank(handles)

% Define the start path
if isappdata(0, 'panel_multiaxialFatigue_msc_path') == 1.0
    startPath_msc = getappdata(0, 'panel_multiaxialFatigue_msc_path');
else
    startPath_msc = [pwd, '/Data/msc'];
end

% Get the file
[file, path, ~] = uigetfile({'*.msc', 'Mean stress correction file';...
    '*.txt','Text File (*.txt)';...
    '*.dat','Data File (*.dat)';...
    '*.*',  'All Files (*.*)'},...
    'Mean Stress Correction File', startPath_msc);
    
if isequal(file, 0.0) || isequal(path, 0.0)
    % User cancelled operation
else
    set(handles.edit_msc_user, 'string', [path, file])
    
    % Save the file path
    setappdata(0, 'panel_multiaxialFatigue_msc_path', path)
end

% Re-enable the GUI
multiaxialPreProcess.enable(handles)


function edit_msc_user_Callback(~, ~, ~)
% hObject    handle to edit_msc_user (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_msc_user as text
%        str2double(get(hObject,'String')) returns contents of edit_msc_user as a double


% --- Executes during object creation, after setting all properties.
function edit_msc_user_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_msc_user (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_precision_Callback(~, ~, ~)
% hObject    handle to edit_precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_precision as text
%        str2double(get(hObject,'String')) returns contents of edit_precision as a double


% --- Executes during object creation, after setting all properties.
function edit_precision_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_ucs.
function check_ucs_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.edit_ucs, 'enable', 'on', 'backgroundColor', 'white')
    set(handles.text_mpa, 'enable', 'on')
else
    set(handles.edit_ucs, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
    set(handles.text_mpa, 'enable', 'off')
end


function edit_ucs_Callback(~, ~, ~)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ucs as text
%        str2double(get(hObject,'String')) returns contents of edit_ucs as a double


% --- Executes during object creation, after setting all properties.
function edit_ucs_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ucs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_matManager.
function pButton_matManager_Callback(~, ~, handles)
multiaxialPreProcess.blank(handles)
MaterialManager
uiwait
multiaxialPreProcess.enable(handles)


function edit_conversionFactor_Callback(~, ~, ~)
% hObject    handle to edit_conversionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_conversionFactor as text
%        str2double(get(hObject,'String')) returns contents of edit_conversionFactor as a double


% --- Executes during object creation, after setting all properties.
function edit_conversionFactor_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_conversionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_rz_Callback(~, ~, ~)
% hObject    handle to edit_rz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_rz as text
%        str2double(get(hObject,'String')) returns contents of edit_rz as a double


% --- Executes during object creation, after setting all properties.
function edit_rz_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_rz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_kt_direct.
function check_kt_direct_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.text_defineSurfaceFinish, 'enable', 'off')
    set(handles.rButton_kt_list, 'enable', 'off')
    set(handles.rButton_kt_value, 'enable', 'off')
    set(handles.text_RzEq, 'enable', 'off')
    set(handles.edit_rz, 'enable', 'off')
    set(handles.text_definitionFile, 'enable', 'off')
    set(handles.pMenu_kt_list, 'enable', 'off')
    set(handles.text_surfaceFinish, 'enable', 'off')
    set(handles.pMenu_surfaceFinish, 'enable', 'off')
    set(handles.text_KtEq, 'enable', 'on')
    set(handles.edit_kt, 'enable', 'on')
else
    set(handles.text_defineSurfaceFinish, 'enable', 'on')
    set(handles.rButton_kt_list, 'enable', 'on')
    set(handles.rButton_kt_value, 'enable', 'on')
    
    if get(handles.rButton_kt_list, 'value') == 1.0
        set(handles.text_RzEq, 'enable', 'off')
        set(handles.edit_rz, 'enable', 'off')
        set(handles.text_definitionFile, 'enable', 'on')
        set(handles.pMenu_kt_list, 'enable', 'on')
        set(handles.text_surfaceFinish, 'enable', 'on')
        set(handles.pMenu_surfaceFinish, 'enable', 'on')
        set(handles.text_KtEq, 'enable', 'off')
        set(handles.edit_kt, 'enable', 'off')
    else
        set(handles.text_RzEq, 'enable', 'on')
        set(handles.edit_rz, 'enable', 'on')
        set(handles.text_definitionFile, 'enable', 'on')
        set(handles.pMenu_kt_list, 'enable', 'on')
        set(handles.text_surfaceFinish, 'enable', 'off')
        set(handles.pMenu_surfaceFinish, 'enable', 'off')
        set(handles.text_KtEq, 'enable', 'off')
        set(handles.edit_kt, 'enable', 'off')
    end
end


% --- Executes on button press in pButton_gaugeOrientation.
function pButton_gaugeOrientation_Callback(~, ~, handles)
multiaxialPreProcess.blank(handles)
gaugeOrientation

uiwait
multiaxialPreProcess.enable(handles)


% --- Executes on button press in pButton_materialOptions.
function pButton_materialOptions_Callback(~, ~, handles)
multiaxialPreProcess.blank(handles)
materialOptions

uiwait
multiaxialPreProcess.enable(handles)

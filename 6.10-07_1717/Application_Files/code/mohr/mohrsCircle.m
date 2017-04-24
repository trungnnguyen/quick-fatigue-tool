function varargout = mohrsCircle(varargin)%#ok<*DEFNU>
%MOHRSCIRCLE    QFT functions for Mohr Solver
%   These functions are used to call and operate the Mohr Solver
%   application.
%   
%   MOHRSCIRCLE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also circle.
%
%   Reference section in Quick Fatigue Tool User Guide
%      A3.5 Mohr Solver
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mohrsCircle_OpeningFcn, ...
                   'gui_OutputFcn',  @mohrsCircle_OutputFcn, ...
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


% --- Executes just before mohrsCircle is made visible.
function mohrsCircle_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mohrsCircle (see VARARGIN)
if getappdata(0, 'mohrComplete') == 1
    movegui(hObject, 'west')
else
    movegui(hObject, 'center')
end

% Choose default command line output for mohrsCircle
handles.output = hObject;

% Clear the command window
clc

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mohrsCircle wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Set units
setappdata(0, 'units', 0)

% Check that image acquisition and processing toolboxes are available:
requiredToolboxes = {'Image Acquisition Toolbox', 'Image Processing Toolbox',...
    'Communications System Toolbox'};
v = ver;
[installedToolboxes{1:length(v)}] = deal(v.Name);
setappdata(0, 'tbCheck', all(ismember(requiredToolboxes, installedToolboxes)));

if getappdata(0, 'tbCheck') == 1.0
    % Read in image
    set(handles.circleIcon, 'visible', 'on')
    imageArray =imread('mohr.png');
    % Switch active axes to the one you made for the image.
    axes(handles.circleIcon);
    imshow(imageArray);
else
    set(handles.circleIcon, 'visible', 'off')
end

% Calculation
if ~(isappdata(0, 'mohrComplete') && getappdata(0, 'mohrComplete') == 1)
    setappdata(0, 'mohrComplete', 0)
end
setappdata(0, 'mohrError', 0)

if getappdata(0, 'displayedCircle') == 1
    setappdata(0, 'displayedCircle', 1)
else
    setappdata(0, 'displayedCircle', 0)
end

% Refresh panel state after plotting
if getappdata(0, 'reloadMohr') == 1
    % Load panel state
    set(handles.xx, 'string', getappdata(0, 'state_xx'))
    set(handles.yy, 'string', getappdata(0, 'state_yy'))
    set(handles.zz, 'string', getappdata(0, 'state_zz'))
    set(handles.xy, 'string', getappdata(0, 'state_xy'))
    set(handles.yz, 'string', getappdata(0, 'state_yz'))
    set(handles.xz, 'string', getappdata(0, 'state_xz'))
    
    set(handles.r11, 'string', getappdata(0, 'state_r11'))
    set(handles.r22, 'string', getappdata(0, 'state_r22'))
    set(handles.r33, 'string', getappdata(0, 'state_r33'))
    set(handles.rTxy, 'string', getappdata(0, 'state_Txy'))
    set(handles.rTyz, 'string', getappdata(0, 'state_Tyz'))
    set(handles.rTxz, 'string', getappdata(0, 'state_Txz'))
    set(handles.rNxy, 'string', getappdata(0, 'state_Nxy'))
    set(handles.rNyz, 'string', getappdata(0, 'state_Nyz'))
    set(handles.rNxz, 'string', getappdata(0, 'state_Nxz'))
    
    set(handles.mpa_units, 'value', getappdata(0, 'state_mpa_units'))
    set(handles.scale_units, 'value', getappdata(0, 'state_scale_units'))
    
    if get(handles.scale_units, 'value') == 1
        setappdata(0, 'units', 1)
    end
end
setappdata(0, 'reloadMohr', 0)

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
function varargout = mohrsCircle_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function xx_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function xx_CreateFcn(hObject, ~, ~)
% hObject    handle to xx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function yy_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function yy_CreateFcn(hObject, ~, ~)
% hObject    handle to yy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function zz_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function zz_CreateFcn(hObject, ~, ~)
% hObject    handle to zz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xy_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function xy_CreateFcn(hObject, ~, ~)
% hObject    handle to xy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function yz_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function yz_CreateFcn(hObject, ~, ~)
% hObject    handle to yz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xz_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function xz_CreateFcn(hObject, ~, ~)
% hObject    handle to xz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in close.
function close_Callback(~, ~, ~)
rmappdata(0, 'mohrComplete')
rmappdata(0, 'reloadMohr')
rmappdata(0, 'mohrError')
close mohrsCircle


% --- Executes on button press in calculate.
function calculate_Callback(~, ~, handles)
%% Get data from fields
error = 0;

if ~isreal(str2double(get(handles.xx, 'string'))) ||...
        isnan(str2double(get(handles.xx, 'string'))) ||...
        isinf(str2double(get(handles.xx, 'string')))
    
    if isempty(get(handles.xx, 'string'))
        xx = 0;
        set(handles.xx, 'backgroundColor', 'white')
    else
        set(handles.xx,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.xx, 'backgroundColor', 'white')
    xx = str2double(get(handles.xx, 'string'));
end
if ~isreal(str2double(get(handles.yy, 'string'))) ||...
        isnan(str2double(get(handles.yy, 'string'))) ||...
        isinf(str2double(get(handles.yy, 'string')))
    
    if isempty(get(handles.yy, 'string'))
        yy = 0;
        set(handles.yy, 'backgroundColor', 'white')
    else
        set(handles.yy,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.yy, 'backgroundColor', 'white')
    yy = str2double(get(handles.yy, 'string'));
end
if ~isreal(str2double(get(handles.zz, 'string'))) ||...
        isnan(str2double(get(handles.zz, 'string'))) ||...
        isinf(str2double(get(handles.zz, 'string')))
    
    if isempty(get(handles.zz, 'string'))
        zz = 0;
        set(handles.zz, 'backgroundColor', 'white')
    else
        set(handles.zz,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.zz, 'backgroundColor', 'white')
    zz = str2double(get(handles.zz, 'string'));
end
if ~isreal(str2double(get(handles.xy, 'string'))) ||...
        isnan(str2double(get(handles.xy, 'string'))) ||...
        isinf(str2double(get(handles.xy, 'string')))
    
    if isempty(get(handles.xy, 'string'))
        xy = 0;
        set(handles.xy, 'backgroundColor', 'white')
    else
        set(handles.xy,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.xy, 'backgroundColor', 'white')
    xy = str2double(get(handles.xy, 'string'));
end
if ~isreal(str2double(get(handles.yz, 'string'))) ||...
        isnan(str2double(get(handles.yz, 'string'))) ||...
        isinf(str2double(get(handles.yz, 'string')))
    
    if isempty(get(handles.yz, 'string'))
        yz = 0;
        set(handles.yz, 'backgroundColor', 'white')
    else
        set(handles.yz,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.yz, 'backgroundColor', 'white')
    yz = str2double(get(handles.yz, 'string'));
end
if ~isreal(str2double(get(handles.xz, 'string'))) ||...
        isnan(str2double(get(handles.xz, 'string'))) ||...
        isinf(str2double(get(handles.xz, 'string')))
    
    if isempty(get(handles.xz, 'string'))
        xz = 0;
        set(handles.xz, 'backgroundColor', 'white')
    else
        set(handles.xz,'backgroundColor',[1 0.4 0.4])
        error = 1;
    end
else
    set(handles.xz, 'backgroundColor', 'white')
    xz = str2double(get(handles.xz, 'string'));
end

if error
    setappdata(0, 'mohrError', 1)
    return
end
setappdata(0, 'mohrError', 0)

%% Calculate Mohr's Circle
stress = [xx, xy, xz; xy, yy, yz; xz, yz, zz];
eigenStress = eig(stress);

r11 = max(eigenStress);
r22 = median(eigenStress);
r33 = min(eigenStress);

rTxy = 0.5*(r11-r22);
rTyz = 0.5*(r22-r33);
rTxz = 0.5*(r11-r33);

rNxy = 0.5*(r11+r22);
rNyz = 0.5*(r22+r33);
rNxz = 0.5*(r11+r33);

setappdata(0, 'r11', r11)
setappdata(0, 'r22', r22)
setappdata(0, 'r33', r33)
setappdata(0, 'rTxy', rTxy)
setappdata(0, 'rTyz', rTyz)
setappdata(0, 'rTxz', rTxz)
setappdata(0, 'rNxy', rNxy)
setappdata(0, 'rNyz', rNyz)
setappdata(0, 'rNxz', rNxz)

if getappdata(0, 'units') == 1
    if abs(r11)>1e3
        r11 = r11/1e3;
        unit1 = sprintf('%.0fGPa', r11);
    elseif abs(r11)>=1
        unit1 = sprintf('%.0fMPa', r11);
    elseif abs(r11)>1e-3
        r11 = r11/1e-3;
        unit1 = sprintf('%.0fkPa', r11);
    elseif abs(r11)>-inf
        r11 = r11/1e-6;
        unit1 = sprintf('%.0fPa', r11);
    end
    
    if abs(r22)>1e3
        r22 = r22/1e3;
        unit2 = sprintf('%.0fGPa', r22);
    elseif abs(r22)>=1
        unit2 = sprintf('%.0fMPa', r22);
    elseif abs(r22)>1e-3
        r22 = r22/1e-3;
        unit2 = sprintf('%.0fkPa', r22);
    elseif abs(r22)>-inf
        r22 = r22/1e-6;
        unit2 = sprintf('%.0fPa', r22);
    end
    
    if abs(r33)>1e3
        r33 = r33/1e3;
        unit3 = sprintf('%.0fGPa', r33);
    elseif abs(r33)>=1
        unit3 = sprintf('%.0fMPa', r33);
    elseif abs(r33)>1e-3
        r33 = r33/1e-3;
        unit3 = sprintf('%.0fkPa', r33);
    elseif abs(r33)>-inf
        r33 = r33/1e-6;
        unit3 = sprintf('%.0fPa', r33);
    end
    
    if abs(rTxy)>1e3
        rTxy = rTxy/1e3;
        unit4 = sprintf('%.0fGPa', rTxy);
    elseif abs(rTxy)>=1
        unit4 = sprintf('%.0fMPa', rTxy);
    elseif abs(rTxy)>1e-3
        rTxy = rTxy/1e-3;
        unit4 = sprintf('%.0fkPa', rTxy);
    elseif abs(rTxy)>-inf
        rTxy = rTxy/1e-6;
        unit4 = sprintf('%.0fPa', rTxy);
    end
    
    if abs(rTyz)>1e3
        rTyz = rTyz/1e3;
        unit5 = sprintf('%.0fGPa', rTyz);
    elseif abs(rTyz)>=1
        unit5 = sprintf('%.0fMPa', rTyz);
    elseif abs(rTyz)>1e-3
        rTyz = rTyz/1e-3;
        unit5 = sprintf('%.0fkPa', rTyz);
    elseif abs(r11)>-inf
        rTyz = rTyz/1e-6;
        unit5 = sprintf('%.0fPa', rTyz);
    end
    
    if abs(rTxz)>1e3
        rTxz = rTxz/1e3;
        unit6 = sprintf('%.0fGPa', rTxz);
    elseif abs(rTxz)>=1
        unit6 = sprintf('%.0fMPa', rTxz);
    elseif abs(rTxz)>1e-3
        rTxz = rTxz/1e-3;
        unit6 = sprintf('%.0fkPa', rTxz);
    elseif abs(rTxz)>-inf
        rTxz = rTxz/1e-6;
        unit6 = sprintf('%.0fPa', rTxz);
    end
    
    if abs(rNxy)>1e3
        rNxy = rNxy/1e3;
        unit7 = sprintf('%.0fGPa', rNxy);
    elseif abs(rNxy)>=1
        unit7 = sprintf('%.0fMPa', rNxy);
    elseif abs(rNxy)>1e-3
        rNxy = rNxy/1e-3;
        unit7 = sprintf('%.0fkPa', rNxy);
    elseif abs(rNxy)>-inf
        rNxy = rNxy/1e-6;
        unit7 = sprintf('%.0fPa', rNxy);
    end
    
    if abs(rNyz)>1e3
        rNyz = rNyz/1e3;
        unit8 = sprintf('%.0fGPa', rNyz);
    elseif abs(rNyz)>=1
        unit8 = sprintf('%.0fMPa', rNyz);
    elseif abs(rNyz)>1e-3
        rNyz = rNyz/1e-3;
        unit8 = sprintf('%.0fkPa', rNyz);
    elseif abs(rNyz)>-inf
        rNyz = rNyz/1e-6;
        unit8 = sprintf('%.0fPa', rNyz);
    end
    
    if abs(rNxz)>1e3
        rNxz = rNxz/1e3;
        unit9 = sprintf('%.0fGPa', rNxz);
    elseif abs(rNxz)>=1
        unit9 = sprintf('%.0fMPa', rNxz);
    elseif abs(rNxz)>1e-3
        rNxz = rNxz/1e-3;
        unit9 = sprintf('%.0fkPa', rNxz);
    elseif abs(rNxz)>-inf
        rNxz = rNxz/1e-6;
        unit9 = sprintf('%.0fPa', rNxz);
    end
    
    set(handles.r11, 'string', unit1)
    set(handles.r22, 'string', unit2)
    set(handles.r33, 'string', unit3)
    
    set(handles.rTxy, 'string', unit4)
    set(handles.rTyz, 'string', unit5)
    set(handles.rTxz, 'string', unit6)
    
    set(handles.rNxy, 'string', unit7)
    set(handles.rNyz, 'string', unit8)
    set(handles.rNxz, 'string', unit9)
else
    set(handles.r11, 'string', r11)
    set(handles.r22, 'string', r22)
    set(handles.r33, 'string', r33)
    
    set(handles.rTxy, 'string', rTxy)
    set(handles.rTyz, 'string', rTyz)
    set(handles.rTxz, 'string', rTxz)
    
    set(handles.rNxy, 'string', rNxy)
    set(handles.rNyz, 'string', rNyz)
    set(handles.rNxz, 'string', rNxz)
end

setappdata(0, 'mohrComplete', 1)


% --- Executes on button press in displayCircle.
function displayCircle_Callback(hObject, eventdata, handles)
% Run calculation
calculate_Callback(hObject, eventdata, handles)
if getappdata(0, 'mohrError') == 1
    return
else
    setappdata(0, 'displayedCircle', 1)
end

% Save panel state
setappdata(0, 'reloadMohr', 1)

setappdata(0, 'state_xx', get(handles.xx, 'string'));
setappdata(0, 'state_yy', get(handles.yy, 'string'));
setappdata(0, 'state_zz', get(handles.zz, 'string'));
setappdata(0, 'state_xy', get(handles.xy, 'string'));
setappdata(0, 'state_yz', get(handles.yz, 'string'));
setappdata(0, 'state_xz', get(handles.xz, 'string'));

setappdata(0, 'state_r11', get(handles.r11, 'string'));
setappdata(0, 'state_r22', get(handles.r22, 'string'));
setappdata(0, 'state_r33', get(handles.r33, 'string'));
setappdata(0, 'state_Txy', get(handles.rTxy, 'string'));
setappdata(0, 'state_Tyz', get(handles.rTyz, 'string'));
setappdata(0, 'state_Txz', get(handles.rTxz, 'string'));
setappdata(0, 'state_Nxy', get(handles.rNxy, 'string'));
setappdata(0, 'state_Nyz', get(handles.rNyz, 'string'));
setappdata(0, 'state_Nxz', get(handles.rNxz, 'string'));

setappdata(0, 'state_mpa_units', get(handles.mpa_units, 'value'));
setappdata(0, 'state_scale_units', get(handles.scale_units, 'value'));

% Continue

close mohrsCircle

S1 = getappdata(0, 'r11');
S2 = getappdata(0, 'r22');
S3 = getappdata(0, 'r33');

%XY circle
mark = 'x1';
x = S2 + 0.5*(abs(S1 - S2));
r = 0.5*abs((S1 - S2));
C1 = circle(mark, x, 0, r);   hold on
%YZ circle
mark = 'x2';
x = S3+0.5*(abs(S2 - S3));
r = 0.5*abs((S2 - S3));
C2 = circle(mark, x, 0, r);
%XZ circle
mark = 'x3';
x = S3 + 0.5*(abs(S1 - S3));
r = 0.5*abs((S1 - S3));  grid on
C3 = circle(mark, x, 0, r);

if abs(S1)>1e3
    S1 = S1/1e3;
    unit1 = 'GPa';
elseif abs(S1)>=1
    unit1 = 'MPa';
elseif abs(S1)>1e-3
    S1 = S1/1e-3;
    unit1 = 'kPa';
elseif abs(S1)>-inf
    S1 = S1/1e-6;
    unit1 = 'Pa';
end

if abs(S2)>1e3
    S2 = r22/1e3;
    unit2 = 'GPa';
elseif abs(S2)>=1
    unit2 = 'Mpa';
elseif abs(S2)>1e-3
    S2 = S2/1e-3;
    unit2 = 'kPa';
elseif abs(S2)>-inf
    S2 = S2/1e-6;
    unit2 = 'Pa';
end

if abs(S3)>1e3
    S3 = S3/1e3;
    unit3 = 'GPa';
elseif abs(S3)>=1
    unit3 = 'MPa';
elseif abs(S3)>1e-3
    S3 = S3/1e-3;
    unit3 = 'kPa';
elseif abs(S3)>-inf
    S3 = S3/1e-6;
    unit3 = 'Pa';
end

legend([C1 C2 C3], 'X-Y Plane', 'Y-Z Plane', 'X-Z Plane')
xlabel('Direct Stress [Pa]');  ylabel('Shear Stress [Pa]')
title('Mohr''s Circle')
string={'\bf\color{black}'};
string1=sprintf('S1 = %.2f %s', S1, unit1);
string2=sprintf('S2 = %.2f %s', S2, unit2);
string3=sprintf('S3 = %.2f %s', S3, unit3);
text(S1, 0, [string string1],...
    'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right')
text(S2, 0, [string string2])
text(S3, 0, [string string3])
plot(S1, 0, 'or', 'LineWidth', 1)
plot(S2, 0, 'og', 'LineWidth', 1)
plot(S3, 0, 'ob', 'LineWidth', 1);  hold off

mohrsCircle


% --- Executes when selected object is changed in input.
function input_SelectionChangeFcn(~, ~, ~)


% --- Executes when selected object is changed in units.
function units_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'Tag')
    case 'mpa_units'
        setappdata(0, 'units', 0)
        if getappdata(0, 'mohrComplete') == 1
            r11 = getappdata(0, 'r11');
            r22 = getappdata(0, 'r22');
            r33 = getappdata(0, 'r33');
            rTxy = getappdata(0, 'rTxy');
            rTyz = getappdata(0, 'rTyz');
            rTxz = getappdata(0, 'rTxz');
            rNxy = getappdata(0, 'rNxy');
            rNyz = getappdata(0, 'rNyz');
            rNxz = getappdata(0, 'rNxz');
            
            set(handles.r11, 'string', r11)
            set(handles.r22, 'string', r22)
            set(handles.r33, 'string', r33)
            
            set(handles.rTxy, 'string', rTxy)
            set(handles.rTyz, 'string', rTyz)
            set(handles.rTxz, 'string', rTxz)
            
            set(handles.rNxy, 'string', rNxy)
            set(handles.rNyz, 'string', rNyz)
            set(handles.rNxz, 'string', rNxz)
        end
    case 'scale_units'
        setappdata(0, 'units', 1)
        if getappdata(0, 'mohrComplete') == 1
            r11 = getappdata(0, 'r11');
            r22 = getappdata(0, 'r22');
            r33 = getappdata(0, 'r33');
            rTxy = getappdata(0, 'rTxy');
            rTyz = getappdata(0, 'rTyz');
            rTxz = getappdata(0, 'rTxz');
            rNxy = getappdata(0, 'rNxy');
            rNyz = getappdata(0, 'rNyz');
            rNxz = getappdata(0, 'rNxz');
            
            if abs(r11)>1e3
                r11 = r11/1e3;
                unit1 = sprintf('%.0fGPa', r11);
            elseif abs(r11)>=1
                unit1 = sprintf('%.0fMPa', r11);
            elseif abs(r11)>1e-3
                r11 = r11/1e-3;
                unit1 = sprintf('%.0fkPa', r11);
            elseif abs(r11)>-inf
                r11 = r11/1e-6;
                unit1 = sprintf('%.0fPa', r11);
            end
            
            if abs(r22)>1e3
                r22 = r22/1e3;
                unit2 = sprintf('%.0fGPa', r22);
            elseif abs(r22)>=1
                unit2 = sprintf('%.0fMPa', r22);
            elseif abs(r22)>1e-3
                r22 = r22/1e-3;
                unit2 = sprintf('%.0fkPa', r22);
            elseif abs(r22)>-inf
                r22 = r22/1e-6;
                unit2 = sprintf('%.0fPa', r22);
            end
            
            if abs(r33)>1e3
                r33 = r33/1e3;
                unit3 = sprintf('%.0fGPa', r33);
            elseif abs(r33)>=1
                unit3 = sprintf('%.0fMPa', r33);
            elseif abs(r33)>1e-3
                r33 = r33/1e-3;
                unit3 = sprintf('%.0fkPa', r33);
            elseif abs(r33)>-inf
                r33 = r33/1e-6;
                unit3 = sprintf('%.0fPa', r33);
            end
            
            if abs(rTxy)>1e3
                rTxy = rTxy/1e3;
                unit4 = sprintf('%.0fGPa', rTxy);
            elseif abs(rTxy)>=1
                unit4 = sprintf('%.0fMPa', rTxy);
            elseif abs(rTxy)>1e-3
                rTxy = rTxy/1e-3;
                unit4 = sprintf('%.0fkPa', rTxy);
            elseif abs(rTxy)>-inf
                rTxy = rTxy/1e-6;
                unit4 = sprintf('%.0fPa', rTxy);
            end
            
            if abs(rTyz)>1e3
                rTyz = rTyz/1e3;
                unit5 = sprintf('%.0fGPa', rTyz);
            elseif abs(rTyz)>=1
                unit5 = sprintf('%.0fMPa', rTyz);
            elseif abs(rTyz)>1e-3
                rTyz = rTyz/1e-3;
                unit5 = sprintf('%.0fkPa', rTyz);
            elseif abs(r11)>-inf
                rTyz = rTyz/1e-6;
                unit5 = sprintf('%.0fPa', rTyz);
            end
            
            if abs(rTxz)>1e3
                rTxz = rTxz/1e3;
                unit6 = sprintf('%.0fGPa', rTxz);
            elseif abs(rTxz)>=1
                unit6 = sprintf('%.0fMPa', rTxz);
            elseif abs(rTxz)>1e-3
                rTxz = rTxz/1e-3;
                unit6 = sprintf('%.0fkPa', rTxz);
            elseif abs(rTxz)>-inf
                rTxz = rTxz/1e-6;
                unit6 = sprintf('%.0fPa', rTxz);
            end
            
            if abs(rNxy)>1e3
                rNxy = rNxy/1e3;
                unit7 = sprintf('%.0fGPa', rNxy);
            elseif abs(rNxy)>=1
                unit7 = sprintf('%.0fMPa', rNxy);
            elseif abs(rNxy)>1e-3
                rNxy = rNxy/1e-3;
                unit7 = sprintf('%.0fkPa', rNxy);
            elseif abs(rNxy)>-inf
                rNxy = rNxy/1e-6;
                unit7 = sprintf('%.0fPa', rNxy);
            end
            
            if abs(rNyz)>1e3
                rNyz = rNyz/1e3;
                unit8 = sprintf('%.0fGPa', rNyz);
            elseif abs(rNyz)>=1
                unit8 = sprintf('%.0fMPa', rNyz);
            elseif abs(rNyz)>1e-3
                rNyz = rNyz/1e-3;
                unit8 = sprintf('%.0fkPa', rNyz);
            elseif abs(rNyz)>-inf
                rNyz = rNyz/1e-6;
                unit8 = sprintf('%.0fPa', rNyz);
            end
            
            if abs(rNxz)>1e3
                rNxz = rNxz/1e3;
                unit9 = sprintf('%.0fGPa', rNxz);
            elseif abs(rNxz)>=1
                unit9 = sprintf('%.0fMPa', rNxz);
            elseif abs(rNxz)>1e-3
                rNxz = rNxz/1e-3;
                unit9 = sprintf('%.0fkPa', rNxz);
            elseif abs(rNxz)>-inf
                rNxz = rNxz/1e-6;
                unit9 = sprintf('%.0fPa', rNxz);
            end
            
            set(handles.r11, 'string', unit1)
            set(handles.r22, 'string', unit2)
            set(handles.r33, 'string', unit3)
            
            set(handles.rTxy, 'string', unit4)
            set(handles.rTyz, 'string', unit5)
            set(handles.rTxz, 'string', unit6)
            
            set(handles.rNxy, 'string', unit7)
            set(handles.rNyz, 'string', unit8)
            set(handles.rNxz, 'string', unit9)
        end
end


% --- Executes on button press in reset.
function reset_Callback(~, ~, handles)
if isappdata(0, 'r11')
    rmappdata(0, 'r11');
end
if isappdata(0, 'r22')
    rmappdata(0, 'r22');
end
if isappdata(0, 'r33')
    rmappdata(0, 'r33');
end
if isappdata(0, 'rTxy')
    rmappdata(0, 'rTxy');
end
if isappdata(0, 'rTyz')
    rmappdata(0, 'rTyz');
end
if isappdata(0, 'rTxz')
    rmappdata(0, 'rTxz');
end
if isappdata(0, 'rNxy')
    rmappdata(0, 'rNxy');
end
if isappdata(0, 'rNyz')
    rmappdata(0, 'rNyz');
end
if isappdata(0, 'rNxz')
    rmappdata(0, 'rNxz');
end

setappdata(0, 'units', 0)

set(handles.xx, 'backgroundColor', 'white')
set(handles.yy, 'backgroundColor', 'white')
set(handles.zz, 'backgroundColor', 'white')
set(handles.xy, 'backgroundColor', 'white')
set(handles.yz, 'backgroundColor', 'white')
set(handles.xz, 'backgroundColor', 'white')

if getappdata(0, 'displayedCircle') == 1
    close mohrsCircle
    
    setappdata(0, 'mohrComplete', 0)
    setappdata(0, 'displayedCircle', 0)
    
    mohrsCircle
else
    setappdata(0, 'mohrComplete', 0)
    
    set(handles.xx, 'string', '')
    set(handles.yy, 'string', '')
    set(handles.zz, 'string', '')
    set(handles.xy, 'string', '')
    set(handles.yz, 'string', '')
    set(handles.xz, 'string', '')
    
    set(handles.r11, 'string', '')
    set(handles.r22, 'string', '')
    set(handles.r33, 'string', '')
    set(handles.rTxy, 'string', '')
    set(handles.rTyz, 'string', '')
    set(handles.rTxz, 'string', '')
    set(handles.rNxy, 'string', '')
    set(handles.rNyz, 'string', '')
    set(handles.rNxz, 'string', '')
    
    set(handles.mpa_units, 'value', 1)
    set(handles.scale_units, 'value', 0)
end

function varargout = materialOptions(varargin)
%MATERIALOPTIONS    QFT functions for Multiaxial Gauge Fatigue.
%   These functions contain methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   MATERIALOPTIONS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also multiaxialAnalysis, multiaxialPostProcess,
%   multiaxialPreProcess, gaugeOrientation, MultiaxialFatigue.
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
                   'gui_OpeningFcn', @materialOptions_OpeningFcn, ...
                   'gui_OutputFcn',  @materialOptions_OutputFcn, ...
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


% --- Executes just before materialOptions is made visible.
function materialOptions_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to materialOptions (see VARARGIN)

% Position the GUI in the centre of the screen
movegui(hObject, 'center')

% Choose default command line output for materialOptions
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if isappdata(0, 'materialOptions_check_ndCompression') == 1.0
    set(handles.check_ndCompression, 'value', getappdata(0, 'materialOptions_check_ndCompression'))
    set(handles.check_outOfPlane, 'value', getappdata(0, 'materialOptions_check_outOfPlane'))
    
    set(handles.check_ndEndurance, 'value', getappdata(0, 'materialOptions_check_ndEndurance'))
    set(handles.check_modifyEnduranceLimit, 'value', getappdata(0, 'materialOptions_check_modifyEnduranceLimit'))
    
    set(handles.rButton_defaultControls, 'value', getappdata(0, 'materialOptions_rButton_defaultControls'))
    set(handles.rButton_userControls, 'value', getappdata(0, 'materialOptions_rButton_userControls'))
    
    set(handles.edit_enduranceScaleFactor, 'string', getappdata(0, 'materialOptions_edit_enduranceScaleFactor'))
    set(handles.edit_cyclesToRecover, 'string', getappdata(0, 'materialOptions_edit_cyclesToRecover'))
    
    if get(handles.check_modifyEnduranceLimit, 'value') == 1.0
        set(handles.text_enduranceControls, 'enable', 'on')
        set(handles.rButton_defaultControls, 'enable', 'on')
        set(handles.rButton_userControls, 'enable', 'on')
        
        if get(handles.rButton_userControls, 'value') == 1.0
            set(handles.text_enduranceScaleFactor, 'enable', 'on')
            set(handles.edit_enduranceScaleFactor, 'enable', 'on', 'backgroundColor', 'white')
            
            set(handles.text_cyclesToRecover, 'enable', 'on')
            set(handles.edit_cyclesToRecover, 'enable', 'on', 'backgroundColor', 'white')
            set(handles.text_cycles, 'enable', 'on')
        end
    end
end

% UIWAIT makes materialOptions wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = materialOptions_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~) %#ok<*DEFNU>
close materialOptions


% --- Executes on button press in pButton_ok.
function pButton_ok_Callback(~, ~, handles)
% Blank the GUI
blank(handles)

error = 0.0;

if get(handles.check_modifyEnduranceLimit, 'value') == 1.0 && get(handles.rButton_userControls, 'value') == 1.0
    enduranceScaleFactor = str2double(get(handles.edit_enduranceScaleFactor, 'string'));
    
    if isempty(get(handles.edit_enduranceScaleFactor, 'string')) == 1.0
        error = 1.0;
        errorMessage = 'Please specify a value for the endurance scale factor.';
    elseif (isnumeric(enduranceScaleFactor) == 0.0) || (isinf(enduranceScaleFactor) == 1.0) || (isnan(enduranceScaleFactor) == 1.0)
        error = 1.0;
        errorMessage = 'An invalid endurance scale factor was specified.';
    elseif enduranceScaleFactor >= 1.0
        error = 1.0;
        errorMessage = 'The endurance scale factor must be less than 1.';
    end
    
    if error == 1.0
        errordlg(errorMessage, 'Quick Fatigue Tool')
        uiwait
        show(handles)
        return
    end
    
    cyclesToRecover = str2double(get(handles.edit_cyclesToRecover, 'string'));
    
    if isempty(get(handles.edit_cyclesToRecover, 'string')) == 1.0
        error = 1.0;
        errorMessage = 'Please specify a value for number of cycles to recover.';
    elseif (isnumeric(cyclesToRecover) == 0.0) || (isinf(cyclesToRecover) == 1.0) || (isnan(cyclesToRecover) == 1.0)
        error = 1.0;
        errorMessage = 'An invalid number of cycles to recover was specified.';
    elseif rem(cyclesToRecover, 1.0) ~= 0
        error = 1.0;
        errorMessage = 'The number of cycles to recover must be an integer.';
    elseif floor(cyclesToRecover) < 1.0
        error = 1.0;
        errorMessage = 'The number of cycles to recover must be positive.';
    end
    
    if error == 1.0
        errordlg(errorMessage, 'Quick Fatigue Tool')
        uiwait
        show(handles)
        return
    end
    
    setappdata(0, 'multiaxialFatigue_enduranceScaleFactor', enduranceScaleFactor)
    setappdata(0, 'multiaxialFatigue_cyclesToRecover', cyclesToRecover)
else
    setappdata(0, 'multiaxialFatigue_enduranceScaleFactor', 0.25)
    setappdata(0, 'multiaxialFatigue_cyclesToRecover', 50.0)
end

setappdata(0, 'multiaxialFatigue_ndCompression', get(handles.check_ndCompression, 'value'))
setappdata(0, 'multiaxialFatigue_outOfPlane', get(handles.check_outOfPlane, 'value'))
setappdata(0, 'multiaxialFatigue_ndEndurance', get(handles.check_ndEndurance, 'value'))
setappdata(0, 'multiaxialFatigue_modifyEnduranceLimit', get(handles.check_modifyEnduranceLimit, 'value'))

% Save the GUI state
setappdata(0, 'materialOptions_check_ndCompression', get(handles.check_ndCompression, 'value'))
setappdata(0, 'materialOptions_check_outOfPlane', get(handles.check_outOfPlane, 'value'))

setappdata(0, 'materialOptions_check_ndEndurance', get(handles.check_ndEndurance, 'value'))
setappdata(0, 'materialOptions_check_modifyEnduranceLimit', get(handles.check_modifyEnduranceLimit, 'value'))

setappdata(0, 'materialOptions_rButton_defaultControls', get(handles.rButton_defaultControls, 'value'))
setappdata(0, 'materialOptions_rButton_userControls', get(handles.rButton_userControls, 'value'))

setappdata(0, 'materialOptions_edit_enduranceScaleFactor', get(handles.edit_enduranceScaleFactor, 'string'))
setappdata(0, 'materialOptions_edit_cyclesToRecover', get(handles.edit_cyclesToRecover, 'string'))

close materialOptions


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


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in check_ndEndurance.
function check_ndEndurance_Callback(hObject, ~, handles)
if get(hObject, 'value') == 0.0
    set(handles.check_modifyEnduranceLimit, 'value', 0.0)
    
    set(handles.text_enduranceControls, 'enable', 'off')
    set(handles.rButton_defaultControls, 'enable', 'off')
    set(handles.rButton_userControls, 'enable', 'off')
    
    set(handles.text_enduranceScaleFactor, 'enable', 'off')
    set(handles.text_cyclesToRecover, 'enable', 'off')
    set(handles.text_cycles, 'enable', 'off')
    
    if get(handles.rButton_defaultControls, 'value') == 1.0
        set(handles.edit_cyclesToRecover, 'enable', 'inactive')
        set(handles.edit_enduranceScaleFactor, 'enable', 'inactive')
    else
        set(handles.edit_cyclesToRecover, 'enable', 'off', 'backgroundColor', 'white')
        set(handles.edit_enduranceScaleFactor, 'enable', 'off', 'backgroundColor', 'white')
    end
end


% --- Executes on button press in check_modifyEnduranceLimit.
function check_modifyEnduranceLimit_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.check_ndEndurance, 'value', 1.0)
    
    set(handles.text_enduranceControls, 'enable', 'on')
    set(handles.rButton_defaultControls, 'enable', 'on')
    set(handles.rButton_userControls, 'enable', 'on')
    
    if get(handles.rButton_userControls, 'value') == 1.0
        set(handles.text_enduranceScaleFactor, 'enable', 'on')
        set(handles.edit_enduranceScaleFactor, 'enable', 'on', 'backgroundColor', 'white')
        
        set(handles.text_cyclesToRecover, 'enable', 'on')
        set(handles.edit_cyclesToRecover, 'enable', 'on', 'backgroundColor', 'white')
        set(handles.text_cycles, 'enable', 'on')
    end
else
    set(handles.text_enduranceControls, 'enable', 'off')
    set(handles.rButton_defaultControls, 'enable', 'off')
    set(handles.rButton_userControls, 'enable', 'off')
    
    set(handles.text_enduranceScaleFactor, 'enable', 'off')
    set(handles.text_cyclesToRecover, 'enable', 'off')
    set(handles.text_cycles, 'enable', 'off')
    
    if get(handles.rButton_defaultControls, 'value') == 1.0
        set(handles.edit_cyclesToRecover, 'enable', 'inactive')
        set(handles.edit_enduranceScaleFactor, 'enable', 'inactive')
    else
        set(handles.edit_cyclesToRecover, 'enable', 'off', 'backgroundColor', 'white')
        set(handles.edit_enduranceScaleFactor, 'enable', 'off', 'backgroundColor', 'white')
    end
end


function edit_enduranceScaleFactor_Callback(~, ~, ~)
% hObject    handle to edit_enduranceScaleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_enduranceScaleFactor as text
%        str2double(get(hObject,'String')) returns contents of edit_enduranceScaleFactor as a double


% --- Executes during object creation, after setting all properties.
function edit_enduranceScaleFactor_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_enduranceScaleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_cyclesToRecover_Callback(~, ~, ~)
% hObject    handle to edit_cyclesToRecover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cyclesToRecover as text
%        str2double(get(hObject,'String')) returns contents of edit_cyclesToRecover as a double


% --- Executes during object creation, after setting all properties.
function edit_cyclesToRecover_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_cyclesToRecover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_ndCompression.
function check_ndCompression_Callback(~, ~, ~)
% hObject    handle to check_ndCompression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_ndCompression


% --- Executes on button press in check_outOfPlane.
function check_outOfPlane_Callback(~, ~, ~)
% hObject    handle to check_outOfPlane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_outOfPlane


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(~, ~, ~)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function blank(handles)
set(handles.check_ndCompression, 'enable', 'off')
set(handles.check_outOfPlane, 'enable', 'off')

set(handles.check_ndEndurance, 'enable', 'off')
set(handles.check_modifyEnduranceLimit, 'enable', 'off')

set(handles.text_enduranceControls, 'enable', 'off')
set(handles.rButton_defaultControls, 'enable', 'off')
set(handles.rButton_userControls, 'enable', 'off')

set(handles.text_enduranceScaleFactor, 'enable', 'off')
set(handles.edit_enduranceScaleFactor, 'enable', 'off')

set(handles.text_cyclesToRecover, 'enable', 'off')
set(handles.edit_cyclesToRecover, 'enable', 'off')
set(handles.text_cycles, 'enable', 'off')

set(handles.pButton_ok, 'enable', 'off')
set(handles.pButton_cancel, 'enable', 'off')


function show(handles)
set(handles.check_ndCompression, 'enable', 'on')
set(handles.check_outOfPlane, 'enable', 'on')

set(handles.check_ndEndurance, 'enable', 'on')
set(handles.check_modifyEnduranceLimit, 'enable', 'on')

if get(handles.check_modifyEnduranceLimit, 'value') == 1.0
    set(handles.text_enduranceControls, 'enable', 'on')
    set(handles.rButton_defaultControls, 'enable', 'on')
    set(handles.rButton_userControls, 'enable', 'on')
    
    if get(handles.rButton_userControls, 'value') == 1.0
        set(handles.text_enduranceScaleFactor, 'enable', 'on')
        set(handles.edit_enduranceScaleFactor, 'enable', 'on')
        
        set(handles.text_cyclesToRecover, 'enable', 'on')
        set(handles.edit_cyclesToRecover, 'enable', 'on')
        set(handles.text_cycles, 'enable', 'on')
    end
end

set(handles.pButton_ok, 'enable', 'on')
set(handles.pButton_cancel, 'enable', 'on')


% --- Executes on button press in rButton_defaultControls.
function rButton_defaultControls_Callback(hObject, ~, handles)
if get(hObject, 'value') == 0.0
    set(hObject, 'value', 1.0)
end
set(handles.rButton_userControls, 'value', 0.0)

set(handles.text_enduranceScaleFactor, 'enable', 'off')
set(handles.edit_enduranceScaleFactor, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])

set(handles.text_cyclesToRecover, 'enable', 'off')
set(handles.edit_cyclesToRecover, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
set(handles.text_cycles, 'enable', 'off')


% --- Executes on button press in rButton_userControls.
function rButton_userControls_Callback(hObject, ~, handles)
if get(hObject, 'value') == 0.0
    set(hObject, 'value', 1.0)
end
set(handles.rButton_defaultControls, 'value', 0.0)

set(handles.text_enduranceScaleFactor, 'enable', 'on')
set(handles.edit_enduranceScaleFactor, 'enable', 'on', 'backgroundColor', 'white')

set(handles.text_cyclesToRecover, 'enable', 'on')
set(handles.edit_cyclesToRecover, 'enable', 'on', 'backgroundColor', 'white')
set(handles.text_cycles, 'enable', 'on')

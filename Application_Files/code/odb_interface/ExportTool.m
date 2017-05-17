function varargout = ExportTool(varargin)%#ok<*DEFNU>
%EXPORTTOOL    QFT functions for ODB Interface.
%   These functions are used to call and operate the Export Tool
%   application.
%   
%   EXPORTTOOL is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also python.
%
%   Reference section in Quick Fatigue Tool User Guide
%      10.4 The ODB Interface
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExportTool_OpeningFcn, ...
                   'gui_OutputFcn',  @ExportTool_OutputFcn, ...
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


% --- Executes just before ExportTool is made visible.
function ExportTool_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ExportTool (see VARARGIN)
clc

approot = [getenv('USERPROFILE'), '\Documents\MATLAB\Apps\Export Tool'];

if exist(approot, 'dir')
    addpath(approot)
end

% Choose default command line output for ExportTool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ExportTool wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% Load the panel state
set(handles.edit_fieldData, 'string', getappdata(0, 'panel_exportTool_edit_fieldData'))

set(handles.edit_modelFile, 'string', getappdata(0, 'panel_exportTool_edit_modelFile'))

if isempty(getappdata(0, 'panel_exportTool_check_resultFile')) == 0.0
    set(handles.check_resultFile, 'value', getappdata(0, 'panel_exportTool_check_resultFile'))
end

if isempty(getappdata(0, 'panel_exportTool_edit_resultFile')) == 1.0
    set(handles.check_resultFile, 'value', 0.0)
    if exist([pwd, '\Project\output'], 'dir') == 7.0
        set(handles.edit_resultFile, 'string', [pwd, '\Project\output'], 'backgroundColor', [241/255, 241/255, 241/255], 'enable', 'inactive')
    else
        set(handles.edit_resultFile, 'string', [pwd, '\Project'], 'backgroundColor', [241/255, 241/255, 241/255], 'enable', 'inactive')
    end
    set(handles.pButton_findResultFile, 'enable', 'off')
else
    set(handles.edit_resultFile, 'string', getappdata(0, 'panel_exportTool_edit_resultFile'))
end

if get(handles.check_resultFile, 'value') == 1.0
    set(handles.edit_resultFile, 'enable', 'on', 'backgroundColor', 'white')
    set(handles.pButton_findResultFile, 'enable', 'on')
else
    set(handles.edit_resultFile, 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
    set(handles.pButton_findResultFile, 'enable', 'off')
end

set(handles.edit_partInstance, 'string', getappdata(0, 'panel_exportTool_edit_partInstance'))
set(handles.edit_resultsStepName, 'string', getappdata(0, 'panel_exportTool_edit_resultsStepName'))

if isempty(getappdata(0, 'panel_exportTool_pMenu_elementPosition')) == 0.0
    set(handles.pMenu_elementPosition, 'value', getappdata(0, 'panel_exportTool_pMenu_elementPosition'))
    set(handles.check_autoDeterminePosition, 'value', getappdata(0, 'panel_exportTool_check_autoDeterminePosition'))
    set(handles.check_keepScript, 'value', getappdata(0, 'panel_exportTool_check_keepScript'))
    set(handles.check_writeScriptOnly, 'value', getappdata(0, 'panel_exportTool_check_writeScriptOnly'))
    
    set(handles.edit_ODBSetName, 'string', getappdata(0, 'panel_exportTool_edit_ODBSetName'))
    if getappdata(0, 'panel_exportTool_check_createODBSet') == 1.0
        set(handles.check_createODBSet, 'value', 1.0)
        set(handles.edit_ODBSetName, 'enable', 'on', 'backgroundColor', 'white')
    else
        set(handles.check_createODBSet, 'value', 0.0)
        set(handles.edit_ODBSetName, 'enable', 'inactive', 'backgroundColor', [177/256, 206/256, 237/256])
    end
end

if isappdata(0, 'panel_exportTool_check_upgrade') == 1.0
    set(handles.check_upgrade, 'value', getappdata(0, 'panel_exportTool_check_upgrade'))
end

if isappdata(0, 'panel_exportTool_edit_abqCmd') == 1.0
    set(handles.edit_abqCmd, 'string', getappdata(0, 'panel_exportTool_edit_abqCmd'))
end

if isappdata(0, 'panel_exportTool_check_isExplicit') == 1.0
    set(handles.check_isExplicit, 'value', getappdata(0, 'panel_exportTool_check_isExplicit'))
    set(handles.rButton_createNewStep, 'value', getappdata(0, 'panel_exportTool_rButton_createNewStep'))
    set(handles.rButton_specifyExistingStep, 'value', getappdata(0, 'panel_exportTool_rButton_specifyExistingStep'))
    
    if get(handles.rButton_specifyExistingStep, 'value') == 1.0
        set(handles.check_isExplicit, 'enable', 'off')
        set(handles.edit_resultsStepName, 'backgroundColor', 'white')
    end
end

if isappdata(0, 'panel_exportTool_rButton_selectFromList') == 1.0
    set(handles.rButton_selectFromList, 'value', getappdata(0, 'panel_exportTool_rButton_selectFromList'))
    set(handles.rButton_preselect, 'value', getappdata(0, 'panel_exportTool_rButton_preselect'))
    set(handles.rButton_selectAll, 'value', getappdata(0, 'panel_exportTool_rButton_selectAll'))
end

if isempty(getappdata(0, 'panel_exportTool_check_LL')) == 0.0
    set(handles.check_LL, 'value', getappdata(0, 'panel_exportTool_check_LL'))
    set(handles.check_L, 'value', getappdata(0, 'panel_exportTool_check_L'))
    set(handles.check_D, 'value', getappdata(0, 'panel_exportTool_check_D'))
    set(handles.check_DDL, 'value', getappdata(0, 'panel_exportTool_check_DDL'))
    set(handles.check_FOS, 'value', getappdata(0, 'panel_exportTool_check_FOS'))
    set(handles.check_SFA, 'value', getappdata(0, 'panel_exportTool_check_SFA'))
    set(handles.check_FRFR, 'value', getappdata(0, 'panel_exportTool_check_FRFR'))
    set(handles.check_FRFV, 'value', getappdata(0, 'panel_exportTool_check_FRFV'))
    set(handles.check_FRFH, 'value', getappdata(0, 'panel_exportTool_check_FRFH'))
    set(handles.check_FRFW, 'value', getappdata(0, 'panel_exportTool_check_FRFW'))
    set(handles.check_SMAX, 'value', getappdata(0, 'panel_exportTool_check_SMAX'))
    set(handles.check_SMXP, 'value', getappdata(0, 'panel_exportTool_check_SMXP'))
    set(handles.check_SMXU, 'value', getappdata(0, 'panel_exportTool_check_SMXU'))
    set(handles.check_TRF, 'value', getappdata(0, 'panel_exportTool_check_TRF'))
    set(handles.check_WCM, 'value', getappdata(0, 'panel_exportTool_check_WCM'))
    set(handles.check_WCA, 'value', getappdata(0, 'panel_exportTool_check_WCA'))
    set(handles.check_WCDP, 'value', getappdata(0, 'panel_exportTool_check_WCDP'))
    set(handles.check_WCATAN, 'value', getappdata(0, 'panel_exportTool_check_WCATAN'))
    
    set(handles.check_copyToClipboard, 'value', getappdata(0, 'panel_exportTool_check_copyToClipboard'))
end

% Load the help icon
[a,~]=imread('icoR_info.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.frame_modelInfo, 'CData', g);

% Load the tips icon
[a,~]=imread('icoR_bulb.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_dataPositionHelp, 'CData', g);

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
function varargout = ExportTool_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in check_L.
function check_L_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_LL.
function check_LL_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_D.
function check_D_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_DDL.
function check_DDL_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_FOS.
function check_FOS_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_SFA.
function check_SFA_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_FRFR.
function check_FRFR_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_FRFV.
function check_FRFV_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_FRFH.
function check_FRFH_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_FRFW.
function check_FRFW_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_SMAX.
function check_SMAX_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_SMXP.
function check_SMXP_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_SMXU.
function check_SMXU_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_TRF.
function check_TRF_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_WCM.
function check_WCM_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_WCA.
function check_WCA_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_WCATAN.
function check_WCATAN_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_YIELD.
function check_YIELD_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_WCDP.
function check_WCDP_Callback(~, ~, handles)
set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in pButton_cancel.
function pButton_cancel_Callback(~, ~, ~)
close ExportTool

% --- Executes on button press in pButton_start.
function pButton_start_Callback(hObject, eventdata, handles)
% Blank the GUI
blankGUI(handles)
pause(1e-6)
warning('off', 'all')

% Flag to indicate the ODB Interface is operating in app mode
setappdata(0, 'ODB_interface_auto', 0.0)

% Warn user that results will not be written to the ODB in certain cases
if get(handles.check_writeScriptOnly, 'value') == 1.0
    % If "Write python script only" is checked
    response = questdlg('The option "Write python script only" is selected. Results will not be written to the ODB. OK to continue?', 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
    
    if strcmpi(response, 'No') == 1.0
        enableGUI(handles)
        warning('on', 'all')
        return
    end
end

% Get path and name of field data
fieldDataPath = get(handles.edit_fieldData, 'string');
[~, fieldDataName, EXT] = fileparts(fieldDataPath);
fieldDataName = [fieldDataName, EXT];

% Get path and name of model output database
modelDatabasePath = get(handles.edit_modelFile, 'string');
[~, modelDatabaseNameShort, EXT] = fileparts(modelDatabasePath);
modelDatabaseName = [modelDatabaseNameShort, EXT];

% Try to get the job name from the field output file
try
    fid = fopen(fieldDataPath, 'r');
    fgetl(fid);
    fileExtension = fgetl(fid);
    fileExtension = [fileExtension(6:end), 'Results'];
    
    if isempty(fileExtension) == 1.0
        fileExtension = 'Results';
    else
        % Check the job name for illegal characters
        jobNameLength = length(fileExtension);
        
        temp = length(strtok(fileExtension, ' '));
        
        if temp ~= jobNameLength
            message = sprintf('The job name cannot contain spaces. Rename the job in the field data file');
            errordlg(message, 'Quick Fatigue Tool')
            uiwait
            
            enableGUI(handles)
            warning('on', 'all')
            return
        end
        
        temp(1.0) = length(strtok(fileExtension, '/'));
        temp(2.0) = length(strtok(fileExtension, '\'));
        temp(3.0) = length(strtok(fileExtension, '*'));
        temp(4.0) = length(strtok(fileExtension, ':'));
        temp(5.0) = length(strtok(fileExtension, '?'));
        temp(6.0) = length(strtok(fileExtension, '"'));
        temp(7.0) = length(strtok(fileExtension, '<'));
        temp(8.0) = length(strtok(fileExtension, '>'));
        temp(9.0) = length(strtok(fileExtension, '|'));
        
        if any(temp ~= jobNameLength) == 1.0
            message1 = sprintf('The job name cannot contain any of the following characters:\n\n');
            message2 = sprintf('/ \\ * : ? " < > |\n\n');
            message3 = sprintf('Rename the job in the field data file.');
            errordlg([message1, message2, message3], 'Quick Fatigue Tool')
            uiwait
            
            enableGUI(handles)
            warning('on', 'all')
            return
        end
    end
catch
    fileExtension = 'Results';
end

% Get name and directory of results output database
resultsDatabasePath = get(handles.edit_resultFile, 'string');
resultsDatabaseName = [modelDatabaseNameShort, sprintf('_%s', fileExtension)];

% Replace back slashes with forward slashes
for i = 1:length(resultsDatabasePath)
    if strcmp(resultsDatabasePath(i), '\') == 1.0
        resultsDatabasePath(i) = '/';
    end
end
for i = 1:length(modelDatabasePath)
    if strcmp(modelDatabasePath(i), '\') == 1.0
        modelDatabasePath(i) = '/';
    end
end

% Get the part instance name
partInstanceList = get(handles.edit_partInstance, 'string');

% Check if there are multiple part instances
partInstanceList = python.checkMultipleInstances(partInstanceList);

% Get the number of part instances
nInstances = length(partInstanceList);

% Get the results step type
if get(handles.rButton_createNewStep, 'value') == 1.0
    if nInstances > 1.0
        stepType_m = [1.0, linspace(2.0, 2.0, (nInstances - 1.0))];
    else
        stepType_m = 1.0;
    end
else
    stepType_m = linspace(2.0, 2.0, nInstances);
end

% Get the results step name
stepName = get(handles.edit_resultsStepName, 'string');

% Get the element/node set name (if applicable)
createODBSet = 0.0;
ODBSetName = [];
if (get(handles.check_createODBSet, 'value') == 1.0) && (nInstances == 1.0)
    ODBSetName = get(handles.edit_ODBSetName, 'string');
    
    if (isempty(ODBSetName) == 1.0) || (ischar(ODBSetName) == 0.0)
        msg = sprintf('An element/node set must be specified.');
        errordlg(msg, 'Quick Fatigue Tool')
        uiwait
        enableGUI(handles)
        warning('on', 'all')
        return
    end
    
    createODBSet = 1.0;
end

% Collect requested fields
if get(handles.rButton_selectFromList, 'value') == 1.0
    requestedFields = [get(handles.check_LL, 'value'),...
        get(handles.check_L, 'value'),...
        get(handles.check_D, 'value'),...
        get(handles.check_DDL, 'value'),...
        get(handles.check_FOS, 'value'),...
        get(handles.check_SFA, 'value'),...
        get(handles.check_FRFR, 'value'),...
        get(handles.check_FRFV, 'value'),...
        get(handles.check_FRFH, 'value'),...
        get(handles.check_FRFW, 'value'),...
        get(handles.check_SMAX, 'value'),...
        get(handles.check_SMXP, 'value'),...
        get(handles.check_SMXU, 'value'),...
        get(handles.check_TRF, 'value'),...
        get(handles.check_WCM, 'value'),...
        get(handles.check_WCA, 'value'),...
        get(handles.check_WCDP, 'value'),...
        get(handles.check_WCATAN, 'value'), ...
        0.0];
elseif get(handles.rButton_preselect, 'value') == 1.0
    requestedFields = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0,...
        1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0];
else
    requestedFields = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,...
        1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0];
end

% Verify the inputs
error = python.verify(hObject, eventdata, handles, requestedFields,...
    fieldDataPath, fieldDataName, modelDatabasePath, modelDatabaseName,...
    resultsDatabasePath, partInstanceList, stepType_m, stepName);

% If there was an error whilst verifying the inputs, stop execution
if error == 1.0
    enableGUI(handles)
    warning('on', 'all')
    return
end

%{
    If an .odb file of the same name already exists in the directory, ask
    the user if they wish to overwrite the file, or keep it
%}
if exist([resultsDatabasePath, '/', resultsDatabaseName, '.odb'], 'file') == 2.0 && (get(handles.check_writeScriptOnly, 'value') == 0.0)
    % The file already exists, so prompt the user
    msg = sprintf('The output directory ''%s'' already contains a file called ''%s''', resultsDatabasePath, [resultsDatabaseName, '.odb']);
    response = questdlg(msg, 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Abort procedure', 'Overwrite');
    
    if isempty(response) == 1.0 || strcmpi(response, 'Abort procedure') == 1.0
        enableGUI(handles)
        warning('on', 'all')
        return
    elseif strcmpi(response, 'Overwrite') == 1.0
        % Try to delete the file
        lastwarn('')
        delete([resultsDatabasePath, '/', resultsDatabaseName, '.odb'])
        [~, msgid] = lastwarn;
        if strcmpi(msgid, 'MATLAB:DELETE:Permission') == 1.0
            clc
            msg = sprintf('The file ''%s'' could not be overwritten (permission denied).\n\nMake sure the .odb file is not currently open in Abaqus/Viewer.',...
                [resultsDatabaseName, '.odb']);
            errordlg(msg, 'Quick Fatigue Tool')
            uiwait
            enableGUI(handles)
            warning('on', 'all')
            return
        end
    else
        % Change the name of the new results output database
        while exist([resultsDatabaseName, '.odb'], 'file') == 2.0
            resultsDatabaseName = [resultsDatabaseName , '-1']; %#ok<AGROW>
        end
    end
end

% Get the Abaqus command line argument
abqCmd = get(handles.edit_abqCmd, 'string');
if isempty(abqCmd) == 1.0
    abqCmd = 'abaqus';
end
setappdata(0, 'autoExport_abqCmd', abqCmd)

% Copy the model output database to the abaqus directory
% First, try to upgrade the ODB
if get(handles.check_upgrade, 'value') == 1.0
    [status, result] = system(sprintf('%s -upgrade -job "%s" -odb "%s"', abqCmd, [resultsDatabasePath, '/', resultsDatabaseName], modelDatabasePath(1:end - 4.0)));
    
    if status == 1.0
        % Check the nature of the error
        if isempty(strfind(result, 'The database is from a previous release of Abaqus.')) == 0.0
           errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s\r\nPlease do one of the following:\r\n\r\nSelect "Upgrade ODB file" and specify the Abaqus command line argument of the version you wish to upgrade to (default is ''abaqus.bat'' if no command is specified).\r\n\r\nSpecify the Abaqus command line argument corresponding to the version of the model ODB file.', result), 'Quick Fatigue Tool') 
        elseif isempty(strfind(result, 'is not recognized as an internal or external command')) == 0.0
            errordlg(sprintf('The system prompt returned the following error:\r\n\r\n%s\r\nThe specified version of Abaqus could not be found. Make sure the Abaqus command line argument refers to an existing batch file on your system.', result), 'Quick Fatigue Tool') 
        else
            errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s', result), 'Quick Fatigue Tool')
        end
        
        uiwait
        enableGUI(handles)
        clc
        warning('on', 'all')
        return
    end
else
    result = '123456789';
end

% If the ODB is already up-to-date, simply copy the file instead
if exist([resultsDatabasePath, '/', resultsDatabaseName, '.odb'], 'file') == 0.0
    try
        copyfile(modelDatabasePath, [resultsDatabasePath, '/', resultsDatabaseName, '.odb'])
    catch
        clc
        
        if strcmp(result(1:9), '*** Error') == 1.0
            msg1 = sprintf('The Abaqus API returned the following error:\n\n%s', result);
            msg2 = sprintf('\n\nThe results database name is taken from the job name in the field data file.');
            msg3 = sprintf(' If the file contains formatting errors, this could lead to an invalid file name.');
            errordlg([msg1, msg2, msg3], 'Quick Fatigue Tool')
        else
            msg1 = sprintf('The model output database file\n\n''%s''\n\ncould not be copied.', [resultsDatabaseName, '.odb']);
            msg2 = sprintf('\n\nThe results database name is taken from the job name in the field data file.');
            msg3 = sprintf(' If the file contains formatting errors, this could lead to an invalid file name.');
            errordlg([msg1, msg2, msg3], 'Quick Fatigue Tool')
        end
        
        uiwait
        enableGUI(handles)
        warning('on', 'all')
        return
    end
end

% Delete the upgrade log file if it exists
delete([resultsDatabasePath, '/', resultsDatabaseName, '-upgrade', '.log'])
if exist([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'], 'file') == 2.0
    delete([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'])
end

% Remove the lock file if it exists
if exist([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'], 'file') == 2.0
    delete([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'])
end

% Open the log file for writing
fid_debug = fopen(sprintf('%s\\%s.log', resultsDatabasePath, resultsDatabaseName), 'w+');
clc
fprintf(fid_debug, 'Quick Fatigue Tool 6.10-08 ODB Interface Log');
fprintf('Quick Fatigue Tool 6.10-08 ODB Interface Log\n');

% Get the selected position
userPosition = get(handles.pMenu_elementPosition, 'value');
positions = get(handles.pMenu_elementPosition, 'string');
fprintf(fid_debug, '\r\n\r\nUser-selected results position: %s', positions{userPosition});
fprintf('\nUser-selected results position: %s\n', positions{userPosition});

% Check if position should be determined automatically
autoPosition = get(handles.check_autoDeterminePosition, 'value');
if autoPosition == 1.0
    fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: YES');
    fprintf('Allow Quick Fatigue Tool to determine results position based on field IDs: YES\n');
else
    fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: NO');
    fprintf('Allow Quick Fatigue Tool to determine results position based on field IDs: NO\n');
end

%{
    If multiple part instances were specified, loop over each instance from
    this point forward
%}
for instanceNumber = 1:nInstances
    partInstanceName = partInstanceList{instanceNumber};
    stepType = stepType_m(instanceNumber);
    
    % Get the field data
    fprintf(fid_debug, '\r\n\r\nCollecting field data for instance ''%s''...', partInstanceName);
    fprintf('Collecting field data for instance ''%s''...\n', partInstanceName);
    [positionLabels, position, positionLabelData, positionID, connectivity,...
        mainIDs, subIDs, stepDescription, fieldData, fieldNames,...
        connectedElements, error] = python.getFieldData(fieldDataPath,...
        requestedFields, userPosition, partInstanceName,...
        autoPosition, fid_debug, resultsDatabasePath, resultsDatabaseName);
    
    if error > 0.0
        if error == 1.0
            errordlg('No matching position labels were found in the model output database. Check the log file for details.', 'Quick Fatigue Tool')
        elseif error == 2.0
            errordlg('An error occurred while retrieving the connectivity matrix. Check the log file for details.', 'Quick Fatigue Tool')
        elseif error == 3.0
            errordlg('An error occurred while reading the connectivity matrix. Check the log file for details.', 'Quick Fatigue Tool')
        elseif error == 4.0
            errordlg('An error occurred while reading the field data file. Check the log file for details.', 'Quick Fatigue Tool')
        elseif error == 5.0
            if isempty(strfind(getappdata(0, 'abqAPIError'), 'The database is from a previous release of Abaqus.')) == 0.0
                errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s\r\nPlease do one of the following:\r\n\r\nSelect "Upgrade ODB file" and specify the Abaqus command line argument of the version you wish to upgrade to (default is ''abaqus.bat'' if no command is specified).\r\n\r\nSpecify the Abaqus command line argument corresponding to the version of the model ODB file.', getappdata(0, 'abqAPIError')), 'Quick Fatigue Tool') 
            elseif isempty(strfind(getappdata(0, 'abqAPIError'), sprintf('numberOfElements = len(odb.rootAssembly.instances[''%s'']', partInstanceName))) == 0.0
                errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s\r\nThe specified part instance could not be found in the output database file.', getappdata(0, 'abqAPIError')), 'Quick Fatigue Tool')
            elseif isempty(strfind(getappdata(0, 'abqAPIError'), sprintf('''%s'' is not recognized as an internal or external command', abqCmd))) == 0.0
                errordlg(sprintf('The system prompt returned the following error:\r\n\r\n%s\r\nThe specified version of Abaqus could not be found. Make sure the Abaqus command line argument refers to an existing batch file on your system.', getappdata(0, 'abqAPIError')), 'Quick Fatigue Tool')
            else
                errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s\r\nCheck the Export Tool inputs for possible errors.', getappdata(0, 'abqAPIError')), 'Quick Fatigue Tool')
            end
            
            rmappdata(0, 'abqAPIError')
        end
        
        delete([resultsDatabasePath, '\', resultsDatabaseName, '.odb'])
        
        uiwait
        enableGUI(handles)
        fclose(fid_debug);
        clc
        warning('on', 'all')
        return
    end
    
    % Determine whether the FEA was from an Abaqus/Explicit procedure
    isExplicit = get(handles.check_isExplicit, 'value');
    
    % Create the Python script
    fprintf(fid_debug, '\r\n\r\nPreparing field data...');
    fprintf('Preparing field data...\n');
    [scriptFile, newLocation, stepName, error] = python.writePythonScript(resultsDatabaseName,...
        resultsDatabasePath, partInstanceName, positionLabels,...
        position, positionLabelData, positionID, connectivity, mainIDs,...
        subIDs, stepDescription, fieldData, fieldNames, fid_debug, stepName,...
        isExplicit, connectedElements, createODBSet, ODBSetName, stepType);
    
    % If there was an error while writing the field data, abort the export process
    if error == 1.0
        msg1 = sprintf('An error occurred while writing field data to the output database.\n\n');
        msg2 = sprintf('Consistent element-node IDs for instance ''%s'' could not be found between the model output database and the field data (matching node IDs contain zero-valued indices)', partInstanceName);
        msg3 = sprintf('\r\n\r\nThis can occur when an invalid part instance is specified.');
        errordlg([msg1, msg2, msg3], 'Quick Fatigue Tool');
        
        uiwait
        enableGUI(handles)
        fclose(fid_debug);
        clc
        warning('on', 'all')
        return
    end
    
    %{
        If the user requested to retain the python script, copy the file to
        the results database directory
    %}
    if (get(handles.check_writeScriptOnly, 'value') == 1.0) || (get(handles.check_keepScript, 'value') == 1.0)
        if nInstances > 1.0
            copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, sprintf('_%s', partInstanceName), '.py'])
        else
            copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, '.py'])
        end
    end
    
    % System command to execute python script
    if get(handles.check_writeScriptOnly, 'value') == 0.0
        fprintf(fid_debug, '\r\n\r\nWriting field data to ODB...');
        fprintf('Writing field data to ODB...\n');
        
        try
            [status, message] = system(sprintf('%s python %s', abqCmd, scriptFile));
            
            if status == 1.0
                if isempty(strfind(message, sprintf('KeyError: ''%s''', stepName))) == 0.0
                    % The step name is invalid
                    errordlg(sprintf('The step name ''%s'' could not be found in the ODB. Results will not be written to the output database.', stepName), 'Quick Fatigue Tool')
                elseif isempty(strfind(message, 'OdbError: Invalid node label')) == 0.0
                    %{
                        The field data does not exactly match the part
                        instance name, so an ODB element/node set could not
                        be created
                    %}
                    errordlg(sprintf('The ODB element/node set could not be written because the field data does not exactly match the specified part instance. Results will not be written to the output database.'), 'Quick Fatigue Tool')
                elseif isempty(strfind(message, 'is not recognized as an internal or external command')) == 0.0
                    % There is no Abaqus executable on the host machine
                    errordlg(sprintf('The Abaqus command ''%s'' could not be found on the system. Check your Abaqus installation. Results will not be written to the output database.', abqCmd), 'Quick Fatigue Tool')
                else
                    % Unkown exception
                    errordlg(sprintf('The Abaqus API returned the following error:\r\n\r\n%s\r\nResults will not be written to the output database.', message), 'Quick Fatigue Tool')
                end
                
                uiwait
                delete(scriptFile)
                enableGUI(handles)
                clc
                warning('on', 'all')
                return
            end
        catch unhandledException
            fprintf(fid_debug, '\r\nError: %s', unhandledException.message);
            errordlg('An unknown exception was encountered while writing field data to the output database', 'Quick Fatigue Tool')
            
            uiwait
            enableGUI(handles)
            fclose(fid_debug);
            clc
            
            if get(handles.check_keepScript, 'value') == 0.0 && get(handles.check_writeScriptOnly, 'value') == 0.0
                delete(scriptFile)
            end
            warning('on', 'all')
            return
        end
    elseif instanceNumber == nInstances
        delete(newLocation)
    end
end

fprintf(fid_debug, ' Success');
fprintf('\nExport complete. View the log file for a detailed summary of the process\n');
fclose(fid_debug);

% Delete the Python script
delete(scriptFile)

% Copy the results ODB path to the clipboard
if get(handles.check_copyToClipboard, 'value') == 1.0
    clipboard('copy', which([resultsDatabasePath, '/', resultsDatabaseName, '.odb']))
end

% Re-enable the GUI
close ExportTool


function edit_fieldData_Callback(~, ~, ~)
% hObject    handle to edit_fieldData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fieldData as text
%        str2double(get(hObject,'String')) returns contents of edit_fieldData as a double


% --- Executes during object creation, after setting all properties.
function edit_fieldData_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_fieldData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_keepScript.
function check_keepScript_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 1.0
        set(handles.check_writeScriptOnly, 'value', 0.0)
end


function edit_modelFile_Callback(~, ~, ~)
% hObject    handle to edit_modelFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_modelFile as text
%        str2double(get(hObject,'String')) returns contents of edit_modelFile as a double


% --- Executes during object creation, after setting all properties.
function edit_modelFile_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_modelFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButon_findFieldData.
function pButon_findFieldData_Callback(~, ~, handles)
% Blank the GUI
blankGUI(handles)

% Define the start path
if isappdata(0, 'panel_exportTool_field_path') == 1.0
    startPath_field = getappdata(0, 'panel_exportTool_field_path');
else
    startPath_field = [pwd, '/Project/output'];
end

% Get the file
[filename, pathname] = uigetfile({'*.dat', 'Field Data File'; '*.*', 'All Files (*.*)'},...
    'Field Data File', startPath_field);
fullpath = [pathname, filename];

if isequal(filename,0) || isequal(pathname,0)
    % User cancelled operation
    enableGUI(handles)
else
    enableGUI(handles)
    
    set(handles.edit_fieldData, 'string', fullpath)
    
    % Save the file path
    setappdata(0, 'panel_exportTool_field_path', pathname)
    
    % If the results database path checkbox is de-selected, set the results path automatically
    if get(handles.check_resultFile, 'value') == 0.0
        set(handles.edit_resultFile, 'string', pathname(1.0:end - 1.0))
        setappdata(0, 'panel_exportTool_results_path', pathname(1.0:end - 1.0))
    end
end


% --- Executes on button press in pButton_findModelFile.
function pButton_findModelFile_Callback(~, ~, handles)
% Blank the GUI
blankGUI(handles)

% Define the start path
if isappdata(0, 'panel_exportTool_model_path') == 1.0
    startPath_model = getappdata(0, 'panel_exportTool_model_path');
else
    startPath_model = pwd;
end

% Get the file
[filename, pathname] = uigetfile({'*.odb', 'Output Databse File'},...
    'FEA Source ODB File', startPath_model);
fullpath = [pathname, filename];

if isequal(filename,0) || isequal(pathname,0)
    % User cancelled operation
else
    set(handles.edit_modelFile, 'string', fullpath)
    
    % Save the file path
    setappdata(0, 'panel_exportTool_model_path', pathname)
end
enableGUI(handles)


function edit_partInstance_Callback(~, ~, ~)
% hObject    handle to edit_partInstance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_partInstance as text
%        str2double(get(hObject,'String')) returns contents of edit_partInstance as a double


% --- Executes during object creation, after setting all properties.
function edit_partInstance_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_partInstance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_resultsStepName_Callback(~, ~, ~)
% hObject    handle to edit_resultsStepName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_resultsStepName as text
%        str2double(get(hObject,'String')) returns contents of edit_resultsStepName as a double


% --- Executes during object creation, after setting all properties.
function edit_resultsStepName_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_resultsStepName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pMenu_elementPosition.
function pMenu_elementPosition_Callback(~, ~, ~)
% hObject    handle to pMenu_elementPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pMenu_elementPosition contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pMenu_elementPosition


% --- Executes during object creation, after setting all properties.
function pMenu_elementPosition_CreateFcn(hObject, ~, ~)
% hObject    handle to pMenu_elementPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in check_autoDeterminePosition.
function check_autoDeterminePosition_Callback(hObject, ~, handles)
blankGUI(handles)

if get(hObject, 'value') == 1.0
    msg1 = sprintf('The results position will be determined by the number of columns in the field data file.');
    msg2 = sprintf('\n\nField data may be written to incorrect locations.');
    
    helpdlg([msg1, msg2], 'Quick fatigue Tool')
else
    resultsPosition = get(handles.pMenu_elementPosition, 'value');
    switch resultsPosition
        case 1.0
            position = 'element-nodal (nodal unaveraged)';
        case 2.0
            position = 'unique nodal (nodal averaged)';
        case 3.0
            position = 'integration point';
        case 4.0
            position = 'centroidal';
    end
    
    msg = sprintf('The results position will be assumed as %s.', position);
    helpdlg(msg, 'Quick fatigue Tool')
end

uiwait
enableGUI(handles)


% --- Executes on button press in check_writeScriptOnly.
function check_writeScriptOnly_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 1.0
        set(handles.check_keepScript, 'value', 0.0)
end


% --- Executes on button press in check_copyToClipboard.
function check_copyToClipboard_Callback(~, ~, ~)
% hObject    handle to check_copyToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_copyToClipboard


function edit_resultFile_Callback(~, ~, ~)
% hObject    handle to edit_resultFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_resultFile as text
%        str2double(get(hObject,'String')) returns contents of edit_resultFile as a double


% --- Executes during object creation, after setting all properties.
function edit_resultFile_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_resultFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_findResultFile.
function pButton_findResultFile_Callback(~, ~, handles)
% Blank the GUI
blankGUI(handles)

% Define the start path
if isappdata(0, 'panel_exportTool_results_path') == 1.0
    startPath_results = getappdata(0, 'panel_exportTool_results_path');
else
    startPath_results = [pwd, '\Project\output'];
end

location = uigetdir(startPath_results, 'Fatigue Results ODB File');

if location == 0.0
    % User cancelled operation
else
    set(handles.edit_resultFile, 'string', location)
    
    % Save the file path
    setappdata(0, 'panel_exportTool_results_path', location)
end
enableGUI(handles)


% --- Executes on button press in check_resultFile.
function check_resultFile_Callback(hObject, ~, handles)
switch get(hObject, 'value')
    case 0.0
        set(handles.edit_resultFile, 'enable', 'inactive', 'backgroundColor', [241/255, 241/255, 241/255])
        if exist([pwd, '/Project/output'], 'dir') == 7.0
            set(handles.edit_resultFile, 'string', [pwd, '\Project\output'])
        else
            set(handles.edit_resultFile, 'string', [pwd, '\Project'])
        end
        set(handles.pButton_findResultFile, 'enable', 'off')
    case 1.0
        set(handles.edit_resultFile, 'enable', 'on', 'backgroundColor', 'white')
        if isappdata(0, 'panel_exportTool_results_path') == 1.0
            set(handles.edit_resultFile, 'string', getappdata(0, 'panel_exportTool_results_path'))
        end
        
        set(handles.pButton_findResultFile, 'enable', 'on')
end


% --- Executes on button press in pButton_fieldDataHelp.
function pButton_fieldDataHelp_Callback(~, ~, handles)
blankGUI(handles)

msg1 = sprintf('Select the field data file from the project output directory.');
msg2 = sprintf('\n\n(e.g. Project\\output\\<JobName>\\Data Files\\f-output-all.dat)');

helpdlg([msg1, msg2], 'Quick fatigue Tool')

uiwait
enableGUI(handles)


% --- Executes on button press in pButton_modelFileHelp.
function pButton_modelFileHelp_Callback(~, ~, handles)
blankGUI(handles)

msg1 = sprintf('Select the output database (.odb) file which was used');
msg2 = sprintf('\nto write stress data to the .rpt file.');

helpdlg([msg1, msg2], 'Quick fatigue Tool')

uiwait
enableGUI(handles)


% --- Executes on button press in pButton_dataPositionHelp.
function pButton_dataPositionHelp_Callback(~, ~, handles)
blankGUI(handles)

msg1 = sprintf('*Abaqus command line argument:');
msg2 = sprintf('\nSpecify the command used to access the Abaqus API.');
msg3 = sprintf('\nIf no argument is specified, ''abaqus'' is used by default.');

msg4 = sprintf('\n\n*ODB part instance name:');
msg5 = sprintf('\nExport Tool can write field data to a single part instance.');
msg6 = sprintf('\nThe part instance name must be specified.');

msg7 = sprintf('\n\n*Results step name:');
msg8 = sprintf('\nIf field data is written to an existing step in the ODB, the step name');
msg9 = sprintf('\nis optional. If no name is specified, a default name will be used.');
msg10 = sprintf('\nIf field data is written to an existing step in the ODB, the step name');
msg11 = sprintf('\nmust be specified.');

msg12 = sprintf('\n\n*Explicit FEA:');
msg13 = sprintf('\nThis option must be selected if the previous FE analysis step was a procedure of type *DYNAMIC, EXPLICIT.');

msg14 = sprintf('\n\n*Result position:');
msg15 = sprintf('\nQuick Fatigue Tool does not know the position of the field data by');
msg16 = sprintf('\ndefault. The user must indicate from where the field data originates.');

msg17 = sprintf('\n\n*Determine position from field IDs:');
msg18 = sprintf('\nIf the position of the field data is unknown, checking this option allows');
msg19 = sprintf('\nQuick Fatigue Tool to guess the position based on the format of the field');
msg20 = sprintf('\nIDs. Use of this option may lead to the fatigue results being written to');
msg21 = sprintf('\nincorrect locations.');

msg22 = sprintf('\n\n*Retain python script after execution:');
msg23 = sprintf('\nKeep a copy of the python script used to write output to the output database.');
msg24 = sprintf(' The script is stored in the same location as the results .odb file.');

msg25 = sprintf('\n\n*Write python script only:');
msg26 = sprintf('\nThe python script is written, but not submitted to the Abaqus API.');
msg27 = sprintf(' No output database file is created.');

helpdlg([msg1, msg2, msg3, msg4, msg5, msg6, msg7, msg8, msg9, msg10, msg11, msg12, msg13, msg14, msg15, msg16, msg17, msg18, msg19, msg20, msg21, msg22, msg23, msg24, msg25, msg26, msg27], 'Quick fatigue Tool')

uiwait
enableGUI(handles)


% --- Executes on button press in pButton_resultsFileHelp.
function pButton_resultsFileHelp_Callback(~, ~, handles)
blankGUI(handles)

msg1 = sprintf('Select the directory to which the results output database (.odb) file is written.');

helpdlg(msg1, 'Quick fatigue Tool')

uiwait
enableGUI(handles)


% --- Executes on button press in pButton_reset.
function pButton_reset_Callback(hObject, eventdata, handles)
%Reset default directories
setappdata(0, 'panel_exportTool_field_path', [pwd, '\Project\output'])
setappdata(0, 'panel_exportTool_model_path', pwd)
setappdata(0, 'panel_exportTool_results_path', [pwd, '\Project\output'])

set(handles.edit_fieldData, 'string', [])
set(handles.edit_modelFile, 'string', [])
set(handles.check_resultFile, 'value', 0.0)
if exist ([pwd, '/Project/output'], 'dir') == 7.0
    set(handles.edit_resultFile, 'enable', 'inactive', 'string',...
        [pwd, '\Project\output'], 'backgroundColor', [241/255, 241/255, 241/255])
else
    set(handles.edit_resultFile, 'enable', 'inactive', 'string',...
        [pwd, '\Project'], 'backgroundColor', [241/255, 241/255, 241/255])
end
set(handles.pButton_findResultFile, 'enable', 'off')
set(handles.text_partInstance, 'enable', 'on')
set(handles.edit_partInstance, 'string', [], 'enable', 'on')
set(handles.edit_resultsStepName, 'string', [], 'enable', 'on', 'backgroundColor', [177/256, 206/256, 237/256])
set(handles.check_isExplicit, 'value', 0.0, 'enable', 'on')
set(handles.rButton_createNewStep, 'value', 1.0)
set(handles.rButton_specifyExistingStep, 'value', 0.0)
set(handles.pMenu_elementPosition, 'value', 1.0)
set(handles.check_autoDeterminePosition, 'value', 0.0)
set(handles.check_writeScriptOnly, 'value', 0.0)
set(handles.check_keepScript, 'value', 0.0)
set(handles.check_upgrade, 'value', 0.0)
set(handles.edit_abqCmd, 'string', [])
set(handles.check_createODBSet, 'value', 0.0)
set(handles.edit_ODBSetName, 'string', 'QFT-Results', 'backgroundColor', [177/256, 206/256, 237/256], 'enable', 'inactive')
set(handles.check_copyToClipboard, 'value', 1.0)
% Reset field selection
set(handles.rButton_preselect, 'value', 1.0)
setappdata(0, 'variableSelectReset', 1.0)
panel_selection_SelectionChangeFcn(hObject, eventdata, handles)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles)
% Save the panel state
setappdata(0, 'panel_exportTool_edit_fieldData', get(handles.edit_fieldData, 'string'))
setappdata(0, 'panel_exportTool_edit_modelFile', get(handles.edit_modelFile, 'string'))
setappdata(0, 'panel_exportTool_check_resultFile', get(handles.check_resultFile, 'value'))
setappdata(0, 'panel_exportTool_edit_resultFile', get(handles.edit_resultFile, 'string'))

setappdata(0, 'panel_exportTool_edit_partInstance', get(handles.edit_partInstance, 'string'))
setappdata(0, 'panel_exportTool_check_isExplicit', get(handles.check_isExplicit, 'value'))
setappdata(0, 'panel_exportTool_rButton_createNewStep', get(handles.rButton_createNewStep, 'value'))
setappdata(0, 'panel_exportTool_rButton_specifyExistingStep', get(handles.rButton_specifyExistingStep, 'value'))
setappdata(0, 'panel_exportTool_edit_resultsStepName', get(handles.edit_resultsStepName, 'string'))
setappdata(0, 'panel_exportTool_pMenu_elementPosition', get(handles.pMenu_elementPosition, 'value'))
setappdata(0, 'panel_exportTool_check_autoDeterminePosition', get(handles.check_autoDeterminePosition, 'value'))

setappdata(0, 'panel_exportTool_check_keepScript', get(handles.check_keepScript, 'value'))
setappdata(0, 'panel_exportTool_check_writeScriptOnly', get(handles.check_writeScriptOnly, 'value'))
setappdata(0, 'panel_exportTool_check_createODBSet', get(handles.check_createODBSet, 'value'))
setappdata(0, 'panel_exportTool_check_upgrade', get(handles.check_upgrade, 'value'))
setappdata(0, 'panel_exportTool_edit_abqCmd', get(handles.edit_abqCmd, 'string'))
setappdata(0, 'panel_exportTool_edit_ODBSetName', get(handles.edit_ODBSetName, 'string'))

setappdata(0, 'panel_exportTool_rButton_selectFromList', get(handles.rButton_selectFromList, 'value'))
setappdata(0, 'panel_exportTool_rButton_preselect', get(handles.rButton_preselect, 'value'))
setappdata(0, 'panel_exportTool_rButton_selectAll', get(handles.rButton_selectAll, 'value'))

setappdata(0, 'panel_exportTool_check_LL', get(handles.check_LL, 'value'))
setappdata(0, 'panel_exportTool_check_L', get(handles.check_L, 'value'))
setappdata(0, 'panel_exportTool_check_D', get(handles.check_D, 'value'))
setappdata(0, 'panel_exportTool_check_DDL', get(handles.check_DDL, 'value'))
setappdata(0, 'panel_exportTool_check_FOS', get(handles.check_FOS, 'value'))
setappdata(0, 'panel_exportTool_check_SFA', get(handles.check_SFA, 'value'))
setappdata(0, 'panel_exportTool_check_FRFR', get(handles.check_FRFR, 'value'))
setappdata(0, 'panel_exportTool_check_FRFV', get(handles.check_FRFV, 'value'))
setappdata(0, 'panel_exportTool_check_FRFH', get(handles.check_FRFH, 'value'))
setappdata(0, 'panel_exportTool_check_FRFW', get(handles.check_FRFW, 'value'))
setappdata(0, 'panel_exportTool_check_SMAX', get(handles.check_SMAX, 'value'))
setappdata(0, 'panel_exportTool_check_SMXP', get(handles.check_SMXP, 'value'))
setappdata(0, 'panel_exportTool_check_SMXU', get(handles.check_SMXU, 'value'))
setappdata(0, 'panel_exportTool_check_TRF', get(handles.check_TRF, 'value'))
setappdata(0, 'panel_exportTool_check_WCM', get(handles.check_WCM, 'value'))
setappdata(0, 'panel_exportTool_check_WCA', get(handles.check_WCA, 'value'))
setappdata(0, 'panel_exportTool_check_WCDP', get(handles.check_WCDP, 'value'))
setappdata(0, 'panel_exportTool_check_WCATAN', get(handles.check_WCATAN, 'value'))

setappdata(0, 'panel_exportTool_check_copyToClipboard', get(handles.check_copyToClipboard, 'value'))

delete(hObject);

function blankGUI(handles)
set(handles.text_job, 'enable', 'off')
set(handles.edit_fieldData, 'enable', 'off')
set(handles.pButon_findFieldData, 'enable', 'off')
set(handles.pButton_fieldDataHelp, 'enable', 'off')
set(handles.text_modelFile, 'enable', 'off')
set(handles.edit_modelFile, 'enable', 'off')
set(handles.pButton_findModelFile, 'enable', 'off')
set(handles.pButton_modelFileHelp, 'enable', 'off')
set(handles.pButton_resultsFileHelp, 'enable', 'off')
set(handles.pButton_dataPositionHelp, 'enable', 'off')
set(handles.frame_modelInfo, 'enable', 'off')
set(handles.text_execution, 'enable', 'off')
set(handles.text_hint, 'enable', 'off')
set(handles.check_resultFile, 'enable', 'off')
set(handles.edit_resultFile, 'enable', 'off')
set(handles.pButton_findResultFile, 'enable', 'off')
set(handles.text_partInstance, 'enable', 'off')
set(handles.edit_partInstance, 'enable', 'off')
set(handles.text_resultsStepName, 'enable', 'off')
set(handles.edit_resultsStepName, 'enable', 'off')
set(handles.check_isExplicit, 'enable', 'off')
set(handles.rButton_createNewStep, 'enable', 'off')
set(handles.rButton_specifyExistingStep, 'enable', 'off')
set(handles.text_elementPosition, 'enable', 'off')
set(handles.pMenu_elementPosition, 'enable', 'off')
set(handles.check_autoDeterminePosition, 'enable', 'off')
set(handles.check_keepScript, 'enable', 'off')
set(handles.check_writeScriptOnly, 'enable', 'off')
set(handles.check_upgrade, 'enable', 'off')
set(handles.text_abqCmd, 'enable', 'off')
set(handles.edit_abqCmd, 'enable', 'off')
set(handles.check_createODBSet, 'enable', 'off')
set(handles.edit_ODBSetName, 'enable', 'off')
set(handles.check_LL, 'enable', 'off')
set(handles.check_L, 'enable', 'off')
set(handles.check_D, 'enable', 'off')
set(handles.check_DDL, 'enable', 'off')
set(handles.check_FOS, 'enable', 'off')
set(handles.check_SFA, 'enable', 'off')
set(handles.check_FRFR, 'enable', 'off')
set(handles.check_FRFV, 'enable', 'off')
set(handles.check_FRFH, 'enable', 'off')
set(handles.check_FRFW, 'enable', 'off')
set(handles.check_SMAX, 'enable', 'off')
set(handles.check_SMXP, 'enable', 'off')
set(handles.check_SMXU, 'enable', 'off')
set(handles.check_TRF, 'enable', 'off')
set(handles.check_WCM, 'enable', 'off')
set(handles.check_WCA, 'enable', 'off')
set(handles.check_WCDP, 'enable', 'off')
set(handles.check_WCATAN, 'enable', 'off')
set(handles.rButton_selectFromList, 'enable', 'off')
set(handles.rButton_preselect, 'enable', 'off')
set(handles.rButton_selectAll, 'enable', 'off')
set(handles.pButton_clearSelection, 'enable', 'off')
set(handles.pButton_reset, 'enable', 'off')
set(handles.check_copyToClipboard, 'enable', 'off')
set(handles.pButton_start, 'enable', 'off')
set(handles.pButton_cancel, 'enable', 'off')

function enableGUI(handles)
set(handles.text_job, 'enable', 'on')
set(handles.edit_fieldData, 'enable', 'on')
set(handles.pButon_findFieldData, 'enable', 'on')
set(handles.pButton_fieldDataHelp, 'enable', 'on')
set(handles.text_modelFile, 'enable', 'on')
set(handles.edit_modelFile, 'enable', 'on')
set(handles.pButton_findModelFile, 'enable', 'on')
set(handles.pButton_modelFileHelp, 'enable', 'on')
set(handles.pButton_resultsFileHelp, 'enable', 'on')
set(handles.pButton_dataPositionHelp, 'enable', 'on')
set(handles.frame_modelInfo, 'enable', 'inactive')
set(handles.text_execution, 'enable', 'on')
set(handles.text_hint, 'enable', 'on')
set(handles.check_resultFile, 'enable', 'on')
if get(handles.check_resultFile, 'value') == 1.0
    set(handles.edit_resultFile, 'enable', 'on')
    set(handles.pButton_findResultFile, 'enable', 'on')
else
    set(handles.edit_resultFile, 'enable', 'inactive')
end
set(handles.text_partInstance, 'enable', 'on')
set(handles.edit_partInstance, 'enable', 'on')
set(handles.text_resultsStepName, 'enable', 'on')
set(handles.edit_resultsStepName, 'enable', 'on')
set(handles.rButton_createNewStep, 'enable', 'on')
set(handles.rButton_specifyExistingStep, 'enable', 'on')
if get(handles.rButton_createNewStep, 'value') == 1.0
    set(handles.check_isExplicit, 'enable', 'on')
end
set(handles.text_elementPosition, 'enable', 'on')
set(handles.pMenu_elementPosition, 'enable', 'on')
set(handles.check_autoDeterminePosition, 'enable', 'on')
set(handles.check_writeScriptOnly, 'enable', 'on')
set(handles.check_keepScript, 'enable', 'on')
set(handles.check_upgrade, 'enable', 'on')
set(handles.text_abqCmd, 'enable', 'on')
set(handles.edit_abqCmd, 'enable', 'on')
set(handles.check_createODBSet, 'enable', 'on')
if get(handles.check_createODBSet, 'value') == 1.0
    set(handles.edit_ODBSetName, 'enable', 'on')
else
    set(handles.edit_ODBSetName, 'enable', 'inactive')
end
set(handles.check_LL, 'enable', 'on')
set(handles.check_L, 'enable', 'on')
set(handles.check_D, 'enable', 'on')
set(handles.check_DDL, 'enable', 'on')
set(handles.check_FOS, 'enable', 'on')
set(handles.check_SFA, 'enable', 'on')
set(handles.check_FRFR, 'enable', 'on')
set(handles.check_FRFV, 'enable', 'on')
set(handles.check_FRFH, 'enable', 'on')
set(handles.check_FRFW, 'enable', 'on')
set(handles.check_SMAX, 'enable', 'on')
set(handles.check_SMXP, 'enable', 'on')
set(handles.check_SMXU, 'enable', 'on')
set(handles.check_TRF, 'enable', 'on')
set(handles.check_WCM, 'enable', 'on')
set(handles.check_WCA, 'enable', 'on')
set(handles.check_WCDP, 'enable', 'on')
set(handles.check_WCATAN, 'enable', 'on')
set(handles.rButton_selectFromList, 'enable', 'on')
set(handles.rButton_preselect, 'enable', 'on')
set(handles.rButton_selectAll, 'enable', 'on')
set(handles.pButton_clearSelection, 'enable', 'on')
set(handles.pButton_reset, 'enable', 'on')
set(handles.check_copyToClipboard, 'enable', 'on')
set(handles.pButton_start, 'enable', 'on')
set(handles.pButton_cancel, 'enable', 'on')


% --- Executes on button press in frame_modelInfo.
function frame_modelInfo_Callback(~, ~, ~)
% hObject    handle to frame_modelInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in frame_scriptInfo.
function frame_scriptInfo_Callback(~, ~, ~)
% hObject    handle to frame_scriptInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in panel_selection.
function panel_selection_SelectionChangeFcn(~, eventdata, handles)
if getappdata(0, 'variableSelectReset') == 1.0
    tag = 'rButton_preselect';
    setappdata(0, 'variableSelectReset', 0.0)
else
    tag = get(eventdata.NewValue, 'Tag');
end

switch tag
    case 'rButton_selectFromList'
    case 'rButton_preselect'
        set(handles.check_L, 'value', 0.0)
        set(handles.check_LL, 'value', 1.0)
        set(handles.check_D, 'value', 0.0)
        set(handles.check_DDL, 'value', 0.0)
        set(handles.check_FOS, 'value', 0.0)
        set(handles.check_SFA, 'value', 0.0)
        set(handles.check_FRFR, 'value', 1.0)
        set(handles.check_FRFV, 'value', 1.0)
        set(handles.check_FRFH, 'value', 1.0)
        set(handles.check_FRFW, 'value', 1.0)
        set(handles.check_SMAX, 'value', 1.0)
        set(handles.check_SMXP, 'value', 0.0)
        set(handles.check_SMXU, 'value', 0.0)
        set(handles.check_TRF, 'value', 0.0)
        set(handles.check_WCM, 'value', 1.0)
        set(handles.check_WCA, 'value', 1.0)
        set(handles.check_WCDP, 'value', 0.0)
        set(handles.check_WCATAN, 'value', 0.0)
    case 'rButton_selectAll'        
        set(handles.check_L, 'value', 1.0)
        set(handles.check_LL, 'value', 1.0)
        set(handles.check_D, 'value', 1.0)
        set(handles.check_DDL, 'value', 1.0)
        set(handles.check_FOS, 'value', 1.0)
        set(handles.check_SFA, 'value', 1.0)
        set(handles.check_FRFR, 'value', 1.0)
        set(handles.check_FRFV, 'value', 1.0)
        set(handles.check_FRFH, 'value', 1.0)
        set(handles.check_FRFW, 'value', 1.0)
        set(handles.check_SMAX, 'value', 1.0)
        set(handles.check_SMXP, 'value', 1.0)
        set(handles.check_SMXU, 'value', 1.0)
        set(handles.check_TRF, 'value', 1.0)
        set(handles.check_WCM, 'value', 1.0)
        set(handles.check_WCA, 'value', 1.0)
        set(handles.check_WCDP, 'value', 1.0)
        set(handles.check_WCATAN, 'value', 1.0)
end


% --- Executes on button press in pButton_clearSelection.
function pButton_clearSelection_Callback(~, ~, handles)
set(handles.check_L, 'value', 0.0)
set(handles.check_LL, 'value', 0.0)
set(handles.check_D, 'value', 0.0)
set(handles.check_DDL, 'value', 0.0)
set(handles.check_FOS, 'value', 0.0)
set(handles.check_SFA, 'value', 0.0)
set(handles.check_FRFR, 'value', 0.0)
set(handles.check_FRFV, 'value', 0.0)
set(handles.check_FRFH, 'value', 0.0)
set(handles.check_FRFW, 'value', 0.0)
set(handles.check_SMAX, 'value', 0.0)
set(handles.check_SMXP, 'value', 0.0)
set(handles.check_SMXU, 'value', 0.0)
set(handles.check_TRF, 'value', 0.0)
set(handles.check_WCM, 'value', 0.0)
set(handles.check_WCA, 'value', 0.0)
set(handles.check_WCDP, 'value', 0.0)
set(handles.check_WCATAN, 'value', 0.0)

set(handles.rButton_selectFromList, 'value', 1.0)
set(handles.rButton_preselect, 'value', 0.0)
set(handles.rButton_selectAll, 'value', 0.0)


% --- Executes on button press in check_isExplicit.
function check_isExplicit_Callback(~, ~, ~)


% --- Executes on button press in check_createODBSet.
function check_createODBSet_Callback(hObject, ~, handles)
if get(hObject, 'value') == 1.0
    set(handles.edit_ODBSetName, 'enable', 'on', 'backgroundColor', 'white')
else
    set(handles.edit_ODBSetName, 'enable', 'inactive', 'backgroundColor', [177/256, 206/256, 237/256])
end


function edit_ODBSetName_Callback(~, ~, ~)
% hObject    handle to edit_ODBSetName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ODBSetName as text
%        str2double(get(hObject,'String')) returns contents of edit_ODBSetName as a double


% --- Executes during object creation, after setting all properties.
function edit_ODBSetName_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ODBSetName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel14.
function uipanel14_SelectionChangeFcn(~, eventdata, handles)
switch get(eventdata.NewValue, 'Tag')
    case 'rButton_createNewStep'
        set(handles.edit_resultsStepName, 'backgroundColor', [177/256, 206/256, 237/256])
        set(handles.check_isExplicit, 'enable', 'on')
    case 'rButton_specifyExistingStep'
        set(handles.edit_resultsStepName, 'backgroundColor', 'white')
        set(handles.check_isExplicit, 'enable', 'off')
end


% --- Executes on button press in check_upgrade.
function check_upgrade_Callback(~, ~, ~)
% hObject    handle to check_upgrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of check_upgrade



function edit_abqCmd_Callback(~, ~, ~)
% hObject    handle to edit_abqCmd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_abqCmd as text
%        str2double(get(hObject,'String')) returns contents of edit_abqCmd as a double


% --- Executes during object creation, after setting all properties.
function edit_abqCmd_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_abqCmd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

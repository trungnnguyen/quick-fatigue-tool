function varargout = MaterialManager(varargin)%#ok<*DEFNU>
%MATERIALMANAGER    QFT functions for Material Manager.
%   These functions are used to call and operate the Material Manager
%   application.
%   
%   MATERIALMANAGER is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also evaluateMaterial, kSolution, UserMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 13-Apr-2017 10:01:38 GMT
    
    %%
    
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MaterialManager_OpeningFcn, ...
                   'gui_OutputFcn',  @MaterialManager_OutputFcn, ...
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


% --- Executes just before MaterialManager is made visible.
function MaterialManager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MaterialManager (see VARARGIN)

if isappdata(0, 'importMaterial') == 0.0
    clc
else
    rmappdata(0, 'importMaterial')
end

% Load the help icon
[a,~]=imread('icoR_info.jpg');
[r,c,~]=size(a);
x=ceil(r/35);
y=ceil(c/35);
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pButton_help, 'CData', g);

approot = [getenv('USERPROFILE'), '\Documents\MATLAB\Apps\Material Manager'];

if exist(approot, 'dir')
    addpath(approot)
end

% Choose default command line output for MaterialManager
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Position the figure in the centre of the screen
movegui(hObject, 'center')

% UIWAIT makes MaterialManager wait for user response (see UIRESUME)
% uiwait(handles.MaterialManager);

%% Check for user materials in the DATA/MATERIAL/LOCAL directory
% Get listing of materials
userMaterials = dir('Data/material/local/*.mat');

% Check number of materials
[numberOfMaterials, ~] = size(userMaterials);
if numberOfMaterials < 1.0
    set(handles.pButton_edit, 'enable', 'off')
    set(handles.pButton_copy, 'enable', 'off')
    set(handles.pButton_rename, 'enable', 'off')
    set(handles.pButton_delete, 'enable', 'off')
    set(handles.pButton_query, 'enable', 'off')
    set(handles.pButton_eval, 'enable', 'off')
    
    set(handles.list_database, 'string', 'No user materials to display.')
else
    materialStrings = cell(1, numberOfMaterials);
    
    for i = 1:numberOfMaterials
        userMaterials(i).name(end-3:end) = [];
        materialStrings{i} = userMaterials(i).name;
    end
    
    set(handles.list_database, 'string', materialStrings)
end

%% Create string of system materials
% Load enums into workspace
if isappdata(0, 'adi_iron') == 0.0
    if exist('mat_enum.mat', 'file') == 2.0
        setappdata(0, 'errorMissingENums', 0.0)
        load('mat_enum.mat');
    else
        setappdata(0, 'errorMissingENums', 1.0)
        return
    end
end

systemMaterials = {mat_enum.sae_steel{:}, mat_enum.bs_steel{:},...
    mat_enum.astm_steel{:}, mat_enum.aluminium{:}, mat_enum.adi_iron{:},...
    mat_enum.di_iron{:}, mat_enum.cgi_iron{:}, mat_enum.gi_iron{:}}; %#ok<CCAT>

setappdata(gcf, 'systemMaterials', systemMaterials)

%% Force database refresh
setappdata(0, 'forceLocalDatabaseRefresh', 1.0)
panel_database_SelectionChangeFcn(hObject, eventdata, handles)

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
function varargout = MaterialManager_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in list_database.
function list_database_Callback(hObject, eventdata, handles)
if ischar(get(handles.list_database, 'string')) == 1.0
    return
end

try
    time = toc;
catch
    time = 1.0;
end

if (get(hObject, 'UserData') == get(hObject, 'Value'))
    if time <= 0.5
        if get(handles.rButton_user, 'value') == 1.0
            pButton_edit_Callback(hObject, eventdata, handles)
        else
            pButton_copy_Callback(hObject, eventdata, handles)
        end
    else
        set(hObject, 'UserData', get(hObject, 'Value'))
        tic
    end
else
    set(hObject, 'UserData', get(hObject, 'Value'))
    tic
end


% --- Executes during object creation, after setting all properties.
function list_database_CreateFcn(hObject, ~, ~)
% hObject    handle to list_database (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pButton_create.
function pButton_create_Callback(~, ~, ~)
close MaterialManager
UserMaterial


% --- Executes on button press in pButton_edit.
function pButton_edit_Callback(~, ~, handles)
setappdata(0, 'editMaterial', 1)
materials = get(handles.list_database, 'string');
setappdata(0, 'materialToEdit', materials(get(handles.list_database, 'value')))

close MaterialManager
UserMaterial


% --- Executes on button press in pButton_copy.
function pButton_copy_Callback(hObject, eventdata, handles)
materials = get(handles.list_database, 'string');
material = materials{get(handles.list_database, 'value')};
if get(handles.rButton_user, 'value') == 1.0
    copiedMaterial = [materials{get(handles.list_database, 'value')}, '_copy'];
    message = sprintf('Copy %s to:', material);
    copiedMaterial = char(inputdlg(message, 'Copy Material', 1.0, {copiedMaterial}));
else
    fetchedMaterial = materials{get(handles.list_database, 'value')};
    message = sprintf('Copy %s to local database:', material);
    copiedMaterial = char(inputdlg(message, 'Quick Fatigue Tool', 1.0, {fetchedMaterial}));
end

% First check that the material name is valid
if isempty(copiedMaterial) == 1.0
    return
elseif ~isempty(regexp(copiedMaterial, '[/\\*:?"<>|]', 'once'))
    message1 = sprintf('The material name cannot contain any of the following characters:\n\n');
    message2 = sprintf('/ \\ * : ? " < > | ');
    errordlg([message1, message2], 'Quick Fatigue Tool')
    return
else
    % Check if the material already exists
    userMaterials = dir('Data/material/local/*.mat');
    
    for i = 1:length(userMaterials)
        if strcmp([copiedMaterial, '.mat'], userMaterials(i).name)
            message = sprintf('%s already exists in the local database and cannot be overwritten.', copiedMaterial);
            if get(handles.rButton_user, 'value') == 1.0
                errordlg(message, 'Quick Fatigue Tool')
            else
                errordlg(message, 'Quick Fatigue Tool')
            end
            return
        end
    end
end

if get(handles.rButton_user, 'value') == 1.0
    % Save the new material
    oldPath = ['Data\material\local\', material, '.mat'];
    newPath = ['Data\material\local\', copiedMaterial, '.mat'];
    
    try
        copyfile(oldPath, newPath)
    catch
        if exist(material, 'file') == 0.0
            message = sprintf('Could not copy %s because it no longer exists in the local database.', material);
        else
            message = sprintf('Could not copy %s.\n\nMake sure the material name does not contain any illegal characters.', copiedMaterial);
        end
        errordlg(message, 'Quick Fatigue Tool')
        return
    end
    
    % Get listing of materials from /LOCAL directory
    userMaterials = dir('Data/material/local/*.mat');
    [numberOfMaterials, ~] = size(userMaterials);
    
    materialStrings = cell(1, numberOfMaterials);
    
    for i = 1:numberOfMaterials
        userMaterials(i).name(end-3:end) = [];
        materialStrings{i} = userMaterials(i).name;
    end
    
    % Display the new material list
    set(handles.list_database, 'string', materialStrings)
    
    % Set the user highlighted value to the newly copied material
    set(handles.list_database, 'value', find(strcmp(materialStrings, copiedMaterial)))
else
    % Load the system database into the workspace for reading
    value = get(handles.list_database, 'value');
    
    properties = getMaterialFields(value);
    
    % If there was an error while reading the system databse, RETURN
    if isstruct(properties) == 0.0
        if properties == 0.0
            return
        end
    end
    
    material_properties = saveMaterial(properties); %#ok<NASGU>
    
    % Save the copy in the /USER_MATERIAL directory
    try
        save(['Data\material\local\', copiedMaterial, '.mat'], 'material_properties')
    catch
        message = sprintf('Cannot fetch %s because the local database is not currently on the MATLAB path.', copiedMaterial);
        errordlg(message, 'Quick Fatigue Tool')
        return
    end
    
    % Switch back to the local database view
    set(handles.rButton_user, 'value', 1.0)
    setappdata(0, 'forceLocalDatabaseRefresh', 1.0)
    panel_database_SelectionChangeFcn(hObject, eventdata, handles)
end


% --- Executes on button press in pButton_rename.
function pButton_rename_Callback(~, ~, handles)
% Get the current list of materials
materials = get(handles.list_database, 'string');

% Find the material being renamed
material = char(materials(get(handles.list_database, 'value')));
message = sprintf('Rename %s to:', material);

% Ask user for new name
newName = char(inputdlg(message, 'Rename Material', 1.0, {material}));
if isempty(newName) == 1.0
    return
elseif ~isempty(regexp(newName, '[/\\*:?"<>|]', 'once'))
    message1 = sprintf('The material name cannot contain any of the following characters:\n\n');
    message2 = sprintf('/ \\ * : ? " < > | ');
    errordlg([message1, message2], 'Quick Fatigue Tool')
    return
elseif strcmp(newName, material) == 1.0
    % Material already exists
    if exist([newName, '.mat'], 'file') == 0.0
        message = sprintf('Could not rename %s because it no longer exists in the local database.', material);
    else
        message = sprintf('%s already exists in the local database and cannot be overwritten.', newName);
    end
    errordlg(message, 'Quick Fatigue Tool')
else
    % Create paths to old and new material names
    fullpathOld = ['Data\material\local\', material, '.mat'];
    fullpathNew = ['Data\material\local\', newName, '.mat'];
    
    % Rename the material
    try
        movefile(fullpathOld, fullpathNew)
    catch
        if exist(fullpathOld, 'file') == 0.0
            message = sprintf('Could not rename %s because it no longer exists in the local database.', newName);
        else
            message = sprintf('Material name %s is invalid.', newName);
        end
        errordlg(message, 'Quick Fatigue Tool')
        return
    end
    
    % Change the string value in the list box
    materials{get(handles.list_database, 'value')} = newName;
    set(handles.list_database, 'string', materials)
end


% --- Executes on button press in pButton_delete.
function pButton_delete_Callback(~, ~, handles)
materials = get(handles.list_database, 'string');
materialToDelete = materials{get(handles.list_database, 'value')};
question = sprintf('OK to delete %s?', materialToDelete);
response = questdlg(question, 'Quick Fatigue Tool');

if strcmpi(response, 'yes')
    fullpath = ['Data\material\local\', materialToDelete, '.mat'];
    if exist(fullpath, 'file') ~= 0.0
        delete(fullpath);
    end
    
    list = get(handles.list_database', 'string');
    list(get(handles.list_database, 'value')) = [];
    
    if isempty(list) == 1.0
        set(handles.list_database, 'string', 'No user materials to display')
        
        set(handles.pButton_edit, 'enable', 'off')
        set(handles.pButton_copy, 'enable', 'off')
        set(handles.pButton_rename, 'enable', 'off')
        set(handles.pButton_delete, 'enable', 'off')
        set(handles.pButton_query, 'enable', 'off')
        set(handles.pButton_eval, 'enable', 'off')
    else
        set(handles.list_database, 'string', list)
        set(handles.list_database, 'value', 1.0)
    end
else
    return
end


% --- Executes on button press in pButton_close.
function pButton_close_Callback(~, ~, ~)
close MaterialManager


% --- Executes when selected object is changed in panel_database.
function panel_database_SelectionChangeFcn(~, eventdata, handles)
try
    tag = get(eventdata.NewValue, 'Tag');
catch
    tag = getappdata(0, 'startTag');
end

if getappdata(0, 'forceLocalDatabaseRefresh') == 1.0
    setappdata(0, 'forceLocalDatabaseRefresh', 0.0)
    
    set(handles.list_database, 'value', 1.0)
    %% Enable/Disable buttons
    set(handles.pButton_create, 'enable', 'on')
    set(handles.pButton_import, 'enable', 'on')
    set(handles.pButton_edit, 'enable', 'on')
    set(handles.pButton_rename, 'enable', 'on')
    set(handles.pButton_delete, 'enable', 'on')
    set(handles.pButton_copy, 'string', 'Copy...')
    
    %% Check for user materials in the DATA/MATERIAL/LOCAL directory
    % Get listing of materials
    userMaterials = dir('Data/material/local/*.mat');
    % Check number of materials
    [numberOfMaterials, ~] = size(userMaterials);
    if numberOfMaterials < 1.0
        set(handles.pButton_edit, 'enable', 'off')
        set(handles.pButton_copy, 'enable', 'off')
        set(handles.pButton_rename, 'enable', 'off')
        set(handles.pButton_delete, 'enable', 'off')
        set(handles.pButton_query, 'enable', 'off')
        set(handles.pButton_eval, 'enable', 'off')
        
        set(handles.list_database, 'string', 'No user materials to display')
    else
        set(handles.pButton_edit, 'enable', 'on')
        set(handles.pButton_copy, 'enable', 'on')
        set(handles.pButton_rename, 'enable', 'on')
        set(handles.pButton_delete, 'enable', 'on')
        set(handles.pButton_query, 'enable', 'on')
        set(handles.pButton_eval, 'enable', 'on')
        
        materialStrings = cell(1.0, numberOfMaterials);
        
        for i = 1:numberOfMaterials
            userMaterials(i).name(end - 3.0:end) = [];
            materialStrings{i} = userMaterials(i).name;
        end
        
        set(handles.list_database, 'string', materialStrings)
    end
else
    switch tag
        case 'rButton_user'
            set(handles.list_database, 'value', 1.0)
            %% Enable/Disable buttons
            set(handles.pButton_create, 'enable', 'on')
            set(handles.pButton_import, 'enable', 'on')
            set(handles.pButton_edit, 'enable', 'on')
            set(handles.pButton_rename, 'enable', 'on')
            set(handles.pButton_delete, 'enable', 'on')
            set(handles.pButton_copy, 'string', 'Copy...')
            
            %% Check for user materials in the DATA/MATERIAL/LOCAL directory
            % Get listing of materials
            userMaterials = dir('Data/material/local/*.mat');
            % Check number of materials
            [numberOfMaterials, ~] = size(userMaterials);
            if numberOfMaterials < 1
                set(handles.pButton_edit, 'enable', 'off')
                set(handles.pButton_copy, 'enable', 'off')
                set(handles.pButton_rename, 'enable', 'off')
                set(handles.pButton_delete, 'enable', 'off')
                set(handles.pButton_query, 'enable', 'off')
                set(handles.pButton_eval, 'enable', 'off')
                
                set(handles.list_database, 'string', 'No user materials to display')
            else
                set(handles.pButton_edit, 'enable', 'on')
                set(handles.pButton_copy, 'enable', 'on')
                set(handles.pButton_rename, 'enable', 'on')
                set(handles.pButton_delete, 'enable', 'on')
                set(handles.pButton_query, 'enable', 'on')
                set(handles.pButton_eval, 'enable', 'on')
                
                materialStrings = cell(1, numberOfMaterials);
                
                for i = 1:numberOfMaterials
                    userMaterials(i).name(end-3:end) = [];
                    materialStrings{i} = userMaterials(i).name;
                end
                
                set(handles.list_database, 'string', materialStrings)
            end
        case 'rButton_qft'
            %% Populate list with system database
            if getappdata(0, 'errorMissingENums') == 1.0
                errordlg('Missing file ''mat_enums.mat''. Check that the file exists in Data/material/system.', 'Quick Fatigue Tool')
                set(handles.rButton_user, 'value', 1.0)
                return
            else
                set(handles.list_database, 'value', 1.0)
                %% Enable/Disable buttons
                set(handles.pButton_copy, 'enable', 'on')
                set(handles.pButton_create, 'enable', 'off')
                set(handles.pButton_import, 'enable', 'off')
                set(handles.pButton_edit, 'enable', 'off')
                set(handles.pButton_rename, 'enable', 'off')
                set(handles.pButton_query, 'enable', 'on')
                set(handles.pButton_delete, 'enable', 'off')
                set(handles.pButton_copy, 'string', 'Fetch...')
                set(handles.pButton_eval, 'enable', 'off')
                
                set(handles.list_database, 'string', getappdata(gcf, 'systemMaterials'))
            end
    end
end


function material_properties = saveMaterial(properties)
material_properties = struct(...
'default_algorithm', properties.default_algorithm,...
'default_msc', properties.default_msc,...
'class', properties.class,...
'behavior', properties.behavior,...
'reg_model', 1.0,...
'cael', properties.cael,...
'cael_active', 1.0,...
'e', properties.e,...
'e_active', 1.0,...
'uts', properties.uts,...
'uts_active', 1.0,...
'proof', properties.proof,...
'proof_active', 1.0,...
'poisson', properties.poisson,...
'poisson_active', 1.0,...
's_values', properties.s_values,...
'n_values', properties.n_values,...
'r_values', properties.r_values,...
'sf', properties.sf,...
'sf_active', 1.0,...
'b', properties.b,...
'b_active', 1.0,...
'ef', properties.ef,...
'ef_active', 1.0,...
'c', properties.c,...
'c_active', 1.0,...
'kp', properties.kp,...
'kp_active', 1.0,...
'np', properties.np,...
'np_active', 1.0,...
'nssc', properties.nssc,...
'nssc_active', 1.0,...
'comment', properties.comment);

if isempty(properties.cael)
    material_properties.cael_active = 0.0;
end
if isempty(properties.e)
    material_properties.e_active = 0.0;
end
if isempty(properties.uts)
    material_properties.uts_active = 0.0;
end
if isempty(properties.proof)
    material_properties.proof_active = 0.0;
end
if isempty(properties.poisson)
    material_properties.poisson_active = 0.0;
end
if isempty(properties.sf)
    material_properties.sf_active = 0.0;
end
if isempty(properties.b)
    material_properties.b_active = 0.0;
end
if isempty(properties.ef)
    material_properties.ef_active = 0.0;
end
if isempty(properties.c)
    material_properties.c_active = 0.0;
end
if isempty(properties.kp)
    material_properties.kp_active = 0.0;
end
if isempty(properties.np)
    material_properties.np_active = 0.0;
end
if isempty(properties.nssc)
    material_properties.nssc_active = 0.0;
end
if isempty(properties.comment)
    material_properties.comment = '';
end

if properties.default_algorithm < 4
    material_properties.default_algorithm = properties.default_algorithm + 1;
elseif properties.default_algorithm < 10
    material_properties.default_algorithm = properties.default_algorithm + 2;
else
    material_properties.default_algorithm = properties.default_algorithm + 3;
end


% --- Executes on button press in pButton_query.
function pButton_query_Callback(~, ~, handles)
value = get(handles.list_database, 'value');

materials = get(handles.list_database, 'string');
material = char(materials{value});

if get(handles.rButton_qft, 'value') == 1.0
    properties = getMaterialFields(value);
    
    % Display the material's comment field to the user
    if isempty(properties.comment)
        msgbox('No material information available.', 'Quick Fatigue Tool')
    else
        message = sprintf('Query %s', char(material));
        msgbox(properties.comment, message)
    end
else
    % Get the material properties
    fullpath = ['Data\material\local\', material, '.mat'];
    if exist(fullpath, 'file') == 0.0
        msg = sprintf('Could not query ''%s.mat'' because the file no longer exists in the local database.', material);
        errordlg(msg, 'Quick Fatigue Tool')
        return
    else
        load(fullpath)
    end
    
    if exist('material_properties', 'var') == 0
        msg = sprintf('Error whilst reading ''%s.mat''. Properties are inaccessible.', material);
        errordlg(msg, 'Quick Fatigue Tool')
    elseif isempty(material_properties.comment)
        msg = sprintf('No information available for %s.', material);
        msgbox(msg, 'Quick Fatigue Tool')
    else
        message = sprintf('Query %s', material);
        msgbox(material_properties.comment, message)
    end
end

% --- Executes on button press in pButton_eval.
function pButton_eval_Callback(~, ~, handles)
% Flag to prevent messages from being written
setappdata(0, 'evaluateMaterialMessenger', 1.0)

% Get list of materials
materials = get(handles.list_database, 'string');

% Get the currently selected material
material = [materials{get(handles.list_database, 'value')}, '.mat'];

% Read material properties
error = preProcess.getMaterial(material, 0.0, 1.0);

% Remove flag
rmappdata(0, 'evaluateMaterialMessenger')

% Remove '.mat' extension
material(end-3:end) = [];

% Create file name
fileName = sprintf('Project/output/material_reports/%s_report.dat', material);

% Write material evaluation results to file
evaluateMaterial(fileName, material, error)

if (error > 0.0)
    return
end

% User message
message = sprintf('A material report has been written to %s.', fileName);

if (ispc == 1.0) && (ismac == 0.0)
    userResponse = questdlg(message, 'Quick Fatigue Tool', 'Open in MATLAB...',...
        'Open in Windows...', 'Dismiss', 'Open in MATLAB...');
elseif (ispc == 0.0) && (ismac == 1.0)
    userResponse = questdlg(message, 'Quick Fatigue Tool', 'Open in MATLAB...',...
        'Dismiss', 'Open in MATLAB...');
else
    userResponse = -1.0;
end

if strcmpi(userResponse, 'Open in MATLAB...')
    addpath('Project/output/material_reports')
    open(fileName)
elseif strcmpi(userResponse, 'Open in Windows...')
    winopen(fileName)
end



% --- Executes on button press in pButton_import.
function pButton_import_Callback(~, ~, ~)
close MaterialManager

% Define the start path
if isappdata(0, 'panel_materialManager_import_path') == 1.0
    startPath_import = getappdata(0, 'panel_materialManager_import_path');
else
    startPath_import = pwd;
end

[filename, pathname] = uigetfile({'*.*', 'All types'; '*.mat', 'MAT-files'; '*.txt', 'Normal text file'}, 'Select A Material To Import', startPath_import);
fullpath = [pathname filename];

if (isequal(filename, 0.0)) || (isequal(pathname, 0.0))
    % User cancelled operation
    MaterialManager
    return
else
    [~, materialName, ext] = fileparts(fullpath);
    
    % Save the file path
    setappdata(0, 'panel_materialManager_import_path', pathname)
end

% Flag to determine if the file is .mat or a text file
if strcmpi(ext, '.mat') == 1.0
    isMat = 1.0;
else
    isMat = 0.0;
end

if isMat == 1.0
    % Source and destination paths cannot be the same
    if strcmpi(fullpath, [pwd, '\Data\material\local\', materialName, ext]) == 1.0
        message = sprintf('Cannot copy ''%s'' to itself.', materialName);
        errordlg(message, 'Quick Fatigue Tool')
        uiwait
        MaterialManager
        return
    end
    
    % Perform file checks on the .mat file
    if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
        % User is attempting to overwrite an existing material
        response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Cancel', 'Overwrite');
        
        if (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
            MaterialManager
            return
        elseif strcmpi(response, 'Keep file') == 1.0
            % Change the name of the new results output database
            oldMaterial = ['Data/material/local/', materialName, '.mat'];
            while exist(oldMaterial, 'file') == 2.0
                oldMaterial = [oldMaterial(1.0:end - 4.0) , '-old', '.mat'];
            end
            
            % Rename the original material
            movefile(['Data/material/local/', materialName, '.mat'], oldMaterial)
        end
    end
    
    % Check that the file can be opened
    try
        open(fullpath);
    catch
        message = sprintf('Unable to open ''%s''.', filename);
        errordlg(message, 'Quick Fatigue Tool')
        uiwait
        MaterialManager
        return
    end
    
    % Copy the selected file into the user material database
    [success, ~, ~] = copyfile(fullpath, ['Data/material/local/', filename]);
    
    if success == 0.0
        message = sprintf('Unable to copy ''%s'' from ''%s'' to the local database.', filename, pathname);
        errordlg(message, 'Quick Fatigue Tool')
        uiwait
        MaterialManager
        return
    end
else
    %{
        The material is being imported from a text file. Read the text file
        through the text file processor and create a .mat file from the
        contents
    %}
    setappdata(0, 'materialManagerImport', 1.0)
    [error, material_properties, materialName, ~, ~] = importMaterial.processFile(fullpath, -1.0); %#ok<ASGLU>
    
    % Check for errors
    if error > 0.0
        [~, fileName, ext] = fileparts(fullpath);
        material = [fileName, ext];
        
        if error == 1.0
            msg = sprintf('The material file ''%s'' could not be opened.', material);
        else
            msg = sprintf('The material file ''%s'' contains no valid material definitions.', material);
        end
        
        errordlg(msg, 'Quick Fatigue Tool')
        uiwait
    else
        if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
            % User is attempting to overwrite an existing material
            response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Cancel', 'Overwrite');
            
            if (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
                MaterialManager
                return
            elseif strcmpi(response, 'Keep file') == 1.0
                % Change the name of the new results output database
                oldMaterial = ['Data/material/local/', materialName];
                while exist([oldMaterial, '.mat'], 'file') == 2.0
                    oldMaterial = [oldMaterial , '-old']; %#ok<AGROW>
                end
                
                % Rename the original material
                movefile(['Data/material/local/', materialName, '.mat'], [oldMaterial, '.mat'])
            end
        end
        
        % Save the material
        try
            save(['Data/material/local/', materialName], 'material_properties')
        catch
            errordlg(sprintf('Unable to save material ''%s''. Make sure the material save location has read/write access.', materialName), 'Quick Fatigue Tool')
            return
        end
    end
    
    % Flag to prevent command window from being cleared
    setappdata(0, 'importMaterial', 1.0)
end

MaterialManager


function properties = getMaterialFields(value)
% Check that the system database exists
if exist('mat.mat', 'file') == 2.0
    load('mat.mat')
else
    errordlg('Missing file ''mat.mat''. Check that the file exists in Data/material/system.', 'Quick Fatigue Tool')
    properties = 0.0;
    return
end

if value < 32.0 % SAE steel
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.sae);
    
    % Get the material properties
    materialF = fields(value);
    properties = getfield(mat.sae, char(materialF)); %#ok<*GFLD>
elseif value < 60.0 % BS steel
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.bs);
    
    % Get the material properties
    materialF = fields(value - 31);
    properties = getfield(mat.bs, char(materialF));
elseif value < 67.0 % ASTM steel
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.astm);
    
    % Get the material properties
    materialF = fields(value - 59);
    properties = getfield(mat.astm, char(materialF));
elseif value < 73.0 % Al
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.al);
    
    % Get the material properties
    materialF = fields(value - 66);
    properties = getfield(mat.al, char(materialF));
elseif value < 81.0 % ADI
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.adi);
    
    % Get the material properties
    materialF = fields(value - 72);
    properties = getfield(mat.adi, char(materialF));
elseif value < 100.0 % DI
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.di);
    
    % Get the material properties
    materialF = fields(value - 80);
    properties = getfield(mat.di, char(materialF));
elseif value < 103.0 % CGI
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.cgi);
    
    % Get the material properties
    materialF = fields(value - 99);
    properties = getfield(mat.cgi, char(materialF));
else % GI
    % Get the list of materials belonging to this family of metals
    fields = fieldnames(mat.gi);
    
    % Get the material properties
    materialF = fields(value - 102);
    properties = getfield(mat.gi, char(materialF));
end

% --- Executes on button press in pButton_snHelp.
function pButton_help_Callback(~, ~, ~)
ln1 = sprintf('Create and manage materials for fatigue analysis.\n\n');
ln2 = sprintf('Local Database:\n');
ln3 = sprintf('Materials used for analysis. Materials in the local database\n');
ln4 = sprintf('are stored in Data/material/local\n\n');
ln5 = sprintf('System Database:\n');
ln6 = sprintf('Write-protected database containing QFT material library.\n');
ln7 = sprintf('To use these materials, select the material then select "Fetch"');
msgbox([ln1, ln2, ln3, ln4, ln5, ln6, ln7], 'Material Databases')


% --- Executes when user attempts to close MaterialManager.
function MaterialManager_CloseRequestFcn(hObject, ~, ~)
% hObject    handle to MaterialManager (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

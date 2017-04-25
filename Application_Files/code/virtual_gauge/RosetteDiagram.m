function varargout = RosetteDiagram(varargin)
%ROSETTEDIAGRAM    QFT functions for Virtual Strain Gauge.
%   These functions are used to display a Rosette strain gauge as a MATLA
%   figure.
%   
%   ROSETTEDIAGRAM is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also virtualGaugeUtils, virtualGauge.
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
                   'gui_OpeningFcn', @RosetteDiagram_OpeningFcn, ...
                   'gui_OutputFcn',  @RosetteDiagram_OutputFcn, ...
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


% --- Executes just before RosetteDiagram is made visible.
function RosetteDiagram_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RosetteDiagram (see VARARGIN)
movegui(hObject, 'center')

% Choose default command line output for RosetteDiagram
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RosetteDiagram wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Read in the gauge image
set(handles.gauge_axes, 'visible', 'on')

if getappdata(0, 'gaugeDiagram') == 1.0
    imageArray = imread('gauge_45.png');
elseif getappdata(0, 'gaugeDiagram') == 2.0
    imageArray = imread('gauge_60.png');
else
    imageArray = imread('gauge_arbitrary.png');
end
% Switch active axes to the one you made for the image.
axes(handles.gauge_axes);
imshow(imageArray);


% --- Outputs from this function are returned to the command line.
function varargout = RosetteDiagram_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pButton_dismiss.
function pButton_dismiss_Callback(~, ~, ~) %#ok<*DEFNU>
close RosetteDiagram

function SFA = getSFA(WCA, WCDP, N)
%GETSFA    QFT function to calculate endurance safety factor.
%   This function calculates the endurance safety factor (SFA).
%   
%   GETSFA is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Get the number of groups
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Initialize SFA
SFA = linspace(-1.0, -1.0, N);

% Set the starting ID
startID = 1.0;

% Establish whether to use the worst amplitude or parameter
if getappdata(0, 'algorithm') == 6.0
    parameter = WCDP;
else
    parameter = WCA;
end

for groups = 1:G
    %{
        If the analysis is a PEEK analysis, override the value of GROUP to
        the group containing the PEEK item
    %}
    if getappdata(0, 'peekAnalysis') == 1.0
        groups = getappdata(0, 'peekGroup'); %#ok<FXSET>
    end
    
    % Assign group parameters to the current set of analysis IDs
    [N, ~] = group.switchProperties(groups, groupIDBuffer(groups));
    
    fatigueLimit = getappdata(0, 'fatigueLimit');
    
    % Get the WCA variable for the current group
    WCA_GROUP = parameter(startID:(startID + N) - 1.0);
    
    % SFA (Fatigue limit / stress amplitude)
    SFA(startID:(startID + N) - 1.0) = fatigueLimit./WCA_GROUP;
    
    % Update the start ID
    startID = startID + N;
end
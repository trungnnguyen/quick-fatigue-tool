function [] = normStress(SMAX_ABS, mainID, subID)
%NORMSTRESS    QFT function to calculate normalized stress components.
%    This function contains code to calculate the normalized stress output
%    variables SMXU and SMXP which are written to the field output file.
%
%    NORMSTRESS is used internally by Quick Fatigue Tool. The user is not
%    required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      10.2 Output variable types
%    
%    Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%    Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Get the number of groups
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Initialize SMXP and SMXU
SMXP = linspace(-1.0, -1.0, length(SMAX_ABS));
SMXU = linspace(-1.0, -1.0, length(SMAX_ABS));

% Set the starting ID
startID = 1.0;

if getappdata(0, 'utsWarn') == 0.0
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
        
        uts = getappdata(0, 'uts');
        
        % Get the SMAX variable for the current group
        SMAX_ABS_GROUP = SMAX_ABS(startID:(startID + N) - 1.0);
        
        % SMXU (Largest stress in loading / UTS)
        SMXU(startID:(startID + N) - 1.0) = SMAX_ABS_GROUP/uts;
        
        % Update the start ID
        startID = startID + N;
    end
end

% Set the starting ID
startID = 1.0;

if getappdata(0, 'twopsWarn') == 0.0
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
        
        twops = getappdata(0, 'twops');
        
        % Get the SMAX variable for the current group
        SMAX_ABS_GROUP = SMAX_ABS(startID:(startID + N) - 1.0);
        
        % SMXP (Largest stress in loading / 0.2% yield stress)
        SMXP(startID:(startID + N) - 1.0) = SMAX_ABS_GROUP/twops;
        
        % Update the start ID
        startID = startID + N;
    end
end

%% Get the worst value of SMXP
setappdata(0, 'SMXP', SMXP)

if abs(min(SMXP)) > abs(max(SMXP))
    MAX_SMXP = min(SMXP);
    SMXP_item = find(SMXP == min(SMXP));
else
    MAX_SMXP = max(SMXP);
    SMXP_item = find(SMXP == max(SMXP));
end

setappdata(0, 'SMXP_ABS', MAX_SMXP)

SMXP_item = SMXP_item(1.0);

setappdata(0, 'SMXP_mainID', mainID(SMXP_item))
setappdata(0, 'SMXP_subID', subID(SMXP_item))

%% Get the worst value of SMXU
setappdata(0, 'SMXU', SMXU)

if abs(min(SMXU)) > abs(max(SMXU))
    MAX_SMXU = min(SMXU);
    SMXU_item = find(SMXU == min(SMXU));
else
    MAX_SMXU = max(SMXU);
    SMXU_item = find(SMXU == max(SMXU));
end

setappdata(0, 'SMXU_ABS', MAX_SMXU)

SMXU_item = SMXU_item(1.0);

setappdata(0, 'SMXU_mainID', mainID(SMXU_item))
setappdata(0, 'SMXU_subID', subID(SMXU_item))
end
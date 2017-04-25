classdef qftWorkspace < handle
%QFTWORKSPACE    QFT class to save analysis variables to workspace.
%   This class contains methods for saving analysis variables and
%   application data to a .mat file.
%   
%   QFTWORKSPACE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 19-Apr-2017 14:29:55 GMT
    
    %%
    
    methods(Static = true)
        %% Initialize the save points
        function [debugItems, overlay] = initialize(N, debugItems, jobName, overlay)
            
            if getappdata(0, 'workspaceToFile') > 0.0
                % Get the interval data
                intervalData = getappdata(0, 'workspaceToFileInterval');
                
                if iscell(intervalData) == 0.0
                    interval = 1.0;
                    overlay = 1.0;
                elseif length(intervalData) ~= 2.0
                    interval = 1.0;
                    overlay = 1.0;
                else
                    interval = intervalData{1.0};
                    
                    switch lower(intervalData{2.0})
                        case 'overlay'
                            overlay = 1.0;
                        case 'retain'
                            overlay = 0.0;
                        otherwise
                            overlay = 1.0;
                    end
                end
            else
                return
            end
            
            if isempty(interval) == 1.0
                return
            elseif exist([pwd, sprintf('\\Project\\output\\%s\\Data Files', jobName)], 'dir') == 0.0
                % Check that the DATA FILES directory exists
                mkdir([pwd, sprintf('\\Project\\output\\%s\\Data Files', jobName)])
            end
            
            % Get the interval type
            switch getappdata(0, 'workspaceToFile')
                case 1.0 % Every n analysis items
                    
                    % Get the first debug item
                    debugItems = interval(1.0);
                    
                    % Get subsequent debug items
                    if interval > N
                        debugItems = N;
                    else
                        for i = 1:N
                            debugItems = [debugItems, debugItems(end) + interval]; %#ok<AGROW>
                            
                            if debugItems(end) > N
                                debugItems(end) = [];
                                break
                            end
                        end
                    end
                    
                    % Get last debug item (if applicable)
                    if debugItems(end) ~= N
                        debugItems = [debugItems, N];
                    end
                case 2.0 % n evenly spaced analysis items
                    
                    % Get the first debug item
                    debugItems = ceil(N/interval(1.0));
                    
                    if debugItems == 0.0
                        debugItems = 1.0;
                    end
                    
                    notFinished = 1.0;
                    while notFinished == 1.0
                        % Find all additional debug items
                        debugItems = [debugItems, (debugItems(end) + debugItems(1.0))]; %#ok<AGROW>
                        
                        %{
                            If the current debug item exceeds the total
                            number of items, BREAK
                        %}
                        if debugItems(end) > N
                            debugItems(end) = [];
                            notFinished = 0.0;
                        end
                    end
                    
                    % Get last debug item (if applicable)
                    if debugItems(end) ~= N
                        debugItems = [debugItems, N];
                    end
                case 3.0 % From analysis item IDs
                    
                    % Get the debug items
                    debugItems = interval;
                    
                    % Remove invalid debug items
                    debugItems(debugItems > N) = [];
                otherwise
                    return
            end
        end
    end
end
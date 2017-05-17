function [] = knockdown(nSets)
%KNOCKDOWN    QFT function to apply knock-down factors to user stress-life
%data.
%   This function apples knock-down factors from a '.kd' file to
%   user-defined stress-life data.
%   
%   KNOCKDOWN is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      4.7 S-N knock-down factors
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Get the number of groups for the analysis
G = getappdata(0, 'numberOfGroups');

% Flag indicating that the knock-down calculation failed
setappdata(0, 'kd_error', zeros(1.0, G))

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Get knock-down data
snKnockDown = getappdata(0, 'snKnockDown');
L = length(snKnockDown);

%{
        If there is no S-N knock-down defined for the analysis, RETURN
%}
emptyKd = zeros(1.0, L);
for i = 1:L
    if isempty(snKnockDown{i}) == 1.0
        emptyKd(i) = 1.0;
    end
end
if all(emptyKd) == 1.0
    return
end

% Apply knock-down factors to each group if applicable
for groups = 1:G
    % Get the S-N knock-down file for the current group
    if G > 1.0
        % Assign material properties for the current group
        [~, ~] = group.switchProperties(groups, groupIDBuffer(groups));
        
        % Store the current material
        setappdata(0, 'message_material', groupIDBuffer(groups).material)
    else
        % Store the current material
        setappdata(0, 'message_material', getappdata(0, 'material'))
    end
    
    % Get original S-N data
    sValues_original = getappdata(0, 's_values');
    nValues_original = getappdata(0, 'n_values');
    
    snKnockDown_i = snKnockDown(groups);
    
    %{
        If there is no S-N knock-down defined for the current group,
        CONTINUE to the next group
    %}
    if isempty(cell2mat(snKnockDown_i)) == 1.0
        continue
    end
    
    % Store the current group number
    setappdata(0, 'message_groupNumber', groups)
    
    % Store the current S-N knock-down file
    setappdata(0, 'message_knockDownFile', char(snKnockDown_i))
    
    %% Open the knock-down file
    try
        % Open the .kt/.ktx file
        kdData = dlmread(char(snKnockDown_i));
    catch unhandledException
        setappdata(0, 'warning_147_exceptionMessage', unhandledException.message)
        messenger.writeMessage(147.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        
        continue
    end
    
    % Check dimensionality of knock-down data
    [row, col] = size(kdData);
    
    % There must be exactly 2 columns in the .kd file
    if col ~= 2.0
        setappdata(0, 'kdFile_numberOfColumns', col)
        messenger.writeMessage(148.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        continue
    end
    
    % There must not be any negative values in the .kd file
    if any(kdData) < 0.0
        messenger.writeMessage(149.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        continue
    end
    
    % There must be at least two rows in the .kd file
    if row == 1.0
        messenger.writeMessage(254.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        continue
    end
    
    % Extract the knock-down factors and N-values from the .kd file
    kdNValues_original = kdData(:, 1.0)';
    kdFactors_original = kdData(:, 2.0)';
    
    % N-values must be increasing from top to bottom
    if all(diff(kdNValues_original) > 0.0) ~= 1.0
        messenger.writeMessage(150.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        continue
    end
    
    % Initialise the variable containing scaled S-values
    scaled_sValues = zeros(1.0, 1.0);
    
    %{
        Begin scaling the S-N data. Repeat the process for each S-N curve
        if there is more than one R-ratio defiend for the current material
    %}
    for r = 1:nSets
        % Get the S-values for the current S-N curve
        sValues = sValues_original(r, :);
        nValues = nValues_original;
        kdNValues = kdNValues_original;
        kdFactors = kdFactors_original;
        
        %{
            Starting from the lowest knock-down Nf value, interpolate to find
            the corresponding S-values and N-values for the original S-values.
            If the Nf values exceed the Nf values of the original N-values,
            stop interpolating
        %}
        for i = 1:row
            % Get the current knock-down N-value
            N = kdNValues(i);
            %{
                If the current knock-down N-value does not appear in the
                original N-value list, interpolate/extrapolate to find the
                corresponding S-value for the original S-N data
            %}
            if isempty(find(nValues == N, 1.0)) == 1.0
                %{
                    The current N-value in the S-N knock-down list does not
                    appear in the original S-N data
                %}
                if N < nValues(1.0)
                    %{
                        The current N-value in the S-N knock-down list is less
                        than the minimum N-value in the original S-N data.
                        EXTRAPOLATE to find the corresponding S-value for the
                        original S-N data
                    %}
                    S = 10^(interp1(log10(nValues), log10(sValues), log10(N), 'linear', 'extrap'));
                    
                    %{
                        Prepend the extrapolated S-N value to the beginning of
                        the original S-N data
                    %}
                    sValues = [S, sValues]; %#ok<AGROW>
                    nValues = [N, nValues]; %#ok<AGROW>
                elseif N > nValues(end)
                    %{
                        The current N-value in the S-N knock-down list is
                        greater than the maximum N-value in the original S-N
                        data. BREAK from the loop
                    %}
                    break
                else
                    %{
                        The current N-value in the S-N knock-down list lies
                        between two N-values in the original S-N data.
                        INTERPOLATE to find the corresponding S-value for the
                        original S-N data
                    %}
                    S = 10^(interp1(log10(nValues), log10(sValues), log10(N), 'linear'));
                    
                    %{
                        Add the interpolated S-N value to the original S-N
                        data. Find where the data belongs in the original list
                    %}
                    for j = 1:length(nValues) - 1.0
                        if (N > nValues(j)) && (N < nValues(j + 1.0))
                            sValues = [sValues(1.0:j), S, sValues(j+1.0:end)];
                            nValues = [nValues(1.0:j), N, nValues(j+1.0:end)];
                            
                            break
                        end
                    end
                end
            end
        end
        
        %{
            Starting from the lowest original Nf value, interpolate to find the
            corresponding knock-down scales and knock-down N-values.
            Interpolate all the way up to the largest N-value
        %}
        for i = 1:length(nValues)
            % Get the current N-value from the original S-N data
            N = nValues(i);
            %{
                If the current N-value from the original S-N data does not
                appear in the knock-down N-value list, interpolate/extrapolate
                to find the knock-down factor for the corresponding knock-down
                N-value
            %}
            if isempty(find(kdNValues == N, 1.0)) == 1.0
                %{
                    The current N-value in the original S-N data does not
                    appear in the knock-down data
                %}
                
                if (N < kdNValues(1.0)) || (N > kdNValues(end))
                    %{
                        The current N-value in the original S-N list is
                        less than the minimum or greater than the largest
                        N-value in the knock-down S-N data. EXTRAPOLATE to
                        find the corresponding S-value for the knock-down
                        S-N data
                    %}
                    
                    F = 10^(interp1(log10(kdNValues), log10(kdFactors), log10(N), 'linear', 'extrap'));
                    
                    if N < kdNValues(1.0)
                        %{
                            Prepend the extrapolated knock-down factor
                            value to the beginning of the knock-down S-N
                            data
                        %}
                        kdFactors = [F, kdFactors]; %#ok<AGROW>
                        kdNValues = [N, kdNValues]; %#ok<AGROW>
                    else
                        %{
                            Append the extrapolated knock-down factor value
                            to the beginning of the knock-down S-N data
                        %}
                        kdFactors = [kdFactors, F]; %#ok<AGROW>
                        kdNValues = [kdNValues, N]; %#ok<AGROW>
                    end
                else
                    F = 10^(interp1(log10(kdNValues), log10(kdFactors), log10(N), 'linear'));
                    
                    %{
                        Add the interpolated knock-down factor to the
                        knock-down data. Find where the data belongs in the
                        original list
                    %}
                    for j = 1:length(kdNValues) - 1.0
                        if (N > kdNValues(j)) && (N < kdNValues(j + 1.0))
                            kdFactors = [kdFactors(1.0:j), F, kdFactors(j+1.0:end)];
                            kdNValues = [kdNValues(1.0:j), N, kdNValues(j+1.0:end)];
                            
                            break
                        end
                     end
                end
            end
        end
        
        % Remove knock-down data which extends beyond the maximum S-N data pair
        elementsToDelete = length(kdFactors) - length(nValues);
        kdFactors(end - (elementsToDelete - 1.0):end) = [];
        
        %{
            Scale the original S-N data by the knock-down factors
        %}
        scaled_sValues(r, 1:length(sValues)) = sValues.*kdFactors;
    end
    
    %{
        Check the knock-down S-N curve for consistency. S-values must be
        decreasing
    %}
    if all(diff(scaled_sValues) < 0.0) ~= 1.0
        messenger.writeMessage(255.0)
        
        kd_error = getappdata(0, 'kd_error');
        kd_error(groups) = 1.0;
        setappdata(0, 'kd_error', kd_error)
        continue
    end
    
    % Save the scaled S-N data to the APPDATA
    setappdata(0, 's_values', scaled_sValues)
    setappdata(0, 'n_values', nValues)
    
    % Save the Kt definitions for the current group
    group.saveMaterial(groups)
end
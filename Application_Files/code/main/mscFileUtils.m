classdef mscFileUtils < handle
%MSCFILEUTILS    QFT class for mean stress correction processing.
%   This class contains methods for mean stress correction file processing
%   tasks.
%   
%   MSCFILEUTILS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        
        %% CHECK THE DEFINITION OF THE USER FRF DATA
        function [error, mscData_i] = checkUserData(mscData_i, group, mscORfrf)
            error = 0.0;
            setappdata(0, 'mscORfrf', mscORfrf)
            
            if ischar(mscData_i) == 1.0
                
                if exist(mscData_i, 'file') == 0.0
                    % Check that the .msc file exists
                    setappdata(0, 'E049', 1.0)
                    setappdata(0, 'msCorrection', mscData_i)
                    error = 1.0;
                    
                    return
                else
                    %% FILE OPEN CHECK
                    try
                        frfData = dlmread(mscData_i);
                    catch errorMessage
                        setappdata(0, 'msCorrection', mscData_i)
                        setappdata(0, 'E050', 1.0)
                        setappdata(0, 'error_log_050_message', errorMessage)
                        error = 1.0;
                        
                        return
                    end
                    
                    %% COLUMN NUMBER CHECK
                    [mscRows, mscColumns] = size(frfData);
                    if mscColumns ~= 2.0
                        error = 1.0;
                        setappdata(0, 'E139', 1.0)
                        setappdata(0, 'E139_group', group)
                        setappdata(0, 'E139_file', mscData_i)
                        
                        return
                    end
                    
                    % Get the Sm and Sa values
                    sm_values = frfData(:, 1.0);
                    sa_values = frfData(:, 2.0);
                    
                    %% MINIMUM PAIR CHECK
                    if mscRows < 3.0
                        error = 1.0;
                        setappdata(0, 'E140', 1.0)
                        setappdata(0, 'E140_group', group)
                        setappdata(0, 'E140_file', mscData_i)
                        
                        return
                    end
                    
                    %% Sm OVER-UNITY CHECK
                    if any(sm_values > 1.0) == 1.0
                        setappdata(0, 'message_237_group', group)
                        setappdata(0, 'message_237_file', mscData_i)
                        messenger.writeMessage(237.0)
                    end
                    
                    %% DECREASING Sm CHECK
                    for i = 2:mscRows
                        if sm_values(i) >= sm_values(i - 1.0)
                            setappdata(0, 'msCorrection', mscData_i)
                            setappdata(0, 'E048', 1.0)
                            setappdata(0, 'E048_group', group)
                            error = 1.0;
                            
                            return
                        end
                    end
                    
                    %% NEGATIVE Sa CHECK
                    if any(sa_values < 0.0) == 1.0
                        error = 1.0;
                        setappdata(0, 'E138', 1.0)
                        setappdata(0, 'E138_group', group)
                        setappdata(0, 'E138_file', mscData_i)
                        
                        return
                    end
                    
                    %% INTERMEDIATE POINT CHECK
                    if length(sa_values) > 2.0
                        markForDelete = [];
                        
                        for i = 2:length(sa_values) - 1.0
                            m1 = (sa_values(i) - sa_values(i - 1.0))/(sm_values(i) - sm_values(i - 1.0));
                            m2 = (sa_values(i + 1.0) - sa_values(i))/(sm_values(i + 1.0) - sm_values(i));
                            
                            if (m1/m2 < 1.000000000000007) && (m1/m2 > 0.999999999999993)
                                markForDelete = [markForDelete, i]; %#ok<AGROW>
                            end
                        end
                        
                        sa_values(markForDelete) = [];
                        sm_values(markForDelete) = [];
                    end
                    
                    %% Sa AT Sm=0 CHECK
                    %{
                        For greater ease in the calculation, interpolate
                        find an Sa value at Sm=0 if one does not already
                        exist
                    %}
                    if isempty(find(sm_values == 0.0, 1.0)) == 1.0
                        Sa_Sm0 = interp1(sm_values, sa_values, 0.0);
                        
                        if isnan(Sa_Sm0) == 1.0
                            Sa_Sm0 = 1.0;
                        end
                        
                        if length(find(sm_values > 0.0)) == length(sm_values)
                            sm_values = [sm_values', 0.0]';
                            sa_values = [sa_values', Sa_Sm0]';
                        elseif length(find(sm_values < 0.0)) == length(sm_values)
                            sm_values = [0.0, sm_values']';
                            sa_values = [Sa_Sm0, sa_values']';
                        else
                            for i = 1:length(sm_values)
                                if (sm_values(i) > 0.0) && (sm_values(i + 1.0) < 0.0)
                                    sm_values = [sm_values(1.0:i)', 0.0, sm_values(i + 1.0:end)']';
                                    sa_values = [sa_values(1.0:i)', Sa_Sm0, sa_values(i + 1.0:end)']';
                                    break
                                end
                            end
                        end
                    end
                    
                    %% ADJACENT Sa VALUE CHECK
                    %{
                        If there are any adjacent Sa values, adjust them so
                        that the neighbouring value is very slightly
                        different
                    %}
                    message240Warning = 0.0;
                    
                    index = 1.0;
                    maxIterations = length(sa_values);
                    while index < (maxIterations - 1.0)
                        if sa_values(index) == sa_values(index + 1.0)
                            if maxIterations == 2.0
                                % e.g. [1.0, 1.0]
                                sa_values(index + 1.0) = sa_values(index + 1.0) + 1e-6;
                            elseif (index + 1.0 == maxIterations) && (sa_values(index - 1.0) < sa_values(index))
                                % e.g. [..., 1.0, 2.0, 2.0]
                                sa_values(index) = sa_values(index) - 1e-6;
                            elseif (index + 1.0 == maxIterations) && (sa_values(index - 1.0) > sa_values(index))
                                % e.g. [..., 2.0, 1.0, 1.0]
                                sa_values(index) = sa_values(index) + 1e-6;
                            elseif (index == 1.0) && (sa_values(index + 2.0) > sa_values(index + 1.0))
                                % e.g. [1.0, 1.0, 2.0,...]
                                sa_values(index + 1.0) = sa_values(index + 1.0) + 1e-6;
                            elseif (index == 1.0) && (sa_values(index + 2.0) < sa_values(index + 1.0))
                                % e.g. [2.0, 2.0, 1.0,...]
                                sa_values(index + 1.0) = sa_values(index + 1.0) - 1e-6;
                            elseif sa_values(index + 2.0) < sa_values(index + 1.0)
                                % e.g. [..., 2.0, 2.0, 1.0,...]
                                sa_values(index + 1.0) = sa_values(index + 1.0) - 1e-6;
                            elseif sa_values(index + 2.0) > sa_values(index + 1.0)
                                % e.g. [..., 1.0, 1.0, 2.0,...]
                                sa_values(index + 1.0) = sa_values(index + 1.0) + 1e-6;
                            elseif sa_values(index + 2.0) == sa_values(index + 1.0)
                                % e.g. [..., 1.0, 1.0, 1.0,...]
                                if sm_values(index + 1.0) ~= 0.0
                                    sa_values(index + 1.0) = [];
                                    sm_values(index + 1.0) = [];
                                    
                                    maxIterations = maxIterations - 1.0;
                                elseif sa_values(index - 1.0) < sa_values(index)
                                    sa_values(index) = sa_values(index + 1.0) - 1e-6;
                                else
                                    sa_values(index) = sa_values(index + 1.0) + 1e-6;
                                end
                            end
                            
                            message240Warning = 1.0;
                            
                            index = index + 1.0;
                        else
                            index = index + 1.0;
                        end
                    end
                    
                    % Warn the user if applicable
                    if message240Warning == 1.0
                        setappdata(0, 'message_240_group', group)
                        setappdata(0, 'message_240_file', mscData_i)
                        messenger.writeMessage(240.0)
                    end
                    
                    %% UNCLOSED ENVELOPE CHECK
                    if ((sm_values(end) < 0.0) && (sa_values(end) > 0.0))...
                            || ((sm_values(1.0) > 0.0) && (sa_values(1.0) > 0.0))
                        setappdata(0, 'message_241_group', group)
                        setappdata(0, 'message_241_file', mscData_i)
                        messenger.writeMessage(241.0)
                    end
                    
                    %% Sa VALUE CURVATURE CHECK
                    positiveIndexes = sm_values > 0.0;
                    sa_values_p = sa_values(positiveIndexes);
                    sm_values_p = sm_values(positiveIndexes);
                    
                    if isempty(sa_values_p) == 0.0
                        for i = 1:length(sa_values_p)
                            %{
                                Get the equation of the straight line from
                                the origin to the current Sa-Sm value
                            %}
                            i2 = length(sa_values_p) - (i - 1.0);
                            for j = 1:(i - 1.0)
                                j2 = length(sa_values_p) - (j - 1.0);
                                if sa_values_p(j2) <= ((sa_values_p(i2)/sm_values_p(i2))*sm_values_p(j2))
                                    error = 1.0;
                                    setappdata(0, 'E137', 1.0)
                                    setappdata(0, 'E137_group', group)
                                    setappdata(0, 'E137_file', mscData_i)
                                    
                                    return
                                end
                            end
                        end
                    end
                    
                    % Do the same for the negative Sm values
                    negativeIndexes = sm_values < 0.0;
                    sa_values_n = sa_values(negativeIndexes);
                    sm_values_n = sm_values(negativeIndexes);
                    
                    if isempty(sa_values_n) == 0.0
                        for i = 1:length(sa_values_n)
                            %{
                                Get the equation of the straight line from
                                the origin to the current Sa-Sm value
                            %}
                            for j = 1:(i - 1.0)
                                if sa_values_n(j) <= ((sa_values_n(i)/sm_values_n(i))*sm_values_n(j))
                                    error = 1.0;
                                    setappdata(0, 'E137', 1.0)
                                    setappdata(0, 'E137_group', group)
                                    setappdata(0, 'E137_file', mscData_i)
                                    
                                    return
                                end
                            end
                        end
                    end
                    
                    %% DUPLICATE SIDE Sa VALUES CHECK
                    x = find(sm_values == 0.0);
                    sa_values_n = [sa_values(x), sa_values_n']';
                    sa_values_p = [sa_values_p', sa_values(x)]';
                    
                    if (all(diff(sort(sa_values_n))) == 0.0) || (all(diff(sort(sa_values_p))) == 0.0) %#ok<TRSRT>
                        error = 1.0;
                        setappdata(0, 'E141', 1.0)
                        setappdata(0, 'E141_group', group)
                        setappdata(0, 'E141_file', mscData_i)
                        
                        return
                    end
                    
                    %% DATA SIDE CHECK
                    if any(sm_values > 0.0) == 0.0
                        setappdata(0, 'message_238_group', group)
                        setappdata(0, 'message_238_file', mscData_i)
                        messenger.writeMessage(238.0)
                    end
                    
                    if any(sm_values < 0.0) == 0.0
                        setappdata(0, 'message_239_group', group)
                        setappdata(0, 'message_239_file', mscData_i)
                        messenger.writeMessage(239.0)
                    end
                end
                
                %% CONCATENATE NEW Sm-Sa VALUES
                frfData = [sm_values, sa_values];
                
                if strcmp(mscORfrf, 'MSC') == 1.0
                    % Save the MSC data
                    setappdata(0, 'userMSCData', frfData)
                    
                    % Set msCorrection to -1.0
                    setappdata(0, 'userMSCFile', mscData_i)
                    mscData_i = -1.0;
                else
                    % Save the FRF data
                    frfData = [sm_values, sa_values];
                    setappdata(0, 'userFRFData', frfData)
                    
                    % Set frfEnevlope to -1.0
                    setappdata(0, 'frfEnvelope', -1.0)
                end
            else
                if strcmp(mscORfrf, 'MSC') == 1.0
                    defaultMSC = getappdata(0, 'defaultMSC');
                    
                    % If the default MSC is requested, check if it is available
                    if mscData_i == 0.0
                        mscData_i = defaultMSC;
                        % Check if the requested MSC is available
                    elseif (mod(mscData_i, 1.0) ~= 0.0) || (mscData_i > 8.0)
                        mscData_i = defaultMSC;
                    end
                else
                    % Save the FRF data
                    setappdata(0, 'userFRFData', [])
                    
                    % Set frfEnevlope
                    setappdata(0, 'frfEnvelope', mscData_i)
                end
            end
        end
        
        %% PLOT THE CURRENT CYCLE ON THE USER FRF ENVELOPE
        function plotUserFRFCycle(Smi, Sai, frfData_m, frfData_a, item)
            % Get the current figure handle
            f1 = figure('visible', 'off');
            
            % Defaults
            lineWidth = getappdata(0, 'defaultLineWidth');
            fontX = getappdata(0, 'defaultFontSize_XAxis');
            fontY = getappdata(0, 'defaultFontSize_YAxis');
            fontTitle = getappdata(0, 'defaultFontSize_Title');
            fontTicks = getappdata(0, 'defaultFontSize_Ticks');
            gridLines = getappdata(0, 'gridLines');
            
            % Plot the user FRF envelope
            p1 = plot(frfData_m, frfData_a, 'ko-', 'lineWidth', lineWidth);
            hold on
            
            % Plot the cycle
            p2 = scatter(Smi, Sai, 40, 'MarkerEdgeColor', [0.5 0 0.5],...
                'MarkerFaceColor', [0.7 0 0.7], 'LineWidth', lineWidth);
            
            % Plot the radial
            if Smi >= 0.0
                positiveM = frfData_m >= 0.0;
                frfData_a_side = frfData_a(positiveM);
                frfData_m_side = frfData_m(frfData_m >= 0.0);
            else
                negativeM = frfData_m <= 0.0;
                frfData_a_side = frfData_a(negativeM);
                frfData_m_side = frfData_m(frfData_m <= 0.0);
            end
            mo = Sai/Smi;
            
            for c = 1:length(frfData_a_side) - 1.0
                
                % Gradient of the current line
                m = (frfData_a_side(c) - frfData_a_side(c + 1.0))/(frfData_m_side(c) - frfData_m_side(c + 1.0));
                
                % Coordinates of the intercept with the radial
                SmU = (m*frfData_m_side(c) - frfData_a_side(c))/(m - mo);
                SaU = mo*SmU;
                
                if ((SmU <= frfData_m_side(c) && SmU >= frfData_m_side(c + 1.0)) || (SmU >= frfData_m_side(c) && SmU <= frfData_m_side(c + 1.0))) ...
                        && ((SaU <= frfData_a_side(c) && SaU >= frfData_a_side(c + 1.0)) || (SaU >= frfData_a_side(c) && SaU <= frfData_a_side(c + 1.0)))
                    % The correct intercept has been found
                    break
                end
            end
            
            if abs(Smi) > abs(SmU)
                x = linspace(0.0, Smi, 2.0);
            else
                x = linspace(0.0, SmU, 2.0);
            end
            
            y = mo.*x;
            
            p3 = plot(x, y, '--b', 'lineWidth', lineWidth);
            
            % Plot the horizontal
            p4 = plot([frfData_m(end), frfData_m(1.0)], [Sai, Sai], '--g', 'lineWidth', lineWidth);
            
            % Plot the vertical
            SaU = interp1(frfData_m, frfData_a, Smi);
            
            if Sai < SaU
                p5 = line([Smi, Smi], [0.0, SaU], 'LineWidth', lineWidth);
            else
                p5 = line([Smi, Smi], [0.0, Sai], 'LineWidth', lineWidth);
            end
            
            if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                grid on
            end
            
            % Save the figure
            mainID = getappdata(0, 'mainID');
            subID = getappdata(0, 'subID');
            
            xlabel('Normalized mean stress', 'FontSize', fontX)
            ylabel('Normalized stress amplitude', 'FontSize', fontY)
            title(sprintf('UFRF, User FRF diagnostics at item %.0f.%.0f', mainID(item), subID(item)), 'FontSize', fontTitle)
            set(gca, 'FontSize', fontTicks)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            legend([p1, p2, p3, p4, p5], 'FRF Envelope', 'Cycle', 'Radial', 'Horizontal', 'Vertical')
            
            dir = [getappdata(0, 'outputDirectory'), sprintf('MATLAB Figures/UFRF, User FRF diagnostics at data set location %.0f', item)];
            figureFormat = getappdata(0, 'figureFormat');
            saveas(f1, dir, figureFormat)
            if strcmpi(figureFormat, 'fig') == true
                postProcess.makeVisible([dir, '.fig'])
            end
        end
    end
end
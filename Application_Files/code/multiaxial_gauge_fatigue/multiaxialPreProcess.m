classdef multiaxialPreProcess < handle
%MULTIAXIALPREPROCESS    QFT class for Multiaxial Gauge Fatigue.
%   This class contains methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   MULTIAXIALPREPROCESS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also multiaxialAnalysis, multiaxialPostProcess, gaugeOrientation,
%   materialOptions, MultiaxialFatigue.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.2 Multiaxial Gauge Fatigue
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods (Static = true)
        
        %% Blank the GUI
        function [] = blank(handles)
            set(handles.text_gauge_0, 'enable', 'off')
            set(handles.text_gauge_45, 'enable', 'off')
            set(handles.text_gauge_90, 'enable', 'off')
            set(handles.edit_gauge_0, 'enable', 'off')
            set(handles.edit_gauge_45, 'enable', 'off')
            set(handles.edit_gauge_90, 'enable', 'off')
            set(handles.pButton_gauge_0_path, 'enable', 'off')
            set(handles.pButton_gauge_45_path, 'enable', 'off')
            set(handles.pButton_gauge_90_path, 'enable', 'off')
            set(handles.text_units, 'enable', 'off')
            set(handles.pMenu_units, 'enable', 'off')
            set(handles.text_conversionFactor, 'enable', 'off')
            set(handles.edit_conversionFactor, 'enable', 'off')
            set(handles.pButton_gaugeOrientation, 'enable', 'off')
            
            set(handles.text_material, 'enable', 'off')
            set(handles.edit_material, 'enable', 'off')
            set(handles.pButton_materialOptions, 'enable', 'off')
            set(handles.pButton_browseMaterial, 'enable', 'off')
            set(handles.pButton_createMaterial, 'enable', 'off')
            set(handles.pButton_matManager, 'enable', 'off')
            
            set(handles.rButton_algorithm_ps, 'enable', 'off')
            set(handles.rButton_algorithm_bm, 'enable', 'off')
            set(handles.text_precision, 'enable', 'off')
            set(handles.edit_precision, 'enable', 'off')
            
            set(handles.rButton_msc_none, 'enable', 'off')
            set(handles.rButton_msc_morrow, 'enable', 'off')
            set(handles.rButton_msc_user, 'enable', 'off')
            set(handles.text_msc_user, 'enable', 'off')
            set(handles.edit_msc_user, 'enable', 'off')
            set(handles.pButton_msc_user, 'enable', 'off')
            set(handles.check_ucs, 'enable', 'off')
            set(handles.edit_ucs, 'enable', 'off')
            set(handles.text_mpa, 'enable', 'off')
            
            set(handles.text_defineSurfaceFinish, 'enable', 'off')
            set(handles.rButton_kt_list, 'enable', 'off')
            set(handles.rButton_kt_value, 'enable', 'off')
            set(handles.text_RzEq, 'enable', 'off')
            set(handles.text_microns, 'enable', 'off')
            set(handles.edit_rz, 'enable', 'off')
            set(handles.text_definitionFile, 'enable', 'off')
            set(handles.pMenu_kt_list, 'enable', 'off')
            set(handles.text_surfaceFinish, 'enable', 'off')
            set(handles.pMenu_surfaceFinish, 'enable', 'off')
            set(handles.check_kt_direct, 'enable', 'off')
            set(handles.text_KtEq, 'enable', 'off')
            set(handles.edit_kt, 'enable', 'off')
            
            set(handles.check_location, 'enable', 'off')
            set(handles.edit_location, 'enable', 'off')
            set(handles.pButton_location, 'enable', 'off')
            
            set(handles.pButton_reset, 'enable', 'off')
            set(handles.pButton_analyse, 'enable', 'off')
            set(handles.pButton_cancel, 'enable', 'off')
        end
        
        %% Re-enable the GUI
        function [] = enable(handles)
            set(handles.text_gauge_0, 'enable', 'on')
            set(handles.text_gauge_45, 'enable', 'on')
            set(handles.text_gauge_90, 'enable', 'on')
            set(handles.edit_gauge_0, 'enable', 'on')
            set(handles.edit_gauge_45, 'enable', 'on')
            set(handles.edit_gauge_90, 'enable', 'on')
            set(handles.pButton_gauge_0_path, 'enable', 'on')
            set(handles.pButton_gauge_45_path, 'enable', 'on')
            set(handles.pButton_gauge_90_path, 'enable', 'on')
            set(handles.text_units, 'enable', 'on')
            set(handles.pMenu_units, 'enable', 'on')
            if get(handles.pMenu_units, 'value') == 3.0
                set(handles.text_conversionFactor, 'enable', 'on')
                set(handles.edit_conversionFactor, 'enable', 'on')
            end
            set(handles.pButton_gaugeOrientation, 'enable', 'on')
            
            set(handles.text_material, 'enable', 'on')
            set(handles.edit_material, 'enable', 'on')
            set(handles.pButton_materialOptions, 'enable', 'on')
            set(handles.pButton_browseMaterial, 'enable', 'on')
            set(handles.pButton_createMaterial, 'enable', 'on')
            set(handles.pButton_matManager, 'enable', 'on')
            
            set(handles.rButton_algorithm_ps, 'enable', 'on')
            set(handles.rButton_algorithm_bm, 'enable', 'on')
            set(handles.text_precision, 'enable', 'on')
            set(handles.edit_precision, 'enable', 'on')
            
            set(handles.rButton_msc_none, 'enable', 'on')
            set(handles.rButton_msc_morrow, 'enable', 'on')
            set(handles.rButton_msc_user, 'enable', 'on')
            if get(handles.rButton_msc_user, 'value') == 1.0
                set(handles.text_msc_user, 'enable', 'on')
                set(handles.edit_msc_user, 'enable', 'on')
                set(handles.pButton_msc_user, 'enable', 'on')
                set(handles.check_ucs, 'enable', 'on')
                if get(handles.check_ucs, 'value') == 1.0
                    set(handles.edit_ucs, 'enable', 'on', 'backgroundColor', 'white')
                    set(handles.text_mpa, 'enable', 'on')
                else
                    set(handles.edit_ucs, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
                end
            else
                set(handles.edit_ucs, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
            end
            
            set(handles.check_kt_direct, 'enable', 'on')
            if get(handles.check_kt_direct, 'value') == 1.0
                set(handles.text_KtEq, 'enable', 'on')
                set(handles.edit_kt, 'enable', 'on')
            else
                set(handles.text_defineSurfaceFinish, 'enable', 'on')
                set(handles.rButton_kt_list, 'enable', 'on')
                set(handles.rButton_kt_value, 'enable', 'on')
                
                if get(handles.rButton_kt_list, 'value') == 1.0
                    set(handles.text_definitionFile, 'enable', 'on')
                    set(handles.pMenu_kt_list, 'enable', 'on')
                    set(handles.text_surfaceFinish, 'enable', 'on')
                    set(handles.pMenu_surfaceFinish, 'enable', 'on')
                else
                    set(handles.text_RzEq, 'enable', 'on')
                    set(handles.text_microns, 'enable', 'on')
                    set(handles.edit_rz, 'enable', 'on')
                    set(handles.text_definitionFile, 'enable', 'on')
                    set(handles.pMenu_kt_list, 'enable', 'on')
                end
            end
            
            set(handles.check_location, 'enable', 'on')
            if get(handles.check_location, 'value') == 1.0
                set(handles.edit_location, 'enable', 'on')
                set(handles.pButton_location, 'enable', 'on')
            else
                set(handles.edit_location, 'enable', 'inactive')
            end
            
            set(handles.pButton_reset, 'enable', 'on')
            set(handles.pButton_analyse, 'enable', 'on')
            set(handles.pButton_cancel, 'enable', 'on')
        end

        %% Prescan the file selection
        function [e0, e45, e90, timeHistory0, timeHistory45, timeHistory90, error] = preScanFile(handles)
            %% Initialise output
            error = 0.0;
            e0 = -1.0;
            e45 = -1.0;
            e90 = -1.0;
            timeHistory0 = -1.0;
            timeHistory45 = -1.0;
            timeHistory90 = -1.0;
            
            %% Check if each file exists
            pathGauge0 = get(handles.edit_gauge_0, 'string');
            pathGauge45 = get(handles.edit_gauge_45, 'string');
            pathGauge90 = get(handles.edit_gauge_90, 'string');
            
            if (isempty(pathGauge0) == 1.0) || (isempty(pathGauge45) == 1.0) || (isempty(pathGauge90) == 1.0)
                errordlg('All three gauge signals must be defined.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if exist(pathGauge0, 'file') == 0.0
                errorMessage = sprintf('Error while processing ''%s''. The file could not be located.',...
                    pathGauge0);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if exist(pathGauge45, 'file') == 0.0
                errorMessage = sprintf('Error while processing ''%s''. The file could not be located.',...
                    pathGauge45);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if exist(pathGauge90, 'file') == 0.0
                errorMessage = sprintf('Error while processing ''%s''. The file could not be located.',...
                    pathGauge90);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Check if each file can be read
            try
                gauge0Data = dlmread(pathGauge0);
            catch
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.',...
                    pathGauge0);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            try
                gauge45Data = dlmread(pathGauge45);
            catch
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.',...
                    pathGauge45);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            try
                gauge90Data = dlmread(pathGauge90);
            catch
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.',...
                    pathGauge90);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Check for non-numeric data in each file
            if any(any(isinf(gauge0Data))) == 1.0 || any(any(isnan(gauge0Data))) == 1.0 || any(any(isreal(gauge0Data))) == 0.0
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', pathGauge0);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if any(any(isinf(gauge45Data))) == 1.0 || any(any(isnan(gauge45Data))) == 1.0 || any(any(isreal(gauge45Data))) == 0.0
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', pathGauge45);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if any(any(isinf(gauge90Data))) == 1.0 || any(any(isnan(gauge90Data))) == 1.0 || any(any(isreal(gauge90Data))) == 0.0
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', pathGauge90);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Make sure the dimensions of each data channel are consistent
            %{
                If the user provided a time history, the data is allowed to
                be either 2xN or Nx2
            %}
            errorMessage2 = sprintf('\n\nThe data has invalid dimensions. Refer to the Quick Fatigue Tool User Guide for gauge signal definition.');
            
            [rA, cA] = size(gauge0Data);
            if (rA == 2.0) && (cA > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second row of data
                %}
                timeHistory0 = gauge0Data(2.0, :);
                gauge0Data = gauge0Data(1.0, :);
                length0Data = cA;
                rA = 1.0;
            elseif (cA == 2.0) && (rA > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second column of data
                %}
                timeHistory0 = gauge0Data(:, 2.0);
                gauge0Data = gauge0Data(:, 1.0);
                length0Data = rA;
            elseif (cA == 1.0) && (rA > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of rows
                %}
                timeHistory0 = linspace(0.0, (rA - 1.0), rA);
                length0Data = rA;
            elseif (rA == 1.0) && (cA > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of
                    columns
                %}
                timeHistory0 = linspace(0.0, (cA - 1.0), cA);
                length0Data = cA;
            else
                %{
                    The data dimensions are invalid. Abort and warn the
                    user
                %}
                errorMessage1 = sprintf('Error while processing ''%s''.', pathGauge0);
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            [rB, cB] = size(gauge45Data);
            if (rB == 2.0) && (cB > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second row of data
                %}
                timeHistory45 = gauge45Data(2.0, :);
                gauge45Data = gauge45Data(1.0, :);
                length45Data = cA;
                rB = 1.0;
            elseif (cB == 2.0) && (rB > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second column of data
                %}
                timeHistory45 = gauge45Data(:, 2.0);
                gauge45Data = gauge45Data(:, 1.0);
                length45Data = rB;
            elseif (cB == 1.0) && (rB > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of rows
                %}
                timeHistory45 = linspace(0.0, (rB - 1.0), rB);
                length45Data = rB;
            elseif (rB == 1.0) && (cB > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of
                    columns
                %}
                timeHistory45 = linspace(0.0, (cB - 1.0), cB);
                length45Data = cB;
            else
                %{
                    The data dimensions are invalid. Abort and warn the
                    user
                %}
                errorMessage1 = sprintf('Error while processing ''%s''.', pathGauge45);
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            [rC, cC] = size(gauge90Data);
            if (rC == 2.0) && (cC > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second row of data
                %}
                timeHistory90 = gauge90Data(2.0, :);
                gauge90Data = gauge90Data(1.0, :);
                length90Data = cC;
                rC = 1.0;
            elseif (cC == 2.0) && (rC > 1.0)
                %{
                    The gauge definition includes a time history. Take the
                    time history as the second column of data
                %}
                timeHistory90 = gauge90Data(:, 2.0);
                gauge90Data = gauge90Data(:, 1.0);
                length90Data = rC;
            elseif (cC == 1.0) && (rC > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of rows
                %}
                timeHistory90 = linspace(0.0, (rC - 1.0), rC);
                length90Data = rC;
            elseif (rC == 1.0) && (cC > 1.0)
                %{
                    The gauge definition does not include a time history.
                    Assume a monotonic time history from the number of
                    columns
                %}
                timeHistory90 = linspace(0.0, (cC - 1.0), cC);
                length90Data = cC;
            else
                %{
                    The data dimensions are invalid. Abort and warn the
                    user
                %}
                errorMessage1 = sprintf('Error while processing ''%s''.', pathGauge90);
                errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Each time history must start at zero
            timeHistoryWarning0 = 0.0;
            timeHistoryWarning45 = 0.0;
            timeHistoryWarning90 = 0.0;
            
            if timeHistory0(1.0) ~= 0.0
                timeHistory0(1.0) = 0.0;
                timeHistoryWarning0 = 1.0;
            end
            
            if timeHistory45(1.0) ~= 0.0
                timeHistory45(1.0) = 0.0;
                timeHistoryWarning45 = 1.0;
            end
            
            if timeHistory90(1.0) ~= 0.0
                timeHistory90(1.0) = 0.0;
                timeHistoryWarning90 = 1.0;
            end
            
            %% Each time history must be increasing (Gauge 0)
            
            % Replace non-increasing values with zeros
            L = length(timeHistory0);
            delta = diff(timeHistory0);
            if any(delta <= 0.0)
                elementsToZero = [0.0; delta <= 0.0];
                
                for i = 1:L
                    if elementsToZero(i) == 1.0
                        timeHistory0(i) = 0.0;
                        
                        if i ~= L
                            if timeHistory0(i + 1.0) == timeHistory0(i - 1.0)
                                timeHistory0(i + 1.0) = 0.0;
                            end
                        end
                        
                        timeHistoryWarning0 = 1.0;
                    end
                end
                
                % Replace zeros with interpolated values
                for i = 2:L
                    if timeHistory0(i) == 0.0
                        % Determine the size of the gap
                        gap = 0.0;
                        while 1.0
                            gap = gap + 1.0;
                            
                            if i + gap > L
                                msg = 'The time history for Gauge 0 could not be interpolated because there are insufficient data points.';
                                errordlg(msg, 'Quick Fatigue Tool')
                                uiwait
                                error = 1.0;
                                return
                            elseif timeHistory0(i + gap) == 0.0
                                continue
                            else
                                break
                            end
                        end
                        
                        timeHistory0(i) = interp1([0.0, 1.0], [timeHistory0(i - 1.0), timeHistory0(i + gap)], 1.0/(gap + 1.0), 'linear');
                    end
                end
            end
            
            %% Each time history must be increasing (Gauge 45)
            
            % Replace non-increasing values with zeros
            L = length(timeHistory45);
            delta = diff(timeHistory45);
            if any(delta <= 0.0)
                elementsToZero = [0.0; delta <= 0.0];
                
                for i = 1:L
                    if elementsToZero(i) == 1.0
                        timeHistory45(i) = 0.0;
                        
                        if i ~= L
                            if timeHistory45(i + 1.0) == timeHistory45(i - 1.0)
                                timeHistory45(i + 1.0) = 0.0;
                            end
                        end
                        
                        timeHistoryWarning45 = 1.0;
                    end
                end
                
                % Replace zeros with interpolated values
                for i = 2:L
                    if timeHistory45(i) == 0.0
                        % Determine the size of the gap
                        gap = 0.0;
                        while 1.0
                            gap = gap + 1.0;
                            
                            if i + gap > L
                                msg = 'The time history for Gauge 45 could not be interpolated because there are insufficient data points.';
                                errordlg(msg, 'Quick Fatigue Tool')
                                uiwait
                                error = 1.0;
                                return
                            elseif timeHistory45(i + gap) == 0.0
                                continue
                            else
                                break
                            end
                        end
                        
                        timeHistory45(i) = interp1([0.0, 1.0], [timeHistory45(i - 1.0), timeHistory45(i + gap)], 1.0/(gap + 1.0), 'linear');
                    end
                end
            end
            
            %% Each time history must be increasing (Gauge 90)
            
            % Replace non-increasing values with zeros
            L = length(timeHistory90);
            delta = diff(timeHistory90);
            if any(delta <= 0.0)
                elementsToZero = [0.0; delta <= 0.0];
                
                for i = 1:L
                    if elementsToZero(i) == 1.0
                        timeHistory90(i) = 0.0;
                        
                        if i ~= L
                            if timeHistory90(i + 1.0) == timeHistory90(i - 1.0)
                                timeHistory90(i + 1.0) = 0.0;
                            end
                        end
                        
                        timeHistoryWarning90 = 1.0;
                    end
                end
                
                % Replace zeros with interpolated values
                for i = 2:L
                    if timeHistory90(i) == 0.0
                        % Determine the size of the gap
                        gap = 0.0;
                        while 1.0
                            gap = gap + 1.0;
                            
                            if i + gap > L
                                msg = 'The time history for Gauge 90 could not be interpolated because there are insufficient data points.';
                                errordlg(msg, 'Quick Fatigue Tool')
                                uiwait
                                error = 1.0;
                                return
                            elseif timeHistory90(i + gap) == 0.0
                                continue
                            else
                                break
                            end
                        end
                        
                        timeHistory90(i) = interp1([0.0, 1.0], [timeHistory90(i - 1.0), timeHistory90(i + gap)], 1.0/(gap + 1.0), 'linear');
                    end
                end
            end
            
            % Inform the user if there were any problem with the time histories
            if timeHistoryWarning0 == 1.0 || timeHistoryWarning45 == 1.0 || timeHistoryWarning90 == 1.0
                affectedGauges = [];
                if timeHistoryWarning0 == 1.0;
                    affectedGauges = [affectedGauges, sprintf('\nGauge 0')];
                end
                if timeHistoryWarning45 == 1.0;
                    affectedGauges = [affectedGauges, sprintf('\nGauge 45')];
                end
                if timeHistoryWarning90 == 1.0;
                    affectedGauges = [affectedGauges, sprintf('\nGauge 90')];
                end
                
                msg1 = 'Some time history points had to be re-interpolated prior to analysis to ensure consistency.';
                msg2 = ' Either the first point in the time history was non-zero, or the time history was not strictly increasing.';
                msg3 = sprintf('\n\nThese points have been corrected by interpolating between valid time points');
                msg4 = ', but the time history may no longer be valid.';
                msg5 = ' The issues were identified in the following gauge definitions:';
                msg6 = sprintf('\n%s', affectedGauges);
                msg = [msg1, msg2, msg3 msg4, msg5, msg6];
                
                response = questdlg(msg, 'Quick Fatigue Tool', 'Continue', 'Abort', 'Continue');
                
                if strcmpi(response, 'abort') == 1.0
                    error = 1.0;
                    return
                end
            end
            
            %% Make sure each signal has a length of at least 2.0
            if length0Data < 2.0
                errorMessage = sprintf('Error while processing ''%s''. The signal must contain at least 2 measurements.', pathGauge0);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if length45Data < 2.0
                errorMessage = sprintf('Error while processing ''%s''. The signal must contain at least 2 measurements.', pathGauge45);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            if length90Data < 2.0
                errorMessage = sprintf('Error while processing ''%s''. The signal must contain at least 2 measurements.', pathGauge90);
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            %% Make sure each file is the same dimension
            if rA > 1.0
                gauge0Data = gauge0Data';
            end
            
            if rB > 1.0
                gauge45Data = gauge45Data';
            end
            
            if rC > 1.0
                gauge90Data = gauge90Data';
            end
            
            [rA, ~] = size(timeHistory0);
            if rA > 1.0
                timeHistory0 = timeHistory0';
            end
            
            [rB, ~] = size(timeHistory45);
            if rB > 1.0
                timeHistory45 = timeHistory45';
            end
            
            [rC, ~] = size(timeHistory90);
            if rC > 1.0
                timeHistory90 = timeHistory90';
            end
            
            %% Interpolate each signal so their time stamps match
            
            [timeHistory0, timeHistory45, timeHistory90, gauge0Data,...
                gauge45Data, gauge90Data] =...
                multiaxialPreProcess.getCorrelatedSignal(timeHistory0,...
                timeHistory45, timeHistory90, gauge0Data, gauge45Data,...
                gauge90Data);
            
            %% Assign data to output
            e0 = gauge0Data;
            e45 = gauge45Data;
            e90 = gauge90Data;
        end
        
        %% Read the material file
        function [returnError] = preScanMaterial(handles, msCorrection)
            %% Initialise output
            returnError = 0.0;
            
            %% Get the material properties
            material = get(handles.edit_material, 'string');
            [~, material, ~] = fileparts(material);
            error = preProcess.getMaterial(material, 0.0, 1.0);
            
            %% Check for errors
            switch error
                case 1.0
                    if strcmpi(material, 'Undefined.mat') == 1.0
                        errorMessage = sprintf('A meterial must be selected for analysis.');
                    elseif isempty(material) == 1.0
                        errorMessage = sprintf('A meterial must be selected for analysis.');
                    else
                        errorMessage = sprintf('Error while processing material ''%s''. The file could not be located.\r\n\r\nThe material must be located in ''Data/material/local'' to be used for analysis.', material);
                    end
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                case 2.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file could not be opened.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                case 3.0
                    errorMessage = sprintf('Error while processing material ''%s''. The file contains one or more syntax errors.', material);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                otherwise
            end
            
            %% Check that the required material properties are available
            if isempty(getappdata(0, 'poisson')) == 1.0
                missingProperties{1} = 'UNDEFINED';
            else
                missingProperties{1} = 'OK';
            end
            
            if isempty(getappdata(0, 'Sf')) == 1.0
                missingProperties{2} = 'UNDEFINED';
                missingProperties{5} = 'NOT EVALUATED';
                missingProperties{6} = 'NOT EVALUATED';
            else
                missingProperties{2} = 'OK';
                
                if isempty(getappdata(0, 'Ef')) == 1.0
                    missingProperties{5} = 'UNDEFINED';
                else
                    missingProperties{5} = 'OK';
                end
                
                if isempty(getappdata(0, 'c')) == 1.0
                    missingProperties{6} = 'UNDEFINED';
                else
                    missingProperties{6} = 'OK';
                end
            end
            
            if isempty(getappdata(0, 'E')) == 1.0
                missingProperties{3} = 'UNDEFINED';
            else
                missingProperties{3} = 'OK';
            end
            
            if isempty(getappdata(0, 'b')) == 1.0
                missingProperties{4} = 'UNDEFINED';
            else
                missingProperties{4} = 'OK';
            end
            
            if msCorrection > 0.0
                if isempty(getappdata(0, 'kp')) == 1.0
                    missingProperties{7} = 'UNDEFINED';
                else
                    missingProperties{7} = 'OK';
                end
                
                if isempty(getappdata(0, 'np')) == 1.0
                    missingProperties{8} = 'UNDEFINED';
                else
                    missingProperties{8} = 'OK';
                end
                
                if isempty(getappdata(0, 'uts')) == 1.0 && msCorrection == 2.0
                    errordlg('The ultimate tensile strength of the material is required for user-defined mean stress correction', 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                elseif isempty(getappdata(0, 'kp')) == 1.0 ||...
                        isempty(getappdata(0, 'np')) == 1.0 ||...
                        isempty(getappdata(0, 'E')) == 1.0
                    errorMessage1 = 'Cyclic properties are required for mean stress correction. The following properties are required for analysis:';
                    errorMessage2 = sprintf('\n\nYoung''s Modulus (%s)\nCyclic strain hardening coefficient (%s)\nCyclic strain hardening exponent (%s)',...
                        missingProperties{3}, missingProperties{7}, missingProperties{8});
                    errordlg([errorMessage1, errorMessage2], 'Quick Fatigue Tool')
                    uiwait
                    returnError = 1.0;
                    return
                end
            elseif msCorrection == 2.0 && isempty(getappdata(0, 'uts')) == 1.0
                errordlg('The ultimate tensile strength of the material is required for user-defined mean stress correction', 'Quick Fatigue Tool')
                uiwait
                returnError = 1.0;
                return
            end
            
            if any(strcmpi(missingProperties, 'UNDEFINED') == 1.0)
                errorMessage1 = sprintf('Error while processing the material definition. The following properties are required for analysis:\n\n');
                errorMessage2 = sprintf('Poisson''s ratio (%s)\nYoung''s Modulus (%s)\nFatigue strength coefficient (%s)\n',...
                    missingProperties{1}, missingProperties{3}, missingProperties{2});
                errorMessage3 = sprintf('Fatigue strength exponent (%s)\nFatigue ductility coefficient (%s)\nFatigue ductility exponent (%s)',...
                    missingProperties{4}, missingProperties{5}, missingProperties{6});
                errorMessage = [errorMessage1, errorMessage2, errorMessage3];
                errordlg(errorMessage, 'Quick Fatigue Tool')
                uiwait
                returnError = 1.0;
                return
            end
        end
        
        %% Read the surface finish definition
        function [ktError] = preScanKt(handles)
            ktError = 0.0;
            
            if get(handles.check_kt_direct, 'value') == 1.0
                kt = str2double(get(handles.edit_kt, 'string'));
                
                if isnan(kt) == 1.0 || isinf(kt) == 1.0 || isreal(kt) == 0.0
                    errordlg('An invalid Kt value was specified. Kt must be equal to or greater than 1.',...
                        'Quick Fatigue Tool')
                    uiwait
                    ktError = 1.0;
                    return
                elseif kt < 1.0
                    errordlg('An invalid Kt value was specified. Kt must be equal to or greater than 1.',...
                        'Quick Fatigue Tool')
                    uiwait
                    ktError = 1.0;
                    return
                else
                    setappdata(0, 'kt', kt)
                end
            else
                try
                    if get(handles.rButton_kt_list, 'value') == 1.0
                        kt_files = {'default.kt', 'juvinall-1967.kt', 'rcjohnson-1973.kt'};
                    else
                        kt_files = {'Niemann-Winter-Cast-Iron-Lamellar-Graphite.ktx',...
                            'Niemann-Winter-Cast-Iron-Nodular-Graphite.ktx',...
                            'Niemann-Winter-Cast-Steel.ktx',...
                            'Niemann-Winter-Malleable-Cast-Iron.ktx',...
                            'Niemann-Winter-Rolled-Steel.ktx',...
                            'Corroded in tap water.ktx',...
                            'Corroded in salt water.ktx'};
                    end
                    kt_value = get(handles.pMenu_kt_list, 'value');
                    fileName = kt_files{kt_value};
                    ktData = dlmread(['Data/kt/', fileName]);
                catch
                    errorMessage = sprintf('Error whie processing ''%s''. Check that the file exists and the contents are valid.',...
                        fileName);
                    errordlg(errorMessage, 'Quick Fatigue Tool')
                    uiwait
                    ktError = 1.0;
                    return
                end
                
                uts = getappdata(0, 'uts');
                
                if get(handles.rButton_kt_list, 'value') == 1.0
                    % Surface finish is defined from a list
                    
                    ktCurve = get(handles.pMenu_surfaceFinish, 'value');
                    
                    x = ktData(:, 1.0);
                    y = ktData(:, ktCurve + 1.0);
                    
                    % If the UTS exceeds the range of UTS values, take
                    % the last Kt value
                    if isempty(uts)
                        errordlg('Error while processing surface finish definition. A value for the ultimate tensile strength is required when using Kt curves.',...
                            'Quick Fatigue Tool')
                        uiwait
                        ktError = 1.0;
                        return
                    end
                    
                    if uts > x(end)
                        setappdata(0, 'kt', y(end))
                    else
                        setappdata(0, 'kt', interp1(x, y, uts))
                    end
                else
                    % Surface finish is defined as a value
                    
                    % Get Rz values
                    Rz = ktData(1.0, 1.0:end - 1.0);
                    
                    % Get user Rz value
                    rz = str2double(get(handles.edit_rz, 'string'));
                
                    if isnan(rz) == 1.0 || isinf(rz) == 1.0 || isreal(rz) == 0.0
                        errordlg('An invalid Rz value was specified.',...
                            'Quick Fatigue Tool')
                        uiwait
                        ktError = 1.0;
                        return
                    elseif rz < min(Rz)
                        errordlg(sprintf('The surface finish (Rz = %.3g) is less than the lowest curve available (Rz = %.3g)', rz, min(Rz)),...
                            'Quick Fatigue Tool')
                        uiwait
                        ktError = 1.0;
                        return
                    elseif rz > max(Rz)
                        errordlg(sprintf('The surface finish (Rz = %.3g) is greater than the highest curve available (Rz = %.3g)', rz, max(Rz)),...
                            'Quick Fatigue Tool')
                        uiwait
                        ktError = 1.0;
                        return
                    end
                    
                    ktCurve = rz;
                    
                    x = ktData(2.0:end, 1.0);
                    
                    if isempty(find(Rz == ktCurve, 1.0)) == 0.0
                        % The user Rz value is an exact match so there
                        % is no need to interpolate
                        
                        y = ktData(2.0:end, find(Rz == ktCurve, 1.0));
                        
                        % If the UTS exceeds the range of UTS values, take
                        % the last Kt value
                        if uts > x(end)
                            setappdata(0, 'kt', y(end))
                        else
                            setappdata(0, 'kt', interp1(x, y, uts))
                        end
                    else
                        % Interpolate to find the Kt data corresponding
                        % to the user Rz value
                        for i = 1:length(Rz) - 1.0
                            if ktCurve > Rz(i) && ktCurve < Rz(i + 1.0)
                                Rz_lo = Rz(i);
                                Rz_lo_i = i;
                                
                                Rz_hi = Rz(i + 1.0);
                                Rz_hi_i = i + 1.0;
                                break
                            end
                        end
                        
                        y = zeros(1, length(x));
                        KtGrid = ktData(2.0:end, 2.0:end);
                        
                        for i = 1:length(x)
                            if KtGrid(i, Rz_lo_i) > KtGrid(i, Rz_hi_i)
                                Kt2 = KtGrid(Rz_lo_i, i);
                                Kt1 = KtGrid(Rz_hi_i, i);
                            else
                                Kt2 = KtGrid(i, Rz_hi_i);
                                Kt1 = KtGrid(i, Rz_lo_i);
                            end
                            
                            y(i) = Kt2 - (((Kt2 - Kt1)/(Rz_hi - Rz_lo))*(ktCurve - Rz_lo));
                        end
                        
                        % If the UTS exceeds the range of UTS values, take
                        % the last Kt value
                        if uts > x(end)
                            setappdata(0, 'kt', y(end))
                        else
                            setappdata(0, 'kt', interp1(x, y, uts))
                        end
                    end
                end
            end
        end
        
        %% Check the conversion factor value
        function [conversionFactorError, factor] = checkConversionFactor(handles)
            conversionFactorError = 0.0;
            
            factor = str2double(get(handles.edit_conversionFactor, 'string'));
            
            if isnan(factor) == 1.0 || isinf(factor) == 1.0 || isreal(factor) == 0.0 || isempty(factor) == 1.0
                errordlg('An invalid conversion factor was specified.',...
                    'Quick Fatigue Tool')
                uiwait
                conversionFactorError = 1.0;
                return
            end
        end
        
        %% Read the user-defined mean stress correction file
        function [mscError] = getUserMSC(handles, msCorrection)
            mscError = 0.0;
            
            % Try to open the .msc file
            if isempty(msCorrection) == 1.0
                errordlg('No mean stress correction file was specified.',...
                    'Quick Fatigue Tool')
                uiwait
                mscError = 1.0;
                return
            else
                try
                    mscData = dlmread(msCorrection);
                catch
                    errordlg('The mean stresss correction file could not be read.',...
                        'Quick Fatigue Tool')
                    uiwait
                    mscError = 1.0;
                    return
                end
            end
            
            % Make sure the data only contains two columns
            [mscRows, mscColumns] = size(mscData);
            if mscColumns > 2.0
                mscData(:, end - (mscColumns - 3.0):end) = [];
            end
            
            % Make sure the Sm values are decreasing
            for i = 2:mscRows
                if mscData(i, 1.0) > mscData(i - 1.0, 1.0)
                    errordlg('The mean stress values must be decreasing down the column.',...
                        'Quick Fatigue Tool')
                    uiwait
                    mscError = 1.0;
                    return
                end
            end
            
            % Check the value of the UCS
            if get(handles.check_ucs, 'value') == 1.0
                ucs = str2double(get(handles.edit_ucs, 'string'));
                
                if isempty(get(handles.edit_ucs, 'string')) == 1.0
                    errordlg('No value for the ultimate compressive strength was specified.',...
                        'Quick Fatigue Tool')
                    uiwait
                    mscError = 1.0;
                    return
                elseif isnan(ucs) == 1.0 || isinf(ucs) == 1.0 || isreal(ucs) == 0.0 || ucs <= 0.0
                    errordlg('An invalid value of ultimate compressive strength was specified.',...
                        'Quick Fatigue Tool')
                    uiwait
                    mscError = 1.0;
                    return
                else
                    setappdata(0, 'ucs', ucs)
                end
            end
            
            % Save the user MSC data
            setappdata(0, 'userMSCData', mscData)
        end
        
        %% Check if the output directory exists
        function [error, path] = checkOutput(checkLocation, path)
            error = 0.0;
            
            c = clock;
            dateString = datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6)));
            
            if checkLocation == 0.0
                %{
                    Using the default results directory. Construct
                    the results directory using the current itme stamp
                %}
                for i = 1:length(dateString)
                    if (strcmpi(dateString(i), ':') == 1.0) || (strcmpi(dateString(i), ' ') == 1.0)
                        dateString(i) = '_';
                    end
                end
                
                path = [pwd, sprintf('/Project/output/gauge_fatigue_results_%s', dateString)];
                
                % If the output directory  does not exist, create it
                if exist(path, 'dir') == 0.0
                    mkdir(path)
                elseif exist(path, 'dir') == 7.0
                    %{
                        The current output path already exists, so append
                        an additional character to the path
                    %}
                    path = [path, '_1'];
                end
            else
                %{
                    Using a custom results directory. Check if the results
                    directory exists
                %}
                if isempty(path) == 1.0
                    error = 1.0;
                    return
                elseif exist(path, 'dir') == 0.0
                    try
                        mkdir(path)
                    catch
                        error = 2.0;
                        return
                    end
                end
            end
            
            % Save the file name and date
            setappdata(0, 'outputPath', path)
            setappdata(0, 'dateString', dateString)
        end
        
        %% Convert strain gauge components into principal strain
        function [e1, e2, e3, timeHistoryE1, timeHistoryE2, timeHistoryE3, error, errorMessage]...
                = gauge2principal(gaugeA, gaugeB, gaugeC, timeHistoryE1,...
                timeHistoryE2, timeHistoryE3)
            
            %% Initialize output
            e1 = -1.0;
            e2 = -1.0;
            e3 = -1.0;
            error = -1.0;
            errorMessage = -1.0;
            
            %% Get strain gauge orientation
            alpha = getappdata(0, 'multiaxialFatigue_alpha');
            beta = getappdata(0, 'multiaxialFatigue_beta');
            gamma = getappdata(0, 'multiaxialFatigue_gamma');
            
            if isempty(alpha) == 1.0
                alpha = 0.0;
            end
            if isempty(beta) == 1.0
                beta = 45.0;
            end
            if isempty(gamma) == 1.0
                gamma = 45.0;
            end
            
            %% Calculate principal strain componenets
            if alpha == 0.0 && beta == 45.0 && gamma == 45.0
                e1 = (0.5.*(gaugeA + gaugeC)) + ((1.0./sqrt(2.0)).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2));
                e2 = (0.5.*(gaugeA + gaugeC)) - ((1.0/sqrt(2.0)).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2));
            elseif alpha == 30.0 && beta == 60.0 && gamma == 60.0
                e1 = (1.0/3.0).*(gaugeA + gaugeB + gaugeC) + (sqrt(2.0)./3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
                e2 = (1.0/3.0)*(gaugeA + gaugeB + gaugeC) - (sqrt(2.0)/3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
            else
                syms Exx Eyy Exy
                
                % Make rosette angles relative to reference x-axis
                theta1 = alpha;
                theta2 = (alpha + beta);
                theta3 = beta + gamma;
                
                % Reference strain
                eqn1 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta1) + (0.5*Exy)*sind(2.0*theta1) == 0.0;
                eqn2 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta2) + (0.5*Exy)*sind(2.0*theta2) == 0.0;
                eqn3 = 0.5*(Exx + Eyy) + 0.5*(Exx - Eyy)*cosd(2.0*theta3) + (0.5*Exy)*sind(2.0*theta3) == 0.0;
                
                A = equationsToMatrix([eqn1, eqn2, eqn3], [Exx ,Eyy, Exy]);
                B = [gaugeA; gaugeB; gaugeC];
                
                X = linsolve(A, B);
                
                E11 = double(X(1.0, :));
                E22 = double(X(2.0, :));
                E12 = double(X(3.0, :));
                
                % Check validity of solution
                if (any(isinf(E11)) == 1.0 || any(isnan(E11)) == 1.0) || (any(isinf(E22)) == 1.0 || any(isnan(E22)) == 1.0) || (any(isinf(E12)) == 1.0 || any(isnan(E12)) == 1.0)
                    error = 1.0;
                    errorMessage = 'A solution could not be found for the specified strain gauge orientation.';
                    return
                end
                
                % Get the principal strains from the reference strains
                e1 = 0.5.*(E11 + E22) + sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
                e2 = 0.5.*(E11 + E22) - sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
            end
            
            % Get the out-of-plane strain
            if getappdata(0, 'multiaxialFatigue_outOfPlane') == 1.0
                v = getappdata(0, 'poisson');
                e3 = (-v/(1.0 - v)).*(e1 + e2);
            else
                e3 = zeros(1.0, length(e1));
            end
            
            %% Remove duplicate points
            index = 1.0;
            while 1.0
                if index == length(e1)
                    break
                elseif e1(index) == e1(index + 1.0)
                    e1(index) = [];
                    timeHistoryE1(index) = [];
                else
                    index = index + 1.0;
                end
            end
            
            index = 1.0;
            while 1.0
                if index == length(e2)
                    break
                elseif e2(index) == e2(index + 1.0)
                    e2(index) = [];
                    timeHistoryE2(index) = [];
                else
                    index = index + 1.0;
                end
            end
            
            index = 1.0;
            while 1.0
                if index == length(e3)
                    break
                elseif e3(index) == e3(index + 1.0)
                    e3(index) = [];
                    timeHistoryE3(index) = [];
                else
                    index = index + 1.0;
                end
            end
            
            %% Apply peak-valley detection to E1
            if length(e1) > 2.0
                finished = 0.0;
                index = 2.0;
                while finished == 0.0
                    if length(e1) < 3.0 || index == length(e1)
                        finished = 1.0;
                    elseif e1(index) > e1(index - 1.0) && e1(index) < e1(index + 1.0) ||...
                            e1(index) < e1(index - 1.0) && e1(index) > e1(index + 1.0)
                        % Remove the point from the signal
                        e1(index) = [];
                        timeHistoryE1(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
            
            %% Apply peak-valley detection to E2
            if length(e2) > 2.0
                finished = 0.0;
                index = 2.0;
                while finished == 0.0
                    if length(e2) < 3.0 || index == length(e2)
                        finished = 1.0;
                    elseif e2(index) > e2(index - 1.0) && e2(index) < e2(index + 1.0) ||...
                            e2(index) < e2(index - 1.0) && e2(index) > e2(index + 1.0)
                        % Remove the point from the signal
                        e2(index) = [];
                        timeHistoryE2(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
            
            %% Apply peak-valley detection to E3
            if length(e3) > 2.0
                finished = 0.0;
                index = 2.0;
                while finished == 0.0
                    if length(e3) < 3.0 || index == length(e3)
                        finished = 1.0;
                    elseif e3(index) > e3(index - 1.0) && e3(index) < e3(index + 1.0) ||...
                            e3(index) < e3(index - 1.0) && e3(index) > e3(index + 1.0)
                        % Remove the point from the signal
                        e3(index) = [];
                        timeHistoryE3(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
        end
        
        %% Get principal stress history from principal strain history (NEW)
        function [sigma, trueStressCurveBuffer, trueStrainCurveBuffer] =...
                getPrincipalStress(epsilon, E, kp, np)
            
            %{
                If out-of-plane strains are being ignored, EPSILON will be
                0.0. In this case, skip the calculation
            %}
            if length(epsilon) == 1.0
                if epsilon == 0.0
                    sigma = 0.0;
                    trueStressCurveBuffer = 0.0;
                    trueStrainCurveBuffer = 0.0;
                    return
                end
            end
            
            %% Append the signal with zero if necessary
            removeZero = 0.0;
            if epsilon(1.0) ~= 0.0
                epsilon = [0.0, epsilon];
                removeZero = 1.0;
            end
            
            %% Initialize the precision
            precision = 1e3;
            %method = 'pchip';
            method = 'linear';
            
            % Get the signal length
            signalLength = length(epsilon);

            % Initialize the true stress values
            sigma = zeros(1.0, signalLength);
            
            %{
                Initialize the buffer to store the stress-strain curves for
                MATLAB figures
            %}
            trueStressCurveBuffer = cell(1.0, 1.0);
            trueStrainCurveBuffer = cell(1.0, 1.0);
            
            %% Calcualte the monotonic stage
            %{
                The first excursion is assumed to be monotonic, therefore
                it is calculated separately
            %}
            %{
                Get the range of stresses along the R-O curve. Since the
                true stress at the current strain is not yet known, the
                upper bound of the curve is estimated as the elastic
                stress. This is a safe guess since the elastic stress is
                larger than the true stress
            %}
            trueStressCurve = linspace(0.0, epsilon(2.0)*E, precision);
            
            %{
                The true strain curve is found by substituting the true
                stress curve into the monotonic R-O equation
            %}
            trueStrainCurve = real((trueStressCurve./E) + (trueStressCurve./kp).^(1.0/np));
            
            %{
                The true stress at the current strain is found by
                interpolating the R-O curve. Linear extrapolation should
                not be required since the stress datapoints should always
                contain the true stress value somewhere within it
            %}
            sigma(2.0) = interp1(trueStrainCurve, trueStressCurve, epsilon(2.0), method, 'extrap');
            
            %{
                Save the stress and strain curves into the buffer. Only the
                stress-strain points upto the stress solution (or current
                strain range) are required
            %}
            [~, limitPoint] = min(abs(trueStrainCurve - epsilon(2.0)));
            trueStressCurveBuffer{1.0} = trueStressCurve(1.0:limitPoint);
            trueStrainCurveBuffer{1.0} = trueStrainCurve(1.0:limitPoint);
            
            %% Calculate the cyclic stage
            %{
                The remainder of stress-strain data points are assumed to
                be cyclically stable i.e. the cyclic version of the R-O
                equation can be used to determine every other stress point
                in the strain history
            %}
            
            currentStrainRange = abs(epsilon(2.0));
            
            strainRangeBuffer = currentStrainRange;
            
            allowClosure = 1.0;
            
            matMemFirstExcursion = 1.0;
            matMemFirstExcursionIndex = 2.0;
            ratchetStrain = 0.0;
            
            for i = 3:signalLength
                
                %{
                    Calculate the current strain range. If the signal did
                    not reverse direction, the current strain range must
                    take into account the entire excursion, not just the
                    current strain increment
                %}
                previousStrainRange = currentStrainRange;
                currentStrainRange = abs(epsilon(i) - epsilon(i - 1.0));
                strainRangeBuffer(i - 1.0) = currentStrainRange;
                
                % Record the direction of the current excursion
                if epsilon(i) - epsilon(i - 1.0) > 0.0
                    % The current excursion is moving forward
                    currentDirection = 1.0;
                else
                    % The current excursion is moving backwards
                    currentDirection = -1.0;
                end
                
                %{
                    The current strain range is smaller than the first
                    cyclic excusrion since the previous cycle closure.
                    Successive cycle closures cannot assume the path of the
                    monotonic excursion
                %}
                if currentStrainRange < strainRangeBuffer(matMemFirstExcursionIndex)
                    matMemFirstExcursion = 0.0;
                end
                
                %{
                    It is now possible for hysteresis loops to be closed.
                    If the current strain range exceeds the previous strain
                    range, a loop has bee closed
                    
                    When a loop is closed, the material memory effect
                    becomes observable, so the next stress data point must
                    be calculated from the curve defining the stress value
                    two indexes previously
                
                    The cycle is only closed if the current (larger) strain
                    range is in the opposite direction to the previous
                    strain range
                %}
                if (currentStrainRange > previousStrainRange) && (i > 3.0) && (allowClosure == 1.0)
                    %%
                    %{
                        A cycle has been closed
                    
                        The current strain range exceeds the previous
                        strain range, therefore material memory must be
                        accounted for
                    
                        The first cycle closure can only occur at the
                        earliest on the third reversal. Therefore, do not
                        allow cycle closures before i > 3.0
                    %}
                    
                    %{
                        Since the cycle closure includes the effect of
                        material memory, the next reversal may not close a
                        cycle
                    %}
                    allowClosure = 0.0;
                    
                    %{
                        The stable loop strain range is taken to be the
                        strain rang eof the previously closed cycle
                    %}
                    matMemFirstExcursionIndex = i;
                    
                    %{
                        Calculate the portion of the strain range which
                        accounts only for the distance beyond the cycle
                        closure point
                    %}
                    strainRangeBeyondClosure = currentStrainRange - previousStrainRange;
                    
                    %{
                        The stress is calculated from the curve two
                        excursions ago. The current strain range is the
                        strain range from this excursion, plus the
                        additional strain range beyond the current cycle
                        closure point
                    %}
                    if matMemFirstExcursion == 1.0
                        strainRange = strainRangeBuffer(1.0) + strainRangeBeyondClosure + ratchetStrain;
                    else
                        strainRange = strainRangeBuffer(i - 3.0) + strainRangeBeyondClosure;
                    end
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -strainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, strainRange*E, precision);
                    end
                    
                    % Calculate the stress-strain curve
                    %{
                        If the excursion used for the material memory is
                        the first excursion in the loading, the monotonic
                        stress-strain curve must be used instead
                    %}
                    if matMemFirstExcursion == 1.0
                        previousRatchetStrain = ratchetStrain;
                        ratchetStrain = ratchetStrain + strainRangeBeyondClosure;
                        
                        trueStrainCurve = real((abs(trueStressCurve)./E) + (abs(trueStressCurve)./kp).^(1.0/np));
                    else
                        trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    end
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, strainRange, method, 'extrap');
                    
                    if matMemFirstExcursion == 1.0
                        sigma(i) = sigma(1.0) + stressRange;
                    else
                        sigma(i) = sigma(i - 3.0) + stressRange;
                    end
                    
                    %%
                    %{
                        In order to plot the curves later on, it is
                        necessary to save the portion of the curve up to
                        cycle closure and the extension region where
                        material memory takes effect, then concatenate
                        these two curves together
                    %}
                    
                    strainRange_A = currentStrainRange - strainRangeBeyondClosure;
                    strainRange_B = strainRange;
                    
                    trueStressCurve_A = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStressCurve_B = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    
                    % Get the stress-strain curve up to the point of cycle closure
                    trueStrainCurve_A = real((trueStressCurve_A./E) + 2.0.*(trueStressCurve_A./(2.0*kp)).^(1.0/np));
                    
                    [~, limitPoint_A] = min(abs(abs(trueStrainCurve_A) - strainRange_A));
                    
                    trueStrainCurve_A = trueStrainCurve_A(1.0:limitPoint_A);
                    trueStressCurve_A = trueStressCurve_A(1.0:limitPoint_A);
                    
                    % Get the stress-strsin curve beyond the point of cycle closure
                    if matMemFirstExcursion == 1.0
                        trueStrainCurve_B = real((trueStressCurve_B./E) + (trueStressCurve_B./kp).^(1.0/np));
                        [~, limitPoint_A] = min(abs(abs(trueStrainCurve_B) - (strainRangeBuffer(1.0) + previousRatchetStrain)));
                    else
                        trueStrainCurve_B = real((trueStressCurve_B./E) + 2.0.*(trueStressCurve_B./(2.0*kp)).^(1.0/np));
                        [~, limitPoint_A] = min(abs(abs(trueStrainCurve_B) - strainRangeBuffer(i - 3.0)));
                    end
                    
                    [~, limitPoint_B] = min(abs(abs(trueStrainCurve_B) - strainRange_B));
                    
                    trueStressCurve_B = trueStressCurve_B(limitPoint_A : limitPoint_B);
                    trueStrainCurve_B = trueStrainCurve_B(limitPoint_A : limitPoint_B);
                    
                    stressDifference = abs(trueStressCurve_B(1.0) - trueStressCurve_A(end));
                    strainDifference = abs(trueStrainCurve_B(1.0) - trueStrainCurve_A(end));
                    if trueStressCurve_B(1.0) > trueStressCurve_A(end)
                        trueStressCurve_B = trueStressCurve_B - stressDifference;
                    else
                        trueStressCurve_B = trueStressCurve_B + stressDifference;
                    end
                    
                    if trueStrainCurve_B(1.0) > trueStrainCurve_A(end)
                        trueStrainCurve_B = trueStrainCurve_B - strainDifference;
                    else
                        trueStrainCurve_B = trueStrainCurve_B + strainDifference;
                    end
                    
                    trueStressCurveBuffer{i - 1.0} = [trueStressCurve_A, trueStressCurve_B];
                    trueStrainCurveBuffer{i - 1.0} = [trueStrainCurve_A, trueStrainCurve_B];
                elseif (currentStrainRange == previousStrainRange) && (i > 3.0) && (allowClosure == 1.0)
                    %%
                    %{
                        A cycle has been closed
                    
                        The current strain range equals the previous
                        strain range, therefore material memory does not
                        take effect
                    
                        The first cycle closure can only occur at the
                        earliest on the third reversal. Therefore, do not
                        allow cycle closures before i > 3.0
                    %}
                    
                    %{
                        Since the cycle closure does not include the effect
                        of material memory, the next reversal may close a
                        cycle
                    %}
                    allowClosure = 1.0;
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -currentStrainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
                    end
                    
                    % Calculate the stress-strain curve
                    trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
                    
                    sigma(i) = sigma(i - 1.0) + stressRange;
                    
                    %%
                    %{
                        Save the stress and strain curves into the buffer.
                        Only the stress-strain points upto the stress
                        solution (or current strain range) are required
                    %}
                    trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    [~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
                else
                    %%
                    %{
                        No cycle has been closed

                        The current stress curve starts at the previously
                        calculated true stress value, and ends at a
                        location defined by the elastic stress
                        corresponding to the current strain point
                    %}
                    
                    %{
                        Since this reversal did not result in cycle
                        closure, the next reversal may close a cycle
                    %}
                    allowClosure = 1.0;
                    
                    if currentDirection == -1.0
                        trueStressCurve = linspace(0.0, -currentStrainRange*E, precision);
                    else
                        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
                    end
                    
                    trueStrainCurve = real((abs(trueStressCurve)./E) + 2.0.*(abs(trueStressCurve)./(2.0*kp)).^(1.0/np));
                    
                    % Solve for the stress range
                    stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
                    
                    sigma(i) = sigma(i - 1.0) + stressRange;
                    
                    %{
                        Save the stress and strain curves into the buffer.
                        Only the stress-strain points upto the stress
                        solution (or current strain range) are required
                    %}
                    trueStressCurve = linspace(0.0, sigma(i) - sigma(i - 1.0), precision);
                    trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
                    [~, limitPoint] = min(abs(abs(trueStrainCurve) - currentStrainRange));
                    trueStressCurveBuffer{i - 1.0} = trueStressCurve(1.0:limitPoint);
                    trueStrainCurveBuffer{i - 1.0} = trueStrainCurve(1.0:limitPoint);
                end
            end
            
            if removeZero == 1.0
                sigma(1.0) = [];
            end
        end
        
        %% Get the time-correlated signal
        function [timeHistory1, timeHistory2, timeHistory3, data1, data2,...
                data3] = getCorrelatedSignal(timeHistory1, timeHistory2,...
                timeHistory3, data1, data2, data3)
            %{
                1)
            
                For signal 1, interpolate so that it contains all the time
                points from signals 2 and 3
            
                First, get the number of elements in signal 2 corresponding
                to the end time of signal 1. If the end time of signal 1
                exceeds that of signal 2, only parse signal 2 upto the end
                time of signal 2. If the end time of signal 2 exceeds
                that of signal 1, parse all the way to the point in signal
                45 correspoding to the end time of signal 1
            
                Repeat this process for signal 1 and signal 3 as well
            %}
            if timeHistory1(end) < timeHistory2(end)
                [~, L] = min(timeHistory2 - timeHistory1(end));
                if timeHistory2(L) > timeHistory1(end)
                    L = L - 1.0;
                end
            else
                L = length(timeHistory2);
            end
            
            for i = 1:L
                if isempty(find(timeHistory1 == timeHistory2(i), 1.0)) == 1.0
                    %{
                        The current time point in signal 2 does not exist
                        in singal 1. Insert the time point into the time
                        history for signal 1 and interpolate signal 1 to
                        include data for that time point
                    %}

                    % Insert the new data point
                    [~, P] = min(abs(timeHistory1 - timeHistory2(i)));
                    if timeHistory1(P) > timeHistory2(i)
                        P = P - 1.0;
                    end
                    x = interp1(timeHistory1(P:P + 1.0), data1(P:P + 1.0), timeHistory2(i), 'linear', 'extrap');
                    data1 = [data1(1.0:P), x, data1(P + 1.0:end)];
                    
                    % Insert the new time point
                    timeHistory1 = [timeHistory1(1.0:P), timeHistory2(i), timeHistory1(P + 1.0:end)];
                end
            end
            
            if timeHistory1(end) < timeHistory3(end)
                [~, L] = min(timeHistory3 - timeHistory1(end));
                if timeHistory3(L) > timeHistory1(end)
                    L = L - 1.0;
                end
            else
                L = length(timeHistory3);
            end
            
            for i = 1:L
                if isempty(find(timeHistory1 == timeHistory3(i), 1.0)) == 1.0
                    %{
                        The current time point in signal 3 does not exist
                        in singal 1. Insert the time point into the time
                        history for signal 1 and interpolate signal 1 to
                        include data for that time point
                    %}

                    % Insert the new data point
                    [~, P] = min(abs(timeHistory1 - timeHistory3(i)));
                    if timeHistory1(P) > timeHistory3(i)
                        P = P - 1.0;
                    end
                    x = interp1(timeHistory1(P:P + 1.0), data1(P:P + 1.0), timeHistory3(i), 'linear', 'extrap');
                    data1 = [data1(1.0:P), x, data1(P + 1.0:end)];
                    
                    % Insert the new time point
                    timeHistory1 = [timeHistory1(1.0:P), timeHistory3(i), timeHistory1(P + 1.0:end)];
                end
            end
            
            %{
                2)
            
                Signal 1 now contains data at all the time points from
                signals 2 and 3 upto the end point of signal 1. Signal 1
                may now contain data at time points from signal 3 that do
                not exist in signal 2, and data at time points from signal
                2 that do not exist in signal 3. Back-interpolate signal
                1 onto signals 2 and 3 so that all three signals contain
                data at all the time points upto their respective end
                times
            %}
            
            if timeHistory2(end) < timeHistory1(end)
                [~, L] = min(timeHistory1 - timeHistory2(end));
                if timeHistory1(L) > timeHistory2(end)
                    L = L - 1.0;
                end
            else
                L = length(timeHistory1);
            end
            
            for i = 1:L
                if isempty(find(timeHistory2 == timeHistory1(i), 1.0)) == 1.0
                    %{
                        The current time point in signal 1 does not exist
                        in singal 2. Insert the time point into the time
                        history for signal 2 and interpolate signal 2 to
                        include data for that time point
                    %}
                    
                    % Insert the new data point
                    [~, P] = min(abs(timeHistory2 - timeHistory1(i)));
                    if timeHistory2(P) > timeHistory1(i)
                        P = P - 1.0;
                    end
                    x = interp1(timeHistory2(P:P + 1.0), data2(P:P + 1.0), timeHistory1(i), 'linear', 'extrap');
                    data2 = [data2(1.0:P), x, data2(P + 1.0:end)];
                    
                    % Insert the new time point
                    timeHistory2 = [timeHistory2(1.0:P), timeHistory1(i), timeHistory2(P + 1.0:end)];
                end
            end
            
            if timeHistory3(end) < timeHistory1(end)
                [~, L] = min(timeHistory1 - timeHistory3(end));
                if timeHistory1(L) > timeHistory3(end)
                    L = L - 1.0;
                end
            else
                L = length(timeHistory1);
            end
            
            for i = 1:L
                if isempty(find(timeHistory3 == timeHistory1(i), 1.0)) == 1.0
                    %{
                        The current time point in signal 1 does not exist
                        in singal 2. Insert the time point into the time
                        history for signal 2 and interpolate signal 2 to
                        include data for that time point
                    %}
                    
                    % Insert the new data point
                    [~, P] = min(abs(timeHistory3 - timeHistory1(i)));
                    if timeHistory3(P) > timeHistory1(i)
                        P = P - 1.0;
                    end
                    x = interp1(timeHistory3(P:P + 1.0), data3(P:P + 1.0), timeHistory1(i), 'linear', 'extrap');
                    data3 = [data3(1.0:P), x, data3(P + 1.0:end)];
                    
                    % Insert the new time point
                    timeHistory3 = [timeHistory3(1.0:P), timeHistory1(i), timeHistory3(P + 1.0:end)];
                end
            end
            
            %{
                3)
            
                All three signals now contain tome points from all the
                other signals. However, each signal may still have a
                different end time, and they will not necessarily have the
                same number of samples. Extend the time histories of each
                signal and add zeros to the gauge data where necessary to
                ensure that all three signals have the same end times and
                the same number of sample points
            
                If the end time for all three signals is the same, the
                number of samples in each signal will now be the same as
                well, and further modification is not necessary
            %}
            
            if (length(timeHistory1) ~= length(timeHistory2)) || (length(timeHistory1) ~= length(timeHistory3))
                %{
                    The signals do not all have the same number of sample
                    points. This means that they have different end times.
                    Append zeros to the signals where appropriate
                %}
                
                %{
                    Get the number of samples corresponding to the signal
                    with the most sample points, and the maximum time value
                %}
                Li = [length(timeHistory1), length(timeHistory2), length(timeHistory3)];
                L = max(Li);
                T = max([timeHistory1(end), timeHistory2(end), timeHistory3(end)]);
                
                if length(timeHistory1) ~= L
                    %{
                        Signal 1 does not contain the maximum number of
                        sample points over all three signals. Therefore,
                        its end time is less than the largest end time over
                        all three signals
                    
                        Create time points starting from the end time of
                        signal 1 and ending at the maximum end time
                    %}
                    extraTimePoints = linspace(timeHistory1(end), T, 1.0 + L - Li(1.0));
                    extraTimePoints(1.0) = [];
                    
                    timeHistory1 = [timeHistory1, extraTimePoints];
                    data1 = [data1, zeros(1.0, L - Li(1.0))];
                end
                
                if length(timeHistory2) ~= L
                    %{
                        Signal 2 does not contain the maximum number of
                        sample points over all three signals. Therefore,
                        its end time is less than the largest end time over
                        all three signals
                    
                        Create time points starting from the end time of
                        signal 2 and ending at the maximum end time
                    %}
                    extraTimePoints = linspace(timeHistory2(end), T, 1.0 +  L - Li(2.0));
                    extraTimePoints(1.0) = [];
                    
                    timeHistory2 = [timeHistory2, extraTimePoints];
                    data2 = [data2, zeros(1.0, L - Li(2.0))];
                end
                
                if length(timeHistory3) ~= L
                    %{
                        Signal 3 does not contain the maximum number of
                        sample points over all three signals. Therefore,
                        its end time is less than the largest end time over
                        all three signals
                    
                        Create time points starting from the end time of
                        signal 3 and ending at the maximum end time
                    %}
                    extraTimePoints = linspace(timeHistory3(end), T, 1.0 + L - Li(3.0));
                    extraTimePoints(1.0) = [];
                    
                    timeHistory3 = [timeHistory3, extraTimePoints];
                    data3 = [data3, zeros(1.0, L - Li(3.0))];
                end
            end
        end
        
        %% Get the fatigue limit stress
        function [] = getFatigueLimit(algorithm)
            %% Calculate the endurance limit
            
            % Recall the material properties
            cael = getappdata(0, 'cael');
            Sf = getappdata(0, 'Sf');
            b = getappdata(0, 'b');
            E = getappdata(0, 'E');
            Ef = getappdata(0, 'Ef');
            c = getappdata(0, 'c');

            if algorithm == 2.0 %SBBM
                conditionalStrain = ((1.65*Sf)/(E))*(cael)^b + (1.75*Ef)*(cael)^c;
            else % PS
                conditionalStrain = (Sf/E)*(cael)^b + Ef*(cael)^c;
            end
            
            setappdata(0, 'fatigueLimit_strain', conditionalStrain)
            setappdata(0, 'fatigueLimit_stress', conditionalStrain*E)
        end
    end
end
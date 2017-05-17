classdef virtualGaugeUtils < handle
%VIRTUALGAUGEUTILS    QFT class for Virtual Strain Gauge.
%   This class contains methods for the Virtual Strain Gauge application.
%   
%   VIRTUALGAUGEUTILS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also RosetteDiagram, virtualGauge.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.4 Virtual Strain Gauge
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods (Static = true)
        
        %% Blank the GUI
        function [] = blank(handles)
            set(handles.edit_tensor, 'enable', 'off')
            set(handles.pButton_browseInput, 'enable', 'off')
            set(handles.text_readFrom, 'enable', 'off')
            set(handles.rButton_rows, 'enable', 'off')
            set(handles.rButton_cols, 'enable', 'off')
            
            set(handles.radiobutton_45, 'enable', 'off')
            set(handles.radiobutton_60, 'enable', 'off')
            set(handles.radiobutton_arbitrary, 'enable', 'off')
            set(handles.pButton_showDiagram, 'enable', 'off')
            
            set(handles.check_alpha, 'enable', 'off')
            set(handles.text_beta, 'enable', 'off')
            set(handles.text_gamma, 'enable', 'off')
            set(handles.edit_alpha, 'enable', 'off')
            set(handles.edit_beta, 'enable', 'off')
            set(handles.edit_gamma, 'enable', 'off')
            set(handles.text_alphaUnits, 'enable', 'off')
            set(handles.text_betaUnits, 'enable', 'off')
            set(handles.text_gammaUnits, 'enable', 'off')
            
            set(handles.check_resultsLocation, 'enable', 'off')
            set(handles.edit_output, 'enable', 'off')
            set(handles.pButton_browseOutput, 'enable', 'off')
            
            set(handles.pButton_start, 'enable', 'off')
            set(handles.pButton_close, 'enable', 'off')
        end
        
        %% Re-enable the GUI
        function [] = enable(handles)
            set(handles.edit_tensor, 'enable', 'on')
            set(handles.pButton_browseInput, 'enable', 'on')
            set(handles.text_readFrom, 'enable', 'on')
            set(handles.rButton_rows, 'enable', 'on')
            set(handles.rButton_cols, 'enable', 'on')
            
            set(handles.radiobutton_45, 'enable', 'on')
            set(handles.radiobutton_60, 'enable', 'on')
            set(handles.radiobutton_arbitrary, 'enable', 'on')
            set(handles.pButton_showDiagram, 'enable', 'on')
            
            if get(handles.radiobutton_arbitrary, 'value') == 1.0
                set(handles.check_alpha, 'enable', 'on')
                set(handles.text_beta, 'enable', 'on')
                set(handles.text_gamma, 'enable', 'on')
                set(handles.text_betaUnits, 'enable', 'on')
                set(handles.text_gammaUnits, 'enable', 'on')
                
                if get(handles.check_alpha, 'value') == 1.0
                    set(handles.text_alphaUnits, 'enable', 'on')
                    set(handles.edit_alpha, 'enable', 'on', 'backgroundColor', 'white')
                else
                    set(handles.edit_alpha, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255])
                end
                
                set(handles.edit_beta, 'enable', 'on')
                set(handles.edit_gamma, 'enable', 'on')
            end
            
            set(handles.check_resultsLocation, 'enable', 'on')
            if get(handles.check_resultsLocation, 'value') == 1.0
                set(handles.edit_output, 'enable', 'on')
                set(handles.pButton_browseOutput, 'enable', 'on')
            else
                set(handles.edit_output, 'enable', 'inactive')
            end
            
            set(handles.pButton_start, 'enable', 'on')
            set(handles.pButton_close, 'enable', 'on')
        end

        %% Verify Inputs
        function [alpha, beta, gamma, outputLocation, E11, E22, E12, error, errorMessage] = verifyInput(handles)
            % Initialize output
            alpha = -1.0;
            beta = -1.0;
            gamma = -1.0;
            outputLocation = -1.0;
            E11 = -1.0;
            E22 = -1.0;
            E12 = -1.0;
            error = 0.0;
            errorMessage = -1.0;
            
            % Verify the strain tensor definition
            strainTensorDefinition = get(handles.edit_tensor, 'string');
            
            if isempty(strainTensorDefinition) == 1.0
                error = 1.0;
                errorMessage = 'Please select a strain tensor file.';
                return
            elseif exist(strainTensorDefinition, 'file') ~= 2.0
                flag = exist(strainTensorDefinition, 'file');
                
                switch flag
                    case 0.0
                        errorMessage = 'The strain tensor definition file could not be found.';
                    case 7.0
                        errorMessage = 'The strain tensor definition appears to be a directory.';
                    otherwise
                        errorMessage = 'The strain tensor definition is invalid.';
                end
                
                error = 1.0;
                return
            end
            
            % Check the gauge orientation defintition
            if get(handles.radiobutton_arbitrary, 'value') == 1.0
                if get(handles.check_alpha, 'value') == 1.0
                    alpha = str2double(get(handles.edit_alpha, 'string'));
                    
                    if isempty(get(handles.edit_alpha, 'string')) == 1.0
                        error = 1.0;
                        errorMessage = 'Please specify a value of Alpha.';
                    elseif (isnumeric(alpha) == 0.0) || (isinf(alpha) == 1.0) || (isnan(alpha) == 1.0)
                        error = 1.0;
                        errorMessage = 'An invalid Alpha value was specified.';
                    elseif (alpha < 0.0) || (alpha >= 180.0)
                        error = 1.0;
                        errorMessage = 'Alpha must be in the range (0 <= Alpha < 180).';
                    end
                else
                    alpha = 0.0;
                end
                
                if error == 1.0
                    return
                end
                
                beta = str2double(get(handles.edit_beta, 'string'));
                
                if isempty(get(handles.edit_beta, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of Beta.';
                elseif (isnumeric(beta) == 0.0) || (isinf(beta) == 1.0) || (isnan(beta) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Beta value was specified.';
                elseif (beta <= 0.0) || (beta >= 180.0)
                    error = 1.0;
                    errorMessage = 'Beta must be in the range (0 < Beta < 180).';
                end
                
                if error == 1.0
                    return
                end
                
                gamma = str2double(get(handles.edit_gamma, 'string'));
                
                if isempty(get(handles.edit_gamma, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of Gamma.';
                elseif (isnumeric(gamma) == 0.0) || (isinf(gamma) == 1.0) || (isnan(gamma) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Gamma value was specified.';
                elseif (gamma <= 0.0) || (gamma >= 180.0)
                    error = 1.0;
                    errorMessage = 'Gamma must be in the range (0 < Gamma < 180).';
                end
                
                if (alpha + beta + gamma) > 360.0
                    error = 1.0;
                    errorMessage = 'The total angle (Alpha + Beta + Gamma) must not exceed 360 degrees.';
                end
                
                if error == 1.0
                    return
                end
            elseif get(handles.radiobutton_45, 'value') == 1.0
                alpha = 0.0;
                beta = 45.0;
                gamma = 45.0;
            else
                alpha = 30.0;
                beta = 60.0;
                gamma = 60.0;
            end
            
            % Verify the output definition
            if get(handles.check_resultsLocation, 'value') == 1.0
                outputLocation = get(handles.edit_output, 'string');
                
                if isempty(outputLocation) == 1.0
                    error = 1.0;
                    errorMessage = 'Please select an output directory for gauge results.';
                    return
                elseif exist(outputLocation, 'dir') ~= 7.0
                    error = 1.0;
                    flag = exist(outputLocation, 'dir');
                    
                    switch flag
                        case 0.0
                            if exist(outputLocation, 'file') == 2.0
                                errorMessage = 'The output directory appears to be a file.';
                            else
                                errorMessage = 'The output directory could not be found.';
                            end
                        otherwise
                            errorMessage = 'The specified output directory is invalid.';
                    end
                    
                    return
                end
            else
                outputLocation = [pwd, '\Data\gauge'];
                
                if exist(outputLocation, 'dir') ~= 7.0
                    mkdir(outputLocation)
                end
            end
            
            c = clock;
            dateString = datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6)));
            for i = 1:length(dateString)
                if (strcmpi(dateString(i), ':') == 1.0) || (strcmpi(dateString(i), ' ') == 1.0)
                    dateString(i) = '_';
                end
            end
            
            outputLocation = [outputLocation, ['\virtual_gauge_results_', dateString]];
            
            % Verify the strain tensor data
            try
                strainData = dlmread(strainTensorDefinition);
                [r, c] = size(strainData);
            catch exceptionMessage
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.\r\n\r\n%s', strainTensorDefinition, exceptionMessage.message);
                return
            end
            
            if any(any(isinf(strainData))) == 1.0 || any(any(isnan(strainData))) == 1.0 || any(any(isreal(strainData))) == 0.0
                error = 1.0;
                errorMessage = 'Some of the strain data has inf, NaN or complex values.';
                return
            end
            
            rowOrCol = get(handles.rButton_rows, 'value');
            
            if rowOrCol == 1.0
                if r ~= 3.0
                    error = 1.0;
                    errorMessage = 'The strain data has invalid dimensions. There must be three rows each corresponding to E11, E22 and E12, respectively.';
                    return
                else
                    E11 = strainData(1.0, :);
                    E22 = strainData(2.0, :);
                    E12 = strainData(3.0, :);
                end
            else
                if c ~= 3.0
                    error = 1.0;
                    errorMessage = 'The strain data has invalid dimensions. There must be three columns each corresponding to E11, E22 and E12, respectively.';
                    return
                else
                    E11 = strainData(:, 1.0);
                    E22 = strainData(:, 2.0);
                    E12 = strainData(:, 3.0);
                end
            end
        end
        
        %% Create gauge data
        function [gaugeA, gaugeB, gaugeC] = synthesizeGauges(E11, E22, E12, alpha, beta, gamma)
            gaugeA = 0.5*(E11 + E22) + 0.5*(E11 - E22)*cosd(2.0*alpha) + E12*sind(2.0*alpha);
            gaugeB = 0.5*(E11 + E22) + 0.5*(E11 - E22)*cosd(2.0*(alpha + beta)) + E12*sind(2.0*(alpha + beta));
            gaugeC = 0.5*(E11 + E22) + 0.5*(E11 - E22)*cosd(2.0*(alpha + beta + gamma)) + E12*sind(2.0*(alpha + beta + gamma));
        end
        
        %% Write gauge data to file
        function [error, errorMessage] = writeGaugeData(gaugeA, gaugeB, gaugeC, outputLocation)
            error = 0.0;
            errorMessage = -1.0;
            
            % If the output directory does not exist, create it
            if exist(outputLocation, 'dir') ~= 7.0
                try
                    mkdir(outputLocation)
                catch exceptionMessage
                    error = 1.0;
                    errorMessage = sprintf('An exception occurred while creating the gauge results directory.\r\n\r\n%s', exceptionMessage.message);
                    return
                end
            end
            
            % Create the text file for Gauge A
            fidA = fopen([outputLocation, '\Gauge A.txt'], 'w+');
            fprintf(fidA, '%f ', gaugeA);
            fclose(fidA);
            
            % Create the text file for Gauge B
            fidB = fopen([outputLocation, '\Gauge B.txt'], 'w+');
            fprintf(fidB, '%f ', gaugeB);
            fclose(fidB);
            
            % Create the text file for Gauge C
            fidC = fopen([outputLocation, '\Gauge C.txt'], 'w+');
            fprintf(fidC, '%f ', gaugeC);
            fclose(fidC);
        end
    end
end
classdef rosetteTools < handle
%ROSETTETOOLS    QFT class for Rosette Analysis.
%   This class contains methods for the Rosette Analysis application.
%   
%   ROSETTETOOLS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also rosette.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.3 Rosette Analysis
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods (Static = true)
        %% Blank the GUI
        function [] = blank(handles)
            set(handles.text_gaugeA, 'enable', 'off')
            set(handles.text_gaugeB, 'enable', 'off')
            set(handles.text_gaugeC, 'enable', 'off')
            
            set(handles.edit_gaugeA, 'enable', 'off')
            set(handles.edit_gaugeB, 'enable', 'off')
            set(handles.edit_gaugeC, 'enable', 'off')
            
            set(handles.pButton_gaugeA, 'enable', 'off')
            set(handles.pButton_gaugeB, 'enable', 'off')
            set(handles.pButton_gaugeC, 'enable', 'off')
            
            set(handles.text_alpha, 'enable', 'off')
            set(handles.text_beta, 'enable', 'off')
            set(handles.text_gamma, 'enable', 'off')
            
            set(handles.edit_alpha, 'enable', 'off')
            set(handles.edit_beta, 'enable', 'off')
            set(handles.edit_gamma, 'enable', 'off')
            
            set(handles.text_alphaUnits, 'enable', 'off')
            set(handles.text_betaUnits, 'enable', 'off')
            set(handles.text_gammaUnits, 'enable', 'off')
            
            set(handles.text_gaugeDiagram, 'enable', 'off')
            set(handles.pButton_showDiagram, 'enable', 'off')
            
            set(handles.text_outputType, 'enable', 'off')
            
            set(handles.text_E, 'enable', 'off')
            set(handles.edit_E, 'enable', 'off')
            set(handles.text_eUnits, 'enable', 'off')
            set(handles.text_poisson, 'enable', 'off')
            set(handles.edit_poisson, 'enable', 'off')
            
            set(handles.check_outputLocation, 'enable', 'off')
            set(handles.edit_outputLocation, 'enable', 'off')
            set(handles.pButton_outputLocation, 'enable', 'off')
            set(handles.check_referenceStrain, 'enable', 'off')
            set(handles.check_referenceOrientation, 'enable', 'off')
            
            set(handles.pButton_start, 'enable', 'off')
            set(handles.pButton_cancel, 'enable', 'off')
        end
        
        %% Show the GUI
        function [] = show(handles)
            set(handles.text_gaugeA, 'enable', 'on')
            set(handles.text_gaugeB, 'enable', 'on')
            set(handles.text_gaugeC, 'enable', 'on')
            
            set(handles.edit_gaugeA, 'enable', 'on')
            set(handles.edit_gaugeB, 'enable', 'on')
            set(handles.edit_gaugeC, 'enable', 'on')
            
            set(handles.pButton_gaugeA, 'enable', 'on')
            set(handles.pButton_gaugeB, 'enable', 'on')
            set(handles.pButton_gaugeC, 'enable', 'on')
            
            set(handles.text_alpha, 'enable', 'on')
            set(handles.text_beta, 'enable', 'on')
            set(handles.text_gamma, 'enable', 'on')
            
            set(handles.edit_alpha, 'enable', 'on')
            set(handles.edit_beta, 'enable', 'on')
            set(handles.edit_gamma, 'enable', 'on')
            
            set(handles.text_alphaUnits, 'enable', 'on')
            set(handles.text_betaUnits, 'enable', 'on')
            set(handles.text_gammaUnits, 'enable', 'on')
            
            set(handles.text_gaugeDiagram, 'enable', 'on')
            set(handles.pButton_showDiagram, 'enable', 'on')
            
            set(handles.text_outputType, 'enable', 'on')
            if getappdata(0, 'rosette_pMenu_outputType') == 2.0
                set(handles.text_E, 'enable', 'on')
                set(handles.edit_E, 'enable', 'on')
                set(handles.text_eUnits, 'enable', 'on')
                set(handles.text_poisson, 'enable', 'on')
                set(handles.edit_poisson, 'enable', 'on')
            end
            
            set(handles.check_outputLocation, 'enable', 'on')
            if get(handles.check_outputLocation, 'value') == 1.0
                set(handles.edit_outputLocation, 'enable', 'on')
                set(handles.pButton_outputLocation, 'enable', 'on')
            else
               set(handles.edit_outputLocation, 'enable', 'inactive', 'backgroundColor', [177/255, 206/255, 237/255]) 
            end
            set(handles.check_referenceStrain, 'enable', 'on')
            set(handles.check_referenceOrientation, 'enable', 'on')
            
            set(handles.pButton_start, 'enable', 'on')
            set(handles.pButton_cancel, 'enable', 'on')
        end
        
        %% Verify inputs
        function [alpha, beta, gamma, E, v, outputLocation, gaugeA, gaugeB, gaugeC, error, errorMessage] = verifyInput(handles)
            % Initialize output
            alpha = -1.0;
            beta = -1.0;
            gamma = -1.0;
            E = -1.0;
            v = -1.0;
            outputLocation = -1.0;
            gaugeA = -1.0;
            gaugeB = -1.0;
            gaugeC = -1.0;
            error = 0.0;
            errorMessage = -1.0;
            
            % Verify the gauge definitions
            gaugeFileA = get(handles.edit_gaugeA, 'string');
            gaugeFileB = get(handles.edit_gaugeB, 'string');
            gaugeFileC = get(handles.edit_gaugeC, 'string');
            
            if isempty(gaugeFileA) == 1.0
                error = 1.0;
                errorMessage = 'All three gauge signals must be defined.';
                return
            elseif exist(gaugeFileA, 'file') ~= 2.0
                flag = exist(gaugeFileA, 'file');
                
                switch flag
                    case 0.0
                        errorMessage = 'The definition file for Gauge A could not be found.';
                    case 7.0
                        errorMessage = 'The definition for Gauge A appears to be a directory.';
                    otherwise
                        errorMessage = 'The definition of Gauge A is invalid.';
                end
                
                error = 1.0;
                return
            end
            
            if isempty(gaugeFileB) == 1.0
                error = 1.0;
                errorMessage = 'All three gauge signals must be defined.';
                return
            elseif exist(gaugeFileB, 'file') ~= 2.0
                flag = exist(gaugeFileB, 'file');
                
                switch flag
                    case 0.0
                        errorMessage = 'The definition file for Gauge B could not be found.';
                    case 7.0
                        errorMessage = 'The definition for Gauge B appears to be a directory.';
                    otherwise
                        errorMessage = 'The definition of Gauge B is invalid.';
                end
                
                error = 1.0;
                return
            end
            
            if isempty(gaugeFileC) == 1.0
                error = 1.0;
                errorMessage = 'All three gauge signals must be defined.';
                return
            elseif exist(gaugeFileC, 'file') ~= 2.0
                flag = exist(gaugeFileC, 'file');
                
                switch flag
                    case 0.0
                        errorMessage = 'The definition file for Gauge C could not be found.';
                    case 7.0
                        errorMessage = 'The definition for Gauge C appears to be a directory.';
                    otherwise
                        errorMessage = 'The definition of Gauge C is invalid.';
                end
                
                error = 1.0;
                return
            end
            
            % Check the gauge orientation defintition
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
            
            % Check the definition of E and v
            if getappdata(0, 'rosette_pMenu_outputType') == 2.0
                E = str2double(get(handles.edit_E, 'string'));
                
                if isempty(get(handles.edit_alpha, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of the Young''s Modulus.';
                elseif (isnumeric(E) == 0.0) || (isinf(E) == 1.0) || (isnan(E) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Young''s Modulus value was specified.';
                elseif E <= 0.0
                    error = 1.0;
                    errorMessage = 'The Young''s Modulus must be greater than zero.';
                end
                
                if error == 1.0
                    return
                end
                
                v = str2double(get(handles.edit_poisson, 'string'));
                
                if isempty(get(handles.edit_poisson, 'string')) == 1.0
                    error = 1.0;
                    errorMessage = 'Please specify a value of the Poisson''s ratio.';
                elseif (isnumeric(v) == 0.0) || (isinf(v) == 1.0) || (isnan(v) == 1.0)
                    error = 1.0;
                    errorMessage = 'An invalid Poisson''s ratio value was specified.';
                elseif v > 0.5
                    error = 1.0;
                    errorMessage = 'The Poisson''s ratio must not be greater than 0.5.';
                end
                
                if error == 1.0
                    return
                end
            end
            
            % Verify the output definition
            if get(handles.check_outputLocation, 'value') == 1.0
                outputLocation = get(handles.edit_outputLocation, 'string');
                
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
                outputLocation = [pwd, '\Project\output\rosette_analysis_results'];
            end
            
            % Verify the gauge data
            try
                gaugeA = dlmread(gaugeFileA);
                [r, c] = size(gaugeA);
                
                if r > c
                    gaugeA = gaugeA';
                end
            catch exceptionMessage
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.\r\n\r\n%s', gaugeFileA, exceptionMessage.message);
                return
            end
            
            if any(any(isinf(gaugeA))) == 1.0 || any(any(isnan(gaugeA))) == 1.0 || any(any(isreal(gaugeA))) == 0.0
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', gaugeFileA);
                return
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge A has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            try
                gaugeB = dlmread(gaugeFileB);
                [r, c] = size(gaugeB);
                
                if r > c
                    gaugeB = gaugeB';
                end
            catch exceptionMessage
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.\r\n\r\n%s', gaugeFileB, exceptionMessage.message);
                return
            end
            
            if any(any(isinf(gaugeB))) == 1.0 || any(any(isnan(gaugeB))) == 1.0 || any(any(isreal(gaugeB))) == 0.0
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', gaugeFileB);
                return
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge B has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            try
                gaugeC = dlmread(gaugeFileC);
                [r, c] = size(gaugeC);
                
                if r > c
                    gaugeC = gaugeC';
                end
            catch exceptionMessage
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. The file could not be read.\r\n\r\n%s', gaugeFileC, exceptionMessage.message);
                return
            end
            
            if any(any(isinf(gaugeC))) == 1.0 || any(any(isnan(gaugeC))) == 1.0 || any(any(isreal(gaugeC))) == 0.0
                error = 1.0;
                errorMessage = sprintf('Error while processing ''%s''. Some of the data has inf, NaN or complex values.', gaugeFileC);
                return
            end
            
            if r > 1.0 && c > 1.0
                error = 1.0;
                errorMessage = 'The data for Gauge C has invalid dimensions. Data must be 1xN or Nx1.';
                return
            end
            
            
            % Make sure the signals are the same length
            lengths = [length(gaugeA), length(gaugeB) length(gaugeC)];
            if length(unique(lengths)) ~= 1.0
                longest = max(lengths);
                
                if length(gaugeA) ~= longest
                    diff = longest - length(gaugeA);
                    gaugeA = [gaugeA, zeros(1.0, diff)];
                end
                
                if length(gaugeB) ~= longest
                    diff = longest - length(gaugeB);
                    gaugeB = [gaugeB, zeros(1.0, diff)];
                end
                
                if length(gaugeC) ~= longest
                    diff = longest - length(gaugeC);
                    gaugeC = [gaugeC, zeros(1.0, diff)];
                end
            end
        end
        
        %% Calcualte strain from gauge data
        function [E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, error, errorMessage] = processGauges(gaugeA, gaugeB, gaugeC, alpha, beta, gamma, E, v, referenceStrain, referenceOrientation)
            % Initialize output variables
            E1 = -1.0;
            E2 = -1.0;
            E12M = -1.0;
            
            E11 = -1.0;
            E22 = -1.0;
            E12 = -1.0;
            
            S1 = -1.0;
            S2 = -1.0;
            S12M = -1.0;
            
            S11 = -1.0;
            S22 = -1.0;
            S12 = -1.0;
            
            thetaP = -1.0;
            thetaS = -1.0;
            
            error = -1.0;
            errorMessage = -1.0;
            
            % Search for special cases
            if alpha == 0.0 && beta == 45.0 && gamma == 45.0 % Rectangular
                % Reference strains
                E11 = gaugeA;
                E22 = gaugeC;
                E12 = (2.0.*gaugeB) - gaugeA - gaugeC;
                
                % Principal strains
                E1 = (0.5.*(E11 + E22)) + ((1.0./sqrt(2.0)).*sqrt((E11 - gaugeB).^2 + (gaugeB - E22).^2));
                E2 = (0.5.*(E11 + E22)) - ((1.0/sqrt(2.0)).*sqrt((E11 - gaugeB).^2 + (gaugeB - E22).^2));
            elseif (alpha == 30.0 && beta == 60.0 && gamma == 60.0) && (referenceStrain == 0.0 && referenceOrientation == 0.0) % Delta
                % Principal strains
                E1 = (1.0/3.0).*(gaugeA + gaugeB + gaugeC) + (sqrt(2.0)./3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
                E2 = (1.0/3.0)*(gaugeA + gaugeB + gaugeC) - (sqrt(2.0)/3.0).*sqrt((gaugeA - gaugeB).^2 + (gaugeB - gaugeC).^2 + (gaugeC - gaugeA).^2);
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
                
                % Principal strains
                E1 = 0.5.*(E11 + E22) + sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
                E2 = 0.5.*(E11 + E22) - sqrt((0.5.*(E11 - E22)).^2 + (0.5.*E12).^2);
            end
            
            %% Get principal stresses if requested:
            if getappdata(0, 'rosette_pMenu_outputType') == 2.0
                S1 = (E./(1.0 - v^2)).*(E1 + v.*E2);
                S2 = (E./(1.0 - v^2)).*(E2 + v.*E1);
                
                % Maximum shear stress
                S12M = 0.5.*(S1 - S2);
                
                if referenceStrain == 1.0
                    % Calculate the reference stress as well
                    S11 = (E./(1.0 - v^2)).*(E11 + v.*E22);
                    S22 = (E./(1.0 - v^2)).*(E22 + v.*E11);
                    S12 = (E12*E)/(2.0*(1.0 + v));
                end
            end
            
            %% Get maximum shear stress and strain
            % Maximum shear strain
            E12M = 0.5.*(E1 - E2);
            
            if referenceOrientation == 1.0
                % Principal strain orientation
                thetaP = 0.5.*atand(E12./(E11 - E22));
                thetaP(isnan(thetaP)) = 0.0;
    
                % Maximum shear strain orientation
                thetaS = -0.5.*atand((E11 - E22)./E12);
                thetaS(isnan(thetaS)) = 0.0;
            end
        end
        
        %% Write results data to file
        function [error, errorMessage] = writeData(E1, E2, E12M, thetaP, thetaS, E11, E22, E12, S1, S2, S12M, S11, S22, S12, referenceStrain, referenceOrientation, outputLocation)
            error = 0.0;
            errorMessage = -1.0;
            
            c = clock;
            dateString = datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6)));
            for i = 1:length(dateString)
                if (strcmpi(dateString(i), ':') == 1.0) || (strcmpi(dateString(i), ' ') == 1.0)
                    dateString(i) = '_';
                end
            end
            
            % If the output directory does not exist, create it
            if exist(outputLocation, 'dir') ~= 7.0
                try
                    mkdir(outputLocation)
                catch exception
                    error = 1.0;
                    errorMessage = sprintf('An exception occurred while creating the gauge results directory.\r\n\r\n%s', exception.message);
                    return
                end
            end
            
            % Convert strain to microstrain
            E1 = E1*1e6;
            E2 = E2*1e6;
            E12M = E12M*1e6;
            E11 = E11*1e6;
            E22 = E22*1e6;
            E12 = E12*1e6;
            
            fid = fopen([outputLocation, '\', dateString, '.dat'], 'w+');
            
            % Check for valid FID
            if fid == -1.0
                error = 1.0;
                errorMessage = sprintf('Results cannot be written to the selected location.\r\n\r\n%s', outputLocation);
                return
            end
            
            if referenceStrain == 1.0
                if referenceOrientation == 1.0
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; thetaP; thetaS; E11; E22; E12]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPhi D (degrees)\tPhi S (degrees)\tE11R\tE22R\tE12R\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; E11; E22; E12; S1; S2; S12M; S11; S22; S12; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\tPS1\tPS2\tS12 Max\tS11R\tS22R\tS12R\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableB');
                    end
                else
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; E11; E22; E12]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; E11; E22; E12; S1; S2; S12M; S11; S22; S12]';
                        
                        fprintf(fid, 'Strain units: uE\tStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tE11R\tE22R\tE12R\tPS1\tPS2\tS12 Max\tS11R\tS22R\tS12R\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableB');
                    end
                end
            else
                if referenceOrientation == 1.0
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; S1; S2; S12M; thetaP; thetaS]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPS1\tPS2\tS12 Max\tPhi D (degrees)\tPhi S (degrees)\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableB');
                    end
                else
                    if getappdata(0, 'rosette_pMenu_outputType') == 1.0
                        tableA = [E1; E2; E12M]';
                        
                        fprintf(fid, 'Strain units: uE\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\r\n', tableA');
                    else
                        tableB = [E1; E2; E12M; S1; S2; S12M]';
                        
                        fprintf(fid, 'Strain units: uE\r\nStress units: MPa\r\n');
                        fprintf(fid, 'PE1\tPE2\tE12 Max\tPS1\tPS2\tS12 Max\r\n');
                        fprintf(fid, '%.4g\t%.4g\t%.4g\t%.4g\t%.4g\t%.4g\r\n', tableB');
                    end
                end
            end
            
            fclose(fid);
        end
    end
end
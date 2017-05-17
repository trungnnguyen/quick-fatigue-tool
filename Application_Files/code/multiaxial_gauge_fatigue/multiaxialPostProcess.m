classdef multiaxialPostProcess < handle
%MULTIAXIALPOSTPROCESS    QFT class for Multiaxial Gauge Fatigue.
%   This class contains methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   MULTIAXIALPOSTPROCESS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also multiaxialAnalysis, multiaxialPreProcess, gaugeOrientation,
%   materialOptions, MultiaxialFatigue.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.2 Multiaxial Gauge Fatigue
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods (Static = true)
        %% Write results to the output file
        function [] = outputLog(handles, phiC, thetaC, cyclesOnCP, life,...
                cael, analysisTime)
            outputPath = getappdata(0, 'outputPath');
            setappdata(0, 'multiaxialGaugeFatigue_unableOutput', 0.0)
            
            %% Open the file
            try
                fid = fopen([outputPath, '/results.log'], 'w+');
                if fid == -1.0
                    errordlg('Unable to write output to file. Make sure the results location has read/write access.', 'Quick Fatigue Tool')
                    uiwait
                    setappdata(0, 'multiaxialGaugeFatigue_unableOutput', 1.0)
                    return
                end
            catch
                [message, errorNumber] = ferror(fid);
                message = sprintf('%s\n\nError number: %f', message, errorNumber);
                errordlg(message, 'Quick Fatigue Tool')
            end
            
            %% Header
            % Write file header
            fprintf(fid, 'Quick Fatigue Tool 6.10-08 on machine %s (User is %s)\r\n', char(java.net.InetAddress.getLocalHost().getHostName()), char(java.lang.System.getProperty('user.name')));
            fprintf(fid, '(Copyright Louis Vallance 2017)\r\n');
            fprintf(fid, 'Last modified 08-Feb-2017 12:23:04 GMT\r\n\r\n');
            
            fprintf(fid, 'MULTIAXIAL GAUGE FATIGUE RESULTS (%s)\r\n\r\n', getappdata(0, 'dateString'));
            
            %% Gauge definition
            fprintf(fid, '<GAUGE DATA>\r\n');
            fprintf(fid, 'Gauge Signal A: %s\r\n', get(handles.edit_gauge_0, 'string'));
            fprintf(fid, 'Gauge Signal B: %s\r\n', get(handles.edit_gauge_45, 'string'));
            fprintf(fid, 'Gauge Signal C: %s\r\n\r\n', get(handles.edit_gauge_90, 'string'));
            
            fprintf(fid, '<GAUGE ORIENTATION>\r\n');
            fprintf(fid, 'Alpha: %.3f degrees\r\n', getappdata(0, 'multiaxialFatigue_alpha'));
            fprintf(fid, 'Beta: %.3f degrees\r\n', getappdata(0, 'multiaxialFatigue_beta'));
            fprintf(fid, 'Gamma: %.3f degrees\r\n\r\n', getappdata(0, 'multiaxialFatigue_gamma'));
            
            %% Material definition
            fprintf(fid, '<MATERIAL DATA>\r\n');
            fprintf(fid, 'Analysis material: %s\r\n', get(handles.edit_material, 'string'));
            
            if getappdata(0, 'multiaxialFatigue_ndCompression') == 1.0
                ndCompression = 'YES';
            else
                ndCompression = 'NO';
            end
            fprintf(fid, 'Ignore damage for fully-compressive cycles: %s\r\n', ndCompression);
            
            if getappdata(0, 'multiaxialFatigue_ndCompression') == 1.0
                outOfPlane = 'YES';
            else
                outOfPlane = 'NO';
            end
            fprintf(fid, 'Include out-of-plane strains: %s\r\n', outOfPlane);
            
            if getappdata(0, 'multiaxialFatigue_ndEndurance') == 1.0
                ndEndurance = 'YES';
            else
                ndEndurance = 'NO';
            end
            fprintf(fid, 'Ignore damage below endurance limit: %s\r\n', ndEndurance);
            
            if getappdata(0, 'multiaxialFatigue_ndEndurance') == 1.0
                fprintf(fid, 'Reduce endurance limit for damaging cycles: %s\r\n', 'YES');
                fprintf(fid, 'Endurance scale factor: %.3f\r\n', getappdata(0, 'multiaxialFatigue_enduranceScaleFactor'));
                fprintf(fid, 'Number of cycles to recover: %.3f cycles\r\n\r\n', getappdata(0, 'multiaxialFatigue_cyclesToRecover'));
            else
                fprintf(fid, 'Reduce endurance limit for damaging cycles: %s\r\n\r\n', 'NO');
            end
            
            %% Analysis definition
            fprintf(fid, '<ANALYSIS DEFINITION>\r\n');
            if get(handles.pMenu_units, 'value') == 1.0
                fprintf(fid, 'Strain units: Strain\r\n');
            else
                fprintf(fid, 'Strain units: Microstrain (uE)\r\n');
            end
            
            if get(handles.rButton_algorithm_ps, 'value') == 1.0
                fprintf(fid, 'Analysis algorithm: Normal Strain\r\n');
            else
                fprintf(fid, 'Analysis algorithm: Brown-Miller\r\n');
            end
            
            if get(handles.rButton_msc_none, 'value') == 1.0
                fprintf(fid, 'Mean stress correction: None\r\n');
            else
                fprintf(fid, 'Mean stress correction: Morrow\r\n');
            end
            
            if get(handles.check_kt_direct, 'value') == 1.0
                fprintf(fid, 'Surface finish definition: As Kt value (Kt = %.3g)\r\n\r\n',...
                    str2double(get(handles.edit_kt, 'string')));
            else
                if get(handles.rButton_kt_list, 'value') == 1.0
                    files = get(handles.pMenu_kt_list, 'string');
                    file = files{get(handles.pMenu_kt_list, 'value')};
                    
                    curves = get(handles.pMenu_surfaceFinish, 'string');
                    curve = curves{get(handles.pMenu_surfaceFinish, 'value')};
                    
                    fprintf(fid, 'Surface finish definition: Surface finish from list\r\n');
                    fprintf(fid, 'Definition file: ''%s''\r\n', file);
                    fprintf(fid, 'Surface finish: %s (Kt = %.3g)\r\n\r\n', curve, getappdata(0, 'kt'));
                else
                    files = get(handles.pMenu_kt_list, 'string');
                    file = files{get(handles.pMenu_kt_list, 'value')};
                    
                    Rz = str2double(get(handles.edit_rz, 'string'));
                    
                    fprintf(fid, 'Surface finish definition: Surface finish as a value (Rz = %.3g microns)\r\n', Rz);
                    fprintf(fid, 'Definition file: ''%s''\r\n', file);
                    fprintf(fid, 'Kt: %.3g\r\n\r\n', getappdata(0, 'kt'));
                end
            end
            
            %% Results
            fprintf(fid, '<RESULTS>\r\n');
            
            if getappdata(0, 'multiaxial_gauge_fatigue_warning_001') == 1.0
                fprintf(fid, '***WARNING: The mean stress in some parts of the loading could not be captured by the user-defined mean stress correction\r\n');
                fprintf(fid, '-> The allowable stress amplitude has been held constant for these cycles\r\n\r\n');
            end
                
            fprintf(fid, 'Critical Plane Angle: PHI = %.0f degrees, THETA = %.0f degrees\r\n\r\n', phiC, thetaC);
            fprintf(fid, 'Cycles                                    : %.0f\r\n\r\n', cyclesOnCP);
            if life > cael
                fprintf(fid, 'Life-Repeats                              : No Damage\r\n\r\n');
                fprintf('Life-Repeats                                : No Damage\n\n');
            elseif life <= 1.0
                fprintf(fid, 'Life-Repeats                              : No Life\r\n\r\n');
                fprintf('Life-Repeats                                : No Life\n\n');
            else
                fprintf(fid, 'Life-Repeats                              : %.0f\r\n\r\n', life);
                fprintf('Life-Repeats                                : %.0f\n\n', life);
            end
            
            hrs = floor(analysisTime/3600);
            mins = floor((analysisTime - (3600*hrs))/60);
            secs = analysisTime - (hrs*3600) - (mins*60);
            c = clock;
            
            fprintf(fid, 'Analysis time                             : %.0f:%.0f:%.3f\r\n\r\n', hrs, mins, secs);
            fprintf(fid, 'FATIGUE ANALYSIS COMPLETE (%s)\r\n\r\n', datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))));
            fprintf(fid, '========================================================================================');
            
            % Print summary to command window
            fprintf('Analysis time                               : %.0f:%.0f:%.3f\n\n', hrs, mins, secs)
            fprintf('Fatigue analysis complete (%s)\n\n',...
                datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))))
            
            fclose(fid);
        end
        
        %% Output MATLAB figures
        function [] = outputFigures(step, thetaC, signalLength, Exx, Eyy,...
                Ezz, S11, S22, S33, msCorrection, timeHistoryE1, timeHistoryE2, timeHistoryE3)
            %% Output MATLAB figures
            outOfPlane = getappdata(0, 'multiaxialFatigue_outOfPlane');
            
            midnightBlue = [25/255, 25/255, 112/255];
            outputPath = getappdata(0, 'outputPath');
            
            dir = [outputPath, '/MATLAB Figures'];
            if exist(dir, 'dir') == 0.0
                mkdir(dir)
            end
            
            damageParameter = getappdata(0, 'worstNodeDamageParamCube');
            damage = getappdata(0, 'worstNodeDamageCube');
            
            %% PE Principal strain
            f1 = figure('visible', 'off');
            if outOfPlane == 1.0
                subplot(3.0, 1.0, 1.0)
                plot(timeHistoryE1, Exx, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
                msg = sprintf('PE1, Maximum principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(3.0, 1.0, 2.0)
                plot(timeHistoryE2, Eyy, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE2, Middle principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(3.0, 1.0, 3.0)
                plot(timeHistoryE3, Ezz, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE3, Minimum principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
            else
                subplot(2.0, 1.0, 1.0)
                plot(timeHistoryE1, Exx, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
                msg = sprintf('PE1, Maximum in-plane principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(2.0, 1.0, 2.0)
                plot(timeHistoryE2, Eyy, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE2, Minimum in-plane principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
            end
            xlabel('Time', 'FontSize', 12.0)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            fileName = [dir, '/PE, Correlated Principal strains'];
            saveas(f1, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% PS Principal stress
            
            if msCorrection > 0.0
                f2 = figure('visible', 'off');
                
                if outOfPlane == 1.0
                    subplot(3.0, 1.0, 1.0)
                    plot(timeHistoryE1, S11, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS1, Maximum principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(3.0, 1.0, 2.0)
                    plot(timeHistoryE2, S22, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS2, Middle principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(3.0, 1.0, 3.0)
                    plot(timeHistoryE3, S33, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS3, Minimum principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                else
                    subplot(2.0, 1.0, 1.0)
                    plot(timeHistoryE1, S11, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS1, Maximum in-plane principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(2.0, 1.0, 2.0)
                    plot(timeHistoryE2, S22, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS2, Minimum in-plane principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                end
                xlabel('Time', 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                fileName = [dir, '/PS, Correlated Principal stresses'];
                saveas(f2, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
            end
            
            %% DPP-THETA (Damage parameter vs THETA)
            
            f3 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(damageParameter));
            
            plot(x, damageParameter, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, damageParameter((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('DPP-THETA, Damage parameter vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('Damage parameter [MPa]', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/DPP, Damage parameter vs angle'];
            saveas(f3, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% DP-THETA (Damage vs THETA)
            
            f4 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(damage));
            
            plot(x, damage, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, damage((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('DP-THETA, Damage vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel(sprintf('Damage [1/Nf]'), 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/DP, Damage vs angle'];
            saveas(f4, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% LP-THETA (Life vs THETA)
            
            lifeTheta = 1.0./damage;
            
            f5 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(lifeTheta));
            
            plot(x, lifeTheta, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, lifeTheta((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('LP-THETA, Life vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel(sprintf('Life Nf'), 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/LP, Life vs angle'];
            saveas(f5, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% SHEAR/NORMAL strain VS THETA
            
            %% SHEAR strain VS THETA
            f6 = figure('visible', 'off');
            
            shearStress = getappdata(0, 'shear_cp');
            
            x = linspace(0.0, 180.0, length(shearStress));
            
            subplot(2.0, 1.0, 1.0)
            plot(x, shearStress, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, shearStress((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('CPS-THETA, Maximum shear strain vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 14.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            %% NORMAL strain VS THETA
            normalStress = getappdata(0, 'normal_cp');
            
            x = linspace(0.0, 180.0, length(normalStress));
            
            subplot(2.0, 1.0, 2.0)
            plot(x, normalStress, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, normalStress((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('CPN-THETA, Normal strain vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/CPS, Critical plane strains vs angle'];
            saveas(f6, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% RHIST RAINFLOW HISTOGRAM OF CYCLES
            pairs = getappdata(0, 'cyclesOnCP');
            Sm = 0.5*(pairs(:, 1.0) + pairs(:, 2.0));
            amplitudes = getappdata(0, 'amplitudesOnCP');
            
            f7 = figure('visible', 'off');
            rhistData = [Sm'; 2.0.*amplitudes]';
            hist3(rhistData, [32.0, 32.0])
            
            set(gcf, 'renderer', 'opengl');
            set(get(gca, 'child'), 'FaceColor', 'interp', 'CDataMode', 'auto');
            colorbar
            
            msg = sprintf('RHIST, Rainflow cycle histogram');
            xlabel('Mean Strain', 'FontSize', 12.0)
            ylabel('Strain Range', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            fileName = [dir, '/RHIST, Rainflow cycle histogram'];
            saveas(f7, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% CN (Normal strain on critical plane)
            
            normalOnCP = getappdata(0, 'CN');
            msg = sprintf('CN, Maximum normal strain history on critical plane');
            
            f8 = figure('visible', 'off');
            subplot(2.0, 1.0, 1.0)
            plot(normalOnCP, '-', 'LineWidth', 1.0, 'Color', [178/255, 34/255, 34/255])
            
            ylabel('Strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 14.0)
            set(gca, 'XTick', linspace(1.0, signalLength, 4.0 + 1.0))
            set(gca, 'XTickLabel', round(linspace(1.0, signalLength, 4.0 + 1.0)));
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end

            grid on
            
            %% CS (Shear strain on critical plane)
            
            shearOnCP = getappdata(0, 'CS');
            msg = sprintf('CS, Maximum shear strain history on critical plane');
            
            subplot(2.0, 1.0, 2.0)
            plot(shearOnCP, '-', 'LineWidth', 1.0, 'Color', [34/255, 139/255, 34/255])
            
            xlabel('Sample', 'FontSize', 12.0);
            ylabel('Stress [MPa]', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTick', linspace(1.0, signalLength, 4.0 + 1.0))
            set(gca, 'XTickLabel', round(linspace(1.0, signalLength, 4.0 + 1.0)));
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/CN + CS, Normal and shear strain on critical plane'];
            saveas(f8, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])

            if msCorrection > 0.0
                %% CSS1 (Cyclic stress-strain for PS1)
                
                % Get the buffers containing the stress-strain curves
                trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_1');
                trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_1');
                
                % Get the monotonic stress-strain curve
                stressCurve = trueStressCurveBuffer{1.0};
                strainCurve = trueStrainCurveBuffer{1.0};
                
                for i = 1:length(trueStrainCurveBuffer) - 1.0
                    % Get the cyclic stress-strain curve
                    endStress = stressCurve(end);
                    endStrain = strainCurve(end);
                    
                    stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                    strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                end
                
                f9 = figure('visible', 'off');
                plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                msg = sprintf('CSS1, Cyclic stress-strain for PE1 and PS1');
                
                if outOfPlane == 1.0
                    xlabel('Maximum principal strain', 'FontSize', 12.0);
                    ylabel('Maximum principal stress [MPa]', 'FontSize', 12.0)
                else
                    xlabel('Maximum in-plane principal strain', 'FontSize', 12.0);
                    ylabel('Maximum in-plane principal stress [MPa]', 'FontSize', 12.0)
                end
                
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                grid on
                
                fileName = [dir, sprintf('/CSS1, Cyclic stress-strain for PE1 and PS1')];
                saveas(f9, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
                
                %% CSS2 (Cyclic stress-strain for PS2)
                
                % Get the buffers containing the stress-strain curves
                trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_2');
                trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_2');
                
                % Get the monotonic stress-strain curve
                stressCurve = trueStressCurveBuffer{1.0};
                strainCurve = trueStrainCurveBuffer{1.0};
                
                for i = 1:length(trueStrainCurveBuffer) - 1.0
                    % Get the cyclic stress-strain curve
                    endStress = stressCurve(end);
                    endStrain = strainCurve(end);
                    
                    stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                    strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                end
                
                f10 = figure('visible', 'off');
                plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                msg = sprintf('CSS2, Cyclic stress-strain for PE2 and PS2');
                
                if outOfPlane == 1.0
                    xlabel('Middle principal strain', 'FontSize', 12.0);
                    ylabel('Middle principal stress [MPa]', 'FontSize', 12.0)
                else
                    xlabel('Minimum in-plane principal strain', 'FontSize', 12.0);
                    ylabel('Minimum in-plane principal stress [MPa]', 'FontSize', 12.0)
                end
                
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                grid on
                
                fileName = [dir, '/CSS2, Cyclic stress-strain for PE2 and PS2'];
                saveas(f10, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
                
                %% CSS3 (Cyclic stress-strain for PS3)
                if outOfPlane == 1.0
                    % Get the buffers containing the stress-strain curves
                    trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_3');
                    trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_3');
                    
                    % Get the monotonic stress-strain curve
                    stressCurve = trueStressCurveBuffer{1.0};
                    strainCurve = trueStrainCurveBuffer{1.0};
                    
                    for i = 1:length(trueStrainCurveBuffer) - 1.0
                        % Get the cyclic stress-strain curve
                        endStress = stressCurve(end);
                        endStrain = strainCurve(end);
                        
                        stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                        strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                    end
                    
                    f11 = figure('visible', 'off');
                    plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                    msg = sprintf('CSS3, Cyclic stress-strain for PE3 and PS3');
                    xlabel('Minimum principal strain', 'FontSize', 12.0);
                    ylabel('Minimum principal stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    grid on
                    
                    fileName = [dir, '/CSS3, Cyclic stress-strain for PE3 and PS3'];
                    saveas(f11, fileName, 'fig')
                    postProcess.makeVisible([fileName, '.fig'])
                end
            end
        end
        
        %% Export tables
        function [] = outputTables(step, phiC, E11, E22, E33, S11, S22,...
                S33, signalLength, msCorrection)
            outputPath = getappdata(0, 'outputPath');
            
            dir = [outputPath, '/Data Files'];
            if exist(dir, 'dir') == 0.0
                mkdir(dir)
            end
            
            INC = 1:signalLength;
            
            %%
            %{
                ANGLE HISTORIES -> Multiple values over all plane
                orientations
            %}
            planes = 0:step:180;
            
            ST = getappdata(0, 'shear_cp');
            NT = getappdata(0, 'normal_cp');
            
            PT = getappdata(0, 'worstNodeDamageParamCube');
            DT = getappdata(0, 'worstNodeDamageCube');
            LT = 1.0./DT;
            
            %% Open file for writing:
            
            fid = fopen([dir, '/h-output-angle.dat'], 'w+');
            
            data = [planes; ST; NT; PT; DT; LT]';
            
            fprintf(fid, 'ST, NT, DPP, DP, LP, ANGLE HISTORIES\r\n\r\n');
            
            fprintf(fid, 'PHI = %.0f degrees\r\n', phiC);
            
            fprintf(fid, 'Plane orientation (THETA-degrees)\tMaximum shear strain\tMaximum normal strain\tDamage parameter\tDamage\tLife\n');
            fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4e\t%.4e\r\n', data');
            
            fclose(fid);
            
            %%
            %{
                TENSOR HISTORIES -> Multiple values on the
                critical plane
            %}
            outOfPlane = getappdata(0, 'multiaxialFatigue_outOfPlane');
            
            if msCorrection == 0.0
                if outOfPlane == 1.0
                    data = [INC; E11; E22; E33]';
                    
                    %% Open file for writing:
                    
                    fid = fopen([dir, '/h-output-tensor.dat'], 'w+');
                    
                    fprintf(fid, 'EST, PRINCIPAL TENSOR HISTORY\r\n\r\n');
                    
                    fprintf(fid, 'Load Increment\tPE1\tPE2\tPE3\r\n');
                    
                    fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\r\n', data');
                else
                    data = [INC; E11; E22]';
                    
                    %% Open file for writing:
                    
                    fid = fopen([dir, '/h-output-tensor.dat'], 'w+');
                    
                    fprintf(fid, 'EST, PRINCIPAL TENSOR HISTORY\r\n\r\n');
                    
                    fprintf(fid, 'Load Increment\tPE1\tPE2\r\n');
                    
                    fprintf(fid, '%.0f\t%.4f\t%.4f\r\n', data');
                end
            else
                if outOfPlane == 1.0
                    data = [INC; E11; E22; E33; S11; S22; S33]';
                    
                    %% Open file for writing:
                    
                    fid = fopen([dir, '/h-output-tensor.dat'], 'w+');
                    
                    fprintf(fid, 'EST, PRINCIPAL TENSOR HISTORY\r\n\r\n');
                    
                    fprintf(fid, 'Load Increment\tPE1\tPE2\tPE3\tPS1 (MPa)\tPS2 (MPa)\tPS3 (MPa)\r\n');
                    fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
                else
                    data = [INC; E11; E22; S11; S22]';
                    
                    %% Open file for writing:
                    
                    fid = fopen([dir, '/h-output-tensor.dat'], 'w+');
                    
                    fprintf(fid, 'EST, PRINCIPAL TENSOR HISTORY\r\n\r\n');
                    
                    fprintf(fid, 'Load Increment\tPE1\tPE2\tPS1 (MPa)\tPS2 (MPa)\r\n');
                    fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
                end
            end
            
            fclose(fid);
            
            %%
            %{
                CYCLE HISTORIES -> Worst cycle per item and all cycles at worst
                item
            %}
            
            pairs = getappdata(0, 'cyclesOnCP');
            WCA = getappdata(0, 'amplitudesOnCP');
            WCM = 0.5*(pairs(:, 1.0)' + pairs(:, 2.0)');
            
            C = 1:length(WCM);
            
            data = [C; WCM; WCA]';
            
            %% Open file for writing:
            fid = fopen([dir, '/h-output-cycle.dat'], 'w+');
            
            fprintf(fid, 'HD, ALL CYCLE HISTORIES\r\n');
            fprintf(fid, 'Cycle #\tMean strain\tStrain amplitude\r\n');
            
            fprintf(fid, '%.0f\t%.4f\t%.4f\r\n', data');
            
            fclose(fid);
            
            %%
            %{
                LOAD HISTORIES -> Multiple values at over all signal
                increments
            %}
            CN = getappdata(0, 'CN');
            CS = getappdata(0, 'CS');
            
            data = [INC; CN; CS]';
            
            %% Open file for writing:
            fid = fopen([dir, '/h-output-load.dat'], 'w+');
            
            fprintf(fid, 'CN, CS, NORMAL AND SHEAR STRAIN HISTORY ON CRITICAL PLANE\r\n');
            
            fprintf(fid, 'Load Increment\tNormal strain\tResultant Shear strain\r\n');
            fprintf(fid, '%.0f\t%.4f\t%.4f\r\n', data');
            
            fclose(fid);
        end
    end
end
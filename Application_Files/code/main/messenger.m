classdef messenger < handle
%MESSENGER    QFT class for message file.
%   This class contains methods to write information to the message (.msg)
%   file.
%   
%   MESSENGER is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 12-May-2017 15:25:52 GMT
    
    %%
    
    methods(Static = true)
        
        %% WRITE TO THE MESSAGE FILE
        function [] = writeMessage(messageID)
            %{
                Write analysis-specific messages to the command window
                and/or the message (.msg) file.
            
                The function is called with the argument messageID, which
                is a tag specifying which pre-defined message to print
            %}
            
            %{
                Search for string _AVAILABLE_ to check for unused message IDs
            %}
                
            %% AUXILIARY TASKS
            
            %{
                If this function is being called from the material
                evaluation feature in Material Manager, exit now since
                there is no message file
            %}
            if isappdata(0, 'evaluateMaterialMessenger') == 1.0
                return
            end
            
            % If the message file already exists, get the file ID
            if messageID ~= 0.0
                fid = getappdata(0, 'messageFID');
            end
            
            if messageID == 0.0 % Open the message file for writing
                msgFile = [getappdata(0, 'outputDirectory'), sprintf('%s.msg', getappdata(0, 'jobName'))];
                
                fid = fopen(msgFile, 'w');
                
                fprintf(fid, 'MESSAGES:\r\n=======');
                
                setappdata(0, 'messageFID', fid)
                
                return
            elseif messageID == -999.0 % Close the message file
                if getappdata(0, 'dataCheck') == 1.0
                    fprintf(fid, '\r\n***NOTE: THE DATA CHECK HAS BEEN COMPLETED (%fs)', getappdata(0, 'dataCheck_time'));
                    
                    % Prompt user if they would like to view the message file
                    if (ispc == 1.0) && (ismac == 0.0)
                        answer = questdlg('Data check complete.', 'Quick Fatigue Tool', 'View messages', 'Open results folder', 'Close', 'View messages');
                    elseif (ispc == 0.0) && (ismac == 1.0)
                        answer = msgbox('Data check complete.', 'Quick Fatigue Tool');
                    else
                        answer = -1.0;
                    end
                    
                    jobName = getappdata(0, 'jobName');
                    dir = sprintf('Project\\output\\%s', jobName);
                    if strcmpi(answer, 'View messages') == 1.0
                        try
                            system(sprintf('notepad %s &', [pwd, '\', dir, '\', jobName, '.msg']));
                        catch
                            errordlg('The message file could not be opened.', 'Quick Fatigue Tool')
                        end
                    elseif strcmpi(answer, 'Open results folder') == 1.0
                        winopen(dir)
                    end
                else
                    fprintf(fid, '\r\n***NOTE: THE ANALYSIS HAS BEEN COMPLETED');
                end
                
                fclose(fid);
                
                return
            elseif messageID == -1.0 % Indicate that no messages were written to the file
                if getappdata(0, 'messageFileWarnings') == 0.0 && getappdata(0, 'messageFileNotes') == 0.0
                    fprintf(fid, '\r\nNO MESSAGES TO DISPLAY');
                end
                
                return
            end
            
            %{
                Define return types for FPRINTF depending on whether the
                messages are being echoed to the commmand window
            %}
            if getappdata(0, 'echoMessagesToCWIN') == 1.0 % [message file, command window]
                fidType = [fid, 1.0];
                returnType = {'\r\n', '\n'};
            else
                fidType = fid; % Message file only
                returnType = {'\r\n'};
            end
            
            %% WRITE MESSAGE BASED ON MESSAGE ID
            X = length(fidType);
            
            for i = 1:X
                switch messageID
                    case 1.0
                        % Print warning if extensive output was not requested
                        if (getappdata(0, 'outputField') == 0.0) && (getappdata(0, 'outputHistory') == 0.0) && (getappdata(0, 'outputFigure') == 0.0)
                            fprintf(fidType(i), [returnType{i}, '***NOTE: Extensive output was not requested by the user', returnType{i}]);
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        else
                            if getappdata(0, 'outputField') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: Field output was not requested by the user', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                            if getappdata(0, 'outputHistory') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: History output was not requested by the user', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                            if getappdata(0, 'outputFigure') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: MATLAB figures were not requested by the user', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 2.0
                        % Scale factors and gating values
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The number of load gating values does not match the number of load histories', returnType{i}]);
                        fprintf(fidType(i), ['-> Either the last gating value specified will be used for the remainder of the load histories,', returnType{i}]);
                        fprintf(fidType(i), ['   or excess load gating values will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 3.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The number of load scale factors does not match the number of load histories', returnType{i}]);
                        fprintf(fidType(i), ['-> Either the last load scale factor specified will be used for the remainder of the load histories,', returnType{i}]);
                        fprintf(fidType(i), ['   or excess load scale factors will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 4.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The number of load offset values does not match the number of load histories', returnType{i}]);
                        fprintf(fidType(i), ['-> Either the last load offest value specified will be used for the remainder of the load histories,', returnType{i}]);
                        fprintf(fidType(i), ['   or excess load offest values will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 5.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: One or more load offset values were specified in the job file', returnType{i}]);
                        fprintf(fidType(i), ['-> Dataset sequence analyses are not compatible with load offset values', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 6.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The number of load scale factors for the high frequency data does not match the number of load histories', returnType{i}]);
                        fprintf(fidType(i), ['-> Either the last load scale factor specified will be used for the remainder of the load histories,', returnType{i}]);
                        fprintf(fidType(i), ['   or excess load scale factors will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 7.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The Uniaxial Stress-Life algorithm is not compatible with certain features', returnType{i}]);
                        
                        fprintf(fidType(i), ['The following job file options will be ignored:', returnType{i}]);
                        fprintf(fidType(i), ['-> DATASET, PLANE_STRESS, OUTPUT_DATABASE, PART_INSTANCE, FEA_PROCEDURE, STEP_NAME, RESULT_POSITION, GROUP, ITEMS', returnType{i}]);
                    case 8.0
                        % Proof stress
                        if getappdata(0, 'twops_status') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: The proof stress for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                            fprintf(fidType(i), ['-> A derived value of %.4gMPa will be used', returnType{i}], getappdata(0, 'twops'));
                            
                            if getappdata(0, 'modifiedGoodman') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: The modified Goodman mean stress correction is enabled', returnType{i}]);
                                fprintf(fidType(i), ['-> Derived values of the proof stress may lead to unrealistic damage values when used with this algorithm', returnType{i}]);
                                
                                setappdata(0, 'messageFileWarnings', 1.0)
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        elseif getappdata(0, 'twops_status') == -1.0
                            if getappdata(0, 'outputField') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The proof stress is undefined in group %.0f', returnType{i}], getappdata(0, 'message_8_group'));
                            else
                                fprintf(fidType(i), [returnType{i}, '***NOTE: No proof stress was defined for material %s (group %.0f)', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                fprintf(fidType(i), [returnType{i}, '-> A value could not be derived', returnType{i}]);
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 9.0
                        % Sf'
                        if getappdata(0, 'Sf_status') == 1.0
                            if getappdata(0, 'useSN') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The fatigue strength coefficient for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                
                                if isempty(getappdata(0, 'Sf')) == 0.0
                                    fprintf(fidType(i), ['-> A derived value of %.4gMPa will be used', returnType{i}], getappdata(0, 'Sf'));
                                else
                                    fprintf(fidType(i), ['-> A value could not be derived', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 10.0
                        % b
                        if getappdata(0, 'b_status') == 1.0
                            if getappdata(0, 'useSN') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The fatigue strength exponent for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                fprintf(fidType(i), ['-> A derived value of %.4g will be used', returnType{i}], getappdata(0, 'b'));
                            end
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 11.0
                        % Ef'
                        if getappdata(0, 'Ef_status') == 1.0
                            if getappdata(0, 'algorithm') == 4.0 && getappdata(0, 'plasticSN') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The fatigue ductility coefficient for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                
                                if isempty(getappdata(0, 'Ef')) == 0.0
                                    fprintf(fidType(i), ['-> A derived value of %.4g will be used', returnType{i}], getappdata(0, 'Ef'));
                                else
                                    fprintf(fidType(i), ['-> A value could not be derived', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 12.0
                        % c
                        if getappdata(0, 'c_status') == 1.0
                            if getappdata(0, 'algorithm') == 4.0 && getappdata(0, 'plasticSN') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The fatigue ductility exponent fpr material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                
                                if isempty(getappdata(0, 'c')) == 0.0
                                    fprintf(fidType(i), ['-> A derived value of %.4g will be used', returnType{i}], getappdata(0, 'c'));
                                else
                                    fprintf(fidType(i), ['-> A value could not be derived', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 13.0
                        % K'
                        if getappdata(0, 'kp_status') == 1.0
                            if getappdata(0, 'nlMaterial') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The cyclic strain hardening coefficient for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                
                                if isempty(getappdata(0, 'kp')) == 0.0
                                    fprintf(fidType(i), ['-> A derived value of %.4gMPa will be used', returnType{i}], getappdata(0, 'kp'));
                                else
                                    fprintf(fidType(i), ['-> A value could not be derived', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 14.0
                        % n'
                        if getappdata(0, 'np_status') == 1.0
                            if getappdata(0, 'nlMaterial') == 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The cyclic strain hardening exponent for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                                
                                if isempty(getappdata(0, 'kp')) == 0.0
                                    fprintf(fidType(i), ['-> A derived value of %.4g will be used', returnType{i}], getappdata(0, 'np'));
                                else
                                    fprintf(fidType(i), [returnType{i}, '-> A value could not be derived', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 15.0
                        % k
                        if getappdata(0, 'algorithm') == 6.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: The normal stress sensitivity constant for material %s (group %.0f) was not specified', returnType{i}], getappdata(0, 'getMaterial_currentMaterial'), getappdata(0, 'getMaterial_currentGroup'));
                            fprintf(fidType(i), ['-> Using the Socie & Marquis default value of 0.2857', returnType{i}]);
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 16.0
                        if getappdata(0, 'suppress_ID16') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In one or more datasets, element-nodal or integration point labels were used but only one analysis item was found', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID16', 1.0)
                            end
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 17.0
                        % Multiple regions in the .rpt file
                        if getappdata(0, 'suppress_ID17') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: There are %.0f regions in the model', returnType{i}], getappdata(0, 'numberOfRegions'));
                            
                            if i == X
                                setappdata(0, 'suppress_ID17', 1.0)
                            end
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 18.0
                        % Worst analysis item
                        if getappdata(0, 'peekAnalysis') == 1.0
                            worstItem = getappdata(0, 'peekItem');
                        else
                            worstItem = getappdata(0, 'worstAnalysisItem_original');
                        end
                        
                        algorithm = getappdata(0, 'algorithm');
                        if algorithm ~= 3.0
                            if length(worstItem) > 1.0
                                if length(worstItem) > 10.0
                                    fprintf(fidType(i), [returnType{i}, '***NOTE: The worst analysis item IDs are:', returnType{i}]);
                                    fprintf(fidType(i), '-> %.0f, ', worstItem(1.0));
                                    
                                    for n = 2:8
                                        fprintf(fidType(i), '%.0f, ', worstItem(n));
                                    end
                                    
                                    fprintf(fidType(i), ['%.0f', returnType{i}], worstItem(10.0));
                                    
                                    fprintf(fidType(i), ['-> (Only the first 10 items are printed)', returnType{i}]);
                                    fprintf(fidType(i), ['-> These values can be used in conjunction with the ITEMS option in the job', returnType{i}]);
                                    fprintf(fidType(i), ['   file to re-run the analysis at these locations only', returnType{i}]);
                                else
                                    fprintf(fidType(i), [returnType{i}, '***NOTE: The worst analysis item IDs are:', returnType{i}]);
                                    
                                    fprintf(fidType(i), '-> %.0f, ', worstItem(1.0));
                                    
                                    for n = 2:(length(worstItem) - 1.0)
                                        fprintf(fidType(i), '%.0f, ', worstItem(n));
                                    end
                                    
                                    fprintf(fidType(i), ['%.0f', returnType{i}], worstItem(end));
                                    
                                    fprintf(fidType(i), ['-> These values can be used in conjunction with the ITEMS option in the job', returnType{i}]);
                                    fprintf(fidType(i), ['   file to re-run the analysis at these locations only', returnType{i}]);
                                end
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            else
                                fprintf(fidType(i), [returnType{i}, '***NOTE: The worst analysis item ID is %.0f', returnType{i}], worstItem);
                                fprintf(fidType(i), ['-> This value can be used as an argument for the ITEMS option in the job file', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 19.0
                        % Nodal elimination
                        fprintf(fidType(i), [returnType{i}, '***NOTE: All items were removed during nodal elimination', returnType{i}]);
                        fprintf(fidType(i), ['-> The item(s) with the largest principal stress range will be analysed', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 20.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Nodal elimination is not compatible with the BS 7608 analysis algorithm', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 21.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Nodal elimination is not compatible with the Uniaxial Stress-Life analysis algorithm', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 22.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Whenever nodal elimination is activated, items whose largest stress is less than the elimination']);
                        fprintf(fidType(i), [returnType{i}, 'threshold are not included in the analysis, but they are still printed to the field output file', returnType{i}]);
                        fprintf(fidType(i), ['-> Field output for the analysed items will be copied to ''f-output-analysed.dat''', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 23.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The BS 7608 analysis algorithm is not compatible with certain features', returnType{i}]);
                        
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), ['The following field variables are not available:', returnType{i}]);
                            fprintf(fidType(i), ['-> FOS, SFA, FRFH, FRFV, FRFR, FRFW, YIELD, TSE, PSE', returnType{i}]);
                        end
                        
                        if getappdata(0, 'outputHistory') == 1.0
                            fprintf(fidType(i), ['The following history variables are not available:', returnType{i}]);
                            fprintf(fidType(i), ['-> ANHD, HD', returnType{i}]);
                        end
                        
                        fprintf(fidType(i), ['The following job file options will be ignored:', returnType{i}]);
                        fprintf(fidType(i), ['-> MATERIAL, USE_SN, SN_SCALE, SN_KNOCK_DOWN, MS_CORRECTION, FACTOR_OF_STRENGTH, FATIGUE_RESERVE_FACTOR, KT_DEF, KT_CURVE, NOTCH_CONSTANT, NOTCH_RADIUS', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 24.0
                        % Worst damage at design life is greater than 1.0
                        ddl = max(getappdata(0, 'D')*getappdata(0, 'dLife'));
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Worst damage at design life (%.3g) is %.3g', returnType{i}], getappdata(0, 'dLife'), ddl);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 25.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Multiple S-N datasets (Group %.0f) were provided without the R-ratio S-N curve mean stress correction', returnType{i}], getappdata(0, 'message_25_71_72_73_groupNumber'));
                        fprintf(fidType(i), ['-> The data will be interpolated to approximate the S-N curve at zero mean stress (R = -1)', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 26.0
                        if getappdata(0, 'suppress_ID26') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: After interpolation of material %s (group %.0f), some S-values were found to be negative', returnType{i}], char(getappdata(0, 'message_currentMaterial')), getappdata(0, 'message_groupNumber'));
                            fprintf(fidType(i), ['-> This can happen when the mean stress is very high and does not necessarily indicate a problem with', returnType{i}]);
                            fprintf(fidType(i), ['the material properties. However, it is recommended that the S-N data is double-checked for accuracy', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID26', 1.0)
                            end
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 27.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The SN_SCALE option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'snScale')));
                        fprintf(fidType(i), ['-> The first value of SN_SCALE will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in SN_SCALE matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 28.0
                        % Print warning(s) if there is a problem with the mean stress correction
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Regression fitting for the Walker gamma parameter is not recommended for non-steels', returnType{i}]);
                        fprintf(fidType(i), ['-> A user-defined value of the Walker gamma parameter should be used instead', returnType{i}]);
                        
                        if getappdata(0, 'materialBehavior') == 2.0
                            fprintf(fidType(i), ['-> For aluminium, an approximate value of 0.45 is acceptable', returnType{i}]);
                        end
                        
                        fprintf(fidType(i), ['-> Settings related to the Walker calculation are found in the environment file', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 29.0
                        % Scale and combine warnings
                        fprintf(fidType(i), [returnType{i}, '***NOTE: More than one dataset/history pair was expected because the load history was defined as a cell array', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 30.0
                        % Print a warning to the command window if FOS calculation is active on
                        % more than one analysis item
                        if (getappdata(0, 'enableFOS') == 1.0) && (getappdata(0, 'numberOfNodes') > 1.0) && (getappdata(0, 'outputField') == 1.0) && (getappdata(0, 'algorithm') ~= 8.0)
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The FOS algorithm is active for more than one analysis item', returnType{i}]);
                            fprintf(fidType(i), ['-> The analysis may take a long time to complete', returnType{i}]);
                            fprintf(fidType(i), ['-> Restricting the FOS algorithm to a single analysis item will enable additional FOS diagnostic messages', returnType{i}]);
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 31.0
                        % FEA definition
                        dataLabel = getappdata(0, 'dataLabel');
                        if getappdata(0, 'algorithm') ~= 3.0
                            if dataLabel(1.0) == 9.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: Detected shell section information in the stress dataset', returnType{i}]);
                                if getappdata(0, 'shellLocation') == 1.0
                                    fprintf(fidType(i), ['-> Reading stresses from negative (SNEG) element faces with unique nodal or centroidal position labels', returnType{i}]);
                                else
                                    fprintf(fidType(i), ['-> Reading stresses from positive (SPOS) element faces with unique nodal or centroidal position labels', returnType{i}]);
                                end
                                fprintf(fidType(i), ['-> The default shell face is set by the environment variable ''shellLocation''', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            elseif dataLabel(1.0) == 10.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: Detected shell section information in the stress dataset', returnType{i}]);
                                if getappdata(0, 'shellLocation') == 1.0
                                    fprintf(fidType(i), ['-> Reading stresses from negative (SNEG) element faces with element-nodal or integration point position labels', returnType{i}]);
                                else
                                    fprintf(fidType(i), ['-> Reading stresses from positive (SPOS) element faces with element-nodal or integration point position labels', returnType{i}]);
                                end
                                fprintf(fidType(i), ['-> The default shell face is set by the environment variable ''shellLocation''', returnType{i}]);
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                        end
                    case 32.0
                        % Load proportionality
                        if (getappdata(0, 'algorithm') == 4.0 || getappdata(0, 'algorithm') == 5.0 || getappdata(0, 'algorithm') == 6.0 || getappdata(0, 'algorithm') == 8.0)
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In all or part of the model, the maximum deviation of the principal directions in the loading does not exceed the specified tolerance of %.3g degrees', returnType{i}], getappdata(0, 'proportionalityTolerance'));
                            fprintf(fidType(i), ['-> The critical plane step size has been increased to 90 degrees for these analysis items', returnType{i}]);
                            fprintf(fidType(i), ['-> The tolerance can be changed with the environment variable ''proportionalityTolerance''', returnType{i}]);
                            fprintf(fidType(i), ['-> The load proportionality check can be disabled by setting the environment variable ''checkLoadProportionality'' to 0.0', returnType{i}]);
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 33.0
                        % Automatic Export
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Automatic export for Abaqus .odb files is enabled', returnType{i}]);
                        fprintf(fidType(i), ['-> To associate the job with an .odb file, specify the full (absolute) path to the model .odb file', returnType{i}]);
                        fprintf(fidType(i), ['   using OUTPUT_DATABASE and provide the part instance name with PART_INSTANCE in the job file', returnType{i}]);
                        fprintf(fidType(i), ['-> Optionally, you may add a suffix to the results step with the option STEP_NAME if multiple results steps', returnType{i}]);
                        fprintf(fidType(i), ['   are being written to the same .odb file', returnType{i}]);
                        fprintf(fidType(i), ['-> Settings related to automatic export are found in the environment file (Application_Files\\default\\environment.m)', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 34.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Automatic export for Abaqus .odb files is enabled', returnType{i}]);
                        fprintf(fidType(i), ['-> Set OUTPUT_FIELD = 1.0 in the job file to generate field data', returnType{i}]);
                        fprintf(fidType(i), ['-> Settings related to automatic export are found in the environment file (Application_Files\\default\\environment.m)', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 35.0
                        % Print warning if the previous job directory could not be
                        % removed
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The output directory could not be completely overwritten', returnType{i}]);
                        fprintf(fidType(i), ['-> MException ID: %s', returnType{i}], getappdata(0, 'warning_026_exceptionMessage'));
                        fprintf(fidType(i), ['-> Data from a previous analysis may still remain in the output directory', returnType{i}]);
                        fprintf(fidType(i), ['-> The user is advised to restart MATLAB between each analysis', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 36.0
                        % Print warning if material properties could not be defined properly
                        fprintf(fidType(i), [returnType{i}, '***WARNING: S-N coefficients could not be derived for ''%s'' (group %.0f)', returnType{i}], getappdata(0, 'material'), getappdata(0,'getMaterial_currentGroup'));
                        fprintf(fidType(i), ['-> S-N data points will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 37.0
                        % If S-N data was requested, check that it exists
                        fprintf(fidType(i), [returnType{i}, '***WARNING: S-N data points were requested, but in at least one group none was available', returnType{i}]);
                        fprintf(fidType(i), ['-> S-N coefficients will be used instead', returnType{i}]);
                        fprintf(fidType(i), ['-> The following job file options will be ignored: SN_SCALE, SN_KNOCK_DOWN', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 38.0
                        % If an invalid S-N scale factor is specified
                        fprintf(fidType(i), [returnType{i}, '***WARNING: An invalid S-N scale factor was specified for ''%s'' (group %.0f)', returnType{i}], getappdata(0, 'material'), getappdata(0,'getMaterial_currentGroup'));
                        fprintf(fidType(i), ['-> The value must be greater than zero', returnType{i}]);
                        fprintf(fidType(i), ['-> A value of 1.0 will be assumed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 39.0
                        % If an invalid Kt value was specified
                        fprintf(fidType(i), [returnType{i}, '***WARNING: An invalid value for Kt was specified for ''%s'' (group %.0f)', returnType{i}], getappdata(0, 'message_ktFile'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> Kt must be equal to or greater than 1.0', returnType{i}]);
                        fprintf(fidType(i), ['-> A Kt value of 1.0 will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 40.0
                        % If the Kt file cannot be opened
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Kt file ''%s'' could not be read', returnType{i}], getappdata(0, 'message_ktFile'));
                        fprintf(fidType(i), ['-> MException ID: %s', returnType{i}], getappdata(0, 'warning_028_exceptionMessage'));
                        fprintf(fidType(i), ['-> A value of Kt = 1.0 will be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 41.0
                        % If the user Rz value exceeds the range of Rz values
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The user-specified Rz value of %.3g for ''%s'' (group %.0f) exceeds the range of available Rz values', returnType{i}], getappdata(0, 'message_rzValue'), getappdata(0, 'message_ktFile'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> Kt data corresponding to the largest available Rz value will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 42.0
                        % If the UTS exceeds the range of Kt values
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The material UTS (%.3gMPa) for material %s (group %.0f) exceeds the range of Kt values in ''%s''', returnType{i}], getappdata(0, 'uts'), char(getappdata(0, 'message_material')), getappdata(0, 'message_groupNumber'), getappdata(0, 'message_ktFile'));
                        fprintf(fidType(i), ['-> The last value of Kt for the corresponding curve will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 43.0
                        % If the user selected a Kt curve that doesn't exist in the Kt
                        % file
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Kt curve specified in the job file does not exist', returnType{i}]);
                        fprintf(fidType(i), ['-> MException ID: %s', returnType{i}], getappdata(0, 'warning_030_exceptionMessage'));
                        fprintf(fidType(i), ['-> Check the data in ''%s''', returnType{i}], getappdata(0, 'ktDef'));
                        fprintf(fidType(i), ['-> A Kt value of 1.0 will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 44.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The job file option SN_KNOCK_DOWN appears to be defined as a character array rather than a cell', returnType{i}]);
                        fprintf(fidType(i), ['-> If a single S-N knock-down file was specified, the analysis should be able to continue. However, SN_KNOCK_DOWN must be defined as a', returnType{i}]);
                        fprintf(fidType(i), ['   cell if multiple S-N knock-down files have been specified', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 45.0
                        % If an invalid value of Poisson's ratio was specified
                        fprintf(fidType(i), [returnType{i}, '***WARNING: An invalid value of Poisson''s ratio for material %s (group %.0f) was specified', returnType{i}], char(getappdata(0, 'getMaterial_currentMaterial')), getappdata(0, 'getMaterial_currentGroup'));
                        fprintf(fidType(i), ['-> The Poisson''s ratio must be greater than -1.0 and less than 0.5', returnType{i}]);
                        fprintf(fidType(i), ['-> A value of 0.33 will be assumed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 46.0
                        % Invalid Sf
                        if getappdata(0, 'algorithm') ~= 8.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The fatigue strength coefficient for material %s (group %.0f) is less than zero', returnType{i}], char(getappdata(0, 'getMaterial_currentMaterial')), getappdata(0, 'getMaterial_currentGroup'));
                            fprintf(fidType(i), ['-> A value of Sf = 0.0 will be used', returnType{i}]);
                            if getappdata(0, 'Sf_status') == 1.0
                                if getappdata(0, 'materialBehavior') == 1.0
                                    fprintf(fidType(i), ['-> The defined material is probably not a plain carbon or low/medium alloy steel', returnType{i}]);
                                elseif getappdata(0, 'materialBehavior') == 2.0
                                    fprintf(fidType(i), ['-> The defined material is probably not an alumiunium/titanium alloy', returnType{i}]);
                                end
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 47.0
                        % Invalid Ef
                        if getappdata(0, 'algorithm') == 4.0 && getappdata(0, 'plasticSN') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The fatigue ductility coefficient for material %s (group %.0f) is less than zero', returnType{i}], char(getappdata(0, 'getMaterial_currentMaterial')), getappdata(0, 'getMaterial_currentGroup'));
                            fprintf(fidType(i), ['-> A value of Ef = 0.0 will be used', returnType{i}]);
                            if getappdata(0, 'Ef_status') == 1.0
                                if getappdata(0, 'materialBehavior') == 1.0
                                    fprintf(fidType(i), ['-> The defined material is probably not a plain carbon or low/medium alloy steel', returnType{i}]);
                                elseif getappdata(0, 'materialBehavior') == 2.0
                                    fprintf(fidType(i), ['-> The defined material is probably not an alumiunium/titanium alloy', returnType{i}]);
                                end
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 48.0
                        % Check if nonlinear material data was available
                        fprintf(fidType(i), [returnType{i}, '***WARNING: In at least one group, nonlinear material data is not available', returnType{i}]);
                        fprintf(fidType(i), ['-> Elastic (Hookean) material data will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 49.0
                        % Print warning(s) if there is a problem with the mean stress correction
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Morrow mean stress correction requires a value for the fatigue strength coefficient', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 50.0
                        fprintf(fidType(i), [returnType{i}, '\r\n***WARNING: The Smith-Watson-Topper mean stress correction is not compatible with the stress-based Brown-Miller algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Morrow mean stress correction will be used instead\r\n', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 51.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Walker mean stress correction is not compatible with the Stress-based Brown-Miller algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Morrow mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 52.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Morrow mean stress correction is not compatible with the Stress Invariant Parameter algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 53.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Smith-Watson-Topper mean stress correction is not compatible with the Stress Invariant Parameter algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 54.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Morrow mean stress correction is not compatible with the Uniaxial Stress-Life algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 55.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Smith-Watson-Topper mean stress correction is not compatible with the Uniaxial Stress-Life algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 56.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Goodman mean stress correction requires a value for the ultimate tensile strength', returnType{i}]);
                        fprintf(fidType(i), ['-> No mean stress correction will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 57.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Soderberg mean stress correction requires a value for the yield stress', returnType{i}]);
                        fprintf(fidType(i), ['-> No mean stress correction will be used', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 58.0
                        if getappdata(0, 'suppress_ID58') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The mean stress in some parts of the loading could not be captured by the user-defined mean stress correction', returnType{i}]);
                            fprintf(fidType(i), ['-> The allowable stress amplitude has been held constant for these cycles', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID58', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 59.0
                        % RPT interface
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Some user-defined items could not be located in the stress dataset', returnType{i}]);
                        fprintf(fidType(i), ['-> Check the ITEMS option in the job file. All items will be analysed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 60.0
                        % Complex values in the load signal
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Parts of the load history contain complex stress values', returnType{i}]);
                        fprintf(fidType(i), ['-> Complex values will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 61.0
                        % CP search
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The selected step size is inappropriate', returnType{i}]);
                        fprintf(fidType(i), ['-> The step size has been changed to 15 degrees', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 62.0
                        % Warning if there was a problem with the rainflow counting algorithm
                        if getappdata(0, 'suppress_ID62') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: No peak/valley pairs were detected in parts of the load signal', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID62', 1.0)
                            end
                        
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 63.0
                        if getappdata(0, 'suppress_ID63') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: Time stamps for some shear cycles were zero', returnType{i}]);
                            fprintf(fidType(i), ['-> A normal stress component could not be found for these cycles', returnType{i}]);
                            fprintf(fidType(i), ['-> The Findley parameter will be taken from the shear stress only', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID63', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 64.0
                        % Invalid Sf
                        if getappdata(0, 'algorithm') ~= 8.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The fatigue strength coefficient for material %s (group %.0f) is less than zero', returnType{i}], char(getappdata(0, 'getMaterial_currentMaterial')), getappdata(0, 'getMaterial_currentGroup'));
                            fprintf(fidType(i), ['-> A value of Sf = %.3gMPa (0.9*UTS/2e3^b) will be assumed using the "90/50" approximation.', returnType{i}], getappdata(0, 'Sf'));
                            fprintf(fidType(i), ['-> Consult Appendix II of the User Guide for a detialed description of this method', returnType{i}]);
                            if getappdata(0, 'Sf_status') == 1.0
                                if getappdata(0, 'materialBehavior') == 1.0
                                    fprintf(fidType(i), ['-> The defined material is probably not a plain carbon or low/medium alloy steel', returnType{i}]);
                                elseif getappdata(0, 'materialBehavior') == 2.0
                                    fprintf(fidType(i), [returnType{i}, '-> The defined material is probably not an alumiunium/titanium alloy', returnType{i}]);
                                end
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 65.0
                        % Print warning if plasticity was detected in the loading
                        L = getappdata(0, 'L');
                        if any(L < 1e6)
                            if getappdata(0, 'nlMaterial') == 0.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f items have lives less than 1e+06 %s', returnType{i}], length(L (L < 1e6)), getappdata(0, 'loadEqUnits'));
                                fprintf(fidType(i), ['-> The S-N methodology is usually intended for high cycle fatigue problems', returnType{i}]);
                                fprintf(fidType(i), ['-> Please check the validity of the input data for the analysis application', returnType{i}]);
                                fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_lcf_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                                
                                setappdata(0, 'messageFileWarnings', 1.0)
                            else
                                fprintf(fidType(i), [returnType{i}, '***NOTE: After considering plasticity, %.0f items still have lives less than 1e6 cycles', returnType{i}], length(L (L < 1e6)));
                                
                                setappdata(0, 'messageFileNotes', 1.0)
                            end
                            
                            % Print warning if overflows were detected in the loading
                            if any(L < 1.0)
                                fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f items have stresses too large for fatigue analysis', returnType{i}], length(L(L < 1.0)));
                                fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_overflow_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                                
                                setappdata(0, 'messageFileWarnings', 1.0)
                            end
                        end
                    case 66.0
                        numberOfGroups = getappdata(0, 'numberOfGroups');
                        N = getappdata(0, 'warning_066_N');
                        
                        if N > 0.0
                            if numberOfGroups > 1.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f items in material %s (group %.0f) have yielded', returnType{i}], N, char(getappdata(0, 'message_groupMaterial')), getappdata(0, 'message_groupNumber'));
                            else
                                fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f items have yielded', returnType{i}], N);
                            end
                            setappdata(0, 'messageFileWarnings', 1.0)
                        else
                            if numberOfGroups > 1.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: %.0f items in material %s (group %.0f) have yielded', returnType{i}], N, char(getappdata(0, 'message_groupMaterial')), getappdata(0, 'message_groupNumber'));
                            else
                                fprintf(fidType(i), [returnType{i}, '***NOTE: %.0f items have yielded', returnType{i}], N);
                            end
                        end
                        
                        fprintf(fidType(i), ['-> The ratio between the maximum volumetric strain energy and the tensile limit strain energy is %.4g', returnType{i}], max(getappdata(0, 'totalStrainEnergy_group'))/getappdata(0, 'strainLimitEnergy'));
                    case 67.0
                        if getappdata(0, 'suppress_ID67') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The largest stress range in the loading exceeds the yield strength by more than 200%%', returnType{i}]);
                            fprintf(fidType(i), ['-> The weld is likely to experience non-fatigue failure', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID67', 1.0)
                            end
                        
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 68.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The ultimate tensile strength is required when using Class X (axially loaded bolts) with BS 7608', returnType{i}]);
                        fprintf(fidType(i), ['-> A value of 785MPa will be assumed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 69.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Analysis of Class X (axially loaded bolts) with BS 7608 is not valid for an ultimate tensile strength greater than 785MPa', returnType{i}]);
                        fprintf(fidType(i), ['-> A value of 785MPa will be assumed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 70.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The specified weld class was not recognised', returnType{i}]);
                        fprintf(fidType(i), ['-> A class B weld will be assumed', returnType{i}]);
                        fprintf(fidType(i), ['-> For information about weld classification, consult document BS 7608:1993', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 71.0
                        % R-ratio S-N data
                        fprintf(fidType(i), [returnType{i}, '***WARNING: R-ratio S-N curves were requested for a single S-N dataset (Group %.0f) with an R-value of -1', returnType{i}], getappdata(0, 'message_25_71_72_73_groupNumber'));
                        fprintf(fidType(i), ['-> The mean stress will not be taken into account', returnType{i}]);
                        fprintf(fidType(i), ['-> Specify additional S-N data for different R-ratios', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 72.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: R-ratio S-N curves were requested but only one S-N dataset (Group %.0f) was provided', returnType{i}], getappdata(0, 'message_25_71_72_73_groupNumber'));
                        fprintf(fidType(i), ['-> The mean stress correction may be incorrect', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 73.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The S-N data provided (Group %.0f) is associated with an R-ratio at a non-zero mean stress, but R-ratio S-N curves were not requested', returnType{i}], getappdata(0, 'message_25_71_72_73_groupNumber'));
                        fprintf(fidType(i), ['-> The S-N data will be treated as being R = -1 (zero mean stress)', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 74.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: R-ratio S-N curves are only compatible with S-N data', returnType{i}]);
                        fprintf(fidType(i), ['-> The Morrow mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 75.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: R-ratio S-N curves are only compatible with S-N data', returnType{i}]);
                        fprintf(fidType(i), ['-> The Goodman mean stress correction will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 76.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Prior to analysis, the S-N curve for material %s (group %.0f) had to be linearly extrapolated because the curve for', returnType{i}], char(getappdata(0, 'message_currentMaterial')), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['R = -1 falls outside the range of the data provided', returnType{i}]);
                        fprintf(fidType(i), ['-> The fatigue result may be inaccurate', returnType{i}]);
                        fprintf(fidType(i), ['-> This problem can be solved by providing S-N data over a greater range of R-values', returnType{i}]);
                        fprintf(fidType(i), ['-> This problem can be solved by providing S-N data for R = -1.0', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 77.0
                        if getappdata(0, 'suppress_ID77') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: During the analysis, the S-N curve had to be linearly extrapolated because the load ratio', returnType{i}]);
                            fprintf(fidType(i), ['for some cycles fell outside the range of the data provided', returnType{i}]);
                            fprintf(fidType(i), ['-> The fatigue result may be inaccurate for some cycles', returnType{i}]);
                            fprintf(fidType(i), ['-> This problem can be alleviated by providing S-N data over a greater range of R-values', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID77', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 78.0
                        % S-values are not decreasing monotonically
                        if getappdata(0, 'suppress_ID78') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: After interpolation, some S-values for material %s (group %.0f) are not strictly decreasing', returnType{i}], char(getappdata(0, 'message_currentMaterial')), getappdata(0, 'message_groupNumber'));
                            fprintf(fidType(i), ['-> These points have been automatically adjusted to ensure consistency', returnType{i}]);
                            fprintf(fidType(i), ['-> This can happen when there is a large relative difference between consecutive pairs of S-values,', returnType{i}]);
                            fprintf(fidType(i), ['   if two S-N curves cross each other, or if the the S-N curve contains a plateau', returnType{i}]);
                            fprintf(fidType(i), ['-> Check the quality of the S-N data', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID78', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 79.0
                        % FOS accuracy
                        fprintf(fidType(i), [returnType{i}, '***WARNING: After adjusting the load by the estimated FOS, the ratio between the calculated life and the target life is %.3g', returnType{i}], getappdata(0, 'fosRatio'));
                        fprintf(fidType(i), ['-> The calculated FOS is inaccurate, which suggests that the default FOS settings should be changed', returnType{i}]);
                        fprintf(fidType(i), ['-> Guidance on obtaining an accurate FOS solution can be found in Section 8.3.4 of the Quick Fatigue Tool User Guide', returnType{i}]);
                        
                        setappdata(0, 'warning_79_suppressGuidanceMessage', 1.0)
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 80.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The specified FOS tolerance of %.3g%% was not achieved at the worst FOS item (%.0f.%.0f)', returnType{i}], getappdata(0, 'fosTolerance'), getappdata(0, 'WNFOS_mainID'), getappdata(0, 'WNFOS_subID'));
                        if getappdata(0, 'fosDiagnostics') == 0.0
                            fprintf(fidType(i), ['-> Set fosDiagnostics = 1.0 in the environment file for additional insight', returnType{i}]);
                        end
                        if isappdata(0, 'warning_79_suppressGuidanceMessage') == 0.0
                            fprintf(fidType(i), ['-> Guidance on obtaining an accurate FOS solution can be found in Section 8.3.4 of the Quick Fatigue Tool User Guide', returnType{i}]);
                        else
                            rmappdata(0, 'warning_79_suppressGuidanceMessage')
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 81.0
                        % Automatic Export
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Abaqus .odb file ''%s'' could not be found. Field data will not be exported', returnType{i}], getappdata(0, 'autoExport_modelDatabaseNotFound'));
                        fprintf(fidType(i), ['-> The absolute (full) path of the .odb file is required', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 82.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: A problem occurred while accessing the field data file ''%s''. Field data will not be exported', returnType{i}], getappdata(0, 'autoExport_fieldDataInacessible'));
                        fprintf(fidType(i), ['-> MATLAB error message: %s', returnType{i}], getappdata(0, 'autoExport_fieldDataErrorMessage'));
                        fprintf(fidType(i), ['-> File ID: %.0f', returnType{i}], getappdata(0, 'autoExport_fieldDataFID'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 83.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: A part instance name must be specified. Field data will not be exported', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 84.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: At least one field must be selected. Field data will not be exported', returnType{i}]);
                        fprintf(fidType(i), ['-> Fields are requested in the environment file (Application_Files\default)', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 85.0
                        switch getappdata(0, 'warning_061_number')
                            case 1.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: No matching position labels were found in the model output database. Field data will not be exported', returnType{i}]);
                                fprintf(fidType(i), ['-> Check the PART_INSTANCE definition in the job file', returnType{i}]);
                            case 2.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: An error occurred while retrieving the connectivity matrix. Field data will not be exported', returnType{i}]);
                            case 3.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: An error occurred while reading the connectivity matrix. Field data will not be exported', returnType{i}]);
                                fprintf(fidType(i), ['-> Check the PART_INSTANCE definition in the job file', returnType{i}]);
                            case 4.0
                                fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: An error occurred while reading the field data file. Field data will not be exported', returnType{i}]);
                            otherwise
                        end
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 86.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: An error occurred while writing field data to the output database. Field data will not be exported', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 87.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: Consistent element-node IDs for instance ''%s'' could not', returnType{i}], getappdata(0, 'warning_067_partInstance'));
                        fprintf(fidType(i), ['be found between the model output database and the field data (matching node IDs contain zero-valued indices)', returnType{i}]);
                        fprintf(fidType(i), ['-> This can occur when an invalid part instance is specified', returnType{i}]);
                        fprintf(fidType(i), ['-> Field data will not be exported', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 88.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The user-defined endurance in Group %.0f limit is undefined', returnType{i}], getappdata(0, 'enduranceLimitGroupNumber'));
                        fprintf(fidType(i), ['-> Assuming an endurance limit of %.3gMPa based on the Basquin material coefficients (Sf and b)', returnType{i}], getappdata(0, 'fatigueLimit'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 89.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: User-defined values of the endurance limit are not supported with the BS 7608 algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> Using a pre-calculated value of %.3gMPa based on the selected weld class (%s)', returnType{i}], getappdata(0, 'bs7608_s0'), getappdata(0, 'weldClass'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 90.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The material is defined as a cell', returnType{i}]);
                        fprintf(fidType(i), ['-> Cell definitions are only necessary when using multiple analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 91.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single material definition spans multiple analysis groups', returnType{i}]);
                        fprintf(fidType(i), ['-> The material %s will be used for each group', returnType{i}], getappdata(0, 'material'));
                        fprintf(fidType(i), ['-> If this is intentional, the above message can be ignored', returnType{i}]);
                    case 92.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The job file option GROUP appears to be defined as a character array rather than a cell', returnType{i}]);
                        fprintf(fidType(i), ['-> If a single group was specified, the analysis should be able to continue. However, GROUP must be defined as a', returnType{i}]);
                        fprintf(fidType(i), ['   cell if multiple groups have been specified', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 93.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Reading group %.0f (''%s'') as an item ID list', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 94.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Reading group %.0f (''%s'') as an FEA subset', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Please ensure that the position labels between the subset and the master dataset match', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 95.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Group %.0f (''%s'') was read as an FEA subset, but the data contents differ from the master dataset', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> The position IDs might not match those of the master dataset, and the group may not refer to the expected region of the model', returnType{i}]);
                        fprintf(fidType(i), ['-> This warning could be avoided by ensuring that the position labels between the subset and the master dataset match', returnType{i}]);
                        fprintf(fidType(i), ['-> This warning can be generated if the user modified the field output selection when defining the FEA subset for the group.', returnType{i}]);
                        fprintf(fidType(i), ['   If this is the case, and the data position was kept the same as the master dataset, the above warning can be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 96.0
                        switch getappdata(0.0, 'cleanAppData')
                            case 4.0
                                fprintf(fidType(i), [returnType{i}, '***NOTE: By default, Quick Fatigue Tool does not modify existing %%APPDATA%% variables. However, clearing the %%APPDATA%%', returnType{i}]);
                                fprintf(fidType(i), ['         between analyses reduces the risk of unexpected behaviour such as incorrect fatigue results and spurious crashes.', returnType{i}]);
                                fprintf(fidType(i), ['-> It is strongly recommended that you restart MATLAB between each analysis', returnType{i}]);
                                fprintf(fidType(i), ['-> Settings related to the %%APPDATA%% can be changed with the environment variable ''cleanAppData''', returnType{i}]);
                                setappdata(0, 'messageFileNotes', 1.0)
                            otherwise
                                fprintf(fidType(i), [returnType{i}, '***NOTE: Quick Fatigue Tool will clear all %%APPDATA%% in the current MATLAB session, including any user-defined variables.', returnType{i}]);
                                fprintf(fidType(i), ['-> To prevent this, set the environment variable ''cleanAppData'' to 4.0', returnType{i}]);
                                setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 97.0
                        if getappdata(0, 'suppress_ID97') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: When defining groups as FEA subsets it is not compulsory to include the field data', returnType{i}]);
                            fprintf(fidType(i), ['-> Provided that the data position between the FEA subset and the master dataset agree with each other,', returnType{i}]);
                            fprintf(fidType(i), ['   the group definition remains valid', returnType{i}]);
                            fprintf(fidType(i), ['-> However, if field data is included in the group definition, it can be used to resolve ambiguities in the', returnType{i}]);
                            fprintf(fidType(i), ['   event that the group contains duplicate IDs (which can arise if the group spans multiple regions)', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID97', 1.0)
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 98.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Reading group %.0f (''%s'') as an FEA subset', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 99.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: After processing group %.0f (''%s'') there are no remaining analysis items. Subsequent groups will be ignored', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 100.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: There are %.0f IDs in group %.0f (''%s'') which do not belong to the model. These items will be excluded from the analysis', returnType{i}], getappdata(0, 'unmatchedIDs'), getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Check the group definition file for errors', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 101.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: No matching IDs were found in group %.0f (''%s''). The entire group will be excluded from the analysis', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Check the group definition file for errors', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 102.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Group %.0f (''%s'') is a subset of a preceeding group. The entire group will be excluded from the analysis', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 103.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The DEFAULT group is empty and will not be used for analysis', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 105.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The surface finish definition is defined as a cell', returnType{i}]);
                        fprintf(fidType(i), ['-> Cell definitions are only necessary when using multiple analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 106.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single surface finish definition spans multiple analysis groups', returnType{i}]);
                        fprintf(fidType(i), ['-> The surface finish %s will be used for each group', returnType{i}], getappdata(0, 'ktDef'));
                        fprintf(fidType(i), ['-> If this is intentional, the above message can be ignored', returnType{i}]);
                    case 107.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The KT_DEF option contains %.0f references to surface finish files, but there are %.0f values in KT_CURVE', returnType{i}], getappdata(0, 'warning_107_numberOfKtFiles'), getappdata(0, 'warning_107_numberOfKtCurves'));
                        fprintf(fidType(i), ['-> The first value in KT_CURVE will be used for all surface finish files', returnType{i}]);
                        fprintf(fidType(i), ['-> Make sure that KT_CURVE references the correct number of surface finish files', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 108.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The KT_CURVE option contains %.0f defintions, but there is only one surface finish file defined by KT_DEF', returnType{i}], getappdata(0, 'warning_108_numberOfKtCurves'));
                        fprintf(fidType(i), ['-> The first value in KT_CURVE will be used for the surface finish definition', returnType{i}]);
                        fprintf(fidType(i), ['-> Make sure that KT_CURVE references the correct number of surface finish files', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 109.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The KT_CURVE option has been used in conjunction with KT_DEF, but there are no surface finish files defined by KT_DEF', returnType{i}]);
                        fprintf(fidType(i), ['-> KT_CURVE is used to reference a specific curve from a .kt/.ktx file, hence its use is not applicable when KT_DEF is used to define surface finish value(s) directly', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 110.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The SN_SCALE option is used with %.0f values, but there id only one analysis group', returnType{i}], length(getappdata(0, 'snScale')));
                        fprintf(fidType(i), ['-> The first value of SN_SCALE will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in SN_SCALE matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 111.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The RESIDUAL option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'residualStress')));
                        fprintf(fidType(i), ['-> The first value of RESIDUAL will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in RESIDUAL matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 112.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The RESIDUAL option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'residualStress')));
                        fprintf(fidType(i), ['-> The first value of RESIDUAL will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in RESIDUAL matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 113.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f duplicate IDs were found in group %s', returnType{i}], getappdata(0, 'numberOfDuplicateIDs'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> The locationon of these IDs in the model is ambiguous because the group was defined without its respective field data', returnType{i}]);
                        fprintf(fidType(i), ['-> The analysis may report results at incorrect locations', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 114.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: %.0f duplicate IDs were found in group %s', returnType{i}], getappdata(0, 'numberOfDuplicateIDs'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Field data from the group definition file was used to match all duplicate IDs', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 115.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f duplicate IDs were found in group %s', returnType{i}], getappdata(0, 'numberOfDuplicateIDs'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Field data from the group definition file was used to match some duplicate IDs, but others remain ambiguous', returnType{i}]);
                        fprintf(fidType(i), ['-> This indicates an inconsistency between the group and the master dataset', returnType{i}]);
                        fprintf(fidType(i), ['-> The analysis may report results at incorrect locations', returnType{i}]);
                        fprintf(fidType(i), ['-> If the loading is a multiple scale and combine or a dataset sequence, the field data from the group file must match the last file specified by the DATASET option', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 116.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: %.0f duplicate IDs were found in group %s', returnType{i}], getappdata(0, 'numberOfDuplicateIDs'), getappdata(0, 'message_groupFile'));
                        fprintf(fidType(i), ['-> Field data from the group definition file could not be used to match any of the duplicate IDs', returnType{i}]);
                        fprintf(fidType(i), ['-> This indicates an inconsistency between the group and the master dataset', returnType{i}]);
                        fprintf(fidType(i), ['-> The analysis may report results at incorrect locations', returnType{i}]);
                        fprintf(fidType(i), ['-> If the loading is a multiple scale and combine or a dataset sequence, the field data from the group file must match the last file specified by the DATASET option', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 117.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A list of duplicate IDs from the groups has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_group_duplicate_ids.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 118.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The proof stress is not defined for material %s (group %.0f)', returnType{i}], char(getappdata(0, 'message_groupMaterial')), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> The yield calculation requires a value of the proof stress to determine the strain limit energy', returnType{i}]);
                        fprintf(fidType(i), ['-> The yield calculation will not be performed for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 119.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Cyclic properties are not defined for material %s (group %.0f)', returnType{i}], getappdata(0, 'message_groupMaterial'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> The yield calculation requires values of the elastic modulus (E), the cyclic strain hardening coefficient (K) and the cyclic strain hardening exponent (n) to correct the principal stresses for effect of plasticity', returnType{i}]);
                        fprintf(fidType(i), ['-> The yield calculation will not be performed for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 120.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A list of yielded items has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_yielding_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 121.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Stress dataset ''%s'' is all zero', returnType{i}], getappdata(0, 'FOPEN_error_file'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 122.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: After processing group %.0f (''%s'') there are no remaining IDs in the model, and at least %.0f IDs in this group did not belong to the model. These items will be excluded from the analysis', returnType{i}], getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'), getappdata(0, 'unmatchedIDs'));
                        fprintf(fidType(i), ['-> Check the group definition file for errors', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 123.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The low frequency dataset has less than three history points', returnType{i}]);
                        fprintf(fidType(i), ['-> Zeros will be appended to the load history to allow superposition of high frequency data', returnType{i}]);
                        fprintf(fidType(i), ['-> The accuracy of the resultant dataset may be reduced', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 124.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF envelope is specified for more than one analysis group', returnType{i}]);
                            fprintf(fidType(i), ['-> The envelope definition will be propagated accross all analysis groups', returnType{i}]);
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 125.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In at least one group, the UTS is undefined. The following fields are unavailable:', returnType{i}]);
                            fprintf(fidType(i), ['-> FRFR, FRFH, FRFV, FRFW, SMXU', returnType{i}]);
                        
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 126.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The surface finish definition file ''%s'' (group %.0f) could not be processed because the UTS is not defined for this group', returnType{i}], getappdata(0, 'message_ktFile'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> A default value of Kt = 1.0 will be used for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 127.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The B2 option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'b2')));
                        fprintf(fidType(i), ['-> The first value of B2 will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in B2 matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 128.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The B2_NF option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'b2Nf')));
                        fprintf(fidType(i), ['-> The first value of B2_NF will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in B2_NF matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 129.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The UCS option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'ucs')));
                        fprintf(fidType(i), ['-> The first value of UCS will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in UCS matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 130.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The B2 option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'b2')));
                        fprintf(fidType(i), ['-> The first value of B2 will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in B2 matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 131.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The B2_NF option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'b2Nf')));
                        fprintf(fidType(i), ['-> The first value of B2_NF will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in B2_NF matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 132.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The UCS option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'ucs')));
                        fprintf(fidType(i), ['-> The first value of UCS will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in UCS matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 133.0
                        if (ispc == 1.0) && (ismac == 0.0)
                            [userView, systemView] = memory;
                            
                            fprintf(fidType(1.0), [returnType{1.0}, '***MEMORY INFORMATION', returnType{1.0}]);
                            fprintf(fidType(1.0), ['                 Physical memory:', returnType{1.0}]);
                            fprintf(fidType(1.0), ['                     Available: %.0f bytes', returnType{1.0}], systemView.PhysicalMemory.Available);
                            fprintf(fidType(1.0), ['                     Total: %.0f bytes', returnType{1.0}], systemView.PhysicalMemory.Total);
                            fprintf(fidType(1.0), ['                 Available memory for data: %.0f bytes', returnType{1.0}], userView.MemAvailableAllArrays);
                            fprintf(fidType(1.0), ['                 Reserved system memory for MATLAB: %.0f bytes', returnType{1.0}], userView.MemUsedMATLAB);
                            
                            break
                        end
                    case 134.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: PLEASE READ THE MANUAL ACCOMPANYING THIS RELEASE', returnType{i}]);
                        fprintf(fidType(i), ['-> For assistance or any other information please contact the author: louisvallance@hotmail.co.uk', returnType{i}]);
                        fprintf(fidType(i), ['-> Please rate this submission on the file exchange: http://www.mathworks.com/matlabcentral/fileexchange/51041-quick-fatigue-tool', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 135.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Non-default group settings are not compatible with the Uniaxial Stress-Life algorithm', returnType{i}]);
                        fprintf(fidType(i), ['-> Group definitions will be ignored', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 136.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single endurance limit value is specified for more than one analysis group', returnType{i}]);
                        fprintf(fidType(i), ['-> The endurance limit definition will be propagated accross all analysis groups', returnType{i}]);
                            
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 137.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single gamma value is specified for more than one analysis group', returnType{i}]);
                        fprintf(fidType(i), ['-> The gamma definition will be propagated accross all analysis groups', returnType{i}]);
                            
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 138.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: No hotspots were found for the specified design life (%.3g %s)', returnType{i}],  getappdata(0, 'dLife'), getappdata(0, 'loadEqUnits'));
                            
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 139.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: %.0f hotspots were located for the specified design life (%.3g %s)', returnType{i}],  getappdata(0, 'numberOfHotSpots'), getappdata(0, 'dLife'), getappdata(0, 'loadEqUnits'));
                        fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\input\\hotspots_%s.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        fprintf(fidType(i), ['-> This file can be used as an argument for the ITEMS option in the job file', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 140.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: History output has been written to ''%s\\Project\\output\\%s\\Data Files''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 141.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Field output has been written to ''%s\\Project\\output\\%s\\Data Files''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 142.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: MATLAB figures have been written to ''%s\\Project\\output\\%s\\MATLAB Figures''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 143.0
                        if getappdata(0, 'suppress_ID143') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: No hotspots were found in the file ''%s''', returnType{i}], getappdata(0, 'hotspotFile'));
                            fprintf(fidType(i), ['-> The hotspot file used must be ''%s\\Project\\input\\hotspots_<jobName>.dat'' generated by a previous analysis', returnType{i}], pwd);
                            fprintf(fidType(i), ['-> Hotspots are generated by setting HOTSPOT = 1.0 in the job file', returnType{i}]);
                            fprintf(fidType(i), ['-> All items will be analysed', returnType{i}]);
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                            
                            if i == X
                                setappdata(0, 'suppress_ID143', 1.0)
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 144.0
                        if getappdata(0, 'suppress_ID144') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The hotspot file ''%s'' is formatted incorrectly', returnType{i}], getappdata(0, 'hotspotFile'));
                            fprintf(fidType(i), ['-> The file must contain either a single column of item IDs, or be a hotspot file generated by a previous analysis', returnType{i}]);
                            fprintf(fidType(i), ['-> The hotspot file must be ''%s\\Project\\input\\hotspots_<jobName>.dat''', returnType{i}], pwd);
                            fprintf(fidType(i), ['-> Hotspot files are generated by setting HOTSPOT = 1.0 in the job file', returnType{i}]);
                            fprintf(fidType(i), ['-> All items will be analysed', returnType{i}]);
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                            
                            if i == X
                                setappdata(0, 'suppress_ID144', 1.0)
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 145.0
                        if getappdata(0, 'suppress_ID145') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The hotspot file ''%s'' could not be found', returnType{i}], getappdata(0, 'hotspotFile'));
                            fprintf(fidType(i), ['-> The hotspot file used must be ''%s\\Project\\input\\hotspots_<jobName>.dat'' generated by a previous analysis', returnType{i}], pwd);
                            fprintf(fidType(i), ['-> Hotspots are generated by setting HOTSPOT = 1.0 in the job file', returnType{i}]);
                            fprintf(fidType(i), ['-> All items will be analysed', returnType{i}]);
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                            
                            if i == X
                                setappdata(0, 'suppress_ID145', 1.0)
                            end
                            
                            setappdata(0, 'messageFileNotes', 1.0)
                        end
                    case 146.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The SN_KNOCK_DOWN option is used with %.0f files, but there is only one analysis group', returnType{i}], length(getappdata(0, 'snKnockDown')));
                        fprintf(fidType(i), ['-> The first S-N knock-down file will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of files in SN_KNOCK_DOWN matches the number of analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 147.0
                        % If the Kd file cannot be opened
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The S-N knock-down file ''%s'' could not be read', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> MException ID: %s', returnType{i}], getappdata(0, 'warning_147_exceptionMessage'));
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 148.0
                        % There are not exactly 2 columns in the kd file
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The data format of the S-N knock-down file ''%s'' is invalid', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> There must be exactly 2 columns in the .kd file, but %.0f columns were found', returnType{i}], getappdata(0, 'kdFile_numberOfColumns'));
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 149.0
                        % There are negative values in the kd file
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The S-N knock-down file ''%s'' contains negative values', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 150.0
                        % N-values are not increasing from top to bottom in the kd file
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The data format of the S-N knock-down file ''%s'' is invalid', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> The N-values must be increasing from top to bottom', returnType{i}]);
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 151.0
                        % At least one group item was removed during nodal elimination
                        fprintf(fidType(i), [returnType{i}, '***NOTE: %.0f analysis items from group %.0f (''%s'') were removed during nodal elimination', returnType{i}], getappdata(0, 'numberOfEliminatedItems'), getappdata(0, 'currentGroupNumber'), getappdata(0, 'currentGroup'));
                        [~, groupNameShort, ~] = fileparts(getappdata(0, 'currentGroup'));
                        fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\output\\%s\\Data Files\\%s_eliminated_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'), groupNameShort);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 152.0
                        % All group items were removed during nodal elimination
                        fprintf(fidType(i), [returnType{i}, '***NOTE: All %.0f analysis items were removed from group %.0f (''%s'') during nodal elimination', returnType{i}], getappdata(0, 'numberOfEliminatedItems'), getappdata(0, 'currentGroupNumber'), getappdata(0, 'currentGroup'));
                        [~, groupNameShort, ~] = fileparts(getappdata(0, 'currentGroup'));
                        fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\output\\%s\\Data Files\\%s_eliminated_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'), groupNameShort);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 153.0
                        % There are duplicate position IDs in the model
                        fprintf(fidType(i), [returnType{i}, '***WARNING: There are %.0f duplicate position IDs in the model', returnType{i}], getappdata(0, 'duplicateMainIDs'));
                        fprintf(fidType(i), ['-> Fatigue results may be quoted at incorrect locations', returnType{i}]);
                        fprintf(fidType(i), ['-> This can happen when there are multiple regions in the model', returnType{i}]);
                        
                        if (getappdata(0, 'autoExport_ODB') == 1.0) && (isempty(getappdata(0, 'outputDatabase')) == 0.0)
                            fprintf(fidType(i), ['-> Field data visualization in the Abaqus output database (.odb) file may be incorrect', returnType{i}]);
                        end
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 154.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Strain-based Brown-Miller algorithm has not yet been implemented', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 155.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Principal Strain algorithm has not yet been implemented', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 156.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Maximum Shear Strain algorithm has not yet been implemented', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 157.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Modified Manson McKnight (Filipini) algorithm has not yet been implemented', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 158.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Uniaxial Strain-Life algorithm has not yet been implemented', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used instead', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 159.0
                        if getappdata(0, 'suppress_ID159') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: After applying the Morrow mean stress correction, some cycles are negative', returnType{i}]);
                            fprintf(fidType(i), ['-> The Morrow mean stress correction is not defined for mean stress at or above the fatigue strength coefficient (Sf'')', returnType{i}]);
                            fprintf(fidType(i), ['-> Non-fatigue failure will be assumed at the affected analysis items', returnType{i}]);
                            fprintf(fidType(i), ['-> Check the validity of the loading', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID159', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 160.0
                        if getappdata(0, 'suppress_ID160') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In parts of the model, the mean stress exceeds the proof stress', returnType{i}]);
                            fprintf(fidType(i), ['-> Non-fatigue failure will be assumed at these locations', returnType{i}]);
                            fprintf(fidType(i), ['-> This message is printed at the first occurrence of an overload only', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID160', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 161.0
                        if getappdata(0, 'suppress_ID161') == 0.0
                            goodmanLimit = getappdata(0, 'goodmanMeanStressLimit');
                            if goodmanLimit == -1.0
                                goodmanLimit = getappdata(0, 'uts');
                            elseif goodmanLimit == -2.0
                                goodmanLimit = getappdata(0, 'twops');
                            end
                            
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In parts of the model, the mean stress exceeds the Goodman limit stress (%.3fMPa)', returnType{i}], goodmanLimit);
                            fprintf(fidType(i), ['-> Non-fatigue failure will be assumed at these locations', returnType{i}]);
                            fprintf(fidType(i), ['-> This message is printed at the first occurrence of an overload only. Therefore, if the Goodman limit stress was set to the UTS', returnType{i}]);
                            fprintf(fidType(i), ['   or the yield stress of the material, the quoted Goodman limit stress references the group in which the first overload occurred', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID161', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 162.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Poisson''s ratio is not defined for material %s (group %.0f)', returnType{i}], getappdata(0, 'message_groupMaterial'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> The total strain energy criterion requires a value of the Poisson''s ratio', returnType{i}]);
                        fprintf(fidType(i), ['-> The yield calculation will not be performed for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 163.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The worst stress range (S1 - S3) in the model is %.3fMPa at item %.0f.%.0f in group %.0f (''%s'')', returnType{i}], getappdata(0, 'peekAnalysis_worstStressRange'),getappdata(0, 'mainID'), getappdata(0, 'subID'), getappdata(0, 'peekGroup'), getappdata(0, 'peekAnalysis_groupName'));
                        
                        if getappdata(0, 'multiplePeekItems') == 1.0
                            setappdata(0, 'multiplePeekItems', 0.0)
                            
                            fprintf(fidType(i), ['-> This is the first of %.0f items encountered in the model which have the same stress range. A list of all peek items has been written to', returnType{i}], getappdata(0, 'nPeekItems'));
                            fprintf(fidType(i), ['   ''%s\\Project\\output\\%s\\Data Files\\peek_items.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        end
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 164.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Load proportionality checking is not available for Findley''s method. The user-defined step size of %.0f will be used for the whole model', returnType{i}], getappdata(0, 'stepSize'));
                    case 165.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Goodman limit stress (PROOF) could not be set for group %.0f because the proof stress is undefined for that group', returnType{i}], getappdata(0, 'message_165_group'));
                        fprintf(fidType(i), ['-> The UTS will be used instead', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 166.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Unable to obtain the worst item stress tensor from the worst item ID', returnType{i}]);
                        fprintf(fidType(i), ['-> MATLAB error message: %s', returnType{i}], getappdata(0, 'message_166_exceptionMessage'));
                        fprintf(fidType(i), ['-> Check the stress dataset file(s) for duplicate elements and/or nodes', returnType{i}]);
                        fprintf(fidType(i), ['-> Fatigue results may be reported at incorrect locations', returnType{i}]);
                    case 167.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The stress dataset contains %.0f duplicate analysis items', returnType{i}], getappdata(0, 'message_167_nDuplicateItems'));
                        fprintf(fidType(i), ['-> A list of these items has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_model_duplicate_ids.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 168.0
                        N = getappdata(0, 'numberOfNodes') - getappdata(0, 'nodalEliminationRemovedItems');
                        fprintf(fidType(i), [returnType{i}, '***NOTE: There are %.0f items in the model (%.0f will be analysed)', returnType{i}], getappdata(0, 'message168_N'), N);
                        
                        if (getappdata(0, 'autoExport_ODB') == 1.0) && (N == 1.0) && (exist(getappdata(0, 'outputDatabase'), 'file') == 2.0) && (isempty(getappdata(0, 'partInstance')) == 0.0) && (getappdata(0, 'outputField') == 1.0)
                            fprintf(fidType(i), ['-> Results export to the output database file might not be possible', returnType{i}]);
                        end
                    case 169.0
                        if isappdata(0, 'message169_environmentFileName') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: Reading settings from local environment file ''%s''', returnType{i}], getappdata(0, 'message169_environmentFileName'));
                            fprintf(fidType(i), ['-> Settings in the local environment file supercede those in the global environment file', returnType{i}]);
                            rmappdata(0, 'message169_environmentFileName')
                        end
                    case 170.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The environment variable ''modifiedGoodman'' has been defined as a cell, but this is not recommended here. Only numeric values are supported so the definition should be a numeric array', returnType{i}]);
                    case 171.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The environment variable ''userWalkerGamma'' has been defined as a cell, but this is not recommended here. Only numeric values are supported so the definition should be a numeric array', returnType{i}]);
                    case 172.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single Goodman envelope is specified for more than one analysis group', returnType{i}]);
                        fprintf(fidType(i), ['-> The envelope definition will be propagated accross all analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 173.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single Goodman limit stress is specified for more than one Goodman envelope', returnType{i}]);
                        fprintf(fidType(i), ['-> The limit stress definition will be propagated accross all analysis groups', returnType{i}]);
                        
                        setappdata(0, 'messageFileNotes', 1.0)
                    case 174.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The Goodman limit stress definition for group %.0f could not be recognised', returnType{i}], getappdata(0, 'limitStressGroup'));
                        fprintf(fidType(i), ['-> The material UTS will be used for this group', returnType{i}]);
                    case 175.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Stress-Life data is not enabled (USE_SN = 0). The following job file options will be ignored: SN_SCALE, SN_KNOCK_DOWN', returnType{i}]);
                    case 176.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Findley''s Method does not require the user to specify a mean stress correction. The following job file option will be ignored: MS_CORRECTION', returnType{i}]);
                    case 177.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The NASALIFE algorithm uses the Walker mean stress correction. The following job file option will be ignored: MS_CORRECTION', returnType{i}]);
                    case 178.0
                        % If the user Rz value is less than the lowest Rz value
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The user-specified Rz value of %.3g for ''%s'' (group %.0f) is less than the smallest available Rz value', returnType{i}], getappdata(0, 'message_rzValue'), getappdata(0, 'message_ktFile'), getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> Kt = 1.0 will be assumed', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case  179.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface ERROR: No matching element in the field data could be found for element %.0f in the connectivity matrix', returnType{i}], getappdata(0, 'warning_179_problemElement'));
                        fprintf(fidType(i), ['-> Field data will not be exported', returnType{i}]);
                    case 180.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: ODB Interface WARNING: %.0f elements appear to be collapsed or degenerate (the element nodes are not unique)', returnType{i}], getappdata(0, 'warning_180_numberOfCollapsedElements'));
                        fprintf(fidType(i), ['-> If these elements belong to a crack seam, they should not be used for fatigue analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> If the model does not contain this kind of element, check the field data for errors', returnType{i}]);
                        fprintf(fidType(i), ['-> A list of these elements has been written to ''%s\\Project\\output\\%s\\Data Files\\warn_degenerate_elements.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                    case 181.0
                        if getappdata(0, 'suppress_ID181') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: An ambiguity was encountered while determining the element type for one or more regions in the model', returnType{i}]);
                            elementType = getappdata(0, 'message_181_elementType');
                            if elementType == 0.0
                                fprintf(fidType(i), ['-> The results at these locations are assumed to be 3D stress at an unknown element position, based on the value of PLANE_STRESS = 0.0 in the job file', returnType{i}]);
                                fprintf(fidType(i), ['-> If the model contains plane stress elements with results at element-nodal or integration point element positions, it is likely that they have been incorrectly identified as 3D stress', returnType{i}]);
                                fprintf(fidType(i), ['-> If this is the case, set PLANE_STRESS = 1.0 to resolve the ambiguity', returnType{i}]);
                            else
                                fprintf(fidType(i), ['-> The results at these locations are assumed to be plane stress at element-nodal or integration point element positions, based on the value of PLANE_STRESS = 1.0 in the job file', returnType{i}]);
                                fprintf(fidType(i), ['-> If the model does not contain plane stress elements, set PLANE_STRESS = 0.0 to correctly resolve the ambiguity. The ambiguous region(s) will be interpreted as 3D stress at an unknown element position', returnType{i}]);
                            end
                            fprintf(fidType(i), ['-> If the dataset(s) are defined as stress tensors without position labels (no element information), then this warning can be ignored', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID181', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 182.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: When load history pre-gating is active and the loading contains high frequency datasets, the resulting loading may be adversely affected by the gating process', returnType{i}]);
                        fprintf(fidType(i), ['-> The user is advised to verify the loading by checking the contents of ''h-output-tensor.dat''. If the resulting load is unrealistic,', returnType{i}]);
                        fprintf(fidType(i), ['   then load history pre-gating should be disabled by setting gateHistories = 0.0 in the environment file', returnType{i}]);
                        if getappdata(0, 'gateTensors') == 0.0
                            fprintf(fidType(i), ['-> Tensor gating may be used instead. This form of gating does not affect the high frequency datasets and is more accurate than load', returnType{i}]);
                            fprintf(fidType(i), ['   history pre-gating. Tensor gating is enabled by setting gateTensors = 1.0 in the environment file', returnType{i}]);
                        end
                    case 183.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Load history pre-gating and tensor gating are both active', returnType{i}]);
                        fprintf(fidType(i), ['-> Enabling both gating criteria simultaneously may affect the accuracy of the fatigue results', returnType{i}]);
                    case 184.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Whenever CONTINUE_FROM is used, field output is automatically written', returnType{i}]);
                        fprintf(fidType(i), ['The following job file option will be ignored:', returnType{i}]);
                        fprintf(fidType(i), ['-> OUTPUT_FIELD', returnType{i}]);
                    case 185.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Whenever results are exported to an output database containing steps written by Quick Fatigue Tool, if the step name is not specified then the default step name may clash with existing steps', returnType{i}]);
                        
                        if isappdata(0, 'writeMessage_185') == 1.0
                            rmappdata(0, 'writeMessage_185')
                        end
                    case 186.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: An existing step has been specified for automatic ODB export', returnType{i}]);
                        fprintf(fidType(i), ['The following job file option will be ignored:', returnType{i}]);
                        fprintf(fidType(i), ['-> FEA_PROCEDURE', returnType{i}]);
                        
                        if isappdata(0, 'writeMessage_186') == 1.0
                            rmappdata(0, 'writeMessage_186')
                        end
                    case 187.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The requested algorithm is not available', returnType{i}]);
                        fprintf(fidType(i), ['-> The default algorithm will be used', returnType{i}]);
                    case 188.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Neither the requested nor the default algorithm is available', returnType{i}]);
                        fprintf(fidType(i), ['-> The Stress-based Brown-Miller algorithm will be used', returnType{i}]);
                    case 189.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The field data contains %.0f ambiguous items which map to more than one item from the previous job', returnType{i}], getappdata(0, 'message_189_duplicateItems'));
                        fprintf(fidType(i), ['-> These items will be matched to the first occurrence of the item from the previous job. Subsequent ocurrences will be treated as separate items', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 190.0
                        if getappdata(0, 'suppress_ID190') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In some parts of the model, the Brown-Miller damage parameter (either normal or shear) had to be resampled', returnType{i}]);
                            fprintf(fidType(i), ['-> Fatigue results may be innacurate at these locations', returnType{i}]);
                            fprintf(fidType(i), ['-> This warning can be avoided by setting rainflowMode = 1.0 in the environment file', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID190', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 191.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Quick Fatigue Tool encountered an error while attempting to copy the field output file', returnType{i}]);
                        fprintf(fidType(i), ['-> MATLAB error message: %s', returnType{i}], getappdata(0, 'message_191_message'));
                        fprintf(fidType(i), ['-> Analysis continuation was aborted', returnType{i}]);
                    case 192.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF mean stress (tensile) normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF mean stress (tensile) normalization parameter definition will be propagated accross all user-defined FRF envelope definitions', returnType{i}]);
                        end
                    case 193.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The definitin of frfNormParamMeanT for group %.0f could not be recognised', returnType{i}], getappdata(0, 'message_193_group'));
                            fprintf(fidType(i), ['-> The material UTS will be used by default', returnType{i}]);
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 194.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF mean stress (compressive) normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF mean stress (compressive) normalization parameter definition will be propagated accross all user-defined FRF envelope definitions', returnType{i}]);
                        end
                    case 195.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF stress amplitude normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF stress amplitude normalization parameter definition will be propagated accross all user-defined FRF envelope definitions', returnType{i}]);
                        end
                    case 196.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The definitin of frfNormParamMeanC for group %.0f could not be recognised', returnType{i}], getappdata(0, 'message_196_group'));
                            fprintf(fidType(i), ['-> The material UCS (or UTS) will be used by default', returnType{i}]);
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 197.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: An exception occurred while interpolating the user FRF data for group %.0f', returnType{i}], getappdata(0, 'message_197_group'));
                        fprintf(fidType(i), ['-> MATLAB error message: %s', returnType{i}], getappdata(0, 'message_197_exception'));
                        fprintf(fidType(i), ['-> FRF data will not be calculated for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 198.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The definitin of frfNormParamAmp for group %.0f could not be recognised', returnType{i}], getappdata(0, 'message_198_group'));
                            fprintf(fidType(i), ['-> The material fatigue limit stress will be used by default', returnType{i}]);
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 199.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In at least one group, the proof stress is undefined. The following field is unavailable:', returnType{i}]);
                            fprintf(fidType(i), ['-> SMXP', returnType{i}]);
                        end
                    case 200.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF mean stress (tensile) normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF mean stress (tensile) normalization parameter definition will be propagated accross all user-defined FRF envelope definitions using the parameter ''UTS''', returnType{i}]);
                        end
                    case 201.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF mean stress (compressive) normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF mean stress (compressive) normalization parameter definition will be propagated accross all user-defined FRF envelope definitions using the parameter ''UCS''', returnType{i}]);
                        end
                    case 202.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: A single FRF stress amplitude normalization parameter is specified for more than one user-defined FRF envelope', returnType{i}]);
                            fprintf(fidType(i), ['-> The FRF stress amplitude normalization parameter definition will be propagated accross all user-defined FRF envelope definitions using the paramter ''LIMIT''', returnType{i}]);
                        end
                    case 203.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Field output from Uniaxial Stress-Life analyses is not supported by the ODB interface', returnType{i}]);
                        fprintf(fidType(i), ['-> Field data will not be written to the output database', returnType{i}]);
                    case 204.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Automatic export for Abaqus .odb files is enabled, but the field data contains only one analysis item', returnType{i}]);
                        fprintf(fidType(i), ['-> For element-nodal (or integration point) results, every node (or integration point) belonging to the element must be defined', returnType{i}]);
                        fprintf(fidType(i), ['-> For unique nodal (or centroid) results, at least two nodes (or centroids) must be defined', returnType{i}]);
                        fprintf(fidType(i), ['-> Results export will continue, but the ODB interface may exit with errors', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 205.0
                        if getappdata(0, 'suppress_ID205') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The monotonic stress excursion of %.3gMPa resulted in a first strain interpolation point of %.3g, but the calculated elastic strain is only %.3g', returnType{i}], getappdata(0, 'message_205_sigma'), getappdata(0, 'message_205_strain'), getappdata(0, 'message_205_epsilon'));
                            fprintf(fidType(i), ['-> The stress is so large that it exceeds the precision of the linear interpolation algorithm', returnType{i}]);
                            fprintf(fidType(i), ['-> The yield calculation is unlikely to produce reliable results', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID205', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 206.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The maximum stress range [MIN(S3) -> MAX(S1)] in group %.0f (''%s'') is [%.4gMPa -> %.4gMPa] at items [%s -> %s]', returnType{i}], getappdata(0, 'message_206_groupNumber'), getappdata(0, 'message_206_groupName'), getappdata(0, 'message_206_minStress'), getappdata(0, 'message_206_maxStress'), getappdata(0, 'message_206_minStressID'), getappdata(0, 'message_206_maxStressID'));
                    case 207.0
                        alphaMin = getappdata(0, 'message_207_alphaMin');
                        alphaMax = getappdata(0, 'message_207_alphaMax');
                        
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The item with the largest stress in group %.0f (''%s'') has a biaxiality ratio (alpha) in the range of [%.4g -> %.4g] at item %s', returnType{i}], getappdata(0, 'message_206_groupNumber'), getappdata(0, 'message_206_groupName'), alphaMin, alphaMax, getappdata(0, 'message_207_alphaID'));
                        
                        param = getappdata(0, 'stressInvariantParameter');
                        
                        principalCondition = (alphaMin >= -1.0 && alphaMin <= 0.0) && (alphaMax >= -1.0 && alphaMax <= 0.0);
                        trescaCondition = (alphaMin >= 0.0 && alphaMin <= 1.0) && (alphaMax >= 0.0 && alphaMax <= 1.0);
                        
                        if param > 0.0
                            switch param
                                case 1.0 % VON MISES
                                    if (alphaMin ~= 0.0 && alphaMin ~= 1.0) || (alphaMax ~= 0.0 && alphaMax ~= 1.0)
                                        fprintf(fidType(i), [returnType{i}, '***WARNING: The von Mises stress as a damage parameter is only valid for uniaxial (alpha = 0) and equibiaxial (alpha = 1) stresses', returnType{i}]);
                                        if principalCondition == true
                                            fprintf(fidType(i), ['-> The principal stress is recommended based on the range of alpha (set stressInvariantParameter = 2.0 in the environment file)', returnType{i}]);
                                        elseif trescaCondition == true
                                            fprintf(fidType(i), ['-> The Tresca stress is recommended based on the range of alpha (set stressInvariantParameter = 4.0 in the environment file)', returnType{i}]);
                                        else
                                            fprintf(fidType(i), ['-> The Stress Invariant Parameter algorithm is not recommended. Consider a biaxial algorithm instead', returnType{i}]);
                                        end
                                        
                                        setappdata(0, 'messageFileWarnings', 1.0)
                                    else
                                        fprintf(fidType(i), ['-> The user-specified stress invariant parameter (von Mises) is valid for the given range of alpha', returnType{i}]);
                                    end
                                case 2.0 % PRINCIPAL
                                    if (alphaMin < -1.0 || alphaMin > 0.0) || (alphaMax < -1.0 || alphaMax > 0.0)
                                        fprintf(fidType(i), [returnType{i}, '***WARNING: The principal stress as a damage parameter is only valid for (-1 <= alpha <= 0)', returnType{i}]);
                                        
                                        if alphaMin == 1.0 && alphaMax == 1.0
                                            fprintf(fidType(i), ['-> The Tresca or the von Mises stress are recommended based on the range of alpha (set stressInvariantParameter = [4.0 | 1.0] in the environment file)', returnType{i}]);
                                        elseif trescaCondition == true
                                            fprintf(fidType(i), ['-> The Tresca stress is recommended based on the range of alpha (set stressInvariantParameter = 4.0 in the environment file)', returnType{i}]);
                                        else
                                            fprintf(fidType(i), ['-> The Stress Invariant Parameter algorithm is not recommended. Consider a biaxial algorithm instead', returnType{i}]);
                                        end
                                        
                                        setappdata(0, 'messageFileWarnings', 1.0)
                                    else
                                        fprintf(fidType(i), ['-> The user-specified stress invariant parameter (principal) is valid for the given range of alpha', returnType{i}]);
                                    end
                                case 3.0 % HYDROSTATIC
                                    if (alphaMin < -1.0 || alphaMin > 0.0) || (alphaMax < -1.0 || alphaMax > 0.0)
                                        fprintf(fidType(i), [returnType{i}, '***WARNING: The hydrostatic (pressure) stress as a damage parameter is only valid for (-1 <= alpha <= 0)', returnType{i}]);
                                        
                                        if alphaMin == 1.0 && alphaMax == 1.0
                                            fprintf(fidType(i), ['-> The Tresca or the von Mises stress are recommended based on the range of alpha (set stressInvariantParameter = [4.0 | 1.0] in the environment file)', returnType{i}]);
                                        elseif trescaCondition == true
                                            fprintf(fidType(i), ['-> The Tresca stress is recommended based on the range of alpha (set stressInvariantParameter = 4.0 in the environment file)', returnType{i}]);
                                        else
                                            fprintf(fidType(i), ['-> The Stress Invariant Parameter algorithm is not recommended. Consider a biaxial algorithm instead', returnType{i}]);
                                        end
                                        
                                        setappdata(0, 'messageFileWarnings', 1.0)
                                    else
                                        fprintf(fidType(i), ['-> The user-specified stress invariant parameter (principal) is valid for the given range of alpha', returnType{i}]);
                                    end
                                case 4.0 % TRESCA
                                    if (alphaMin < 0.0 || alphaMin > 1.0) || (alphaMax < 0.0 || alphaMax > 1.0)
                                        fprintf(fidType(i), [returnType{i}, '***WARNING: The Tresca stress as a damage parameter is only valid for (0 <= alpha <= 1)', returnType{i}]);
                                        if principalCondition == true
                                            fprintf(fidType(i), ['-> The principal stress is recommended based on the range of alpha (set stressInvariantParameter = 2.0 in the environment file)', returnType{i}]);
                                        else
                                            fprintf(fidType(i), ['-> The Stress Invariant Parameter algorithm is not recommended. Consider a biaxial algorithm instead', returnType{i}]);
                                        end
                                        
                                        setappdata(0, 'messageFileWarnings', 1.0)
                                    else
                                        fprintf(fidType(i), ['-> The user-specified stress invariant parameter (Tresca) is valid for the given range of alpha', returnType{i}]);
                                    end
                            end
                        end
                    case 208.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: In general, the use of stress invariants as a damage parameter is not recommended. The user should exercise extreme caution when using stress invariant parameters for fatigue analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> The loading should be limited to uniaxial and biaxial stresses (triaxial stresses should be avoided)', returnType{i}]);
                        fprintf(fidType(i), ['-> The biaxiality ratio should be in the range of (-1 <= alpha <= 1)', returnType{i}]);
                        fprintf(fidType(i), ['-> For all other problems, a multiaxial algorithm should be used instead', returnType{i}]);
                    case 209.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: In at least one analysis group, a suitable stress invariant parameter could be found', returnType{i}]);
                        fprintf(fidType(i), ['-> The %s stress will be used by default for all analysis groups', returnType{i}], getappdata(0, 'preferredParameter'));
                        fprintf(fidType(i), ['-> The user is advised to analyse each group separately with an appropriate stress invariant parameter using CONTINUE_FROM', returnType{i}]);
                        fprintf(fidType(i), ['-> If a suitable stress invariant parameter cannot be found, a biaxial fatigue analysis algorithm is recommended instead', returnType{i}]);
                        fprintf(fidType(i), ['-> Consult Section 4.8 of the Quick Fatigue Tool User Guide for more details', returnType{i}]);
                    case 210.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The recommended stress invariant parameter is different between two or more analysis groups', returnType{i}]);
                        fprintf(fidType(i), ['-> The %s stress will be used by default for all analysis groups', returnType{i}], getappdata(0, 'preferredParameter'));
                        fprintf(fidType(i), ['-> The user is advised to analyse each group separately with an appropriate stress invariant parameter using CONTINUE_FROM', returnType{i}]);
                        fprintf(fidType(i), ['-> Consult Section 4.8 of the Quick Fatigue Tool User Guide for more details', returnType{i}]);
                    case 211.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: A suitable stress invariant parameter could not be found in any analysis group', returnType{i}]);
                        fprintf(fidType(i), ['-> The %s stress will be used by default for all analysis groups', returnType{i}], getappdata(0, 'preferredParameter'));
                        fprintf(fidType(i), ['-> The Invariant Stress Parameter analysis algorithm is not recommended. Consider using a biaxial analysis algorithm instead', returnType{i}]);
                    case 212.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The %s stress will be used as the stress invariant parameter based on the range of alpha', returnType{i}], getappdata(0, 'preferredParameter'));
                    case 213.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: A suitable stress invariant parameter could not be found', returnType{i}]);
                        fprintf(fidType(i), ['-> The %s stress will be used based on the range of alpha', returnType{i}], getappdata(0, 'preferredParameter'));
                        fprintf(fidType(i), ['-> The Invariant Stress Parameter analysis algorithm is not recommended. Consider using a biaxial analysis algorithm instead', returnType{i}]);
                    case 214.0
                        material = getappdata(0, 'message_214_groupMaterial');
                        material(end - 3.0:end) = [];
                        
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The yield calculation failed in group %.0f (''%s'')', returnType{i}], getappdata(0, 'message_214_groupNumber'), getappdata(0, 'message_214_groupName'));
                        fprintf(fidType(i), ['-> The material properties in ''%s'' may be incorrectly defined:', returnType{i}], material);
                        fprintf(fidType(i), ['-> Young''s Modulus (E) = %.3fMPa', returnType{i}], getappdata(0, 'message_214_E'));
                        fprintf(fidType(i), ['-> Strain hardening coefficient (K) = %.3fMPa', returnType{i}], getappdata(0, 'message_214_K'));
                        fprintf(fidType(i), ['-> Strain hardening exponent (n) = %f', returnType{i}], getappdata(0, 'message_214_N'));
                        fprintf(fidType(i), ['-> The yield calculation will be skipped for this group', returnType{i}], getappdata(0, 'message_214_N'));
                    case 215.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The FOS accuracy for each analysis item has been written to ''%s\\Project\\output\\%s\\Data Files\\fos_accuracy.dat''', returnType{i}], pwd, getappdata(0, 'jobName'));
                    case 216.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The NOTCH_SENSITIVITY_CONSTANT option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'notchSensitivityConstant')));
                        fprintf(fidType(i), ['-> The first value of NOTCH_SENSITIVITY_CONSTANT will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in NOTCH_SENSITIVITY_CONSTANT matches the number of analysis groups', returnType{i}]);
                    case 217.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The NOTCH_SENSITIVITY_CONSTANT option is used with %.0f values, but there id only one analysis group', returnType{i}], length(getappdata(0, 'notchSensitivityConstant')));
                        fprintf(fidType(i), ['-> The first value of NOTCH_SENSITIVITY_CONSTANT will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in NOTCH_SENSITIVITY_CONSTANT matches the number of analysis groups', returnType{i}]);
                    case 218.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The NOTCH_ROOT_RADIUS option is used with %.0f values, but there is only one analysis group', returnType{i}], length(getappdata(0, 'notchRootRadius')));
                        fprintf(fidType(i), ['-> The first value of NOTCH_ROOT_RADIUS will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in NOTCH_ROOT_RADIUS matches the number of analysis groups', returnType{i}]);
                    case 219.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The NOTCH_ROOT_RADIUS option is used with %.0f values, but there id only one analysis group', returnType{i}], length(getappdata(0, 'notchRootRadius')));
                        fprintf(fidType(i), ['-> The first value of NOTCH_ROOT_RADIUS will be used for the analysis', returnType{i}]);
                        fprintf(fidType(i), ['-> Ensure that the number of values in NOTCH_ROOT_RADIUS matches the number of analysis groups', returnType{i}]);
                    case 220.0
                        if getappdata(0, 'suppress_ID220') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In at least one group the notch sensitivity factor and/or notch root radius is undefined', returnType{i}], getappdata(0, 'message_205_sigma'), getappdata(0, 'message_205_strain'), getappdata(0, 'message_205_epsilon'));
                            fprintf(fidType(i), ['-> The default Peterson approximation will be used instead', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID220', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 221.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The option WELD_CLASS is specified with a single argument. By default, Quick Fatigue Tool assumes', returnType{i}]);
                        fprintf(fidType(i), ['         that the user Sr-N curve is specified in a column-wise fashion. This behaviour can be overridden by', returnType{i}]);
                        fprintf(fidType(i), ['         specifying WELD_CLASS = {<userCurveFile>, ''ROW''}', returnType{i}]);
                    case 222.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: One or more virtual strain gauges were defined, but no gauge orientation was specified', returnType{i}]);
                        fprintf(fidType(i), ['-> An orientation is required, e.g. GAUGE_ORIENTATION = {[0.0, 45.0, 45.0]}', returnType{i}]);
                        fprintf(fidType(i), ['-> Virtual strain gauges will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 223.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The number of virtual strain gauge definitions does not match the number of gauge orientations', returnType{i}]);
                        fprintf(fidType(i), ['-> Multiple orientations are specified as a cell of arrays, e.g. GAUGE_ORIENTATION = {[0.0, 45.0, 45.0], [30.0, 60.0, 60.0]}', returnType{i}]);
                        fprintf(fidType(i), ['-> Virtual strain gauges will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 224.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Virtual strain gauge #%.0f (item %.0f.%.0f) does not exist in the model', returnType{i}], getappdata(0, 'vGaugeNumber'), getappdata(0, 'vGaugeMainID'),getappdata(0, 'vGaugeSubID'));
                        fprintf(fidType(i), ['-> This gauge will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 225.0
                        if isempty(getappdata(0, 'vGauge_E')) == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The Young''s Modulus (E) is not defined for virtual strain gauge #%.0f', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        end
                        if isempty(getappdata(0, 'vGauge_v')) == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The Poisson''s ratio (v) is not defined for virtual strain gauge #%.0f', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        end
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Virtual strain gauge #%.0f will not be analysed', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 226.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Constant amplitude loading is detected with more than 3 history points', returnType{i}]);
                        fprintf(fidType(i), ['-> For efficiency, only the first two points (one cycle) in the loading will be analysed', returnType{i}]);
                        fprintf(fidType(i), ['-> The value of REPEATS has been automatically adjusted to %.0f', returnType{i}], getappdata(0, 'repeats'));
                    case 227.0
                        if isempty(getappdata(0, 'vGauge_kp')) == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The cyclic strain hardening coefficient (kp) is not defined for virtual strain gauge #%.0f', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        end
                        if isempty(getappdata(0, 'vGauge_np')) == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The cyclic strain hardening exponent (np) is not defined for virtual strain gauge #%.0f', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        end
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The strains for virtual strain gauge #%.0f will not be corrected for the effect of plasticity. Results will be inaccurate for inelastic stresses', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 228.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The definition of virtual gauge #%.0f was not recognised', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        fprintf(fidType(i), ['-> This gauge will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 229.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The definition of virtual strain gauge #%.0f refers to more than one item in the model', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        fprintf(fidType(i), ['-> The first instance of this item will be used', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 230.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: Virtual strain gauge locations must be defiend as a cell', returnType{i}]);
                        fprintf(fidType(i), ['-> e.g. GAUGE_LOCATION = {''<mainID_1>.<subID_1>'', ''<mainID_2>.<subID_2>'',..., ''<mainID_n>.<subID_n>''}', returnType{i}]);
                        fprintf(fidType(i), ['-> Virtual strain auges will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 231.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Out-of-plane stresses were found at virtual strain gauge #%.0f (item %.0f.%.0f)', returnType{i}], getappdata(0, 'vGaugeNumber'), getappdata(0, 'vGaugeMainID'),getappdata(0, 'vGaugeSubID'));
                        fprintf(fidType(i), ['-> These stresses will not be detected by the gauge', returnType{i}]);
                        fprintf(fidType(i), ['-> Plane stress elements are recommended for best accuracy', returnType{i}]);
                    case 232.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The definition of virtual strain gauge #%.0f appears to reference a single position ID', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        fprintf(fidType(i), ['-> Both the main ID and the sub ID must be specified and separated by a decimal point', returnType{i}]);
                        if getappdata(0, 'algorithm') == 3.0
                            fprintf(fidType(i), ['-> For Uniaxial Stress-Life analysis, the main and sub IDs are always 1: GAUGE_LOCATION = {''1.1''}', returnType{i}]);
                        else
                            fprintf(fidType(i), ['-> e.g. If the gauge position is integration point or element-nodal, the main ID is the element number and the sub ID is the integration point/node number: GAUGE_LOCATION = {''7.3''}', returnType{i}]);
                            fprintf(fidType(i), ['-> e.g. If the gauge position is centroidal or unique nodal, the main ID is the centroid/node number. The sub ID is always 1: GAUGE_LOCATION = {''7.1''}', returnType{i}]);
                        end
                        fprintf(fidType(i), ['-> This gauge will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 233.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The definition of virtual strain gauge #%.0f appears to reference more than two position IDs', returnType{i}], getappdata(0, 'vGaugeNumber'));
                        fprintf(fidType(i), ['-> Both the main ID and the sub ID must be specified and separated by a decimal, e.g. GAUGE_LOCATION = {''205.7''}', returnType{i}]);
                        fprintf(fidType(i), ['-> This gauge will not be analysed', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 234.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The default Goodman envelope will be used for FRF calculations (group %.0f)', returnType{i}], getappdata(0, 'message_234_group'));
                    case 235.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The value of frfMinValue must be less than the value of frfMaxValue', returnType{i}]);
                        fprintf(fidType(i), ['-> The following defaults will be used instead: frfMinValue = 0.1; frfMaxValue = 10.0', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 236.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The values of frfMinValue and frfMaxValue cannot be negative', returnType{i}]);
                        fprintf(fidType(i), ['-> The following defaults will be used instead: frfMinValue = 0.1; frfMaxValue = 10.0', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 237.0
                        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In user FRF file ''%s'' (group %.0f), there are over-unity mean stress values', returnType{i}], getappdata(0, 'message_237_file'), getappdata(0, 'message_237_group'));
                        else
                            fprintf(fidType(i), [returnType{i}, '***WARNING: In user MSC file ''%s'', there are over-unity mean stress values', returnType{i}], getappdata(0, 'message_237_file'));
                        end
                        fprintf(fidType(i), ['-> Mean stress data is usually normalized by a limiting stress, so a value greater than 1.0 would indicate non-fatigue failure', returnType{i}]);
                        fprintf(fidType(i), ['-> Check the .msc file definition to make sure the data is correct', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 238.0
                        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user FRF file ''%s'' (group %.0f), there are no positive mean stress values', returnType{i}], getappdata(0, 'message_238_file'), getappdata(0, 'message_238_group'));
                            fprintf(fidType(i), ['-> The %s will not be evaluated (-1.0) for cycles with positive mean stress', returnType{i}], getappdata(0, 'mscORfrf'));
                        else
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user MSC file ''%s'', there are no positive mean stress values', returnType{i}], getappdata(0, 'message_238_file'));
                            fprintf(fidType(i), ['-> The %s will not be evaluated for cycles with positive mean stress', returnType{i}], getappdata(0, 'mscORfrf'));
                        end
                    case 239.0
                        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user FRF file ''%s'' (group %.0f), there are no negative mean stress values', returnType{i}], getappdata(0, 'message_239_file'), getappdata(0, 'message_239_group'));
                            fprintf(fidType(i), ['-> The %s will not be evaluated (-1.0) for cycles with negative mean stress', returnType{i}], getappdata(0, 'mscORfrf'));
                        else
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user MSC file ''%s'', there are no negative mean stress values', returnType{i}], getappdata(0, 'message_239_file'));
                            fprintf(fidType(i), ['-> The %s will not be evaluated for cycles with negative mean stress', returnType{i}], getappdata(0, 'mscORfrf'));
                        end
                    case 240.0
                        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user FRF file ''%s'' (group %.0f), some amplitude values were automatically adjusted', returnType{i}], getappdata(0, 'message_240_file'), getappdata(0, 'message_240_group'));
                        else
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user MSC file ''%s'', some amplitude values were automatically adjusted', returnType{i}], getappdata(0, 'message_240_file'));
                        end
                        fprintf(fidType(i), ['-> Adjacent %s points may not share the same amplitude value', returnType{i}], getappdata(0, 'mscORfrf'));
                        fprintf(fidType(i), ['-> These data points have been offset by 1e-6 to avoid zero gradient regions on the envelope', returnType{i}]);
                    case 241.0
                        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user FRF file ''%s'' (group %.0f), the envelope is not closed', returnType{i}], getappdata(0, 'message_241_file'), getappdata(0, 'message_241_group'));
                        else
                            fprintf(fidType(i), [returnType{i}, '***NOTE: In user MSC file ''%s'', the envelope is not closed', returnType{i}], getappdata(0, 'message_241_file'));
                        end
                        fprintf(fidType(i), ['-> It is recommended that the minimum and maximum non-zero mean stress values are defined at zero stress amplitude', returnType{i}]);
                    case 242.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The yield calculation failed in group %.0f (''%s'')', returnType{i}], getappdata(0, 'message_242_groupNumber'), getappdata(0, 'message_242_groupName'));
                        fprintf(fidType(i), ['-> An exception was encountered during the calculation. Please contact the author.', returnType{i}]);
                    case 243.0
                        if getappdata(0, 'outputField') == 1.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The FRF normalization parameter ''%s'' was not recognised', returnType{i}], getappdata(0, 'message_243_paramOld'));
                            fprintf(fidType(i), ['-> A default value of ''%s'' will be used instead', returnType{i}], getappdata(0, 'message_243_paramNew'));
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                    case 244.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single S-N scale factor definition spans multiple analysis groups', returnType{i}]);
                        fprintf(fidType(i), ['-> The S-N scale value %.3f will be used for each group', returnType{i}], getappdata(0, 'snScale'));
                        fprintf(fidType(i), ['-> If this is intentional, the above message can be ignored', returnType{i}]);
                    case 245.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: A single residual stress definition spans multiple analysis groups', returnType{i}]);
                        fprintf(fidType(i), ['-> The residual stress value %.3f will be used for each group', returnType{i}], getappdata(0, 'residualStress'));
                        fprintf(fidType(i), ['-> If this is intentional, the above message can be ignored', returnType{i}]);
                    case 246.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: The FOS algorithm detected a chattering condition', returnType{i}]);
                        fprintf(fidType(i), ['-> The best solution will be accepted based on the tolerance', returnType{i}]);
                    case 247.0
                        reason = getappdata(0, 'message_247_breakCondition');
                        if reason == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: The FOS calculation has been stopped for an unknown reason', returnType{i}]);
                            fprintf(fidType(i), ['-> Please contact the author for further assistance', returnType{i}]);
                            setappdata(0, 'messageFileWarnings', 1.0)
                        else
                            fprintf(fidType(i), [returnType{i}, '***NOTE: The FOS calculation has reached the following stop condition:', returnType{i}]);
                            switch reason
                                case 1.0
                                    fprintf(fidType(i), ['-> The user-specified tolerance has been achieved', returnType{i}]);
                                case 2.0
                                    fprintf(fidType(i), ['-> The maximum FOS value has been reached', returnType{i}]);
                                case 3.0
                                    fprintf(fidType(i), ['-> The minimum FOS value has been reached', returnType{i}]);
                                case 4.0
                                    fprintf(fidType(i), ['-> The maximum number of fine iterations has been reached', returnType{i}]);
                                case 5.0
                                    fprintf(fidType(i), ['-> The maximum number of coarse iterations has been reached', returnType{i}]);
                                case 6.0
                                    fprintf(fidType(i), ['-> The FOS solution brackets the target life', returnType{i}]);
                                otherwise
                                    fprintf(fidType(i), ['-> Unknown', returnType{i}]);
                            end
                        end
                    case 248.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: History data for virtual strain gauge #%.0f has been written to ''%s\\Project\\output\\%s\\Data Files\\virtual_strain_gauge_#%.0f.dat''', returnType{i}], getappdata(0, 'vGaugeNumber'), pwd, getappdata(0, 'jobName'), getappdata(0, 'vGaugeNumber'));
                    case 249.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The orientation ''%s'' for virtual strain gauge #%.0f was not recognised', returnType{i}], getappdata(0, 'vGaugeOri'), getappdata(0, 'vGaugeNumber'));
                        fprintf(fidType(i), ['-> Either the flags ''RECTANGULAR'' or ''DELTA'' may be used, or the orientation maay be specified directly', returnType{i}]);
                        fprintf(fidType(i), ['-> e.g. GAUGE_ORIENTATION = {''RECTANGULAR'' | ''DELTA''}', returnType{i}]);
                        fprintf(fidType(i), ['-> e.g. GAUGE_ORIENTATION = {[0.0, 45.0, 45.0]}', returnType{i}]);
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 250.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: For virtual strain gauge #%.0f, %.0f orientations were specified, but 3 are required (ALPHA, BETA and GAMMA)', returnType{i}], getappdata(0, 'vGaugeNumber'), getappdata(0, 'vGaugeNOri'));
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 251.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: For virtual strain gauge #%.0f, an invalid value of %s was specified', returnType{i}], getappdata(0, 'vGaugeNumber'), getappdata(0, 'vGaugeOriName'));
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 252.0
                        fprintf(fidType(i), [returnType{i}, '***WARNING: For virtual strain gauge #%.0f, an invalid value of %s was specified (%.3g)', returnType{i}], getappdata(0, 'vGaugeNumber'), getappdata(0, 'vGaugeOriName'), getappdata(0, 'vGaugeValue'));
                        fprintf(fidType(i), ['-> %s must be in the range (0 %s %s < 180)', returnType{i}], getappdata(0, 'vGaugeOriName'), getappdata(0, 'vGaugeOriSymbol'), getappdata(0, 'vGaugeOriName'));
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 253.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Virtual strain gauge #%.0f will not be analysed', returnType{i}], getappdata(0, 'vGaugeNumber'));
                    case 254.0
                        % There are not at least two rows in the .kd file
                        fprintf(fidType(i), [returnType{i}, '***WARNING: The S-N knock-down file ''%s'' is formatted incorrectly', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> At least two S-N knock-down factors must be specified', returnType{i}]);
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for group %.0f', returnType{i}], getappdata(0, 'message_groupNumber'));
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 255.0
                        % S-values are not strictly decreasing after knock-down scaling
                        fprintf(fidType(i), [returnType{i}, '***WARNING: After applying knock-down factors to the S-N curve in group %.0f, the S-values are not strictly decreasing', returnType{i}], getappdata(0, 'message_groupNumber'));
                        fprintf(fidType(i), ['-> The specified knock-down factors in file ''%s'' have produced an invalid S-N curve', returnType{i}], getappdata(0, 'message_knockDownFile'));
                        fprintf(fidType(i), ['-> S-N knock-down factors will not be used for this group', returnType{i}]);
                        
                        setappdata(0, 'messageFileWarnings', 1.0)
                    case 256.0
                        fprintf(fidType(i), [returnType{i}, '***NOTE: Whenever R-ratio S-N Curves mean stress correction is used, the fatigue limit is calculated from the interpolated S-N curve', returnType{i}]);
                        if getappdata(0, 'modifyEnduranceLimit') == 1.0
                            fprintf(fidType(i), ['-> Modification of the fatigue limit is enabled with the environment variable ''modifyEnduranceLimit''. Therefore, the fatigue limit may be reduced during the analysis, causing unexpected behaviour', returnType{i}]);
                            fprintf(fidType(i), ['-> Consult Section 7.8 of the Quick Fatigue Tool User Guide for additional guidance on this message', returnType{i}]);
                        end
                    case 257.0
                        if getappdata(0, 'suppress_ID257') == 0.0
                            fprintf(fidType(i), [returnType{i}, '***WARNING: After applying the Morrow mean stress correction, the corrected fatigue strength coefficient (Sf'') is negative', returnType{i}]);
                            fprintf(fidType(i), ['-> The Morrow mean stress correction is not defined for mean stress at or above the fatigue strength coefficient (Sf'')', returnType{i}]);
                            fprintf(fidType(i), ['-> Non-fatigue failure will be assumed at the affected analysis items', returnType{i}]);
                            fprintf(fidType(i), ['-> Check the validity of the loading', returnType{i}]);
                            
                            if i == X
                                setappdata(0, 'suppress_ID257', 1.0)
                            end
                            
                            setappdata(0, 'messageFileWarnings', 1.0)
                        end
                end
            end
        end
        
        %% UNSUPPRESS MESSAGE IDs
        function [] = unsupressMessageIDs()
            setappdata(0, 'suppress_ID16', 0.0)
            setappdata(0, 'suppress_ID17', 0.0)
            setappdata(0, 'suppress_ID26', 0.0)
            setappdata(0, 'suppress_ID58', 0.0)
            setappdata(0, 'suppress_ID62', 0.0)
            setappdata(0, 'suppress_ID63', 0.0)
            setappdata(0, 'suppress_ID67', 0.0)
            setappdata(0, 'suppress_ID77', 0.0)
            setappdata(0, 'suppress_ID78', 0.0)
            setappdata(0, 'suppress_ID97', 0.0)
            setappdata(0, 'suppress_ID143', 0.0)
            setappdata(0, 'suppress_ID144', 0.0)
            setappdata(0, 'suppress_ID145', 0.0)
            setappdata(0, 'suppress_ID159', 0.0)
            setappdata(0, 'suppress_ID160', 0.0)
            setappdata(0, 'suppress_ID161', 0.0)
            setappdata(0, 'suppress_ID181', 0.0)
            setappdata(0, 'suppress_ID190', 0.0)
            setappdata(0, 'suppress_ID205', 0.0)
            setappdata(0, 'suppress_ID220', 0.0)
            setappdata(0, 'suppress_ID257', 0.0)
        end
        
        %% WRITE LOG FILE
        function [] = writeLog(jobName, jobDescription, dataset,...
                material, history, items, units, scale, repeats, useSN,...
                gateHistories, gateTensors, nodalElimination, planePrecision,...
                worstAnalysisItem, thetaOnCP, phiOnCP, outputField,...
                algorithm, nodalDamage, worstMainID, worstSubID, dir,...
                step, cael, msCorrection, nlMaterial, removed,...
                hotspotWarning, loadEqVal, loadEqUnits, elementType, offset)
            
            % Open the log file for writing
            logFile = [dir, sprintf('%s.log', jobName)];

            fid = fopen(logFile, 'w');
            
            % Write file header
            try
                fprintf(fid, 'Quick Fatigue Tool 6.10-07 on machine %s (User is %s)\r\n', char(java.net.InetAddress.getLocalHost().getHostName()), char(java.lang.System.getProperty('user.name')));
            catch
                fprintf(fid, 'Quick Fatigue Tool 6.10-07\r\n');
            end
            fprintf(fid, '(Copyright Louis Vallance 2017)\r\n');
            fprintf(fid, 'Last modified 15-Apr-2017 19:34:54 GMT\r\n\r\n');
            
            %% Write the input summary
            fprintf(fid, 'INPUT SUMMARY:\r\n=======\r\n');
            
            % General
            fprintf(fid, '    Job name: %s\r\n', jobName);
            if isempty(jobDescription) == 1.0
                fprintf(fid, '    Description: NO DESCRIPTION\r\n\r\n');
            else
                fprintf(fid, '    Description: %s\r\n\r\n', jobDescription);
            end
            
            %% Get the S-N scale factors
            snScale = getappdata(0, 'snScale');
            kdError = getappdata(0, 'kd_error');
            
            % Material properties
            G = getappdata(0, 'numberOfGroups');
            if G == 1.0
                fprintf(fid, '    <MATERIAL DATA>\r\n');
                if algorithm == 8.0
                    fprintf(fid, '    Material: Structural Steel\r\n');
                    fprintf(fid, '    Material Model: Linear Elastic (Hookean)\r\n');
                else
                    fprintf(fid, '    Material: %s\r\n', material(1:end-4));
                    
                    if nlMaterial == 1.0
                        fprintf(fid, '    Material Model: Nonlinear elastic (Ramberg-Osgood)\r\n');
                    else
                        fprintf(fid, '    Material Model: Linear Elastic (Hookean)\r\n');
                    end
                end
                
                if algorithm == 8.0
                    fprintf(fid, '    Stress-Life Curve: BS 7608\r\n');
                    fprintf(fid, '    Fatigue Limit: %.3gMPa\r\n', getappdata(0, 'bs7608_s0'));
                else
                    if useSN > 0.0
                        fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Direct (S-N data)');
                    elseif useSN == 0
                        if algorithm == 4.0 && getappdata(0, 'plasticSN') == 1.0
                            fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Derived Elastic + Plastic (Sf'', b) + (Ef'', c)');
                        else
                            fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Derived Elastic (Sf'' and b)');
                        end
                    end
                    
                    fprintf(fid, '    S-N Scale: %.3g\r\n', snScale);
                    
                    snKnockDown = char(cell2mat(getappdata(0, 'snKnockDown')));
                    if isempty(snKnockDown) == 1.0
                        fprintf(fid, '    S-N Knock-Down Curve: NONE\r\n');
                    elseif useSN == 1.0
                        if kdError == 1.0
                            fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (INACTIVE)\r\n', snKnockDown);
                        else
                            fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (ACTIVE)\r\n', snKnockDown);
                        end
                    else
                        fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (INACTIVE)\r\n', snKnockDown);
                    end
                    
                    b2 = getappdata(0, 'b2');
                    if isempty(b2) == 0.0
                        fprintf(fid, '    Basquin''s Exponent Above Knee Point (B2): %.3g\r\n', b2);
                        b2Nf = getappdata(0, 'b2Nf');
                        if isempty(b2Nf) == 0.0
                            fprintf(fid, '    Life Above Which To Use B2: %.3g\r\n', b2Nf);
                        else
                            fprintf(fid, '    Life Above Which To Use B2: N/A\r\n');
                        end
                    else
                        fprintf(fid, '    Basquin''s Exponent Above Knee Point (B2): NONE\r\n');
                    end
                    fprintf(fid, '    Constant Amplitude Endurance Limit: %.3g Cycles\r\n', 0.5*cael);
                    fprintf(fid, '    Fatigue Limit: %.3gMPa\r\n', getappdata(0, 'fatigueLimit'));
                    ucs = getappdata(0, 'ucs');
                    if isempty(ucs) == 0.0
                        fprintf(fid, '    Ultimate Compressive Strength: %.3gMPa\r\n', getappdata(0, 'ucs'));
                    else
                        fprintf(fid, '    Ultimate Compressive Strength: N/A\r\n');
                    end
                end
            else
                group_materialProps = getappdata(0, 'group_materialProps');
                groupIDBuffer = getappdata(0, 'groupIDBuffer');
                
                fprintf(fid, '    <MATERIAL DATA [ALL GROUPS]>\r\n');
                
                if algorithm == 8.0
                    fprintf(fid, '    Material: Structural Steel\r\n');
                    fprintf(fid, '    Material Model: Linear Elastic (Hookean)\r\n');
                else
                    if nlMaterial == 1.0
                        fprintf(fid, '    Material Model: Nonlinear elastic (Ramberg-Osgood)\r\n');
                    else
                        fprintf(fid, '    Material Model: Linear Elastic (Hookean)\r\n');
                    end
                end
                
                if algorithm == 8.0
                    fprintf(fid, '    Stress-Life Curve: BS 7608\r\n');
                    fprintf(fid, '    Fatigue Limit: %.3gMPa\r\n', getappdata(0, 'bs7608_s0'));
                else
                    if useSN > 0.0
                        fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Direct (S-N data)');
                    elseif useSN == 0
                        if algorithm == 4.0 && getappdata(0, 'plasticSN') == 1.0
                            fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Derived Elastic + Plastic (Sf'', b) + (Ef'', c)');
                        else
                            fprintf(fid, '    Stress-Life Curve: %s\r\n', 'Derived Elastic (Sf'' and b)');
                        end
                    end
                end
                
                if algorithm ~= 8.0
                    snKnockDown = group_materialProps.snKnockDown;
                    
                    for groups = 1:G
                        fprintf(fid, '\r\n    <MATERIAL DATA FOR %s [GROUP %.0f]>\r\n', char(groupIDBuffer(groups).material), groups);
                        % S-N Scale
                        if useSN > 0.0
                            fprintf(fid, '    S-N Scale: %.3g\r\n', snScale(groups));
                        else
                            fprintf(fid, '    S-N Scale: N/A\r\n');
                        end
                        
                        % S-N Knock-Down Curve
                        if isempty(snKnockDown) == 1.0
                            fprintf(fid, '    S-N Knock-Down Curve: NONE\r\n');
                        else
                            snKnockDown_i = snKnockDown{groups};
                            if isempty(snKnockDown_i) == 1.0
                                fprintf(fid, '    S-N Knock-Down Curve: NONE\r\n');
                            elseif useSN == 1.0
                                if kdError(groups) == 1.0
                                    fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (INACTIVE)\r\n', snKnockDown_i);
                                else
                                    fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (ACTIVE)\r\n', snKnockDown_i);
                                end
                            else
                                fprintf(fid, '    S-N Knock-Down Curve: ''%s'' (INACTIVE)\r\n', snKnockDown_i);
                            end
                        end
                        
                        % B2
                        b2 = group_materialProps(groups).b2;
                        b2Nf = group_materialProps(groups).b2Nf;
                        
                        if isempty(b2) == 0.0
                            fprintf(fid, '    Basquin''s Exponent Above Knee Point (B2): %.3g\r\n', b2);
                            if isempty(b2Nf) == 0.0
                                fprintf(fid, '    Life Above Which To Use B2: %.3g\r\n', b2Nf);
                            else
                                fprintf(fid, '    Life Above Which To Use B2: N/A\r\n');
                            end
                        else
                            fprintf(fid, '    Basquin''s Exponent Above Knee Point (B2): NONE\r\n');
                        end
                        
                        % Fatigue Limit
                        fprintf(fid, '    Constant Amplitude Endurance Limit: %.3g Cycles\r\n', 0.5*group_materialProps(groups).cael);
                        fprintf(fid, '    Fatigue Limit: %.3gMPa\r\n', group_materialProps(groups).fatigueLimit);
                        
                        % UCS
                        ucs = getappdata(0, 'ucs');
                        if isempty(ucs) == 0.0
                            fprintf(fid, '    Ultimate Compressive Strength: %.3gMPa\r\n', group_materialProps(groups).ucs);
                        else
                            fprintf(fid, '    Ultimate Compressive Strength: N/A\r\n');
                        end
                    end
                end
            end
            
            % Model data
            fprintf(fid, '\r\n    <MODEL DATA>\r\n');
            if algorithm == 3.0
                fprintf(fid, '    Stress Dataset: N/A\r\n');
            elseif ischar(dataset) == 0.0
                string = cell(1, length(dataset) + 1.0);
                string{1} = sprintf('    Stress Datasets: {');
                for i = 2:length(dataset) + 1.0
                    if i == length(dataset) + 1.0
                        string{i} = sprintf('''%s'' }\r\n', dataset{i-1});
                    else
                        string{i} = sprintf('''%s'',', dataset{i-1});
                    end
                end
                fprintf(fid, strjoin(string));
            else
                fprintf(fid, '    Stress Dataset: ''%s''\r\n', dataset);
            end
            dataLabel = getappdata(0, 'dataLabel');
            if dataLabel(1.0) == 4.0 || dataLabel(1) == 5.0 || (dataLabel(1) == 6.0 && elementType == 1.0) || dataLabel(1) == 9.0 || dataLabel(1) == 10.0
                fprintf(fid, '    Allow Datasets with Plane Stress Elements: YES\r\n');
                if dataLabel(1.0) == 9.0 || dataLabel(1.0) == 10.0
                    if getappdata(0, 'shellLocation') == 1.0
                        fprintf(fid, '    Shell Element Face: SNEG\r\n');
                    else
                        fprintf(fid, '    Shell Element Face: SPOS\r\n');
                    end
                end
            elseif dataLabel(1) == 6.0 || dataLabel(1) == 7.0 || dataLabel(1) == 8.0
                fprintf(fid, '    Allow Datasets with Plane Stress Elements: NO\r\n');
            end
            if getappdata(0, 'dataPosition') == 1.0
                fprintf(fid, '    Data Position: Element-Nodal or Integration Point\r\n');
            end
            if getappdata(0, 'dataPosition') == 2.0
                fprintf(fid, '    Data Position: Unique Nodal or Centroidal\r\n');
            end
            if getappdata(0, 'dataPosition') == 3.0
                fprintf(fid, '    Data Position: UNKNOWN\r\n');
            end
            if algorithm == 8.0
                weldClass = getappdata(0, 'weldClass');
                weldClassInt = getappdata(0, 'weldClassInt');
                if weldClassInt == 12.0
                    if iscell(weldClass) == 1.0
                        weldClass = weldClass{1.0};
                    end
                elseif weldClass(1.0) == 1.0 || strcmpi(weldClass, 'b')
                    weldClass = 'B';
                elseif weldClass(1.0) == 2.0 || strcmpi(weldClass, 'c')
                    weldClass = 'C';
                elseif weldClass(1.0) == 3.0 || strcmpi(weldClass, 'd')
                    weldClass = 'D';
                elseif weldClass(1.0) == 4.0 || strcmpi(weldClass, 'e')
                    weldClass = 'E';
                elseif weldClass(1.0) == 5.0 || strcmpi(weldClass, 'f')
                    weldClass = 'F';
                elseif weldClass(1.0) == 6.0 || strcmpi(weldClass, 'f2')
                    weldClass = 'F2';
                elseif weldClass(1.0) == 7.0 || strcmpi(weldClass, 'g')
                    weldClass = 'G';
                elseif weldClass(1.0) == 8.0 || strcmpi(weldClass, 'w')
                    weldClass = 'W';
                elseif weldClass(1.0) == 9.0 || strcmpi(weldClass, 's')
                    weldClass = 'S';
                elseif weldClass(1.0) == 10.0 || strcmpi(weldClass, 't')
                    weldClass = 'T';
                elseif weldClass(1.0) == 11.0 || strcmpi(weldClass, 'x')
                    weldClass = 'X';
                end
                if strcmpi(weldClass, 'x') == 1.0
                    fprintf(fid, '    Weld Class: X (Axially Loaded Bolts)\r\n');
                else
                    fprintf(fid, '    Weld Class: %s\r\n', weldClass);
                end
                fprintf(fid, '    Standard Deviations Below Mean Curve: %.3g\r\n', getappdata(0, 'devsBelowMean'));
                thickness = getappdata(0, 'plateThickness');
                if getappdata(0, 'weldClassInt') ~= 11.0
                    fprintf(fid, '    Plate Thickness: %.3gmm\r\n', thickness);
                else
                    fprintf(fid, '    Bolt Diameter: %.3gmm\r\n', thickness);
                end
            end
            
            % Loading settings
            fprintf(fid, '\r\n    <LOADING SETTINGS>\r\n');
            if isempty(history) == 1.0
                fprintf(fid, '    Load History: NONE (Dataset Sequence)\r\n');
            elseif isnumeric(history) == 1.0
                fprintf(fid, '    Load History: [DEFINED IN JOB FILE]\r\n');
            elseif ischar(history) == 0.0
                string = cell(1.0, length(history) + 1.0);
                string{1.0} = sprintf('    Load Histories: {');
                for i = 2.0:length(history) + 1.0
                    if i == length(history) + 1.0
                        if ischar(history{i - 1.0}) == 1.0
                            string{i} = sprintf('''%s'' }\r\n', history{i - 1.0});
                        else
                            string{i} = sprintf('[DEFINED IN JOB FILE] }\r\n');
                        end
                    else
                        if ischar(history{i - 1.0}) == 1.0
                            string{i} = sprintf('''%s'',', history{i - 1.0});
                        else
                            string{i} = sprintf('[DEFINED IN JOB FILE],');
                        end
                    end
                end
                fprintf(fid, strjoin(string));
            else
                fprintf(fid, '    Load History: ''%s''\r\n', history);
            end
            ranges = getappdata(0, 'directShearRanges');
            maxTensorComponents = getappdata(0, 'maxTensorComponents');
            maxTensorComponentsPosition = getappdata(0, 'maxTensorComponentsPosition');
            fprintf(fid, '    Direct Range: %.3g to %.3g\r\n', ranges(1), ranges(2));
            if algorithm == 3.0
                fprintf(fid, '    Shear Range: NONE\r\n');
            else
                fprintf(fid, '    Shear Range: %.3g to %.3g\r\n', ranges(3), ranges(4));
            end
            fprintf(fid, '    Maximum Stress Components in Loading:\r\n');
            if algorithm == 3.0
                fprintf(fid, '    S (Uniaxial)\r\n');
                
                fprintf(fid, '    %.3g\r\n', maxTensorComponents(1));
            else
                fprintf(fid, '    Sxx\tSyy\tSzz\tSxy\tSyz\tSxz\r\n');
                
                fprintf(fid, '    %.3g@%s,\t', maxTensorComponents(1), maxTensorComponentsPosition{1});
                fprintf(fid, '%.3g@%s,\t', maxTensorComponents(2), maxTensorComponentsPosition{2});
                fprintf(fid, '%.3g@%s,\t', maxTensorComponents(3), maxTensorComponentsPosition{3});
                fprintf(fid, '%.3g@%s,\t', maxTensorComponents(4), maxTensorComponentsPosition{4});
                fprintf(fid, '%.3g@%s,\t', maxTensorComponents(5), maxTensorComponentsPosition{5});
                fprintf(fid, '%.3g@%s\r\n', maxTensorComponents(6), maxTensorComponentsPosition{6});
            end
            fprintf(fid, '    Analysis Items: %.0f\r\n', getappdata(0, 'numberOfNodes'));
            fprintf(fid, '    History Points: %.0f\r\n', getappdata(0, 'signalLength'));
            fprintf(fid, '    Units: %s\r\n', units);
            fprintf(fid, '    Loading is equivalent to: %.3g %s\r\n', loadEqVal, loadEqUnits);
            if length(scale) > 1.0
                string = cell(1.0, length(scale) + 1.0);
                string{1.0} = sprintf('    Load Scale Factors: [');
                for i = 2:length(scale) + 1.0
                    if i == length(scale) + 1.0
                        string{i} = sprintf('%g ]\r\n', scale(i-1.0));
                    else
                        string{i} = sprintf('%g,', scale(i-1.0));
                    end
                end
                fprintf(fid, strjoin(string));
            else
                fprintf(fid, '    Load Scale Factor: %g\r\n', scale);
            end
            if length(offset) > 1.0
                string = cell(1.0, length(offset) + 1.0);
                string{1.0} = sprintf('    Load Offset Values: [');
                for i = 2:length(offset) + 1.0
                    if i == length(offset) + 1.0
                        string{i} = sprintf('%g ]\r\n', offset(i-1.0));
                    else
                        string{i} = sprintf('%g,', offset(i-1.0));
                    end
                end
                fprintf(fid, strjoin(string));
            elseif isempty(offset) == 1.0
                fprintf(fid, '    Load Offset Values: NONE\r\n');
            else
                fprintf(fid, '    Load Offset Value: %g\r\n', offset);
            end
            fprintf(fid, '    Repeats: %.3g\r\n', repeats);
            timeHistoryString = [];
            if gateHistories == 1.0 || gateHistories == 2.0
                timeHistoryString = 'PRE-GATE LOAD HISTORIES';
            end
            if gateTensors == 1.0 || gateTensors == 2.0
                if isempty(timeHistoryString) == 1.0
                    timeHistoryString = 'GATE TENSORS';
                else
                    timeHistoryString = [timeHistoryString, ', GATE TENSORS'];
                end
            end
            if isempty(timeHistoryString) == 1.0
                fprintf(fid, '    Time history pre-processing: NONE\r\n');
            else
                fprintf(fid, '    Time history pre-processing: %s\r\n', timeHistoryString);
            end
            
            % Analysis settings
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Get the stress invariant parameter type
            stressInParamType = getappdata(0, 'stressInvariantParameter');
            switch stressInParamType
                case 1.0
                    stressInParamType = 'von Mises';
                case 2.0
                    stressInParamType = 'Principal';
                case 3.0
                    stressInParamType = 'Hydrostatic';
                case 4.0
                    stressInParamType = 'Tresca';
                otherwise
                    stressInParamType = 'von Mises';
            end
            
            % Get the number of groups
            if G == 1.0
                fprintf(fid, '\r\n    <ANALYSIS SETTINGS>\r\n');
                
                switch algorithm
                    case 3.0
                        fprintf(fid, '    Analysis Algorithm: Uniaxial Stress-Life\r\n');
                    case 4.0
                        fprintf(fid, '    Analysis Algorithm: Stress-based Brown-Miller (Shear + Direct)\r\n');
                    case 5.0
                        fprintf(fid, '    Analysis Algorithm: Normal Stress\r\n');
                    case 6.0
                        fprintf(fid, '    Analysis Algorithm: Findley''s Method\r\n');
                    case 7.0
                        fprintf(fid, '    Analysis Algorithm: Stress Invariant Parameter (%s)\r\n', stressInParamType);
                    case 8.0
                        fprintf(fid, '    Analysis Algorithm: BS 7608 Fatigue of Welded Steel Joints\r\n');
                        if getappdata(0, 'bs7608FailureMode') == 1.0
                            fprintf(fid, '    Failure Mode: Normal\r\n');
                        elseif getappdata(0, 'bs7608FailureMode') == 2.0
                            fprintf(fid, '    Failure Mode: Shear\r\n');
                        else
                            fprintf(fid, '    Failure Mode: Combined (normal + shear)\r\n');
                        end
                    case 9.0
                        fprintf(fid, '    Analysis Algorithm: NASALIFE\r\n');
                end
                if algorithm == 6.0
                    fprintf(fid, '    Mean Stress Correction: Built-in\r\n');
                elseif algorithm == 8.0
                    fprintf(fid, '    Mean Stress Correction: N/A\r\n');
                else
                    switch msCorrection
                        case -1.0
                            fprintf(fid, '    Mean Stress Correction: User-defined\r\n');
                            fprintf(fid, '    Mean Stress Correction File: ''%s''\r\n', getappdata(0, 'userMSCFile'));
                        case 1
                            fprintf(fid, '    Mean Stress Correction: Morrow\r\n');
                        case 2
                            fprintf(fid, '    Mean Stress Correction: Goodman\r\n');
                        case 3
                            fprintf(fid, '    Mean Stress Correction: Soderberg\r\n');
                        case 4
                            gamma = getappdata(0, 'walkerGamma');
                            walkerGammaSource = getappdata(0, 'walkerGammaSource');
                            materialBehavior = getappdata(0, 'materialBehavior');
                            fprintf(fid, '    Mean Stress Correction: Walker\r\n');
                            if (materialBehavior == 3.0 && walkerGammaSource == 2.0) || (isempty(getappdata(0, 'uts')) == 1.0) && (materialBehavior == 3.0) && (walkerGammaSource ~= 3.0)
                                fprintf(fid, '    Gamma (Walker): From Load Ratios\r\n');
                            else
                                fprintf(fid, '    Gamma (Walker): %f\r\n', gamma);
                            end
                        case 5
                            fprintf(fid, '    Mean Stress Correction: Smith-Watson-Topper\r\n');
                        case 6
                            fprintf(fid, '    Mean Stress Correction: Gerber\r\n');
                        case 7
                            fprintf(fid, '    Mean Stress Correction: R-Ratio S-N curves\r\n');
                        case 8
                            fprintf(fid, '    Mean Stress Correction: NONE\r\n');
                    end
                end
                fprintf(fid, '    Design Life: %.3g %s\r\n', getappdata(0, 'dLife'), getappdata(0, 'loadEqUnits'));
                if algorithm == 3.0
                    fprintf(fid, '    Items: N/A\r\n');
                elseif isempty(items)
                    fprintf(fid, '    Items: ALL\r\n');
                elseif strcmpi(items, 'all') == 1.0
                    fprintf(fid, '    Items: ALL\r\n');
                elseif length(items) > 1.0
                    fprintf(fid, '    Items: %.0f, ', items(1.0));
                    fprintf(fid, '%.0f, ', items(1:end-1));
                    fprintf(fid, '%.0f\r\n', items(end));
                else
                    fprintf(fid, '    Items: %.0f\r\n', items);
                end
                if algorithm == 3.0 || algorithm == 8.0
                    fprintf(fid, '    Nodal Elimination: N/A\r\n');
                elseif nodalElimination > 0.0
                    if hotspotWarning == 1.0
                        fprintf(fid, '    Nodal Elimination: ON (ALL items removed)\r\n');
                    else
                        fprintf(fid, '    Nodal Elimination: ON (%.0f items removed)\r\n', removed);
                    end
                else
                    fprintf(fid, '    Nodal Elimination: OFF\r\n');
                end
                if getappdata(0, 'checkLoadProportionality') == 1.0
                    fprintf(fid, '    Load Proportionality Checking: ON (Tolerance = %.3g Degrees)\r\n', getappdata(0, 'proportionalityTolerance'));
                else
                    fprintf(fid, '    Load Proportionality Checking: OFF\r\n');
                end
                % Surface finish definition
                if algorithm == 8.0
                    fprintf(fid, '    Surface Finish Definition: N/A\r\n');
                else
                    ktDef = getappdata(0, 'ktDef');
                    if (length(ktDef) > 1.0) && (ischar(ktDef) == 0.0)
                        ktDef = char(ktDef(1.0));
                    end
                    kt = getappdata(0, 'kt');
                    if isnumeric(ktDef)
                        fprintf(fid, '    Surface Finish Definition: As Kt Value (Kt = %.3g)\r\n', kt);
                    elseif getappdata(0, 'ktFileType') == 1.0
                        fprintf(fid, '    Surface Finish Definition: Surface finish from list\r\n');
                        fprintf(fid, '    Definition File: ''%s''\r\n', ktDef);
                        ktCurve = getappdata(0, 'ktCurve');
                        if strcmpi(ktDef, 'default.kt') == 1.0
                            switch ktCurve
                                case 1
                                    fprintf(fid, '    Surface Finish: Mirror Polished - Ra <= 0.25um (Kt = %.3g)\r\n', kt);
                                case 2
                                    fprintf(fid, '    Surface Finish: 0.25 < Ra <= 0.6um (Kt = %.3g)\r\n', kt);
                                case 3
                                    fprintf(fid, '    Surface Finish: 0.6 < Ra <= 1.6um (Kt = %.3g)\r\n', kt);
                                case 4
                                    fprintf(fid, '    Surface Finish: 1.6 < Ra <= 4um (Kt = %.3g)\r\n', kt);
                                case 5
                                    fprintf(fid, '    Surface Finish: Fine Machined - 4 < Ra <= 16um (Kt = %.3g)\r\n', kt);
                                case 6
                                    fprintf(fid, '    Surface Finish: Machined - 16 < Ra <= 16um (Kt = %.3g)\r\n', kt);
                                case 7
                                    fprintf(fid, '    Surface Finish: Precision Forging - 40 < Ra <= 75um (Kt = %.3g)\r\n', kt);
                                case 8
                                    fprintf(fid, '    Surface Finish: 75um < Ra (Kt = %.3g)\r\n', kt);
                                otherwise
                                    fprintf(fid, '    Surface Finish: UNKNOWN (Kt = 1.0)\r\n');
                            end
                        elseif strcmpi(ktDef, 'juvinall-1967.kt') == 1.0
                            switch ktCurve
                                case 1
                                    fprintf(fid, '    Surface Finish: Mirror Polished (Kt = %.3g)\r\n', kt);
                                case 2
                                    fprintf(fid, '    Surface Finish: Fine-ground or commercially polished (Kt = %.3g)\r\n', kt);
                                case 3
                                    fprintf(fid, '    Surface Finish: Machined (Kt = %.3g)\r\n', kt);
                                case 4
                                    fprintf(fid, '    Surface Finish: Hot-rolled (Kt = %.3g)\r\n', kt);
                                case 5
                                    fprintf(fid, '    Surface Finish: As forged (Kt = %.3g)\r\n', kt);
                                case 6
                                    fprintf(fid, '    Surface Finish: Corroded in tap water (Kt = %.3g)\r\n', kt);
                                case 7
                                    fprintf(fid, '    Surface Finish: Corroded in salt water (Kt = %.3g)\r\n', kt);
                                otherwise
                                    fprintf(fid, '    Surface Finish: UNKNOWN (Kt = 1.0)\r\n');
                            end
                        elseif strcmpi(ktDef, 'rcjohnson-1973.kt') == 1.0
                            if (ktCurve < 1.0 || ktCurve > 12.0) || rem(ktCurve, 1.0) ~= 0.0
                                fprintf(fid, '    Surface Finish: AA = UNKNOWN (Kt = %.3g)\r\n', kt);
                            else
                                fprintf(fid, '    Surface Finish: AA = %.0f uins (Kt = %.3g)\r\n', ktCurve, kt);
                            end
                        else
                            fprintf(fid, '    Surface Finish: UNKNOWN (Kt = %.3g)\r\n', kt);
                        end
                    elseif getappdata(0, 'ktFileType') == 2.0
                        fprintf(fid, '    Surface Finish Definition: Surface finish as a value (Rz = %.3g microns)\r\n', getappdata(0, 'ktCurve'));
                        fprintf(fid, '    Definition File: ''%s''\r\n', ktDef);
                        fprintf(fid, '    Kt: %.3g\r\n', kt);
                    end
                    switch getappdata(0, 'notchFactorEstimation')
                        case 1.0
                            fprintf(fid, '    Notch Factor Estimation: Peterson (default)\r\n');
                        case 2.0
                            fprintf(fid, '    Notch Factor Estimation: Peterson B\r\n');
                        case 3.0
                            fprintf(fid, '    Notch Factor Estimation: Neuber\r\n');
                        case 4.0
                            fprintf(fid, '    Notch Factor Estimation: Harris\r\n');
                        case 5.0
                            fprintf(fid, '    Notch Factor Estimation: Heywood\r\n');
                        case 6.0
                            fprintf(fid, '    Notch Factor Estimation: Notch sensitivity\r\n');
                        otherwise
                            fprintf(fid, '    Notch Factor Estimation: N/A\r\n');
                    end
                    
                    if getappdata(0, 'notchFactorEstimation') ~= 1.0
                        if getappdata(0, 'notchFactorEstimation') == 6.0
                            fprintf(fid, '    Notch Sensitivity Constant: %.3g\r\n', getappdata(0, 'notchSensitivityConstant'));
                        else
                            fprintf(fid, '    Notch Characteristic Length: %.3g\r\n', getappdata(0, 'notchSensitivityConstant'));
                            fprintf(fid, '    Notch Root Radius: %.3g\r\n', getappdata(0, 'notchRootRadius'));
                        end
                    end
                end
                
                residualStress = getappdata(0, 'residualStress');
                if residualStress == 0.0
                    fprintf(fid, '    In-Plane Residual Stress: NONE\r\n');
                else
                    fprintf(fid, '    In-Plane Residual Stress: %.3gMPa\r\n', residualStress);
                end
            else
                walkerGammaSource = getappdata(0, 'walkerGammaSource');
                
                fprintf(fid, '\r\n    <ANALYSIS SETTINGS [ALL GROUPS]>\r\n');
                switch algorithm
                    case 3.0
                        fprintf(fid, '    Analysis Algorithm: Uniaxial Stress-Life\r\n');
                    case 4.0
                        fprintf(fid, '    Analysis Algorithm: Stress-based Brown-Miller (Shear + Direct)\r\n');
                    case 5.0
                        fprintf(fid, '    Analysis Algorithm: Normal Stress\r\n');
                    case 6.0
                        fprintf(fid, '    Analysis Algorithm: Findley''s Method\r\n');
                    case 7.0
                        fprintf(fid, '    Analysis Algorithm: Stress Invariant Parameter (%s)\r\n', stressInParamType);
                    case 8.0
                        fprintf(fid, '    Analysis Algorithm: BS 7608 Fatigue of Welded Steel Joints\r\n');
                        if getappdata(0, 'bs7608FailureMode') == 1.0
                            fprintf(fid, '    Failure Mode: Normal\r\n');
                        else
                            fprintf(fid, '    Failure Mode: Shear\r\n');
                        end
                    case 9.0
                        fprintf(fid, '    Analysis Algorithm: NASALIFE\r\n');
                end
                if algorithm == 6.0
                    fprintf(fid, '    Mean Stress Correction: Built-in\r\n');
                elseif algorithm == 8.0
                    fprintf(fid, '    Mean Stress Correction: N/A\r\n');
                else
                    switch msCorrection
                        case -1.0
                            fprintf(fid, '    Mean Stress Correction: User-defined\r\n');
                            fprintf(fid, '    Mean Stress Correction File: ''%s''\r\n', getappdata(0, 'userMSCFile'));
                        case 1
                            fprintf(fid, '    Mean Stress Correction: Morrow\r\n');
                        case 2
                            fprintf(fid, '    Mean Stress Correction: Goodman\r\n');
                        case 3
                            fprintf(fid, '    Mean Stress Correction: Soderberg\r\n');
                        case 4
                            fprintf(fid, '    Mean Stress Correction: Walker\r\n');
                        case 5
                            fprintf(fid, '    Mean Stress Correction: Smith-Watson-Topper\r\n');
                        case 6
                            fprintf(fid, '    Mean Stress Correction: Gerber\r\n');
                        case 7
                            fprintf(fid, '    Mean Stress Correction: R-Ratio S-N curves\r\n');
                        case 8
                            fprintf(fid, '    Mean Stress Correction: NONE\r\n');
                    end
                end
                
                fprintf(fid, '    Design Life: %.3g %s\r\n', getappdata(0, 'dLife'), getappdata(0, 'loadEqUnits'));
                
                if algorithm == 3.0
                    fprintf(fid, '    Items: N/A\r\n');
                elseif isempty(items)
                    fprintf(fid, '    Items: ALL\r\n');
                elseif strcmpi(items, 'all') == 1.0
                    fprintf(fid, '    Items: ALL\r\n');
                elseif length(items) > 1.0
                    fprintf(fid, '    Items: %.0f, ', items(1.0));
                    fprintf(fid, '%.0f, ', items(1:end-1));
                    fprintf(fid, '%.0f\r\n', items(end));
                else
                    fprintf(fid, '    Items: %.0f\r\n', items);
                end
                if algorithm == 3.0 || algorithm == 8.0
                    fprintf(fid, '    Nodal Elimination: N/A\r\n');
                elseif nodalElimination > 0.0
                    if hotspotWarning == 1.0
                        fprintf(fid, '    Nodal Elimination: ON (ALL items removed)\r\n');
                    else
                        fprintf(fid, '    Nodal Elimination: ON (%.0f items removed)\r\n', removed);
                    end
                else
                    fprintf(fid, '    Nodal Elimination: OFF\r\n');
                end
                if getappdata(0, 'checkLoadProportionality') == 1.0
                    fprintf(fid, '    Load Proportionality Checking: ON (Tolerance = %.3g Degrees)\r\n', getappdata(0, 'proportionalityTolerance'));
                else
                    fprintf(fid, '    Load Proportionality Checking: OFF\r\n');
                end
                
                switch getappdata(0, 'notchFactorEstimation')
                    case 1.0
                        fprintf(fid, '    Notch Factor Estimation: Peterson (default)\r\n');
                    case 2.0
                        fprintf(fid, '    Notch Factor Estimation: Peterson B\r\n');
                    case 3.0
                        fprintf(fid, '    Notch Factor Estimation: Neuber\r\n');
                    case 4.0
                        fprintf(fid, '    Notch Factor Estimation: Harris\r\n');
                    case 5.0
                        fprintf(fid, '    Notch Factor Estimation: Heywood\r\n');
                    case 6.0
                        fprintf(fid, '    Notch Factor Estimation: Notch sensitivity\r\n');
                    otherwise
                        fprintf(fid, '    Notch Factor Estimation: N/A\r\n');
                end
                
                for groups = 1:G
                    group_i = groupIDBuffer(groups).name(:)';
                    [~, group_i, ~] = fileparts(group_i);
                    
                    fprintf(fid, '\r\n    <ANALYSIS SETTINGS FOR GROUP %.0f [%s]>\r\n', groups, group_i);

                    % Surface finish definition
                    if algorithm == 8.0
                        fprintf(fid, '    Surface Finish Definition: N/A\r\n');
                    else
                        kt = group_materialProps(groups).Kt;
                        ktCurve = group_materialProps(groups).KtCurve;
                        constant = group_materialProps(groups).notchSensitivityConstant;
                        radius = group_materialProps(groups).notchRootRadius;
                        ktFileType = group_materialProps(groups).KtFileType;
                        ktDef = groupIDBuffer(groups).kt;
                        if (ischar(ktDef) == 0.0) && (isnumeric(ktDef) == 0.0)
                            ktDef = cell2mat(ktDef);
                        end
                        
                        if isnumeric(ktDef)
                            fprintf(fid, '    Surface Finish Definition: As Kt Value (%.3g)\r\n', kt);
                        elseif ktFileType == 1.0
                            fprintf(fid, '    Surface Finish Definition: Surface finish from list\r\n');
                            fprintf(fid, '    Definition File: ''%s''\r\n', ktDef);
                            if strcmpi(ktDef, 'default.kt') == 1.0
                                switch ktCurve
                                    case 1
                                        fprintf(fid, '    Surface Finish: Mirror Polished - Ra <= 0.25um (Kt = %.3g)\r\n', kt);
                                    case 2
                                        fprintf(fid, '    Surface Finish: 0.25 < Ra <= 0.6um (Kt = %.3g)\r\n', kt);
                                    case 3
                                        fprintf(fid, '    Surface Finish: 0.6 < Ra <= 1.6um (Kt = %.3g)\r\n', kt);
                                    case 4
                                        fprintf(fid, '    Surface Finish: 1.6 < Ra <= 4um (Kt = %.3g)\r\n', kt);
                                    case 5
                                        fprintf(fid, '    Surface Finish: Fine Machined - 4 < Ra <= 16um (Kt = %.3g)\r\n', kt);
                                    case 6
                                        fprintf(fid, '    Surface Finish: Machined - 16 < Ra <= 16um (Kt = %.3g)\r\n', kt);
                                    case 7
                                        fprintf(fid, '    Surface Finish: Precision Forging - 40 < Ra <= 75um (Kt = %.3g)\r\n', kt);
                                    case 8
                                        fprintf(fid, '    Surface Finish: 75um < Ra (Kt = %.3g)\r\n', kt);
                                    otherwise
                                        fprintf(fid, '    Surface Finish: UNKNOWN (Kt = 1.0)\r\n');
                                end
                            elseif strcmpi(ktDef, 'juvinall-1967.kt') == 1.0
                                switch ktCurve
                                    case 1
                                        fprintf(fid, '    Surface Finish: Mirror Polished (Kt = %.3g)\r\n', kt);
                                    case 2
                                        fprintf(fid, '    Surface Finish: Fine-ground or commercially polished (Kt = %.3g)\r\n', kt);
                                    case 3
                                        fprintf(fid, '    Surface Finish: Machined (Kt = %.3g)\r\n', kt);
                                    case 4
                                        fprintf(fid, '    Surface Finish: Hot-rolled (Kt = %.3g)\r\n', kt);
                                    case 5
                                        fprintf(fid, '    Surface Finish: As forged (Kt = %.3g)\r\n', kt);
                                    case 6
                                        fprintf(fid, '    Surface Finish: Corroded in tap water (Kt = %.3g)\r\n', kt);
                                    case 7
                                        fprintf(fid, '    Surface Finish: Corroded in salt water (Kt = %.3g)\r\n', kt);
                                    otherwise
                                        fprintf(fid, '    Surface Finish: UNKNOWN (Kt = 1.0)\r\n');
                                end
                            elseif strcmpi(ktDef, 'rcjohnson-1973.kt') == 1.0
                                if (ktCurve < 1.0 || ktCurve > 12.0) || rem(ktCurve, 1.0) ~= 0.0
                                    fprintf(fid, '    Surface Finish: AA = UNKNOWN (Kt = %.3g)\r\n', kt);
                                else
                                    fprintf(fid, '    Surface Finish: AA = %.0f uins (Kt = %.3g)\r\n', ktCurve, kt);
                                end
                            else
                                fprintf(fid, '    Surface Finish: UNKNOWN (Kt = %.3g)\r\n', kt);
                            end
                        elseif getappdata(0, 'ktFileType') == 2.0
                            fprintf(fid, '    Surface Finish Definition: Surface finish as a value (Rz = %.3g microns)\r\n', getappdata(0, 'ktCurve'));
                            fprintf(fid, '    Definition File: ''%s''\r\n', ktDef);
                            fprintf(fid, '    Kt: %.3g\r\n', kt);
                        end
                        
                        if getappdata(0, 'notchFactorEstimation') ~= 1.0
                            if getappdata(0, 'notchFactorEstimation') == 6.0
                                fprintf(fid, '    Notch Sensitivity Constant: %.3g\r\n', constant);
                            else
                                fprintf(fid, '    Notch Characteristic Length: %.3g\r\n', constant);
                                fprintf(fid, '    Notch Root Radius: %.3g\r\n', radius);
                            end
                        end
                    end
                    
                    if algorithm == 8.0
                        residualStress = getappdata(0, 'residualStress_original');
                        residualStress = residualStress(groups);
                    else
                        residualStress = group_materialProps(groups).residualStress;
                    end
                    
                    if residualStress == 0.0
                        fprintf(fid, '    In-Plane Residual Stress: NONE\r\n');
                    else
                        fprintf(fid, '    In-Plane Residual Stress: %.3gMPa\r\n', residualStress);
                    end
                    
                    if msCorrection == 4.0
                        uts = group_materialProps(groups).uts;
                        gamma = group_materialProps(groups).walkerGamma;
                        materialBehavior = group_materialProps(groups).materialBehavior;
                        if (materialBehavior == 3.0 && walkerGammaSource == 2.0) || (isempty(uts) == 1.0) && (materialBehavior == 3.0) && (walkerGammaSource ~= 3.0)
                            fprintf(fid, '    Gamma (Walker): From Load Ratios\r\n');
                        else
                            fprintf(fid, '    Gamma (Walker): %f\r\n', gamma);
                        end
                    end
                end
            end
            
            %% Worst item life
            worstNodeLife = 1.0/nodalDamage(worstAnalysisItem);
            
            %% Write group summary table
            fprintf(fid, '\r\nANALYSIS GROUPS:\r\n=======\r\n');
            
            % Get the material of the group
            if algorithm == 8.0
                material = 'N/A';
            else
                [~, material, ~] = fileparts(material);
            end
            
            % If the group ID buffer is empty, print only the DEFAULT group
            fprintf(fid, '    Group name\t\t\tMaterial\t\t\t# IDs in group\t\t\t# IDs in other groups\t\t\t# IDs used\t\t\tWorst life (%s)\r\n', loadEqUnits);
            fprintf(fid, '    ----------\t\t\t--------\t\t\t--------------\t\t\t---------------------\t\t\t----------\t\t\t--------------------\r\n');
            if G == 1.0 && getappdata(0, 'peekAnalysis') == 0.0
                fprintf(fid, '    DEFAULT\t\t\t%s\t\t\t%.0f\t\t\t%.0f\t\t\t%.0f\t\t\t%.3g@%.0f.%.0f\r\n', material, getappdata(0, 'numberOfNodes'), 0.0, getappdata(0, 'numberOfNodes'), worstNodeLife, worstMainID, worstSubID);
            else
                for i = 1:G
                    %{
                        If the analysis is a PEEK analysis, override the value of GROUP to
                        the group containing the PEEK item
                    %}
                    if getappdata(0, 'peekAnalysis') == 1.0
                        i = getappdata(0, 'peekGroup'); %#ok<FXSET>
                    end
                    
                    group_i = groupIDBuffer(i).name(:)';
                    [~, group_i, ~] = fileparts(group_i);
                    material_i = char(groupIDBuffer(i).material(:)');
                    if algorithm ~= 8.0
                        [~, material_i, ~] = fileparts(material_i);
                    end
                    NIDs_i = groupIDBuffer(i).NIDs;
                    OIDs_i = groupIDBuffer(i).OIDs;
                    UIDs_i = groupIDBuffer(i).UIDs;
                    worstLife_i = groupIDBuffer(i).worstLife;
                    worstLifeMainID_i = groupIDBuffer(i).worstLifeMainID;
                    worstLifeSubID_i = groupIDBuffer(i).worstLifeSubID;
                    if ischar(worstLife_i) == 1.0
                        fprintf(fid, '    %s\t\t\t%s\t\t\t%.0f\t\t\t%.0f\t\t\t%.0f\t\t\t%s\r\n', group_i, material_i, NIDs_i, OIDs_i, UIDs_i, worstLife_i);
                    else
                        fprintf(fid, '    %s\t\t\t%s\t\t\t%.0f\t\t\t%.0f\t\t\t%.0f\t\t\t%.3g@%.0f.%.0f\r\n', group_i, material_i, NIDs_i, OIDs_i, UIDs_i, worstLife_i, worstLifeMainID_i, worstLifeSubID_i);
                    end
                end
                
                if strcmpi(group_i, 'default') == 0.0
                    % Print the DEFAULT group
                    NIDs_i = groupIDBuffer(end).NIDs;
                    OIDs_i = groupIDBuffer(end).NIDs;
                    fprintf(fid, '    DEFAULT\t\t\tN/A\t\t\t%.0f\t\t\t%.0f\t\t\t0\t\t\tN/A\r\n', NIDs_i, OIDs_i);
                end
            end

            %% Write the critical plane summary (if applicable)
            if (algorithm == 8.0) || (algorithm == 6.0) || (algorithm == 5.0) || (algorithm == 4.0)
                fprintf(fid, '\r\nCP SUMMARY AT WORST ITEM:\r\n=======\r\n');
                
                fprintf(fid, '    CP Step Size: %.0f degrees\r\n', step(worstAnalysisItem));
                
                planesSearched = planePrecision(worstAnalysisItem)^2.0;
                fprintf(fid, '    %.0f planes searched\r\n', planesSearched);
                fprintf(fid, '    Coordinates (degrees):\r\n    THETA = %.0f, PHI = %.0f\r\n',...
                    thetaOnCP, phiOnCP);
            end
            
            %% Print FOS diagnostics
            if (getappdata(0, 'fosDiagnostics') == 1.0) && (getappdata(0, 'enableFOS') == 1.0) && (getappdata(0, 'outputField') == 1.0) && (algorithm ~= 8.0)
                fos_buffer = getappdata(0, 'fos_diagnostics_fos_buffer');
                life_buffer = getappdata(0, 'fos_diagnostics_life_buffer');
                fos_iterations = getappdata(0, 'fos_diagnostics_iterations');
                fos_mainID = getappdata(0, 'fos_diagnostics_mainID');
                fos_subID = getappdata(0, 'fos_diagnostics_subID');
                fos_targetLife = getappdata(0, 'fosTargetLife');
                fos_fineIters = getappdata(0, 'fos_diagnostics_fineIters');
                fos_coarseIters = getappdata(0, 'fos_diagnostics_coarseIters');
                fos_tolerance = 100.*getappdata(0, 'fos_diagnostics_tolerance_buffer');
                fos_target_tolerance = getappdata(0, 'fosTolerance');
                fos_max_coarse_iters = getappdata(0, 'fosMaxCoarseIterations');
                fos_max_fine_iters = getappdata(0, 'fosMaxFineIterations');
                fos_data = [fos_iterations; life_buffer; fos_buffer; fos_tolerance]';
                
                fprintf(fid, '\r\nFACTOR OF STRENGTH DIAGNOSTIC TABLE:\r\n=======\r\n');
                fprintf(fid, '    Worst FOS analysis item: %.0f.%.0f\r\n', fos_mainID, fos_subID);
                fprintf(fid, '    Target life: %.3g\r\n', fos_targetLife);
                fprintf(fid, '    Target tolerance: %.3f%%\r\n\r\n', fos_target_tolerance);
                fprintf(fid, '    Fine iterations: %.0f/%.0f\r\n', fos_fineIters, fos_max_fine_iters);
                fprintf(fid, '    Coarse iterations: %.0f/%.0f\r\n\r\n', fos_coarseIters, fos_max_coarse_iters);
                fprintf(fid, '    Iteration\tLife-%s\tFOS\t\t\tTolerance-%%\r\n', loadEqUnits);
                fprintf(fid, '    %.0f\t\t\t%.3e\t\t%.4f\t\t%.3f\r\n', fos_data');
                fprintf(fid, '\r\n');
                
                if fos_tolerance(end) <= fos_target_tolerance
                    fprintf(fid, '    (FOS calculation converged within required tolerance)\r\n\r\n');
                else
                    fprintf(fid, '    (FOS calculation did NOT converge within required tolerance)\r\n\r\n');
                end
                if getappdata(0, 'fosAugment') == 1.0
                    fprintf(fid, '    NOTE: FOS augmentation is enabled. The stated number of iterations may not reflect the number of augmented iterations\r\n');
                end
            end
            
            %% Print analysis summary
            fprintf('\n\nFATIGUE RESULTS SUMMARY:\n=======\n')
            fprintf(fid, '\r\nFATIGUE RESULTS SUMMARY:\r\n=======\r\n');
            
            if worstNodeLife > (0.5*cael)
                fprintf('    Worst Life-%s                    : No Damage\n', loadEqUnits)
                fprintf(fid, '    Worst Life-%s                    : No Damage\r\n', loadEqUnits);
            elseif worstNodeLife < 1.0
                fprintf('    Worst Life-%s                    : Non-fatigue Failure\n', loadEqUnits)
                fprintf(fid, '    Worst Life-%s                    : Non-fatigue Failure\r\n', loadEqUnits);
            else
                fprintf('    Worst Life-%s                    : %.3g\n', loadEqUnits, worstNodeLife)
                fprintf(fid, '    Worst Life-%s                    : %.3g\r\n', loadEqUnits, worstNodeLife);
            end
            fprintf('    at item %.0f.%.0f\n\n', worstMainID, worstSubID)
            fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', worstMainID, worstSubID);
            
            % Number of cycles
            if outputField == 1.0 || getappdata(0, 'outputHistory') == 1.0 || getappdata(0, 'outputFigure') == 1.0
                fprintf('    Number of cycles in loading           : %.0f\n\n', getappdata(0, 'numberOfCycles'))
                fprintf(fid,'    Number of cycles in loading           : %.0f\r\n\r\n', getappdata(0, 'numberOfCycles'));
            end
            
            if algorithm == 8.0
                if outputField == 1.0
                    % Worst item SMAX
                    fprintf('    Maximum stress (MPa)                  : %.4g\n', getappdata(0, 'SMAX_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMAX_mainID'), getappdata(0, 'SMAX_subID'))
                    fprintf(fid, '    Maximum stress (MPa)                  : %.4g\r\n', getappdata(0, 'SMAX_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMAX_mainID'), getappdata(0, 'SMAX_subID'));
                    
                    if getappdata(0, 'twopsWarn') == 0.0
                        % Worst item SMXP
                        fprintf('    Maximum stress/yield                  : %.4g\n', getappdata(0, 'SMXP_ABS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMXP_mainID'), getappdata(0, 'SMXP_subID'))
                        fprintf(fid, '    Maximum stress/yield                  : %.4g\r\n', getappdata(0, 'SMXP_ABS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMXP_mainID'), getappdata(0, 'SMXP_subID'));
                    end
                    
                    if getappdata(0, 'utsWarn') == 0.0
                        % Worst item SMXU
                        fprintf('    Maximum stress/UTS                    : %.4g\n', getappdata(0, 'SMXU_ABS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMXU_mainID'), getappdata(0, 'SMXU_subID'))
                        fprintf(fid, '    Maximum stress/UTS                    : %.4g\r\n', getappdata(0, 'SMXU_ABS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMXU_mainID'), getappdata(0, 'SMXU_subID'));
                    end
                    
                    % Worst item WCM
                    fprintf('    Worst cycle mean stress (MPa)         : %.4g\n', getappdata(0, 'WCM_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCM_mainID'), getappdata(0, 'WCM_subID'))
                    fprintf(fid, '    Worst cycle mean stress (MPa)         : %.4g\r\n', getappdata(0, 'WCM_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCM_mainID'), getappdata(0, 'WCM_subID'));
                    
                    % Worst item WCA
                    fprintf('    Worst cycle stress amplitude (MPa)    : %.4g\n', getappdata(0, 'WCA_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCA_mainID'), getappdata(0, 'WCA_subID'))
                    fprintf(fid, '    Worst cycle stress amplitude (MPa)    : %.4g\r\n', getappdata(0, 'WCA_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCA_mainID'), getappdata(0, 'WCA_subID'));
                    
                    % Worst item WCDP
                    fprintf('    Worst cycle damage parameter (MPa)    : %.4g\n', getappdata(0, 'WCDP_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCDP_mainID'), getappdata(0, 'WCDP_subID'))
                    fprintf(fid, '    Worst cycle damage parameter (MPa)    : %.4g\r\n', getappdata(0, 'WCDP_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCDP_mainID'), getappdata(0, 'WCDP_subID'));
                end
            else
                if outputField == 1.0
                    
                    if getappdata(0, 'enableFOS') == 1.0
                        % Worst item FOS
                        fprintf('    Worst FOS                             : %.4f\n', getappdata(0, 'WNFOS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WNFOS_mainID'), getappdata(0, 'WNFOS_subID'))
                        fprintf(fid, '    Worst FOS                             : %.4f\r\n', getappdata(0, 'WNFOS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WNFOS_mainID'), getappdata(0, 'WNFOS_subID'));
                    end
                    
                    if (getappdata(0, 'utsWarn') == 0.0) && (getappdata(0, 'failedFRF') == 0.0)
                        % Worst item FRFR
                        fprintf('    Worst FRF                             : %.4f\n', getappdata(0, 'FRFW_ABS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'FRFW_mainID'), getappdata(0, 'FRFW_subID'))
                        fprintf(fid, '    Worst FRF                             : %.4f\r\n', getappdata(0, 'FRFW_ABS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'FRFW_mainID'), getappdata(0, 'FRFW_subID'));
                    end
                    
                    % Worst item SMAX
                    fprintf('    Maximum stress (MPa)                  : %.4g\n', getappdata(0, 'SMAX_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMAX_mainID'), getappdata(0, 'SMAX_subID'))
                    fprintf(fid, '    Maximum stress (MPa)                  : %.4g\r\n', getappdata(0, 'SMAX_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMAX_mainID'), getappdata(0, 'SMAX_subID'));
                    
                    if getappdata(0, 'twopsWarn') == 0.0
                        % Worst item SMXP
                        fprintf('    Maximum stress/yield                  : %.4g\n', getappdata(0, 'SMXP_ABS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMXP_mainID'), getappdata(0, 'SMXP_subID'))
                        fprintf(fid, '    Maximum stress/yield                  : %.4g\r\n', getappdata(0, 'SMXP_ABS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMXP_mainID'), getappdata(0, 'SMXP_subID'));
                    end
                    
                    if getappdata(0, 'utsWarn') == 0.0
                        % Worst item SMXU
                        fprintf('    Maximum stress/UTS                    : %.4g\n', getappdata(0, 'SMXU_ABS'))
                        fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'SMXU_mainID'), getappdata(0, 'SMXU_subID'))
                        fprintf(fid, '    Maximum stress/UTS                    : %.4g\r\n', getappdata(0, 'SMXU_ABS'));
                        fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'SMXU_mainID'), getappdata(0, 'SMXU_subID'));
                    end
                    
                    % Worst item WCM
                    fprintf('    Worst cycle mean stress (MPa)         : %.4g\n', getappdata(0, 'WCM_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCM_mainID'), getappdata(0, 'WCM_subID'))
                    fprintf(fid, '    Worst cycle mean stress (MPa)         : %.4g\r\n', getappdata(0, 'WCM_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCM_mainID'), getappdata(0, 'WCM_subID'));
                    
                    % Worst item WCA
                    fprintf('    Worst cycle stress amplitude (MPa)    : %.4g\n', getappdata(0, 'WCA_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCA_mainID'), getappdata(0, 'WCA_subID'))
                    fprintf(fid, '    Worst cycle stress amplitude (MPa)    : %.4g\r\n', getappdata(0, 'WCA_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCA_mainID'), getappdata(0, 'WCA_subID'));
                    
                    % Worst item WCDP
                    fprintf('    Worst cycle damage parameter (MPa)    : %.4g\n', getappdata(0, 'WCDP_ABS'))
                    fprintf('    at Item %.0f.%.0f\n\n', getappdata(0, 'WCDP_mainID'), getappdata(0, 'WCDP_subID'))
                    fprintf(fid, '    Worst cycle damage parameter (MPa)    : %.4g\r\n', getappdata(0, 'WCDP_ABS'));
                    fprintf(fid, '    at Item %.0f.%.0f\r\n\r\n', getappdata(0, 'WCDP_mainID'), getappdata(0, 'WCDP_subID'));
                end
            end
            
            currentTime = toc;
            hrs = floor(currentTime/3600);
            mins = floor((currentTime - (3600*hrs))/60);
            secs = currentTime - (hrs*3600) - (mins*60);
            if mins < 10
                fprintf('Analysis time                             : %.0f:0%.0f:%.3f\n\n', hrs, mins, secs)
                fprintf(fid, 'Analysis time                             : %.0f:0%.0f:%.3f\r\n\r\n', hrs, mins, secs);
            else
                fprintf('Analysis time                             : %.0f:%.0f:%.3f\n\n', hrs, mins, secs)
                fprintf(fid, 'Analysis time                             : %.0f:%.0f:%.3f\r\n\r\n', hrs, mins, secs);
            end
            
            c = clock;
            fprintf('========================================================================================\n')
            fprintf(fid, 'FATIGUE ANALYSIS COMPLETE (%s)\r\n\r\n', datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))));
            fprintf(fid, '========================================================================================');
            
            % Close the log file
            fclose(fid);
            
            if getappdata(0, 'messageFileWarnings') == 1.0
                if getappdata(0, 'echoMessagesToCWIN') == 1.0
                    fprintf('Job %s completed with warnings. Scroll up for details. (%s)\n\n',...
                        jobName, datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))))
                else
                    fprintf('Job %s completed with warnings. See message file for details. (%s)\n\n',...
                        jobName, datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))))
                end
                
                % Prompt user if they would like to view the analysis log
                if (ispc == 1.0) && (ismac == 0.0)
                    answer = questdlg('Analysis completed with warnings.', 'Quick Fatigue Tool', 'View log', 'Open results folder', 'Close', 'View log');
                    delete(answer)
                elseif (ispc == 0.0) && (ismac == 1.0)
                    answer = msgbox('Analysis completed with warnings.', 'Quick Fatigue Tool');
                else
                    answer = -1.0;
                end
            else
                fprintf('Job %s completed successfully (%s)\n\n',...
                    jobName, datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))))
                
                % Prompt user if they would like to view the analysis log
                if (ispc == 1.0) && (ismac == 0.0)
                    answer = questdlg('Analysis completed without warnings.', 'Quick Fatigue Tool', 'View log', 'Open results folder', 'Close', 'View log');
                elseif (ispc == 0.0) && (ismac == 1.0)
                    answer = msgbox('Analysis completed without warnings.', 'Quick Fatigue Tool');
                else
                    answer = -1.0;
                end
            end
            
            if strcmpi(answer, 'View log') == 1.0
                winopen(logFile)
            elseif strcmpi(answer, 'Open results folder') == 1.0
                winopen(dir)
            end
        end
    end
end
classdef python < handle
%PYTHON    QFT class for ODB Interface.
%   This class contains methods for the Export Tool application.
%   
%   PYTHON is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also ExportTool.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      10.4 The ODB Interface
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% Verify the inputs in the GUI
        function [error] = verify(~, ~, ~, requestedFields,...
                fieldDataPath, fieldDataName, modelDatabasePath,...
                modelDatabaseName, resultsDatabasePath, partInstanceName,...
                stepType, stepName)

            error = 0.0;
            
            % Try to access the field data
            if isempty(fieldDataPath) == 1.0
                errordlg('Field data must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            else
                [fid, errorMessage] = fopen(fieldDataPath, 'r');
                
                if isempty(errorMessage) == 0.0
                    msg1 = sprintf('A problem occurred while accessing the field data file ''%s''.', fieldDataName);
                    msg2 = sprintf('\n\nMATLAB error message: %s.', errorMessage);
                    msg3 = sprintf('\n\nFile ID: %.0f', fid);
                    errordlg([msg1, msg2, msg3], 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                end
            end
            
            % Verify that the model output database file exists
            if isempty(modelDatabasePath) == 1.0
                errordlg('A model output database (.odb) file must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif exist(modelDatabasePath, 'file') == 0.0
                msg1 = sprintf('A problem occurred while accessing the model output databse ''%s''.', modelDatabaseName);
                msg2 = sprintf('\n\nThe file does not exist.');
                errordlg([msg1, msg2], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % Verify the the results output databse directory exists
            if isempty(resultsDatabasePath) == 1.0
                errordlg('A results output database (.odb) location must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            elseif exist(resultsDatabasePath, 'dir') == 0.0
                msg1 = sprintf('The results output database location:');
                msg2 = sprintf('\n\n%s', resultsDatabasePath);
                msg3 = sprintf('\n\ncould not be found.');
                errordlg([msg1, msg2, msg3], 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % Verify that a part instance name is specified
            if isempty(partInstanceName) == 1.0
                errordlg('A part instance name must be specified.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
            
            % Verify that a results step name is specified (if applicable)
            if stepType(1.0) == 2.0
                if isempty(stepName) == 1.0
                    errordlg('A results step name must be specified.', 'Quick Fatigue Tool')
                    uiwait
                    error = 1.0;
                    return
                end
            end
            
            % Verify that at least one field is requested
            if any(requestedFields) == 0.0
                errordlg('At least one field must be selected.', 'Quick Fatigue Tool')
                uiwait
                error = 1.0;
                return
            end
        end
        
        %% Verify the inputs for automatic export
        function [error] = verifyAuto(requestedFields,...
                fieldDataPath, fieldDataName, resultsDatabasePath, partInstanceName)

            error = 0.0;
            
            % Try to access the field data
            if getappdata(0, 'outputField') == 0.0
                messenger.writeMessage(34.0)
                error = 1.0;
                return
            else
                [fid, errorMessage] = fopen(fieldDataPath, 'r');
                
                if isempty(errorMessage) == 0.0
                    setappdata(0, 'autoExport_fieldDataInacessible', fieldDataName)
                    setappdata(0, 'autoExport_fieldDataErrorMessage', errorMessage)
                    setappdata(0, 'autoExport_fieldDataFID', fid)
                    messenger.writeMessage(82.0)
                    error = 1.0;
                    return
                end
            end
            
            % Verify the the results output databse directory exists
            if exist(resultsDatabasePath, 'dir') == 0.0
                mkdir(resultsDatabasePath)
            end
            
            % Verify that a part instance name is specified
            if isempty(partInstanceName) == 1.0
                messenger.writeMessage(83.0)
                error = 1.0;
                return
            end
            
            % Verify that at least one field is requested
            if any(requestedFields) == 0.0
                messenger.writeMessage(84.0)
                error = 1.0;
                return
            end
        end
        
        %% Obtain field data from analysis results
        function [positionLabels, position, positionLabelData,...
                positionID, connectivity, mainIDs, subIDs, stepDescription,...
                fieldData, fieldNames, connectedElements, error] = getFieldData(fieldDataPath,...
                requestedFields, userPosition,...
                partInstanceName, autoPosition, fid_debug,...
                resultsDatabasePath, resultsDatabaseName)
            
            error = 0.0;
            connectedElements = [];
            
            %% Collect field data columns in cells
            fieldDataFile = importdata(fieldDataPath, '\t');
            
            %% Get the position labels
            try
                positionLabels = fieldDataFile.data(:, 1:2);
            catch unhandledException
                fprintf(fid_debug, '\r\n\t\tError: Field data file does not contain field information');
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                
                error = 4.0;
                positionLabels = 0.0;
                position = 0.0;
                positionLabelData = 0.0;
                positionID = 0.0;
                connectivity = 0.0;
                mainIDs = 0.0;
                subIDs = 0.0;
                stepDescription = 0.0;
                fieldData = 0.0;
                fieldNames = 0.0;
                return
            end
            
            % Extract the main IDs
            mainIDs = positionLabels(:, 1.0);
            subIDs = positionLabels(:, 2.0);
            
            %% Determine the position of the field data
            %{
                Centroidal or Unique Nodal:
                1.1
                2.1
                3.1
                .
                N.1
            %}
            if autoPosition == 1.0
                if all(subIDs == 1.0) == 1.0 || length(subIDs) == 1.0
                    % Write information to log file
                    if length(subIDs) == 1.0
                        fprintf(fid_debug, '\r\n\tOnly one item detected in the field data');
                    else
                        fprintf(fid_debug, '\r\n\tBased on field IDs, data is either NODAL or CENTROID');
                    end
                    
                    % Data is centroidal or unique nodal
                    if userPosition == 2.0
                        position = 'NODAL';
                        positionID = 1.0;
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as NODAL');
                    elseif userPosition == 4.0
                        position = 'CENTROID';
                        positionID = 4.0;
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as CENTROID');
                    else
                        position = 'NODAL';
                        positionID = 1.0;
                        
                        fprintf(fid_debug, '\r\n\tWarning: User-selected position does not match format of data: field data will be read as NODAL');
                    end
                    
                    positionLabels = mainIDs;
                    connectivity = 0.0;
                    
                    fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                    fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                else
                    % Data is element-nodal or integration point
                    if userPosition == 1.0
                        position = 'ELEMENT_NODAL';
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as ELEMENT_NODAL');
                        positionID = 2.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    elseif userPosition == 3.0
                        position = 'INTEGRATION_POINT';
                        
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as INTEGRATION_POINT');
                        positionID = 3.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getIntegrationPointConnectivity(partInstanceName, mainIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    else
                        position = 'ELEMENT_NODAL';
                        
                        fprintf(fid_debug, '\r\n\tWarning: User-selected position does not match format of data: field data will be read as ELEMENT_NODAL');
                        positionID = 2.0;
                        
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            return
                        end
                        
                        connectivity = connectivityData.nodes;
                    end
                    
                    fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                    positionLabels = connectivityData.elements;
                end
            else
                switch userPosition
                    case 1.0
                        position = 'ELEMENT_NODAL';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as ELEMENT_NODAL');
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getNodalConnectivity(partInstanceName, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            return
                        end
                        
                        fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                        positionLabels = connectivityData.elements;
                        connectivity = connectivityData.nodes;
                        positionID = 2.0;
                    case 2.0
                        position = 'NODAL';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as NODAL');
                        fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                        fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                        positionLabels = mainIDs;
                        connectivity = 0.0;
                        positionID = 1.0;
                    case 3.0
                        position = 'INTEGRATION_POINT';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as INTEGRATION_POINT');
                        fprintf(fid_debug, '\r\n\tRequesting nodal connectivity matrix...');
                        [connectivityData, connectedElements, error] = python.getIntegrationPointConnectivity(partInstanceName, mainIDs, fid_debug, resultsDatabasePath, resultsDatabaseName);
                        
                        if error > 0.0
                            positionLabels = 0.0;
                            position = 0.0;
                            positionLabelData = 0.0;
                            positionID = 0.0;
                            connectivity = 0.0;
                            mainIDs = 0.0;
                            subIDs = 0.0;
                            stepDescription = 0.0;
                            fieldData = 0.0;
                            fieldNames = 0.0;
                            return
                        end
                        
                        fprintf(fid_debug, '\r\n\tTaking position labels from ODB element listing');
                        positionLabels = connectivityData.elements;
                        connectivity = connectivityData.nodes;
                        positionID = 3.0;
                    case 4.0
                        position = 'CENTROID';
                        fprintf(fid_debug, '\r\n\tBased on user selection, field data will be read as CENTROID');
                        fprintf(fid_debug, '\r\n\tTaking position labels from field data main IDs');
                        fprintf(fid_debug, '\r\n\tThe nodal connectivity matrix is not required');
                        positionLabels = mainIDs;
                        connectivity = 0.0;
                        positionID = 4.0;
                end
            end
            
            if isempty(positionLabels) == 1.0
                fprintf(fid_debug, '\r\n\tError: No matching position labels were found from the model output database');
                error = 1.0;
                positionLabels = 0.0;
                position = 0.0;
                positionLabelData = 0.0;
                positionID = 0.0;
                connectivity = 0.0;
                mainIDs = 0.0;
                subIDs = 0.0;
                stepDescription = 0.0;
                fieldData = 0.0;
                fieldNames = 0.0;
                return
            end
            
            fprintf(fid_debug, '\r\n\tGenerating position labels...');
            positionLabelData = '(';
            if strcmpi(position, 'ELEMENT_NODAL') == 1.0
                for i = 1:length(connectedElements)
                    if i == length(connectedElements)
                        positionLabelData = [positionLabelData, sprintf('%.0f)', connectedElements(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', connectedElements(i))]; %#ok<AGROW>
                end
            else
                for i = 1:length(positionLabels)
                    if i == length(positionLabels)
                        positionLabelData = [positionLabelData, sprintf('%.0f)', positionLabels(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', positionLabels(i))]; %#ok<AGROW>
                end
            end
            
            
            %% Get step description
            [job, loading] = fieldDataFile.textdata{2:3};
            try
                c = textscan(loading, '%s%s%s', 'Delimiter', {'\t'});
            catch unhandledException
                fprintf(fid_debug, '\r\n\tError: %s', unhandledException.message);
                
                error = 1.0;
                positionLabels = 0.0;
                position = 0.0;
                positionLabelData = 0.0;
                positionID = 0.0;
                connectivity = 0.0;
                mainIDs = 0.0;
                subIDs = 0.0;
                stepDescription = 0.0;
                fieldData = 0.0;
                fieldNames = 0.0;
                return
            end
            loadingUnits = char(c{3});
            stepDescription = ['version 6.10-07; ', job, ', ', loading];
            
            %% Get the requested field data
            fprintf(fid_debug, ' %.0f fields requested', length(requestedFields(requestedFields == true)));
            
            fieldNamesFile = fieldDataFile.colheaders;
            availableFields = length(fieldNamesFile);
            
            fieldData = zeros(length(mainIDs), length(requestedFields(requestedFields == true)));
            fieldNames = cell(1.0, length(requestedFields(requestedFields == true)));
            
            % Check if the plastic strain energy was calculated
            energyFile = sprintf('Project/output/%s/Data Files/warn_yielding_items.dat', getappdata(0, 'jobName'));
            if (requestedFields(19.0) == true) && exist(energyFile, 'file') == 2.0
                fieldData = zeros(length(mainIDs), 2.0 + length(requestedFields(requestedFields == true)));
                fieldNames = cell(1.0, 2.0 + length(requestedFields(requestedFields == true)));
            else
                YIELD = getappdata(0, 'YIELD');

                if (requestedFields(19.0) == true) && (exist(energyFile, 'file') == 0.0) && (all(YIELD == 0.0) == 1.0)
                    % If YIELD was requested but the model isn't yielding anywhere, inform the user
                    fprintf(fid_debug, '\r\n\tNote: Requested field YIELD is zero everywhere. The field will not be written to the output database');
                elseif (requestedFields(19.0) == true) && (exist(energyFile, 'file') == 0.0) && (all(YIELD == -2.0) == 1.0)
                    % If YIELD was requested but the field could not be evaluated, warn the user
                    fprintf(fid_debug, '\r\n\tWarning: Requested field YIELD could not be evaluated due to insufficient material properties. The field will not be written to the output database');
                elseif (requestedFields(19.0) == true) && (exist(energyFile, 'file') == 0.0) && (all(YIELD == -1.0) == 1.0)
                    % If YIELD was requested but the field was not enabled prior to analysis, warn the user
                    fprintf(fid_debug, '\r\n\tWarning: Requested field YIELD was not enabled. Set yieldCriterion = 1.0 in the environment file. The field will not be written to the output database');
                end
                
                requestedFields(19.0) = false;
            end
            
            % Check if the FOS accuracy is available
            fosAccuracyFile = sprintf('Project/output/%s/Data Files/fos_accuracy.dat', getappdata(0, 'jobName'));
            if (requestedFields(5.0) == true) && exist(fosAccuracyFile, 'file') == 2.0
                fieldData = zeros(length(mainIDs), 1.0 + length(requestedFields(requestedFields == true)));
                fieldNames = cell(1.0, 1.0 + length(requestedFields(requestedFields == true)));
            else
            end
            
            index = 1.0;
            columnsToDelete = 0.0;
            
            if requestedFields(1.0) == true
                % LL is requested
                % Check if the field is available
                
                fieldName = fieldNamesFile{4.0};
                if strcmp(fieldName(1:4), 'LL (') == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, 4.0);
                    fieldNames{index} = sprintf('LL, LOG10(Life) [%s]', loadingUnits);
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field LL could not be found in the field data. The field will not be written to the output database');
                end
            else
                if requestedFields(1.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field LL could not be found in the field data. The field will not be written to the output database');
                end
            end
            
            if requestedFields(2.0) == true
                % L is requested
                % Check if the field is available
                
                fieldName = fieldNamesFile{3.0};
                if strcmp(fieldName(1:3), 'L (') == true
                    % The field exists
                    
                    % Remove INF values
                    tempField = fieldDataFile.data(:, 3.0);
                    tempField(tempField == inf) = 1e7;
                    fieldData(:, index) = tempField;
                    
                    % Cap life values to CAEL
                    if isappdata(0, 'cael') == 1.0
                        cael = getappdata(0, 'cael');
                        if isempty(cael) == 1.0
                            cael = 1e7;
                        end
                        materialCAEL = sprintf('\r\nNote: Life values have been capped at the material CAEL (%g)', cael);
                    else
                        cael = 1e7;
                        materialCAEL = sprintf('\r\nNote: No material CAEL avialable. Life value have been capped at 1e+07');
                    end
                    
                    tempField = fieldDataFile.data(:, 3.0);
                    if any(tempField(tempField > cael)) == 1.0
                        fprintf(fid_debug, materialCAEL);
                        tempField(tempField > cael) = cael;
                        fieldData(:, index) = tempField;
                    end
                    
                    fieldNames{index} = sprintf('L, Life [%s]', loadingUnits);
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field L is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(2.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field L is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(3.0) == true
                % D is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'D')) == true
                    % Remove INF values
                    tempField = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'D') == true)); %#ok<*FNDSB>
                    if any(isinf(tempField)) == 1.0
                       tempField(tempField == inf) = 1.0;
                       fprintf(fid_debug, '\r\n\tWarning: Infinite damage (D) values have been changed to 1e+00');
                    end
                    fieldData(:, index) = tempField;
                    
                    % The field exists
                    fieldNames{index} = sprintf('D, Damage [1/%s]', loadingUnits);
                    
                    index = index + 1.0;
                 else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field D is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(3.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field D is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(4.0) == true
                % DDL is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'DDL')) == true
                    % Remove INF values
                    tempField = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'DDL') == true));
                    if any(isinf(tempField)) == 1.0
                       tempField(tempField == inf) = 1.0;
                       fprintf(fid_debug, '\r\n\tWarning: Infinite damage (DDL) values have been changed to 1e+00');
                    end
                    fieldData(:, index) = tempField;
                    
                    % The field exists
                    fieldNames{index} = sprintf('DDL, Damage at Design Life [1/%s]', loadingUnits);
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field DDL is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(4.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field DDL is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(5.0) == true
                % FOS is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'FOS')) == true
                    % The field exists
                    fos = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'FOS') == true));
                    
                    %{
                        If the FOS field is all -1.0, do not export the
                        field
                    %}
                    if all(fos == -1.0) == 1.0
                        columnsToDelete = columnsToDelete + 1.0;
                        fprintf(fid_debug, '\r\n\tWarning: Requested field FOS is not available. The field will not be written to the output database. To export this field, set FACTOR_OF_STRENGTH = 1.0 in the job file');
                    else
                        fieldData(:, index) = fos;
                        fieldNames{index} = sprintf('FOS, Factor of Strength');
                        
                        if exist(fosAccuracyFile, 'file') == 2.0
                            % Get the FOS accuracy as well
                            fieldDataFile_fosAccuracy = importdata(fosAccuracyFile, '\t');
                            fieldData(:, index + 1.0) = fieldDataFile_fosAccuracy.data(:, 3.0);
                            fieldNames{index + 1.0} = sprintf('FACC, FOS accuracy [%%]');
                            
                            index = index + 2.0;
                        else
                            index = index + 1.0;
                        end
                    end
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FOS is not available. The field will not be written to the output database. To export this field, set FACTOR_OF_STRENGTH = 1.0 in the job file');
                end
            else
                if requestedFields(5.0) == true && availableFields < 7.0
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FOS is not available. The field will not be written to the output database. To export this field, set FACTOR_OF_STRENGTH = 1.0 in the job file');
                end
            end
            
            if requestedFields(6.0) == true
                % SFA is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'SFA')) == true
                    % The field exists
                    
                    % Remove INF values
                    tempField = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'SFA') == true));
                    tempField(tempField == inf) = 10.0;
                    
                    fieldData(:, index) = tempField;
                    fieldNames{index} = sprintf('SFA, Endurance Safety Factor');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SFA is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(6.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SFA is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(7.0) == true
                % FRFR is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'FRFR')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'FRFR') == true));
                    fieldNames{index} = sprintf('FRFR, Fatigue Reserve Factor - Radial');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFR is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(7.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFR is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(8.0) == true
                % FRFH is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'FRFH')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'FRFH') == true));
                    fieldNames{index} = sprintf('FRFH, Fatigue Reserve Factor - Horizontal');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFH is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(8.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFH is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(9.0) == true
                % FRFV is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'FRFV')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'FRFV') == true));
                    fieldNames{index} = sprintf('FRFV, Fatigue Reserve Factor - Vertical');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFV is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(9.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFV is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(10.0) == true
                % FRFW is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'FRFW')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'FRFW') == true));
                    fieldNames{index} = sprintf('FRFW, Fatigue Reserve Factor - Worst');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFW is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(10.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field FRFW is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(11.0) == true
                % SMAX is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'SMAX (MPa)')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'SMAX (MPa)') == true));
                    fieldNames{index} = sprintf('SMAX, Maximum Stress in Loading [MPa]');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMAX is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(11.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMAX is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(12.0) == true
                % SMXP is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'SMXP')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'SMXP') == true));
                    fieldNames{index} = sprintf('SMXP, Maximum Stress in Loading/0.2%% Proof Stress');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMXP is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(12.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMXP is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(13.0) == true
                % SMXU is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'SMXU')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'SMXU') == true));
                    fieldNames{index} = sprintf('SMXU, Maximum Stress in Loading/UTS');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMXU is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(13.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field SMXU is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(14.0) == true
                % TRF is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'TRF')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'TRF') == true));
                    fieldNames{index} = sprintf('TRF, Triaxiality Factor');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field TRF is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(14.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field TRF is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(15.0) == true
                % WCM is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'WCM (MPa)')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'WCM (MPa)') == true));
                    fieldNames{index} = sprintf('WCM, Worst Cycle Mean Stress [MPa]');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCM is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(15.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCM is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(16.0) == true
                % WCA is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'WCA (MPa)')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'WCA (MPa)') == true));
                    fieldNames{index} = sprintf('WCA, Worst Cycle Stress Amplitude [MPa]');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCA is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(16.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCA is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(17.0) == true
                % WCDP is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'WCDP (MPa)')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'WCDP (MPa)') == true));
                    fieldNames{index} = sprintf('WCDP, Worst Cycle Damage Parameter [MPa]');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCDP is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(17.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCDP is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(18.0) == true
                % WCATAN is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'WCATAN (Deg)')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'WCATAN (Deg)') == true));
                    fieldNames{index} = sprintf('WCATAN, Worst Cycle Arctangent');
                    
                    index = index + 1.0;
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCATAN is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(18.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field WCATAN is not available. The field will not be written to the output database');
                end
            end
            
            if requestedFields(19.0) == true
                % YIELD is requested
                % Check if the field is available
                
                if any(strcmp(fieldNamesFile, 'YIELD')) == true
                    % The field exists
                    fieldData(:, index) = fieldDataFile.data(:, find(strcmp(fieldNamesFile, 'YIELD') == true));
                    fieldNames{index} = sprintf('YIELD, Items with plastic strain energy');
                    
                    % Get the associated energies as well
                    fieldDataFile_energy = importdata(energyFile, '\t');
                    energyMainIDs = fieldDataFile_energy.data(:, 1.0);
                    energySubIDs = fieldDataFile_energy.data(:, 2.0);
                    totalStrainEnergy_i = fieldDataFile_energy.data(:, 3.0);
                    plasticStrainEnergy_i = fieldDataFile_energy.data(:, 4.0);
                    totalStrainEnergy = zeros(1.0, length(mainIDs));
                    plasticStrainEnergy = totalStrainEnergy;
                    
                    for i = 1:length(energyMainIDs)
                        matchingMainIDs = find(mainIDs == energyMainIDs(i));
                        matchingSubIDs = find(subIDs == energySubIDs(i));
                        matchingID = intersect(matchingMainIDs, matchingSubIDs);

                        totalStrainEnergy(matchingID) = totalStrainEnergy_i(i);
                        plasticStrainEnergy(matchingID) = plasticStrainEnergy_i(i);
                    end
                    
                    fieldData(:, index + 1.0) = totalStrainEnergy;
                    fieldData(:, index + 2.0) = plasticStrainEnergy;
                    
                    fieldNames{index + 1.0} = sprintf('TSE, Total strain energy [mJ]');
                    fieldNames{index + 2.0} = sprintf('PSE, Plastic strain energy [mJ]');
                else
                    columnsToDelete = columnsToDelete + 1.0;
                    fprintf(fid_debug, '\r\n\tWarning: Requested field YIELD is not available. The field will not be written to the output database');
                end
            else
                if requestedFields(19.0) == true
                    fprintf(fid_debug, '\r\n\tWarning: Requested field YIELD is not available. The field will not be written to the output database');
                end
            end
            
            %% Remove unused field data columns
            if columnsToDelete > 0.0
                fieldData(:, (end - (columnsToDelete - 1.0)):end) = [];
                fieldNames(:, (end - (columnsToDelete - 1.0)):end) = [];
            end
            
            %% Re-order position labels
            %{
                The Abaqus API requires that node and element labels
                supplied to the LABELS argument of the ADDDATA function are
                in ascending order. Therefore, if the values in
                POSITIONLABELS are not in ascending order, re-order them as
                well as the field data
            %}
            if (all(diff(positionLabels) >= 0.0) ~= 1.0) && (strcmpi(position, 'ELEMENT_NODAL') == 0.0)
                % Update the debug log file
                fprintf(fid_debug, '\r\n\tNote: Element IDs for argument LABEL in function ODB.ADDDATA are not increasing. The IDs will be re-ordered');
                
                % Get the length of the label list
                numberOfLabels = length(positionLabels);
                
                % Sort the labels list in ascending order
                positionLabelsSorted = sort(positionLabels);
                
                % Get the number of fields
                [numberOfItems, numberOfFields] = size(fieldData);
                
                % Initialize the variable for the sorted field data
                fieldDataSorted = zeros(numberOfItems, numberOfFields);
                
                % Initialize the index
                index = 1.0;
                
                % Replace the original labels with the sorted labels
                positionLabelData = '(';
                for i = 1:numberOfLabels
                    if i == numberOfLabels
                        positionLabelData = [positionLabelData, sprintf('%.0f)', positionLabelsSorted(i))]; %#ok<AGROW>
                        break
                    end
                    
                    positionLabelData = [positionLabelData, sprintf('%.0f, ', positionLabelsSorted(i))]; %#ok<AGROW>
                end
                
                % Replace the original position labels with the sorted position labels
                positionLabels = positionLabelsSorted;
                
                % Rearrange the field data so that it matches the new position label list
                for label = 1:numberOfLabels
                    newIndex = mainIDs == positionLabelsSorted(label);
                    
                    fieldDataSorted(index:((index - 1.0) + length(find(newIndex == 1.0))), :) = fieldData(newIndex, :);
                    
                    index = 1.0 + ((index - 1.0) + length(find(newIndex == 1.0)));
                end
                
                % Rearrange the main and sub IDs so that they match the new position label list
                mainIDsSorted = sort(mainIDs);
                subIDsSorted = zeros(length(subIDs), 1.0);
                
                % Initialize the index
                index = 1.0;
                
                for i = 1:length(mainIDs)
                    newIndex = find(mainIDs == mainIDsSorted(index));
                    
                    subIDsSorted(index:((index - 1.0) + length(newIndex))) = subIDs(newIndex);
                    
                    index = 1.0 + ((index - 1.0) + length(newIndex));
                    
                    if index > length(mainIDs)
                        break
                    end
                end
                mainIDs = mainIDsSorted;
                subIDs = subIDsSorted;
                
                % Replace the original field data with the sorted field data
                fieldData = fieldDataSorted;
                
                % Rearrange the connectivity matrix so that it matches the new position label list
                if connectivity ~= 0.0
                    connectivitySorted = zeros(numberOfLabels, 20.0);
                    for i = 1:numberOfLabels
                        newIndex = find(positionLabels == positionLabelsSorted(i));
                        connectivitySorted(i, :) = connectivity(newIndex, :);
                    end
                    connectivity = connectivitySorted;
                end
            end
        end
        
        %% Write a Python script which creates the ODB field data
        function [scriptFile, newLocation, stepName, error] = writePythonScript(resultsFileName,...
                resultsDatabasePath, partInstance, positionLabels,...
                position, positionLabelData, positionID, connectivity,...
                mainIDs, subIDs, stepDescription, fieldData, fieldNames, fid_debug,...
                stepName, isExplicit, connectedElements, createODBSet,...
                ODBSetName, stepType)
            % Initialize error flag
            error = 0.0;
            
            % Open the script file for writing
            scriptFile = ['Application_Files\code\odb_interface\', resultsFileName, '.py'];

            fid = fopen(scriptFile, 'w+');
            
            % Copy the ODB to the Abaqus directory
            newLocation = sprintf('%s/%s.odb', resultsDatabasePath, resultsFileName);
            
            % Write the file header
            fprintf(fid, '#AUTOMATICALLY GENERATED PYTHON SCRIPT FOR THE QUICK FATIGUE TOOL ODB INTERFACE');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Author contact:');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   M.Sc. Louis Vallance, AMIMechE');
            fprintf(fid, '\r\n#   louisvallance@hotmail.co.uk');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017');
            fprintf(fid, '\r\n#   Last modified 17-Mar-2017 12:54:53 GMT');
            
            % Write Abaqus import header
            fprintf(fid, '\r\n\r\nfrom odbAccess import *');
            fprintf(fid, '\r\nimport odbAccess');
            fprintf(fid, '\r\nfrom abaqusConstants import *');
            fprintf(fid, '\r\nimport string');
            
            % Specify the source ODB with which to write the output
            fprintf(fid, '\r\n\r\n# Source ODB:');
            fprintf(fid, '\r\nodb = openOdb(path=''%s'')', newLocation);
            
            if stepType == 1.0
                %{
                    If the user requested to write to an existing step, but
                    switched to creating a new step after prompt, make sure
                    that the new step name does not clash with the previous
                    step name
                %}
                if isempty(stepName) == 1.0
                    if getappdata(0, 'appendStepCharacter') == 1.0
                        stepName = '_1';
                        rmappdata(0, 'appendStepCharacter')
                    else
                        stepName = sprintf('QFT_%s_%s', partInstance, stepName);
                    end
                end
                
                % Create a new step in the ODB
                fprintf(fid, '\r\n\r\n# Create a new step:');
                %{
                    If the previous FE analysis step was *DYNAMIC EXPLICIT,
                    add the fatigue results to an Explicit step as well
                %}
                if isExplicit == 1.0
                    fprintf(fid, '\r\nnewStep = odb.Step(name=''%s'', description=''%s'', domain= TIME, timePeriod=1.0, procedure=''*DYNAMIC, EXPLICIT'')', stepName, stepDescription);
                else
                    fprintf(fid, '\r\nnewStep = odb.Step(name=''%s'', description=''%s'', domain= TIME, timePeriod=1.0)', stepName, stepDescription);
                end
                
                % Create a new frame in the ODB
                fprintf(fid, '\r\n\r\n# Create new frame:');
                fprintf(fid, '\r\nnewFrame = newStep.Frame(incrementNumber=1, frameValue=0.1, description=''Fatigue results field data'')');
            else
                %{
                    If results are appended to an existing step, a new step
                    does not have to be created
                %}
            end
            
            % Get the part instance on which to write the data
            fprintf(fid, '\r\n\r\n# Get part instance:');
            fprintf(fid, '\r\ninstance = odb.rootAssembly.instances[''%s'']', partInstance);
            
            % Create the field
            numberOfFields = length(fieldNames);
            
            % Get the number of field items
            [N, ~] = size(fieldData);
            
            % Create the nodal/elemental listing
            %{
                If there is only one position label, append a comma to the
                value so that it agrees with the format required by the
                Abaqus API
            %}
            if length(positionLabels) == 1.0
                fprintf(fid, '\r\nlabelData = (%.0f,)', positionLabels);
            else
                fprintf(fid, '\r\nlabelData = %s', positionLabelData);
            end
            
            %{
                If data position is element-nodal, pre-calculate the
                matching node IDs
            %}
            if positionID == 2.0
                matchingNodeID = zeros(1.0, 1.0);
                
                % Variables to control collapsed elements
                blacklistedElementIDs = [];
                collapsedElements = {};
                collapsedElementsFlag = 0.0;
                numberOfCollapsedElements = 0.0;
                
                for i = 1:length(positionLabels)

                    % For the current element, get the connected nodes
                    connectedNodesAtElement = [];
                    nodesAtElement = length(connectivity(i, :));
                    j = 1.0;
                    while isnan(connectivity(i, j)) == 0.0
                        connectedNodesAtElement = [connectedNodesAtElement, connectivity(i, j)]; %#ok<AGROW>
                        j = j + 1.0;
                        
                        if j > nodesAtElement
                            break
                        end
                    end
                    
                    %{
                        If the element contains collapsed nodes, warn the
                        user and write these nodes to a separate text file
                    %}
                    if length(unique(connectedNodesAtElement)) ~= length(connectedNodesAtElement)
                        collapsedElementsFlag = 1.0;
                        numberOfCollapsedElements = numberOfCollapsedElements + 1.0;
                        collapsedElements{numberOfCollapsedElements} = [connectedElements(i), connectedNodesAtElement]; %#ok<AGROW>
                    end
                    
                    % Get the field values for each node
                    %{
                        There could be a problem here! The following code
                        finds the positions in the field data corresponding
                        to the current element-node in the connectivity
                        matrix. However, it's possible for the connectivity
                        matrix to have an order which differs from the
                        field data.
                        
                        Since the code steps through the elements in the
                        field data from top to bottom and searches for the
                        element at the same location in the connectivity
                        matrix, it's possible that the code may fail to
                        identify the element and the ODB interface will
                        abort under the assumption that the ODB data does
                        not match the field data
                    %}
                    
                    for j = 1:length(connectedNodesAtElement)
                        % All the matching nodes in the field data
                        matchingNodeIDs = find(subIDs == connectedNodesAtElement(j));
                        
                        % Take the node belonging to the current element
                        matchingElements = mainIDs(matchingNodeIDs);
                        %{
                            Instead of calling the next element in the
                            field data, call the next element in the
                            connectivity matrix. This is the correct
                            element and is guaranteed to exist in the field
                            data since the connectivity matrix has already
                            been filtered to only contain elements/nodes
                            already belonging in the dataset(s)
                        %}
                        matchingElement = matchingElements(matchingElements == connectedElements(i));
                        
                        if isempty(matchingElement) == 0.0
                            matchingElement = matchingElement(1.0);
                            
                            % Get the indexes associated with the matching
                            % element
                            matchingElementIDs = find(mainIDs == matchingElement);
                            
                            % Get the node corresponding to the matching
                            % element CRASH
                            intersectValue = intersect(matchingElementIDs, matchingNodeIDs);
                            
                            %{
                                If the element has been collapsed by
                                degeneracy controls, it is possible for the
                                element to contain duplicate nodes. Check
                                the connectivity  at the current element in
                                case of duplicate nodes. The variable
                                BLACKLISTEDELEMENTIDS ensures that each
                                duplicate node can only be identified in
                                the connectivity once
                            %}
                            intersectValue_temp = [];
                            for k = 1:length(intersectValue)
                                if any(find(blacklistedElementIDs == intersectValue(k))) == 0.0
                                    intersectValue_temp = [intersectValue_temp, intersectValue(k)]; %#ok<AGROW>
                                end
                            end
                            intersectValue = intersectValue_temp(1.0);
                            blacklistedElementIDs = [blacklistedElementIDs, intersectValue]; %#ok<AGROW>
                            
                            % Add the current node to the list of matching node IDs
                            matchingNodeID(i, j) = intersectValue;
                        else
                            fprintf(fid_debug, '\r\n\tError: No matching element in the field data could be found for element %.0f in the connectivity matrix', connectedElements(i));
                            fprintf(fid_debug, '\r\n\tExport of field data will be aborted');
                            setappdata(0, 'warning_179_problemElement', connectedElements(i))
                            
                            fclose(fid);
                            delete(scriptFile)
                            delete(newLocation)
                            error = 1.0;
                            return
                        end
                    end
                end
                
                if collapsedElementsFlag == 1.0
                    fprintf(fid_debug, '\r\n\tWarning: %.0f elements appear to be collapsed or degenerate (the element nodes are not unique). If these elements belong to a crack seam, they should not be used for fatigue analysis.', numberOfCollapsedElements);
                    fprintf(fid_debug, '\r\n\tIf the model does not contain this kind of element, check the field data for errors\r\n\t');
                    setappdata(0, 'warning_180_numberOfCollapsedElements', numberOfCollapsedElements)
                    setappdata(0, 'warning_180', 1.0)
                    setappdata(0, 'warning_180_collapsedElements', collapsedElements)
                end
                
                %{
                    If the part instance assignment is incorrect, matchingNodeID
                    may contain zero values. This will cause an out-of-bounds
                    error when field data is written to the variable dataField
                %}
                if any(matchingNodeID == 0.0) == 1.0
                    fprintf(fid_debug, '\r\n\tError: Consistent element-node IDs for instance ''%s'' could not be found between the model output database and the field data (matching node IDs contain zero-valued indices)', partInstance);
                    fprintf(fid_debug, '\r\n\tThis can occur when an invalid part instance is specified');
                    fprintf(fid_debug, '\r\n\tExport of field data will be aborted');
                    setappdata(0, 'warning_067_partInstance', partInstance)
                    
                    fclose(fid);
                    delete(scriptFile)
                    delete(newLocation)
                    error = 1.0;
                    return
                end
            end
            
            fprintf('\t(1 of %.0f),\n', numberOfFields);
            fprintf(fid_debug, '\r\n\t(1 of %.0f)', numberOfFields);
            
            for f = 1:numberOfFields
                % Update the log file
                if f > 1.0
                    fprintf(fid_debug, ', (%.0f of %.0f)', f, numberOfFields);
                    fprintf('\t(%.0f of %.0f),\n', f, numberOfFields);
                end
                
                if stepType == 1.0
                    fprintf(fid, '\r\n\r\n# Create the next field:');
                    fprintf(fid, '\r\nnewField = newFrame.FieldOutput(name="%s", description="%s", type=SCALAR)', fieldNames{f}, fieldNames{f});
                end
                
                % Format the field data
                dataField = '(';
                if (positionID == 1.0) || (positionID == 4.0)
                    % Unique nodal or centroidal
                    for i = 1:N
                        
                        if i == N
                            dataField = [dataField, sprintf('(%f,))', fieldData(i, f))]; %#ok<AGROW>
                            break
                        end
                        
                        dataField = [dataField, sprintf('(%f,), ', fieldData(i, f))]; %#ok<AGROW>
                    end
                elseif positionID == 2.0
                    % Element-nodal or integration point
                    for i = 1:length(positionLabels)
                        % Get the number of connected nodes at the current
                        % element
                        N = length(find(matchingNodeID(i, :) ~= 0.0));
                        
                        % Get the field values for each node
                        for j = 1:N
                            if isempty(matchingElement) == 1.0
                                if j == length(connectedNodesAtElement) && i == length(positionLabels)
                                    dataField = [dataField, '(0.0,))']; %#ok<AGROW>
                                else
                                    dataField = [dataField, '(0.0,), ']; %#ok<AGROW>
                                end
                            else
                                if j == N && i == length(positionLabels)
                                    dataField = [dataField, sprintf('(%f,))', fieldData(matchingNodeID(i, j), f))]; %#ok<AGROW>
                                else
                                    dataField = [dataField, sprintf('(%f,), ', fieldData(matchingNodeID(i, j), f))]; %#ok<AGROW>
                                end
                            end
                        end
                    end
                else
                    % Integration Point
                    for i = 1:N
                        if i == N
                            dataField = [dataField, sprintf('(%f,))', fieldData(i, f))]; %#ok<AGROW>
                            break
                        end
                        
                        dataField = [dataField, sprintf('(%f,), ', fieldData(i, f))]; %#ok<AGROW>
                    end
                end
                
                fprintf(fid, '\r\ndataField = %s', dataField);
                
                % Add data to the ODB field
                fprintf(fid, '\r\n\r\n# Add data to the field:');
                if stepType == 1.0
                    fprintf(fid, '\r\nnewField.addData(position=%s, instance=instance, labels=labelData, data=dataField)', position);
                else
                    fprintf(fid, '\r\nodb.steps[''%s''].frames[0].fieldOutputs[''%s''].addData(position=%s, instance=instance, labels=labelData, data=dataField)',...
                        stepName, fieldNames{f}, position);
                end
            end
            
            % Create an element/node set containing the fatigue results
            if createODBSet == 1.0
                if (positionID == 1.0) || (positionID == 2.0)
                    %{
                        The data is unique nodal or element-nodal. Create a
                        node set
                    %}
                    if positionID == 1.0
                        ODBLabelIDs = unique(mainIDs);
                    else
                        ODBLabelIDs = unique(subIDs);
                    end
                    
                    ODBSetLabels_node = '(';
                    
                    for i = 1:length(ODBLabelIDs)
                        if i == length(ODBLabelIDs)
                            ODBSetLabels_node = [ODBSetLabels_node, sprintf('%.0f)', ODBLabelIDs(i))]; %#ok<AGROW>
                            break
                        end
                        
                        ODBSetLabels_node = [ODBSetLabels_node, sprintf('%.0f, ', ODBLabelIDs(i))]; %#ok<AGROW>
                    end
                    
                    fprintf(fid, '\r\n\r\n# Create a node set for the fatigue results:\r\n');
                    
                    if length(ODBLabelIDs) == 1.0
                        fprintf(fid, 'ODBSetLabels_node = (%.0f,)', ODBLabelIDs);
                    else
                        fprintf(fid, 'ODBSetLabels_node = %s', ODBSetLabels_node);
                    end
                end
                
                if positionID > 1.0
                    %{
                        The data is element-nodal, integration point or
                        centroidal. Create an element set
                    %}
                    ODBLabelIDs = unique(mainIDs);
                    ODBSetLabels_element = '(';
                    
                    for i = 1:length(ODBLabelIDs)
                        if i == length(ODBLabelIDs)
                            ODBSetLabels_element = [ODBSetLabels_element, sprintf('%.0f)', ODBLabelIDs(i))]; %#ok<AGROW>
                            break
                        end
                        
                        ODBSetLabels_element = [ODBSetLabels_element, sprintf('%.0f, ', ODBLabelIDs(i))]; %#ok<AGROW>
                    end
                    
                    fprintf(fid, '\r\n\r\n# Create an element set for the fatigue results:\r\n');
                    
                    if length(ODBLabelIDs) == 1.0
                        fprintf(fid, 'ODBSetLabels_element = (%.0f,)', ODBLabelIDs);
                    else
                        fprintf(fid, 'ODBSetLabels_element = %s', ODBSetLabels_element);
                    end
                end
                
                if (positionID == 1.0) || (positionID == 2.0)
                    % Unique nodal or element-nodal
                    fprintf(fid, '\r\nnodeSet = odb.rootAssembly.NodeSetFromNodeLabels(name=''%s'', nodeLabels=((''%s'', ODBSetLabels_node),))', ODBSetName, partInstance);
                end
                if positionID > 1.0
                    % Element-nodal, integration point or centroidal
                    fprintf(fid, '\r\nelementSet = odb.rootAssembly.ElementSetFromElementLabels(name=''%s'', elementLabels=((''%s'', ODBSetLabels_element),))', ODBSetName, partInstance);
                end
            end
            
            % Update, save and close the ODB
            fprintf(fid, '\r\n\r\n# Save and close the ODB:');
            fprintf(fid, '\r\nodb.update()');
            fprintf(fid, '\r\nodb.save()');
            fprintf(fid, '\r\nodb.close()');
            
            % Close the Python script
            fclose(fid);
        end
        
        %% Query the Abaqus API for the nodal connectivity matrix of the output database
        function [connectivityData, elements, error] = getNodalConnectivity(partInstance, mainIDs, subIDs, fid_debug, resultsDatabasePath, resultsDatabaseName)
            error = 0.0;
            
            % Open the script file for writing
            fid = fopen('Application_Files\code\odb_interface\tmp.py', 'w+');
            
            % Write the file header
            fprintf(fid, '#PYTHON SCRIPT FOR NODAL CONNECTIVITY MATRIX');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Author contact:');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   M.Sc. Louis Vallance, AMIMechE');
            fprintf(fid, '\r\n#   Technical Specialist SIMULIA');
            fprintf(fid, '\r\n#   Office: +43 (1) 22 707 217');
            fprintf(fid, '\r\n#   Mobile: +43 664 889 092 11');
            fprintf(fid, '\r\n#   louis.VALLANCE@3ds.com');
            fprintf(fid, '\r\n#   3DS.com/SIMULIA');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017');
            fprintf(fid, '\r\n#   Last modified 17-Mar-2017 12:54:53 GMT');
            
            % Write Abaqus import header
            fprintf(fid, '\r\n\r\nfrom odbAccess import *');
            fprintf(fid, '\r\nimport odbAccess');
            fprintf(fid, '\r\nfrom abaqusConstants import *');
            fprintf(fid, '\r\nimport string');
            
            % Open the output database
            fprintf(fid, '\r\n\r\n# Open the ODB for reading:');
            fprintf(fid, '\r\nodb = openOdb(path = ''%s'')', [resultsDatabasePath, '/', resultsDatabaseName, '.odb']);
            
            % Get the number of elements in the model
            fprintf(fid, '\r\n\r\n# Get the number of elements from the ODB:');
            fprintf(fid, '\r\nnumberOfElements = len(odb.rootAssembly.instances[''%s''].elements)', partInstance);
            
            % Get the part instance object
            fprintf(fid, '\r\n\r\n# Get the part instance object:');
            fprintf(fid, '\r\ninstance = odb.rootAssembly.instances[''%s'']', partInstance);
            
            % Open the temporary data file for the connectivity data
            fprintf(fid, '\r\n\r\n# Temporary text file for connectivity data:');
            fprintf(fid, '\r\nf = open(''Application_Files/code/odb_interface/tmp.dat'', ''w+'')');
            
            % Loop over each element in the output database to get the
            % connecting nodes for each element
            fprintf(fid, '\r\n\r\n# Loop over elements:');
            fprintf(fid, '\r\nfor i in range(0, numberOfElements):');
            fprintf(fid, '\r\n\telementNumber = instance.elements[i].label');
            fprintf(fid, '\r\n\tnumberOfConnectingNodes = len(instance.elements[i].connectivity)');
            fprintf(fid, '\r\n\telementConnectivity = instance.elements[i].connectivity');
            fprintf(fid, '\r\n\tstring = "%%s\\t%%s\\n" %% (elementNumber, elementConnectivity)');
            fprintf(fid, '\r\n\tf.write(string)');
            
            % Close the temporary file and the output database
            fprintf(fid, '\r\n\r\n# Close files:');
            fprintf(fid, '\r\nf.close()');
            fprintf(fid, '\r\nodb.close()');
            
            fclose(fid);
            
            % Execute the python script
            try
                [status, message] = system(sprintf('%s python Application_Files/code/odb_interface/tmp.py', getappdata(0, 'autoExport_abqCmd')));
                
                if status == 1.0
                    % There is no Abaqus executable on the host machine
                    if getappdata(0, 'ODB_interface_auto') == 1.0
                        fprintf('\n[POST] ERROR: %s', message);
                        rmappdata(0, 'ODB_interface_auto')
                        
                        if isempty(strfind(message, sprintf('KeyError: ''%s''', partInstance))) == 0.0
                            fprintf(fid_debug, '\r\n\tError: The part instance ''%s'' was not found in the output database. Check the definition of PART_INSTANCE in the job file', partInstance);
                        end
                        
                        connectivityData = 0.0;
                        elements = 0.0;
                        delete('Application_Files\code\odb_interface\tmp.py')
                        error = 1.0;
                        return
                    else
                        error = 5.0;
                        setappdata(0, 'abqAPIError', message)
                        connectivityData = 0.0;
                        elements = 0.0;
                        delete('Application_Files\code\odb_interface\tmp.py')
                        return
                    end
                end
            catch unhandledException
                error = 2.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            
            % Read the data from the temporary file
            fid = fopen('tmp.dat');
            
            if fid == -1.0
                error = 3.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: When the nodal connectivity matrix was requested, the Abaqus API returned no data. Check the part instance name');
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            
            try
                cac = textscan(fid, '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f', 'Delimiter', {'\t',','}, 'Whitespace', ' ()', 'CollectOutput', true);
            catch unhandledException
                error = 3.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            fprintf(fid_debug, ' Success');
            fclose(fid);
            
            % Delete the temporary python script
            delete('Application_Files\code\odb_interface\tmp.py')
            
            % Delete the temporary data file
            delete('Application_Files/code/odb_interface/tmp.dat')

            data = cac{:};
            
            %% Remove connectivity data which does not exist in the field
            %% data
            nodes = data(:, 2.0:end);
            elements = data(:, 1.0);
            
            fprintf(fid_debug, '\r\n\t\tDetected %.0f nodes belonging to %.0f elements', 1.0 + length(unique(nodes(isnan(nodes) == 0.0))), length(elements));
            
            % Get intersecting node IDs
            
            % Ignore NaN values in NODES
            nodes_real = nodes;
            nodes_real(isnan(nodes_real)) = [];
            if numel(nodes_real) > length(subIDs)
                intersectingIDs = ismember(nodes_real, subIDs);
                intersectingIDs = nodes_real(intersectingIDs == 1.0);
            else
                intersectingIDs = ismember(subIDs, nodes_real);
                intersectingIDs = subIDs(intersectingIDs == 1.0);
            end
            
            % Remove nodes which aren't included in the field data
            fprintf(fid_debug, '\r\n\t\tChecking for redundant nodes...');
            IDsForDeletion = [];
            
            for i = 1:length(elements)
                j = 1.0;
                while isnan(nodes(i, j)) == 0.0
                    if any(intersectingIDs == nodes(i, j)) == 0.0
                        %{
                            At least one of the nodes at the current
                            element has no field data defined. Mark those
                            nodes and the corresponding element for deletion
                        %}
                        IDsForDeletion = [IDsForDeletion, i]; %#ok<AGROW>
                        break
                    end
                    if j == 20.0
                        %{
                            The element is second order and all nodes are
                            real-valued. Break from the loop to avoid going
                            out of bounds
                        %}
                        break
                    end
                    
                    j = j + 1.0;
                end
            end
            
            if length(IDsForDeletion) == length(nodes)
                fprintf(fid_debug, ' Warning: All nodes were removed');
            elseif isempty(IDsForDeletion) == 0.0
                fprintf(fid_debug, ' %.0f connected node groups removed', length(IDsForDeletion));
            else
                fprintf(fid_debug, ' 0 nodes removed');
            end
            
            % Delete the appropriate elements and their corresponding nodes
            elements(IDsForDeletion) = [];
            nodes(IDsForDeletion, :) = [];
            
            % Repeat the process for elements which do not exist in the
            % field data
            fprintf(fid_debug, '\r\n\t\tChecking for redundant elements...');
            if numel(elements) > length(mainIDs)
                intersectingIDs = ismember(elements, mainIDs);
                intersectingIDs = elements(intersectingIDs == 1.0);
            else
                intersectingIDs = ismember(mainIDs, elements);
                intersectingIDs = mainIDs(intersectingIDs == 1.0);
            end
            
            % Remove elements which aren't included in the field data
            IDsForDeletion = [];
            
            for i = 1:length(elements)
                if any(intersectingIDs == elements(i)) == 0.0
                    %{
                        The current element has no field data defined.
                        Mark this element for deletion
                    %}
                    IDsForDeletion = [IDsForDeletion, i]; %#ok<AGROW>
                end
            end
            
            if length(IDsForDeletion) == length(elements)
                fprintf(fid_debug, ' Warning: All elements were removed');
            elseif isempty(IDsForDeletion) == 0.0
                fprintf(fid_debug, ' %.0f elements removed', length(IDsForDeletion));
            else
                fprintf(fid_debug, ' 0 elements removed');
            end
            
            % Delete the appropriate elements and their corresponding nodes
            elements(IDsForDeletion) = [];
            nodes(IDsForDeletion, :) = [];
            
            %% Add the elements and nodes to the connectivity matrix
            connectivityData = struct('elements', elements, 'nodes', nodes);
        end
        
        %% Query the Abaqus API for the integration point connectivity matrix of the output database
        function [connectivityData, elements, error] = getIntegrationPointConnectivity(partInstance, mainIDs, fid_debug, resultsDatabasePath, resultsDatabaseName)
            error = 0.0;
            
            % Open the script file for writing
            fid = fopen('Application_Files\code\odb_interface\tmp.py', 'w+');
            
            % Write the file header
            fprintf(fid, '#PYTHON SCRIPT FOR INTEGRATION POINT CONNECTIVITY MATRIX');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Author contact:');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   M.Sc. Louis Vallance, AMIMechE');
            fprintf(fid, '\r\n#   Technical Specialist SIMULIA');
            fprintf(fid, '\r\n#   Office: +43 (1) 22 707 217');
            fprintf(fid, '\r\n#   Mobile: +43 664 889 092 11');
            fprintf(fid, '\r\n#   louis.VALLANCE@3ds.com');
            fprintf(fid, '\r\n#   3DS.com/SIMULIA');
            fprintf(fid, '\r\n#');
            fprintf(fid, '\r\n#   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017');
            fprintf(fid, '\r\n#   Last modified 17-Mar-2017 12:54:53 GMT');
            
            % Write Abaqus import header
            fprintf(fid, '\r\n\r\nfrom odbAccess import *');
            fprintf(fid, '\r\nimport odbAccess');
            fprintf(fid, '\r\nfrom abaqusConstants import *');
            fprintf(fid, '\r\nimport string');
            
            % Open the output database
            fprintf(fid, '\r\n\r\n# Open the ODB for reading:');
            fprintf(fid, '\r\nodb = openOdb(path = ''%s'')', [resultsDatabasePath, '/', resultsDatabaseName, '.odb']);
            
            % Get the number of elements in the model
            fprintf(fid, '\r\n\r\n# Get the number of elements from the ODB:');
            fprintf(fid, '\r\nnumberOfElements = len(odb.rootAssembly.instances[''%s''].elements)', partInstance);
            
            % Get the part instance object
            fprintf(fid, '\r\n\r\n# Get the part instance object:');
            fprintf(fid, '\r\ninstance = odb.rootAssembly.instances[''%s'']', partInstance);
            
            % Open the temporary data file for the connectivity data
            fprintf(fid, '\r\n\r\n# Temporary text file for connectivity data:');
            fprintf(fid, '\r\nf = open(''Application_Files/code/odb_interface/tmp.dat'', ''w+'')');
            
            % Loop over each element in the output database to get the
            % connecting integration points for each element
            fprintf(fid, '\r\n\r\n# Loop over elements:');
            fprintf(fid, '\r\nfor i in range(0, numberOfElements):');
            fprintf(fid, '\r\n\telementNumber = instance.elements[i].label');
            fprintf(fid, '\r\n\tnumberOfConnectingIntegrationPoints = len(instance.elements[i].connectivity)');
            fprintf(fid, '\r\n\telementConnectivity = instance.elements[i].connectivity');
            fprintf(fid, '\r\n\tstring = "%%s\\t%%s\\n" %% (elementNumber, elementConnectivity)');
            fprintf(fid, '\r\n\tf.write(string)');
            
            % Close the temporary file and the output database
            fprintf(fid, '\r\n\r\n# Close files:');
            fprintf(fid, '\r\n\r\nf.close()');
            fprintf(fid, '\r\nodb.close()');
            
            fclose(fid);
            
            % Execute the python script
            try
                [status, message] = system(sprintf('%s python Application_Files/code/odb_interface/tmp.py', getappdata(0, 'autoExport_abqCmd')));
                
                if status == 1.0
                    % There is no Abaqus executable on the host machine
                    if getappdata(0, 'ODB_interface_auto') == 1.0
                        fprintf('[POST] ERROR: %s', message);
                        rmappdata(0, 'ODB_interface_auto')
                        
                        if isempty(strfind(message, sprintf('KeyError: ''%s''', partInstance))) == 0.0
                            fprintf(fid_debug, '\r\n\tError: The part instance ''%s'' was not found in the output database. Check the definition of PART_INSTANCE in the job file', partInstance);
                        end
                        
                        connectivityData = 0.0;
                        elements = 0.0;
                        delete('Application_Files\code\odb_interface\tmp.py')
                        error = 1.0;
                        return
                    else
                        error = 5.0;
                        setappdata(0, 'abqAPIError', message)
                        connectivityData = 0.0;
                        elements = 0.0;
                        delete('Application_Files\code\odb_interface\tmp.py')
                        return
                    end
                end
            catch unhandledException
                error = 2.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            
            % Read the data from the temporary file
            fid = fopen('tmp.dat');
            
            if fid == -1.0
                error = 3.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: When the integration point connectivity matrix was requested, the Abaqus API returned no data. Check the part instance name');
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            
            try
                cac = textscan(fid, '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f', 'Delimiter', {'\t',','}, 'Whitespace', ' ()', 'CollectOutput', true);
            catch unhandledException
                error = 3.0;
                connectivityData = 0.0;
                elements = 0.0;
                fprintf(fid_debug, '\r\n\t\tError: %s', unhandledException.message);
                delete('Application_Files\code\odb_interface\tmp.py')
                return
            end
            fprintf(fid_debug, ' Success');
            fclose(fid);
            
            % Delete the temporary python script
            delete('Application_Files\code\odb_interface\tmp.py')
            
            % Delete the temporary data file
            delete('Application_Files/code/odb_interface/tmp.dat')

            data = cac{:};
            
            %{
                Redundant nodes and elements cannot be excluded using this
                method because the script queries the nodal connectivity,
                but the field data from QFT contains element and
                integration point IDs only.
            %}
            
            %% Remove connectivity data which does not exist in the field
            %% data
            nodes = data(:, 2.0:end);
            elements = data(:, 1.0);
            
            fprintf(fid_debug, '\r\n\t\tDetected %.0f nodes belonging to %.0f elements', 1.0 + length(unique(nodes(isnan(nodes) == 0.0))), length(elements));
            
            % Remove elements which do not exist in the
            % field data
            fprintf(fid_debug, '\r\n\t\tChecking for redundant elements...');
            if numel(elements) > length(mainIDs)
                intersectingIDs = ismember(elements, mainIDs);
                intersectingIDs = elements(intersectingIDs == 1.0);
            else
                intersectingIDs = ismember(mainIDs, elements);
                intersectingIDs = mainIDs(intersectingIDs == 1.0);
            end
            
            % Remove elements which aren't included in the field data
            IDsForDeletion = [];
            
            for i = 1:length(elements)
                if any(intersectingIDs == elements(i)) == 0.0
                    %{
                        The current element has no field data defined.
                        Mark this element for deletion
                    %}
                    IDsForDeletion = [IDsForDeletion, i]; %#ok<AGROW>
                end
            end
            
            if length(IDsForDeletion) == length(elements)
                fprintf(fid_debug, ' Warning: All elements were removed');
            elseif isempty(IDsForDeletion) == 0.0
                fprintf(fid_debug, ' %.0f elements removed', length(IDsForDeletion));
            else
                fprintf(fid_debug, ' 0 elements removed');
            end
            
            % Delete the appropriate elements and their corresponding nodes
            elements(IDsForDeletion) = [];
            nodes(IDsForDeletion, :) = [];
            
            %% Add the elements and nodes to the connectivity matrix
            connectivityData = struct('elements', elements, 'nodes', nodes);
        end
        
        %% Check for multiple part instances
        function [instances] = checkMultipleInstances(partInstanceName)
            if isempty(partInstanceName) == 1.0
                instances = [];
                return
            end
            
            instances = regexp(partInstanceName, '(?<=")[^"]+(?=")', 'match');
            
            if isempty(instances) == 1.0
                instances = cellstr(partInstanceName);
                return
            end
            
            if ischar(instances) == 1.0
                % There is only once instance
            elseif iscell(instances) == 1.0
                % There are multiple instances
                
                index = 1.0;
                parse = 1.0;
                while parse == 1.0
                    if index == length(instances)
                        break
                    elseif isempty(instances{index}) == 1.0
                        instances(index) = [];
                    elseif isspace(instances{index}) == 1.0
                        instances(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
        end
    end
end
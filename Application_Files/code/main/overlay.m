classdef overlay < handle
%OVERLAY    QFT class for analysis continuation processing.
%   This class contains methods for analysis continuation processing tasks.
%   
%   OVERLAY is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      4.8 Analysis continuation techniques
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% CHECK THAT THE PREVIOUS JOB EXISTS
        function [error, outputField] = checkJob(outputField)
            error = 0.0;
            
            % Set flag for analysis continuation
            setappdata(0, 'continueAnalysis', 0.0)
            
            % Get the value of CONTINUE_FROM
            continueFrom = getappdata(0, 'continueFrom');
            
            %{
                First, check to see if the CONTINUE_FROM option has been
                defined in the job file. If it is undefined, move on with
                the analysis
            %}
            if isempty(continueFrom) == 1.0
                return
            end
            
            % If CONTINUE_FROM is not a string, exit with an error
            if ischar(continueFrom) == 0.0
                setappdata(0, 'E114', 1.0)
                error = 1.0;
                return
            end
            
            % The current job name must be different from the previous job
            if strcmp(continueFrom, getappdata(0, 'jobName')) == 1.0
                setappdata(0, 'E119', 1.0)
                error = 1.0;
                return
            end
            
            % Check that the previous job exists
            previousJob = sprintf('%s\\Project\\output\\%s\\Data Files\\f-output-all.dat', pwd, continueFrom);
            
            % This function must return 2.0
            fileCheck = exist(previousJob, 'file');
            
            if fileCheck ~= 2.0
                setappdata(0, 'E115', 1.0)
                error = 1.0;
                return
            end
            
            % Try to import the field data from the previous job
            try
                previousJobImport = importdata(previousJob, '\t');
            catch
                setappdata(0, 'E116', 1.0)
                error = 1.0;
                return
            end
            
            % Try to extract field data from the file
            try
                previousJobFieldData = previousJobImport.data;
            catch
                setappdata(0, 'E117', 1.0)
                error = 1.0;
                return
            end
            
            % Try to extract field names from the file
            try
                previousJobFieldNames = previousJobImport.colheaders;
            catch
                setappdata(0, 'E118', 1.0)
                error = 1.0;
                return
            end
            
            % Save the field data from the previous job
            setappdata(0, 'previousJobFieldData', previousJobFieldData(:, 3.0:end))
            
            % Save the field names from the previous job
            setappdata(0, 'previousJobFieldNames', previousJobFieldNames(3.0:end))
            
            % Save the field IDs from the previous job
            setappdata(0, 'previousJobMainID', previousJobFieldData(:, 1.0))
            setappdata(0, 'previousJobSubID', previousJobFieldData(:, 2.0))
            
            % Inform the user about redundant job file options
            messenger.writeMessage(184.0)
            setappdata(0, 'outputField', 1.0)
            outputField = 1.0;
            
            dir = [getappdata(0, 'outputDirectory'), 'Data Files'];
            if exist(dir, 'dir') == 0.0
                try
                    mkdir(dir)
                catch unhandledException
                    setappdata(0, 'E034', 1.0)
                    setappdata(0, 'warning_034_exceptionMessage', unhandledException.identifier)
                    
                    error = 1.0;
                    return
                end
            end
            
            % Set flag for analysis continuation
            setappdata(0, 'continueAnalysis', 1.0)
        end
        
        %% PREPARE FIELD OVERLAY
        function [] = prepare_fields()
            %% GET FIELD DATA FROM PREVIOUS JOB
            
            % Get the field data from the previous job
            fieldDataPrevious = getappdata(0, 'previousJobFieldData');
            
            % Get the field names from the previous job
            fieldNamesPrevious = getappdata(0, 'previousJobFieldNames');
            
            % Get the IDs of the previous job
            mainIDPrevious = getappdata(0, 'previousJobMainID');
            subIDPrevious = getappdata(0, 'previousJobSubID');
            
            %% GET FIELD DATA FROM CURRENT JOB
            
            % Import the current field output file
            fieldDataImport = importdata([pwd, sprintf('\\Project\\output\\%s\\Data Files\\f-output-all.dat', getappdata(0, 'jobName'))], '\t');
            
            % Get the field data from the current job
            fieldDataCurrent = fieldDataImport.data(:, 3.0:end);
            
            % Get the field names from the current job
            fieldNamesCurrent = fieldDataImport.colheaders(3.0:end);
            
            % Get the IDs of the current job
            mainIDCurrent = fieldDataImport.data(:, 1.0);
            subIDCurrent = fieldDataImport.data(:, 2.0);
            
            if (isequal(mainIDCurrent, mainIDPrevious) == 1.0) && (isequal(subIDCurrent, subIDPrevious) == 1.0)
                %% OVERLAY THE FIELDS (SIMPLE METHOD)
                %{
                    If the field IDs match exactly (same values and same
                    order), then the data can be overlaid directly.
                    Otherwise, the elements will have to be searched for
                    individually
                %}
                overlay.fields_simple(fieldDataPrevious, fieldDataCurrent, fieldNamesPrevious, fieldNamesCurrent, mainIDCurrent, subIDCurrent)
            else
                %% OVERLAY THE FIELDS (GENERAL METHOD)
                %{
                    If the position labels between the field output files
                    are not the same or have a different order, the
                    position labels must be sorted to ensure that field
                    output is matched correctly between each job
                %}
                overlay.sort_ids(fieldDataPrevious, fieldDataCurrent, fieldNamesPrevious, fieldNamesCurrent, mainIDCurrent, subIDCurrent, mainIDPrevious, subIDPrevious)
            end
        end
        
        %% OVERLAY FIELD WITH THE PREVIOUS JOB (SIMPLE)
        function [] = fields_simple(fieldDataPrevious, fieldDataCurrent, fieldNamesPrevious, fieldNamesCurrent, mainIDCurrent, subIDCurrent)
            %% Initialize the defined fields
            %{
                The format of the overlaid field output file depends on the
                field data. Typically, the number of fields in each file
                with match, unless one of the analyses used BS 7608 or
                Uniaxial Stress-Life. Therefore, the code must check each
                field against the previous field output file in case there
                is a mismatch. This may slow down the code, but it ensures
                better compatibility and stability
            %}
            fields = [];
            fieldNames = 'Main ID\tSub ID';
            fieldLabels = '%.0f\t%.0f';
            
            %% D
            [isCurrentField, indexCurrent] = ismember('D', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('D', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                D = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                D = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                D = fieldDataPrevious(:, indexPrevious) + fieldDataCurrent(:, indexCurrent);
            else
                D = 'UNDEFINED';
            end
            
            if ischar(D) == 0.0
                % L
                L = 1.0./D;
                
                % LL
                LL = log10(L);
                cael = getappdata(0, 'cael');
                for i = 1:length(LL)
                    if LL(i) > log10(0.5*cael)
                        LL(i) = log10(0.5*cael);
                    elseif LL(i) < 0.0
                        LL(i) = 0.0;
                    end
                end
                
                % DDL
                DDL = D*getappdata(0, 'dLife');
                
                fields = [fields, L, LL, D, DDL];
                fieldNames = [fieldNames, '\tL', sprintf(' (%s)', getappdata(0, 'loadEqUnits')), '\tLL', sprintf(' (%s)', getappdata(0, 'loadEqUnits')), '\tD\tDDL'];
                fieldLabels = [fieldLabels, '\t%.4e\t%.4f\t%.4g\t%.4g'];
            else
                L = 'UNDEFINED'; %#ok<NASGU>
                LL = 'UNDEFINED'; %#ok<NASGU>
                DDL = 'UNDEFINED'; %#ok<NASGU>
            end
            
            %% FOS
            [isCurrentField, indexCurrent] = ismember('FOS', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('FOS', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                FOS = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                FOS = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                FOS_p = fieldDataPrevious(:, indexPrevious); % Previous FOS values
                FOS_p(find(FOS_p == -1.0)) = inf; %#ok<FNDSB>
                FOS = [FOS_p, fieldDataCurrent(:, indexCurrent)]; % Side-by-side
                FOS = min(FOS, [], 2.0); % New FOS values
            else
                FOS = 'UNDEFINED';
            end
            
            if ischar(FOS) == 0.0
                fields = [fields, FOS];
                fieldNames = [fieldNames, '\tFOS'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SFA
            [isCurrentField, indexCurrent] = ismember('SFA', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('SFA', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                SFA = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                SFA = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                SFA_p = fieldDataPrevious(:, indexPrevious);
                SFA_p(find(SFA_p == -1.0)) = inf; %#ok<FNDSB>
                SFA = [SFA_p, fieldDataCurrent(:, indexCurrent)];
                SFA = min(SFA, [], 2.0);
            else
                SFA = 'UNDEFINED';
            end
            
            if ischar(SFA) == 0.0
                fields = [fields, SFA];
                fieldNames = [fieldNames, '\tSFA'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFR
            [isCurrentField, indexCurrent] = ismember('FRFR', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('FRFR', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                FRFR = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                FRFR = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                FRFR_p = fieldDataPrevious(:, indexPrevious);
                FRFR_p(find(FRFR_p == -1.0)) = inf; %#ok<FNDSB>
                FRFR = [FRFR_p, fieldDataCurrent(:, indexCurrent)];
                FRFR = min(FRFR, [], 2.0);
            else
                FRFR = 'UNDEFINED';
            end
            
            if ischar(FRFR) == 0.0
                fields = [fields, FRFR];
                fieldNames = [fieldNames, '\tFRFR'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFH
            [isCurrentField, indexCurrent] = ismember('FRFH', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('FRFH', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                FRFH = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                FRFH = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                FRFH_p = fieldDataPrevious(:, indexPrevious);
                FRFH_p(find(FRFH_p == -1.0)) = inf; %#ok<FNDSB>
                FRFH = [FRFH_p, fieldDataCurrent(:, indexCurrent)];
                FRFH = min(FRFH, [], 2.0);
            else
                FRFH = 'UNDEFINED';
            end
            
            if ischar(FRFH) == 0.0
                fields = [fields, FRFH];
                fieldNames = [fieldNames, '\tFRFH'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFV
            [isCurrentField, indexCurrent] = ismember('FRFV', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('FRFV', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                FRFV = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                FRFV = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                FRFV_p = fieldDataPrevious(:, indexPrevious);
                FRFV_p(find(FRFV_p == -1.0)) = inf; %#ok<FNDSB>
                FRFV = [FRFV_p, fieldDataCurrent(:, indexCurrent)];
                FRFV = min(FRFV, [], 2.0);
            else
                FRFV = 'UNDEFINED';
            end
            
            if ischar(FRFV) == 0.0
                fields = [fields, FRFV];
                fieldNames = [fieldNames, '\tFRFV'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFW
            if (ischar(FRFR) == 0.0) && (ischar(FRFH) == 0.0) && (ischar(FRFV) == 0.0)
                FRFW = [FRFR, FRFH, FRFV];
                FRFW(FRFW == -1.0) = inf;
                FRFW = min(FRFW, [], 2.0);
            else
                FRFW = 'UNDEFINED';
            end
            
            if ischar(FRFW) == 0.0
                fields = [fields, FRFW];
                fieldNames = [fieldNames, '\tFRFW'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMAX
            [isCurrentField, indexCurrent] = ismember('SMAX (MPa)', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('SMAX (MPa)', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                SMAX = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                SMAX = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                SMAX_p = fieldDataPrevious(:, indexPrevious);
                SMAX = [SMAX_p, fieldDataCurrent(:, indexCurrent)];
                SMAX_max = max(SMAX, [], 2.0);
                SMAX_min = min(SMAX, [], 2.0);
                
                SMAX = zeros(length(SMAX_p), 1.0);
                N = length(SMAX);
                for i = 1:N
                    if abs(SMAX_max(i)) > abs(SMAX_min(i))
                        SMAX(i) = SMAX_max(i);
                    else
                        SMAX(i) = SMAX_min(i);
                    end
                end
            else
                SMAX = 'UNDEFINED';
            end
            
            if ischar(SMAX) == 0.0
                fields = [fields, SMAX];
                fieldNames = [fieldNames, '\tSMAX (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXP
            [isCurrentField, indexCurrent] = ismember('SMXP', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('SMXP', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                SMXP = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                SMXP = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                SMXP_p = fieldDataPrevious(:, indexPrevious);
                SMXP = [SMXP_p, fieldDataCurrent(:, indexCurrent)];
                SMXP = max(SMXP, [], 2.0);
            else
                SMXP = 'UNDEFINED';
            end
            
            if ischar(SMXP) == 0.0
                fields = [fields, SMXP];
                fieldNames = [fieldNames, '\tSMXP'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXU
            [isCurrentField, indexCurrent] = ismember('SMXU', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('SMXU', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                SMXU = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                SMXU = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                SMXU_p = fieldDataPrevious(:, indexPrevious);
                SMXU = [SMXU_p, fieldDataCurrent(:, indexCurrent)];
                SMXU = max(SMXU, [], 2.0);
            else
                SMXU = 'UNDEFINED';
            end
            
            if ischar(SMXU) == 0.0
                fields = [fields, SMXU];
                fieldNames = [fieldNames, '\tSMXU'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% TRF
            [isCurrentField, indexCurrent] = ismember('TRF', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('TRF', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                TRF = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                TRF = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                TRF_p = fieldDataPrevious(:, indexPrevious);
                TRF = [TRF_p, fieldDataCurrent(:, indexCurrent)];
                TRF = max(TRF, [], 2.0);
            else
                TRF = 'UNDEFINED';
            end
            
            if ischar(TRF) == 0.0
                fields = [fields, TRF];
                fieldNames = [fieldNames, '\tTRF'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCM
            [isCurrentField, indexCurrent] = ismember('WCM (MPa)', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('WCM (MPa)', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                WCM = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                WCM = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                WCM_p = fieldDataPrevious(:, indexPrevious);
                WCM = [WCM_p, fieldDataCurrent(:, indexCurrent)];
                WCM = max(WCM, [], 2.0);
            else
                WCM = 'UNDEFINED';
            end
            
            if ischar(WCM) == 0.0
                fields = [fields, WCM];
                fieldNames = [fieldNames, '\tWCM (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCA
            [isCurrentField, indexCurrent] = ismember('WCA (MPa)', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('WCA (MPa)', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                WCA = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                WCA = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                WCA_p = fieldDataPrevious(:, indexPrevious);
                WCA = [WCA_p, fieldDataCurrent(:, indexCurrent)];
                WCA = max(WCA, [], 2.0);
            else
                WCA = 'UNDEFINED';
            end
            
            if ischar(WCA) == 0.0
                fields = [fields, WCA];
                fieldNames = [fieldNames, '\tWCA (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCATAN
            if (ischar(WCM) == 0.0) && (ischar(WCA) == 0.0)
                WCATAN = atand(WCM./WCA);
            else
                WCATAN = 'UNDEFINED';
            end
            
            if ischar(WCATAN) == 0.0
                fields = [fields, WCATAN];
                fieldNames = [fieldNames, '\tWCATAN (Deg)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCDP
            [isCurrentField, indexCurrent] = ismember('WCDP (MPa)', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('WCDP (MPa)', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                WCDP = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                WCDP = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                WCDP_p = fieldDataPrevious(:, indexPrevious);
                WCDP = [WCDP_p, fieldDataCurrent(:, indexCurrent)];
                WCDP = max(WCDP, [], 2.0);
            else
                WCDP = 'UNDEFINED';
            end
            
            if ischar(WCDP) == 0.0
                fields = [fields, WCDP];
                fieldNames = [fieldNames, '\tWCDP (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% YIELD
            [isCurrentField, indexCurrent] = ismember('YIELD', fieldNamesCurrent);
            [isPreviousField, indexPrevious] = ismember('YIELD', fieldNamesPrevious);
            
            if (isCurrentField == 1.0) && (isPreviousField == 0.0)
                YIELD = fieldDataCurrent(:, indexCurrent);
            elseif (isCurrentField == 0.0) && (isPreviousField == 1.0)
                YIELD = fieldDataPrevious(:, indexPrevious);
            elseif (isCurrentField == 1.0) && (isPreviousField == 1.0)
                YIELD_p = fieldDataPrevious(:, indexPrevious);
                YIELD = [YIELD_p, fieldDataCurrent(:, indexCurrent)];
                YIELD = max(YIELD, [], 2.0);
            else
                YIELD = 'UNDEFINED';
            end
            
            if ischar(YIELD) == 0.0
                fields = [fields, YIELD];
                fieldNames = [fieldNames, '\tYIELD'];
                fieldLabels = [fieldLabels, '\t%.0f'];
            end
            
            %% WRITE NEW FIELD DATA
            
            % Rename the existing field output file
            jobName = getappdata(0, 'jobName');
            oldFieldFile = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\f-output-all.dat', jobName)];
            newFieldFile = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\f-output-all_%s.dat', jobName, jobName)];
            movefile(oldFieldFile, newFieldFile)
            
            data = [mainIDCurrent'; subIDCurrent'; fields']';
            fieldNames = [fieldNames, '\r\n'];
            fieldLabels = [fieldLabels, '\r\n'];
            
            if getappdata(0, 'file_F_OUTPUT_ALL') == 1.0
                dir = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-all.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'FIELDS [WHOLE MODEL]\r\nJob:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
                
                fprintf(fid, fieldNames);
                fprintf(fid, fieldLabels, data');
                
                fclose(fid);
            end
        end
        
        %% SORT THE FIELD IDS FOR GENERAL OVERLAY
        function [] = sort_ids(fieldDataPrevious, fieldDataCurrent, fieldNamesPrevious, fieldNamesCurrent, mainIDCurrent, subIDCurrent, mainIDPrevious, subIDPrevious)
            %{
                The overlay is split between two tasks. First, matching
                position IDs are located, and field data between these
                common items is superimposed onto each other. Next,
                outsider items are appended onto the end of the new field
                output file from each job, without superposition
            
                Because the general technique assumes that each field
                output file has an arbitrary order, the position IDs must
                be re-ordered prior to the overlay so that matrix addition
                matches the correct items with each other
            %}
            
            %% Re-build the ID list
            %{
                Parse through the ID list of the smaller file (if
                applicable). For each item, attempt to match that item to an
                item in the other file. If the item does not exist in the
                other file, append it to the end of the new ID list
            %}
            if length(mainIDCurrent) < length(mainIDPrevious)
                N = length(mainIDCurrent);
                
                mainIDsA = mainIDCurrent;
                mainIDsB = mainIDPrevious;
                
                subIDsA = subIDCurrent;
                subIDsB = subIDPrevious;
                
                fieldDataA = fieldDataCurrent;
                fieldDataB = fieldDataPrevious;
                
                fieldNamesA = fieldNamesCurrent;
                fieldNamesB = fieldNamesPrevious;
            else
                N = length(mainIDPrevious);
                
                mainIDsA = mainIDPrevious;
                mainIDsB = mainIDCurrent;
                
                subIDsA = subIDPrevious;
                subIDsB = subIDCurrent;
                
                fieldDataA = fieldDataPrevious;
                fieldDataB = fieldDataCurrent;
                
                fieldNamesA = fieldNamesPrevious;
                fieldNamesB = fieldNamesCurrent;
            end
            
            mainIndexesInA = [];
            mainIndexesInB = [];
            
            duplicateIDs = [];
            
            for i = 1:N
                %{
                    Find the IDs in dataset B matching each ID in dataset
                    A. Only IDs common to both datasets will match
                %}
                matchingMainIDs = find(mainIDsB == mainIDsA(i));
                matchingSubIDs = find(subIDsB == subIDsA(i));
                
                matchingID = intersect(matchingMainIDs, matchingSubIDs);
                
                if isempty(matchingID) == 0.0
                    matchingID = matchingID(1.0);
                end
                
                %{
                    There could be multiple matching IDs. In this case
                    there are duplicate IDs whose relationship cannot be
                    disambiguated. Alternatively, there may be no matching
                    ID at all in the event that there are uncommon elements
                    between the jobs
                %}
                if ismember(matchingID, mainIndexesInB) == 1.0
                    %{
                        If the matching ID has already been identified, it
                        is a duplicate and cannot be used in the overlay
                    %}
                    duplicateIDs = duplicateIDs + 1.0;
                    
                    continue
                end
                
                % Add the matching ID to the new list
                if isempty(matchingID) == 0.0
                    mainIndexesInB(i) = matchingID; %#ok<AGROW>
                    mainIndexesInA(i) = i; %#ok<AGROW>
                end
            end
            
            % Warn the user of ambiguous items if applicable
            if duplicateIDs > 0.0
                setappdata(0, 'message_189_duplicateItems', duplicateIDs)
                messenger.writeMessage(189.0)
            end
            
            %% Get the overlay ID list
            %{
                Field data B (the longer dataset) must be re-ordered so 
                that it consists of a region of items which can be overlaid
                onto field data A, followed by a region of items which do
                not belong to dataset A. The first set will be superimposed
                onto A; the second set will be appended
            %}
            
            % Create overlay IDs list
            mainIDs_overlay = mainIDsB(mainIndexesInB(mainIndexesInB ~= 0.0));
            subIDs_overlay = subIDsB(mainIndexesInB(mainIndexesInB ~= 0.0));
            
            % Create overlay field data
            fieldDataA_overlay = fieldDataA(mainIndexesInA(mainIndexesInA ~= 0.0), :);
            fieldDataB_overlay = fieldDataB(mainIndexesInB(mainIndexesInB ~= 0.0), :);
            
            %% Get the unique ID list
            %{
                The remaining IDs and field data must be identified. This
                data will be appended to the end of the new field output
                file
            %}
            addressA = linspace(1.0, length(mainIDsA), length(mainIDsA));
            addressA(mainIndexesInA(mainIndexesInA ~= 0.0)) = [];
            
            addressB = linspace(1.0, length(mainIDsB), length(mainIDsB));
            addressB(mainIndexesInB(mainIndexesInB ~= 0.0)) = [];
            
            mainIDsA_append = mainIDsA(addressA);
            mainIDsB_append = mainIDsB(addressB);
            
            subIDsA_append = subIDsA(addressA);
            subIDsB_append = subIDsB(addressB);
            
            fieldDataA_append = fieldDataA(addressA, :);
            fieldDataB_append = fieldDataB(addressB, :);
            
            mainIDs_append = [mainIDsA_append; mainIDsB_append];
            subIDs_append = [subIDsA_append; subIDsB_append];
            
            %{
                The overlay process checks for inconsistent field
                information between each job. Overlaid fields with
                inconsistent output variables will be rectified, therefore
                the appended data should also be rectified if applicable
            %}
            [fieldDataA_append, fieldDataB_append, fieldNames_append, fieldLabels_append] = overlay.check_appended_fields(fieldDataA_append, fieldDataB_append, fieldNamesA, fieldNamesB);
            
            fieldData_append = [fieldDataA_append; fieldDataB_append];
            
            %% Overlay the fields
            %{
                The format of the overlaid field output file depends on the
                field data. Typically, the number of fields in each file
                with match, unless one of the analyses used BS 7608 or
                Uniaxial Stress-Life. Therefore, the code must check each
                field against the previous field output file in case there
                is a mismatch. This may slow down the code, but it ensures
                better compatibility and stability
            
                Overlay is only possible if there are matching items in the
                field output files
            %}
            if isempty(fieldDataA_overlay) == 0.0
                [fields, fieldNames, fieldLabels] = overlay.fields_general(fieldDataA_overlay, fieldDataB_overlay, fieldNamesA, fieldNamesB);
                
                %{
                    The relevant field data has been overlaid. Next, append
                    the remaining data (if any) onto the new field output
                %}
                fields = [fields; fieldData_append];
                
                mainIDs = [mainIDs_overlay; mainIDs_append];
                subIDs = [subIDs_overlay; subIDs_append];
            else
                %{
                    There are no matching IDs between each dataset.
                    Therefore, no field output can be overlaid. Append all
                    of the field data from dataset B to dataset A
                %}
                mainIDs = mainIDs_append;
                subIDs = subIDs_append;
                
                fields = [fieldDataA_append; fieldDataB_append];
                
                fieldNames = fieldNames_append;
                fieldLabels = fieldLabels_append;
            end
            
            %% Write new field data
            
            % Rename the existing field output file
            jobName = getappdata(0, 'jobName');
            oldFieldFile = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\f-output-all.dat', jobName)];
            newFieldFile = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\f-output-all_%s.dat', jobName, jobName)];
            
            %{
                Try to copy the current field output file. This will only
                work if the file is not currently in use
            %}
            try
                [~, MESSAGE, ~] = movefile(oldFieldFile, newFieldFile);
            catch
                setappdata(0, 'message_191_message', MESSAGE)
                messenger.writeMessage(191.0)
                return
            end
            
            data = [mainIDs'; subIDs'; fields']';
            
            if getappdata(0, 'file_F_OUTPUT_ALL') == 1.0
                dir = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-all.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'FIELDS [WHOLE MODEL]\r\nJob:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
                
                fprintf(fid, fieldNames);
                fprintf(fid, fieldLabels, data');
                
                fclose(fid);
            end
        end
        
        %% OVERLAY FIELD WITH THE PREVIOUS JOB (GENERAL)
        function [fields, fieldNames, fieldLabels] = fields_general(fieldDataA_overlay, fieldDataB_overlay, fieldNamesA, fieldNamesB)
            fields = [];
            fieldNames = 'Main ID\tSub ID';
            fieldLabels = '%.0f\t%.0f';
            
            %% D
            [isAField, indexA] = ismember('D', fieldNamesA);
            [isBField, indexB] = ismember('D', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                D = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                D = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                D = fieldDataB_overlay(:, indexB) + fieldDataA_overlay(:, indexA);
            else
                D = 'UNDEFINED';
            end
            
            if ischar(D) == 0.0
                % L
                L = 1.0./D;
                
                % LL
                LL = log10(L);
                cael = getappdata(0, 'cael');
                for i = 1:length(LL)
                    if LL(i) > log10(0.5*cael)
                        LL(i) = log10(0.5*cael);
                    elseif LL(i) < 0.0
                        LL(i) = 0.0;
                    end
                end
                
                % DDL
                DDL = D*getappdata(0, 'dLife');
                
                fields = [fields, L, LL, D, DDL];
                fieldNames = [fieldNames, '\tL', sprintf(' (%s)', getappdata(0, 'loadEqUnits')), '\tLL', sprintf(' (%s)', getappdata(0, 'loadEqUnits')), '\tD\tDDL'];
                fieldLabels = [fieldLabels, '\t%.4e\t%.4f\t%.4g\t%.4g'];
            else
                L = 'UNDEFINED'; %#ok<NASGU>
                LL = 'UNDEFINED'; %#ok<NASGU>
                DDL = 'UNDEFINED'; %#ok<NASGU>
            end
            
            %% FOS
            [isAField, indexA] = ismember('FOS', fieldNamesA);
            [isBField, indexB] = ismember('FOS', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                FOS = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                FOS = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                FOS_p = fieldDataB_overlay(:, indexB); % Previous FOS values
                FOS_p(find(FOS_p == -1.0)) = inf; %#ok<FNDSB>
                FOS = [FOS_p, fieldDataA_overlay(:, indexA)]; % Side-by-side
                FOS = min(FOS, [], 2.0); % New FOS values
            else
                FOS = 'UNDEFINED';
            end
            
            if ischar(FOS) == 0.0
                fields = [fields, FOS];
                fieldNames = [fieldNames, '\tFOS'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SFA
            [isAField, indexA] = ismember('SFA', fieldNamesA);
            [isBField, indexB] = ismember('SFA', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                SFA = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                SFA = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                SFA_p = fieldDataB_overlay(:, indexB);
                SFA_p(find(SFA_p == -1.0)) = inf; %#ok<FNDSB>
                SFA = [SFA_p, fieldDataA_overlay(:, indexA)];
                SFA = min(SFA, [], 2.0);
            else
                SFA = 'UNDEFINED';
            end
            
            if ischar(SFA) == 0.0
                fields = [fields, SFA];
                fieldNames = [fieldNames, '\tSFA'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFR
            [isAField, indexA] = ismember('FRFR', fieldNamesA);
            [isBField, indexB] = ismember('FRFR', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                FRFR = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                FRFR = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                FRFR_p = fieldDataB_overlay(:, indexB);
                FRFR_p(find(FRFR_p == -1.0)) = inf; %#ok<FNDSB>
                FRFR = [FRFR_p, fieldDataA_overlay(:, indexA)];
                FRFR = min(FRFR, [], 2.0);
            else
                FRFR = 'UNDEFINED';
            end
            
            if ischar(FRFR) == 0.0
                fields = [fields, FRFR];
                fieldNames = [fieldNames, '\tFRFR'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFH
            [isAField, indexA] = ismember('FRFH', fieldNamesA);
            [isBField, indexB] = ismember('FRFH', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                FRFH = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                FRFH = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                FRFH_p = fieldDataB_overlay(:, indexB);
                FRFH_p(find(FRFH_p == -1.0)) = inf; %#ok<FNDSB>
                FRFH = [FRFH_p, fieldDataA_overlay(:, indexA)];
                FRFH = min(FRFH, [], 2.0);
            else
                FRFH = 'UNDEFINED';
            end
            
            if ischar(FRFH) == 0.0
                fields = [fields, FRFH];
                fieldNames = [fieldNames, '\tFRFH'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFV
            [isAField, indexA] = ismember('FRFV', fieldNamesA);
            [isBField, indexB] = ismember('FRFV', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                FRFV = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                FRFV = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                FRFV_p = fieldDataB_overlay(:, indexB);
                FRFV_p(find(FRFV_p == -1.0)) = inf; %#ok<FNDSB>
                FRFV = [FRFV_p, fieldDataA_overlay(:, indexA)];
                FRFV = min(FRFV, [], 2.0);
            else
                FRFV = 'UNDEFINED';
            end
            
            if ischar(FRFV) == 0.0
                fields = [fields, FRFV];
                fieldNames = [fieldNames, '\tFRFV'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFW
            if (ischar(FRFR) == 0.0) && (ischar(FRFH) == 0.0) && (ischar(FRFV) == 0.0)
                FRFW = [FRFR, FRFH, FRFV];
                FRFW(FRFW == -1.0) = inf;
                FRFW = min(FRFW, [], 2.0);
            else
                FRFW = 'UNDEFINED';
            end
            
            if ischar(FRFW) == 0.0
                fields = [fields, FRFW];
                fieldNames = [fieldNames, '\tFRFW'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMAX
            [isAField, indexA] = ismember('SMAX (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('SMAX (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                SMAX = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                SMAX = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                SMAX_p = fieldDataB_overlay(:, indexB);
                SMAX = [SMAX_p, fieldDataA_overlay(:, indexA)];
                SMAX_max = max(SMAX, [], 2.0);
                SMAX_min = min(SMAX, [], 2.0);
                
                SMAX = zeros(length(SMAX_p), 1.0);
                N = length(SMAX);
                for i = 1:N
                    if abs(SMAX_max(i)) > abs(SMAX_min(i))
                        SMAX(i) = SMAX_max(i);
                    else
                        SMAX(i) = SMAX_min(i);
                    end
                end
            else
                SMAX = 'UNDEFINED';
            end
            
            if ischar(SMAX) == 0.0
                fields = [fields, SMAX];
                fieldNames = [fieldNames, '\tSMAX (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXP
            [isAField, indexA] = ismember('SMXP', fieldNamesA);
            [isBField, indexB] = ismember('SMXP', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                SMXP = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                SMXP = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                SMXP_p = fieldDataB_overlay(:, indexB);
                SMXP = [SMXP_p, fieldDataA_overlay(:, indexA)];
                SMXP = max(SMXP, [], 2.0);
            else
                SMXP = 'UNDEFINED';
            end
            
            if ischar(SMXP) == 0.0
                fields = [fields, SMXP];
                fieldNames = [fieldNames, '\tSMXP'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXU
            [isAField, indexA] = ismember('SMXU', fieldNamesA);
            [isBField, indexB] = ismember('SMXU', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                SMXU = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                SMXU = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                SMXU_p = fieldDataB_overlay(:, indexB);
                SMXU = [SMXU_p, fieldDataA_overlay(:, indexA)];
                SMXU = max(SMXU, [], 2.0);
            else
                SMXU = 'UNDEFINED';
            end
            
            if ischar(SMXU) == 0.0
                fields = [fields, SMXU];
                fieldNames = [fieldNames, '\tSMXU'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% TRF
            [isAField, indexA] = ismember('TRF', fieldNamesA);
            [isBField, indexB] = ismember('TRF', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                TRF = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                TRF = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                TRF_p = fieldDataB_overlay(:, indexB);
                TRF = [TRF_p, fieldDataA_overlay(:, indexA)];
                TRF = max(TRF, [], 2.0);
            else
                TRF = 'UNDEFINED';
            end
            
            if ischar(TRF) == 0.0
                fields = [fields, TRF];
                fieldNames = [fieldNames, '\tTRF'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCM
            [isAField, indexA] = ismember('WCM (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCM (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                WCM = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                WCM = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                WCM_p = fieldDataB_overlay(:, indexB);
                WCM = [WCM_p, fieldDataA_overlay(:, indexA)];
                WCM = max(WCM, [], 2.0);
            else
                WCM = 'UNDEFINED';
            end
            
            if ischar(WCM) == 0.0
                fields = [fields, WCM];
                fieldNames = [fieldNames, '\tWCM (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCA
            [isAField, indexA] = ismember('WCA (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCA (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                WCA = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                WCA = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                WCA_p = fieldDataB_overlay(:, indexB);
                WCA = [WCA_p, fieldDataA_overlay(:, indexA)];
                WCA = max(WCA, [], 2.0);
            else
                WCA = 'UNDEFINED';
            end
            
            if ischar(WCA) == 0.0
                fields = [fields, WCA];
                fieldNames = [fieldNames, '\tWCA (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCATAN
            if (ischar(WCM) == 0.0) && (ischar(WCA) == 0.0)
                WCATAN = atand(WCM./WCA);
            else
                WCATAN = 'UNDEFINED';
            end
            
            if ischar(WCATAN) == 0.0
                fields = [fields, WCATAN];
                fieldNames = [fieldNames, '\tWCATAN (Deg)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCDP
            [isAField, indexA] = ismember('WCDP (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCDP (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                WCDP = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                WCDP = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                WCDP_p = fieldDataB_overlay(:, indexB);
                WCDP = [WCDP_p, fieldDataA_overlay(:, indexA)];
                WCDP = max(WCDP, [], 2.0);
            else
                WCDP = 'UNDEFINED';
            end
            
            if ischar(WCDP) == 0.0
                fields = [fields, WCDP];
                fieldNames = [fieldNames, '\tWCDP (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% YIELD
            [isAField, indexA] = ismember('YIELD', fieldNamesA);
            [isBField, indexB] = ismember('YIELD', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                YIELD = fieldDataA_overlay(:, indexA);
            elseif (isAField == 0.0) && (isBField == 1.0)
                YIELD = fieldDataB_overlay(:, indexB);
            elseif (isAField == 1.0) && (isBField == 1.0)
                YIELD_p = fieldDataB_overlay(:, indexB);
                YIELD = [YIELD_p, fieldDataA_overlay(:, indexA)];
                YIELD = max(YIELD, [], 2.0);
            else
                YIELD = 'UNDEFINED';
            end
            
            if ischar(YIELD) == 0.0
                fields = [fields, YIELD];
                fieldNames = [fieldNames, '\tYIELD'];
                fieldLabels = [fieldLabels, '\t%.0f'];
            end
            
            fieldNames = [fieldNames, '\r\n'];
            fieldLabels = [fieldLabels, '\r\n'];
        end
        
        %% CHECK APPENDED FIELDS FOR INCONSISTENT OUTPUT
        function [fieldDataA_append, fieldDataB_append, fieldNames, fieldLabels] = check_appended_fields(fieldDataA_append, fieldDataB_append, fieldNamesA, fieldNamesB)
            %{
                If the algorithm between each job is different, there could
                be a different number of fields written to each file. Check
                the column data in the field output and append "dummy"
                values where necessary in order to ensure dimensional
                consistency
            %}
            [Ra, ~] = size(fieldDataA_append);
            [Rb, ~] = size(fieldDataB_append);
            
            fieldNames = 'Main ID\tSub ID';
            fieldLabels = '%.0f\t%.0f';
            
            loadEqUnits = getappdata(0, 'loadEqUnits');
            
            %% D
            [isAField, indexA] = ismember('D', fieldNamesA);
            [isBField, indexB] = ismember('D', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            %% L
            [isAField, indexA] = ismember(sprintf('L (%s)', loadEqUnits), fieldNamesA);
            [isBField, indexB] = ismember(sprintf('L (%s)', loadEqUnits), fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            %% LL
            [isAField, indexA] = ismember(sprintf('LL (%s)', loadEqUnits), fieldNamesA);
            [isBField, indexB] = ismember(sprintf('LL (%s)', loadEqUnits), fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            %% DDL
            [isAField, indexA] = ismember('DDL', fieldNamesA);
            [isBField, indexB] = ismember('DDL', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tL', sprintf(' (%s)', loadEqUnits)];
                fieldLabels = [fieldLabels, '\t%.4e'];
            end
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tLL', sprintf(' (%s)', loadEqUnits)];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tD'];
                fieldLabels = [fieldLabels, '\t%.4g'];
            end
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tDDL'];
                fieldLabels = [fieldLabels, '\t%.4g'];
            end
            
            %% FOS
            [isAField, indexA] = ismember('FOS', fieldNamesA);
            [isBField, indexB] = ismember('FOS', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tFOS'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SFA
            [isAField, indexA] = ismember('SFA', fieldNamesA);
            [isBField, indexB] = ismember('SFA', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tSFA'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFR
            [isAField, indexA] = ismember('FRFR', fieldNamesA);
            [isBField, indexB] = ismember('FRFR', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tFRFR'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFH
            [isAField, indexA] = ismember('FRFH', fieldNamesA);
            [isBField, indexB] = ismember('FRFH', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tFRFH'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFV
            [isAField, indexA] = ismember('FRFV', fieldNamesA);
            [isBField, indexB] = ismember('FRFV', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tFRFV'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% FRFW
            [isAField, indexA] = ismember('FRFW', fieldNamesA);
            [isBField, indexB] = ismember('FRFW', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tFRFW'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMAX
            [isAField, indexA] = ismember('SMAX (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('SMAX (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tSMAX (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXP
            [isAField, indexA] = ismember('SMXP', fieldNamesA);
            [isBField, indexB] = ismember('SMXP', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tSMXP'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% SMXU
            [isAField, indexA] = ismember('SMXU', fieldNamesA);
            [isBField, indexB] = ismember('SMXU', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tSMXU'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% TRF
            [isAField, indexA] = ismember('TRF', fieldNamesA);
            [isBField, indexB] = ismember('TRF', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tTRF'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCM
            [isAField, indexA] = ismember('WCM (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCM (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tWCM (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCA
            [isAField, indexA] = ismember('WCA (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCA (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tWCA (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCATAN
            [isAField, indexA] = ismember('WCATAN (Deg)', fieldNamesA);
            [isBField, indexB] = ismember('WCATAN (Deg)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tWCATAN (Deg)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% WCDP
            [isAField, indexA] = ismember('WCDP (MPa)', fieldNamesA);
            [isBField, indexB] = ismember('WCDP (MPa)', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tWCDP (MPa)'];
                fieldLabels = [fieldLabels, '\t%.4f'];
            end
            
            %% YIELD
            [isAField, indexA] = ismember('YIELD', fieldNamesA);
            [isBField, indexB] = ismember('YIELD', fieldNamesB);
            
            if (isAField == 1.0) && (isBField == 0.0)
                fieldDataB_append = [fieldDataB_append(:, 1.0:indexA - 1.0), linspace(-1.0, -1.0, Rb)', fieldDataB_append(:, indexA:end)];
            elseif (isAField == 0.0) && (isBField == 1.0)
                fieldDataA_append = [fieldDataA_append(:, 1.0:indexB - 1.0), linspace(-1.0, -1.0, Ra)', fieldDataA_append(:, indexB:end)];
            end
            
            if (isAField == 1.0) || (isBField == 1.0)
                fieldNames = [fieldNames, '\tYIELD'];
                fieldLabels = [fieldLabels, '\t%.0f'];
            end
            
            fieldNames = [fieldNames, '\r\n'];
            fieldLabels = [fieldLabels, '\r\n'];
        end
    end
end
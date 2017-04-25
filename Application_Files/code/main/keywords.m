classdef keywords < handle
%KEYWORDS    QFT class for material keyword processing.
%   This class contains methods for material keyword processing tasks.
%   
%   KEYWORDS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also importMaterial, fetchMaterial, job.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% INITIALIZE DEFAULT KEYWORDS
        function [kwStr, kwStrSp, kwData] = initialize()
            % KEYWORD STRINGS
            kwStr = {'ITEMS', 'UNITS', 'SCALE', 'REPEATS', 'USESN', 'DESIGNLIFE',...
                'ALGORITHM', 'MSCORRECTION', 'LOADEQ', 'PLANESTRESS', 'SNSCALE',...
                'OUTPUTFIELD', 'OUTPUTHISTORY', 'OUTPUTFIGURE', 'B2', 'B2NF', 'KTDEF',...
                'KTCURVE', 'RESIDUAL', 'WELDCLASS', 'DEVIATIONSBELOWMEAN',...
                'CHARACTERISTICLENGTH', 'SEAWATER', 'YIELDSTRENGTH', 'FAILUREMODE',...
                'UTS', 'CONV', 'OUTPUTDATABASE', 'PARTINSTANCE', 'UCS', 'OFFSET',...
                'STEPNAME', 'FACTOROFSTRENGTH', 'GROUP', 'HOTSPOT', 'SNKNOCKDOWN',...
                'EXPLICITFEA', 'RESULTPOSITION', 'CONTINUEFROM', 'DATACHECK',...
                'NOTCHCONSTANT', 'NOTCHRADIUS', 'GAUGELOCATION', 'GAUGEORIENTATION',...
                'JOBNAME', 'JOBDESCRIPTION', 'MATERIAL', 'DATASET', 'HISTORY',...
                'HFDATASET', 'HFHISTORY', 'HFTIME', 'HFSCALE', 'FATIGUERESERVEFACTOR'};
            
            kwStrSp = {'ITEMS', 'UNITS', 'SCALE', 'REPEATS', 'USE SN', 'DESIGN LIFE',...
                'ALGORITHM', 'MS CORRECTION', 'LOAD EQ', 'PLANE STRESS', 'SN SCALE',...
                'OUTPUT FIELD', 'OUTPUT HISTORY', 'OUTPUT FIGURE', 'B2', 'B2 NF', 'KT DEF',...
                'KT CURVE', 'RESIDUAL', 'WELD CLASS', 'DEVIATIONS BELOW MEAN',...
                'CHARACTERISTIC LENGTH', 'SEA WATER', 'YIELD STRENGTH', 'FAILURE MODE',...
                'UTS', 'CONV', 'OUTPUT DATABASE', 'PART INSTANCE', 'UCS', 'OFFSET',...
                'STEP NAME', 'FACTOR OF STRENGTH', 'GROUP', 'HOTSPOT', 'SN KNOCKDOWN',...
                'EXPLICIT FEA', 'RESULT POSITION', 'CONTINUE FROM', 'DATA CHECK',...
                'NOTCH CONSTANT', 'NOTCH RADIUS', 'GAUGE LOCATION', 'GAUGE ORIENTATION',...
                'JOB NAME', 'JOB DESCRIPTION', 'MATERIAL', 'DATASET', 'HISTORY',...
                'HF DATASET', 'HF HISTORY', 'HF TIME', 'HF SCALE', 'FATIGUE RESERVE FACTOR'};
            
            % KEYWORD DATA
            kwData = {'ALL', 3.0, 1.0, 1.0, 1.0, 'CAEL', 0.0, 0.0, {1.0, 'Repeats'},...
                0.0, 1.0, 0.0, 0.0, 0.0, [], [], 'default.kt', 1.0, 0.0, 'B', 0.0, [],...
                0.0, [], 'NORMAL', [], [], [], 'PART-1-1', [], [], [], 0.0, {'DEFAULT'}, 0.0,...
                {}, 0.0, 'ELEMENT NODAL', [], 0.0, [], [], {}, {}, 'Job-1',...
                'Template job file', [], '', [], [], [], {[], []}, [], 1.0};
        end
        
        %% INTERPRET CELL KEYWORD INPUT
        function [cell_buffer] = interpretCell(line, matchingKw)
            %{
                There are different ways in which the cell could be defined:
                
                {'string1', 'string2',..., 'stringn'}
                {[11, 12,..., 1n], [21, 22,..., 2n],..., [n1, n2,..., nn]]}
                {[n1, n2, n3], 'string'}
                {n1, 'string1', 'string2', n2, n3, 'string3'}
                {n1, n2}
            %}
            L = length(line);
            
            currentChar = 2.0;
            
            % Initialize the cell element buffer
            cell_buffer = cell(1.0, 1.0);
            
            % Initialize the buffer index
            index = 0.0;
            
            while currentChar < L
                % The cell is a string
                if strcmp(line(currentChar), sprintf('''')) == 1.0
                    % Get the string
                    TOKEN = strtok(line(currentChar:end), sprintf(''''));
                    
                    index = index + 1.0;
                    cell_buffer{index} = TOKEN;
                    
                    currentChar = currentChar + length(TOKEN) + 2.0;

                % The cell is an array
                elseif strcmp(line(currentChar), '[') == 1.0
                    % Get the string
                    TOKEN = strtok(line(currentChar + 1.0:end), sprintf(']'));
                    
                    index = index + 1.0;
                    cell_buffer{index} = sscanf(TOKEN, '%g,')';
                    
                    currentChar = currentChar + length(TOKEN) + 3.0;
                
                % The cell is a 1x1 numeric
                elseif isnumeric(str2double(line(currentChar))) == 1.0 && isnan(str2double(line(currentChar))) == 0.0 && isreal(str2double(line(currentChar))) == 1.0
                    %{
                        Get the string. Search up to the first occurrence
                        of a comma
                    %}
                    TOKEN = strtok(line(currentChar:end), sprintf(','));
                    
                    if currentChar + length(TOKEN) >= L
                        TOKEN = strtok(line(currentChar:end), sprintf('}'));
                    end
                    
                    index = index + 1.0;
                    if matchingKw == 43.0
                        %{
                            Exception: If the current keyword is *GAUGE
                            LOCATION, accept a lone numeric input and
                            convert it to CHAR
                        %}
                        cell_buffer{index} = char(TOKEN);
                    else
                        cell_buffer{index} = str2double(TOKEN);
                    end
                    
                    currentChar = currentChar + length(TOKEN) + 1.0;
                    
                % The cell is a string without enclosing apostrophes
                elseif isnan(str2double(line(currentChar))) == 1.0 && isspace(line(currentChar)) == 0.0 && strcmp(line(currentChar), ',') == 0.0
                    %{
                        Get the string. Search up to the first occurrence
                        of a comma
                    %}
                    TOKEN = strtok(line(currentChar:end), sprintf(','));
                    
                    if currentChar + length(TOKEN) >= L
                        TOKEN = strtok(line(currentChar:end), sprintf('}'));
                    end
                    
                    index = index + 1.0;
                    cell_buffer{index} = TOKEN;
                    
                    currentChar = currentChar + length(TOKEN) + 1.0;
                else
                    currentChar = currentChar + 1.0;
                end
            end
        end
        
        %% PRINT INPUT FILE READER SUMMARY TO MESSAGE FILE
        function [] = printSummary()
            if isappdata(0, 'jobFromTextFile') == 0.0
                return
            else
                rmappdata(0, 'jobFromTextFile')
            end
            
            if isappdata(0, 'kw_processed') == 0.0
                return
            else
                fid = getappdata(0, 'messageFID');
                kw_processed = getappdata(0,'kw_processed');
            end
            
            fprintf(fid, '\r\n***INPUT FILE SUMMARY');
            
            % Processed keywords
            fprintf(fid, '\r\n\tThe following keywords were processed:');
            
            if length(kw_processed) == 1.0 && isempty(kw_processed{1.0}) == 1.0
                fprintf(fid, '\r\n\t(NONE)\r\');
            else
                for i = 1:length(kw_processed)
                    if i == length(kw_processed)
                        fprintf(fid, '\r\n\t*%s\r\n', kw_processed{i});
                    else
                        fprintf(fid, '\r\n\t*%s', kw_processed{i});
                    end
                end
            end
            
            % Badly defined keywords
            kw_bad = getappdata(0, 'kw_bad');
            if isempty(kw_bad{1.0}) == 0.0
                fprintf(fid, '\r\n\tWarning: The following keywords were not processed:');
                
                for i = 1:length(kw_bad)
                    if i == length(kw_bad)
                        fprintf(fid, '\r\n\t*%s\r\n', kw_bad{i});
                    else
                        fprintf(fid, '\r\n\t*%s', kw_bad{i});
                    end
                end
            end
            
            % Undefined keywords
            kw_undefined = getappdata(0, 'kw_undefined');
            if isempty(kw_undefined{1.0}) == 0.0
                fprintf(fid, '\r\n\tWarning: The following keywords were not recognised:');
                
                for i = 1:length(kw_undefined)
                    if i == length(kw_undefined)
                        fprintf(fid, '\r\n\t*%s\r\n', kw_undefined{i});
                    else
                        fprintf(fid, '\r\n\t*%s', kw_undefined{i});
                    end
                end
            end
            
            % Partial keywords
            kw_partial = getappdata(0, 'kw_partial');
            if isempty(kw_partial{1.0}) == 0.0
                fprintf(fid, '\r\n\tWarning: The following keywords were declared but not defined:');
                
                for i = 1:length(kw_partial)
                    if i == length(kw_partial)
                        fprintf(fid, '\r\n\t%s\r\n', kw_partial{i});
                    else
                        fprintf(fid, '\r\n\t%s', kw_partial{i});
                    end
                end
            end
        end
    end
end
function [] = cleanup(status)
%CLEANUP    QFT function to clear variables.
%   This function removes %APPDATA% and material data.
%   
%   CLEANUP is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 25-Apr-2017 12:13:25 GMT
    
    %%
    
%% Remove material data
setappdata(0, 'defaultAlgorithm', [])
setappdata(0, 'defaultMSC', [])
setappdata(0, 'fsc', [])
setappdata(0, 'cael', [])
setappdata(0, 'E', [])
setappdata(0, 'uts', [])
setappdata(0, 'poisson', [])
setappdata(0, 's_values', [])
setappdata(0, 'n_values', [])
setappdata(0, 'r_values', [])
setappdata(0, 'residualStress', [])
setappdata(0, 'k', [])
setappdata(0, 'ndEndurance', [])
setappdata(0, 'b', [])
setappdata(0, 'b2', [])
setappdata(0, 'ucs', [])
setappdata(0, 'Sf', [])
setappdata(0, 'Ef', [])
setappdata(0, 'c', [])
setappdata(0, 'kp', [])
setappdata(0, 'np', [])
setappdata(0, 'twops', [])
setappdata(0, 'TfPrime', [])
setappdata(0, 'Tfs', [])

%% If the analysis exited with errors, create error log
if status == 1.0
    % Create an error log file
    job = getappdata(0, 'jobName');
    dir = sprintf('Project/output/%s/', job);
    errLogFile = [dir, sprintf('%s.log', job)];
    
    % Remove the DATA and MATLAB FIGURES directories if
    % applicable
    if exist([dir, 'Data Files'], 'dir') == 7.0
        try
            rmdir([dir, 'Data Files'])
        catch
        end
    end
    if exist([dir, 'MATLAB Figures'], 'dir') == 7.0
        try
            rmdir([dir, 'MATLAB Figures'])
        catch
        end
    end
    
    fprintf('\n[ERROR] Job %s exited with an error. Please see ''%s'' for details\n', job, [job, '.log'])
    
    fid = fopen(errLogFile, 'w');
    
    % Write file header
    fprintf(fid, 'Quick Fatigue Tool 6.10-07\r\n');
    fprintf(fid, '(Copyright Louis Vallance 2017)\r\n');
    fprintf(fid, 'Last modified 25-Apr-2017 12:13:25 GMT\r\n\r\n');
    
    % Continue writing the file
    fprintf(fid, 'THE ANALYSIS WAS ABORTED FOR THE FOLLOWING REASON(S):');
    
    % Unable to remove old output directory
    if getappdata(0, 'E034') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Unable to remove the old output files. Access was denied');
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'warning_034_exceptionMessage'));
        fprintf(fid, '\r\n-> Make sure any files from the current output directory are closed');
        fprintf(fid, '\r\n\r\nError code: E034');
        rmappdata(0, 'E034')
    end
    
    % Insufficient material data
    if getappdata(0, 'E001') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: No material was specified in the job file');
        fprintf(fid, '\r\n-> Materials are defined using the Material Manager app or by running ''MaterialManager.m''');
        fprintf(fid, '\r\n-> The material is specified in the job file with the option MATERIAL');
        fprintf(fid, '\r\n-> For detailed guidance on creating and managing material data, consult Section 5 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E001');
        rmappdata(0, 'E001')
    elseif getappdata(0, 'E002') == 1.0
        if strcmpi(getappdata(0, 'material'), '.mat') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: No material was specified in the job file');
            fprintf(fid, '\r\n-> Materials are defined using the Material Manager app or by running ''MaterialManager.m''');
            fprintf(fid, '\r\n-> The material is specified in the job file with the option MATERIAL');
            fprintf(fid, '\r\n-> For detailed guidance on creating and managing material data, consult Section 5 of the Quick Fatigue Tool User Guide');
            fprintf(fid, '\r\n\r\nError code: E001');
        else
            fprintf(fid, '\r\n\r\n***ERROR: The material ''%s'' could not be found', getappdata(0, 'material'));
            fprintf(fid, '\r\n-> Make sure the file exists in Data/material/local and is spelled correctly in the job file');
            fprintf(fid, '\r\n\r\nError code: E002');
        end
        rmappdata(0, 'E002')
    end
    
    % Problem loading the .MAT file
    if getappdata(0, 'E003') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The material ''%s'' could not be opened', getappdata(0, 'material'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_003_exceptionMessage'));
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E003');
        rmappdata(0, 'E003')
    end
    
    % The proof stress is greater than the uts
    if getappdata(0, 'E108') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The yield stress cannot exceed the ultimate tensile strength.');
        fprintf(fid, '\r\n-> This error occurred in material ''%s'' (Group %.0f)', getappdata(0, 'getMaterial_name'), getappdata(0, 'getMaterial_currentGroup'));
        fprintf(fid, '\r\n\r\nError code: E108');
        rmappdata(0, 'E108')
    end
    
    % Error in material definition
    if getappdata(0, 'E004') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There is a syntax error in one or more material properties');
        fprintf(fid, '\r\n-> Check for mistakes in the material editor');
        fprintf(fid, '\r\n-> Non-numeric properties are not accepted');
        fprintf(fid, '\r\n-> Mechanical properties must be positive');
        fprintf(fid, '\r\n\r\nError code: E004');
        rmappdata(0, 'E004')
    end
    
    % FEA definition cannot be found
    if getappdata(0, 'E035') == 1.0
        missingChannel = getappdata(0, 'errorMissingChannel');
         
        if isnumeric(missingChannel) == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The stress dataset ''%f'' could not be found',...
            missingChannel);
        else
            fprintf(fid, '\r\n\r\n***ERROR: The stress dataset ''%s'' could not be found',...
            missingChannel);
        end
        fprintf(fid, '\r\n-> Make sure the file is spelled correctly and is located in Project/input');
        fprintf(fid, '\r\n\r\nError code: E035');
        rmappdata(0, 'E035')
    end
    if getappdata(0, 'E047') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: No load histories were specified');
        
        if getappdata(0, 'algorithm') == 3.0
            fprintf(fid, '\r\n-> The Uniaxial Stress-Life algorithm requires a single load history');
        else
            fprintf(fid, '\r\nIf the loading is a dataset sequence:\r\n-> Specify at least two stress datasets using the DATASET option\r\n-> Set HISTORY = []\r\n');
            fprintf(fid, '\r\nIf the loading is a scale and combine:\r\n-> Specify at least one load history and stress dataset using the HISTORY and DATASET options, respectively');
        end
        
        fprintf(fid, '\r\n\r\nError code: E047');
        rmappdata(0, 'E047')
    end
    if getappdata(0, 'E036') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The load history ''%s'' could not be found',...
            getappdata(0, 'errorMissingScale'));
        fprintf(fid, '\r\n-> Make sure the file is spelled correctly and is located in Project/input');
        fprintf(fid, '\r\n\r\nError code: E036');
        rmappdata(0, 'E036')
    end
    if getappdata(0, 'E037') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Multiple load histories are not permitted for Uniaxial Stress-Life analysis');
        fprintf(fid, '\r\n\r\nError code: E037');
        rmappdata(0, 'E037')
    end
    if getappdata(0, 'E046') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The Uniaxial Stress-Life algorithm was selected but no load histories were specified');
        fprintf(fid, '\r\n\r\nError code: E046');
        rmappdata(0, 'E046')
    end
    if getappdata(0, 'E038') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Multiple load histories are not permitted for high frequency data with Uniaxial Stress-Life');
        s = getappdata(0, 'errMultipleHFLoadHistories');
        fprintf(fid, '\r\n-> %s', s{:});
        fprintf(fid, '\r\n\r\nError code: E038');
        rmappdata(0, 'E038')
    end
    
    % Insufficient material data for analysis
    if getappdata(0, 'E005') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The material definition is insufficient. In at least one group:');
        if getappdata(0, 'useSN') == 1.0
            fprintf(fid, '\r\n-> S-N data points are not available');
            fprintf(fid, '\r\n-> Fatigue coefficients could not be derived');
        else
            fprintf(fid, '\r\n-> Fatigue coefficients could not be derived');
        end
        
        switch getappdata(0, 'algorithm')
            case 3.0
                fprintf(fid, '\r\n-> The Uniaxial Stress-Life algorithm requires the following material constants: Sf'', b');
            case 4.0
                if getappdata(0, 'plasticSN') == 1.0
                    fprintf(fid, '\r\n-> The Stress-based Brown-Miller algorithm requires the following material constants: E, Sf'', b, Ef'', c');
                else
                    fprintf(fid, '\r\n-> The Stress-based Brown-Miller algorithm requires the following material constants: E, Sf'', b');
                end
            case 5.0
                fprintf(fid, '\r\n-> The Normal Stress algorithm requires the following material constants: Sf'', b');
            case 6.0
                fprintf(fid, '\r\n-> Findley''s Method requires the following material constants: Sf'', b, k');
            case 7.0
                fprintf(fid, '\r\n-> The Stress Invariant algorithm requires the following material constants: Sf'', b');
            case 9.0
                fprintf(fid, '\r\n-> The NASALIFE algorithm requires the following material constants: Sf'', b');
        end
        
        fprintf(fid, '\r\n\r\nError code: E005');
        rmappdata(0, 'E005')
    elseif getappdata(0, 'E006') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The material definition is insufficient');
        fprintf(fid, '\r\n-> S-N data points were requested but none are available');
        fprintf(fid, '\r\n-> S-N coefficients could not be derived');
        fprintf(fid, '\r\n\r\nError code: E006');
        rmappdata(0, 'E006')
    end
    
    % SBBM requested but no E value
    if getappdata(0, 'E007') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: In at least one group, the material definition is insufficient');
        fprintf(fid, '\r\n-> The Stress-based Brown-Miller algorithm requires a value for the modulus of elasticity');
        fprintf(fid, '\r\n\r\nError code: E007');
        rmappdata(0, 'E007')
    end
    
    % User-defined MSC is badly formatted
    if getappdata(0, 'E048') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user-defined FRF definition for ''%s'' (group %.0f) is invalid', getappdata(0, 'msCorrection'), getappdata(0, 'E048_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user-defined MSC file ''%s'' is invalid', getappdata(0, 'msCorrection'));
        end
        fprintf(fid, '\r\n-> The mean stress values must be strictly decreasing');
        fprintf(fid, '\r\n\r\nError code: E048');
        rmappdata(0, 'E048')
        rmappdata(0, 'msCorrection')
        rmappdata(0, 'E048_group')
    end
    
    % User-defined MSC could not be found
    if getappdata(0, 'E049') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The user-defined %s file ''%s'' could not be found', getappdata(0, 'mscORfrf'), getappdata(0, 'msCorrection'));
        fprintf(fid, '\r\n\r\nError code: E049');
        rmappdata(0, 'msCorrection')
        rmappdata(0, 'E049')
    end
    
    % User-defined MSC could not be read
    if getappdata(0, 'E050') == 1.0
        exception = getappdata(0, 'error_log_050_message');
        fprintf(fid, '\r\n\r\n***ERROR: The user-defined %s file ''%s'' could not be read', getappdata(0, 'mscORfrf'), getappdata(0, 'msCorrection'));
        fprintf(fid, '\r\n-> Check that the file is formatted correctly. Data must be numeric');
        fprintf(fid, '\r\n-> %s', exception.message);
        fprintf(fid, '\r\n\r\nError code: E050');
        rmappdata(0, 'E050')
    end
    
    % User-defined MSC does not include UTS value
    if getappdata(0, 'E051') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: At least one group has a missing UTS definition');
        fprintf(fid, '\r\n-> The UTS is required for all analysis groups for user-defined mean stress corrections');
        fprintf(fid, '\r\n\r\nError code: E051');
        rmappdata(0, 'E051')
    end
    
    % NaN damage values from S-N data
    if getappdata(0, 'E008') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Some damage values are non-numeric');
        fprintf(fid, '\r\n-> Check the job for syntax errors');
        fprintf(fid, '\r\n-> If the problem persists, please contact the author for assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E008');
        rmappdata(0, 'E008')
    end
    
    % Check that FOS bands are valid
    if getappdata(0, 'E039') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Invalid FOS band definition');
        fprintf(fid, '\r\n-> Parameters should decrease i.e. max >= maxFine >= minFine >= min and max > min');
        fprintf(fid, '\r\n\r\nError code: E039');
        rmappdata(0, 'E039')
    end
    
    % Check that FOS increments are valid
    if getappdata(0, 'E052') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Invalid FOS increment definition');
        fprintf(fid, '\r\n-> The coarse increment must be equal to or greater than the fine increment');
        fprintf(fid, '\r\n\r\nError code: E052');
        rmappdata(0, 'E052')
    end
    
    % Issues with the P-V detection algorithm
    if getappdata(0, 'E009') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Peak-valley detection failed');
        fprintf(fid, '\r\n-> The input vectors V and X must have the same length');
        fprintf(fid, '\r\n-> This exception should have been caught during validation!');
        fprintf(fid, '\r\n-> Visit http://www.billauer.co.il/peakdet.html for information about this algorithm');
        fprintf(fid, '\r\n\r\nError code: E009');
        rmappdata(0, 'E009')
    elseif getappdata(0, 'E010') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Peak-valley detection failed');
        fprintf(fid, '\r\n-> The input argument DELTA must be a scalar');
        fprintf(fid, '\r\n-> This exception should have been caught during validation!');
        fprintf(fid, '\r\n-> Visit http://www.billauer.co.il/peakdet.html for information about this algorithm');
        fprintf(fid, '\r\n\r\nError code: E010');
        rmappdata(0, 'E010')
    elseif getappdata(0, 'E011') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Peak-valley detection failed');
        fprintf(fid, '\r\n-> The input argument DELTA must be positive');
        fprintf(fid, '\r\n-> This exception should have been caught during validation!');
        fprintf(fid, '\r\n-> Visit http://www.billauer.co.il/peakdet.html for information about this algorithm');
        fprintf(fid, '\r\n\r\nError code: E011');
        rmappdata(0, 'E011')
    end
    
    % Scale and combine issues
    datasets = getappdata(0, 'dataset');
    if ischar(datasets) == 1.0
        datasets = 1.0;
    else
        datasets = length(datasets);
    end
    histories = getappdata(0, 'history');
    if isnumeric(histories) == 1.0 || ischar(histories) == 1.0
        histories = 1.0;
    else
        histories = length(histories);
    end
    
    if getappdata(0, 'E012') == 1.0
        if datasets == histories
            fprintf(fid, '\r\n\r\n***ERROR: The options DATASET is defined as a cell, but the loading does not appear to be a scale and combine');
            fprintf(fid, '\r\n-> For a simple (DATASET * HISTORY) loading, specify DATASET as a string');
        else
            fprintf(fid, '\r\n\r\n***ERROR: There are %.0f datasets and %.0f load histories',...
                datasets, histories);
            fprintf(fid, '\r\n-> For scale & combine analysis, the number of datasets and load histories must be the same');
        end
        
        if datasets == 0.0
            fprintf(fid, '\r\n-> If the analysis is uniaxial, set ALGORITHM = 3.0 in the job file');
        end
        fprintf(fid, '\r\n\r\nError code: E012');
        rmappdata(0, 'E012')
    end
    if getappdata(0, 'E013') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f load histories but only 1 dataset',...
            histories);
        fprintf(fid, '\r\n-> The number of datasets and load histories must be the same');
        fprintf(fid, '\r\n\r\nError code: E013');
        rmappdata(0, 'E013')
    end
    if getappdata(0, 'E014') == 1.0
        if datasets > 1.0
            fprintf(fid, '\r\n\r\n***ERROR: There are %.0f datasets but only 1 load history', datasets);
        else
            fprintf(fid, '\r\n\r\n***ERROR: A load history was specified without any datasets');
            fprintf(fid, '\r\n-> If the intended analysis type was uniaxial, set ALGORITHM = 3.0 in the job file');
        end
        fprintf(fid, '\r\n-> If the loading is a dataset sequence, set HISTORY = [] in the job file');
        fprintf(fid, '\r\n-> For a scale and combine loading, the number of datasets and load histories must be the same');
        fprintf(fid, '\r\n\r\nError code: E014');
        rmappdata(0, 'E014')
    end
    if getappdata(0, 'E015') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The input file reader returned one or more empty datasets');
        fprintf(fid, '\r\n-> This can happen if the input file reader encounters a problem with a dataset');
        fprintf(fid, '\r\n-> Make sure the data file(s) are formatted correctly');
        fprintf(fid, '\r\n-> For detailed guidance on creating a loading definition, consult the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E015');
        rmappdata(0, 'E015')
    end
    if getappdata(0, 'E016') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The load history file ''%s'' was not processed', getappdata(0, 'loadHistoryUnableOpen'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_016_exceptionMessage'));
        if getappdata(0, 'scaleNotFound') == 1.0
            fprintf(fid, '\r\n-> The file could not be located');
        else
            fprintf(fid, '\r\n-> The file could not be read');
            fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        end
        fprintf(fid, '\r\n\r\nError code: E016');
        rmappdata(0, 'E016')
    end
    if getappdata(0, 'E017') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: At least one load history has a length less than 2');
        fprintf(fid, '\r\n-> Fatigue analysis requires at least 2 history points to form a cycle');
        fprintf(fid, '\r\n\r\nError code: E017');
        rmappdata(0, 'E017')
    end
    if getappdata(0, 'E018') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Peak-valley detection failed while processing ''%s''. You may wish to try the following:', getappdata(0, 'pvDetectionFailFile'));
        fprintf(fid, '\r\n-> Reduce the gating criterion');
        fprintf(fid, '\r\n-> Switch to Nielsony''s Method');
        fprintf(fid, '\r\n-> Disable time history gating');
        
        fprintf(fid, '\r\n\r\nError code: E018');
        rmappdata(0, 'E018')
    end
    if getappdata(0, 'E019') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: At least one stress dataset contains an incomplete tensor');
        fprintf(fid, '\r\n-> This should have been caught by a previous validation check!');
        fprintf(fid, '\r\n\r\nError code: E019');
        rmappdata(0, 'E019')
    end
    if getappdata(0, 'E042') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of items in the stress datasets is not consistent');
        fprintf(fid, '\r\n-> Check the size of each dataset. Datasets should originate from the same model.');
        fprintf(fid, '\r\n\r\nError code: E042');
        rmappdata(0, 'E042')
    end
    if getappdata(0, 'E043') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of items in the high frequency stress datasets is not consistent');
        fprintf(fid, '\r\n-> Check the size of each dataset. Datasets should originate from the same model.');
        fprintf(fid, '\r\n\r\nError code: E043');
        rmappdata(0, 'E043')
    end
    if getappdata(0, 'E020') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The load history file ''%s'' contains data with more than one dimension', getappdata(0, 'loadHistoryUnableOpen'));
        fprintf(fid, '\r\n-> Load history data must be 1xN or Nx1');
        fprintf(fid, '\r\n\r\nError code: E020');
        rmappdata(0, 'E020')
    end
    if getappdata(0, 'E021') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The data positions in the loading are inconsistent');
        fprintf(fid, '\r\n-> Ensure that the field output location is the same for each stress dataset');
        fprintf(fid, '\r\n\r\nError code: E021');
        rmappdata(0, 'E021')
    end
    if getappdata(0, 'E022') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: An unhandled exception was encountered while combining the loading data');
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_022_exceptionMessage'));
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E022');
        rmappdata(0, 'E022')
    end
    if getappdata(0, 'E045') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: An unhandled exception was encountered while scaling a dataset with its respective channel');
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_045_exceptionMessage'));
        fprintf(fid, '\r\n-> There is not enough memory for analysis. Increase system memory or reduce the size of the model and/or loading');
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        [userView, systemView] = memory;
        
        fprintf(fid, '\r\n\r\n***MEMORY INFORMATION');
        fprintf(fid, '\r\n                 Physical memory:');
        fprintf(fid, '\r\n                     Available: %.0f bytes', systemView.PhysicalMemory.Available);
        fprintf(fid, '\r\n                     Total: %.0f bytes', systemView.PhysicalMemory.Total);
        fprintf(fid, '\r\n                 Available memory for data: %.0f bytes', userView.MemAvailableAllArrays);
        fprintf(fid, '\r\n                 Reserved system memory for MATLAB: %.0f bytes', userView.MemUsedMATLAB);
        fprintf(fid, '\r\n\r\nError code: E045');
        rmappdata(0, 'E045')
    end
    if getappdata(0, 'E023') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: No stress datasets were specified');
        fprintf(fid, '\r\n-> At least one stress dataset is required for analysis');
        fprintf(fid, '\r\n\r\nError code: E023');
        rmappdata(0, 'E023')
    end
    if getappdata(0, 'E024') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: A stress dataset was specified without a load history');
        fprintf(fid, '\r\n-> If the loading is a dataset sequence, specify at least two stress datasets using the DATASET option in the job file');
        fprintf(fid, '\r\n-> If the loading is a scale and combine, specify at least one load history using the HISTORY option in the job file');
        fprintf(fid, '\r\n\r\nError code: E024');
        rmappdata(0, 'E024')
    end
    if getappdata(0, 'E025') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Only one stress dataset was found');
        fprintf(fid, '\r\n-> For a dataset sequence, at least two stress datasets are required');
        fprintf(fid, '\r\n\r\nError code: E025');
        rmappdata(0, 'E025')
    end
    if getappdata(0, 'E026') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: A problem ocurred whilst attempting to open a stress dataset');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> Ensure that the file name is correct and that it exists in the working directory');
        fprintf(fid, '\r\n\r\nError code: E026');
        rmappdata(0, 'E026')
    end
    if getappdata(0, 'E059') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: A problem ocurred whilst attempting to open a group definition file');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> Ensure that the file name is correct and that it exists in the working directory');
        fprintf(fid, '\r\n\r\nError code: E059');
        rmappdata(0, 'E059')
    end
    if getappdata(0, 'E027') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: A problem ocurred whilst attempting to read the data columns from a stress dataset');
        fprintf(fid, '\r\n-> The error occurred in stress dataset ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_027_exceptionMessage'));
        fprintf(fid, '\r\n-> Check the header of the data file for irregularities');
        fprintf(fid, '\r\n-> Stress datasets must contain between four and eight columns, depending on the format of the data');
        fprintf(fid, '\r\n-> For detailed guidance on creating stress datasets, consult the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E027');
        rmappdata(0, 'E027')
    end
    if getappdata(0, 'E060') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: A problem ocurred whilst attempting to read the data columns from a group definition file');
        fprintf(fid, '\r\n-> The error occurred in file ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_060_exceptionMessage'));
        fprintf(fid, '\r\n-> Check the header of the file for irregularities');
        fprintf(fid, '\r\n-> Group definition files must contain either a single row or column of item IDs or they should be a');
        fprintf(fid, '\r\n   field data (.rpt) file containing an FEA subset of position IDs');
        fprintf(fid, '\r\n-> If the group definition file is defined as an FEA subset, the data position must agree with the master model');
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E060');
        rmappdata(0, 'E060')
    end
    if getappdata(0, 'E028') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The input file reader encountered a problem with a dataset');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_028_exceptionMessage'));
        fprintf(fid, '\r\n-> Ensure that the data columns of the stress dataset are formatted correctly');
        fprintf(fid, '\r\n-> Quick Fatigue Tool cannot create a loading if the dataset contains less');
        fprintf(fid, '\r\n   than 4 or more than 10 data columns');
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E028');
        rmappdata(0, 'E028')
    end
    if getappdata(0, 'E061') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The input file reader encountered a problem with a group definition file');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> MException ID: %s', getappdata(0, 'error_log_061_exceptionMessage'));
        fprintf(fid, '\r\n-> Ensure that the group definition file is formatted correctly');
        fprintf(fid, '\r\n-> Please contact the developer for further assistance: louisvallance@hotmail.co.uk');
        fprintf(fid, '\r\n\r\nError code: E061');
        rmappdata(0, 'E061')
    end
    if getappdata(0, 'E029') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: No field data was detected in the stress dataset');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> If the stress dataset was created as a field output (.rpt) file in Abaqus, check the following:');
        fprintf(fid, '\r\n-> Make sure that "Column totals" and "Column min/max" are unchecked in the Report Field Output dialogue');
        fprintf(fid, '\r\n-> Remove the text header from the top of the file');
        fprintf(fid, '\r\n\r\nError code: E029');
        rmappdata(0, 'E029')
    end
    if getappdata(0, 'E062') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: No group data was detected in the group definition file');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n\r\nError code: E062');
        rmappdata(0, 'E061')
    end
    if getappdata(0, 'E030') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: INF and/or NaN values were detected in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> This can happen if different element types are defined in a single region of stress data, the tensor definition is incomplete for one or more items,');
        fprintf(fid, '\r\n   or the dataset processor was unable to determine the element type');
        fprintf(fid, '\r\n-> Check the stress dataset file(s) for spurious data');
        fprintf(fid, '\r\n-> For an explanation of the dataset processor, consult Section 3.6 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E030');
        rmappdata(0, 'E030')
    end
    if getappdata(0, 'E063') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: INF and/or NaN values were detected in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> Check the group definition file(s) for spurious data');
        fprintf(fid, '\r\n\r\nError code: E063');
        rmappdata(0, 'E063')
    end
    if getappdata(0, 'E031') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The stress dataset contains an incomplete stress tensor');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> Ensure that the data file was generated in Abaqus correctly. See "help readRPT" for further details');
        fprintf(fid, '\r\n\r\nError code: E031');
        rmappdata(0, 'E031')
    end
    if getappdata(0, 'E032') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The group definition file contains an incomplete stress tensor');
        fprintf(fid, '\r\n-> The error occurred in ''%s''', getappdata(0, 'FOPEN_error_file'));
        fprintf(fid, '\r\n-> Position IDs cannot be reliably extracted from the group definition file');
        fprintf(fid, '\r\n-> Ensure that the data file was generated in Abaqus correctly. See "help readRPT" for further details');
        fprintf(fid, '\r\n\r\nError code: E032');
        rmappdata(0, 'E032')
    end
    if getappdata(0, 'E033') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of items specified by ITEMS is greater than the number of items in the stress dataset');
        fprintf(fid, '\r\n-> When setting the value of ITEMS in the job file, its length must be equal to or less than the total number of items in the stress dataset');
        fprintf(fid, '\r\n\r\nError code: E033');
        rmappdata(0, 'E033')
    end
    if getappdata(0, 'E040') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of analysis items in the high and low frequency datasets are not equal');
        fprintf(fid, '\r\n-> Ensure that the high frequency dataset(s) belong to the same model');
        fprintf(fid, '\r\n\r\nError code: E040');
        rmappdata(0, 'E040')
    end
    if getappdata(0, 'E041') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The time period of the high frequency datasets must be smaller than the low frequency datasets');
        fprintf(fid, '\r\n-> Time period for low frequency dataset: %.3g seconds', getappdata(0, 'errTimeLo'));
        fprintf(fid, '\r\n-> Time period for high frequency dataset: %.3g seconds', getappdata(0, 'errTimeHi'));
        fprintf(fid, '\r\n\r\nError code: E041');
        rmappdata(0, 'E041')
    end
    if getappdata(0, 'E044') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The exposure time for the low or high frequency data is undefined');
        fprintf(fid, '\r\n\r\nError code: E044');
        rmappdata(0, 'E044')
    end
    % Problems associated with group definitions
    if getappdata(0, 'E053') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Multiple materials are specified as a cell, but no analysis groups were defined');
        fprintf(fid, '\r\n-> The material definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the material definition so that only one material is specified, or define groups');
        fprintf(fid, '\r\n   corresponding to each material');
        fprintf(fid, '\r\n\r\nError code: E053');
        rmappdata(0, 'E053')
    end
    if getappdata(0, 'E054') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: More than two materials are specified as a cell, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The material definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the material definition so that only one material is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and materials agree with each other');
        fprintf(fid, '\r\n\r\nError code: E054');
        rmappdata(0, 'E054')
    end
    if getappdata(0, 'E055') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two materials are specified as a cell, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The material definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the material definition so that only one material is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and materials agree with each other');
        fprintf(fid, '\r\n-> If you wish to define material properties for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first material is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second material is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E055');
        rmappdata(0, 'E055')
    end
    if getappdata(0, 'E056') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f materials (defined as a cell)', getappdata(0, 'error_log_056_numberOfGroups'), getappdata(0, 'error_log_056_numberOfMaterials'));
        fprintf(fid, '\r\n-> Modify the group and/or material defintions so that the number of groups and materials agree with each other');
        fprintf(fid, '\r\n-> If one material is being used to span multiple groups, define the material as a character array e.g. MATERIAL = ''<mat_name.mat>''');
        fprintf(fid, '\r\n\r\nError code: E056');
        rmappdata(0, 'E056')
    end
    if getappdata(0, 'E057') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f materials but only %.0f analysis groups', getappdata(0, 'error_log_057_numberOfMaterials'), getappdata(0, 'error_log_057_numberOfGroups'));
        fprintf(fid, '\r\n-> The material definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the material definition so that only one material is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and materials agree with each other');
        fprintf(fid, '\r\n-> If you wish to define material properties for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last material is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E057');
        rmappdata(0, 'E057')
    end
    if getappdata(0, 'E058') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f materials but only %.0f analysis groups', getappdata(0, 'error_log_058_numberOfMaterials'), getappdata(0, 'error_log_058_numberOfGroups'));
        fprintf(fid, '\r\n-> The material definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the material definition so that only one material is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and materials agree with each other');
        fprintf(fid, '\r\n\r\nError code: E058');
        rmappdata(0, 'E058')
    end
    if getappdata(0, 'E064') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The use of DEFAULT with the GROUP option is invalid');
        fprintf(fid, '\r\n-> DEFAULT can only be specified as the last argument');
        fprintf(fid, '\r\n\r\nError code: E064');
        rmappdata(0, 'E064')
    end
    if getappdata(0, 'E065') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Multiple surface finish definition are specified as a cell, but no analysis groups were defined');
        fprintf(fid, '\r\n-> The surface finish definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the surface finish definition so that only one surface finish is specified, or define groups');
        fprintf(fid, '\r\n   corresponding to each surface finish');
        fprintf(fid, '\r\n\r\nError code: E065');
        rmappdata(0, 'E065')
    end
    if getappdata(0, 'E066') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: More than two surface finish definitions are specified as a cell, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The surface finish definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the surface finish definition so that only one surface finish is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and surface finishes agree with each other');
        fprintf(fid, '\r\n\r\nError code: E066');
        rmappdata(0, 'E066')
    end
    if getappdata(0, 'E067') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two surface finishes are specified as a cell, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The surface finish definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the surface finish definition so that only one surface finish is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and surface finishes agree with each other');
        fprintf(fid, '\r\n-> If you wish to define surface finish properties for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first surface finish is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second surface finish is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E067');
        rmappdata(0, 'E067')
    end
    if getappdata(0, 'E068') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f surface finish definitions (defined as a cell)', getappdata(0, 'error_log_068_numberOfGroups'), getappdata(0, 'error_log_068_numberOfKtDefinitions'));
        fprintf(fid, '\r\n-> Modify the group and/or surface finish defintions so that the number of groups and surface finishes agree with each other');
        fprintf(fid, '\r\n-> If one surface finish is being used to span multiple groups, define the surface finish as a character array e.g. KT_DEF = ''<kt_def.kt/.ktx>''');
        fprintf(fid, '\r\n\r\nError code: E068');
        rmappdata(0, 'E068')
    end
    if getappdata(0, 'E069') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f surface finish definitions but only %.0f analysis groups', getappdata(0, 'error_log_069_numberOfKtDefinitions'), getappdata(0, 'error_log_069_numberOfGroups'));
        fprintf(fid, '\r\n-> The surface finish definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the surface finish definition so that only one surface finish is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and surface finishes agree with each other');
        fprintf(fid, '\r\n-> If you wish to define surface finish properties for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last surface finish is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E069');
        rmappdata(0, 'E069')
    end
    if getappdata(0, 'E070') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f surface finish definitions but only %.0f analysis groups', getappdata(0, 'error_log_070_numberOfKtDefinitions'), getappdata(0, 'error_log_070_numberOfGroups'));
        fprintf(fid, '\r\n-> The surface finish definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the surface finish definition so that only one surface finish is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and surface finishes agree with each other');
        fprintf(fid, '\r\n\r\nError code: E070');
        rmappdata(0, 'E070')
    end
    if getappdata(0, 'E071') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two S-N scale factors are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The S-N scale definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N scale definition so that only one S-N scale is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N scales agree with each other');
        fprintf(fid, '\r\n-> If you wish to define S-N scales for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first S-N scale is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second S-N scale is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E071');
        rmappdata(0, 'E071')
    end
    if getappdata(0, 'E072') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f S-N scale factors', getappdata(0, 'error_log_072_numberOfGroups'), getappdata(0, 'error_log_072_numberOfSNScales'));
        fprintf(fid, '\r\n-> Modify the group and/or S-N scale defintions so that the number of groups and S-N scales agree with each other');
        fprintf(fid, '\r\n\r\nError code: E072');
        rmappdata(0, 'E072')
    end
    if getappdata(0, 'E073') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f S-N scales but only %.0f analysis groups', getappdata(0, 'error_log_073_numberOfSNScales'), getappdata(0, 'error_log_073_numberOfGroups'));
        fprintf(fid, '\r\n-> The S-N scale definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N scales so that only one S-N scale is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N scales agree with each other');
        fprintf(fid, '\r\n-> If you wish to define S-N scales for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last S-N scale is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E073');
        rmappdata(0, 'E073')
    end
    if getappdata(0, 'E074') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f S-N scales but only %.0f analysis groups', getappdata(0, 'error_log_074_numberOfSNScales'), getappdata(0, 'error_log_074_numberOfGroups'));
        fprintf(fid, '\r\n-> The S-N scale definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N scales so that only one S-N scale is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N scales agree with each other');
        fprintf(fid, '\r\n\r\nError code: E074');
        rmappdata(0, 'E074')
    end
    if getappdata(0, 'E075') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two residual stresses are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The residual stress definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the residual stress definition so that only one residual stress is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and residual stresses agree with each other');
        fprintf(fid, '\r\n-> If you wish to define residual stresses for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first residual stress is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second residual stress is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E075');
        rmappdata(0, 'E075')
    end
    if getappdata(0, 'E076') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f residual stresses', getappdata(0, 'error_log_076_numberOfGroups'), getappdata(0, 'error_log_076_numberOfResidualStresses'));
        fprintf(fid, '\r\n-> Modify the group and/or residual stress defintions so that the number of groups and residual stresses agree with each other');
        fprintf(fid, '\r\n\r\nError code: E076');
        rmappdata(0, 'E076')
    end
    if getappdata(0, 'E077') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f residual stresses but only %.0f analysis groups', getappdata(0, 'error_log_077_numberOfResidualStresses'), getappdata(0, 'error_log_077_numberOfGroups'));
        fprintf(fid, '\r\n-> The residual stress definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the residual stresses so that only one residual stress is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and residual stresses agree with each other');
        fprintf(fid, '\r\n-> If you wish to define residual stresses for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last residual stress is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E077');
        rmappdata(0, 'E077')
    end
    if getappdata(0, 'E078') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f residual stresses but only %.0f analysis groups', getappdata(0, 'error_log_078_numberOfResidualStresses'), getappdata(0, 'error_log_078_numberOfGroups'));
        fprintf(fid, '\r\n-> The residual stress definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the residual stresses so that only one residual stress is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and residual stresses agree with each other');
        fprintf(fid, '\r\n\r\nError code: E078');
        rmappdata(0, 'E078')
    end
    if getappdata(0, 'E079') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: After processing all analysis groups, there are no matching IDs between the groups and the model');
        fprintf(fid, '\r\n-> There are no active IDs for analysis');
        fprintf(fid, '\r\n\r\nError code: E079');
        rmappdata(0, 'E079')
    end
    if getappdata(0, 'E080') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of FRF envelope definitions does not match the number of analysis groups');
        fprintf(fid, '\r\n-> There are %.0f FRF envelope definitions and %.0f analysis groups', getappdata(0, 'error_log_080_NfrfDefinitions'), getappdata(0, 'error_log_080_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF envelope definition references the correct number of analysis groups');
        fprintf(fid, '\r\n\r\nError code: E080');
        rmappdata(0, 'E080')
    end
    if getappdata(0, 'E081') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: FRF envelopes are defined as a cell with the frfEnvelope variable, but the number of definitions does not match the number of groups');
        fprintf(fid, '\r\n-> There are %.0f FRF envelope definitions and %.0f analysis groups', getappdata(0, 'error_log_081_NfrfDefinitions'), getappdata(0, 'error_log_081_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF envelope definition references the correct number of analysis groups');
        fprintf(fid, '\r\n\r\nError code: E081');
        rmappdata(0, 'E081')
    end
    if getappdata(0, 'E082') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The FRF envelope definition is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, frfEnvelope should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, frfEnvelope must either be a numerical array of envelope numbers, or a cell array of envelope numbers and/or user defined FRF files');
        fprintf(fid, '\r\n\r\nError code: E082');
        rmappdata(0, 'E082')
    end
    if getappdata(0, 'E083') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two values of b2 are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The b2 definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2 definition so that only one b2 value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2 values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define b2 values for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first b2 value is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second b2 is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E083');
        rmappdata(0, 'E083')
    end
    if getappdata(0, 'E084') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two values of b2Nf are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The b2Nf definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2Nf definition so that only one b2Nf value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2Nf values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define b2Nf values for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first b2Nf value is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second b2Nf is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E084');
        rmappdata(0, 'E084')
    end
    if getappdata(0, 'E085') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two values of ucs are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The ucs definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the ucs definition so that only one ucs value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and ucs values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define ucs values for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first ucs value is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second ucs is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E085');
        rmappdata(0, 'E085')
    end
    if getappdata(0, 'E086') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f b2 values', getappdata(0, 'error_log_086_numberOfGroups'), getappdata(0, 'error_log_086_numberOfB2'));
        fprintf(fid, '\r\n-> Modify the group and/or b2 defintions so that the number of groups and b2 values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E086');
        rmappdata(0, 'E086')
    end
    if getappdata(0, 'E087') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f b2 values but only %.0f analysis groups', getappdata(0, 'error_log_087_numberOfB2'), getappdata(0, 'error_log_087_numberOfGroups'));
        fprintf(fid, '\r\n-> The b2 definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2 values so that only one b2 value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2 values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define b2 values for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last b2 value is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E087');
        rmappdata(0, 'E087')
    end
    if getappdata(0, 'E088') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f b2 values but only %.0f analysis groups', getappdata(0, 'error_log_088_numberOfB2'), getappdata(0, 'error_log_088_numberOfGroups'));
        fprintf(fid, '\r\n-> The b2 definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2 values so that only one b2 value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2 values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E088');
        rmappdata(0, 'E088')
    end
    if getappdata(0, 'E089') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f b2Nf values', getappdata(0, 'error_log_089_numberOfGroups'), getappdata(0, 'error_log_089_numberOfB2Nf'));
        fprintf(fid, '\r\n-> Modify the group and/or b2Nf defintions so that the number of groups and b2 values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E089');
        rmappdata(0, 'E089')
    end
    if getappdata(0, 'E090') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f b2Nf values but only %.0f analysis groups', getappdata(0, 'error_log_090_numberOfB2Nf'), getappdata(0, 'error_log_090_numberOfGroups'));
        fprintf(fid, '\r\n-> The b2Nf definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2Nf values so that only one b2Nf value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2Nf values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define b2Nf values for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last b2Nf value is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E090');
        rmappdata(0, 'E090')
    end
    if getappdata(0, 'E091') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f b2Nf values but only %.0f analysis groups', getappdata(0, 'error_log_091_numberOfB2Nf'), getappdata(0, 'error_log_091_numberOfGroups'));
        fprintf(fid, '\r\n-> The b2Nf definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the b2Nf values so that only one b2Nf value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and b2Nf values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E091');
        rmappdata(0, 'E091')
    end
    if getappdata(0, 'E092') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f UCS values', getappdata(0, 'error_log_092_numberOfGroups'), getappdata(0, 'error_log_092_numberOfUCS'));
        fprintf(fid, '\r\n-> Modify the group and/or UCS defintions so that the number of groups and UCS values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E092');
        rmappdata(0, 'E092')
    end
    if getappdata(0, 'E093') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f UCS values but only %.0f analysis groups', getappdata(0, 'error_log_093_numberOfUCS'), getappdata(0, 'error_log_093_numberOfGroups'));
        fprintf(fid, '\r\n-> The UCS definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the UCS values so that only one UCS value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and UCS values agree with each other');
        fprintf(fid, '\r\n-> If you wish to define UCS values for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last UCS value is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E093');
        rmappdata(0, 'E093')
    end
    if getappdata(0, 'E094') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f UCS values but only %.0f analysis groups', getappdata(0, 'error_log_094_numberOfUCS'), getappdata(0, 'error_log_094_numberOfGroups'));
        fprintf(fid, '\r\n-> The UCS definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the UCS values so that only one UCS value is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and UCS values agree with each other');
        fprintf(fid, '\r\n\r\nError code: E094');
        rmappdata(0, 'E094')
    end
    if getappdata(0, 'E095') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of values in B2 and B2_NF do not agree');
        fprintf(fid, '\r\n\r\nError code: E095');
        rmappdata(0, 'E095')
    end
    if getappdata(0, 'E096') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of endurance limit definitions does not match the number of analysis groups');
        fprintf(fid, '\r\n-> There are %.0f endurance limit definitions and %.0f analysis groups', getappdata(0, 'error_log_096_NEnduranceDefinitions'), getappdata(0, 'error_log_096_NGroups'));
        fprintf(fid, '\r\n-> Make sure the endurance limit references the correct number of analysis groups');
        fprintf(fid, '\r\n\r\nError code: E096');
        rmappdata(0, 'E096')
    end
    if getappdata(0, 'E097') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Cell definitions for user defined endurance limit values are not supported');
        fprintf(fid, '\r\n-> User endurance limit values must be defined as a numerical array');
        fprintf(fid, '\r\n\r\nError code: E097');
        rmappdata(0, 'E097')
    end
    if getappdata(0, 'E098') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The endurance limit definition is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, userEnduranceLimit should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, userEnduranceLimit must be a numerical array of endurance limit values');
        fprintf(fid, '\r\n\r\nError code: E098');
        rmappdata(0, 'E098')
    end
    if getappdata(0, 'E099') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of gamma definitions does not match the number of analysis groups');
        fprintf(fid, '\r\n-> There are %.0f gamma definitions and %.0f analysis groups', getappdata(0, 'error_log_099_NGammaDefinitions'), getappdata(0, 'error_log_099_NGroups'));
        fprintf(fid, '\r\n-> Make sure the gamma values reference the correct number of analysis groups');
        fprintf(fid, '\r\n\r\nError code: E099');
        rmappdata(0, 'E099')
    end
    if getappdata(0, 'E100') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Cell definitions for user defined gamma values are not supported');
        fprintf(fid, '\r\n-> User gamma values must be defined as a numerical array');
        fprintf(fid, '\r\n\r\nError code: E100');
        rmappdata(0, 'E100')
    end
    if getappdata(0, 'E101') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The gamma definition is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, userWalkerGamma should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, userWalkerGamma must be a numerical array of endurance limit values');
        fprintf(fid, '\r\n\r\nError code: E101');
        rmappdata(0, 'E101')
    end
    if getappdata(0, 'E102') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two S-N knock-down files are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The S-N knock-down definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N knock-down definition so that only one S-N knock-down file is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N knock-down files agree with each other');
        fprintf(fid, '\r\n-> If you wish to define S-N knock-down files for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first S-N knock-down file is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second S-N knock-down file is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E102');
        rmappdata(0, 'E102')
    end
    if getappdata(0, 'E103') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f S-N knock-down files', getappdata(0, 'error_log_103_numberOfGroups'), getappdata(0, 'error_log_103_numberOfSnKnockDown'));
        fprintf(fid, '\r\n-> Modify the group and/or S-N knock-down defintions so that the number of groups and S-N knock-down files agree with each other');
        fprintf(fid, '\r\n\r\nError code: E103');
        rmappdata(0, 'E103')
    end
    if getappdata(0, 'E104') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f S-N knock-down files but only %.0f analysis groups', getappdata(0, 'error_log_104_numberOfSnKnockDown'), getappdata(0, 'error_log_104_numberOfGroups'));
        fprintf(fid, '\r\n-> The S-N knock-down definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N knock-down files so that only one S-N knock-down file is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N knock-down files agree with each other');
        fprintf(fid, '\r\n-> If you wish to define S-N knock-down files for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last S-N knock-down file is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E104');
        rmappdata(0, 'E104')
    end
    if getappdata(0, 'E105') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f S-N knock-down files but only %.0f analysis groups', getappdata(0, 'error_log_105_numberOfSnKnockDown'), getappdata(0, 'error_log_105_numberOfGroups'));
        fprintf(fid, '\r\n-> The S-N knock-down definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the S-N knock-down files so that only one S-N knock-down file is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and S-N knock-down files agree with each other');
        fprintf(fid, '\r\n\r\nError code: E105');
        rmappdata(0, 'E105')
    end
    if getappdata(0, 'E106') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Group %.0f (''%s'') was read as an FEA subset, but the data position differs from the master dataset', getappdata(0, 'message_groupNumber'), getappdata(0, 'message_groupFile'));
        fprintf(fid, '\r\n-> The data position in the FEA subset defining the group must agree with that of the master dataset');
        fprintf(fid, '\r\n\r\nError code: E106');
        rmappdata(0, 'E106')
    end
    if getappdata(0, 'E107') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The item with the worst (S1 - S3) range does not exist in any of the analysis groups');
        fprintf(fid, '\r\n-> Material properties and analysis settings are unknown at this item');
        fprintf(fid, '\r\n-> Set ITEMS = ''ALL'' to analyse the specified groups, remove group definitions or append ''DEFAULT'' to the end of the GROUP option in the job file');
        fprintf(fid, '\r\n\r\nError code: E107');
        rmappdata(0, 'E107')
    end
    if getappdata(0, 'E109') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of Goodman envelope definitions does not match the number of analysis groups');
        fprintf(fid, '\r\n-> There are %.0f Goodman envelope definitions and %.0f analysis groups', getappdata(0, 'error_log_109_NGoodmanDefinitions'), getappdata(0, 'error_log_109_NGroups'));
        fprintf(fid, '\r\n-> Make sure the Goodman envelope definition references the correct number of analysis groups');
        fprintf(fid, '\r\n\r\nError code: E109');
        rmappdata(0, 'E109')
    end
    if getappdata(0, 'E110') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The Goodman envelope definition is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, modifiedGoodman should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, modifiedGoodman must be a numerical array of envelope numbers');
        fprintf(fid, '\r\n\r\nError code: E110');
        rmappdata(0, 'E110')
    end
    if getappdata(0, 'E111') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of Goodman limit stress definitions does not match the number of Goodman envelope defintitions');
        fprintf(fid, '\r\n-> There are %.0f Goodman limit stress definitions and %.0f Goodman envelope definitions', getappdata(0, 'error_log_111_NGoodmanLimits'), getappdata(0, 'error_log_111_NGroups'));
        fprintf(fid, '\r\n-> Make sure the Goodman limit stress definition references the correct number of Goodman envelope definitions');
        fprintf(fid, '\r\n-> The Goodman limit stress can only be defined for the standard Goodman envelope (modifiedGoodman = 1.0)');
        fprintf(fid, '\r\n\r\nError code: E111');
        rmappdata(0, 'E111')
    end
    if getappdata(0, 'E113') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The element positions in the dataset file(s) are not consistent between regions');
        fprintf(fid, '\r\n-> Check the dataset file(s) for errors');
        fprintf(fid, '\r\n-> If the dataset(s) contain a mixture of plane stress and 3D elements, ensure that the stresses are written to the same element position and set PLANE_STRESS = 1.0 in the job file');
        fprintf(fid, '\r\n\r\nError code: E113');
        rmappdata(0, 'E113')
    end
    % Problems with CONTINUE_FROM
    if getappdata(0, 'E114') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The option CONTINUE_FROM must be a string');
        fprintf(fid, '\r\n\r\nError code: E114');
        rmappdata(0, 'E114')
    end
    if getappdata(0, 'E115') == 1.0
        jobName = getappdata(0, 'continueFrom');
        fprintf(fid, '\r\n\r\n***ERROR: The field data from the job ''%s'' could not be located', jobName);
        fprintf(fid, '\r\n-> To perform the analysis as a continuation from a previous job, the following file must be available:');
        fprintf(fid, '\r\n   ''%s\\output\\%s\\Data Files\\f-output-all.dat''', pwd, jobName);
        fprintf(fid, '\r\n-> Field output must be enabled in ''%s'' by setting OUTPUT_FIELD = 1.0', jobName);
        fprintf(fid, '\r\n\r\nError code: E115');
        rmappdata(0, 'E115')
    end
    if getappdata(0, 'E116') == 1.0
        jobName = getappdata(0, 'continueFrom');
        fprintf(fid, '\r\n\r\n***ERROR: The field data file from job ''%s'' could not be imported', jobName);
        fprintf(fid, '\r\n-> Make sure the field output file is formatted correctly');
        fprintf(fid, '\r\n\r\nError code: E116');
        rmappdata(0, 'E116')
    end
    if getappdata(0, 'E117') == 1.0
        jobName = getappdata(0, 'continueFrom');
        fprintf(fid, '\r\n\r\n***ERROR: The field data from job ''%s'' could not be read', jobName);
        fprintf(fid, '\r\n-> Analysis continuation will not work if the field output file has been modified by the user');
        fprintf(fid, '\r\n\r\nError code: E117');
        rmappdata(0, 'E117')
    end
    if getappdata(0, 'E118') == 1.0
        jobName = getappdata(0, 'continueFrom');
        fprintf(fid, '\r\n\r\n***ERROR: The field data from job ''%s'' could not be read', jobName);
        fprintf(fid, '\r\n-> Analysis continuation will not work if the field output file has been modified by the user');
        fprintf(fid, '\r\n\r\nError code: E118');
        rmappdata(0, 'E118')
    end
    if getappdata(0, 'E119') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The names of the current and the previous job must be unique when continuing an analysis');
        fprintf(fid, '\r\n\r\nError code: E119');
        rmappdata(0, 'E119')
    end
    if getappdata(0, 'E120') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: FRF mean stress (tensile) normalization parameters are defined as a cell with the frfNormParamMeanT variable, but the number of definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF mean stress (tensile) normalization parameters and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_120_NfrfDefinitions'), getappdata(0, 'error_log_120_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF mean stress (tensile) normalization parameter definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E120');
        rmappdata(0, 'E120')
    end
    if getappdata(0, 'E121') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The FRF mean stress (tensile) normalization factor definiion is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, frfNormParamMeanT should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, frfNormParamMeanT must either be a numerical array, or a cell array of numericals and strings');
        fprintf(fid, '\r\n\r\nError code: E121');
        rmappdata(0, 'E121')
    end
    if getappdata(0, 'E122') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of FRF mean stress (tensile) normalization factor definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF mean stress (tensile) normalization factor definitions and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_122_NfrfDefinitions'), getappdata(0, 'error_log_122_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF mean stress (tensile) normalization factor definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E122');
        rmappdata(0, 'E122')
    end
    if getappdata(0, 'E123') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of FRF stress amplitude normalization factor definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF stress amplitude normalization factor definitions and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_123_NfrfDefinitions'), getappdata(0, 'error_log_123_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF stress amplitude normalization factor definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E123');
        rmappdata(0, 'E123')
    end
    if getappdata(0, 'E124') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: FRF stress amplitude normalization parameters are defined as a cell with the frfNormParamAmp variable, but the number of definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF stress amplitude normalization parameters and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_124_NfrfDefinitions'), getappdata(0, 'error_log_124_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF stress amplitude normalization parameter definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E124');
        rmappdata(0, 'E124')
    end
    if getappdata(0, 'E125') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The FRF stress amplitude normalization factor definiion is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, frfNormParamAmp should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, frfNormParamAmp must either be a numerical array, or a cell array of numericals and strings');
        fprintf(fid, '\r\n\r\nError code: E125');
        rmappdata(0, 'E125')
    end
    if getappdata(0, 'E126') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The number of FRF mean stress (compressive) normalization factor definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF mean stress (compressive) normalization factor definitions and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_126_NfrfDefinitions'), getappdata(0, 'error_log_126_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF mean stress (compressive) normalization factor definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E126');
        rmappdata(0, 'E126')
    end
    if getappdata(0, 'E127') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: FRF mean stress (compressive) normalization parameters are defined as a cell with the frfNormParamMeanC variable, but the number of definitions does not match the number of user-defined FRF envelopes');
        fprintf(fid, '\r\n-> There are %.0f FRF mean stress (compressive) normalization parameters and %.0f user-defined FRF envelopes', getappdata(0, 'error_log_127_NfrfDefinitions'), getappdata(0, 'error_log_127_NGroups'));
        fprintf(fid, '\r\n-> Make sure the FRF mean stress (compressive) normalization parameter definition references the correct number of user-defined FRF envelopes');
        fprintf(fid, '\r\n\r\nError code: E127');
        rmappdata(0, 'E127')
    end
    if getappdata(0, 'E128') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The FRF mean stress (compressive) normalization factor definiion is invalid');
        fprintf(fid, '\r\n-> For a single analysis group, frfNormParamMeanC should be a single value');
        fprintf(fid, '\r\n-> For multiple analysis groups, frfNormParamMeanC must either be a numerical array, or a cell array of numericals and strings');
        fprintf(fid, '\r\n\r\nError code: E128');
        rmappdata(0, 'E128')
    end
    if getappdata(0, 'E112') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two notch sensitivity constants are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The notch sensitivity constant definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch sensitivity constant definition so that only one notch sensitivity constant is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch sensitivity constants agree with each other');
        fprintf(fid, '\r\n-> If you wish to define notch sensitivity constants for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first notch sensitivity constant is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second notch sensitivity constant is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E112');
        rmappdata(0, 'E112')
    end
    if getappdata(0, 'E129') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f notch sensitivity constants', getappdata(0, 'error_log_129_numberOfGroups'), getappdata(0, 'error_log_129_numberOfConstants'));
        fprintf(fid, '\r\n-> Modify the group and/or notch sensitivity constant defintions so that the number of groups and notch sensitivity constants agree with each other');
        fprintf(fid, '\r\n\r\nError code: E129');
        rmappdata(0, 'E129')
    end
    if getappdata(0, 'E130') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f notch sensitivity constants but only %.0f analysis groups', getappdata(0, 'error_log_130_numberOfConstants'), getappdata(0, 'error_log_130_numberOfGroups'));
        fprintf(fid, '\r\n-> The notch sensitivity constant definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch sensitivity constants so that only one notch sensitivity constant is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch sensitivity constants agree with each other');
        fprintf(fid, '\r\n-> If you wish to define notch sensitivity constants for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last notch sensitivity constant is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E130');
        rmappdata(0, 'E130')
    end
    if getappdata(0, 'E131') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f notch sensitivity constants but only %.0f analysis groups', getappdata(0, 'error_log_131_numberOfConstants'), getappdata(0, 'error_log_131_numberOfGroups'));
        fprintf(fid, '\r\n-> The notch sensitivity constant definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch sensitivity constants so that only one notch sensitivity constant is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch sensitivity constants agree with each other');
        fprintf(fid, '\r\n\r\nError code: E131');
        rmappdata(0, 'E131')
    end
    if getappdata(0, 'E132') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: Two notch root radii are specified, but only one analysis group was defined');
        fprintf(fid, '\r\n-> The notch root radius definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch root radius definition so that only one notch root radius is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch root radii agree with each other');
        fprintf(fid, '\r\n-> If you wish to define notch root radii for a single analysis group, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group>, ''DEFAULT''}, where the first notch root radius is used');
        fprintf(fid, '\r\n   to analyse <sub_group> and the second notch root radius is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E132');
        rmappdata(0, 'E132')
    end
    if getappdata(0, 'E133') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f analysis groups but only %.0f notch root radii', getappdata(0, 'error_log_133_numberOfGroups'), getappdata(0, 'error_log_133_numberOfRadii'));
        fprintf(fid, '\r\n-> Modify the group and/or notch root radius defintions so that the number of groups and notch root radii agree with each other');
        fprintf(fid, '\r\n\r\nError code: E133');
        rmappdata(0, 'E133')
    end
    if getappdata(0, 'E134') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f notch root radii but only %.0f analysis groups', getappdata(0, 'error_log_134_numberOfRadii'), getappdata(0, 'error_log_134_numberOfGroups'));
        fprintf(fid, '\r\n-> The notch root radius definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch root radii so that only one notch root radius is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch root radii agree with each other');
        fprintf(fid, '\r\n-> If you wish to define notch root radii for multiple analysis groups, followed by analysis of the');
        fprintf(fid, '\r\n   remainder of the model, specify GROUP as {<sub_group_1>,..., <sub_group_n>, ''DEFAULT''}, where the');
        fprintf(fid, '\r\n   last notch root radius is used to analyse the rest of the model');
        fprintf(fid, '\r\n\r\nError code: E134');
        rmappdata(0, 'E134')
    end
    if getappdata(0, 'E135') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: There are %.0f notch root radii but only %.0f analysis groups', getappdata(0, 'error_log_135_numberOfRadii'), getappdata(0, 'error_log_135_numberOfGroups'));
        fprintf(fid, '\r\n-> The notch root radius definition is ambiguous');
        fprintf(fid, '\r\n-> Either modify the notch root radii so that only one notch root radius is specified, or modify the group');
        fprintf(fid, '\r\n   defintion so that the number of groups and notch root radii agree with each other');
        fprintf(fid, '\r\n\r\nError code: E135');
        rmappdata(0, 'E135')
    end
    if getappdata(0, 'E136') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The user Sr-N weld data could not be processed');
        
        % Get the error ID
        ID = getappdata(0, 'E136_id');
        switch ID
            case 1.0
                fprintf(fid, '\r\n-> Two rows of data are required');
            case 2.0
                fprintf(fid, '\r\n-> At least two data points are required');
            case 3.0
                fprintf(fid, '\r\n-> S-values must be monotonically decreasing along the row');
            case 4.0
                fprintf(fid, '\r\n-> N-values must be monotonically increasing along the row');
            case 5.0
                fprintf(fid, '\r\n-> Two columns of data are required');
            case 6.0
                fprintf(fid, '\r\n-> At least two data points are required');
            case 7.0
                fprintf(fid, '\r\n-> S-values must be monotonically decreasing along the column');
            case 8.0
                fprintf(fid, '\r\n-> N-values must be monotonically increasing along the column');
        end
        if getappdata(0, 'bs7608_weldClass1Arg') == 1.0
            fprintf(fid, '\r\n-> By default, Quick Fatigue Tool assumes that the user Sr-N is provided in a column-wise fashion.');
            fprintf(fid, '\r\n   This behaviour can be overridden by specifying WELD_CLASS = {<userCurveFile>, ''ROW''}');
        end
        fprintf(fid, '\r\n\r\nError code: E136');
        rmappdata(0, 'E136')
    end
    if getappdata(0, 'E137') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user FRF amplitude definition for ''%s'' (group %.0f) contains invalid amplitude values', getappdata(0, 'E137_file'), getappdata(0, 'E137_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user MSC amplitude definition for ''%s'' contains invalid amplitude values', getappdata(0, 'E137_file'));
        end
        fprintf(fid, '\r\n-> The straight line from (0,0) to the cycle (Sm,Sa) may not extend across the envelope more than once');
        fprintf(fid, '\r\n-> For detailed guidance on creating user-defined .msc files, consult Section 7.9 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E137');
        rmappdata(0, 'E137')
        rmappdata(0, 'E137_file')
        rmappdata(0, 'E137_group')
    end
    if getappdata(0, 'E138') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'FRF') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user FRF amplitude definition for ''%s'' (group %.0f) contains invalid amplitude values', getappdata(0, 'E138_file'), getappdata(0, 'E138_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user MSC amplitude definition for ''%s'' contains invalid amplitude values', getappdata(0, 'E138_file'));
        end
        fprintf(fid, '\r\n-> Negative amplitude values are not permitted');
        fprintf(fid, '\r\n-> For detailed guidance on creating user-defined .msc files, consult Section 7.9 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E137');
        rmappdata(0, 'E138')
        rmappdata(0, 'E138_file')
        rmappdata(0, 'E138_group')
    end
    if getappdata(0, 'E139') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'MSC') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user FRF definition for ''%s'' (group %.0f) is invalid', getappdata(0, 'E139_file'), getappdata(0, 'E139_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user MSC definition for ''%s'' is invalid', getappdata(0, 'E139_file'));
        end
        fprintf(fid, '\r\n-> The file must contain two columns of data');
        fprintf(fid, '\r\n-> The first column must be values of mean stress (in descending order)');
        fprintf(fid, '\r\n-> The second column must be the corresponding stress ampliitude values');
        fprintf(fid, '\r\n-> For detailed guidance on creating user-defined .msc files, consult Section 7.9 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E139');
        rmappdata(0, 'E139')
        rmappdata(0, 'E139_file')
        rmappdata(0, 'E139_group')
    end
    if getappdata(0, 'E140') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'MSC') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user FRF definition for ''%s'' (group %.0f) is invalid', getappdata(0, 'E140_file'), getappdata(0, 'E140_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user MSC definition for ''%s'' is invalid', getappdata(0, 'E140_file'));
        end
        fprintf(fid, '\r\n-> The file must contain at least two user-defined (Sm,Sa) pairs');
        fprintf(fid, '\r\n-> For detailed guidance on creating user-defined .msc files, consult Section 7.9 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E140');
        rmappdata(0, 'E140')
        rmappdata(0, 'E140_file')
        rmappdata(0, 'E140_group')
    end
    if getappdata(0, 'E141') == 1.0
        if strcmp(getappdata(0, 'mscORfrf'), 'MSC') == 1.0
            fprintf(fid, '\r\n\r\n***ERROR: The user FRF definition for ''%s'' (group %.0f) contains invalid amplitude values', getappdata(0, 'E141_file'), getappdata(0, 'E141_group'));
        else
            fprintf(fid, '\r\n\r\n***ERROR: The user MSC definition for ''%s'' contains invalid amplitude values', getappdata(0, 'E141_file'));
        end
        fprintf(fid, '\r\n-> On a given side of the Sa-axis, duplicate amplitude values may not be defined');
        fprintf(fid, '\r\n-> For detailed guidance on creating user-defined .msc files, consult Section 7.9 of the Quick Fatigue Tool User Guide');
        fprintf(fid, '\r\n\r\nError code: E141');
        rmappdata(0, 'E141')
        rmappdata(0, 'E141_file')
        rmappdata(0, 'E141_group')
    end
    if getappdata(0, 'E142') == 1.0
        fprintf(fid, '\r\n\r\n***ERROR: The Walker gamma definition in group %.0f is %.3g', getappdata(0, 'error_log_142_group'), getappdata(0, 'error_log_142_gamma'));
        fprintf(fid, '\r\n-> Negative values of the Walker gamma parameter are not permitted');
        fprintf(fid, '\r\n\r\nError code: E142');
        rmappdata(0, 'E142')
    end
    
    % Write file footer
    c = clock;
    fprintf(fid, '\r\n\r\nQUICK FATIGUE TOOL EXITED WITH AN ERROR (%s)\r\n\r\n', datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))));
    fprintf(fid, '========================================================================================');
    
    fclose(fid);
    
    % Prompt user if they would like to view the analysis log
    if (ispc == 1.0) && (ismac == 0.0)
        answer = questdlg('The analysis exited with and error - Please see the log file for more information.', 'Quick Fatigue Tool', 'View log', 'Close', 'View log');
    elseif (ispc == 0.0) && (ismac == 1.0)
        answer = errordlg('The analysis exited with and error - Please see the log file for more information.', 'Quick Fatigue Tool');
    else
        answer = -1.0;
    end
    
    if strcmpi(answer, 'View log') == 1.0
        winopen(errLogFile)
    end
end

%% Remove %APPDATA%
if (getappdata(0, 'cleanAppData') == 2.0) || (getappdata(0, 'cleanAppData') == 3.0)
    app=getappdata(0.0);
    appdatas = fieldnames(app);
    for kA = 1:length(appdatas)
        name = sprintf('%s',appdatas{kA});
        rmappdata(0.0, name)
    end
end

fclose('all');

%% Re-enable warnings
warning('on', 'all')
end
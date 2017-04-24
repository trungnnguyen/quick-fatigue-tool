function [] = job(varargin)
%JOB    QFT function to submit analysis job from text file.
%   This function contains code to submit an analysis job from a text file
%   using the MATLAB command line.
%   
%   JOB(JOBNAME) submits an analysis job from a text file 'JOBNAME.*'
%   containing valid job file option and material definitions.
%
%   JOB(JOBNAME, OPTION) submits the analyis job JOBNAME with additional
%   options. Available options are:
%
%     'datacheck'   - Submits the analysis job as a data check analysis
%     'interactive' - Prints an echo of the message (.msg) file to the
%     MATLAB commands window.
%
%   If the extention of the job file is '.inp', then the JOBNAME parameter
%   can be speficied without the extention.
%
%   See also importMaterial, keywords, fetchMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4.2 Configuring a data check analysis
%      2.4.3 Configuring an analysis from a text file
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      1 Job file options
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 10-Apr-2017 12:07:34 GMT
    
    %%
    
%% GET INPUT ARGUMENTS
% Initialize data check flag
datacheck = 0.0;    clc

switch nargin
    % User called JOB with no arguments
    case 0.0
        varargin = cellstr(input('Input file: ', 's'));
    % User called JOB with one argument
    case 1.0
        if strcmpi(varargin, 'interactive') == 1.0
            setappdata(0, 'force_echoMessagesToCWIN', 1.0)
            varargin = cellstr(input('Input file: ', 's'));
        elseif strcmpi(varargin, 'datacheck') == 1.0
            datacheck = 1.0;
            varargin = cellstr(input('Input file: ', 's'));
        else
            % Assume that VARARGIN is JOBNAME
        end
    % User called JOB with more than one argument
    otherwise
        if nargin > 3.0
            fprintf('ERROR: JOB was called with too many input arguments\n');
            return
        elseif (strcmpi(varargin{1.0}, 'interactive') == 1.0) || (strcmpi(varargin{1.0}, 'datacheck') == 1.0)
            fprintf('ERROR: The command line option ''%s'' is misplaced\n       Whenever JOB is called with OPTION, the first argument must be the name of the job file\n', varargin{1.0});
            return
        else
            for i = 2:nargin
                if strcmpi(varargin{i}, 'interactive') == 1.0
                    setappdata(0, 'force_echoMessagesToCWIN', 1.0)
                elseif strcmpi(varargin{i}, 'datacheck') == 1.0
                    datacheck = 1.0;
                else
                    fprintf('ERROR: Invalid command line option ''%s''\n       Valid options are:\n[<jobName>, interactive, datacheck]\n', varargin{i});
                    return
                end
            end
        end
end

% The input file is the first argument
inputFile = varargin{1.0};

%% INITIALIZE BUFFERS
[kwStr, kwStrSp, kwData] = keywords.initialize();

if datacheck == 1.0
    kwData{40.0} = 1.0;
end

% Flag indicating that text file processor was used
setappdata(0, 'jobFromTextFile', 1.0)

% Check the file extension
[~, ~, EXT] = fileparts(inputFile);
if isempty(EXT) == 1.0
    inputFile = [inputFile, '.inp'];
elseif strcmp(EXT, '.') == 1.0
    inputFile = [inputFile, 'inp'];
end

% Check that the file exists
if exist(inputFile, 'file') == 0.0
    clc
    fprintf('ERROR: Input file ''%s'' could not be located\n', inputFile);
    return
end

% Open the input file for reading
fid = fopen(inputFile, 'r+');

% Index to store incomplete keyword definitions
partialKw = cell(1.0, 1.0);
ambiguousKw = cell(1.0, 1.0);
undefinedKw = cell(1.0, 1.0);
incompleteKw = cell(1.0, 1.0);
assumedKw = cell(1.0, 1.0);
badKw = cell(1.0, 1.0);
processedKeywords = cell(1.0, 1.0);

index_pkw = 1.0;
index_ikw = 1.0;
index_ukw = 1.0;
index_akw = 1.0;
index_bkw = 1.0;
index_ckw = 1.0;

% Buffer to count the number of keywords successfully parsed
numberOfKeywords = 0.0;
emptyKeywords = 0.0;

% Buffer to store number of lines parsed by the material file processor
nTLINE_total = 0.0;

%% READ THE CURRENT LINE
% While the end of the file has not been reached
while feof(fid) == 0.0
    % Get the current line in the file
    TLINE = fgetl(fid);
    
    % If the current line is emtpy, skip to the next line
    if isempty(TLINE) == 1.0
        continue
    end
    
    % Check that the current line is a keyword
    if strcmp(TLINE(1.0), '*') == 1.0
        % The current line is a keyword definition
        
        % Isolate the keyword
        TOKEN = strtok(TLINE, '=');
        
        %{
            If the current token is *USER MATERIAL, process this material
            and add it to the local database
        %}
        % Remove spaces and asterisk from the keyword
        TOKEN_umat = TOKEN;
        TOKEN_umat(ismember(TOKEN_umat,' *')) = [];
        if strcmpi(strtok(lower(TOKEN_umat), ','), 'USERMATERIAL') == 1.0
            [error, material_properties, materialName, nTLINE_material, nTLINE_total] = importMaterial.processFile(inputFile, nTLINE_total); %#ok<ASGLU>
            
            %{
                Check to see if there is already a material by that name in
                the local database
            %}
            if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
                response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Abort', 'Overwrite');
                
                if (strcmpi(response, 'Abort') == 1.0) || (isempty(response) == 1.0)
                    fprintf('[NOTICE] Input file processing was aborted by the user\n');
                    return
                elseif strcmpi(response, 'Keep file') == 1.0
                    % Change the name of the new results output database
                    oldMaterial = materialName;
                    while exist([oldMaterial, '.mat'], 'file') == 2.0
                        oldMaterial = [oldMaterial , '-old']; %#ok<AGROW>
                    end
                    
                    % Rename the original material
                    movefile(['Data/material/local/', materialName, '.mat'], ['Data/material/local/', oldMaterial, '.mat'])
                end
            end
            
            % Save the material in the local database
            try
                save(['Data/material/local/', materialName], 'material_properties')
            catch
                fprintf('ERROR: The material ''%s'' could not be saved to the local database. Make sure the material save location has read/write access\n', materialName);
                return
            end
            
            % Advance the file by nTLINE to get past the material definition
            for i = 1:nTLINE_material
                TLINE = fgetl(fid);
            end 
            TOKEN = strtok(TLINE, '=');
        end
        
        % Get the length of the token
        tokenLength = length(TOKEN);
        
        if tokenLength == length(TLINE)
            %{
                There is no '=' sign in the keyword declaration or there is
                no data after the asterisk
            %}
            if tokenLength == 1.0
                emptyKeywords = emptyKeywords + 1.0;
            else
                partialKw{index_pkw} = TOKEN;
                
                index_pkw = index_pkw + 1.0;
            end
            continue
        end
        
        % Remove spaces and asterisk from the keyword
        TOKEN(ismember(TOKEN,' , *')) = [];
        
        % Check if the keyword matches the library
        matchingKw = find(strncmpi({TOKEN}, kwStr, length(TOKEN)) == 1.0);
        
        if length(matchingKw) > 1.0
            % The keyword definition is ambiguous
            ambiguousKw{index_akw} = TOKEN;
            
            index_akw = index_akw + 1.0;
            continue
        elseif isempty(matchingKw) == 1.0
            % The keyword could not be found in the library
            undefinedKw{index_ukw} = TOKEN;
            
            index_ukw = index_ukw + 1.0;
            continue
        elseif length(kwStr{matchingKw}) ~= length(TOKEN)
            % The keyword is unambiguous, but incomplete
            incompleteKw{index_ikw} = TOKEN;
            assumedKw{index_ikw} = kwStrSp{matchingKw};
            
            index_ikw = index_ikw + 1.0;
        end
    else
        continue
    end
    
    %% READ DATA FROM THE CURRENT KEYWORD
    for i = 2:length(TLINE)
        % If the parser reached the end of the line, discard the line
        if tokenLength + i > length(TLINE)
            badKw{index_bkw} = TOKEN;
            
            index_bkw = index_bkw + 1.0;
            break
        end
        
        % Get the current character from TLINE
        currentChar = TLINE(tokenLength + i);
        currentLine = TLINE(tokenLength + i:end);
        
        if strcmp(currentChar, ' ') == 1.0
            % Continue until a character is found
            continue
        end
        
        % If the current line ends with a semicolon, remove it
        if strcmp(currentLine(end), ';') == 1.0
            currentLine(end) = [];
        end
        
        % Count the keyword
        numberOfKeywords = numberOfKeywords + 1.0;
        processedKeywords{index_ckw} = kwStrSp{matchingKw};
        index_ckw = index_ckw + 1.0;
        
        if strcmpi(currentChar, sprintf('''')) == 1.0
            %{
                The keyword definition begins as an apostrophe. Treat the
                input as a string
            %}
            currentLine(ismember(currentLine, sprintf(''''))) = [];
            
            kwData{matchingKw} = currentLine;
            
            break
        elseif strcmpi(currentChar, '[') == 1.0
            % The keyword definition appears to be a numeric array
            if isnumeric(str2num(currentLine)) == 1.0 %#ok<ST2NM>
                kwData{matchingKw} = str2num(currentLine); %#ok<ST2NM>
                
                break
            end
        elseif isnumeric(str2double(currentChar)) == 1.0 && isnan(str2double(currentChar)) == 0.0 && isreal(str2double(currentChar)) == 1.0
            % The keyword definition appears to be a numeric value
            kwData{matchingKw} = str2double(currentLine);
            
            break
        elseif strcmpi(currentChar, '{') == 1.0
            % The keyword definition appears to be a cell
            
            %{
                The cell is represented as a single character array from
                FGETL. In order to convert this array into a cell, use
                regular expressions to match metacharacters to the FGETL
                string
            %}
            C = keywords.interpretCell(currentLine, matchingKw);
            
            kwData{matchingKw} = C;
            
            break
        else
            %{
                The keyword definition does not start as a square or curly
                bracket or an apostrophe, and is not numeric. The
                definition might be invalid, but it may also be intended as
				a string vwhich isn't enclosed by apostrophes. Just assume
				the definition is a string. QFT will throw an error or crash
                later if the definition is invalid
            %}
            kwData{matchingKw} = currentLine;
                
            break
        end
    end
end

%% SAVE THE BUFFERS
setappdata(0, 'kw_partial', partialKw)
setappdata(0, 'kw_processed', processedKeywords)
setappdata(0, 'kw_undefined', undefinedKw)
setappdata(0, 'kw_bad', badKw)

%% CLOSE THE FILE AND SUBMIT THE JOB
% Close the input file
fclose(fid);

% Submit the job for analysis
main(kwData)
end
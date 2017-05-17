classdef importMaterial < handle
%IMPORTMATERIAL    QFT class for material import processing.
%   This class contains methods for material import processing tasks.
%   
%   IMPORTMATERIAL is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also keywords, fetchMaterial, job.
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% INITIALIZE DEFAULT KEYWORDS
        function [material_properties, kwStr, kwStrSp] = initialize()
            % DEFAULT MATERIAL STRUCTURE
            material_properties = struct(...
                'default_algorithm', 6.0,...
                'default_msc', 1.0,...
                'class', 1.0,...
                'behavior', 1.0,...
                'reg_model', 1.0,...
                'cael', 2e+07,...
                'cael_active', 0.0,...
                'e', [],...
                'e_active', 0.0,...
                'uts', [],...
                'uts_active', 0.0,...
                'proof', [],...
                'proof_active', 0.0,...
                'poisson', 0.33,...
                'poisson_active', 0.0,...
                's_values', [],...
                'n_values', [],...
                'r_values', [],...
                'sf', [],...
                'sf_active', 0.0,...
                'b', [],...
                'b_active', 0.0,...
                'ef', [],...
                'ef_active', 0.0,...
                'c', [],...
                'c_active', 0.0,...
                'kp', [],...
                'kp_active', 0.0,...
                'np', [],...
                'np_active', 0.0,...
                'nssc', 0.2857,...
                'nssc_active', 0.0,...
                'comment', []);
            
            % KEYWORD STRINGS
            kwStr = {'USERMATERIAL', 'DESCRIPTION', 'DEFAULTALGORITHM',...
                'DEFAULTMSC', 'CAEL', 'REGRESSION', 'MECHANICAL',...
                'FATIGUE', 'CYCLIC', 'NORMALSTRESSSENSITIVITY', 'CLASS',...
                'ENDMATERIAL'};
            
            kwStrSp = {'USER MATERIAL', 'DESCRIPTION', 'DEFAULT ALGORITHM',...
                'DEFAULT MSC', 'CAEL', 'REGRESSION', 'MECHANICAL',...
                'FATIGUE', 'CYCLIC', 'NORMAL STRESS SENSITIVITY', 'CLASS',...
                'END MATERIAL'};
        end
        
        %% PROCESS THE MATERIAL FILE
        function [error, material_properties, materialName, nTLINE_material, nTLINE_total] = processFile(materialFile, nTLINE_total)
            % Initialize the error flag
            %{
                1: Could not open file
                2: No material data
            %}
            error = 0.0;
            
            % Initialize the material properties
            [material_properties, kwStr, kwStrSp] = importMaterial.initialize();
            
            % Initialize the material name
            materialName = 'Material-1 (empty)';
            
            % Initialize the keyword warnings
            keywordWarnings = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,...
                0.0, 0.0, 0.0, 0.0, ];
            
            % Counter for number of lines read for the material
            nTLINE_material = 1.0;
            
            % Open the material file
            fid = fopen(materialFile, 'r+');
            
            % If the file could not be opened, RETURN
            if fid == -1.0
                error = 1.0;
                % Print the import summary
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            %{
                If the material is being read from a job file and this is
                not the first definition, advance the file by nTLINE so
                that the next definition can be read
            %}
            if nTLINE_total ~= -1.0
                for i = 1:nTLINE_total
                    % Get the next line in the file
                    TLINE = lower(fgetl(fid));
                end
            end
            
            %% Search for material definition keyword
            foundMaterial = 0.0;
            
            while feof(fid) == 0.0
                % Get the next line in the file
                TLINE = lower(fgetl(fid));  nTLINE_total = nTLINE_total + 1.0;
                
                TLINEi = TLINE;
                TLINEi(ismember(TLINEi, ' ')) = [];
                
                % If the current line is emtpy, skip to the next line
                if strfind(TLINEi, '*usermaterial') == 1.0
                    % A material definition has been found
                    foundMaterial = 1.0;
                    break
                elseif strfind(TLINEi, '*endmaterial') == 1.0
                    break
                end
            end
            
            %% Process *USER MATERIAL
            if foundMaterial == 0.0;
                %{
                    A material definition keyword could not be found in the
                    file. RETURN and warn the user
                %}
                error = 2.0;
                % Print the import summary
                if isappdata(0, 'materialManagerImport') == 1.0
                    importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                    rmappdata(0, 'materialManagerImport')
                end
                return
            end
            
            % Check if the *USER MATERIAL keyword contains the NAME parameter
            [~, TOKEN] = strtok(TLINE, ',');
            TOKEN = lower(TOKEN);
            TOKEN(1.0) = [];
            materialName = strtrim(TOKEN);
            
            % Get the next line in the file
            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
            
            % User material end flag
            endOfMaterial = 0.0;
            
            %% Process next keyword
            while (feof(fid) == 0.0) && (endOfMaterial == 0.0)
                % If the current line is emtpy, skip to the next line
                if isempty(TLINE) == 1.0
                    % Get the next line in the file
                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                    
                    continue
                end
                
                % Check that the current line is a keyword
                if strcmp(TLINE(1.0), '*') == 1.0
                    % The current line is a keyword definition
                    
                    % Isolate the keyword
                    TOKEN = strtok(TLINE, ',');
                    
                    % Get the length of the token
                    tokenLength = length(TOKEN);
                    
                    % Get the remainder of the keyword definition
                    parameter = TLINE((tokenLength + 1.0):end);
                    
                    % Remove spaces and asterisk from the keyword
                    TOKEN(ismember(TOKEN,' , *')) = [];
                    
                    % Check if the keyword matches the library
                    matchingKw = find(strncmpi({TOKEN}, kwStr, length(TOKEN)) == 1.0);
                    
                    if length(matchingKw) > 1.0
                        % Get the next line in the file
                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        
                        % The keyword definition is ambiguous
                        continue
                    elseif isempty(matchingKw) == 1.0
                        % Get the next line in the file
                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        
                        % The keyword could not be found in the library
                        continue
                    end
                    
                    % Process the appropriate keyword
                    switch matchingKw
                        case 2.0 % *DESCRIPTION
                            %{
                                The material description is defined as all
                                of the text under the keyword until the
                                next keyword is encountered
                            %}
                            % Initialize the description
                            material_description = '';
                            
                            % Set the end criterion
                            continueKeyword = 1.0;
                            
                            while continueKeyword == 1.0
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Check for end condition
                                if isempty(TLINE) == 0.0 && strcmpi(TLINE(1.0), '*') == 1.0
                                    % End of description
                                    break
                                else
                                    material_description = [material_description, TLINE]; %#ok<AGROW>
                                end
                            end
                            
                            % Add the property to the material
                            material_properties.comment = material_description;
                        case 3.0 % *DEFAULT ALGORITHM
                            %{
                                The default algorithm is defined by a
                                single parameter after the keyword
                                declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'uniaxial'
                                    material_properties.default_algorithm = 14.0;
                                case 'sbbm'
                                    material_properties.default_algorithm = 6.0;
                                case 'normal'
                                    material_properties.default_algorithm = 7.0;
                                case 'findley'
                                    material_properties.default_algorithm = 8.0;
                                case 'invariant'
                                    material_properties.default_algorithm = 9.0;
                                case 'nasalife'
                                    material_properties.default_algorithm = 10.0;
                                otherwise
                                    material_properties.default_algorithm = 6.0;
                                    keywordWarnings(3.0) = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 4.0 % *DEFAULT MSC
                            %{
                                The default mean stress correction is
                                defined by a single parameter after the
                                keyword declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'morrow'
                                    material_properties.default_msc = 1.0;
                                case 'goodman'
                                    material_properties.default_msc = 2.0;
                                case 'soderberg'
                                    material_properties.default_msc = 3.0;
                                case 'walker'
                                    material_properties.default_msc = 4.0;
                                case 'swt'
                                    material_properties.default_msc = 5.0;
                                case 'gerber'
                                    material_properties.default_msc = 6.0;
                                case 'ratio'
                                    material_properties.default_msc = 7.0;
                                case 'none'
                                    material_properties.default_msc = 8.0;
                                otherwise
                                    material_properties.default_msc = 2.0;
                                    keywordWarnings(4.0) = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 5.0 % *CAEL
                            %{
                                The constant amplitude endurance limit is
                                defined as up to two numeric values
                                directly below the keyword declaration
                            %}
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                            
                            % If the next line is a keyword definition, continue
                            if (isempty(TLINE) == 0.0) && (strcmp(TLINE, '*') == 1.0)
                                keywordWarnings(5.0) = 1.0;
                                continue
                            end
                            
                            % Get the numeric value of the data line
                            cael = str2num(TLINE); %#ok<ST2NM>
                            
                            if isempty(cael) == 1.0
                                % Get the next line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                keywordWarnings(5.0) = 1.0;
                                continue
                            end
                            
                            % Process the data line
                            if length(cael) >= 2.0
                                cael = cael(1.0:2.0);
                                
                                material_properties.cael = cael(1.0);
                                material_properties.cael_active = cael(2.0);
                            else
                                material_properties.cael = cael(1.0);
                                material_properties.cael_active = 1.0;
                            end
                            
                            % Get the next line
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 6.0 % *REGRESSION
                            %{
                                The regression method is defined by a
                                single parameter after the keyword
                                declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'uniform'
                                    material_properties.reg_model = 1.0;
                                case 'universal'
                                    material_properties.reg_model = 2.0;
                                case 'modified'
                                    material_properties.reg_model = 3.0;
                                case '9050'
                                    material_properties.reg_model = 4.0;
                                case 'none'
                                    material_properties.reg_model = 5.0;
                                otherwise
                                    material_properties.reg_model = 1.0;
                                    keywordWarnings(6.0) = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 7.0 % *MECHANICAL
                            %{
                                Mechanical properties are defined by up to
                                four numeric values per data line, and up
                                to two datalines, directly below the
                                keyword declaration
                            %}
                            for dataLine = 1:2
                                % Get the data line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Initialize the data line flags
                                flags = [];
                                
                                % If the next line is a keyword definition, continue
                                if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                    if dataLine == 1.0
                                        keywordWarnings(7.0) = 1.0;
                                    end
                                    break
                                elseif isempty(TLINE) == 1.0
                                    if dataLine == 1.0
                                        keywordWarnings(7.0) = 1.0;
                                    end
                                    break
                                end
                                
                                %{
                                    There can be empty entries where a
                                    property is left undefined. Parse the
                                    line and identify empty definitions
                                %}
                                TLINE(ismember(TLINE,' ')) = [];
                                
                                index = 1.0;
                                while 1.0 == 1.0
                                    if index == length(TLINE)
                                        break
                                    elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                        TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                        index = index + 6.0;
                                    elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                        % This value is undefined
                                        TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                        index = index + 7.0;
                                    else
                                        index = index + 1.0;
                                    end
                                end
                                
                                if dataLine == 1.0
                                    % Get the numeric value of the data line
                                    properties = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nProperties = length(properties);
                                    if nProperties > 4.0
                                        properties = properties(1.0:4.0);
                                    elseif nProperties < 4.0
                                        properties(nProperties + 1.0:4.0) = -9e100;
                                    end
                                    
                                    % E
                                    if properties(1.0) ~= -9e100
                                        material_properties.e = properties(1.0);
                                    end
                                    
                                    % v
                                    if properties(2.0) ~= -9e100
                                        material_properties.poisson = properties(2.0);
                                    end
                                    
                                    % UTS
                                    if properties(3.0) ~= -9e100
                                        material_properties.uts = properties(3.0);
                                    end
                                    
                                    % Proof
                                    if properties(4.0) ~= -9e100
                                        material_properties.proof = properties(4.0);
                                    end
                                else
                                    % Get the numeric value of the data line
                                    flags = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nFlags = length(flags);
                                    if nFlags > 4.0
                                        flags = flags(1.0:4.0);
                                    elseif nFlags < 4.0
                                        flags(nFlags + 1.0:4.0) = -9e100;
                                    end
                                    
                                    % E
                                    if (flags(1.0) ~= 0.0) && (isempty(material_properties.e) == 0.0)
                                        material_properties.e_active = 1.0;
                                    end
                                    
                                    % v
                                    if (flags(2.0) ~= 0.0) && (isempty(material_properties.poisson) == 0.0)
                                        material_properties.poisson_active = 1.0;
                                    end
                                    
                                    % UTS
                                    if (flags(3.0) ~= 0.0) && (isempty(material_properties.uts) == 0.0)
                                        material_properties.uts_active = 1.0;
                                    end
                                    
                                    % Proof
                                    if (flags(4.0) ~= 0.0) && (isempty(material_properties.proof) == 0.0)
                                        material_properties.proof_active = 1.0;
                                    end
                                    
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                end
                            end
                            
                            if isempty(flags) == 1.0
                                if isempty(material_properties.e) == 0.0
                                    material_properties.e_active = 1.0;
                                end
                                
                                if isempty(material_properties.poisson) == 0.0
                                    material_properties.poisson_active = 1.0;
                                end
                                
                                if isempty(material_properties.uts) == 0.0
                                    material_properties.uts_active = 1.0;
                                end
                                
                                if isempty(material_properties.proof) == 0.0
                                    material_properties.proof_active = 1.0;
                                end
                            end
                        case 8.0 % *FATIGUE
                            %{
                                Fatigue constants are defined by up to
                                four numeric values per data line, and up
                                to two datalines, directly below the
                                keyword declaration
                            
                                Fatigue test data is defined by up to three
                                numeric values per data line, and as many
                                data lines that are necessary to define the
                                S-N curve
                            %}
                            
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'constants'
                                    for dataLine = 1:2
                                        % Get the data line
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        % Initialize the data line flags
                                        flags = [];
                                        
                                        % If the next line is a keyword definition, continue
                                        if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                            if dataLine == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                            end
                                            break
                                        elseif isempty(TLINE) == 1.0
                                            if dataLine == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                            end
                                            break
                                        end
                                        
                                        %{
                                            There can be empty entries
                                            where a property is left
                                            undefined. Parse the line and
                                            identify empty definitions
                                        %}
                                        TLINE(ismember(TLINE,' ')) = [];
                                        
                                        index = 1.0;
                                        while 1.0 == 1.0
                                            if index == length(TLINE)
                                                break
                                            elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                                TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                                index = index + 6.0;
                                            elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                                % This value is undefined
                                                TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                                index = index + 7.0;
                                            else
                                                index = index + 1.0;
                                            end
                                        end
                                        
                                        if dataLine == 1.0
                                            % Get the numeric value of the data line
                                            properties = str2num(TLINE); %#ok<ST2NM>
                                            
                                            % Process the data line
                                            nProperties = length(properties);
                                            if nProperties > 4.0
                                                properties = properties(1.0:4.0);
                                            elseif nProperties < 4.0
                                                properties(nProperties + 1.0:4.0) = -9e100;
                                            end
                                            
                                            % Sf'
                                            if properties(1.0) ~= -9e100
                                                material_properties.sf = properties(1.0);
                                            end
                                            
                                            % b
                                            if properties(2.0) ~= -9e100
                                                material_properties.b = properties(2.0);
                                            end
                                            
                                            % Ef'
                                            if properties(3.0) ~= -9e100
                                                material_properties.ef = properties(3.0);
                                            end
                                            
                                            % c
                                            if properties(4.0) ~= -9e100
                                                material_properties.c = properties(4.0);
                                            end
                                        else
                                            % Get the numeric value of the data line
                                            flags = str2num(TLINE); %#ok<ST2NM>
                                            
                                            % Process the data line
                                            nFlags = length(flags);
                                            if nFlags > 4.0
                                                flags = flags(1.0:4.0);
                                            elseif nFlags < 4.0
                                                flags(nFlags + 1.0:4.0) = -9e100;
                                            end
                                            
                                            % Sf'
                                            if (flags(1.0) ~= 0.0) && (isempty(material_properties.sf) == 0.0)
                                                material_properties.sf_active = 1.0;
                                            end
                                            
                                            % b
                                            if (flags(2.0) ~= 0.0) && (isempty(material_properties.b) == 0.0)
                                                material_properties.b_active = 1.0;
                                            end
                                            
                                            % Ef'
                                            if (flags(3.0) ~= 0.0) && (isempty(material_properties.ef) == 0.0)
                                                material_properties.ef_active = 1.0;
                                            end
                                            
                                            % c
                                            if (flags(4.0) ~= 0.0) && (isempty(material_properties.c) == 0.0)
                                                material_properties.c_active = 1.0;
                                            end
                                            
                                            % Get the next line in the file
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        end
                                    end
                                    
                                    if isempty(flags) == 1.0
                                        if isempty(material_properties.sf) == 0.0
                                            material_properties.sf_active = 1.0;
                                        end
                                        
                                        if isempty(material_properties.b) == 0.0
                                            material_properties.b_active = 1.0;
                                        end
                                        
                                        if isempty(material_properties.ef) == 0.0
                                            material_properties.ef_active = 1.0;
                                        end
                                        
                                        if isempty(material_properties.c) == 0.0
                                            material_properties.c_active = 1.0;
                                        end
                                    end
                                case 'testdata'
                                    % Initialize the test data buffers
                                    n_values = [];
                                    s_values = [];
                                    
                                    dataLine = 0.0;
                                    
                                    while 1.0 == 1.0
                                        % Increment the data line number
                                        dataLine = dataLine + 1.0;
                                        
                                        % Get the data line
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        % If the next line is a keyword definition, continue
                                        if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                            if dataLine == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                            end
                                            break
                                        elseif isempty(TLINE) == 1.0
                                            if dataLine == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                            end
                                            break
                                        end
                                        
                                        % Get the numeric value of the data line
                                        properties = str2num(TLINE); %#ok<ST2NM>
                                        
                                        % Get the number of S-values
                                        nSValues = length(properties) - 1.0;
                                        
                                        % Process the data line
                                        nProperties = length(properties);
                                        if nProperties < 2.0
                                            % Get the next line in the file
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            
                                            keywordWarnings(8.0) = 1.0;
                                            break
                                        elseif (dataLine > 1.0) && (nSValues ~= nSValuesP)
                                            % Get the next line in the file
                                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                            
                                            keywordWarnings(8.0) = 1.0;
                                            break
                                        end
                                        
                                        n_values(dataLine) = properties(1.0); %#ok<AGROW>
                                        s_values(dataLine, :) = properties(2.0:end); %#ok<AGROW>
                                        
                                        nSValuesP = nSValues;
                                    end
                                    
                                    % Check if there is any S-N data
                                    if isempty(n_values) == 0.0
                                        % Make sure there are at least two rows
                                        if length(n_values) < 2.0
                                            keywordWarnings(8.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Make sure the N-values are increasing
                                        if any(diff(n_values) < 0.0) == 1.0
                                            keywordWarnings(8.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Make sure the S-values are decreasing
                                        for i = 1:nSValues
                                            if any(diff(s_values(1.0, :)) > 0.0) == 1.0
                                                keywordWarnings(8.0) = 1.0;
                                                break
                                            end
                                        end
                                        
                                        material_properties.n_values = n_values;
                                        material_properties.s_values = s_values';
                                    end
                                    
                                    %{
                                        If the user specified more than one
                                        S-N curve, the next keyword must be
                                        *R RATIOS
                                    %}
                                    if nSValues > 1.0
                                        if isempty(TLINE) == 1.0
                                            while 1.0 == 1.0
                                                % Get the next line in the file
                                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                                
                                                if isempty(TLINE) == 0.0
                                                    keywordWarnings(8.0) = 1.0;
                                                    break
                                                end
                                            end
                                        end
                                        % Isolate the keyword
                                        TOKEN = strtok(TLINE, ',');
                                        TOKEN(ismember(TOKEN,' , *')) = [];
                                        
                                        if strcmpi(TOKEN, 'RRATIOS') == 0.0
                                            keywordWarnings(8.0) = 1.0;
                                            continue
                                        end
                                        
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                        
                                        % Get the numeric value of the data line
                                        r_values = str2num(TLINE); %#ok<ST2NM>
                                        
                                        if isempty(r_values) == 1.0
                                            keywordWarnings(8.0) = 1.0;
                                            continue
                                        end
                                        
                                        if (all(diff(r_values) > 0.0) == 0.0) || (any(r_values >= 1.0) == 1.0) || (length(r_values) ~= nSValues)
                                            keywordWarnings(8.0) = 1.0;
                                            continue
                                        end
                                        
                                        material_properties.r_values = r_values;
                                        
                                        % Get the next line in the file
                                        TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    else
                                        %{
                                            There is only one set of S-N
                                            data. Assign an R-value of -1
                                            to this data
                                        %}
                                        material_properties.r_values = -1.0;
                                    end
                                otherwise
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    keywordWarnings(8.0) = 1.0;
                                    continue
                            end
                        case 9.0 % *CYCLIC
                            for dataLine = 1:2
                                % Get the data line
                                TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                
                                % Initialize the data line flags
                                flags = [];
                                
                                % If the next line is a keyword definition, continue
                                if (isempty(TLINE) == 0.0) && (strcmp(TLINE(1.0), '*') == 1.0)
                                    if dataLine == 1.0
                                        keywordWarnings(9.0) = 1.0;
                                    end
                                    break
                                elseif isempty(TLINE) == 1.0
                                    if dataLine == 1.0
                                        keywordWarnings(9.0) = 1.0;
                                    end
                                    keywordWarnings(9.0) = 1.0;
                                    break
                                end
                                
                                %{
                                    There can be empty entries where a
                                    property is left undefined. Parse the
                                    line and identify empty definitions
                                %}
                                TLINE(ismember(TLINE,' ')) = [];
                                
                                index = 1.0;
                                while 1.0 == 1.0
                                    if index == length(TLINE)
                                        break
                                    elseif (index == 1.0) && (strcmp(TLINE(length(TLINE) - length(strtrim(TLINE)) + 1.0), ',') == 1.0)
                                        TLINE = ['-9e100', TLINE]; %#ok<AGROW>
                                        index = index + 6.0;
                                    elseif strcmp(TLINE(index:index + 1.0), ',,') == 1.0
                                        % This value is undefined
                                        TLINE = [TLINE(1.0: index), '-9e100', TLINE(index + 1.0:end)];
                                        index = index + 7.0;
                                    else
                                        index = index + 1.0;
                                    end
                                end
                                
                                if dataLine == 1.0
                                    % Get the numeric value of the data line
                                    properties = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nProperties = length(properties);
                                    if nProperties > 2.0
                                        properties = properties(1.0:2.0);
                                    elseif nProperties < 2.0
                                        properties(nProperties + 1.0:2.0) = -9e100;
                                    end
                                    
                                    % K'
                                    if properties(1.0) ~= -9e100
                                        material_properties.kp = properties(1.0);
                                    end
                                    
                                    % n'
                                    if properties(2.0) ~= -9e100
                                        material_properties.np = properties(2.0);
                                    end
                                else
                                    % Get the numeric value of the data line
                                    flags = str2num(TLINE); %#ok<ST2NM>
                                    
                                    % Process the data line
                                    nFlags = length(flags);
                                    if nFlags > 2.0
                                        flags = flags(1.0:2.0);
                                    elseif nFlags < 2.0
                                        flags(nFlags + 1.0:2.0) = -9e100;
                                    end
                                    
                                    % K'
                                    if (flags(1.0) ~= 0.0) && (isempty(material_properties.kp) == 0.0)
                                        material_properties.kp_active = 1.0;
                                    end
                                    
                                    % n'
                                    if (flags(2.0) ~= 0.0) && (isempty(material_properties.np) == 0.0)
                                        material_properties.np_active = 1.0;
                                    end
                                    
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                end
                            end
                            
                            if isempty(flags) == 1.0
                                if isempty(material_properties.kp) == 0.0
                                    material_properties.kp_active = 1.0;
                                end
                                
                                if isempty(material_properties.np) == 0.0
                                    material_properties.np_active = 1.0;
                                end
                            end
                        case 10.0 % *NORMAL STRESS SENSITIVITY
                            %{
                                The normal stress sensitivity is defined by
                                a single parameter after the keyword
                                declaration, followed by uptp one data line
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'user'
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    if isempty(TLINE) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get the numeric value of the data line
                                    solk = str2num(TLINE); %#ok<ST2NM>
                                    
                                    if isempty(solk) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    elseif length(solk) > 1.0
                                        solk = solk(1.0);
                                    end
                                case 'socie'
                                    solk = 0.2857;
                                case 'general'
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    if isempty(TLINE) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get the numeric value of the data line
                                    nssc = str2num(TLINE); %#ok<ST2NM>
                                    
                                    if isempty(nssc) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    elseif length(nssc) > 3.0
                                        nssc = nssc(1.0:3.0);
                                    elseif length(nssc) < 3.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get user input
                                    r = nssc(1.0);
                                    fi = nssc(2.0);
                                    t = nssc(3.0);
                                    
                                    % Calculate k based on user input
                                    syms k
                                    eqn = (fi/t) == (2.0*sqrt(1.0 + k^2))/(sqrt(((2.0*k)/(1.0 - r))^2.0 + 1.0) + ((2.0*k)/(1.0- r)));
                                    solk = eval(solve(eqn, k)); clc
                                case 'dangvan'
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    if isempty(TLINE) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get the numeric value of the data line
                                    nssc = str2num(TLINE); %#ok<ST2NM>
                                    
                                    if isempty(nssc) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    elseif length(nssc) > 2.0
                                        nssc = nssc(1.0:2.0);
                                    elseif length(nssc) < 2.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get user input
                                    fi = nssc(1.0);
                                    t = nssc(2.0);
                                    
                                    % Calculate k based on user input
                                    solk = ((3.0*t)/(fi)) - (3.0/2.0);
                                case 'sines'
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    if isempty(TLINE) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get the numeric value of the data line
                                    nssc = str2num(TLINE); %#ok<ST2NM>
                                    
                                    if isempty(nssc) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    elseif length(nssc) > 3.0
                                        nssc = nssc(1.0:3.0);
                                    elseif length(nssc) < 3.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get user input
                                    fi = nssc(1.0);
                                    t = nssc(2.0);
                                    uts = nssc(3.0);
                                    
                                    % Calculate k based on user input
                                    solk = ((3.0*t*(uts + fi))/(uts*fi)) - sqrt(6.0);
                                case 'crossland'
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    if isempty(TLINE) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get the numeric value of the data line
                                    nssc = str2num(TLINE); %#ok<ST2NM>
                                    
                                    if isempty(nssc) == 1.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    elseif length(nssc) > 2.0
                                        nssc = nssc(1.0:2.0);
                                    elseif length(nssc) < 2.0
                                        keywordWarnings(10.0) = 1.0;
                                        continue
                                    end
                                    
                                    % Get user input
                                    fi = nssc(1.0);
                                    t = nssc(2.0);
                                    
                                    % Calculate k based on user input
                                    solk = ((3.0*t)/(fi)) - sqrt(3.0);
                                otherwise
                                    % Get the next line in the file
                                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                                    
                                    keywordWarnings(10.0) = 1.0;
                                    continue
                            end
                            
                            if isempty(solk) == 1.0
                                keywordWarnings(10.0) = 1.0;
                                continue
                            elseif isreal(solk) == 0.0
                                keywordWarnings(10.0) = 1.0;
                                continue
                            elseif isnan(solk) == 1.0
                                keywordWarnings(10.0) = 1.0;
                                continue
                            elseif isinf(solk) == 1.0
                                keywordWarnings(10.0) = 1.0;
                                continue
                            elseif solk < 0.0
                                keywordWarnings(10.0) = 1.0;
                                continue
                            else
                                material_properties.nssc = solk;
                                material_properties.nssc_active = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 11.0 % *CLASS
                            %{
                                The material class is defined by a single
                                parameter after the keyword declaration
                            %}
                            % Get the parameter after the keyword
                            parameter = lower(parameter);
                            parameter(ismember(parameter,' ,')) = [];
                            
                            switch parameter
                                case 'wroughtsteel'
                                    material_properties.class = 1.0;
                                case 'ductileiron'
                                    material_properties.class = 2.0;
                                case 'malleableiron'
                                    material_properties.class = 3.0;
                                case 'wroughtiron'
                                    material_properties.class = 4.0;
                                case 'castiron'
                                    material_properties.class = 5.0;
                                case 'aluminium'
                                    material_properties.class = 6.0;
                                case 'other'
                                    material_properties.class = 7.0;
                                otherwise
                                    material_properties.class = 1.0;
                                    keywordWarnings(11.0) = 1.0;
                            end
                            
                            % Get the next line in the file
                            TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                        case 12.0 % *END MATERIAL
                            %{
                                The user has manually declared the end of
                                the material definition. Stop processing
                                further material definitions
                            %}
                            endOfMaterial = 1.0;
                    end
                else
                    % Get the next line in the file
                    TLINE = fgetl(fid); nTLINE_material = nTLINE_material + 1.0; nTLINE_total = nTLINE_total + 1.0;
                end
            end
            
            % Print the import summary
            if isappdata(0, 'materialManagerImport') == 1.0
                importMaterial.printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
                rmappdata(0, 'materialManagerImport')
            end
            
            % Close the material file
            fclose(fid);
        end
        
        %% PRINT WARNINGS TO THE COMMAND WINDOW
        function [] = printSummary(keywordWarnings, materialName, materialFile, kwStrSp, error)
            [~, n, e] = fileparts(materialFile);
            materialFile = [n, e];
            clc
            
            % Check for errors
            switch error
                case 0.0
                    fprintf('The material ''%s'' has been imported from the file ''%s''\n', materialName, materialFile)
                case 1.0
                    fprintf('WARNING: The material file ''%s'' could not be opened\n', materialFile)
                case 2.0
                    fprintf('WARNING: The material file ''%s'' contains no valid material definitions\n', materialFile)
            end
            
            % Summarise processed keywords
            if any(keywordWarnings) == 1.0
                fprintf('\nWARNING: The following keywords/parameters were not processed correctly by the material file reader:\n')
                fprintf('-------------------------------------------------------------------------------------------------\n')
                
                keywords = keywordWarnings == 1.0;
                keywords = kwStrSp(keywords);
                
                fprintf('*%s\n', keywords{:})
                fprintf('Check the material file for possible syntax errors. Material data may only be partially saved\n')
            end
        end
    end
end
classdef jobFile < handle
%JOBFILE    QFT class for job file processing.
%   This class contains methods for job file processing tasks.
%   
%   JOBFILE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% READ FLAGS FROM THE JOB FILE
        function [error, items, units, scale, useSN, designLife, algorithm, offset,...
                msCorrection, loadEqVal, loadEqUnits, elementType,...
                outputField, outputHistory, outputFigure, ktDef, ktCurve,...
                residualStress, failureMode, userUnits, jobName, jobDescription,...
                dataset, history, hfDataset, hfHistory, hfTime, hfScales]...
                ...
                = readFlags(flags)
            
            error = 0.0;
            
            %% READ FLAGS FROM THE JOB FILE
            items = flags{1};   setappdata(0, 'items', items)
            units = flags{2};   setappdata(0, 'units', units)
            scale = flags{3};   setappdata(0, 'scale', scale)
            repeats = flags{4};   setappdata(0, 'repeats', repeats)
            useSN = flags{5};   setappdata(0, 'useSN', useSN)
            designLife = flags{6};   setappdata(0, 'dLife', designLife)
            algorithm = flags{7};   setappdata(0, 'algorithm', algorithm)
            msCorrection = flags{8};   setappdata(0, 'msCorrection', msCorrection)
            loadEq = flags{9};
            if (iscell(loadEq) == 1.0) && (length(loadEq) == 2.0)
                loadEqVal = loadEq{1};  setappdata(0, 'loadEqVal', loadEqVal)
                loadEqUnits = loadEq{2};  setappdata(0, 'loadEqUnits', loadEqUnits)
            end
            elementType = flags{10};   setappdata(0, 'elementType', elementType)
            snScale = flags{11};   setappdata(0, 'snScale', snScale)
            outputField = flags{12};   setappdata(0, 'outputField', outputField)
            outputHistory = flags{13};   setappdata(0, 'outputHistory', outputHistory)
            outputFigure = flags{14};   setappdata(0, 'outputFigure', outputFigure)
            b2 = flags{15};   setappdata(0, 'b2', b2)
            b2Nf = flags{16};   setappdata(0, 'b2Nf', b2Nf)
            ktDef = flags{17};   setappdata(0, 'ktDef', ktDef)
            ktCurve = flags{18};   setappdata(0, 'ktCurve', ktCurve)
            residualStress = flags{19};   setappdata(0, 'residualStress', residualStress)
            weldClass = flags{20};   setappdata(0, 'weldClass', weldClass)
            devsBelowMean = flags{21};   setappdata(0, 'devsBelowMean', devsBelowMean)
            plateThickness = flags{22};   setappdata(0, 'plateThickness', plateThickness)
            seaWater = flags{23};   setappdata(0, 'seaWater', seaWater)
            yieldStrength = flags{24};   setappdata(0, 'bs7608Twops', yieldStrength)
            failureMode = flags{25};   setappdata(0, 'bs7608FailureMode', failureMode)
            bsUTS = flags{26};   setappdata(0, 'bs7608UTS', bsUTS)
            userUnits = flags{27};  setappdata(0, 'userUnits', userUnits)
            outputDatabase = flags{28};  setappdata(0, 'outputDatabase', outputDatabase)
            partInstance = flags{29};  setappdata(0, 'partInstance', partInstance)
            ucs = flags{30};  setappdata(0, 'ucs', ucs)
            offset = flags{31};  setappdata(0, 'offset', offset)
            stepName = flags{32};   setappdata(0, 'stepName', stepName)
            enableFOS = flags{33};  setappdata(0, 'enableFOS', enableFOS)
            analysisGroups = flags{34}; setappdata(0, 'analysisGroups', analysisGroups)
            getHotSpots = flags{35}; setappdata(0, 'getHotSpots', getHotSpots)
            snKnockDown = flags{36}; setappdata(0, 'snKnockDown', snKnockDown)
            isExplicit = flags{37}; setappdata(0, 'isExplicit', isExplicit)
            odbResultPosition = flags{38}; setappdata(0, 'odbResultPosition', odbResultPosition)
            continueFrom = flags{39}; setappdata(0, 'continueFrom', continueFrom)
            dataCheck = flags{40};  setappdata(0, 'dataCheck', dataCheck)
            notchSensitivityConstant = flags{41};  setappdata(0, 'notchSensitivityConstant', notchSensitivityConstant)
            notchRootRadius = flags{42};  setappdata(0, 'notchRootRadius', notchRootRadius)
            vGaugeLoc = flags{43};  setappdata(0, 'vGaugeLoc', vGaugeLoc)
            vGaugeOri = flags{44};  setappdata(0, 'vGaugeOri', vGaugeOri)
            jobName = flags{45};  setappdata(0, 'jobName', jobName)
            jobDescription = flags{46};  setappdata(0, 'jobDescription', jobDescription)
            material = flags{47};  setappdata(0, 'material', material)
            dataset = flags{48};  setappdata(0, 'dataset', dataset)
            history = flags{49};  setappdata(0, 'history', history)
            hfDataset = flags{50};  setappdata(0, 'hfDataset', hfDataset)
            hfHistory = flags{51};  setappdata(0, 'hfHistory', hfHistory)
            hfTime = flags{52};  setappdata(0, 'hfTime', hfTime)
            hfScales = flags{53};  setappdata(0, 'hfScales', hfScales)
            frfEnvelope = flags{54};    setappdata(0, 'frfEnvelope', frfEnvelope)
            
            %% CHECK FLAGS FOR CONSISTENCY
            if isempty(jobName) == 1.0
                fprintf('[ERROR] Job name undefined\n')
                errordlg('Please specify a name for the analysis job.', 'Quick Fatigue Tool')
                error = 1.0;
                return
            end
            
            if (isempty(designLife) == 1.0) || ((ischar(designLife) == 1.0) && (strcmpi(designLife, 'CAEL') == 0.0))
                designLife = 'CAEL';
                setappdata(0, 'dLife', designLife)
            end
            
            if isempty(useSN) == 1.0
                useSN = 0.0;
                setappdata(0, 'useSN', 0.0)
            elseif length(useSN) > 1.0
                useSN = useSN(1.0);
                setappdata(0, 'useSN', useSN)
            end
            
            if isempty(analysisGroups) == 1.0
                setappdata(0, 'analysisGroups', 'DEFAULT')
            end
            
            if (isempty(items) == 1.0) || ((ischar(items) == 1.0) && (strcmpi(items, 'ALL') == 0.0) && strcmpi(items, 'PEEK') == 0.0)
                items = 'ALL';
                setappdata(0, 'items', 'ALL')
            end
            
            if isempty(scale) == 1.0
                scale = 1.0;
                setappdata(0, 'scale', 1.0)
            end
            
            if isempty(snScale) == 1.0
                setappdata(0, 'snScale', 1.0)
            end
            
            if isempty(loadEq) == 1.0 || iscell(loadEq) == 0.0 || length(loadEq) ~= 2.0
                loadEqVal = 1.0;
                loadEqUnits = 'Repeats';
                setappdata(0, 'loadEqVal', loadEqVal)
                setappdata(0, 'loadEqUnits', loadEqUnits)
            end
            
            if isempty(units) == 1.0
                units = 3.0;
                setappdata(0, 'units', 3.0)
            end
            
            if isempty(repeats) == 1.0
                setappdata(0, 'repeats', 1.0)
            end
            
            if isempty(elementType) == 1.0
                elementType = 0.0;
                setappdata(0, 'elementType', 0.0)
            end
            
            if isempty(isExplicit) == 1.0
                setappdata(0, 'isExplicit', 0.0)
            end
            
            if isempty(odbResultPosition) == 1.0
                setappdata(0, 'odbResultPosition', 'ELEMENT NODAL')
            end
            
            if isempty(algorithm) == 1.0
                algorithm = 0.0;
                setappdata(0, 'algorithm', 0.0)
            end
            
            if isempty(msCorrection) == 1.0
                msCorrection = 0.0;
                setappdata(0, 'msCorrection', 0.0)
            end
            
            if isempty(enableFOS) == 1.0
                setappdata(0, 'enableFOS', 0.0)
            end
            
            if isempty(outputField) == 1.0
                outputField = 0.0;
                setappdata(0, 'outputField', 0.0)
            end
            
            if isempty(outputHistory) == 1.0
                outputHistory = 0.0;
                setappdata(0, 'outputHistory', 0.0)
            end
            
            if isempty(outputFigure) == 1.0
                outputFigure = 0.0;
                setappdata(0, 'outputFigure', 0.0)
            end
            
            if isempty(weldClass) == 1.0
                setappdata(0, 'weldClass', 'B')
            end
            
            if isempty(failureMode) == 1.0
                failureMode = 'NORMAL';
                setappdata(0, 'failureMode', 'NORMAL')
            end
            
            if isempty(residualStress) == 1.0
                residualStress = 0.0;
                setappdata(0, 'residualStress', residualStress)
            end
            
            if isempty(ktDef) == 1.0
                ktDef = 'default.kt';
                setappdata(0, 'ktDef', ktDef)
            end
            
            if isempty(ktCurve) == 1.0 && ischar(ktDef) == 1.0
                ktCurve = 1.0;
                setappdata(0, 'ktCurve', ktCurve)
            end
            
            if isempty(getHotSpots) == 1.0
                setappdata(0, 'getHotSpots', getHotSpots)
            end
            
            if isempty(frfEnvelope) == 1.0
                setappdata(0, 'frfEnvelope', 0.0)
            elseif isnumeric(frfEnvelope) == 1.0
                for i = 1:length(frfEnvelope)
                    if (frfEnvelope(i) ~= 1.0) && (frfEnvelope(i) ~= 2.0) && (frfEnvelope(i) ~= 3.0)
                        frfEnvelope(i) = 1.0;
                    end
                end
                setappdata(0, 'frfEnvelope', frfEnvelope)
            end
            
            %% CHECK CERTAIN FLAGS FOR STRING INPUT
            if ischar(units) == 1.0
                units = lower(units);
                switch units
                    case 'user'
                        units = 0.0;
                        setappdata(0, 'units', 0.0)
                    case 'pa'
                        units = 1.0;
                        setappdata(0, 'units', 1.0)
                    case 'kpa'
                        units = 2.0;
                        setappdata(0, 'units', 2.0)
                    case 'mpa'
                        units = 3.0;
                        setappdata(0, 'units', 3.0)
                    case 'psi'
                        units = 4.0;
                        setappdata(0, 'units', 4.0)
                    case 'ksi'
                        units = 5.0;
                        setappdata(0, 'units', 5.0)
                    case 'msi'
                        units = 6.0;
                        setappdata(0, 'units', 6.0)
                    otherwise
                        units = 10.0;
                        setappdata(0, 'units', 10.0)
                        
                end
            end
            
            if ischar(algorithm) == 1.0
                algorithm = lower(algorithm);
                switch algorithm
                    case 'default'
                        algorithm = 0.0;
                        setappdata(0, 'algorithm', 0.0)
                    case 'uniaxial'
                        algorithm = 3.0;
                        setappdata(0, 'algorithm', 3.0)
                    case 'sbbm'
                        algorithm = 4.0;
                        setappdata(0, 'algorithm', 4.0)
                    case 'normal'
                        algorithm = 5.0;
                        setappdata(0, 'algorithm', 5.0)
                    case 'findley'
                        algorithm = 6.0;
                        setappdata(0, 'algorithm', 6.0)
                    case 'invariant'
                        algorithm = 7.0;
                        setappdata(0, 'algorithm', 7.0)
                    case 'weld'
                        algorithm = 8.0;
                        setappdata(0, 'algorithm', 8.0)
                    case 'nasalife'
                        algorithm = 9.0;
                        setappdata(0, 'algorithm', 9.0)
                    otherwise
                        % No exact string match
                        algorithms = {'default', 'uniaxial', 'sbbm', 'normal', 'findley', 'invariant', 'weld', 'nasalife'};
                        algorithmN = [0.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
                        matchingAlg = find(strncmpi({algorithm}, algorithms, length(algorithm)) == 1.0);
                        
                        if isempty(matchingAlg) == 1.0
                            % The algorithm could not be found in the library
                            error = 1.0;
                            fprintf('ERROR: The value of ALGORITHM (''%s'') could not be recognized\n', algorithm)
                            fprintf('-> A list of available analysis algorithms can be found in Section 6 of the Quick Fatigue Tool User Guide\n');
                            return
                        elseif length(algorithms{matchingAlg}) ~= length(algorithm)
                            % The algorithm is a partial match
                            algorithm = algorithmN(matchingAlg);
                            setappdata(0, 'algorithm', algorithm)
                        end
                end
            end
            
            if ischar(msCorrection) == 1.0
                msCorrection = lower(msCorrection);
                switch msCorrection
                    case 'default'
                        msCorrection = 0.0;
                        setappdata(0, 'msCorrection', 0.0)
                    case 'morrow'
                        msCorrection = 1.0;
                        setappdata(0, 'msCorrection', 1.0)
                    case 'goodman'
                        msCorrection = 2.0;
                        setappdata(0, 'msCorrection', 2.0)
                    case 'soderberg'
                        msCorrection = 3.0;
                        setappdata(0, 'msCorrection', 3.0)
                    case 'walker'
                        msCorrection = 4.0;
                        setappdata(0, 'msCorrection', 4.0)
                    case 'swt'
                        msCorrection = 5.0;
                        setappdata(0, 'msCorrection', 5.0)
                    case 'gerber'
                        msCorrection = 6.0;
                        setappdata(0, 'msCorrection', 6.0)
                    case 'ratio'
                        msCorrection = 7.0;
                        setappdata(0, 'msCorrection', 7.0)
                    case 'none'
                        msCorrection = 8.0;
                        setappdata(0, 'msCorrection', 8.0)
                    otherwise
                        %{
                            No exact string match for pre-defined mean
                            stress correction. Check if the string points
                            to a user-defined .msc file
                        %}
                        if exist(msCorrection, 'file') == 0.0
                            mscs = {'default', 'morrow', 'goodman', 'soderberg', 'walker', 'swt', 'gerber', 'ratio', 'none'};
                            matchingMsc = find(strncmpi({msCorrection}, mscs, length(msCorrection)) == 1.0);
                            
                            if isempty(matchingMsc) == 1.0
                                % The mean stress correction could not be found in the library
                                error = 1.0;
                                fprintf('ERROR: The value of MS_CORRECTION (''%s'') could not be recognized\n', msCorrection)
                                fprintf('-> A list of available mean stress corrections can be found in Section 7 of the Quick Fatigue Tool User Guide\n');
                                return
                            elseif length(mscs{matchingMsc}) ~= length(msCorrection)
                                % The mean stress correction is a partial match
                                msCorrection = matchingMsc - 1.0;
                                setappdata(0, 'msCorrection', msCorrection)
                            end
                        end
                end
            end
            
            if ischar(isExplicit) == 1.0
                isExplicit = lower(isExplicit);
                switch isExplicit
                    case 'static'
                        setappdata(0, 'isExplicit', 0.0)
                    case 'dynamic'
                        setappdata(0, 'isExplicit', 1.0)
                    case 'explicit'
                        setappdata(0, 'isExplicit', 1.0)
                    otherwise
                        setappdata(0, 'isExplicit', 0.0)
                end
            end
        end
        
        %% READ AND VERIFY MATERIAL PROPERTIES
        function [material, failureMode, cleanExit] = verifyMaterial(algorithm, failureMode, useSN, cleanExit)
            % Get the number of groups for the analysis
            G = getappdata(0, 'numberOfGroups');
            
            % If the user selected BS 7608, there is no need to read material properties
            if algorithm == 8.0
                material = [];
                
                % Assign dummy place holders for each gorup material
                groupIDBuffer = getappdata(0, 'groupIDBuffer');
                for groups = 1:G
                    groupIDBuffer(groups).material = {'N/A'};
                end
                setappdata(0, 'groupIDBuffer', groupIDBuffer)
                
                setappdata(0, 'defaultAlgorithm', 4.0)
                setappdata(0, 'defaultMSC', 1.0)
                setappdata(0, 'materialBehavior', 1.0)
                
                % Failure mode
                if strcmpi(failureMode, 'normal') == 1.0
                    setappdata(0, 'bs7608FailureMode', 1.0)
                    failureMode = 1.0;
                elseif strcmpi(failureMode, 'shear') == 1.0
                    setappdata(0, 'bs7608FailureMode', 2.0)
                    failureMode = 2.0;
                elseif strcmpi(failureMode, 'combined') == 1.0
                    setappdata(0, 'bs7608FailureMode', 3.0)
                    failureMode = 3.0;
                end
                if ischar(failureMode) == 0.0
                    if (failureMode ~= 1.0) && (failureMode~= 2.0) && (failureMode ~= 3.0)
                        failureMode = 1.0;
                    end
                end
                
                % Get the S-N curve based on the weld classification
                error = algorithm_bs7608.getBS7608Properties();
                
               if error > 0.0
                   setappdata(0, 'E136', 1.0)
                   setappdata(0, 'E136_id', error)
                   cleanup(1.0)
                   cleanExit = 1.0;
                   return
               end
            else
                % Get the material(s)
                materials = getappdata(0, 'material');
                
                for groups = 1:G
                    if G > 1.0
                        % Get the current material
                        material = materials{groups};
                    else
                        material = materials;
                    end
                    
                    % Save the material number of the current group
                    setappdata(0, 'getMaterial_currentGroup', groups)
                    
                    % Save the current material name
                    setappdata(0, 'getMaterial_name', material)
                    
                    % Read material properties from MAT file
                    [error, material] = preProcess.getMaterial(material, useSN, groups);
                    
                    % Save the previously read material into the group buffer
                    group.saveMaterial(groups)
                    
                    % Check if material was read successfully
                    switch error
                        case 1.0  % No material specified
                            if isempty(material) == 1.0
                                setappdata(0, 'E001', 1.0)
                            else
                                setappdata(0, 'E002', 1.0)
                            end
                            
                            cleanExit = 1.0;
                        case 2.0  % Problem loading MAT file
                            setappdata(0, 'E003', 1.0)
                            
                            cleanExit = 1.0;
                        case 3.0  % User error in material definition
                            setappdata(0, 'E004', 1.0)
                            
                            cleanExit = 1.0;
                        case 4.0  % Insufficient material data for analysis
                            if (useSN == 0.0) && (isempty(getappdata(0, 's_values')) == 1.0)
                                setappdata(0, 'E005', 1.0)
                                
                                cleanExit = 1.0;
                            elseif (useSN == 0.0) && (isempty(getappdata(0, 's_values')) == 0.0)
                                setappdata(0, 'useSN', 1.0)
                                messenger.writeMessage(36.0)
                            elseif (useSN == 1) && (isempty(getappdata(0, 's_values')) == 1.0)
                                setappdata(0, 'E006', 1.0)
                                
                                cleanExit = 1.0;
                            end
                        case 5.0  % The yield stress exceeds the UTS
                            setappdata(0, 'E108', 1.0)
                                
                            cleanExit = 1.0;
                    end
                    
                    % Save the material to the group ID buffer
                    groupIDBuffer = getappdata(0, 'groupIDBuffer');
                    groupIDBuffer(groups).material = material;
                    setappdata(0, 'groupIDBuffer', groupIDBuffer)
                    
                    % If there was an error, clean APPDATA and terminate
                    if cleanExit == 1.0
                        cleanup(1.0)
                        return
                    end
                end
            end
        end
        
        %% DETERMINE THE ALGORITHM AND MEAN STRESS CORRECTION TO BE USED FOR THE ANALYSIS
        function [algorithm, msCorrection, nlMaterial, useSN, error] = getAlgorithmAndMSC(algorithm, msCorrection, useSN)
            % Initialite output
            nlMaterial = -1.0;
            error = 0.0;
            
            %% DETERMINE THE ANALYSIS ALGORITHM TO BE USED FOR THE ANALYSIS
            defaultAlgorithm = getappdata(0, 'defaultAlgorithm');
            
            % If the algorithm is Uniaxial Stress-Life, change defaultAlgorithm value
            if defaultAlgorithm == 11.0
                defaultAlgorithm = 3.0;
            end
            
            % If the default algorithm is requested, check if it is available
            if algorithm == 0.0
                if ((defaultAlgorithm ~= 3.0) && (defaultAlgorithm ~= 4.0) && (defaultAlgorithm ~= 5.0) && (defaultAlgorithm ~= 6.0) && (defaultAlgorithm ~= 7.0)) && (algorithm ~= 8.0)
                    % The default algorithm is not available and the user did not
                    % request BS 7608, so use Stress-based Brown-Miller
                    algorithm = 4.0;
                    
                    % Warn the user
                    switch defaultAlgorithm
                        case 1.0
                            messenger.writeMessage(154.0)
                        case 2.0
                            messenger.writeMessage(155.0)
                        case 3.0
                            messenger.writeMessage(156.0)
                        case 9.0
                            messenger.writeMessage(157.0)
                        case 10.0
                            messenger.writeMessage(158.0)
                    end
                else
                    % The default algorithm is available
                    algorithm = defaultAlgorithm;
                end
                % Check if the requested algorithm is available
            elseif (algorithm ~= 3.0) && (algorithm ~= 4.0) && (algorithm ~= 5.0) && (algorithm ~= 6.0) && (algorithm ~= 7.0) && (algorithm ~= 8.0) && (algorithm ~= 9.0)
                %{
                    The requested algorithm is not available, so check if
                    the default algorithm is. Do not use BS 7608 or
                    Uniaxial Stress-Life
                %}
                if (defaultAlgorithm == 3.0) || (defaultAlgorithm == 4.0) || (defaultAlgorithm == 5.0) || (defaultAlgorithm == 6.0) || (defaultAlgorithm == 7.0) || (defaultAlgorithm == 9.0)
                    algorithm = defaultAlgorithm;
                    messenger.writeMessage(187.0)
                else
                    %{
                        The default algorithm is not available either, so
                        use Stress-based Brown Miller
                    %}
                    algorithm = 4.0;
                    messenger.writeMessage(188.0)
                end
            end
            
            %% CHECK THE UTS DEFINITION
            G = getappdata(0, 'numberOfGroups');
            group_materialProps = getappdata(0, 'group_materialProps');
            
            utsWarn = 0.0;
            setappdata(0, 'utsWarn', 0.0)
            for groups = 1:G
                if isempty(group_materialProps(groups).uts) == 1.0
                    % At least one value of the UTS is empty
                    utsWarn = 1.0;
                    setappdata(0, 'utsWarn', 1.0)
                    break
                end
            end
            
            %% CHECK THE Sf DEFINITION
            SfWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).Sf) == 1.0
                    % At least one value of Sf is emtpy
                    SfWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE b DEFINITION
            bWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).b) == 1.0
                    % At least one value of b is emtpy
                    bWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE TWOPS DEFINITION
            if algorithm ~= 8.0
                twopsWarn = 0.0;
                setappdata(0, 'twopsWarn', 0.0)
                for groups = 1:G
                    if isempty(group_materialProps(groups).twops) == 1.0
                        % At least one value of the proof stress is emtpy
                        twopsWarn = 1.0;
                        setappdata(0, 'twopsWarn', 1.0)
                        messenger.writeMessage(199.0)
                        break
                    end
                end
            else
                setappdata(0, 'twopsWarn', 1.0)
            end
            
            %% CHECK THE S-N DATA DEFINITION
            snWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).sValues) == 1.0
                    % At least one value of S-N data is emtpy
                    snWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE EF DEFINITION
            EfWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).Ef) == 1.0
                    % At least one value of Ef is emtpy
                    EfWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE C DEFINITION
            cWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).c) == 1.0
                    % At least one value of c is emtpy
                    cWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE E DEFINITION
            EWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).E) == 1.0
                    % At least one value of E is emtpy
                    EWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE KP DEFINITION
            kpWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).kp) == 1.0
                    % At least one value of kp is emtpy
                    cWarn = 1.0;
                    break
                end
            end
            
            %% CHECK THE NP DEFINITION
            npWarn = 0.0;
            for groups = 1:G
                if isempty(group_materialProps(groups).np) == 1.0
                    % At least one value of np is emtpy
                    npWarn = 1.0;
                    break
                end
            end
            
            %% DETERMINE THE MEAN STRESS CORRECTION TO BE USED FOR THE ANALYSIS
            
            %{
                If the mean stress correction is user-defined, check that
                it exists and verify the contents
            %}
            if algorithm ~= 6.0 && algorithm ~= 8.0 && algorithm ~= 9.0
                [error, msCorrection] = mscFileUtils.checkUserData(msCorrection, 0.0, 'MSC');
            else
                msCorrection = -9999.0;
            end
            
            if error == 1.0
                return
            end
            
            %% CHECK FOR ADDITIONAL WARNINGS AND ERRORS
            
            % Check the rainflow algorithm
            rainflowAlgorithm = getappdata(0, 'rainflowAlgorithm');
            if rainflowAlgorithm ~= 1.0 && rainflowAlgorithm ~= 2.0
                setappdata(0, 'rainflowAlgorithm', 2.0)
            end
            
            % Check the rainflow mode
            rainFlowMode = getappdata(0, 'rainflowMode');
            if rainFlowMode ~= 1.0 && rainFlowMode ~= 2.0
                setappdata(0, 'rainFlowMode', 1.0)
            end
            
            % Walker MSC doesn't work well for steels
            if getappdata(0, 'materialBehavior') ~= 1.0 && msCorrection == 4.0 && (algorithm ~= 6.0 && algorithm ~= 8.0) && (getappdata(0, 'walkerGammaSource') == 1.0)
                messenger.writeMessage(28.0)
            end
            
            % Verify user-defined Walker gamma definition
            if (msCorrection == 4.0) || (algorithm == 9.0)
                error = preProcess.getWalkerGamma();
                
                if error == 1.0
                    return
                end
            end
            
            % Morrow requires a value for the fatigue strength coefficient
            if msCorrection == 1.0 && SfWarn == 1.0 && (algorithm ~= 6.0 && algorithm ~= 8.0)
                msCorrection = 2.0;
                messenger.writeMessage(49.0)
            end
            
            % SBBM is not compatible with Smith-Watson-Topper MSC
            if msCorrection == 5.0 && algorithm == 4.0
                msCorrection = 1.0;
                messenger.writeMessage(50.0)
            end
            
            % SBBM is not compatible with Walker MSC
            if msCorrection == 4.0 && algorithm == 4.0
                msCorrection = 1.0;
                messenger.writeMessage(51.0)
            end
            
            % Uniaxial Stress-Life is not compatible with Morrow MSC
            if msCorrection == 1.0 && algorithm == 3.0
                msCorrection = 2.0;
                messenger.writeMessage(54.0)
            end
            
            % Uniaxial Stress-Life is not compatible with Smith-Watson-Topper MSC
            if msCorrection == 5.0 && algorithm == 3.0
                msCorrection = 2.0;
                messenger.writeMessage(55.0)
            end
            
            % Notify user about the danger of using Stress Invariant Parameter
            if algorithm == 7.0
                messenger.writeMessage(208.0)
            end
            
            % Stress Invariant Parameter is not compatible with Morrow MSC
            if msCorrection == 1.0 && algorithm == 7.0
                msCorrection = 2.0;
                messenger.writeMessage(52.0)
            end
            
            % Stress Invariant Parameter is not compatible with Smith-Watson-Topper MSC
            if msCorrection == 5.0 && algorithm == 7.0
                msCorrection = 2.0;
                messenger.writeMessage(53.0)
            end
            
            % The Goodman MSC requires a value for the UTS
            if msCorrection == 2.0 && utsWarn == 1.0 && algorithm ~= 8.0
                msCorrection = 8.0;
                messenger.writeMessage(56.0)
            end
            
            % Get the Goodman parameters
            if msCorrection == 2.0
                error = jobFile.getGoodmanParameters(G);
                
                if error == 1.0
                    return
                end
            end
            
            % The Soderberg MSC requires a value for the yield stress
            if msCorrection == 3.0 && twopsWarn == 1.0 && algorithm ~= 8.0
                msCorrection = 8.0;
                messenger.writeMessage(57.0)
            end
            
            % The NASALIFE algorithm is only compatible with the Walker mean stress
            % correction
            if algorithm == 9.0
                msCorrection = 4.0;
            end
            
            % Findley's method is not compatible with load proportionality
            % checking
            if algorithm == 6.0 && getappdata(0, 'checkLoadProportionality') == 1.0
                messenger.writeMessage(164.0)
            end
            
            % Certain algorithms do not require a value for MS_CORRECTION
            switch algorithm
                case 6.0
                    messenger.writeMessage(176.0)
                case 9.0
                    messenger.writeMessage(177.0)
            end
            
            % If S-N data was requested, check that it exists
            if (useSN == 1.0) && (snWarn == 1.0) && (algorithm ~= 8.0) || (useSN == 0.0)
                %{
                    Either S-N data was requested but none was available,
                    or S-N data was not requested. In either case, check
                    that there are sufficient material properties to
                    continue the analysis
                %}
                
                % S-N data was requested but none was available
                if useSN == 1.0
                    useSN = 0.0;
                    setappdata(0, 'useSN', 0.0)
                    messenger.writeMessage(37.0)
                end
                
                %{
                    S-N data cannot be used, but there might not be
                    sufficient material data either. Check the material
                    properties
                %}
                
                switch algorithm
                    case 3.0
                        if SfWarn == 1.0 || bWarn == 1.0
                            error = 1.0;
                            setappdata(0, 'E005', 1.0)
                            return
                        end
                    case 4.0
                        if SfWarn == 1.0 || bWarn == 1.0 || EWarn == 1.0
                            error = 1.0;
                            setappdata(0, 'E005', 1.0)
                            return
                        end
                        if getappdata(0, 'plasticSN') == 1.0
                            if EfWarn == 1.0 || cWarn == 1.0
                                error = 1.0;
                                setappdata(0, 'E005', 1.0)
                                return
                            end
                        end
                    case 5.0
                        if SfWarn == 1.0 || bWarn == 1.0
                            error = 1.0;
                            setappdata(0, 'E005', 1.0)
                            return
                        end
                    case 6.0
                        if SfWarn == 1.0 || bWarn == 1.0
                            error = 1.0;
                            setappdata(0, 'E005', 1.0)
                            return
                        end
                    case 7.0
                        if SfWarn == 1.0 || bWarn == 1.0
                            error = 1.0;
                            setappdata(0, 'E005', 1.0)
                            return
                        end
                end
            elseif (useSN == 0.0) && (algorithm ~= 8.0)
                %{
                    S-N datapoints were not requested in the job file, so
                    warn the user that certain job file options will not be
                    considered in the analysis
                %}
                messenger.writeMessage(175.0)
            end
            
            % Check if nonlinear material data is available
            nlMaterial = getappdata(0, 'nlMaterial');
            if nlMaterial == 1.0 && (EWarn == 1.0 || kpWarn == 1.0 || npWarn == 1.0) && algorithm ~= 8.0
                nlMaterial = 0.0;
                setappdata(0, 'nlMaterial', 0.0)
                messenger.writeMessage(48.0)
            end
            
            % If the stress-based Brown-Miller algorithm is being used, check that the modulus of
            % elasticity is defined
            if algorithm == 4.0 && EWarn == 1.0
                setappdata(0, 'E007', 1.0)
                
                error = 1.0;
                return
            end
            
            % Check for issues related to R-ratio S-N curves
            setappdata(0, 'nSNDatasets', length(getappdata(0, 'r_values')))
            
            if useSN == 1.0 && algorithm ~= 8.0
                for groups = 1:G
                    nSets = group_materialProps(groups).nSNDatasets;
                    rValues = group_materialProps(groups).rValues;
                    
                    setappdata(0, 'message_25_71_72_73_groupNumber', groups)
                    
                    % Current group
                    
                    % SN data is requested for analysis
                    if nSets > 1.0
                        % There are multiple S-N datasets
                        if msCorrection == 7.0
                            % R-ratio S-N curves are requested
                        else
                            % R-ratio S-N curves are not requested
                            
                            % Note that S-N data will be interpolated to approximate an R = -1 S-N curve
                            messenger.writeMessage(25.0)
                        end
                    elseif rValues == -1.0
                        % There is one S-N dataset with an R-value of -1.0
                        if msCorrection == 7.0
                            % R-ratio S-N curves are requested
                            
                            % Warn that mean stress cannot be taken into account
                            messenger.writeMessage(71.0)
                        end
                    else
                        % There is one S-N dataset with an R-value ~= -1.0
                        if msCorrection == 7.0
                            % R-ratio S-N curves are requested
                            
                            % Warn that R-ratio will be assumed as -1.0 and results will be
                            % extrapolated
                            messenger.writeMessage(72.0)
                        else
                            % R-ratio S-N curves are not requested
                            
                            % Warn that R-ratio will be assumed as -1.0
                            messenger.writeMessage(73.0)
                        end
                    end
                end
            elseif algorithm ~= 8.0
                % S-N data is not requested for analysis
                if msCorrection == 7.0
                    % R-ratio S-N curves are requested
                    
                    % Warn that R-ratio S-N curves are not compatible when S-N data is
                    % not requested
                    switch algorithm
                        case 3.0 % Uniaxial Stress-Life
                            % Use Goodman instead
                            msCorrection = 2.0;
                            
                            messenger.writeMessage(75.0)
                        case 4.0 % Stress-based Brown-Miller
                            % Use Morrow instead
                            msCorrection = 1.0;
                            
                            messenger.writeMessage(74.0)
                        case 5.0 % Principal stress
                            % Use Morrow instead
                            msCorrection = 1.0;
                            
                            messenger.writeMessage(74.0)
                        case 7.0 % Stress Invariant Parameter
                            % Use Goodman instead
                            msCorrection = 2.0;
                            
                            messenger.writeMessage(75.0)
                        otherwise
                    end
                end
            end
            
            if algorithm == 8.0
                messenger.writeMessage(23.0)
            end
            
            if algorithm == 3.0
                messenger.writeMessage(7.0)
            end
        end
        
        %% GET USER-DEFINED FRF DATA IF APPLICABLE
        function [error] = getUserFRF(algorithm)
            error = 0.0;
            
            %{
                If the FRF is user-defined, check that it exists and
                verify the contents
            %}
            
            %{
                If multiple groups are being used, it is possible to
                specify multiple FRF definitions.

                If the frfEnvelope environment variable is specified as a
                single value, propagate this value through all groups.

                If frfEnvelope is defined as a cell, the number of
                definitions mutch match exactly the number of groups
                defined by the GROUP option.
                
                If frfEnvelope is defined in any other way, abort the
                analysis
            %}
            
            % If the algorithm is BS 7608, RETURN
            if algorithm == 8.0
                return
            end
            
            % Get the number of groups
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            %% Verify the definition of the FRF envelope
            
            % Get the FRF envelope definition
            frfEnvelope = getappdata(0, 'frfEnvelope');
            
            % Verify the envelope settings
            frfMinValue = getappdata(0, 'frfMinValue');
            frfMaxValue = getappdata(0, 'frfMaxValue');
            
            if frfMinValue >= frfMaxValue
                setappdata(0, 'frfMinValue', 0.1)
                setappdata(0, 'frfMaxValue', 10.0)
                messenger.writeMessage(235.0)
            elseif frfMinValue < 0.0 || frfMaxValue < 0.0
                setappdata(0, 'frfMinValue', 0.1)
                setappdata(0, 'frfMaxValue', 10.0)
                messenger.writeMessage(236.0)
            end
            
            if ischar(frfEnvelope) == 1.0
                frfEnvelope = cellstr(frfEnvelope);
            end
            
            numberOfEnvelopes = length(frfEnvelope);
            if isnumeric(frfEnvelope) == 1.0
                if (numberOfEnvelopes ~= 1.0) && (numberOfEnvelopes ~= G)
                    %{
                        If the envelope is defined as a numerical array
                        with length greater than one, but different to the
                        number of groups, abort the analysis
                    %}
                    setappdata(0, 'E080', 1.0)
                    setappdata(0, 'error_log_080_NfrfDefinitions', numberOfEnvelopes)
                    setappdata(0, 'error_log_080_NGroups', G)
                    error = 1.0;
                    return
                elseif numberOfEnvelopes == 1.0
                    %{
                        If the envelope is defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    frfEnvelope = linspace(frfEnvelope, frfEnvelope, G);
                    
                    if numberOfEnvelopes ~= G
                        % Notify the user that the definition will be propagated
                        messenger.writeMessage(124.0)
                    end
                end
            elseif iscell(frfEnvelope) == 1.0
                %{
                    The FRF envelope is defined as a cell. The number of
                    cell definitions must exactly match the number of
                    analysis groups
                %}
                if numberOfEnvelopes ~= G
                    %{
                        The number of FRF envelope definitions differs from
                        the number of analysis groups. Abort the analysis
                    %}
                    setappdata(0, 'E081', 1.0)
                    setappdata(0, 'error_log_081_NfrfDefinitions', numberOfEnvelopes)
                    setappdata(0, 'error_log_081_NGroups', G)
                    error = 1.0;
                    return
                end
            else
                %{
                    The FRF definition is unrecognisable. Abort the
                    analysis
                %}
                setappdata(0, 'E082', 1.0)
                error = 1.0;
                return
            end
            
            %% Get the number of character entries in frfEnvelope
            numberOfCharEnvelopes_index = zeros(1.0, G);
            if ischar(frfEnvelope) == 1.0
                numberOfCharEnvelopes = 1.0;
                numberOfCharEnvelopes_index = 1.0;
            elseif iscell(frfEnvelope) == 1.0
                numberOfCharEnvelopes = 0.0;
                
                for i = 1:length(frfEnvelope)
                    if ischar(frfEnvelope{i}) == 1.0
                        numberOfCharEnvelopes = numberOfCharEnvelopes + 1.0;
                        numberOfCharEnvelopes_index(i) = 1.0;
                    end
                end
            else
                numberOfCharEnvelopes = 0.0;
            end
            
            %% Verify the definition of the tensile mean stress normalization parameters
            
            % Get the tensile parameter definition
            frfNormParamMeanT = getappdata(0, 'frfNormParamMeanT');
            
            if ischar(frfNormParamMeanT) == 1.0
                frfNormParamMeanT = cellstr(frfNormParamMeanT);
            end
            
            numberOfParameters = length(frfNormParamMeanT);
            if isnumeric(frfNormParamMeanT) == 1.0
                if (numberOfParameters ~= 1.0) && (numberOfParameters ~= numberOfCharEnvelopes)
                    %{
                        If the parameters are defined as a numerical array
                        with length greater than one, but different to the
                        number of groups, abort the analysis
                    %}
                    setappdata(0, 'E122', 1.0)
                    setappdata(0, 'error_log_122_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_122_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                elseif numberOfParameters == 1.0
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    frfNormParamMeanT = linspace(frfNormParamMeanT, frfNormParamMeanT, numberOfCharEnvelopes);
                    
                    if numberOfParameters ~= numberOfCharEnvelopes
                        % Notify the user that the definition will be propagated
                        messenger.writeMessage(192.0)
                    end
                end
            elseif iscell(frfNormParamMeanT) == 1.0
                %{
                    The parameters are defined as a cell. The number of
                    cell definitions must exactly match the number of
                    analysis groups
                %}
                if (numberOfParameters == 1.0) && (numberOfCharEnvelopes > 1.0)
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    diff = numberOfCharEnvelopes - numberOfParameters;
                    for i = 1:diff
                        frfNormParamMeanT{i + 1.0} = 'UTS';
                    end
                    
                    messenger.writeMessage(200.0)
                elseif (numberOfParameters ~= numberOfCharEnvelopes) && (numberOfCharEnvelopes > 1.0)
                    %{
                        The number of parameter definitions differs from
                        the number of analysis groups. Abort the analysis
                    %}
                    setappdata(0, 'E120', 1.0)
                    setappdata(0, 'error_log_120_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_120_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                end
            else
                %{
                    The parameter is unrecognisable. Abort the
                    analysis
                %}
                setappdata(0, 'E121', 1.0)
                error = 1.0;
                return
            end
            
            %% Verify the definition of the compressive mean stress normalization parameters
            frfNormParamMeanC = getappdata(0, 'frfNormParamMeanC');
            
            if ischar(frfNormParamMeanC) == 1.0
                frfNormParamMeanC = cellstr(frfNormParamMeanC);
            end
            
            numberOfParameters = length(frfNormParamMeanC);
            if isnumeric(frfNormParamMeanC) == 1.0
                if (numberOfParameters ~= 1.0) && (numberOfParameters ~= numberOfCharEnvelopes)
                    %{
                        If the parameters are defined as a numerical array
                        with length greater than one, but different to the
                        number of groups, abort the analysis
                    %}
                    setappdata(0, 'E126', 1.0)
                    setappdata(0, 'error_log_126_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_126_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                elseif numberOfParameters == 1.0
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    frfNormParamMeanC = linspace(frfNormParamMeanC, frfNormParamMeanC, numberOfCharEnvelopes);
                    
                    if numberOfParameters ~= numberOfCharEnvelopes
                        % Notify the user that the definition will be propagated
                        messenger.writeMessage(201.0)
                    end
                end
            elseif iscell(frfNormParamMeanC) == 1.0
                %{
                    The parameters are defined as a cell. The number of
                    cell definitions must exactly match the number of
                    analysis groups
                %}
                if (numberOfParameters == 1.0) && (numberOfCharEnvelopes > 1.0)
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    diff = numberOfCharEnvelopes - numberOfParameters;
                    for i = 1:diff
                        frfNormParamMeanC{i + 1.0} = 'UCS';
                    end
                    
                    messenger.writeMessage(194.0)
                elseif (numberOfParameters ~= numberOfCharEnvelopes) && (numberOfCharEnvelopes > 1.0)
                    %{
                        The number of parameter definitions differs from
                        the number of analysis groups. Abort the analysis
                    %}
                    setappdata(0, 'E127', 1.0)
                    setappdata(0, 'error_log_127_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_127_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                end
            else
                %{
                    The parameter is unrecognisable. Abort the
                    analysis
                %}
                setappdata(0, 'E128', 1.0)
                error = 1.0;
                return
            end
            
            %% Verify the definition of the stress amplitude normalization parameter
            
            % Get the parameter definition
            frfNormParamAmp = getappdata(0, 'frfNormParamAmp');
            
            if ischar(frfNormParamAmp) == 1.0
                frfNormParamAmp = cellstr(frfNormParamAmp);
            end
            
            numberOfParameters = length(frfNormParamAmp);
            if isnumeric(frfNormParamAmp) == 1.0
                if (numberOfParameters ~= 1.0) && (numberOfParameters ~= numberOfCharEnvelopes)
                    %{
                        If the parameters are defined as a numerical array
                        with length greater than one, but different to the
                        number of groups, abort the analysis
                    %}
                    setappdata(0, 'E123', 1.0)
                    setappdata(0, 'error_log_123_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_123_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                elseif numberOfParameters == 1.0
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    frfNormParamAmp = linspace(frfNormParamAmp, frfNormParamAmp, numberOfCharEnvelopes);
                    
                    if numberOfParameters ~= numberOfCharEnvelopes
                        % Notify the user that the definition will be propagated
                        messenger.writeMessage(202.0)
                    end
                end
            elseif iscell(frfNormParamAmp) == 1.0
                %{
                    The parameters are defined as a cell. The number of
                    cell definitions must exactly match the number of
                    analysis groups
                %}
                if (numberOfParameters == 1.0) && (numberOfCharEnvelopes > 1.0)
                    %{
                        If the parameters are defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    diff = numberOfCharEnvelopes - numberOfParameters;
                    for i = 1:diff
                        frfNormParamAmp{i + 1.0} = 'LIMIT';
                    end
                    
                    messenger.writeMessage(195.0)
                elseif (numberOfParameters ~= numberOfCharEnvelopes) && (numberOfCharEnvelopes > 1.0)
                    %{
                        The number of parameter definitions differs from
                        the number of analysis groups. Abort the analysis
                    %}
                    setappdata(0, 'E124', 1.0)
                    setappdata(0, 'error_log_124_NfrfDefinitions', numberOfParameters)
                    setappdata(0, 'error_log_124_NGroups', numberOfCharEnvelopes)
                    error = 1.0;
                    return
                end
            else
                %{
                    The parameter is unrecognisable. Abort the
                    analysis
                %}
                setappdata(0, 'E125', 1.0)
                error = 1.0;
                return
            end
            
            %%
            %{
                Pad out the parameter variable to account for non-user
                envelopes
            %}
            if iscell(frfNormParamMeanT) == 0.0 && isnumeric(frfNormParamMeanT) == 1.0
                frfNormParamMeanT = num2cell(frfNormParamMeanT);
            end
            if iscell(frfNormParamMeanC) == 0.0 && isnumeric(frfNormParamMeanC) == 1.0
                frfNormParamMeanC = num2cell(frfNormParamMeanC);
            end
            if iscell(frfNormParamAmp) == 0.0 && isnumeric(frfNormParamAmp) == 1.0
                frfNormParamAmp = num2cell(frfNormParamAmp);
            end
            
            if iscell(frfEnvelope) == 1.0
                index = 1.0;
                frfNormParamMeanT_temp = cell(1.0, length(frfNormParamMeanT));
                frfNormParamMeanC_temp = cell(1.0, length(frfNormParamMeanC));
                frfNormParamAmp_temp = cell(1.0, length(frfNormParamAmp));
                
                for i = 1:length(frfEnvelope)
                    if ischar(frfEnvelope{i}) == 0.0
                        frfNormParamMeanT_temp{i} = [];
                        frfNormParamMeanC_temp{i} = [];
                        frfNormParamAmp_temp{i} = [];
                    else
                        frfNormParamMeanT_temp{i} = frfNormParamMeanT{index};
                        frfNormParamMeanC_temp{i} = frfNormParamMeanC{index};
                        frfNormParamAmp_temp{i} = frfNormParamAmp{index};
                        
                        index = index + 1.0;
                    end
                end
                frfNormParamMeanT = frfNormParamMeanT_temp;
                frfNormParamMeanC = frfNormParamMeanC_temp;
                frfNormParamAmp = frfNormParamAmp_temp;
            end
            
            %% Check the string inputs
            for i = 1:length(frfNormParamMeanT)
                if ischar(frfNormParamMeanT{i}) == 1.0
                    if (isempty(frfNormParamMeanT{i}) == 0.0) && (strcmpi(frfNormParamMeanT{i}, 'UCS') == 0.0) && (strcmpi(frfNormParamMeanT{i}, 'UTS') == 0.0) && (strcmpi(frfNormParamMeanT{i}, 'PROOF') == 0.0)
                        setappdata(0, 'message_243_paramOld', frfNormParamMeanT{i})
                        setappdata(0, 'message_243_paramNew', 'UTS')
                        frfNormParamMeanT{i} = 'UTS';
                        messenger.writeMessage(243.0)
                    end
                end
                
                if ischar(frfNormParamMeanC{i}) == 1.0
                    if (isempty(frfNormParamMeanC{i}) == 0.0) && (strcmpi(frfNormParamMeanC{i}, 'UCS') == 0.0) && (strcmpi(frfNormParamMeanC{i}, 'UTS') == 0.0) && (strcmpi(frfNormParamMeanC{i}, 'PROOF') == 0.0)
                        setappdata(0, 'message_243_paramOld', frfNormParamMeanC{i})
                        setappdata(0, 'message_243_paramNew', 'UTS')
                        frfNormParamMeanT{i} = 'UTS';
                        messenger.writeMessage(243.0)
                    end
                end
                
                if ischar(frfNormParamAmp{i}) == 1.0
                    if (isempty(frfNormParamAmp{i}) == 0.0) && (strcmpi(frfNormParamAmp{i}, 'LIMIT') == 0.0)
                        setappdata(0, 'message_243_paramOld', frfNormParamAmp{i})
                        setappdata(0, 'message_243_paramNew', 'LIMIT')
                        frfNormParamAmp{i} = 'LIMIT';
                        messenger.writeMessage(243.0)
                    end
                end
            end
            
            %% Get the FRF data
            if getappdata(0, 'utsWarn') == 1.0
                % Save the FRF settings for this group
                setappdata(0, 'frfNormParamMeanT', frfNormParamMeanT)
                setappdata(0, 'frfNormParamMeanC', frfNormParamMeanC)
                setappdata(0, 'frfNormParamAmp', frfNormParamAmp)
                
                if iscell(frfEnvelope) == 1.0
                    for groups = 1:G
                        if ischar(frfEnvelope{groups}) == 1.0
                            setappdata(0, 'frfEnvelope', -1.0);
                        else
                            setappdata(0, 'frfEnvelope', frfEnvelope{groups});
                        end
                        group.saveMaterial(groups)
                    end
                end
            else
                userFRFIndex = 0.0;
                
                for groups = 1:G
                    % Get the current group material properties
                    [~, ~] = group.switchProperties(groups, groupIDBuffer(groups));
                    
                    % Get the current FRF envelope definition
                    if iscell(frfEnvelope) == 1.0
                        frfEnvelope_i = frfEnvelope{groups};
                    else
                        frfEnvelope_i = frfEnvelope(groups);
                    end
                    
                    %{
                        Check the integrity of the user FRF data and save
                        the current envelope definition
                    %}
                    [error, ~] = mscFileUtils.checkUserData(frfEnvelope_i, groups, 'FRF');
                    
                    %% Set FRF normalization parameters
                    if numberOfCharEnvelopes_index(groups) == 1.0
                        userFRFIndex = userFRFIndex + 1.0;
                        
                        if iscell(frfNormParamMeanT) == 1.0
                            if ischar(frfNormParamMeanT{userFRFIndex}) == 1.0 && strcmpi(frfNormParamMeanT{userFRFIndex}, 'PROOF') == 0.0 && strcmpi(frfNormParamMeanT{userFRFIndex}, 'UTS') == 0.0 && strcmpi(frfNormParamMeanT{userFRFIndex}, 'UCS') == 0.0
                                setappdata(0, 'frfNormParamMeanT', 'UTS')
                                
                                setappdata(0, 'message_193_group', groups)
                                messenger.writeMessage(193.0)
                            end
                        end
                        
                        if iscell(frfNormParamMeanC) == 1.0
                            if ischar(frfNormParamMeanC{userFRFIndex}) == 1.0 && strcmpi(frfNormParamMeanC{userFRFIndex}, 'PROOF') == 0.0 && strcmpi(frfNormParamMeanC{userFRFIndex}, 'UTS') == 0.0 && strcmpi(frfNormParamMeanC{userFRFIndex}, 'UCS') == 0.0
                                setappdata(0, 'frfNormParamMeanC', 'UCS')
                                
                                setappdata(0, 'message_196_group', groups)
                                messenger.writeMessage(196.0)
                            end
                        end
                        
                        if iscell(frfNormParamAmp) == 1.0
                            if ischar(frfNormParamAmp{userFRFIndex}) == 1.0 && strcmpi(frfNormParamAmp{userFRFIndex}, 'LIMIT') == 0.0
                                setappdata(0, 'frfNormParamAmp', 'LIMIT')
                                
                                setappdata(0, 'message_198_group', groups)
                                messenger.writeMessage(198.0)
                            end
                        end
                    else
                        setappdata(0, 'frfNormParamMeanT', [])
                        setappdata(0, 'frfNormParamMeanC', [])
                        setappdata(0, 'frfNormParamAmp', [])
                    end
                    
                    % Save the FRF settings for this group
                    setappdata(0, 'frfNormParamMeanT', frfNormParamMeanT)
                    setappdata(0, 'frfNormParamMeanC', frfNormParamMeanC)
                    setappdata(0, 'frfNormParamAmp', frfNormParamAmp)
                    
                    group.saveMaterial(groups)
                end
            end
        end
        
        %% CHECK FOS BANDS
        function [error] = checkFosBands()
            error = 0.0;
            
            % Check band definitions
            fosMaxValue = getappdata(0, 'fosMaxValue');
            fosMaxFine = getappdata(0, 'fosMaxFine');
            fosMinFine = getappdata(0, 'fosMinFine');
            fosMinValue = getappdata(0, 'fosMinValue');
            
            if fosMaxFine > fosMaxValue
                error = 1.0;
            end
            
            if fosMinFine > fosMaxFine
                error = 1.0;
            end
            
            if fosMinValue > fosMinFine
                error = 1.0;
            end
            
            values = [fosMaxValue, fosMaxFine, fosMinFine, fosMinValue];
            if range(values) == 0.0
                error = 1.0;
            end
            
            % Check increment defintions
            fosCoarseIncrement = getappdata(0, 'fosCoarseIncrement');
            fosFineIncrement = getappdata(0, 'fosFineIncrement');
            
            if fosCoarseIncrement < fosFineIncrement
                error = 2.0;
            end
        end
        
        %% SCALE AND COMBINE THE LOADING
        function [scale, offset, repeats, units, N, signalLength, Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, gateHistories, gateTensors, tensorGate, error] =...
                getLoading(units, scale, algorithm, msCorrection,...
                nlMaterial, userUnits, hfDataset, hfHistory, hfTime,...
                hfScales, items, dataset, history, elementType, offset)
            
            N = [];
            signalLength = [];
            
            % Define system of units
            switch units
                case 0.0
                    if isempty(userUnits) == 1.0
                        conversionFactor = 1.0;
                        units = 'MPa';
                    elseif isnan(userUnits) == 1.0
                        conversionFactor = 1.0;
                        units = 'MPa';
                    elseif ischar(userUnits) == 1.0
                        conversionFactor = 1.0;
                        units = 'MPa';
                    else
                        conversionFactor = 1.0/(userUnits*1E6);
                        units = 'User-defined';
                    end
                case 1.0
                    conversionFactor = 1.0/1E6;
                    units = 'Pa';
                case 2.0
                    conversionFactor = 1.0/1E3;
                    units = 'kPa';
                case 3.0
                    conversionFactor = 1.0;
                    units = 'MPa';
                case 4.0
                    conversionFactor = 1.0/145.0377;
                    units = 'psi';
                case 5.0
                    conversionFactor = 1.0/0.1450377;
                    units = 'ksi';
                case 6.0
                    conversionFactor = 1.0/0.0001450377;
                    units = 'Msi';
                otherwise
                    conversionFactor = 1.0;
                    units = 'Unknown (assumed MPa)';
            end
            
            %{
                Sii(a, b):
                
                ii = component e.g. xx, yy, zz, xy, yz, xz
                a = increment
                b = position in load history
            %}
            
            % Verify the histroy gate settings
            gateHistories = getappdata(0, 'gateHistories');
            historyGate = getappdata(0, 'historyGate');
            
            if historyGate == 0.0
                historyGate = 1e-6;
            elseif isempty(historyGate)
                historyGate = 1e-6;
            end
            
            % Verify the tensor gate settings
            gateTensors = getappdata(0, 'gateTensors');
            tensorGate = getappdata(0, 'tensorGate');
            
            if tensorGate == 0.0
                tensorGate = 1e-6;
            elseif isempty(tensorGate)
                tensorGate = 1e-6;
            end
            
            % Inform the user that multiple gating criteria may adversely affect the results
            if (gateTensors > 0.0) && (gateHistories > 0.0)
                messenger.writeMessage(183.0)
            end
            
            % Verify the scale factors
            if isnumeric(scale) == 0.0
                scale = 1.0;
            elseif isempty(scale) == 1.0
                scale = 1.0;
            elseif any(isnan(scale)) == 1.0 || any(isinf(scale)) == 1.0 || any(isreal(scale)) == 0.0
                scale = 1.0;
            end
            
            % Verify the offest values
            if isnumeric(offset) == 0.0
                offset = 0.0;
            elseif any(isnan(offset)) == 1.0 || any(isinf(offset)) == 1.0 || any(isreal(offset)) == 0.0
                offset = 0.0;
            end
            
            % Verify the repeats
            repeats = getappdata(0, 'repeats');
            if length(repeats) > 1.0
                repeats = repeats(1.0);
            end
            if repeats <= 0.0
                repeats = 1.0;
            end
            setappdata(0, 'repeats', repeats)
            
            % Initialise warnings for scale and combine
            setappdata(0, 'incorrectItemList', 0.0)
            
            % If using Uniaxial Stress-Life, no scale & combine is necessary
            if algorithm == 3.0
                [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, error, oldSignal] = preProcess.uniaxialRead(history, gateHistories, historyGate, scale, offset);
            else
                [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, error] = preProcess.scalecombine(dataset, history, items, gateHistories, historyGate, scale, offset, elementType);
            end
            
            if error == true
                return
            end
            
            % If high frequency data is provided, superimpose it onto the low frequency
            % block
            if (isempty(hfDataset) == 0.0) || (algorithm == 3.0 && isempty(hfHistory) == 0.0)
                [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = highFrequency.main(Sxx, Syy, Szz, Txy, Tyz, Txz, hfDataset, hfHistory, hfTime, algorithm, items, hfScales);
                
                %{
                    If high frequency datasets were used with the Uniaxial
                    Stress-Life algorithm, update the OLDSIGNAL variable to
                    reflect the newly superinposed data
                %}
                if algorithm == 3.0
                    oldSignal = Sxx;
                end
            end
            
            if error == true
                return
            end            
            
            % Inform the user of the FEA data type
            messenger.writeMessage(31.0)
            
            % Warn the user if the loading contained any complex values
            if any(isreal(Sxx) == 0.0) == 1.0 || any(isreal(Syy) == 0.0) == 1.0 ||...
                    any(isreal(Szz) == 0.0) == 1.0 || any(isreal(Txy) == 0.0) == 1.0 ||...
                    any(isreal(Tyz) == 0.0) == 1.0 || any(isreal(Txz) == 0.0) == 1.0
                messenger.writeMessage(60.0)
            end
            
            % Remove complex components from the signal
            Sxx = real(Sxx);
            Syy = real(Syy);
            Szz = real(Szz);
            Txy = real(Txy);
            Tyz = real(Tyz);
            Txz = real(Txz);
            
            % Get the normal and shear stress range from the stress data
            preProcess.getRanges(Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID)
            
            %% APPLY CONVERSION FACTOR TO LOADING IF APPLICABLE
            
            % Apply unit conversion factor to FEA definition
            Sxx = Sxx*conversionFactor;    Syy = Syy*conversionFactor;    Szz = Szz*conversionFactor;
            Txy = Txy*conversionFactor;    Tyz = Tyz*conversionFactor;    Txz = Txz*conversionFactor;
            
            % Apply unit conversion factor to the old signal for Uniaxial Stress-Life
            if algorithm == 3.0
                setappdata(0, 'SIGOriginalSignal', oldSignal*conversionFactor)
            end
            
            %% COLLAPSE LOAD HISTORY (IF APPLICABLE)
            if (length(Sxx) > 3.0) && (gateHistories == 1.0)
                [Sxx, Syy, Szz, Txy, Txz, Tyz] = constantAmplitude(Sxx, Syy, Szz, Txy, Txz, Tyz, repeats, historyGate);
            end
            
            %% Save stress tensors in the appdata
            setappdata(0, 'Sxx', Sxx)
            setappdata(0, 'Syy', Syy)
            setappdata(0, 'Szz', Szz)
            setappdata(0, 'Txy', Txy)
            setappdata(0, 'Tyz', Tyz)
            setappdata(0, 'Txz', Txz)
            
            % Number of items to analyse
            [N, signalLength] = size(Sxx);
            setappdata(0, 'message168_N', N)
            setappdata(0, 'signalLength', signalLength)
            
            %% GET THE FATIGE LIMIT STRESS
            % Only if BS 7608 is not being used for analysis
            if algorithm ~= 8.0
                plasticSN = getappdata(0, 'plasticSN');
                error = preProcess.getFatigueLimit(plasticSN, algorithm, msCorrection, nlMaterial);
                
                if error == 1.0
                    return
                end
            end
        end
        
        %% IF AUTOMATIC EXPORT IS BEING USED, CHECK IN ADVANCE THAT THE SET-UP IS VALID
        function [error, outputField] = checkAutoExport(outputField)
            %{
                This check should only be performed if the user has set the
                following:
                
                1. Has set autoExport_ODB = 1.0 in the environment file
                2: Has specified an ODB path in the job file
            %}
            
            error = 0.0;
            
            outputDatabase = getappdata(0, 'outputDatabase');
            partInstance = getappdata(0, 'partInstance');
            autoExportODB = getappdata(0, 'autoExport_ODB');
            feaProcedure = getappdata(0, 'isExplicit');
            jobName = getappdata(0, 'jobName');
            stepName = getappdata(0, 'stepName');
            odbResultPosition = getappdata(0, 'odbResultPosition');
            algorithm = getappdata(0, 'algorithm');
            
            if algorithm == 3.0
                setappdata(0, 'autoExport_uniaxial', 1.0)
            end
            
            if autoExportODB == 1.0 && isempty(outputDatabase) == 0.0
                % The ODB interface does not support Uniaxial Stress-Life
                if algorithm == 3.0
                    msg = sprintf('Uniaxial Stress-Life is not supported by the ODB interface.\n\nResults will not be exported to the output database. OK to continue with job submission?');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    if strcmpi('No', response) == 1.0
                        fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                        error = 1.0;
                    end
                    return
                end
                
                % The job name contains illegal characters
                if autoExportODB == 1.0 && any(isspace(jobName)) == 1.0
                    message1 = sprintf('Job names which contain spaces are not accepted by the ODB interface. Remove spaces from the job name and re-submit the job.');
                    errordlg(message1, 'Quick Fatigue Tool')
                    error = 1.0;
                    fprintf('\n[ERROR] Invalid job name\n')
                    return
                end
                
                [~, ~, EXT] = fileparts(outputDatabase);
                switch exist(outputDatabase, 'file')
                    case 0.0
                        if strcmpi(EXT, '.odb') == 1.0
                            msg = sprintf('The output database could not be found:\n\n%s\n\nResults will not be exported to the output database. OK to continue with job submission?', outputDatabase);
                        else
                            msg = sprintf('The output database is not a valid file:\n\n%s\n\nOUTPUT_DATABASE must be the absolute (full) path to an Abaqus output database (.odb) file.\n\nResults will not be exported to the output database. OK to continue with job submission?', outputDatabase);
                        end
                        response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    case 7.0
                        msg = sprintf('The output database appears to be a directory:\n\n%s\n\nOUTPUT_DATABASE must be the absolute (full) path to the model output database file.\n\nResults will not be exported to the output database. OK to continue with job submission?', outputDatabase);
                        response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    otherwise
                        if exist(outputDatabase, 'file') ~= 2.0 || strcmpi(EXT, '.odb') == 0.0
                            msg = sprintf('The output database is not a valid file:\n\n%s\n\nOUTPUT_DATABASE must be the absolute (full) path to an Abaqus output database (.odb) file.\n\nResults will not be exported to the output database. OK to continue with job submission?', outputDatabase);
                            response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                        end
                end
                
                if exist('response', 'var') == 1.0
                    if strcmpi('No', response)
                        fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                        error = 1.0;
                        return
                    else
                        setappdata(0, 'autoExport_ODB', 0.0)
                        return
                    end
                end
                
                % Check the value of FEA_PROCEDURE
                if isempty(feaProcedure) == 1.0
                    msg = sprintf('No FEA procedure has been defined. The procedure will be assumed as *STATIC.\n\nOK to continue with job submission?');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    if strcmpi('Yes', response) == 1.0
                        setappdata(0, 'isExplicit', 'STATIC')
                    end
                elseif (feaProcedure ~= 0.0) && (feaProcedure ~= 1.0)
                    msg = sprintf('An invalid FEA procedure has been selected. Use either ''STATIC'' or ''DYNAMIC'' to define FEA_PROCEDURE. The procedure will be assumed as *STATIC.\n\nOK to continue with job submission?');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    if strcmpi('Yes', response) == 1.0
                        setappdata(0, 'isExplicit', 'STATIC')
                    end
                else
                    response = 'YES';
                end
                
                if strcmpi('No', response) == 1.0
                    fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                    error = 1.0;
                    return
                end
                
                % Check if a part instance was specified
                if (autoExportODB == 1.0) && (isempty(partInstance) == 1.0)
                    msg = sprintf('An output database has been specified without a part instance name.\n\nResults will not be exported to the output database. OK to continue with job submission?');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                    
                    if strcmpi('No', response)
                        fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                        error = 1.0;
                        return
                    end
                % Check that field data is requested
                elseif getappdata(0, 'outputField') == 0.0
                    msg = sprintf('An output database has been specified but field output was not requested in the job file.');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Enable field output', 'Continue without export', 'Cancel', 'Enable field output');
                    
                    if strcmpi('Cancel', response)
                        fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                        error = 1.0;
                        return
                    elseif strcmpi('Enable field output', response)
                        outputField = 1.0;
                        setappdata(0, 'outputField', 1.0)
                    end
                end
                
                %{
                    If the specifed output database exists in the same
                    directory as the results output datase, warn the user
                    that the file will be removed and export will not occur
                %}
                if isempty(outputDatabase) == 0.0
                    [directoryA, ~, ~] = fileparts(outputDatabase);
                    directoryB = [pwd, sprintf('\\Project\\output\\%s\\Data Files', jobName)];
                    
                    if strcmp(directoryA, directoryB) == 1.0
                        msg = sprintf('The model output database is inside the current job''s output directory, therefore it will be overwritten before results export.\n\nResults will not be exported to the output database. OK to continue with job submission?');
                        response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                        
                        if strcmpi('No', response)
                            fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                            error = 1.0;
                            return
                        end
                    end
                    
                    %{
                        In addition, verify that a step name has been
                        defined in the event that results are being written
                        to a previous QFT step
                    %}
                    if getappdata(0, 'autoExport_stepType') == 2.0
                        if isempty(stepName) == 1.0
                            msg = sprintf('The user specified to export results to an existing QFT step, but no step was defined.');
                            response = questdlg(msg, 'Quick Fatigue Tool', 'Create a new step', 'Continue without export', 'Cancel', 'Create a new step');
                        
                            if strcmpi('Cancel', response)
                                fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                                error = 1.0;
                                return
                            elseif strcmpi('Continue without export', response)
                                setappdata(0, 'autoExport_ODB', 0.0)
                            elseif strcmpi('Create a new step', response)
                                setappdata(0, 'autoExport_stepType', 1.0)
                                setappdata(0, 'appendStepCharacter', 1.0)
                                setappdata(0, 'writeMessage_185', 1.0)
                            end
                        else
                            setappdata(0, 'writeMessage_186', 1.0)
                        end
                    elseif isempty(stepName) == 1.0
                        setappdata(0, 'writeMessage_185', 1.0)
                    end
                end
                
                % Check the definition of RESULT_POSITION
                flags = [strcmpi(odbResultPosition, 'ELEMENT NODAL'),...
                    strcmpi(odbResultPosition, 'UNIQUE NODAL'),...
                    strcmpi(odbResultPosition, 'INTEGRATION POINT'),...
                    strcmpi(odbResultPosition, 'CENTROID')];
                
                if any(flags) == 0.0
                    % An invalid result position was specified
                    msg = sprintf('The specified results position is invalid. The following inputs are accepted:\n\n''ELEMENT NODAL''\n''UNIQUE NODAL''\n''INTEGRATION POINT''\n''CENTROID''');
                    response = questdlg(msg, 'Quick Fatigue Tool', 'Continue without export', 'Cancel', 'Continue without export');
                    if strcmpi('Cancel', response)
                        fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                        error = 1.0;
                        return
                    elseif strcmpi('Continue without export', response)
                        setappdata(0, 'autoExport_ODB', 0.0)
                    end
                end
            elseif (autoExportODB == 1.0) && ((isempty(partInstance) == 0.0 && strcmpi(partInstance, 'PART-1-1') == 0.0) || isempty(stepName) == 0.0)
                % A part instance or step name was specified without an ODB file
                msg = sprintf('A non-default part instance and/or results step name has been specified without an output database.\n\nResults will not be exported to the output database. OK to continue with job submission?');
                response = questdlg(msg, 'Quick Fatigue Tool', 'Yes', 'No', 'Yes');
                
                if strcmpi('No', response)
                    fprintf('\n[NOTICE] Job %s was aborted by the user\n', jobName);
                    error = 1.0;
                    return
                end
            end
        end
        
        %% IF THE FOS IS REQUESTED, CHECK THAT FIELD OUTPUT IS ALSO REQUESTED
        function [outputField, error] = checkFOS(outputField)
            error = 0.0;
            
            if (getappdata(0, 'enableFOS') == 1.0) && (outputField == 0.0)
                msg = sprintf('The Factor of Strength algorithm is enabled, but field output was not requested in the job file.');
                response = questdlg(msg, 'Quick Fatigue Tool', 'Enable field output', 'Continue without FOS calcualtion', 'Cancel', 'Enable field output');
                
                if strcmpi('Cancel', response)
                    fprintf('\n[NOTICE] Job %s was aborted by the user\n', getappdata(0, 'jobName'));
                    error = 1.0;
                    return
                elseif strcmpi('Enable field output', response)
                    setappdata(0, 'outputField', 1.0)
                    outputField = 1.0;
                end
            end
        end
        
        %% Get the Goodman parameters for each group
        function [error] = getGoodmanParameters(G)
            error = 0.0;
            
            %% Verify the definition of the Goodman envelope
            
            % Get the Goodman definition
            modifiedGoodman = getappdata(0, 'modifiedGoodman');
            numberOfDefinitions = length(modifiedGoodman);
            
            if isnumeric(modifiedGoodman) == 1.0
                if (numberOfDefinitions ~= 1.0) && (numberOfDefinitions ~= G)
                    %{
                        If the envelope is defined as a numerical array
                        with length greater than one, but different to the
                        number of groups, abort the analysis
                    %}
                    setappdata(0, 'E109', 1.0)
                    setappdata(0, 'error_log_109_NGoodmanDefinitions', numberOfDefinitions)
                    setappdata(0, 'error_log_109_NGroups', G)
                    error = 1.0;
                    return
                elseif numberOfDefinitions == 1.0
                    %{
                        If the envelope is defined as a single value,
                        modify the definition if necessary so that the
                        number of envelope values match the number of
                        groups for analysis
                    %}
                    modifiedGoodman = linspace(modifiedGoodman, modifiedGoodman, G);
                    
                    if numberOfDefinitions ~= G
                        % Notify the user that the definition will be propagated
                        messenger.writeMessage(172.0)
                    end
                end
            elseif iscell(modifiedGoodman) == 1.0
                %{
                    The Goodman envelopes is defined as a cell. Convert the
                    cell into a numeric array and warn the user that this
                    is not the recommended practice
                %}
                messenger.writeMessage(170.0)
                modifiedGoodman = cell2mat(modifiedGoodman);
                if numberOfDefinitions ~= G
                    %{
                        The number of Goodman envelopes differs from
                        the number of analysis groups. Abort the analysis
                    %}
                    setappdata(0, 'E109', 1.0)
                    setappdata(0, 'error_log_109_NGoodmanDefinitions', numberOfDefinitions)
                    setappdata(0, 'error_log_109_NGroups', G)
                    error = 1.0;
                    return
                end
            else
                %{
                    The Goodman definition is unrecognisable. Abort the
                    analysis
                %}
                setappdata(0, 'E110', 1.0)
                error = 1.0;
                return
            end
            
            %% Verify the values of the Goodman envelope
            for i = 1:length(modifiedGoodman)
                if (modifiedGoodman(i) ~= 0.0) && (modifiedGoodman(i) ~= 1.0)
                    modifiedGoodman(i) = 0.0;
                end
            end
            
            %% Commit the Goodman envelope definitions to the buffer
            for groups = 1:G
                group_materialProps = getappdata(0, 'group_materialProps');
                group_materialProps(groups).modifiedGoodman = modifiedGoodman(groups);
                setappdata(0, 'group_materialProps', group_materialProps)
            end
            
            %% Verify the definition of the Goodman limit stress
            % Get the stress definition
            goodmanMeanStressLimit = getappdata(0, 'goodmanMeanStressLimit');
            
            %{
                Get the number of Goodman definitions where a limit stress
                definition is applicable
            %}
            numberOfDefinitions = length(find(modifiedGoodman == 0.0));
            
            % Convert the limit stress definitino to a cell
            if ischar(goodmanMeanStressLimit) == 1.0
                goodmanMeanStressLimit = cellstr(goodmanMeanStressLimit);
            end
            if isnumeric(goodmanMeanStressLimit) == 1.0
                goodmanMeanStressLimit = num2cell(goodmanMeanStressLimit);
            end
            
            numberOfLimits = length(goodmanMeanStressLimit);
            
            %{ 
                The number of limit stress definitions should match the
                number of Goodman envelope definitions. It can be numeric,
                cell or character
            %}
            
            if (numberOfLimits ~= 1.0) && (numberOfLimits ~= numberOfDefinitions)
                %{
                    The number of Goodman limit stresses differs from the
                    number of analysis groups. Abort the analysis
                %}
                setappdata(0, 'E111', 1.0)
                setappdata(0, 'error_log_111_NGoodmanLimits', numberOfLimits)
                setappdata(0, 'error_log_111_NGroups', numberOfDefinitions)
                error = 1.0;
                return
            elseif numberOfLimits == 1.0
                
                if (numberOfLimits ~= numberOfDefinitions) && (numberOfDefinitions > 1.0)
                    % Notify the user that the definition will be propagated
                    messenger.writeMessage(173.0)
                end
            end
            
            % Re-organise goodmanMeanStressLimit to it has length G
            if length(goodmanMeanStressLimit) ~= G
                goodmanMeanStressLimit2 = cell(1.0, G);
                index = 1.0;
                for i = 1:G
                    if (modifiedGoodman(i) == 1.0) || (index > length(goodmanMeanStressLimit))
                        %{
                            This is a dummy value, just so that a value can
                            be submitted for each analysis group
                        %}
                        goodmanMeanStressLimit2{i} = 'UTS';
                    else
                        goodmanMeanStressLimit2{i} = goodmanMeanStressLimit{index};
                        index = index + 1.0;
                    end
                end
                goodmanMeanStressLimit = goodmanMeanStressLimit2;
            end
            
            %% Verify the values of the Goodman limit stress
            for i = 1:length(goodmanMeanStressLimit)
                if (ischar(goodmanMeanStressLimit{i}) == 1.0) &&...
                        (strcmpi(goodmanMeanStressLimit{i}, 'uts') == 0.0) &&...
                        (strcmpi(goodmanMeanStressLimit{i}, 'proof') == 0.0) &&...
                        (strcmpi(goodmanMeanStressLimit{i}, 's-n') == 0.0)
                    goodmanMeanStressLimit{i} = 'UTS';
                    setappdata(0, 'limitStressGroup', i)
                    messenger.writeMessage(174.0)
                end
            end
            
            %% Commit the Goodman limit stress definitions to the buffer
            for groups = 1:G
                group_materialProps = getappdata(0, 'group_materialProps');
                group_materialProps(groups).goodmanLimitStress = goodmanMeanStressLimit(groups);
                setappdata(0, 'group_materialProps', group_materialProps)
            end
        end
    end
end
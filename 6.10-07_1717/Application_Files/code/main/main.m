function [] = main(flags)
%MAIN Quick Fatigue Tool 6
%   Entry function for analysis job files created in MATLAB.
%
%   MAIN is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   For a detailed reference to the use of the code and its features,
%   please refer to the Quick Fatigue Tool User Guide.
%
%   Author contact: louisvallance@hotmail.co.uk
%
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 24-Apr-2017 18:27:33 GMT

% Begin main code - DO NOT EDIT
format long;    clc;    warning('off', 'all')

%% READ SETTINGS FROM THE ENVIRONMENT FILE
error = preProcess.readEnvironment(flags{45.0});

if error == 1.0;
    return
end

%% READ FLAGS AND DATA FROM THE JOB FILE
[error, items, units, scale, useSN, designLife, algorithm, offset,...
    msCorrection, loadEqVal, loadEqUnits, elementType, outputField,...
    outputHistory, outputFigure, ktDef, ktCurve, ~, failureMode,...
    userUnits, jobName, jobDescription, dataset, history, hfDataset,...
    hfHistory, hfTime, hfScales]...
    ...
    = jobFile.readFlags(flags);

if error == 1.0
    return
end
	
%% TIMER FOR DATA CHECK ANALYSIS
if getappdata(0, 'dataCheck') > 0.0
    tic_dataCheck = tic;
end

%% INITIALIZE MESSAGE FILE FLAGS
setappdata(0, 'messageFileNotes', 0.0)
setappdata(0, 'messageFileWarnings', 0.0)

%% PRINT COMMAND WINDOW HEADER
fprintf('[NOTICE] Quick Fatigue Tool 6.10-07')
fprintf('\n[NOTICE] (Copyright Louis Vallance 2017)')
fprintf('\n[NOTICE] Last modified 24-Apr-2017 18:27:33 GMT')

cleanExit = 0.0;

%% IF THE FOS IS REQUESTED, CHECK THAT FIELD OUTPUT IS ALSO REQUESTED
[outputField, error] = jobFile.checkFOS(outputField);

if error == 1.0
    return
end

%% IF AUTOMATIC EXPORT IS BEING USED, CHECK IN ADVANCE THAT THE SET-UP IS VALID
[error, outputField] = jobFile.checkAutoExport(outputField);

if error == 1.0
    return
end

%% MAKE SURE THE OUTPUT DIRECTORY EXISTS
[dir, error] = preProcess.checkOutput(jobName, outputField, outputHistory, outputFigure);

if error == 1.0
    return
end

% Open status file for writing
fileName = sprintf('Project/output/%s/%s.sta', jobName, jobName);
fid_status = fopen(fileName, 'w+');
c = clock;
fprintf(fid_status, '[NOTICE] Quick Fatigue Tool 6.10-07\t%s', datestr(datenum(c(1.0), c(2.0), c(3.0), c(4.0), c(5.0), c(6.0))));

fprintf('\n[NOTICE] The job file "%s.m" has been submitted for analysis', jobName)
fprintf(fid_status, '\n[NOTICE] The job file "%s.m" has been submitted for analysis', jobName);

% Advise user is verbose output is not requested
if getappdata(0, 'echoMessagesToCWIN') == 0.0
    fprintf('\n[NOTICE] Analysis-related messages can be printed to the command window by setting echoMessagesToCWIN = 1.0 in the environment file')
    fprintf(fid_status, '\n[NOTICE] Analysis-related messages can be printed to the command window by setting echoMessagesToCWIN = 1.0 in the environment file');
end

%% Unsuppress message IDs
messenger.unsupressMessageIDs()

%% OPEN THE MESSAGE FILE
messenger.writeMessage(0.0)
messenger.writeMessage(134.0)
messenger.writeMessage(1.0)
messenger.writeMessage(96.0)
messenger.writeMessage(169.0)

%% PRINT INPUT FILE READER SUMMARY TO MESSAGE FILE
keywords.printSummary()

%% CHECK IF RESULTS DIRECTORY WAS SUCCESSFULLY REMOVED
if getappdata(0, 'warning_026') == 1.0
    rmappdata(0, 'warning_026')
    messenger.writeMessage(35.0)
end

%% INFORM THE USER ABOUT THE OUTPUT DATABASE DEFINITIONS
if getappdata(0, 'writeMessage_184') == 1.0
    messenger.writeMessage(184.0)
end
if getappdata(0, 'writeMessage_185') == 1.0
    messenger.writeMessage(185.0)
end
if getappdata(0, 'writeMessage_186') == 1.0
    messenger.writeMessage(186.0)
end

%% CHECK THE CONTINUE_FROM FLAG
[error, outputField] = overlay.checkJob(outputField);

if error == 1.0
    cleanup(1.0)
    return
end

%% INITIALIZE GROUP SETTINGS
fprintf('\n[NOTICE] Begin analysis preprocessor')
fprintf(fid_status, '\n[NOTICE] Begin analysis preprocessor');

[error, G] = group.initialize();

if error == 1.0
    cleanup(1.0)
    return
end

%% READ AND VERIFY MATERIAL PROPERTIES
[material, failureMode, cleanExit] = jobFile.verifyMaterial(algorithm, failureMode, useSN, cleanExit);

if cleanExit == 1.0
    return
end

%% DETERMINE THE ALGORITHM AND MEAN STRESS CORRECTION TO BE USED FOR THE ANALYSIS
[algorithm, msCorrection, nlMaterial, useSN, error] = jobFile.getAlgorithmAndMSC(algorithm, msCorrection, useSN);
setappdata(0, 'algorithm', algorithm)

if error == 1.0
    cleanup(1.0)
    return
end

%% CHECK IF USER-DEFINED FRF DATA IS SUPPLIED
error = jobFile.getUserFRF(algorithm);

if error == 1.0
    cleanup(1.0)
    return
end

%% CHECK THE FOS BAND DEFINITION
error = jobFile.checkFosBands();

if error > 0.0
    if error == 1.0
        setappdata(0, 'E039', 1.0)
    else
        setappdata(0, 'E052', 1.0)
    end
    cleanup(1.0)
    return
end

%% APPLY KNOCK-DOWN FACTORS TO S-N DATA IF NECESSARY
%{
    Knock-down factors are not compatible with the BS 7806 analysis
    algorithm

    Knock-down factors are only used when USE_SN = 1.0
%}
[nSets, ~] = size(getappdata(0, 's_values'));

if (algorithm ~= 8.0) && (useSN == 1.0)
    knockdown(nSets);
end

%% DETERMINE THE STRESS CONCENTRATION FACTOR (KT) FOR THE ANALYSIS
% Only if BS 7608 is not being used for analysis
if algorithm ~= 8.0
    preProcess.kt(ktDef, ktCurve, getappdata(0, 'uts'));
end

%% INTERPOLATE THE S-N CURVE FOR R = -1 if R-RATIOS ARE NOT REQUESTED
% Only if BS 7608 is not being used for analysis
if algorithm ~= 8.0
    %{
        If the user provided multiple S-N curves for different R-ratios and
        requested S-N data for fatigue analysis, but did not request
        R-ratio S-N curves mean stress correction, the S-N curve for
        R = -1.0 must be found
    %}
    getRMinus1Curve(useSN, msCorrection, nSets, G)
end

%% SCALE AND COMBINE THE LOADING
fprintf('\n[PRE] Processing datasets')
fprintf(fid_status, '\n[PRE] Processing datasets');

[scale, offset, repeats, units, N, signalLength, Sxx, Syy, Szz, Txy, Tyz, Txz, mainID,...
    subID, gateHistories, gateTensors, tensorGate, error]...
    ...
    = jobFile.getLoading(units, scale,...
    algorithm, msCorrection, nlMaterial, userUnits, hfDataset, hfHistory,...
    hfTime, hfScales, items, dataset, history, elementType, offset);

if error == 1.0
    cleanup(1.0)
    return
end

%% WARN THE USER IF THERE ARE DUPLICATE ITEMS IN THE MODEL
preProcess.checkDuplicateItems(N, mainID, subID)

%% GET GROUP ITEMS FOR THE ANALYSIS IF APPLICABLE
[error, N, mainID, subID] = group.getItems(N, mainID, subID);

[r, ~] = size(mainID);
if r == 1.0
    mainID = mainID';
end
[r, ~] = size(subID);
if r == 1.0
    subID = subID';
end

if error == 1.0
    cleanup(1.0)
    return
end

% Save item IDs
setappdata(0, 'mainID', mainID)
setappdata(0, 'subID', subID)

%% GET THE PRINCIPAL STRESS HISTORY FOR THE LOADING
fprintf('\n[PRE] Calculating invariants')
fprintf(fid_status, '\n[PRE] Calculating invariants');

preProcess.getPrincipalStress(N, Sxx, Syy, Szz, Txy, Tyz, Txz, algorithm, 0.0)

%% GET THE VON MISES STRESS FOR THE LOADING
if (algorithm == 7.0 && getappdata(0, 'stressInvariantParameter') == 1.0) || algorithm == 9.0 || outputField == 1.0 || outputHistory == 1.0 || outputFigure == 1.0
    vonMises = preProcess.getVonMisesStress(N, Sxx, Syy, Szz, Txy, Tyz, Txz);
elseif strcmpi(getappdata(0, 'items'), 'peek') == 1.0
    setappdata(0, 'CalculatedVonMisesStress', 0.0)
end

%% GET THE STRESS INVARIANT PARAMETER (IF APPLICABLE)
if algorithm == 7.0
    stressInvParam = preProcess.getStressInvParam(0.0);
end

%% ISOLATE THE LARGEST (S1-S3) ITEM IF APPLICABLE
if (strcmpi(getappdata(0, 'items'), 'peek') == 1.0) && (N > 1.0)
    [Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID, peekGroup, vonMises, error] = preProcess.peekAtNode(Sxx, Syy, Szz, Txy, Tyz, Txz, mainID, subID);
    
    if error == 1.0
        cleanup(1.0)
        return
    elseif algorithm == 7.0
        stressInvParam = getappdata(0, 'stressInvParam');
    end
    
    N = 1.0;
    peekAnalysis = 1.0;
    setappdata(0, 'peekAnalysis', 1.0)
else
    peekAnalysis = 0.0;
    setappdata(0, 'peekAnalysis', 0.0)
end

%% GET THE GOODMAN LIMIT STRESS FOR EACH GROUP IF APPLICABLE
if msCorrection == 2.0
    preProcess.goodmanLimitStress(G)
end

%% PERFORM NODAL ELIMINATION ANALYSIS IF REQUESTED
nodalElimination = getappdata(0, 'nodalElimination');

% Only if Uniaxial Stress-Life or BS 7608 are not being used for analysis
if (algorithm ~= 3.0) && (algorithm ~= 8.0)
    if (nodalElimination > 0.0) && (N > 1.0)
        fprintf('\n[PRE] Optimizing datasets')
        fprintf(fid_status, '\n[PRE] Optimizing datasets');
        
        [coldItems, removedItems, hotspotWarning] = preProcess.nodalElimination(algorithm,...
            nlMaterial, msCorrection, N);
        
        setappdata(0, 'separateFieldOutput', 1.0)
        messenger.writeMessage(22.0)
        
        %{
            Check if individual group items were eliminated. If so, inform
            the user
        %}
        if (removedItems > 0.0) && (G > 1.0)
            group.checkEliminatedGroupItems(coldItems, mainID, subID, G)
        end
    else
        coldItems = [];
        removedItems = 0.0;
        hotspotWarning = 0.0;
        setappdata(0, 'separateFieldOutput', 0.0)
    end
else
    if nodalElimination > 0.0 && algorithm == 8.0
        messenger.writeMessage(20.0)
    end
    
    if nodalElimination > 0.0 && algorithm == 3.0
        messenger.writeMessage(21.0)
    end
    
    coldItems = [];
    hotspotWarning = 0.0;
    removedItems = 0.0;
    setappdata(0, 'separateFieldOutput', 0.0)
end
setappdata(0, 'nodalEliminationRemovedItems', removedItems)

if hotspotWarning == 1.0
    messenger.writeMessage(19.0)
end

setappdata(0, 'numberOfNodes', N)

%% DETERMINE IF THE MODEL IS YIELDING
preProcess.getPlasticItems(N, algorithm);

if getappdata(0, 'warning_063') == 1.0
    postProcess.writeYieldingItems(jobName, mainID, subID)
end

%% INITIALISE THE CP SEARCH PARAMETERS

step = getappdata(0, 'stepSize');

% Check that total number of required steps is an integer
if mod(180.0, step) ~= 0.0 || step < 1.0 || step > 180.0
    step = 15.0;
    if (algorithm ~= 8.0) && (algorithm ~= 3.0)
        messenger.writeMessage(61.0)
    end
end

step = linspace(step, step, N);
setappdata(0, 'stepSize', step)

planePrecision = floor(180.0./step) + 1.0;
setappdata(0, 'planePrecision', planePrecision)

%% CHECK THE LOAD PROPORTIONALITY
if getappdata(0, 'checkLoadProportionality') == 1.0 && (algorithm ~= 3.0 && algorithm ~= 7.0 && algorithm ~= 9.0 && algorithm ~= 6.0)
    fprintf('\n[PRE] Performing load proportionality checks')
    fprintf(fid_status, '\n[PRE] Performing load proportionality checks');
    
    [step, planePrecision] = preProcess.getLoadProportionality(Sxx, Syy, N, step, planePrecision, getappdata(0, 'proportionalityTolerance'));
end

%% CALCULATE SIGNAL HISTORIES FROM VIRTUAL STRAIN GAUGES
virtualStrainGauge(Sxx, Syy, Txy, Szz, Txz, Tyz)

%% INITIALISE ANALYSIS VARIABLES
fprintf('\n[NOTICE] End analysis preprocessor')
fprintf(fid_status, '\n[NOTICE] End analysis preprocessor');

% Set the default design life for the analysis
if strcmpi(designLife, 'cael') == 1.0
    if algorithm == 8.0
        setappdata(0, 'dLife', 1e7)
    else
        setappdata(0, 'dLife', 0.5*getappdata(0, 'cael'))
    end
end

if isempty(designLife) == 1.0
    if algorithm == 8.0
        setappdata(0, 'dLife', 1e7)
    else
        setappdata(0, 'dLife', 0.5*getappdata(0, 'cael'))
    end
end

% Variables for progress counter
x0 = 20.0;
x = 20.0;
reported = 0.0;
analysedNodes = 0.0;

% Number of items to analysis after nodal elimination
N2 = N - length(coldItems);

% Constant amplitude endurance limit for analysis summary
cael = getappdata(0, 'cael');
if isempty(cael) == 1.0
    cael = 2e7;
end

% General fatigue analysis variables
nodalDamage = zeros(1.0, N); % Total damage at each analysis item

nodalPairs = cell(1.0, N); % Every min/max cycle value in the loading at each analysis item
nodalAmplitudes = cell(1.0, N); % Every cycle in the loading at each analysis item

setappdata(0, 'localFatigueLimit', zeros(1.0, N)) % Fatigue limit stress at each location in the model

% Fatigue analysis variables for rainflow algorithm
setappdata(0, 'printRFWarn', 0.0)

% Fatigue analysis variables for critical plane search algorithm
nodalDamageParameter = zeros(1.0, N);

nodalPhiC = zeros(1.0, N);    % Angle PHI on critical plane for each analysis item
nodalThetaC = zeros(1.0, N);  % Angle THETA on critical plane for each analysis item

% Maximum phi curve
maxPhiCurve = zeros(1.0, N);

% Maximum equivalent sress calculated from the Goodman/Gerber/Soderberg
% mean stress correction
setappdata(0, 'goodman_max_Sa0', 0.0)
setappdata(0, 'soderberg_max_Sa0', 0.0)
setappdata(0, 'gerber_max_Sa0', 0.0)

% Sign convention
signConvention = getappdata(0, 'signConvention');

% Initialize damageParameter variable in case analysis is not uniaxial
damageParameter = 0.0;

% Get the principal stresses
s1 = getappdata(0, 'S1');
s2 = getappdata(0, 'S2');
s3 = getappdata(0, 'S3');

% If PEEK analysis, reset value of G to 1.0
if peekAnalysis == 1.0
    %{
        In order to identify the worst analysis item from the correct
        group, save the original number of groups
    %}
    setappdata(0, 'numberOfGroupsPeek', G)
    
    G = 1.0;
    setappdata(0, 'numberOfGroups', 1.0)
end

%% MAIN ANALYSIS
if getappdata(0, 'dataCheck') > 0.0
    %{
        If the job is a data check analysis, abort here. Print the
        principal stresses to a text file
    %}
    if outputField == 1.0
        printTensor(Sxx, Syy, Szz, Txy, Tyz, Txz)
    end
    
	setappdata(0, 'dataCheck_time', toc(tic_dataCheck))
	fprintf('\n[NOTICE] Data Check complete (%fs)\n', toc(tic_dataCheck))
    messenger.writeMessage(-999.0)
    fprintf(fid_status, '\n[NOTICE] END OF FILE');
    fclose(fid_status);
    return
end

% Start the timer
tic

% Warn if multiple items are being used with the FOS algorithm
messenger.writeMessage(30.0)

% Perform fatigue analysis on each item in the model
fprintf('\n[NOTICE] Begin fatigue analysis')
fprintf('\n[NOTICE] See status and message files for details')
fprintf(fid_status, '\n[NOTICE] Begin fatigue analysis');
fprintf(fid_status, '\n[NOTICE] See status and message files for details');

fprintf(fid_status, '\r\n\r\nProgress\tLife\tItem\tIncrement\tTime\r\n');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Set a counter which runs from 1 to the total number of analysis items
totalCounter = 0.0;

% Inform the user how many items will be analysed
messenger.writeMessage(168.0)

% Print a summary of the memory state
messenger.writeMessage(133.0)

% Calculate items at which debug information is to be written
[debugItems, cacheOverlay] = qftWorkspace.initialize(N, [], jobName, []);

% Buffer for the worst fatigue damage per group
groupWorstLife = zeros(1.0, G);

% Get the rainflow type variable
rainflowMode = getappdata(0, 'rainflowMode');

% Get the stress invariant parameter type
stressInvParamType = getappdata(0, 'stressInvariantParameter');

% Get the NASALIFE parameter
nasalifeParameter = getappdata(0, 'nasalifeParameter');

for groups = 1:G
    %{ 
        If the analysis is a PEEK analysis, override the value of GROUP to
        the group containing the PEEK item
    %}
    if peekAnalysis == 1.0
        groups = peekGroup; %#ok<FXSET>
    end
    
    if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
        % There is one, default group
        groupIDs = linspace(1.0, N, N);
    else
        % Assign group parameters to the current set of analysis IDs
        [N, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
        
        %{
            If N == 0.0, there are no items in the current group to
            analyse. Move on to the next group
        %}
        if N == 0.0
            continue
        end
    end
    
    % Initialize the group nodal damage buffer
    groupNodalDamage = zeros(1.0, N);
    
    % Save the current group number
    setappdata(0, 'getMaterial_currentGroup', groups)
    
    for item = 1:N
        % Update the counter
        totalCounter = totalCounter + 1.0;
        
        % Save workspace to file
        if any(debugItems == totalCounter) == 1.0
            if cacheOverlay == 1.0
                fileName = 'qft_data.mat';
            else
                fileName = sprintf('qft_data_%.0f.mat', totalCounter);
            end
            
            % Save variables
            save(sprintf('%s/Project/output/%s/Data Files/%s', pwd, jobName, fileName))
            
            % Save %APPDATA%
            APPDATA = getappdata(0.0); %#ok<NASGU>
            save(sprintf('%s/Project/output/%s/Data Files/%s', pwd, jobName, fileName), 'APPDATA', '-append')
        end
        
        %{
            If groups are being used, convert the current item number to
            the current item ID in the current group
        %}
        groupItem = groupIDs(item);
        
        % Skip items which have been eliminated from the analysis
        if any(totalCounter == coldItems) == 1.0
            % Set damage to zero
            nodalDamage(totalCounter) = 0.0;
            
            % Store worst cycles for current item
            nodalAmplitudes{totalCounter} = 0.0;
            nodalPairs{totalCounter} = [0.0, 0.0];
            continue
        end
        
        % Number of items analysed so far
        analysedNodes = analysedNodes + 1.0;
        
        % Get the stress history for the current analysis item
        Sxxi = Sxx(groupItem, :);   Syyi = Syy(groupItem, :);   Szzi = Szz(groupItem, :);
        Txyi = Txy(groupItem, :);   Tyzi = Tyz(groupItem, :);   Txzi = Txz(groupItem, :);
        
        % Get the principal stress history at the current item
        s1i = s1(totalCounter, :);  s2i = s2(totalCounter, :);  s3i = s3(totalCounter, :);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%FATIGUE ANALYSIS ALGORITHM%%%%%%%%%%%%%%%%%%%%%%%
        
        switch algorithm
            case 3.0 % UNIAXIAL STRESS-LIFE
                [nodalAmplitudes, nodalPairs, nodalDamage, nodalDamageParameter, damageParameter]...
                    = algorithm_usl.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, signalLength,...
                    totalCounter, nodalDamage, msCorrection, nodalAmplitudes, nodalPairs,...
                    nodalDamageParameter, gateTensors, tensorGate);
            case 4.0 % STRESS-BASED BROWN-MILLER
                [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                    nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                    algorithm_sbbm.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi,...
                    signalLength, step(totalCounter), planePrecision(totalCounter),...
                    nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                    nodalPhiC, nodalThetaC, totalCounter, msCorrection,...
                    nodalDamage, gateTensors, tensorGate, signConvention,...
                    s1i, s2i, s3i, maxPhiCurve, rainflowMode);
            case 5.0 % NORMAL STRESS
                [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                    nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                    algorithm_ns.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi,...
                    signalLength, step(totalCounter),...
                    planePrecision(totalCounter), nodalDamageParameter,...
                    nodalAmplitudes, nodalPairs, nodalPhiC, nodalThetaC,...
                    totalCounter, msCorrection, nodalDamage, gateTensors,...
                    tensorGate, maxPhiCurve);
            case 6.0 % FINDLEY'S METHOD
                k = getappdata(0, 'k');
                [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                    nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                    algorithm_findley.main(Sxxi, Syyi, Szzi, Txyi, Tyzi,...
                    Txzi, signalLength, step(totalCounter), planePrecision(totalCounter),...
                    nodalDamageParameter, nodalAmplitudes, nodalPairs, nodalPhiC,...
                    nodalThetaC, totalCounter, nodalDamage, msCorrection,...
                    gateTensors, tensorGate, signConvention, s1i, s2i,...
                    s3i, maxPhiCurve, k);
            case 7.0 % STRESS INVARIANT PARAMETER
                % Get the von Mises stress at the current item
                stressInvParam_i = stressInvParam(totalCounter, :);
                
                [nodalAmplitudes, nodalPairs, nodalDamage, nodalDamageParameter]...
                    = algorithm_sip.main(s1i, s2i, s3i, signalLength, totalCounter,...
                    nodalDamage, msCorrection, nodalAmplitudes, nodalPairs,...
                    nodalDamageParameter, signConvention, gateTensors,...
                    tensorGate, stressInvParam_i, stressInvParamType,...
                    Sxxi, Syyi);
            case 8.0 % BS 7608
                [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                    nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                    algorithm_bs7608.main(Sxxi, Syyi, Szzi, Txyi, Tyzi,...
                    Txzi, signalLength, step(totalCounter),...
                    planePrecision(totalCounter), nodalDamageParameter,...
                    nodalAmplitudes, nodalPairs, nodalPhiC, nodalThetaC,...
                    totalCounter, nodalDamage, failureMode, gateTensors,...
                    tensorGate, signConvention, s1i, s2i, s3i,...
                    maxPhiCurve, repeats);
            case 9.0 % NASALIFE
                % Get the von Mises stress at the current item
                vonMises_i = vonMises(totalCounter, :);
                
                [nodalAmplitudes, nodalPairs, nodalDamage, nodalDamageParameter]...
                    = algorithm_nasa.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, signalLength,...
                    totalCounter, nodalDamage, nodalAmplitudes, nodalPairs, nodalDamageParameter,...
                    s1i, s2i, s3i, signConvention, gateTensors, tensorGate, vonMises_i, nasalifeParameter);
            otherwise
        end
        
        %%%%%%%%%%%%%%%%%%%%%%FATIGUE ANALYSIS ALGORITHM%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % If user S-N data was used without extrapolation, check for NaN damage values
        if (useSN == 1.0) && any(isnan(nodalDamage))
            setappdata(0, 'E008', 1.0)
            
            cleanup(1.0)
            return
        end
        
        % Save the damage at the current node in the current group
        groupNodalDamage(item) = nodalDamage(totalCounter);
        
        % REPORT PROGRESS
        [reported, x] = status(fid_status, analysedNodes, totalCounter, N2, nodalDamage, mainID, subID,...
            reported, x0, x);
    end
    
    % Save the worst damage for the current group
    groupWorstLife(groups) = 1.0./max(groupNodalDamage);
end

% Close summary file
fprintf('\n[NOTICE] End fatigue analysis')
fprintf(fid_status, '\n[NOTICE] End fatigue analysis');

% Worst life item
worstAnalysisItem = find(nodalDamage == max(nodalDamage));
setappdata(0, 'worstAnalysisItem', worstAnalysisItem)

mainID_master = getappdata(0,'mainID_master');
subID_master = getappdata(0,'subID_master');

%{
    The worst analysis item is reported to the message file. However, the
    value of WORSTANALYSISITEM corresponds to the (potentially) re-arranged
    item ID list. This happens if groups are defined for the analysis. The
    worst item(s) reported in the message file must therefore be corrected
    to reference the original item ID list, since the ITEM option is used
    during input file processing, before the groups are read
%}
if G > 1.0
    mainID_groupAll = getappdata(0, 'mainID_groupAll');
    subID_groupAll = getappdata(0, 'subID_groupAll');
    
    if isempty(mainID_groupAll) == 1.0 || isempty(subID_groupAll) == 1.0
        worstAnalysisItem_original = worstAnalysisItem;
        setappdata(0, 'worstAnalysisItem_original', worstAnalysisItem_original)
    else
        worstAnalysisItem_original = zeros(1.0, length(worstAnalysisItem));
        
        for i = 1:length(worstAnalysisItem)
            %{
                Find the index of the original ID list at which the worst
                item appears in the re-arranged list
            %}
            x1 = find(mainID_master == mainID_groupAll(worstAnalysisItem(i)));
            x2 = find(subID_master == subID_groupAll(worstAnalysisItem(i)));
            
            if (isempty(x1) == 1.0) || (isempty(x2) == 1.0)
                worstAnalysisItem_original = worstAnalysisItem;
            else
                worstAnalysisItem_original_i = intersect(x1, x2);
                worstAnalysisItem_original(i) = worstAnalysisItem_original_i(1.0);
            end
        end
        worstAnalysisItem_original = worstAnalysisItem_original(1.0);
    end
    
    setappdata(0, 'worstAnalysisItem_original', worstAnalysisItem_original)
else
    worstAnalysisItem_original = worstAnalysisItem;
    worstAnalysisItem_original = worstAnalysisItem_original(1.0);
    setappdata(0, 'worstAnalysisItem_original', worstAnalysisItem_original)
end
messenger.writeMessage(18.0)

if length(worstAnalysisItem) > 1.0
    %{
        If there is more than one worst analysis item, take the item with
        the largest stress
    %}
    maximumStressItem = postProcess.getMaximumStress();
    
    %{
        If the item with the largest stress does not coincide with any of
        the reported worst analysis items, take the first item in the list
    %}
    if isempty(find(worstAnalysisItem == maximumStressItem, 1.0)) == 1.0
        worstAnalysisItem = worstAnalysisItem(1.0);
    else
        worstAnalysisItem = worstAnalysisItem(worstAnalysisItem == maximumStressItem);
    end
    
    % The item with the largest stress no longer needs to be calculated
    setappdata(0, 'skipMaximumStressCalculation', 1.0)
else
    setappdata(0, 'skipMaximumStressCalculation', 0.0)
end

% Get the worst main and sub IDs
worstMainID = mainID_master(worstAnalysisItem_original);
worstSubID = subID_master(worstAnalysisItem_original);

setappdata(0, 'worstMainID', worstMainID)
setappdata(0, 'worstSubID', worstSubID)
setappdata(0, 'worstItem', worstAnalysisItem_original)

%% ADDITIONAL ANALYSIS CODE FOR USER OUTPUT
fprintf('\n[NOTICE] Begin analysis postprocessor')
fprintf(fid_status, '\n[NOTICE] Begin analysis postprocessor');

phiOnCP = nodalPhiC(worstAnalysisItem);
thetaOnCP = nodalThetaC(worstAnalysisItem);

setappdata(0, 'phiOnCP', phiOnCP)    % Angle PHI on critical plane for worst analysis item
setappdata(0, 'thetaOnCP', thetaOnCP)% Angle THETA on critical plane for worst analysis item

% Stress tensor at the worst analysis item in the model

%{
    If groups are being used, the worst item ID does not refer to the
    correct location in the stress tensor matrix. This is because the
    stress tensors were formed from the master dataset, but the worst item
    ID comes from the nodal damage buffer which is formed from the group
    IDs. The worstItemID variable cannot be used to index the stress
    tensors and hence must be converted to the corresponding index from the
    global ID list

    If groups are not being used, the tensor ID should be identical to the
    worst item ID
%}
% Get tensor ID from worst analysis item ID
tensorID = group.getTensorID(worstAnalysisItem, nodalDamage, mainID_master, subID_master);
tensorID = tensorID(1.0);

% Get the stress tensor at the worst node
worstNodeTensor = [Sxx(tensorID, :); Syy(tensorID, :);...
    Szz(tensorID, :); Txy(tensorID, :);...
    Txz(tensorID, :); Tyz(tensorID, :)];

setappdata(0, 'worstNodeSxx', Sxx(tensorID, :))
setappdata(0, 'worstNodeSyy', Syy(tensorID, :))
setappdata(0, 'worstNodeSzz', Szz(tensorID, :))
setappdata(0, 'worstNodeTxy', Txy(tensorID, :))
setappdata(0, 'worstNodeTyz', Tyz(tensorID, :))
setappdata(0, 'worstNodeTxz', Txz(tensorID, :))

% Get the principal stresses at the worst node
x1 = find(mainID == worstMainID);
x2 = find(subID == worstSubID);
x3 = intersect(x1, x2);
s1i = s1(x3, :);
s2i = s2(x3, :);
s3i = s3(x3, :);

%{
    Get the material properties for the group containing the worst analysis
    item
%}
worstGroup = find(groupWorstLife == min(groupWorstLife));

if length(worstGroup) ~= 1.0
    worstGroup = worstGroup(1.0);
end
[~, ~] = group.switchProperties(worstGroup, groupIDBuffer);

% Additional analysis for history output
if (outputHistory == 1.0) || (outputField == 1.0) || (outputFigure == 1.0)
    fprintf('\n[POST] Calculating worst item output')
    fprintf(fid_status, '\n[POST] Calculating worst item output');
    
    switch algorithm
        case 3.0 % UNIAXIAL STRESS-LIFE
            algorithm_usl.worstItemAnalysis(signalLength, msCorrection,...
                nodalAmplitudes, nodalPairs)
        case 4.0
            % STRESS-BASED BROWN-MILLER
            algorithm_sbbm.worstItemAnalysis(worstNodeTensor, phiOnCP,...
                thetaOnCP, signalLength, msCorrection,...
                planePrecision(worstAnalysisItem), gateTensors, tensorGate,...
                step(worstAnalysisItem), signConvention, s1i, s2i, s3i, rainflowMode)
        case 6.0
            % FINDLEY'S METHOD
            algorithm_findley.worstItemAnalysis(worstNodeTensor, phiOnCP,...
                thetaOnCP, signalLength, msCorrection, planePrecision(worstAnalysisItem),...
                gateTensors, tensorGate, step(worstAnalysisItem), signConvention,...
                s1i, s2i, s3i, k)
        case 7.0 % STRESS INVARIANT PARAMETER
            algorithm_sip.worstItemAnalysis(worstNodeTensor, signalLength,...
                msCorrection, signConvention, gateTensors, tensorGate,...
                s1i, s2i, s3i)
        case 5.0
            % NORMAL STRESS
            algorithm_ns.worstItemAnalysis(worstNodeTensor, phiOnCP, thetaOnCP,...
                signalLength, msCorrection, planePrecision(worstAnalysisItem),...
                gateTensors, tensorGate, step(worstAnalysisItem), signConvention,...
                s1i, s2i, s3i)
        case 8.0
            % BS 7608
            algorithm_bs7608.worstItemAnalysis(worstNodeTensor, phiOnCP,...
                thetaOnCP, signalLength, failureMode,...
                planePrecision(worstAnalysisItem), gateTensors,...
                tensorGate, step(worstAnalysisItem), signConvention, s1i,...
                s2i, s3i, repeats)
        case 9.0 % NASALIFE
            algorithm_nasa.worstItemAnalysis(worstAnalysisItem, G,...
                worstNodeTensor, signalLength, s1i, s2i, s3i,...
                signConvention, gateTensors, tensorGate, nasalifeParameter)
        otherwise
    end
end

%% CONVERT FATIGUE LIFE TO LOADING EQUIVALENCE
nodalDamage = nodalDamage/loadEqVal;

%% GET FATIGUE LIFE VALUES FROM DAMAGE DATA
% Findley parameter if applicable
setappdata(0, 'WCDP', nodalDamageParameter)

% Worst cycle for each item
setappdata(0, 'nodalAmplitudes', nodalAmplitudes)
setappdata(0, 'nodalPairs', nodalPairs)

% LOG10(Life) per item
LL = log10(1.0./nodalDamage);
for i = 1:length(LL)
    if LL(i) > log10(0.5*cael)
        LL(i) = log10(0.5*cael);
    elseif LL(i) < 0.0
        LL(i) = 0.0;
    end
end
setappdata(0, 'LL', LL)

% Nodal damage
setappdata(0, 'D', nodalDamage)
messenger.writeMessage(24.0)

%% GET THE WORST LIFE FOR EACH ANALYSIS GROUP
group.worstLifePerGroup(1.0./nodalDamage, mainID, subID, groupWorstLife, peekAnalysis)

%% GET THE NUMBER OF CYCLES IN THE LOADING
postProcess.getNumberOfCycles()

%% GET WCM AND WCA FOR FIELD OR HISTORY OUTPUT
if outputField == 1.0 || outputHistory == 1.0
    postProcess.getWorstCycleMeanAmp()
end

if outputField == 1.0
    %% CALCULATE FIELD OUTPUT
    fprintf('\n[POST] Writing field output')
    fprintf(fid_status, '\n[POST] Writing field output');
    
    if algorithm == 8.0
        algorithm_bs7608.getFields()
    else
        postProcess.getFields(algorithm, msCorrection, gateTensors, tensorGate, coldItems, fid_status)
    end
    
    %% EXPORT FIELDS
    if algorithm == 8.0
        algorithm_bs7608.exportFields(loadEqUnits)
    else
        postProcess.exportFields(loadEqUnits, coldItems)
    end
    
    messenger.writeMessage(141.0)
end

if (outputHistory == 1.0) || (outputFigure == 1.0)
    %% CALCULATE HISTORY OUTPUT
    fprintf('\n[POST] Writing history output')
    fprintf(fid_status, '\n[POST] Writing history output');
    
    if algorithm == 8.0
        algorithm_bs7608.getHistories(loadEqUnits, outputField, outputFigure)
    else
        postProcess.getHistories(algorithm, loadEqUnits, outputField, outputFigure, damageParameter, G)
    end
    
    if outputHistory == 1.0
        %% EXPORT HISTORIES
        if algorithm == 8.0
            algorithm_bs7608.exportHistories(loadEqUnits)
        else
            postProcess.exportHistories(algorithm, loadEqUnits)
        end
        
        messenger.writeMessage(140.0)
    end
    
    if outputFigure == 1.0
        messenger.writeMessage(142.0)
    end
end

%% WRITE WARNING FIELD DATA
L = (1.0./nodalDamage);
setappdata(0, 'L', L)

messenger.writeMessage(65.0)

if any(L < 1e6)
    postProcess.writeLCFItems(L, jobName, mainID, subID, loadEqUnits)
    
    if any(L < 1.0)
        postProcess.writeOverflowItems(nodalDamage, jobName, mainID, subID)
    end
end

%% WRITE HOTSPOTS
if getappdata(0, 'getHotSpots') == 1.0
    postProcess.writeHotSpots(nodalDamage, mainID, subID, jobName, loadEqUnits)
end

%% OVERLAY FIELD OUTPUT WITH PREVIOUS JOB IF REQUESTED
if getappdata(0, 'continueAnalysis') == 1.0
    overlay.prepare_fields()
end

%% EXPORT FIELDS TO ODB IF REQUESTED
if getappdata(0, 'autoExport_ODB') == 1.0
    if getappdata(0, 'autoExport_uniaxial') == 1.0
        messenger.writeMessage(203.0)
    else
        postProcess.autoExportODB(fid_status, mainID)
    end
end

%% CLOSE THE MESSAGE FILE
messenger.writeMessage(-1.0)
messenger.writeMessage(-999.0)

fprintf('\n[NOTICE] End analysis postprocessor')
fprintf(fid_status, '\n[NOTICE] End analysis postprocessor');

%% WRITE LOG FILE
messenger.writeLog(jobName, jobDescription, dataset, material,...
    history, items, units, scale, repeats, useSN, gateHistories, gateTensors,...
    nodalElimination, planePrecision, worstAnalysisItem, thetaOnCP,...
    phiOnCP, outputField, algorithm, nodalDamage, worstMainID, worstSubID,...
    dir, step, cael, msCorrection, nlMaterial, removedItems,...
    hotspotWarning, loadEqVal, loadEqUnits, elementType, offset)

% SAVE WORKSPACE TO FILE
if any(debugItems == totalCounter) == 1.0
    if cacheOverlay == 1.0
        fileName = 'qft_data.mat';
    else
        fileName = sprintf('qft_data_%.0f.mat', totalCounter);
    end
    
    % Save variables
    save(sprintf('%s/Project/output/%s/Data Files/%s', pwd, jobName, fileName))
    
    % Save %APPDATA%
    APPDATA = getappdata(0.0); %#ok<NASGU>
    save(sprintf('%s/Project/output/%s/Data Files/%s', pwd, jobName, fileName), 'APPDATA', '-append')
end

%% CLOSE THE STATUS FILE
fprintf(fid_status, '\n[NOTICE] END OF FILE');
fclose(fid_status);

%% REMOVE APPDATA

cleanup(0.0)
% End main code - DO NOT EDIT
%ENVIRONMENT    Environment file for Quick Fatigue Tool.
%   This file contains a list of environment variables which control the
%   default behaviour of Quick Fatigue Tool.
%
%   ENVIRONMENT is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Environment settings from this file are applied globally to all
%   analyses. To specify environment variables for a specific job, copy
%   this file into Project\job and rename the file to '<jobName>_env.m'.
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      2 Environment variables
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 12-May-2017 15:25:52 GMT

%% GATE TENSORS
%{
    0: Off
    1: Gate tensors (as % of max tensor)
    2: Gate tensors (Nielsony's method)
%}
setappdata(0, 'gateTensors', 2.0)

% GATE VALUE (%)
setappdata(0, 'tensorGate', 5.0)

%% PRE-GATE LOAD HISTORIES
%{
    0: Off
    1: Pre-gate load histories (as % of max tensor)
    2: Pre-gate load histories (Nielsony's method)
%}
setappdata(0, 'gateHistories', 0.0)

% GATE VALUE (%)
setappdata(0, 'historyGate', 5.0)

%% NOISE REDUCTION
setappdata(0, 'noiseReduction', 0.0)
setappdata(0, 'numberOfWindows', 2.0)

%% GROUP DEFINITION
%{
    0: Program controlled
    1: Always read group data as an FEA subset
%}
setappdata(0, 'groupDefinition', 0.0)

%% MEAN STRESS CORRECTION

% GOODMAN ENVELOPE DEFINITION
%{
    0: Use standard envelope for Goodman mean stress correction
    1: Use intersection of Buch and Goodman envelopes (if applicable)
%}
setappdata(0, 'modifiedGoodman', 0.0)

% GOODMAN MEAN STRESS LIMIT
%{
    'UTS': Material UTS (Default)
    'PROOF': Material proof stress
    'S-N': S-N curve intercept
    n: User-defined
%}
setappdata(0, 'goodmanMeanStressLimit', 'UTS')

% WALKER GAMMA PARAMETER DEFINITION
%{
    1: Regression fit (Walker)
    2: Standard values (Dowling)
    3: User-defined
%}
setappdata(0, 'walkerGammaSource', 1.0)

% USER-DEFINED WALKER GAMMA PARAMETER
setappdata(0, 'userWalkerGamma', [])

%% RAINFLOW CYCLE COUNTING

% RAINFLOW ALGORITHM
%{
    1: De Morais (Legacy)
    2: Vallance
%}
setappdata(0, 'rainflowAlgorithm', 2.0)

% RAINFLOW MODE FOR TWO-PARAMETER COUNTING
%{
    1: Combine parameters, count cycles
    2: Count parameters, combine cycles
%}
setappdata(0, 'rainflowMode', 1.0)

%% DEFAULT SHELL SECTION POINT
%{
    1: Bottom face (SNEG)
    2: Top face (SPOS)
%}
setappdata(0, 'shellLocation', 1.0)

%% NON-LINEAR MATERIAL PROPERTIES
%{
    0: Linear (Hookean) material model
    1: Nonlinear elastic (Ramberg-Osgood) material model
%}
setappdata(0, 'nlMaterial', 0.0)
setappdata(0, 'cssTolerance', 3e-04)
setappdata(0, 'cssMaxIterations', 5.5e+06)

%% NODAL ELIMINATION
%{
    0: Analyse all nodes
    1: Nodal elimination based on material's CAEL
    2: Nodal elimination based on user design life
%}
setappdata(0, 'nodalElimination', 1.0)

% ELIMINATION THRESHOLD SCALE FACTOR
setappdata(0, 'thresholdScaleFactor', 0.8)

%% YIELD CALCULATION
%{
    0: Do not perform yield calculations
    1: Perform yield calculations based on the total strain energy theory
    2: Perform yield calculations based on the shear strain energy theory
%}
setappdata(0, 'yieldCriterion', 0.0)

%% CRITICAL PLANE (CP) ANALYSIS

% SEARCH PARAMETERS
setappdata(0, 'stepSize', 10.0)
setappdata(0, 'checkLoadProportionality', 0.0)
setappdata(0, 'proportionalityTolerance', 1.0)

% CP HISTORY SMOOTHING
setappdata(0, 'cpSample', 0.0)

% SHEAR STRESS DETERMINATION
%{
    1: Maximum chord method
    2: Maximum resultant shear stress
%}
setappdata(0, 'cpShearStress', 1.0)

%% SIGN CONVENTION
%{
    1: Take sign from hydrostatic stress
    2: Take sign from largest principal stress
    3: Take sign from Mohr cirlce space
%}
setappdata(0, 'signConvention', 1.0)

%% ALGORITHM SETTINGS FOR STRESS-BASED BROWN-MILLER

% S-N CURVE
%{
    0: Use elastic region of S-N curve only (Sf' and b)
    1: Include plastic region of S-N curve (Ef' and c)
%}
setappdata(0, 'plasticSN', 0.0)

%% ALGORITHM SETTINGS FOR FINDLEY'S METHOD

% NORMAL STRESS MATCHING
%{
    1: Use maximum normal stress over loading
    2: Use maximum normal stress over maximum shear cycle interval
    3: Use average normal stress over maximum shear cycle interval
%}
setappdata(0, 'findleyNormalStress', 2.0)

%% ALGORITHM SETTINGS FOR STRESS INVARIANT PARAMETER

% STRESS INVARIANT PARAMETER
%{
    0: Program controlled
    1: von Mises
    2: Principal
    3: Hydrostatic
    4: Tresca
%}
setappdata(0, 'stressInvariantParameter', 0.0)

%% ALGORITHM SETTINGS FOR NASALIFE

% EFFECTIVE STRESS PARAMETER
%{
    1: Manson-McKnight
    2: Sines
    3: Smith-Watson-Topper
    4: R-Ratio Sines
    5: Effective
%}
setappdata(0, 'nasalifeParameter', 1.0)

%% TREATMENT OF COMPRESSIVE CYCLES
%{
    0: Calculate damage for fully compressive cycles
    1: Assume no damage for fully compressive cycles
%}
setappdata(0, 'ndCompression', 0.0)

%% FATIGUE/ENDURANCE LIMIT

% FATIGUE LIMIT DERIVATION
%{
    1: Calculate the fatigue limit from S-N (Basquin) material coefficients
    2: Calculate the fatigue limit from algorithm-specific equation (if applicable)
    3: User-defined
%}
setappdata(0, 'fatigueLimitSource', 1.0)

% USER-DEFINED FATIGUE LIMIT
setappdata(0, 'userFatigueLimit', [])

% DAMAGE BELOW ENDURANCE LIMIT
%{
    0: Program controlled
    1: Calculate damage for cycles below the endurance limit
    2: Assume no damage for cycles below the endurance limit
%}
setappdata(0, 'ndEndurance', 0.0)

% REDUCE ENDURANCE LIMIT FOR DAMAGING CYCLES
setappdata(0, 'modifyEnduranceLimit', 1.0)

% ENDURANCE LIMIT SCALE FACTOR
setappdata(0, 'enduranceScaleFactor', 0.25)

% NUMBER OF CYCLES FOR ENDURANCE LIMIT TO RECOVER
setappdata(0, 'cyclesToRecover', 50.0)

%% FACTOR OF STRENGTH (FOS)

% CALCULATION TARGET
%{
    1: Perform FOS calculations for user-defined design life
    2: Perform FOS calculations for infinite design life (CAEL)
%}
setappdata(0, 'fosTarget', 1.0)

% BAND DEFINITIONS
setappdata(0, 'fosMaxValue', 2.0)
setappdata(0, 'fosMaxFine', 1.5)
setappdata(0, 'fosMinFine', 0.8)
setappdata(0, 'fosMinValue', 0.5)

% ADVANCED SETTINGS
setappdata(0, 'fosCoarseIncrement', 0.1)
setappdata(0, 'fosFineIncrement', 0.01)
setappdata(0, 'fosMaxCoarseIterations', 8.0)
setappdata(0, 'fosMaxFineIterations', 12.0)
setappdata(0, 'fosTolerance', 5.0)
setappdata(0, 'fosBreakAfterBracket', 0.0)

% AUGMENTED FOS ITERATIONS
setappdata(0, 'fosAugment', 1.0)
setappdata(0, 'fosAugmentThreshold', 0.2)
setappdata(0, 'fosAugmentFactor', 5.0)

% OUTPUT DIAGNOSTICS
setappdata(0, 'fosDiagnostics', 1.0)

%% FATIGUE RESERVE FACTOR (FRF)

% INTERPOLATION ORDER FOR USER FRF DATA
%{
    'NEAREST' (Nearest Neighbor)
    'LINEAR' (Linear)
    'SPLINE' (Cubic, Piecewise)
    'PCHIP' (Cubic, Shape-preserving)
%}
setappdata(0, 'frfInterpOrder', 'LINEAR')

% MEAN STRESS NORMALIZATION PARAMETERS FOR USER FRF DATA
%{
    'UTS': Material ultimate tensile strength
    'UCS': Material ultimate compressive strength
    'PROOF': Material 0.2% proof stress
    n: User-defined
%}
setappdata(0, 'frfNormParamMeanT', 'UTS')
setappdata(0, 'frfNormParamMeanC', 'UCS')

% STRESS AMPLITUDE NORMALIZATION PARAMETER FOR USER FRF DATA
%{
    'LIMIT': Fatigue limit stress (default)
    n: User-defined
%}
setappdata(0, 'frfNormParamAmp', 'LIMIT')

% CALCULATION TARGET
%{
    1: Perform FRF calculations for user-defined design life
    2: Perform FRF calculations for infinite design life (CAEL)
%}
setappdata(0, 'frfTarget', 2.0)

% BAND DEFINITIONS
setappdata(0, 'frfMaxValue', 10.0)
setappdata(0, 'frfMinValue', 0.1)

% OUTPUT DIAGNOSTICS FOR USER FRF DATA
%{
    []: Disabled
    n: Item number
%}
setappdata(0, 'frfDiagnostics', [])

%% NOTCH FACTOR ESTIMATION
%{
    1: Peterson (default)
    2: Peterson B
    3: Neuber
    4: Harris
    5: Heywood
    6: Notch sensitivity
%}
setappdata(0, 'notchFactorEstimation', 1.0)

%% EIGENSOLVER
%{
    1: MATLAB (built-in)
    2: Luong
%}
setappdata(0, 'eigensolver', 2.0)

%% MATLAB FIGURE APPEARANCE
setappdata(0, 'defaultLineWidth', 1.0)
setappdata(0, 'defaultFontSize_XAxis', 12.0)
setappdata(0, 'defaultFontSize_YAxis', 12.0)
setappdata(0, 'defaultFontSize_Title', 14.0)
setappdata(0, 'defaultFontSize_Ticks', 12.0)
setappdata(0, 'XTickPartition', 4.0)
setappdata(0, 'gridLines', 'on')

% NUMBER OF BINS FOR RHIST MATLAB FIGURE
setappdata(0, 'numberOfBins', 30.0)

%% ANALYSIS OUTPUT INDIVIDUAL CONTROL

% MATLAB FIGURES
setappdata(0, 'figure_ANHD', 1.0)
setappdata(0, 'figure_HD', 1.0)
setappdata(0, 'figure_KDSN', 1.0)
setappdata(0, 'figure_VM', 1.0)
setappdata(0, 'figure_PS', 1.0)
setappdata(0, 'figure_CN', 1.0)
setappdata(0, 'figure_CS', 1.0)
setappdata(0, 'figure_DPP', 1.0)
setappdata(0, 'figure_DP', 1.0)
setappdata(0, 'figure_LP', 1.0)
setappdata(0, 'figure_CPS', 1.0)
setappdata(0, 'figure_CPN', 1.0)
setappdata(0, 'figure_DAC', 1.0)
setappdata(0, 'figure_RHIST', 1.0)
setappdata(0, 'figure_RC', 1.0)
setappdata(0, 'figure_SIG', 1.0)

% FIGURE FILE FORMAT
%{
    'fig' = MATLAB Figure
    'png' = Portable Netwok Graphics
    'jpg' = JPEG
%}
setappdata(0, 'figureFormat', 'fig')

% DATA FILES
setappdata(0, 'file_F_OUTPUT_ALL', 1.0)
setappdata(0, 'file_F_OUTPUT_ANALYSED', 1.0)
setappdata(0, 'file_H_OUTPUT_LOAD', 1.0)
setappdata(0, 'file_H_OUTPUT_CYCLE', 1.0)
setappdata(0, 'file_H_OUTPUT_ANGLE', 1.0)
setappdata(0, 'file_H_OUTPUT_TENSOR', 1.0)

% OUTPUT FORMAT STRING
setappdata(0, 'fieldFormatString', 'f')
setappdata(0, 'historyFormatString', 'f')

% COMMAND WINDOW OUTPUT
setappdata(0, 'echoMessagesToCWIN', 0.0)

%% APPLICATION DATA

% CLEAN %APPDATA%
%{
    1: Before
    2: After
    3: Before and after
    4: Never
%}
setappdata(0, 'cleanAppData', 4.0)

%% WORKSPACE CACHING

% CACHE WORKSPACE VARIABLES AND APPLICATION DATA
%{
    0: Disabled
    1: Every n analysis items
    2: n evenly spaced analysis items
    3: From analysis item IDs
%}
setappdata(0, 'workspaceToFile', 0.0)

% INTERVAL
%{
    First argument: Analysis item interval or ID list
    Second argument: ['OVERLAY' | 'RETAIN']
%}
setappdata(0, 'workspaceToFileInterval', {1.0, 'OVERLAY'})

%% ODB INTERFACE OPTIONS

% AUTOMATICALLY EXPORT FIELD DATA TO AN OUTPUT DATABASE (.ODB) FILE
setappdata(0, 'autoExport_ODB', 1.0)

% STEP DEFINITION
%{
    1: Export results to new step
    2: Export results to existing step
%}
setappdata(0, 'autoExport_stepType', 1.0)

% ATTEMPT TO DETERMINE DATA POSITION AUTOMATICALLY
setappdata(0, 'autoExport_autoPosition', 0.0)

% ATTEMPT TO UPGRADE THE ODB
setappdata(0, 'autoExport_upgradeODB', 1.0)

% ABAQUS COMMAND LINE
setappdata(0, 'autoExport_abqCmd', 'abaqus')

% ODB ELEMENT/NODE SET
setappdata(0, 'autoExport_createODBSet', 0.0)
setappdata(0, 'autoExport_ODBSetName', [])

% EXECUTION MODE
%{
    1: Create ODB, discard Python script
    2: Create ODB, retain Python script
    3: Write Python script only
%}
setappdata(0, 'autoExport_executionMode', 1.0)

% FIELD OUTPUT SELECTION MODE
%{
    1: Select from list below
    2: Preselected defaults
    3: All
%}
setappdata(0, 'autoExport_selectionMode', 2.0)

% OUTPUT VARIABLES
setappdata(0, 'autoExport_LL', 1.0)     % LOG10(Life)
setappdata(0, 'autoExport_L', 0.0)      % Life
setappdata(0, 'autoExport_D', 0.0)      % Damage
setappdata(0, 'autoExport_DDL', 0.0)    % Damage at design life
setappdata(0, 'autoExport_FOS', 0.0)    % Factor of strength
setappdata(0, 'autoExport_SFA', 0.0)    % Endurance safety factor
setappdata(0, 'autoExport_FRFR', 1.0)   % Radial fatigue reserve factor
setappdata(0, 'autoExport_FRFV', 1.0)   % Vertical fatigue reserve factor
setappdata(0, 'autoExport_FRFH', 1.0)   % Horizontal fatigue reserve factor
setappdata(0, 'autoExport_FRFW', 1.0)   % Worst fatigue reserve factor
setappdata(0, 'autoExport_SMAX', 1.0)   % Maximum stress in loading (SMAX)
setappdata(0, 'autoExport_SMXP', 0.0)   % SMAX/0.2% Proof Stress
setappdata(0, 'autoExport_SMXU', 0.0)   % SMAX/UTS
setappdata(0, 'autoExport_TRF', 0.0)    % Triaxiality factor
setappdata(0, 'autoExport_WCM', 1.0)    % Worst cycle mean stress
setappdata(0, 'autoExport_WCA', 1.0)    % Worst cycle stress amplitude
setappdata(0, 'autoExport_WCDP', 0.0)   % Worst cycle damage parameter
setappdata(0, 'autoExport_WCATAN', 0.0) % Worst cycle arctangent
setappdata(0, 'autoExport_YIELD', 0.0)  % Items with plastic strain energy
function [] = tutorial_B()
%TUTORIAL_B    Fatigue analysis for Tutorial B.
%   This function contains a list of job file options to define the fatigue
%   analysis for Tutorial B.
%
%   Click "Run" or press F5 to start the fatigue analysis. Output is
%   written to Project\output\tutorial_B.
%   
%   Please refer to the Quick Fatigue Tool User Guide for detailed
%   instructions on creating an analysis job.
%
%   See also environment.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4 Configuring and running an analysis
%      12 Tutorial B: Complex loading of an exhaust manifold
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      1 Job file options
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 19-Apr-2017 14:29:55 GMT

%% JOB

JOB_NAME = 'tutorial_B';

JOB_DESCRIPTION = 'Fatigue analysis of an exhaust manifold subject to combined thermo-mechanical loading';

CONTINUE_FROM = '';

DATA_CHECK = 0.0;

%% MATERIAL

MATERIAL = 'material_tutorial_B.mat';

% USE S-N DATA FOR FATIGUE ANALYSIS
%{
    0: Derived (Sf' and b)
    1: Direct (S-N data points)
%}
USE_SN = 0.0;

% SCALE S-N STRESS DATAPOINTS
SN_SCALE = 1.0;

% S-N KNOCK-DOWN FACTORS
SN_KNOCK_DOWN = {};

%% LOADING

% STRESS DATASETS
DATASET = {'manifold_1.rpt', 'manifold_2.rpt', 'manifold_3.rpt'};

% LOAD HISTORIES
%{
    HISTORY = [] if loading is dataset sequence
%}
HISTORY = [];

% FEA UNITS
%{
    0: User-defined
    1: Pa
    2: kPa
    3: MPa
    4: psi
    5: ksi
    6: Msi
%}
UNITS = 3.0;

%{
    [Pa] = CONV * [model]
%}
CONV = [];

% LOADING EQUIVALENCE
LOAD_EQ = {1.0, 'Repeats'};

% LOAD SCALE FACTORS
SCALE = [1.4, 1.75, 1.4];

% LOAD OFFSET VALUES
OFFSET = [];

% LOAD REPEATS
REPEATS = 1.0;

%% HIGH FREQUENCY LOADINGS

 HF_DATASET = [];
 
 HF_HISTORY = [];

% HF_DATASET = 'manifold_1.rpt';
% 
% HF_HISTORY = 'manifold_history_hf.dat';

%{
    HT_TIME = {[LOW_FREQUENCY_PERIOD], [HI_FREQUENCY_PERIOD]};
%}
HF_TIME = {100, 10};

% SCALE FACTORS FOR HIGH FREQUENCY DATASETS
HF_SCALE = 1.0;

%% ABAQUS RPT / DATASET FILE

%{
    0: Allow dataset files with 3D stress elements only
    1: Allow dataset files with plane stress elements
%}
PLANE_STRESS = 0.0;

%% ANALYSIS

% ANALYSIS GROUPS
GROUP = {'DEFAULT'};

% ANALYSIS ALGORITHM
%{
    0: Default
    3: Uniaxial Stress-Life
    4: Stress-based Brown-Miller (CP)
    5: Normal Stress (CP)
    6: Findley's Method (CP)
    7: Stress Invariant Parameter
    8: BS 7608 Fatigue of welded steel joints (CP)
    9: NASALIFE
%}
ALGORITHM = 0.0;

% MEAN STRESS CORRECTION
%{
    0: Default
    1: Morrow
    2: Goodman
    3: Soderberg
    4: Walker
    5: Smith-Watson-Topper
    6: Gerber
    7: R-ratio S-N curves
    8: None
    <filename>.msc: User-defined
%}
MS_CORRECTION = 0.0;

% ITEMS TO ANALYSE
%{
    'ALL': Whole model
    'PEEK': Item with largest (S1-S3)
    'hotspots_<jobName>.dat': Hotspot region
    n: User-defined list
%}
ITEMS = 'ALL';

%{
    'CAEL': Endurance limit (defined in material)
    n: Nf (repeats)
%}
DESIGN_LIFE = 'CAEL';

% FACTOR OF STRENGTH ALGORITHM
FACTOR_OF_STRENGTH = 0.0;

% FATIGUE RESERVE FACTOR ENVELOPE
%{
    1: Goodman (Default)
    2: Goodman B
    3: Gerber
    <filename>.msc: User-defined
%}
FATIGUE_RESERVE_FACTOR = 1.0;

% SAVE ITEMS BELOW DESIGN LIFE
HOTSPOT = 0.0;

%% SURFACE FINISH / NOTCH EFFECTS
%{
    n: Define Kt as a value
    '<filename>.kt': Select surface finish from list (DATA/KT/*.kt)
    '<filename>.ktx': Define surface finish as a value (DATA/KT/*.ktx)
%}
KT_DEF = 1.0;

%{
    If KT_DEF is a '.kt' file, KT_CURVE is the surface finish as Ra
    See 'kt_curves.m' for a description of available Kt curves

    If KT_DEF is a '.ktx' file, KT_CURVE is the surface finish as Rz
    See 'ktx_curves.m' for a description of available Ktx curves
%}
KT_CURVE = [];

% FATIGUE NOTCH FACTOR
NOTCH_CONSTANT = [];

NOTCH_RADIUS = [];

% IN-PLANE RESIDUAL STRESS
RESIDUAL = 10.0;

%% VIRTUAL STRAIN GAUGES

GAUGE_LOCATION = {};

GAUGE_ORIENTATION = {};

%% OUTPUT REQUESTS

OUTPUT_FIELD = 1.0;

OUTPUT_HISTORY = 0.0;

OUTPUT_FIGURE = 0.0;

%% ABAQUS ODB INTERFACE

% ASSOCIATE THE JOB WITH AN ABAQUS OUTPUT DATABASE (.ODB) FILE
OUTPUT_DATABASE = [];

PART_INSTANCE = 'PART-1-1';

EXPLICIT_FEA = 0.0;

STEP_NAME = [];

RESULT_POSITION = 'ELEMENT NODAL';

%% BS 7608 WELD DEFINITION

% WELD CLASSIFICATION
WELD_CLASS = 'B';

% WELD MATERIAL
YIELD_STRENGTH = [];

UTS = [];

% PROBABILITY OF FAILURE
DEVIATIONS_BELOW_MEAN = 0.0;

% FAILURE TYPE
FAILURE_MODE = 'NORMAL';

% CORRECTION FACTORS
CHARACTERISTIC_LENGTH = [];

SEA_WATER = 0.0;

%% ADDITIONAL MATERIAL DATA

% BASQUIN FATIGUE STRENGTH EXPONENT AT LIVES ABOVE S-N KNEE POINT
B2 = [];

% LIFE ABOVE WHICH TO USE B2
B2_NF = [];

% ULTIMATE COMPRESSIVE STRENGTH
UCS = [];

%% - DO NOT EDIT
flags = {ITEMS, UNITS, SCALE, REPEATS, USE_SN, DESIGN_LIFE, ALGORITHM,...
    MS_CORRECTION, LOAD_EQ, PLANE_STRESS, SN_SCALE, OUTPUT_FIELD,...
    OUTPUT_HISTORY, OUTPUT_FIGURE, B2, B2_NF, KT_DEF, KT_CURVE, RESIDUAL,...
    WELD_CLASS, DEVIATIONS_BELOW_MEAN, CHARACTERISTIC_LENGTH, SEA_WATER,...
    YIELD_STRENGTH, FAILURE_MODE, UTS, CONV, OUTPUT_DATABASE, PART_INSTANCE,...
    UCS, OFFSET, STEP_NAME, FACTOR_OF_STRENGTH, GROUP, HOTSPOT, SN_KNOCK_DOWN,...
    EXPLICIT_FEA, RESULT_POSITION, CONTINUE_FROM, DATA_CHECK, NOTCH_CONSTANT,...
    NOTCH_RADIUS, GAUGE_LOCATION, GAUGE_ORIENTATION, JOB_NAME,...
    JOB_DESCRIPTION, MATERIAL, DATASET, HISTORY, HF_DATASET, HF_HISTORY,...
    HF_TIME, HF_SCALE, FATIGUE_RESERVE_FACTOR};

main(flags)
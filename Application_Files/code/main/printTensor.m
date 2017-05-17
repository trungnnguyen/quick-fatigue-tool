function [] = printTensor(Sxx, Syy, Szz, Txy, Tyz, Txz)
%printTensor    QFT function to print tensor components to a text file.
%    This function contains code to print tensor components to a text file
%    during a data check analysis.
%
%    printTensor is used internally by Quick Fatigue Tool. The user is not
%    required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4.2 Configuring a data check analysis
%    
%    Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%    Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%% Get the maximum tensor components
s11 = max(Sxx, [], 2.0);
s22 = max(Syy, [], 2.0);
s33 = max(Szz, [], 2.0);
s12 = max(Txy, [], 2.0);
s13 = max(Txz, [], 2.0);
s23 = max(Tyz, [], 2.0);

[A, ~] = size(s11);
if A > 1.0
    s11 = s11';
    s22 = s22';
    s33 = s33';
    s12 = s12';
    s13 = s13';
    s23 = s23';
end

%% Get the principal stresses
s1 = getappdata(0, 'S1');
s3 = getappdata(0, 'S3');

% Take the maximum principal value for each item
s1 = max(s1, [], 2.0);
s3 = min(s3, [], 2.0);

[A, ~] = size(s1);
if A > 1.0
    s1 = s1';
    s3 = s3';
end

%% Get the analysis IDs
mainID = getappdata(0, 'mainID');
subID = getappdata(0, 'subID');

[A, ~] = size(mainID);
if A > 1.0
    mainID = mainID';
    subID = subID';
end

%% Worst principal file
% Concatenate field data
data = [mainID; subID; s1; s3]';

dir = [getappdata(0, 'outputDirectory'), 'Data Files/datacheck_principal.dat'];

fid = fopen(dir, 'w+');

fprintf(fid, 'WORST PRINCIPAL STRESS [WHOLE MODEL]\r\nJob:\t%s\r\nUnits:\tMPa\r\n', getappdata(0, 'jobName'));

fprintf(fid, 'Main ID\tSub ID\tMax. Principal\tMin. Principal\r\n');
fprintf(fid, '%.0f\t%.0f\t%.4f\t%.4f\r\n', data');

fclose(fid);

%% Worst tensor file
% Concatenate field data
data = [mainID; subID; s11; s22; s33; s12; s13; s23]';

dir = [getappdata(0, 'outputDirectory'), 'Data Files/datacheck_tensor.dat'];

fid = fopen(dir, 'w+');

fprintf(fid, 'WORST TENSOR [WHOLE MODEL]\r\nJob:\t%s\r\nUnits:\tMPa\r\n', getappdata(0, 'jobName'));

fprintf(fid, 'Main ID\tSub ID\tS11\tS22\tS33\tS12\tS13\tS23\r\n');
fprintf(fid, '%.0f\t%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');

fclose(fid);
function [] = evaluateMaterial(fileName, material, error)
%EVALUATEMATERIAL    QFT function to evaluate material data.
%   This function evaluates a material defined in the Material Manager app.
%   
%   EVALUATEMATERIAL is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also kSolution, MaterialManager, UserMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%% Check for errors
switch error
    case 1.0
        message = sprintf('Material ''%s'' could not be found.', [material, '.mat']);
        errordlg(message, 'Quick Fatigue Tool')
        return
    case 2.0
        message = sprintf('Material ''%s'' could not be opened.', [material, '.mat']);
        errordlg(message, 'Quick Fatigue Tool')
        return
    case 3.0
        message = sprintf('Evaluation failed due to a syntax error in ''%s''.', [material, '.mat']);
        errordlg(message, 'Quick Fatigue Tool')
        return
    case 4.0
        message = sprintf('Evaluation failed due to insufficient material data.');
        errordlg(message, 'Quick Fatigue Tool')
        return
    otherwise
end

%% Open file for writing
% If the output directory  does not exist, create it
if exist('Project/output/material_reports/', 'dir') == 0.0
    mkdir('Project/output/material_reports/')
end

fid = fopen(fileName, 'w+');

fprintf(fid, 'PROPERTY\tVALUE\tSTATUS\r\n\r\n');

%% BASIC
fprintf(fid, '[Basic]\r\n');

fprintf(fid, 'Name:\t%s\t(User-defined)\r\n', material);

fprintf(fid, 'Description:\t%s\t(User-defined)\r\n', getappdata(0, 'materialDescription'));

% DEFAULT ALGORITHM
switch getappdata(0, 'defaultAlgorithm')
    case 1.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Brown-Miller');
    case 2.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Principal Strain');
    case 3.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Maximum Shear Strain');
    case 4.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Stress-based Brown-Miller');
    case 5.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Principal Stress');
    case 6.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Findley''s Method');
    case 7.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'von Mises');
    case 8.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'MMMcK NASALife');
    case 9.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'MMMcK Filipini');
    case 10.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Uniaxial Strain-Life');
    case 11.0
        fprintf(fid, 'Default analysis algorithm:\t%s\t(User-defined)\r\n', 'Uniaxial Stress-Life');
end

% DEFAULT MSC
if getappdata(0, 'defaultAlgorithm') == 6.0
    fprintf(fid, 'Default mean stress correction:\t%s\t(Default)\r\n', 'Built-in');
else
    switch getappdata(0, 'defaultMSC')
        case 1.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'Morrow');
        case 2.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'Goodman');
        case 3.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'Walker');
        case 4.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'Smith-Watson-Topper');
        case 5.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'Gerber');
        case 6.0
            fprintf(fid, 'Default mean stress correction:\t%s\t(User-defined)\r\n', 'None');
    end
end

% CAEL
switch getappdata(0, 'cael_status')
    case 0.0
        fprintf(fid, 'Constant amplitude endurance limit:\t%.3e\t(User-defined)\r\n', getappdata(0, 'cael'));
    case 2.0
        fprintf(fid, 'Constant amplitude endurance limit:\t%.3e\t(Default)\r\n', getappdata(0, 'cael'));
    otherwise
        fprintf(fid, 'Constant amplitude endurance limit:\t-\tERROR\r\n');
end

% MATERIAL BEHAVIOR
switch getappdata(0, 'materialBehavior')
    case 1.0
        fprintf(fid, 'Material behaviour:\t%s\t(User-defined)\r\n', 'Plain Alloy/Steel');
    case 2.0
        fprintf(fid, 'Material behaviour:\t%s\t(User-defined)\r\n', 'Aluminium/titanium alloy');
    case 3.0
        fprintf(fid, 'Material behaviour:\t%s\t(User-defined)\r\n', 'Other');
end

% REGRESSION MODEL
switch getappdata(0, 'regressionModel')
    case 1.0
        fprintf(fid, 'Regression model:\t%s\t(User-defined)\r\n\r\n', 'Uniform Law (Baumel & Seeger)');
    case 2.0
        fprintf(fid, 'Regression model:\t%s\t(User-defined)\r\n\r\n', 'Universal Slopes (Manson)');
    case 3.0
        fprintf(fid, 'Regression model:\t%s\t(User-defined)\r\n\r\n', 'Modified Universal Slopes (Muralidharan)');
    case 4.0
        fprintf(fid, 'Regression model:\t%s\t(User-defined)\r\n\r\n', '90/50 Rule');
end

%% MECHANICAL
fprintf(fid, '[Mechanical]\r\n');

% E
switch getappdata(0, 'E_status')
    case 0.0
        fprintf(fid, 'Young''s modulus (E):\t%.3f\t(User-defined)\r\n', getappdata(0, 'E'));
    case -1.0
        fprintf(fid, 'Young''s modulus (E):\t-\t(Undefined)\r\n');
    otherwise
        fprintf(fid, 'Young''s modulus (E):\t-\tERROR\r\n');
end

% UTS
switch getappdata(0, 'uts_status')
    case 0.0
        fprintf(fid, 'Ultimate tensile strength (UTS):\t%.3f\t(User-defined)\r\n', getappdata(0, 'uts'));
    case -1.0
        fprintf(fid, 'Ultimate tensile strength (UTS):\t-\t(Undefined)\r\n');
    otherwise
        fprintf(fid, 'Ultimate tensile strength (UTS):\t-\tERROR\r\n');
end

% TWOPS
switch getappdata(0, 'twops_status')
    case -1.0
        fprintf(fid, '0.2%% Proof stress:\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, '0.2%% Proof stress:\t%.3f\t(User-defined)\r\n', getappdata(0, 'twops'));
    case 1.0
        fprintf(fid, '0.2%% Proof stress:\t%.3f\t(Derived)\r\n', getappdata(0, 'twops'));
    otherwise
        fprintf(fid, '0.2%% Proof stress:\t-\tERROR\r\n');
end

% POISSON
switch getappdata(0, 'poisson_status')
    case 0.0
        fprintf(fid, 'Poisson''s ratio:\t%.3f\t(User-defined)\r\n\r\n', getappdata(0, 'poisson'));
    case 2.0
        fprintf(fid, 'Poisson''s ratio:\t%.3f\t(Default)\r\n\r\n', getappdata(0, 'poisson'));
    otherwise
        fprintf(fid, 'Poisson''s ratio:\t-\tERROR\r\n\r\n');
end

%% FATIGUE
fprintf(fid, '[Fatigue]\r\n');

% SF
switch getappdata(0, 'Sf_status')
    case -1.0
        fprintf(fid, 'Fatigue strength coefficient (Sf):\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, 'Fatigue strength coefficient (Sf):\t%.3f\t(User-defined)\r\n', getappdata(0, 'Sf'));
    case 1.0
        fprintf(fid, 'Fatigue strength coefficient (Sf):\t%.3f\t(Derived)\r\n', getappdata(0, 'Sf'));
    otherwise
        fprintf(fid, 'Fatigue strength coefficient (Sf):\t-\tERROR\r\n');
end

% B
switch getappdata(0, 'b_status')
    case -1.0
        fprintf(fid, 'Fatigue strength exponent (b):\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, 'Fatigue strength exponent (b):\t%.3f\t(User-defined)\r\n', getappdata(0, 'b'));
    case 1.0
        fprintf(fid, 'Fatigue strength exponent (b):\t%.3f\t(Derived)\r\n', getappdata(0, 'b'));
    otherwise
        fprintf(fid, 'Fatigue strength exponent (b):\t-\tERROR\r\n');
end

% EF
switch getappdata(0, 'Ef_status')
    case -1.0
        fprintf(fid, 'Fatigue ductility coefficient (Ef):\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, 'Fatigue ductility coefficient (Ef):\t%.3f\t(User-defined)\r\n', getappdata(0, 'Ef'));
    case 1.0
        fprintf(fid, 'Fatigue ductility coefficient (Ef):\t%.3f\t(Derived)\r\n', getappdata(0, 'Ef'));
    otherwise
        fprintf(fid, 'Fatigue ductility coefficient (Ef):\t-\tERROR\r\n');
end

% C
switch getappdata(0, 'c_status')
    case -1.0
        fprintf(fid, 'Fatigue ductility exponent (c):\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, 'Fatigue ductility exponent (c):\t%.3f\t(User-defined)\r\n\r\n', getappdata(0, 'c'));
    case 1.0
        fprintf(fid, 'Fatigue ductility exponent (c):\t%.3f\t(Derived)\r\n\r\n', getappdata(0, 'c'));
    otherwise
        fprintf(fid, 'Fatigue ductility exponent (c):\t-\tERROR\r\n\r\n');
end

%% CYCLIC
fprintf(fid, '[Cyclic]\r\n');

% KP
switch getappdata(0, 'kp_status')
    case -1.0
        fprintf(fid, 'Strain hardening coefficient (K):\t-\t(Undefined)\r\n');
    case 0.0
        fprintf(fid, 'Strain hardening coefficient (K):\t%.0f\t(User-defined)\r\n', getappdata(0, 'kp'));
    case 1.0
        fprintf(fid, 'Strain hardening coefficient (K):\t%.0f\t(Derived)\r\n', getappdata(0, 'kp'));
    otherwise
        fprintf(fid, 'Strain hardening coefficient (K):\t-\tERROR\r\n');
end

% NP
switch getappdata(0, 'np_status')
    case -1.0
        fprintf(fid, 'Strain hardening exponent (n):\t-\t(Undefined)\r\n\r\n');
    case 0.0
        fprintf(fid, 'Strain hardening exponent (n):\t%.3f\t(User-defined)\r\n\r\n', getappdata(0, 'np'));
    case 1.0
        fprintf(fid, 'Strain hardening exponent (n):\t%.3f\t(Derived)\r\n\r\n', getappdata(0, 'np'));
    otherwise
        fprintf(fid, 'Strain hardening exponent (n):\t-\tERROR\r\n\r\n');
end

%% NON-STANDARD
fprintf(fid, '[Non-standard]\r\n');

switch getappdata(0, 'k_status')
    case 0.0
        fprintf(fid, 'Normal stress sensitivity constant (k):\t%.4f\t(User-defined)\r\n', getappdata(0, 'k'));
    case 1.0
        fprintf(fid, 'Normal stress sensitivity constant (k):\t%.4f\t(Derived)\r\n', getappdata(0, 'k'));
    case 2.0
        fprintf(fid, 'Normal stress sensitivity constant (k):\t%.4f\t(Default)\r\n', getappdata(0, 'k'));
    otherwise
        fprintf(fid, 'Normal stress sensitivity constant (k):\t-\tERROR\r\n');
end

%% Close the file
fclose(fid);
end
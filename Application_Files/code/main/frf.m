function [] = frf(algorithm, msCorrection, N, mainID, subID, use_sn)
%FRF    QFT function to calculate Fatigue Reserve Factor.
%   This function calculates the Fatigue Reserve Factor (FRF) of the
%   fatigue loading.
%   
%   FRF is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      8.2 Fatigue Reserve Factor
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%% INITIALIZE THE FRF CALCULATION

% User FRF diagnostics
frfDiagnostics = getappdata(0, 'frfDiagnostics');
outputFigure = getappdata(0, 'outputFigure');

% Initialize the FRF variables
frfR = linspace(-1.0, -1.0, N);
frfH = linspace(-1.0, -1.0, N);
frfV = linspace(-1.0, -1.0, N);
frfW = linspace(-1.0, -1.0, N);

% Get the envelope settings for the FRF
frfMinValue = getappdata(0, 'frfMinValue');
frfMaxValue = getappdata(0, 'frfMaxValue');

% Get the worst mean stress and stress amplitude for each analysis item
if algorithm == 6.0
    Sa = getappdata(0, 'WCDP');
else
    Sa = getappdata(0, 'WCA');
end

Sm = getappdata(0, 'WCM');

% Get the number of groups
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Get the normalization parameters
frfNormParamMeanT = getappdata(0, 'frfNormParamMeanT');
frfNormParamMeanC = getappdata(0, 'frfNormParamMeanC');

% Warning flag in case UTS is undefined in any group
utsWarn = getappdata(0, 'utsWarn');

% If the UTS is undefined for any group, do not calculate the FRF
frfError = 0.0;
for groups = 1:G
    % Assign group parameters to the current set of analysis IDs
    group.switchProperties(groups, groupIDBuffer(groups));
    frfEnvelope = getappdata(0, 'frfEnvelope');
    
    if frfEnvelope == -1.0
        if ((strcmpi(frfNormParamMeanT{groups}, 'UTS') == 1.0 || strcmpi(frfNormParamMeanT{groups}, 'UCS') == 1.0)) && (utsWarn == 1.0)
            frfError = 1.0;
            break
        end
        
        if (strcmpi(frfNormParamMeanC{groups}, 'UTS') == 1.0 || strcmpi(frfNormParamMeanC{groups}, 'UCS') == 1.0) && (utsWarn == 1.0)
            frfError = 1.0;
            break
        end
    elseif utsWarn == 1.0
        frfError = 1.0;
        break
    end
end

if frfError == 1.0
    setappdata(0, 'FRFR', frfR)
    setappdata(0, 'FRFH', frfH)
    setappdata(0, 'FRFV', frfV)
    setappdata(0, 'FRFW', frfW)
    
    messenger.writeMessage(125.0)
    
    return
end

% Total counter
totalCounter = 0.0;

% Set failed FRF groups
failedFRFGroups = 0.0;

% Get the user FRF interpolation order
interpolationOrder = getappdata(0, 'frfInterpOrder');

% Get the FRF target definition
So_i = zeros(1.0, G);
frfTarget = getappdata(0, 'frfTarget');
% Get the target life
switch frfTarget
    case 1.0
        targetLife = getappdata(0, 'dLife');
    case 2.0
        group_materialProps = getappdata(0, 'group_materialProps');
        for i = 1:G
            So_i(i) = group_materialProps(i).fatigueLimit';
        end
    otherwise
        group_materialProps = getappdata(0, 'group_materialProps');
        for i = 1:G
            So_i(i) = group_materialProps(i).fatigueLimit';
        end
end

for groups = 1:G
    %{
        If the analysis is a PEEK analysis, override the value of GROUP to
        the group containing the PEEK item
    %}
    if getappdata(0, 'peekAnalysis') == 1.0
        groups = getappdata(0, 'peekGroup'); %#ok<FXSET>
    end
    
    % Assign group parameters to the current set of analysis IDs
    [N, ~] = group.switchProperties(groups, groupIDBuffer(groups));
    
    % Get the current FRF envelope
    frfEnvelope = getappdata(0, 'frfEnvelope');
    
    % Get the normalization parameters
    frfNormParamMeanT = getappdata(0, 'frfNormParamMeanT');
    frfNormParamMeanC = getappdata(0, 'frfNormParamMeanC');
    frfNormParamAmp = getappdata(0, 'frfNormParamAmp');
    
    % Get the current UTS
    uts = getappdata(0, 'uts');
    ucs = getappdata(0, 'ucs');
    
    % Get the residual stress for the group
    residual = getappdata(0, 'residualStress');
    
    % Define a UCS for the group
    if isempty(ucs) == 1.0
        ucs = uts;
    end
    
    % Get the proof stress for the current group
    proof = getappdata(0, 'twops');
    
    %{
        If the Goodman B envelope is requested, but the proof stress is
        undefined for the current group, switch to the standard Goodman
        envelope
    %}
    if frfEnvelope == 2.0 && isempty(proof) == 1.0
        frfEnvelope = 1.0;
        setappdata(0, 'message_234_group', groups)
        messenger.writeMessage(234.0)
    end
    
    % Get S-N coefficients
    Sf = getappdata(0, 'Sf');
    b = getappdata(0, 'b');
    
    % Get S-N data
    n_values = getappdata(0, 'n_values');
    if getappdata(0, 'nSNDatasets') > 1.0
        s_values = getappdata(0, 's_values_reduced');
    else
        s_values = getappdata(0, 's_values');
    end
    
    %{
        Calculate the maximum stress amplitude at zero mean stress

        This is the intercept of the infinite life envelope of the y-axis
        on the Haigh diagram
    %}
    
    %{
        The fatigue limit stress was calculated before the start of the
        analysis based on either the material CAEL or a user-defined value.
        Only re-calculate the fatigue limit stress if the FRF target is set
        to the user-defined design life
    %}
    if frfTarget == 1.0
        % Get the conditional stress based on the target life
        if use_sn == 1.0
            So = 10^(interp1(log10(n_values), log10(s_values), log10(targetLife), 'linear', 'extrap'));
        else
            switch algorithm
                case 3.0 % Uniaxial Stress-Life
                    So = Sf*((2.0*targetLife)^b);
                case 4.0 % Stress-based Brown-Miller
                    Ef = getappdata(0, 'Ef');
                    c = getappdata(0, 'c');
                    E = getappdata(0, 'E');
                    
                    if getappdata(0, 'plasticSN') == 1.0 && (~isempty(Ef) && ~isempty(c))
                        switch msCorrection
                            case 1.0 % Morrow
                                morrowSf = min(getappdata(0, 'worstNodeMorrowSf'));
                                
                                So = E*(((1.65*morrowSf)/(E)).*(2.0*targetLife)^b + (1.75*Ef)*(2.0*targetLife)^c);
                            otherwise % Other/None
                                So = E*(((1.65*Sf)/(E))*(2.0*targetLife)^b + (1.75*Ef)*(2.0*targetLife)^c);
                        end
                    else
                        switch msCorrection
                            case 1.0 % Morrow
                                morrowSf = min(getappdata(0, 'worstNodeMorrowSf'));
                                
                                So = (1.65*morrowSf)*(2.0*targetLife)^b;
                            otherwise % Other/None
                                So = (1.65*Sf)*(2.0*targetLife)^b;
                        end
                    end
                case 5.0 % Principal Stress
                    switch msCorrection
                        case 1.0 % Morrow
                            morrowSf = min(getappdata(0, 'worstNodeMorrowSf'));
                            
                            So = morrowSf*((2.0*targetLife)^b);
                        otherwise % Other/None
                            So = Sf*((2.0*targetLife)^b);
                    end
                case 6.0 % Findley
                    Sf = getappdata(0, 'Tfs');
                    So = Sf*((2.0*targetLife)^b);
                case 7.0 % von Mises
                    So = Sf*((2.0*targetLife)^b);
                case 9.0 % NASALIFE
                    So = Sf*((2.0*targetLife)^b);
            end
        end
    else
        % Get the conditional stress is based on the fatigue limit of the current group
        if getappdata(0, 'peekAnalysis') == 1.0
            So = So_i;
        else
            So = So_i(groups);
        end
    end
    
    % Get user FRF data if required
    if frfEnvelope == -1.0
        frfData = getappdata(0, 'userFRFData');
        frfData_m = frfData(:, 1.0);
        frfData_a = frfData(:, 2.0);
        
        %{
            If the user FRF data contains vertical excursions, the
            interpolation will fail. Test the interpolation once at the
            start to make sure it works
        %}
        try
            interp1(frfData_m, frfData_a, Sm, interpolationOrder);
        catch exception
            if groups == 1.0
                frfR = linspace(-1.0, -1.0, N);
                frfV = linspace(-1.0, -1.0, N);
                frfH = linspace(-1.0, -1.0, N);
            else
                frfR = [frfR, linspace(-1.0, -1.0, N)]; %#ok<AGROW>
                frfV = [frfV, linspace(-1.0, -1.0, N)]; %#ok<AGROW>
                frfH = [frfH, linspace(-1.0, -1.0, N)]; %#ok<AGROW>
            end
            
            failedFRFGroups = failedFRFGroups + 1.0;
            
            setappdata(0, 'message_197_group', groups)
            setappdata(0, 'message_197_exception', exception.message)
            messenger.writeMessage(197.0)
            
            totalCounter = totalCounter + N;
            continue
        end
        
        % Resolve the normalization parameters
        if strcmpi(frfNormParamMeanT{groups}, 'uts') == 1.0
            frfNormParamMeanT_group = uts;
        elseif strcmpi(frfNormParamMeanT{groups}, 'ucs') == 1.0
            frfNormParamMeanT_group = ucs;
        elseif strcmpi(frfNormParamMeanT{groups}, 'proof') == 1.0
            if isempty(proof) == 1.0
                frfNormParamMeanT_group = uts;
            else
                frfNormParamMeanT_group = proof;
            end
        elseif ischar(frfNormParamMeanT{groups}) == 1.0
            frfNormParamMeanT_group = uts;
        end
        
        if strcmpi(frfNormParamMeanC{groups}, 'uts') == 1.0
            frfNormParamMeanC_group = uts;
        elseif strcmpi(frfNormParamMeanC{groups}, 'ucs') == 1.0
            frfNormParamMeanC_group = ucs;
        elseif strcmpi(frfNormParamMeanC{groups}, 'proof') == 1.0
            if isempty(proof) == 1.0
                frfNormParamMeanC_group = uts;
            else
                frfNormParamMeanC_group = proof;
            end
        elseif ischar(frfNormParamMeanC{groups}) == 1.0
            frfNormParamMeanC_group = ucs;
        end
        
        if strcmpi(frfNormParamAmp{groups}, 'limit') == 1.0
            frfNormParamAmp_group = So;
        elseif ischar(frfNormParamAmp{groups}) == 1.0
            frfNormParamAmp_group = So;
        end
    end
    
    %% START THE FRF CALCULATION
    
    for i = 1.0:N
        totalCounter = totalCounter + 1.0;
        
        % Get the totalCounter mean stress and stress amplitude for the current item
        Smi = Sm(totalCounter) + residual;
        Sai = Sa(totalCounter);
        
        switch frfEnvelope
            case 1.0
                %% GOODMAN
                
                % RADIAL FRF
                if Smi == 0.0
                    % Special case where the mean stress is zero
                    if Sai == 0.0
                        Ar = frfMaxValue;
                        Br = 1.0;
                    else
                        Ar = So;
                        Br = Sai;
                    end
                else
                    % The cycle falls within the Goodman envelope
                    Smi = abs(Smi);
                    
                    % Goodman line coordinates
                    SmG = So*(1.0/((Sai/Smi) + (So/uts)));
                    SaG = (Sai/Smi)*SmG;
                    
                    % Distance from the origin to the Goodman line
                    Ar = sqrt((SmG*SmG) + (SaG*SaG));
                    
                    % Distance from the origin to the cycle coordinate
                    Br = sqrt((Smi*Smi) + (Sai*Sai));
                end
                
                % Radial FRF calculation
                frfRi = Ar/Br;
                if frfRi > frfMaxValue
                    frfRi = frfMaxValue;
                elseif frfRi < frfMinValue
                    frfRi = frfMinValue;
                end
                
                frfR(totalCounter) = frfRi;
                
                % HORIZONTAL FRF
                if (Sai == 0.0) && (Sai < So)
                    %{
                        The mean stress is zero, but the cycle is not
                        touching the envelope. Bh is infinite, so take the
                        max value
                    %}
                    Ah = frfMaxValue;
                    Bh = 1.0;
                elseif Sai > So
                    % FRFH is not defined above So
                    Ah = -1.0;
                    Bh = 1.0;
                elseif Sai == So
                    if Smi == 0.0
                        % FRFH = 1.0
                        Ah = 1.0;
                        Bh = 1.0;
                    else
                        % FRFH is not defined at So for non-zero Sm
                        Ah = -1.0;
                        Bh = 1.0;
                    end
                else
                    %{
                        Intercept between the horizontal line from Sm and
                        the Goodman line
                    %}
                    Ah = uts*(1.0 - (Sai/So));
                    
                    % Distance from the y-axis to Sa
                    Bh = abs(Smi);
                end
                
                % Horizontal FRF calculation
                frfHi = Ah/Bh;
                if frfHi > frfMaxValue
                    frfHi = frfMaxValue;
                elseif (frfHi < frfMinValue) && (frfHi ~= -1.0)
                    frfHi = frfMinValue;
                end
                
                frfH(totalCounter) = frfHi;
                
                % VERTICAL FRF
                if abs(Smi) >= uts
                    % FRFV is not defined at or above uts
                    Av = -1.0;
                    Bv = 1.0;
                else
                    %{
                        Intercept between the vertical line from Sa and the
                        Goodman line
                    %}
                    Smi = abs(Smi);
                    
                    Av = So*(1.0 - (Smi/uts));
                    
                    % Distance from the x-axis to Sa
                    Bv = Sai;
                end
                
                % Vertical FRF calculation
                frfVi = Av/Bv;
                if frfVi > frfMaxValue
                    frfVi = frfMaxValue;
                elseif (frfVi < frfMinValue) && (frfVi ~= -1.0)
                    frfVi = frfMinValue;
                end
                
                frfV(totalCounter) = frfVi;
            case 2.0
                %% GOODMAN B
                
                % BUCH INTERCEPTS
                buchNegMean = So - proof;
                buchPosMean = (proof - So)/(1.0 - (So/uts));
                buchNegAmp = So;
                buchPosAmp = proof - ((proof - So)/(1.0 - (So/uts)));
                
                % LINE SIDE PARAMETER
                Dneg = (Smi - buchNegMean)*(0.0 - buchNegAmp) - (Sai - buchNegAmp)*(0.0 - buchNegMean);
                Dpos = (Smi - buchPosMean)*(0.0 - buchPosAmp) - (Sai - buchPosAmp)*(0.0 - buchPosMean);
                
                % RADIAL FRF
                if Smi < 0.0
                    % The cycle mean stress is negative
                    
                    if Dneg < 0.0
                        %{
                            Use the flat (Goodman) line between the
                            negative Buch intercept and 0.0
                        %}
                        
                        % Flat line coordinates
                        SmG = So*(Smi/Sai);
                        SaG = So;
                        
                        % Distance from the origin to the flat line
                        Ar = sqrt((SmG*SmG) + (SaG*SaG));
                    
                        % Distance from the origin to the cycle coordinate
                        Br = sqrt((Smi*Smi) + (Sai*Sai));
                    else
                        % Use the negative Buch line
                        
                        % Buch line coordinates
                        SmG = proof*(1.0/((Sai/Smi) + 1.0));
                        SaG = proof - SmG;
                        
                        % Distance from the origin to the Buch line
                        Ar = sqrt((SmG*SmG) + (SaG*SaG));
                        
                        % Distance from the origin to the cycle coordinate
                        Br = sqrt((Smi*Smi) + (Sai*Sai));
                    end
                elseif Smi == 0.0
                    % Special case where the mean stress is zero
                    if Sai == 0.0
                        Ar = frfMaxValue;
                        Br = 1.0;
                    else
                        Ar = So;
                        Br = Sai;
                    end
                else
                    if Dpos > 0.0
                        % Use the Goodman envelope
                        
                        % Goodman line coordinates
                        SmG = So*(1.0/((Sai/Smi) + (So/uts)));
                        SaG = (Sai/Smi)*SmG;
                        
                        % Distance from the origin to the Goodman line
                        Ar = sqrt((SmG*SmG) + (SaG*SaG));
                        
                        % Distance from the origin to the cycle coordinate
                        Br = sqrt((Smi*Smi) + (Sai*Sai));
                    else
                        % Use the positive Buch line
                        
                        % Buch line coordinates
                        SmG = proof*(1.0/((Sai/Smi) + 1.0));
                        SaG = proof - SmG;
                        
                        % Distance from the origin to the Buch line
                        Ar = sqrt((SmG*SmG) + (SaG*SaG));
                        
                        % Distance from the origin to the cycle coordinate
                        Br = sqrt((Smi*Smi) + (Sai*Sai));
                    end
                end
                
                % Radial FRF calculation
                frfRi = Ar/Br;
                if frfRi > frfMaxValue
                    frfRi = frfMaxValue;
                elseif frfRi < frfMinValue
                    frfRi = frfMinValue;
                end
                
                frfR(totalCounter) = frfRi;
                
                % HORIZONTAL FRF
                if Smi < 0.0
                    %{
                        The cycle mean stress falls within the negative 
                        Buch envelope
                    %}
                    
                    if Sai > So
                        % FRFH is not defined above So
                        Ah = -1.0;
                        Bh = 1.0;
                    else
                        %{
                            Intercept between the horizontal line from Sm
                            and the Buch line
                        %}
                        Ah = proof - Sai;
                        
                        % Distance from the y-axis to Sa
                        Bh = abs(Smi);
                    end
                elseif Smi == 0.0
                    % Special case where the mean stress is zero
                    if Sai > So
                        % FRFH is not defined above So
                        Ah = -1.0;
                        Bh = 1.0;
                    elseif Sai == So
                        % Cycle is on envelope; FRFH is 1.0
                        Ah = 1.0;
                        Bh = 1.0;
                    else
                        % FRFH is infinite because Bh = 0.0. Set max value
                        Ah = frfMaxValue;
                        Bh = 1.0;
                    end
                else
                    %{
                        The cycle mean stress falls within the positive 
                        Buch envelope
                    %}
                    
                    if Sai > So
                        % FRFH is not defined above So
                        Ah = -1.0;
                        Bh = 1.0;
                    elseif Sai >= buchPosAmp
                        %{
                            The cycle mean stress falls between zero and
                            the positive Buch envelope (Goodman)
                        %}
                        
                        %{
                            Intercept between the horizontal line from Sm
                            and the Goodman line
                        %}
                        Ah = uts*(1.0 - (Sai/So));
                        
                        % Distance from the y-axis to Sa
                        Bh = Smi;
                    else
                        %{
                            Intercept between the horizontal line from Sm
                            and the Buch line
                        %}
                        Ah = proof - Sai;
                        
                        % Distance from the y-axis to Sa
                        Bh = Smi;
                    end
                end
                
                % Horizontal FRF calculation
                frfHi = Ah/Bh;
                if frfHi > frfMaxValue
                    frfHi = frfMaxValue;
                elseif (frfHi < frfMinValue) && (frfHi ~= -1.0)
                    frfHi = frfMinValue;
                end
                
                frfH(totalCounter) = frfHi;
                
                % VERTICAL FRF
                if abs(Smi) >= proof
                    % FRFV is not defined at or above proof
                    Av = -1.0;
                    Bv = 1.0;
                elseif (Smi <= buchNegMean) || (Smi >= buchPosMean)
                    %{
                        The cycle mean stress falls within the positive or
                        negative Buch envelopes
                    %}
                    
                    %{
                        Intercept between the vertical line from Sa and the
                        Buch line
                    %}
                    Av = proof - abs(Smi);
                    
                    % Distance from the x-axis to Sa
                    Bv = Sai;
                elseif (Smi > buchNegMean) && (Smi <= 0.0)
                    %{
                        The cycle mean stress falls between the negative
                        Buch envelope and zero
                    %}
                    
                    %{
                        Intercept between the vertical line from Sa and the
                        Goodman (flat) line
                    %}
                    Av = So;
                    
                    % Distance from the x-axis to Sa
                    Bv = Sai;
                else
                    %{
                        The cycle mean stress falls between zero and the
                        positive Buch envelope (Goodman)
                    %}
                    
                    %{
                        Intercept between the vertical line from Sa and the
                        Goodman line
                    %}
                    Av = So*(1.0 - (Smi/uts));
                    
                    % Distance from the x-axis to Sa
                    Bv = Sai;
                end
                
                % Vertical FRF calculation
                frfVi = Av/Bv;
                if frfVi > frfMaxValue
                    frfVi = frfMaxValue;
                elseif (frfVi < frfMinValue) && (frfVi ~= -1.0)
                    frfVi = frfMinValue;
                end
                
                frfV(totalCounter) = frfVi;
            case 3.0
                %% GERBER
                
                % RADIAL FRF
                if Smi == 0.0
                    % Special case where the mean stress is zero
                    if Sai == 0.0
                        Ar = frfMaxValue;
                        Br = 1.0;
                    else
                        Ar = So;
                        Br = Sai;
                    end
                else
                    % The cycle falls within the well-defined envelope
                    Smi = abs(Smi);
                    
                    % Gerber line coordinates
                    a = So/uts;
                    b = Sai/Smi;
                    c = -So;
                    SmG = (-b + sqrt(b^2 - (4*a*c)))/(2*a);
                    SaG = (Sai/Smi)*SmG;
                    
                    % Distance from the origin to the Gerber line
                    Ar = sqrt((SmG*SmG) + (SaG*SaG));
                    
                    % Distance from the origin to the cycle coordinate
                    Br = sqrt((Smi*Smi) + (Sai*Sai));
                end
                
                % Radial FRF calculation
                frfRi = Ar/Br;
                if frfRi > frfMaxValue
                    frfRi = frfMaxValue;
                elseif frfRi < frfMinValue
                    frfRi = frfMinValue;
                end
                
                frfR(totalCounter) = frfRi;
                
                % HORIZONTAL FRF
                if (Sai == 0.0) && (Sai < So)
                    %{
                        The mean stress is zero, but the cycle is not
                        touching the envelope. Bh in infinite, so take the
                        max value
                    %}
                    Ah = frfMaxValue;
                    Bh = 1.0;
                elseif Sai > So
                    % FRFH is not defined above So
                    Ah = -1.0;
                    Bh = 1.0;
                elseif Sai == So
                    if Smi == 0.0
                        % FRFH = 1.0
                        Ah = 1.0;
                        Bh = 1.0;
                    else
                        % FRFH is not defined at So for non-zero Sm
                        Ah = -1.0;
                        Bh = 1.0;
                    end
                else
                    %{ 
                        Intercept between the horizontal line from Sm and
                        the Gerber line
                    %}
                    Ah = sqrt((uts^2/So)*(So - Sai));
                    
                    % Distance from the y-axis to Sa
                    Bh = abs(Smi);
                end
                
                % Horizontal FRF calculation
                frfHi = Ah/Bh;
                if frfHi > frfMaxValue
                    frfHi = frfMaxValue;
                elseif (frfHi < frfMinValue) && (frfHi ~= -1.0)
                    frfHi = frfMinValue;
                end
                
                frfH(totalCounter) = frfHi;
                
                % VERTICAL FRF
                if abs(Smi) >= uts
                    % FRFV is not defined at or above uts
                    Av = -1.0;
                    Bv = 1.0;
                else
                    %{
                        Intercept between the vertical line from Sa and the
                        Gerber line
                    %}
                    Av = So*(1.0 - (Smi^2/uts^2));
                    
                    % Distance from the x-axis to Sa
                    Bv = Sai;
                end
                
                % Vertical FRF calculation
                frfVi = Av/Bv;
                if frfVi > frfMaxValue
                    frfVi = frfMaxValue;
                elseif (frfVi < frfMinValue) && (frfVi ~= -1.0)
                    frfVi = frfMinValue;
                end
                
                frfV(totalCounter) = frfVi;
            case -1.0
                %% USER-DEFINED
                
                %{
                    Normalize the cycle by the UTS/So or user-defined FRF
                    normalization parameters
                %}
                if Smi > 0.0
                    if strcmpi(frfNormParamMeanT_group, 'uts') == 1.0
                        Smi = Smi/uts;
                    else
                        Smi = Smi/frfNormParamMeanT_group;
                    end
                end
                
                if Smi < 0.0
                    if strcmpi(frfNormParamMeanC_group, 'ucs') == 1.0
                        Smi = Smi/ucs;
                    else
                        Smi = Smi/frfNormParamMeanC_group;
                    end
                end
                
                if strcmpi(frfNormParamAmp_group, 'limit') == 1.0
                    Sai = Sai/getappdata(0, 'fatigueLimit');
                else
                    Sai = Sai/frfNormParamAmp_group;
                end
                
                % Get the amplitude values at zero mean stress
                So = frfData_a(frfData_m == 0.0);
                
                % RADIAL FRF
                if Smi == 0.0
                    %{
                        Special case where the mean stress is zero. The
                        radial FRF is just the vertical FRF
                    %}
                    if Sai == 0.0
                        Ar = frfMaxValue;
                        Br = 1.0;
                    else
                        Ar = So;
                        Br = Sai;
                    end
                else
                    % The cycle falls within the well-defined envelope
                    
                    %{
                        Only consider the side of the FRF data
                        corresponding to the sign of the cycle mean stress.
                        This ensures that the radial line faces the correct
                        direction
                    %}
                    
                    if Smi >= 0.0
                        positiveM = frfData_m >= 0.0;
                        frfData_a_side = frfData_a(positiveM);
                        frfData_m_side = frfData_m(frfData_m >= 0.0);
                    else
                        negativeM = frfData_m <= 0.0;
                        frfData_a_side = frfData_a(negativeM);
                        frfData_m_side = frfData_m(frfData_m <= 0.0);
                    end
                    
                    %{
                        If there is no FRF data on this side of the Sa
                        axis, set the FRF value to -1.0
                    %}
                    if isempty(frfData_a_side) == 1.0
                        Ar = -1.0;
                        Br = 1.0;
                    else
                        % Gradient of radial line of the cycle
                        mo = Sai/Smi;
                        
                        found = 0.0;
                        for c = 1:length(frfData_a_side) - 1.0
                            %{
                                For each pair of User-defined FRF data
                                points, derive the straight line between
                                that pair and find the intersection of the
                                radial line with this line
                            %}
                            
                            % Gradient of the current line
                            m = (frfData_a_side(c) - frfData_a_side(c + 1.0))/(frfData_m_side(c) - frfData_m_side(c + 1.0));
                            
                            % Coordinates of the intercept with the radial
                            SmU = (m*frfData_m_side(c) - frfData_a_side(c))/(m - mo);
                            SaU = mo*SmU;
                            
                            %{
                                Check if the current intercept lies between
                                the two User-defined FRF data points on the
                                straight line
                            %}
                            if ((SmU <= frfData_m_side(c) && SmU >= frfData_m_side(c + 1.0)) || (SmU >= frfData_m_side(c) && SmU <= frfData_m_side(c + 1.0))) ...
                                    && ((SaU <= frfData_a_side(c) && SaU >= frfData_a_side(c + 1.0)) || (SaU >= frfData_a_side(c) && SaU <= frfData_a_side(c + 1.0)))
                                % The correct intercept has been found
                                found = 1.0;
                                break
                            end
                        end
                        
                        if found == 0.0
                            %{
                                A valid intercept could not be found, so
                                assign a value of -1.0 to the current node
                            %}
                            Ar = -1.0;
                            Br = 1.0;
                        else
                            %{
                                Re-interpolate the user-defined FRF data
                                according to the user-specified
                                interpolation order
                            %}
                            
                            if (length(frfData_m_side) < 2.0) || (length(frfData_a_side) < 2.0)
                                Ar = -1.0;
                                Br = 0.0;
                            else
                                SaU = interp1(frfData_m_side, frfData_a_side, SmU, interpolationOrder);
                                SmU = interp1(frfData_a_side, frfData_m_side, SaU, interpolationOrder);
                                
                                % Distance from the origin to the User-defined line
                                Ar = sqrt((SmU*SmU) + (SaU*SaU));
                                
                                % Distance from the origin to the cycle coordinate
                                Br = sqrt((Smi*Smi) + (Sai*Sai));
                            end
                        end
                    end
                end
                
                % Radial FRF calculation
                frfRi = Ar/Br;
                if frfRi > frfMaxValue
                    frfRi = frfMaxValue;
                elseif (frfRi < frfMinValue) && (frfRi ~= -1.0)
                    frfRi = frfMinValue;
                end
                
                frfR(totalCounter) = frfRi;
                
                % DEBUG: Plot the current cycle on a Haigh diagram
                if (any(totalCounter == frfDiagnostics) == 1.0) && (outputFigure == 1.0)
                    mscFileUtils.plotUserFRFCycle(Smi, Sai, frfData_m, frfData_a, totalCounter)
                end
                
                % HORIZONTAL FRF
                if (Smi == 0.0) && (Sai < So)
                    %{
                        The mean stress is zero, but the cycle is not
                        touching the envelope. Bh is zero, so take the max
                        value
                    %}
                    
                    Ah = frfMaxValue;
                    Bh = 1.0;
                elseif Sai > max(frfData_a)
                    % FRFH is not defined above the largest Sa value
                    Ah = -1.0;
                    Bh = 1.0;
                elseif Sai == So
                    if Smi == 0.0
                        % FRFH = 1.0
                        Ah = 1.0;
                        Bh = 1.0;
                    else
                        % FRFH is not defined at So for non-zero Sm
                        Ah = -1.0;
                        Bh = 1.0;
                    end
                elseif Sai == max(frfData_a)
                    if (Smi == 0.0) && (So == max(frfData_a))
                        %{
                            The mean stress is zero, and the cycle is
                            touching the envelope. FRFH = 1.0
                        %}
                        Ah = 1.0;
                        Bh = 1.0;
                    else
                        amplitudeIndexes = frfData_a == max(frfData_a);
                        meanStresses = frfData_m(amplitudeIndexes);
                        L = ismember(Smi, meanStresses);
                        
                        if L == 1.0
                            %{
                                The mean stress is non-zero, but the cycle
                                is still touching the envelope. FRFH = 1.0
                            %}
                            Ah = 1.0;
                            Bh = 1.0;
                        else
                            % FRFH is undefined
                            Ah = -1.0;
                            Bh = 1.0;
                        end
                    end
                else
                    %{
                        Interpolate to find the cycle coordinate on the
                        user-defined FRF data
                    %}
                    if Smi >= 0.0
                        positiveM = frfData_m >= 0.0;
                        frfData_a_side = frfData_a(positiveM);
                        frfData_m_side = frfData_m(frfData_m >= 0.0);
                    else
                        negativeM = frfData_m <= 0.0;
                        frfData_a_side = frfData_a(negativeM);
                        frfData_m_side = frfData_m(frfData_m <= 0.0);
                    end
                    
                    if (length(frfData_m_side) < 2.0) || (length(frfData_a_side) < 2.0)
                        Ah = -1.0;
                        Bh = 1.0;
                    else
                        SmU = interp1(frfData_a_side, frfData_m_side, Sai, interpolationOrder);
                        
                        if isnan(SmU) == 1.0
                            Ah = -1.0;
                            Bh = 1.0;
                        else
                            % The cycle falls within the well-defined envelope
                            
                            %{
                                Intercept between the horizontal line from
                                Sm and the user-defined line
                            %}
                            Ah = SmU;
                            
                            % Distance from the y-axis to Sa
                            Bh = Smi;
                        end
                    end
                end
                
                % Horizontal FRF calculation
                frfHi = Ah/Bh;
                if frfHi > frfMaxValue
                    frfHi = frfMaxValue;
                elseif (frfHi < frfMinValue) && (frfHi ~= -1.0)
                    frfHi = frfMinValue;
                end
                
                frfH(totalCounter) = frfHi;
                
                % VERTICAL FRF
                if (Smi < frfData_m(end)) || (Smi > frfData_m(1.0))
                    % FRFV is not defined outside the range of Sm
                    Av = -1.0;
                    Bv = 1.0;
                else
                    %{
                        Interpolate to find the cycle coordinate on the
                        user-defined FRF data.
                    %}
                    if (length(frfData_m) < 2.0) || (length(frfData_a) < 2.0)
                        Av = -1.0;
                        Bv = 1.0;
                    else
                        SaU = interp1(frfData_m, frfData_a, Smi, interpolationOrder);
                        
                        if Sai == 0.0
                            % Special case where the stress amplitude is zero
                            Av = frfMaxValue;
                            Bv = 1.0;
                        else
                            %{
                                Intercept between the vertical line from Sa
                                and the user-defined FRF data
                            %}
                            Av = SaU;
                            
                            % Distance from the x-axis to Sa
                            Bv = Sai;
                        end
                    end
                end
                
                % Vertical FRF calculation
                frfVi = Av/Bv;
                if frfVi > frfMaxValue
                    frfVi = frfMaxValue;
                elseif (frfVi < frfMinValue) && (frfVi ~= -1.0)
                    frfVi = frfMinValue;
                end
                
                frfV(totalCounter) = frfVi;
        end
        
        % Worst FRF calculation
        if frfRi == -1.0
            frfRi = inf;
        end
        if frfHi == -1.0
            frfHi = inf;
        end
        if frfVi == -1.0
            frfVi = inf;
        end
        
        frfWi = min([frfRi, frfHi, frfVi]);
        
        if isinf(frfW) == 1.0
            frfW(totalCounter) = -1.0;
        else
            frfW(totalCounter) = frfWi;
        end
    end  
end

%% COUNT NUMBER OF FAILED FRF GROUPS
if failedFRFGroups == G
    setappdata(0, 'failedFRF', 1.0)
else
    setappdata(0, 'failedFRF', 0.0)
end

%% SAVE THE FRF VARIABLES
% Location of worst FRF value
FRFW_ABS = min(frfW);
frfW_item = find(frfW == FRFW_ABS);
if length(FRFW_ABS) > 1.0 || length(frfW_item) > 1.0
    FRFW_ABS = FRFW_ABS(1.0);
    frfW_item = frfW_item(1.0);
end

% Save the FRF values to the appdata
setappdata(0, 'FRFR', frfR)
setappdata(0, 'FRFH', frfH)
setappdata(0, 'FRFV', frfV)
setappdata(0, 'FRFW', frfW)
setappdata(0, 'FRFW_ABS', FRFW_ABS)

mainID_groupAll = getappdata(0, 'mainID_groupAll');
subID_groupAll = getappdata(0, 'subID_groupAll');

if (G == 1.0) || (isempty(mainID_groupAll) == 1.0) || (isempty(subID_groupAll) == 1.0)
    setappdata(0, 'FRFW_mainID', mainID(frfW_item))
    setappdata(0, 'FRFW_subID', subID(frfW_item))
else
    mainID_groupAll = getappdata(0, 'mainID_groupAll');
    subID_groupAll = getappdata(0, 'subID_groupAll');
    
    setappdata(0, 'FRFW_mainID', mainID_groupAll(frfW_item))
    setappdata(0, 'FRFW_subID', subID_groupAll(frfW_item))
end
end
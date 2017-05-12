function [cumulativeDamage] = interpolate(cumulativeDamage, pairs, msCorrection, numberOfCycles, cycles, scaleFactors, mscWarning, overflowCycles)
%INTERPOLATE    QFT function to interpolate stress-life data.
%   This function calculates the S-N curve based on the current load ratio
%   if the R-ratio S-N Curves mean stress cirrection is used. The function
%   also interpolates user stress-life data to calculate the fatigue damage
%   of the current cycle in the loading.
%   
%   INTERPOLATE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      5.4 Using custom stress-life data
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 12-May-2017 15:25:52 GMT
    
    %%
    
S = getappdata(0, 's_values');
N = getappdata(0, 'n_values');
sets = getappdata(0, 'nSNDatasets');
residualStress = getappdata(0, 'residualStress');
fatigueLimit = getappdata(0, 'fatigueLimit');
fatigueLimit_original = fatigueLimit;
modifyEnduranceLimit = getappdata(0, 'modifyEnduranceLimit');
ndEndurance = getappdata(0, 'ndEndurance');
enduranceScale = getappdata(0, 'enduranceScaleFactor');
cyclesToRecover = abs(round(getappdata(0, 'cyclesToRecover')));
kt = getappdata(0, 'kt');

if (sets == 1.0) || (sets > 1.0 && msCorrection ~= 7.0)
    %{
        There is only one set of S-N data, or there are multiple sets of
        S-N data, but muliple R-ratio S-N curves mean stress correction is
        not being used
    %}
    
    %{
        Make sure the S-values are monotonically decreasing and always
        positive
    %}
    s_zero = 0.1;
    for i = 1:length(S) - 1.0
        if S(i) <= S(i + 1.0)
            S(i) = S(i + 1.0) + 0.001;
            
            %{
                Warn the user that the interpolated S-values are not
                monotonically decreasing
            %}
            messenger.writeMessage(78.0)
        end
        
        % If the current value of Si is negative, make it very
        % close to zero
        if S(i) <= 0.0
            S(i) = s_zero;
            s_zero = s_zero - 1e-6;
            
            % Warn the user that some interpolated S-values are
            % negative
            setappdata(0, 'warning_022', 1.0)
        end
    end
    
    % Perform the damage calculation
    for index = 1:numberOfCycles
        % If the cycle is purely compressive, assume no damage
        if (min(pairs(index, :)) < 0.0 && max(pairs(index, :)) <= 0.0) && (getappdata(0, 'ndCompression') == 1.0)
            cumulativeDamage(index) = 0.0;
            continue
        end
        
        % If the mean stress was too large, report infinite damage
        if mscWarning == 1.0 && any(overflowCycles == index) == 1.0
            cumulativeDamage(index) = inf;
            continue
        end
        
        % Modify the endurance limit if applicable
        [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycles(index), cyclesToRecover, residualStress, enduranceScale);
        if (zeroDamage == 1.0) && (kt == 1.0)
            cumulativeDamage(index) = 0.0;
            continue
        end
        
        %{
        	If the current cycle is negative, continue to the
        	next value in order to avoid complex damage values
        %}
        if cycles(index) <= 0.0
            cumulativeDamage(index) = 0.0;
        else
            % Interpolate directly to get the damage
            cumulativeDamage(index) = (10^(interp1(log10(S), log10(N), log10(cycles(index) + residualStress), 'linear', 'extrap')))^-1.0;
            
            if cumulativeDamage < 0.0
                cumulativeDamage(index) = 1.0;
            end
        end
    end
elseif msCorrection == 7.0
    %{
        Multiple R-ratio S-N curves mean stress correction is being used
    %}
    
    % Get the R-values
    rValues = getappdata(0, 'r_values');
    
    % Get the S-values at R=-1.0 if required later
    s_Rminus1 = getappdata(0, 's_values_reduced');
    
    for index = 1:numberOfCycles
        %{
            Initialize/reset flag to suppress message about non-decreasing
            S-values
        %}
        suppressMessage78 = 0.0;
        
        % If the cycle is purely compressive, assume no damage
        if (min(pairs(index, :)) < 0.0) && (max(pairs(index, :)) <= 0.0)
            %{
                Multiple R-ratio S-N curves are not well defined for fully
                compressive cycles. Therefore, in order to avoid
                interpolation issues, any cycle which is fully compressive
                is assumed to be unaffected by the mean stress
            %}
            if getappdata(0, 'ndCompression') == 1.0
                %{
                    If the user specified no damage for fully-compressive
                    cycles, the cycles damage should be set to zero
                %}
                cumulativeDamage(index) = 0.0;
            else
                %{
                    Otherwise, the cycle may still be damaging, but the
                    R-ratios mean stress correction will not be applied
                %}
                cumulativeDamage(index) = (10^(interp1(log10(s_Rminus1), log10(N), log10(cycles(index) + residualStress), 'linear', 'extrap')))^-1.0;
            end
            continue
        end
        
        % Get the load ratio for the current cycle
        Ri = min(pairs(index, :))/max(pairs(index, :));
        
        % These conditions should never be met!
        if Ri == -inf
            Ri = max(rValues);
        elseif isnan(Ri)
            Ri = -1.0;
        end
        
        % Scale the load ratio if the non-linear material model was used
        Ri = Ri*scaleFactors(index);
        
        % If there is an exact S-N curve for Ri, just use this curve
        rExact = find(rValues == Ri);
        
        if isempty(rExact) == 0.0
            % The S-N data is defined explicitly for the Ri load ratio
            
            rExact = rExact(1.0);
            
            Si = S(rExact, :);
            
            %{
                Make sure the S-values are monotonically decreasing and
                always positive
            %}
            s_zero = 0.1;
            for i = 1:length(Si) - 1.0
                if Si(i) <= Si(i + 1.0)
                    Si(i) = Si(i + 1.0) + 0.001;
                    
                    %{
                        Warn the user that the interpolated S-values are
                        not monotonically decreasing
                    %}
                    messenger.writeMessage(78.0)
                end
                
                %{
                    If the current value of Si is negative, make it very
                    close to zero
                %}
                if Si(i) <= 0.0
                    Si(i) = s_zero;
                    s_zero = s_zero - 1e-6;
                    
                    %{
                        Warn the user that some interpolated S-values are
                        negative
                    %}
                    setappdata(0, 'warning_022', 1.0)
                end
            end
        else
            % Find which curves (if any) the Ri curve lies between
            found = 0.0;
            for i = 1:sets - 1.0
                if rValues(i) < Ri && rValues(i + 1.0) > Ri
                    highR = rValues(i + 1.0);
                    highRi = (i + 1.0);
                    
                    lowR = rValues(i);
                    lowRi = i;
                    
                    found = 1.0;
                    break
                elseif rValues(i) > Ri && rValues(i + 1.0) < Ri
                    lowR = rValues(i + 1.0);
                    lowRi = (i + 1.0);
                    
                    highR = rValues(i);
                    highRi = i;
                    
                    found = 1.0;
                    break
                end
            end
            
            if found == 0.0
                %{
                    The Ri curve lies outside the range of S-N data.
                    Extrapolate linearly to approximate the curve and
                    warn the user that the S-N data may be inaccurate
                %}
                
                %{
                    The message about non-decreasing S-values does not have
                    to be issued if S-N extrapolation is enabled
                %}
                suppressMessage78 = 1.0;
                
                messenger.writeMessage(77.0)
                
                % Find on which side of the S-N data the Ri curve lies
                if max(rValues) < Ri
                    highR = max(rValues);
                    highRi = find(rValues == max(rValues));
                    
                    rValues2 = rValues;
                    pos = rValues2 == max(rValues2);
                    rValues2(pos) = [];
                    lowR = max(rValues2);
                    lowRi = find(rValues == lowR);
                else
                    lowR = min(rValues);
                    lowRi = find(rValues == min(rValues));
                    
                    rValues2 = rValues;
                    pos = rValues2 == min(rValues2);
                    rValues2(pos) = [];
                    highR = min(rValues2);
                    highRi = find(rValues == highR);
                end
            end
            
            nData = length(S(1.0, :));
            Si = zeros(1.0, nData);
            
            %{
                For each S-N datapoint, interpolate to find the S-N
                datapoint at Ri
            %}
            s_zero = 0.1;
            for i = 1:nData
                if S(lowRi, i) > S(highRi, i)
                    S2 = S(lowRi, i);
                    S1 = S(highRi, i);
                else
                    S2 = S(highRi, i);
                    S1 = S(lowRi, i);
                end
                 
                %{
                    If the cycle load ratio falls outside the defined
                    S-N curves, extrapolate. Otherwise, interpolate
                %}
                Si(i) = interp1([highR, lowR], [S1, S2], Ri, 'linear', 'extrap');
                
                %{
                    If current value of Si is greater than or equal to
                    the previous value, make them almost the same
                %}
                if (i > 1.0) && (Si(i) >= Si(i - 1.0))
                    Si(i) = Si(i - 1.0) - 0.001;
                    
                    %{
                        Warn the user that the interpolated S-values are
                        not monotonically decreasing
                    %}
                    if suppressMessage78 == 0.0
                        messenger.writeMessage(78.0)
                    end
                end
                
                %{
                    If the current value of Si is negative, make it very
                    close to zero
                %}
                if Si(i) <= 0.0
                    Si(i) = s_zero;
                    s_zero = s_zero - 1e-6;
                    
                    %{
                        Warn the user that some interpolated S-values are
                        negative
                    %}
                    setappdata(0, 'warning_022', 1.0)
                end
            end
        end
        
        %{
            For R-ratio S-N curves, the fatigue limit will depend on the
            load ratio of the current cycle. The fatigue limit for the
            current cycle is the last S-value of the interpolated S-N
            curve.
        %}
        fatigueLimit = Si(end);
        fatigueLimit_original = fatigueLimit;
        if (index > 1.0) && (fatigueLimit2 < fatigueLimit)
            fatigueLimit = fatigueLimit2;
        end
        
        % Modify the endurance limit if applicable
        [fatigueLimit2, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycles(index), cyclesToRecover, residualStress, enduranceScale);
        if (zeroDamage == 1.0) && (kt == 1.0)
            cumulativeDamage(index) = 0.0;
            continue
        end
        
        %{
            If the current cycle is negative, continue to the
            next value in order to avoid complex damage values
        %}
        if cycles(index) <= 0.0
            cumulativeDamage(index) = 0.0;
        else
            %{
                Find the value of Kt for the SN curve and scale the S
                datapoints if applicable
            %}
            if kt ~= 1.0
                ktn = zeros(1.0, length(Si));
                for ktIndex = 1:length(Si)
                    ktn(ktIndex) = analysis.getKtn(N(ktIndex));
                end
                
                Si = Si.*(1.0./ktn);
            end
            
            % Interpolate directly to get the damage
            cumulativeDamage(index) = (10^(interp1(log10(Si), log10(N), log10(cycles(index) + residualStress), 'linear', 'extrap')))^-1.0;
            
            if cumulativeDamage(index) < 0.0 || isinf(cumulativeDamage(index))
                cumulativeDamage(index) = 1.0;
            end
        end
    end
end
end
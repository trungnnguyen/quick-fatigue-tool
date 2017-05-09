classdef algorithm_sip < handle
%ALGORITHM_SIP    QFT class for Stress Invariant Parameter algorithm.
%   This class contains methods for the Stress Invariant Parameter fatigue
%   analysis algorithm.
%   
%   ALGORITHM_SIP is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_ns, algorithm_sbbm, algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.5 Stress Invariant Parameter
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalAmplitudes, nodalPairs, nodalDamage,...
                nodalDamageParameter] = main(ps1, ps2, ps3, signalLength,...
                node, nodalDamage, msCorrection, nodalAmplitudes,...
                nodalPairs, nodalDamageParameter, signConvention,...
                gateTensors, tensorGate, damageParameter,...
                stressInvParamType, Sxxi, Syyi)
            
            % Apply sign convention to the von Mises stress
            if (stressInvParamType == 1.0) || (stressInvParamType == 4.0)
                % Apply sign to resultant shear stress
                tauXY = ps1 - ps2;
                damageParameter = applySignConvention(damageParameter, signConvention, ps1, ps2, ps3, Sxxi, Syyi, tauXY);
            end
            
            % Remove NaN values from damage DAMAGEPARAMETER
            damageParameter(isnan(damageParameter)) = 0.0;
            
            %% Rainflow count the von Mises stress
            if signalLength < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                cycles = 0.5*abs(max(damageParameter) - min(damageParameter));
                pairs = [min(damageParameter), max(damageParameter)];
            else
                % Gate the tensors if applicable
                if gateTensors > 0.0
                    damageParameter = analysis.gateTensors(damageParameter, gateTensors, tensorGate);
                end
                
                % Filter the von Mises stress
                damageParameter = analysis.preFilter(damageParameter, length(damageParameter));
                
                % Rainflow cycle count the von Mises stresses
                rfData = analysis.rainFlow(damageParameter);
                
                % Get rainflow pairs from rfData
                pairs = rfData(:, 1.0:2.0);
                
                % Get the amplitudes from the rainflow pairs
                [cycles, ~] = analysis.getAmps(pairs);
            end
            
            %% Store worst cycles for current item
            nodalAmplitudes{node} = cycles;
            nodalPairs{node} = pairs;
            
            %% Get current damage parameter
            nodalDamageParameter(node) = max(cycles);
            
            %% Perform a mean stress correection on the nodal damage parameter if necessary
            if msCorrection < 7.0
                x = nodalPairs{node};
                largestPair = find(cycles == max(cycles));
                [nodalDamageParameter(node), ~, ~] = analysis.msc(max(cycles), x(largestPair(1.0), :), msCorrection);
            end
            
            %% Perform a damage calculation on the current analysis item
            nodalDamage(node) = algorithm_sip.damageCalculation(cycles, msCorrection, pairs);
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(cycles, msCorrection, pairs)
            
            %% CALCULATE DAMAGE FOR EACH VON MISES CYCLE
            
            % Is the S-N curve derived or direct?
            useSN = getappdata(0, 'useSN');
            
            % Get the residual stress
            residualStress = getappdata(0, 'residualStress');
            
            % Get number of repeats of loading
            repeats = getappdata(0, 'repeats');
            numberOfCycles = length(cycles);
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Get the fatigue limit
            modifyEnduranceLimit = getappdata(0, 'modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'ndEndurance');
            fatigueLimit = getappdata(0, 'fatigueLimit');
            fatigueLimit_original = fatigueLimit;
            enduranceScale = getappdata(0, 'enduranceScaleFactor');
            cyclesToRecover = abs(round(getappdata(0, 'cyclesToRecover')));
            overflowCycles = zeros(1.0, numberOfCycles);
            
            % Perform mean stress correction if necessary
            if msCorrection < 7.0
                [cycles, mscWarning, overflowCycles] = analysis.msc(cycles, pairs, msCorrection);
            else
                mscWarning = 0.0;
            end
            
            % Plasticity correction
            nlMaterial = getappdata(0, 'nlMaterial');
            
            if nlMaterial == 1.0
                scaleFactors = zeros(1, length(cycles));
                E = getappdata(0, 'E');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                for i = 1:length(cycles)
                    if cycles(i) == 0.0
                        continue
                    else
                        oldCycle = cycles(i);
                        
                        [~, cycles_i, ~] = css(cycles(i), E, kp, np);
                        cycles_i(1) = []; cycles_i = real(cycles_i);
                        
                        cycles(i) = cycles_i;
                    end
                    
                    scaleFactors(i) = cycles_i/oldCycle;
                end
            else
                scaleFactors = ones(1.0, length(cycles));
            end
            
            if useSN == 1.0 % S-N curve was defined directly
                [cumulativeDamage] = interpolate(cumulativeDamage, pairs, msCorrection, numberOfCycles, cycles, scaleFactors, mscWarning, overflowCycles);
            else % S-N curve is derived
                Sf = getappdata(0, 'Sf');
                b = getappdata(0, 'b');
                b2 = getappdata(0, 'b2');
                b2Nf = getappdata(0, 'b2Nf');
                kt = getappdata(0, 'kt');
                
                for index = 1:numberOfCycles
                    % If the cycle is purely compressive, assume no damage
                    if (min(pairs(index, :)) < 0.0 && max(pairs(index, :)) <= 0.0) && (getappdata(0, 'ndCompression') == 1.0)
                        cumulativeDamage(index) = 0.0;
                        continue
                    end
                    
                    % Modify the endurance limit if applicable
                    [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycles(index), cyclesToRecover, residualStress, enduranceScale);
                    if (zeroDamage == 1.0) && (kt == 1.0)
                        cumulativeDamage(index) = 0.0;
                        continue
                    end
                    
                    % If the mean stress was too large, report infinite
                    % damage
                    if mscWarning == 1.0 && any(overflowCycles == index) == 1.0
                        cumulativeDamage(index) = inf;
                        continue
                    end
                    
                    %{
                        If the current cycle is negative, continue to the
                        next value in order to avoid complex damage values
                    %}
                    
                    if cycles(index) < 0.0
                        cumulativeDamage(index) = 0.0;
                    else
                        % Divide the LHS by Sf' so that LHS == Nf^b
                        quotient = (cycles(index) + residualStress)/Sf;
                        
                        % Raise the LHS to the power of 1/b so that LHS == Nf
                        life = 0.5*quotient^(1.0/b);
                        
                        % If the life was above the knee-point,
                        % re-calculate the life using B2
                        if life > b2Nf
                            life = 0.5*quotient^(1.0/b2);
                        end
                        
                        % Find the value of Kt at this life and
                        % re-calculate the life if necessary
                        if kt ~= 1.0
                            radius = getappdata(0, 'notchRootRadius');
                            constant = getappdata(0, 'notchSensitivityConstant');
                            
                            ktn = analysis.getKtn(life, constant, radius);
   
                            quotient = (ktn*cycles(index) + residualStress)/Sf;

                            if life > b2Nf
                                life = 0.5*quotient^(1/b2);
                            else
                                life = 0.5*quotient^(1/b);
                            end
                        end
                        
                        % Invert the life value to get the damage
                        cumulativeDamage(index) = 1.0/life;
                    end
                end
            end
            
            %% SAVE THE CUMULATIVE DAMAGE
            
            setappdata(0, 'cumulativeDamage', cumulativeDamage);
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            
            damage = sum(cumulativeDamage)*repeats;
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis(stress, signalLength, msCorrection, signConvention, gateTensors, tensorGate,...
                ps1, ps2, ps3)
            
            % Obtain the von Mises stress at the worst analysis item
            vm = sqrt(0.5.*((stress(1.0, :) - stress(2.0, :)).^2.0 +...
                (stress(2.0, :) - stress(3.0, :)).^2.0 + (stress(3.0, :) -...
                stress(1.0, :)).^2.0 + 6.0.*(stress(4.0, :).^2.0 +...
                stress(5.0, :).^2.0 + stress(6.0, :).^2.0)));
            
            %% Apply sign convention to the von Mises stress
            tauXY = ps1 - ps2;
            vm = applySignConvention(vm, signConvention, ps1, ps2, ps3, stress(1.0, :), stress(2.0, :), tauXY);
            
            % Remove NaN values from damage DAMAGEPARAMETER
            vm(isnan(vm)) = 0.0;
            
            % Rainflow count the von Mises stress
            if signalLength < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                cycles = 0.5*abs(max(vm) - min(vm));
                pairs = [min(vm) max(vm)];
            else
                % Gate the tensors if applicable
                if gateTensors == 1.0
                    vm = analysis.gateTensors(vm, gateTensors, tensorGate);
                end
                
                % Filter the von Mises stress
                vm = analysis.preFilter(vm, length(vm));
                
                % Rainflow cycle count the von Mises stresses
                rfData = analysis.rainFlow(vm);
                
                % Get rainflow pairs from rfData
                pairs = rfData(:, 1:2);
                
                % Get the amplitudes from the rainflow pairs
                [cycles, ~] = analysis.getAmps(pairs);
            end
            
            % Save data for history output
            setappdata(0, 'CS', 0.5*(ps1 - ps3))
            setappdata(0, 'CN', 0.5*(ps1 + ps3))
            setappdata(0, 'cyclesOnCP', pairs)
            setappdata(0, 'amplitudesOnCP', cycles)
            
            % Get the damage per cycle for the worst node for the damage
            % accumulation plot
            if getappdata(0, 'outputFigure') == 1.0
                [~] = algorithm_sip.damageCalculation(cycles, msCorrection, pairs);
                setappdata(0, 'worstNodeCumulativeDamage', getappdata(0, 'cumulativeDamage'))
            end
        end
        
        %% GET THE STRESS INVARIANT PARAMETER AUTOMATICALLY
        function [] = getInvariantParameter(groupAlpha, G)
            % Variable for the preferred parameter (per group)
            preferredParameter = zeros(1.0, G);
            
            for i = 1:G
                % Get the min/max values of alpha for the current group
                alphas = groupAlpha{i};
                alphaMin = alphas(1.0);
                alphaMax = alphas(2.0);
                
                %{
                    If alpha is very close to zero, round it to zero. This
                    increases the chance of finding a suitable stress
                    invariant parameter
                %}
                if abs(alphaMin) < 1e-6
                    alphaMin = 0.0;
                end
                if abs(alphaMax) < 1e-6
                    alphaMax = 0.0;
                end
                
                % Get the conditions for each stress invariant parameter
                vonMisesCondition = ~((alphaMin ~= 0.0 && alphaMin ~= 1.0) || (alphaMax ~= 0.0 && alphaMax ~= 1.0));
                principalCondition = (alphaMin >= -1.0 && alphaMin <= 0.0) && (alphaMax >= -1.0 && alphaMax <= 0.0);
                trescaCondition = (alphaMin >= 0.0 && alphaMin <= 1.0) && (alphaMax >= 0.0 && alphaMax <= 1.0);
                
                % Concatenate the conditions
                conditions = [vonMisesCondition, principalCondition, trescaCondition];
                
                % Get the preferred parameter for the current group
                if conditions(3.0) == 1.0
                    preferredParameter(i) = 4.0;
                elseif conditions(2.0) == 1.0
                    preferredParameter(i) = 2.0;
                elseif conditions(1.0) == 1.0
                    preferredParameter(i) = 1.0;
                else
                    preferredParameter(i) = 0.0;
                end
            end
            
            if G > 1.0
                if range(preferredParameter) ~= 0.0
                    %{
                        If the preferred stress invariant parameter is
                        different between two or more groups, warn the user
                        and select a paramter based on priority (principal
                        -> Tresca -> von Mises)
                    %}
                    if any(preferredParameter == 0.0) == 1.0
                        %{
                            The preferred stress invariant parameter could
                            not be found for at least one group. Select
                            principal stress by default and warn the user
                        %}
                        setappdata(0, 'stressInvariantParameter', 2.0)
                        
                        setappdata(0, 'preferredParameter', 'principal')
                        messenger.writeMessage(209.0)
                    elseif any(preferredParameter == 2.0) == 1.0
                        setappdata(0, 'stressInvariantParameter', 2.0)
                        
                        setappdata(0, 'preferredParameter', 'principal')
                        messenger.writeMessage(210.0)
                    elseif any(preferredParameter == 4.0) == 1.0
                        setappdata(0, 'stressInvariantParameter', 4.0)
                        
                        setappdata(0, 'preferredParameter', 'Tresca')
                        messenger.writeMessage(210.0)
                    elseif any(preferredParameter == 1.0) == 1.0
                        setappdata(0, 'stressInvariantParameter', 1.0)
                        
                        setappdata(0, 'preferredParameter', 'von Mises')
                        messenger.writeMessage(210.0)
                    end
                else
                    %{
                        The preferred stress invariant parameter is the
                        same for all groups
                    %}
                    if preferredParameter(1.0) == 0.0
                        %{
                            If the preferred stress intensity parameter
                            could not be found for any group, select
                            principal stress by default and warn the user
                        %}
                        setappdata(0, 'stressInvariantParameter', 2.0)
                        
                        setappdata(0, 'preferredParameter', 'principal')
                        messenger.writeMessage(211.0)
                    else
                        setappdata(0, 'stressInvariantParameter', preferredParameter(1.0))
                        
                        if preferredParameter(1.0) == 1.0
                            setappdata(0, 'preferredParameter', 'von Mises')
                        elseif preferredParameter(1.0) == 2.0
                            setappdata(0, 'preferredParameter', 'principal')
                        elseif preferredParameter(1.0) == 4.0
                            setappdata(0, 'preferredParameter', 'Tresca')
                        end
                        messenger.writeMessage(212.0)
                    end
                end
            else
                if preferredParameter == 0.0
                    %{
                        If the preferred stress intensity parameter
                        could not be found, select the parameter which best
                        suites the range of alpha
                    %}
                    if ((alphaMin >= 0.0) && (alphaMax >= 0.0)) || (abs(alphaMin) < abs(alphaMax))
                        setappdata(0, 'stressInvariantParameter', 4.0)
                        setappdata(0, 'preferredParameter', 'Tresca')
                    elseif ((alphaMin <= 0.0) && (alphaMax <= 0.0)) || (abs(alphaMin) > abs(alphaMax))
                        setappdata(0, 'stressInvariantParameter', 2.0)
                        setappdata(0, 'preferredParameter', 'principal')
                    else
                        setappdata(0, 'stressInvariantParameter', 1.0)
                        setappdata(0, 'preferredParameter', 'von Mises')
                    end
                    
                    messenger.writeMessage(213.0)
                else
                    setappdata(0, 'stressInvariantParameter', preferredParameter)
                    
                    if preferredParameter == 1.0
                        setappdata(0, 'preferredParameter', 'von Mises')
                    elseif preferredParameter == 2.0
                        setappdata(0, 'preferredParameter', 'principal')
                    elseif preferredParameter == 4.0
                        setappdata(0, 'preferredParameter', 'Tresca')
                    end
                    messenger.writeMessage(212.0)
                end
            end
        end
    end
end
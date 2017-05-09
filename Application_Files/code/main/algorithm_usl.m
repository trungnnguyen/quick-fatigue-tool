classdef algorithm_usl < handle
%ALGORITHM_USL    QFT class for Uniaxial Stress-Life algorithm.
%   This class contains methods for the Uniaxial Stress-Life fatigue
%   analysis algorithm.
%   
%   ALGORITHM_USL is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_ns, algorithm_sbbm, algorithm_sip.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.7 Uniaxial Stress-Life
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalAmplitudes, nodalPairs, nodalDamage,...
                nodalDamageParameter, damageParameter] = main(Sxx, ~, ~, ~, ~, ~,...
                signalLength, node, nodalDamage, msCorrection,...
                nodalAmplitudes, nodalPairs, nodalDamageParameter,...
                gateTensors, tensorGate)
            
            %% The damage parameter is just the Sxx component
            damageParameter = Sxx;
            
            % Remove NaN values from damage DAMAGEPARAMETER
            damageParameter(isnan(damageParameter)) = 0.0;
            
            %% Rainflow count the stress
            if signalLength < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                cycles = 0.5*abs(max(damageParameter) - min(damageParameter));
                pairs = [min(damageParameter), max(damageParameter)];
            else
                % Gate the tensors if applicable
                if gateTensors > 0.0
                    damageParameter = analysis.gateTensors(damageParameter, gateTensors, tensorGate);
                end
                
                % Filter the stresses
                damageParameter = analysis.preFilter(damageParameter, length(damageParameter));
                
                % Rainflow cycle count stresses
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
                [nodalDamageParameter(node), ~, ~] = analysis.msc(max(cycles), x(largestPair(1), :), msCorrection);
            end
            
            %% Perform a damage calculation on the current analysis item
            nodalDamage(node) = algorithm_usl.damageCalculation(cycles, msCorrection, pairs);
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(cycles, msCorrection, pairs)
            
            %% CALCULATE DAMAGE FOR EACH STRESS CYCLE
            
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
                scaleFactors = zeros(1.0, length(cycles));
                E = getappdata(0, 'E');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                for i = 1:length(cycles)
                    if cycles(i) == 0.0
                        continue
                    else
                        oldCycle = cycles(i);
                        
                        [~, cycles_i, ~] = css(cycles(i), E, kp, np);
                        cycles_i(1.0) = []; cycles_i = real(cycles_i);
                        
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
                                life = 0.5*quotient^(1.0/b2);
                            else
                                life = 0.5*quotient^(1.0/b);
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
        function [] = worstItemAnalysis(signalLength, msCorrection, nodalAmplitudes, nodalPairs)
            nodalPairs = nodalPairs{:};
            nodalAmplitudes = nodalAmplitudes{:};
            
            % Save data for history output
            setappdata(0, 'CS', zeros(1.0, signalLength))
            setappdata(0, 'CN', zeros(1.0, signalLength))
            setappdata(0, 'cyclesOnCP', nodalPairs)
            setappdata(0, 'amplitudesOnCP', nodalAmplitudes)
            
            % Get the damage per cycle for the worst node for the damage
            % accumulation plot
            if getappdata(0, 'outputFigure') == 1.0
                [~] = algorithm_usl.damageCalculation(nodalAmplitudes, msCorrection, nodalPairs);
                setappdata(0, 'worstNodeCumulativeDamage', getappdata(0, 'cumulativeDamage'))
            end
        end
    end
end
classdef algorithm_ns < handle
%ALGORITHM_NS    QFT class for Normal Stress algorithm.
%   This class contains methods for the Normal Stress fatigue analysis
%   algorithm.
%   
%   ALGORITHM_NS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_sbbm, algorithm_sip, algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.3 Normal Stress
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 12-May-2017 15:25:52 GMT
    
    %%
        
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, signalLength,...
                step, precision, nodalDamageParameter, nodalAmplitudes,...
                nodalPairs, nodalPhiC, nodalThetaC, node, msCorrection,...
                nodalDamage, gateTensors, tensorGate, maxPhiCurve)
            
            % Perform the critical plane search
            [damageParameter, damageParamAll, phiC, thetaC, amplitudes,...
                pairs, maxPhiCurve_i] =...
                algorithm_ns.criticalPlaneAnalysis(Sxxi, Syyi, Szzi, Txyi,...
                Tyzi, Txzi, signalLength, step, gateTensors, tensorGate,...
                precision);
            
            % Get current Damage parameter
            nodalDamageParameter(node) = damageParameter;
            
            % Get the current maximum phi curve value
            maxPhiCurve(node) = maxPhiCurve_i;
            
            % Store worst cycles for current item
            nodalAmplitudes{node} = amplitudes;
            nodalPairs{node} = pairs;
            
            % Perform a mean stress correction on the nodal damage
            % parameter if necessary
            if msCorrection < 7.0
                x = nodalPairs{node};
                largestPair = find(amplitudes == max(amplitudes));
                [nodalDamageParameter(node), ~, ~] = analysis.msc(damageParameter, x(largestPair(1.0), :), msCorrection);
            end
            
            % Record angle
            nodalPhiC(node) = phiC;
            nodalThetaC(node) = thetaC;
            
            %% Perform a damage calcuacalculationltion on the current analysis item
            nodalDamage(node) = algorithm_ns.damageCalculation(damageParamAll, msCorrection, pairs);
        end
        
        %% CRITICAL PLANE SEARCH ALGORITHM
        function [damageParameter, damageParamAll, phiC, thetaC,...
                amplitudes, pairs, maxPhiCurve] = criticalPlaneAnalysis(Sxxi, Syyi, Szzi, Txyi,...
                Tyzi, Txzi, signalLength, step, gateTensors, tensorGate, precision)
            
            % Create the stress tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Sxxi(i), Txyi(i), Txzi(i); Txyi(i), Syyi(i), Tyzi(i); Txzi(i), Tyzi(i), Szzi(i)];
            end
            
            % Initialize matrices for normal stress components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            S_prime = cell(1.0, signalLength);
            
            % Critical plane search
            for theta = 0:step:180
                for phi = 0:step:180
                    
                    % Update the indexes
                    index_phi = index_phi + 1.0;
                    if index_phi == precision + 1.0
                        index_phi = 1.0;
                    end
                    
                    if phi == 0.0
                        index_theta = index_theta + 1.0;
                    end
                    
                    % Calculate the current Q matrix
                    Q = [...
                        sind(phi)*cosd(theta), -sind(theta), -cosd(phi)*cosd(theta);...
                        sind(phi)*sind(theta), cosd(theta), -cosd(phi)*sind(theta);...
                        cosd(phi), 0.0, sind(phi)...
                        ];
                    
                    % Calculate the transform stress tensor for the current plane
                    for y = 1:signalLength
                        S_prime{y}=Q'*St{y}*Q;
                    end
                    
                    % Calculate stress components for the first face of rotated stress matrix
                    for i = 1:signalLength
                        normalStress(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
                    end
                    
                    % Rainflow the normal stress on this plane
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        amplitudes = 0.5*(max(normalStress) - min(normalStress));
                        pairs = [min(normalStress), max(normalStress)];
                    else
                        % Gate the tensors if applicable
                        if gateTensors > 0.0
                            fT = analysis.gateTensors(normalStress, gateTensors, tensorGate);
                            
                            % Pre-filter the signal
                            fT = analysis.preFilter(fT, length(fT));
                        else
                            fT = analysis.preFilter(normalStress, signalLength);
                        end
                        
                        % Now rainflow the shear stresses
                        rfData = analysis.rainFlow(fT);
                        
                        % Get rainflow pairs from rfData
                        pairs = rfData(:, 1.0:2.0);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes, ~] = analysis.getAmps(pairs);
                    end
                    
                    % Get the mean stress of each cycle
                    %meanStress = (0.5.*(pairs(:, 1.0) + pairs(:, 2.0)))';
                    
                    % Get the damage parameter on this plane
                    %normalPlusMean = amplitudes + meanStress;
                    
                    % Calculate the normal stress on this plane
                    %f(index_theta, index_phi) = max(normalPlusMean);
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                end
            end
            
            % Get the maximum normal stress over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum normal stress
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the normal stress on the critical plane
            normalStressOnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the normal stress is maximum
            %}
            maxThetaCurve = find(normalStressOnCP == max(normalStressOnCP), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            % Get AMPLITUDES and PAIRS on critical plane
            amplitudes = amplitudesBuffer{maxThetaCurve, maxPhiCurve};
            pairs = pairsBuffer{maxThetaCurve, maxPhiCurve};
            
            % Record the damage parameter
            damageParamAll = amplitudes;
            damageParameter = max(damageParamAll);
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(cycles, msCorrection, pairs)
            
            %% CALCULATE DAMAGE FOR EACH PRINCIPAL STRESS CYCLE
            
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
                
                % Get the morrow Sf values if applicable
                morrowSf = getappdata(0, 'morrowSf');
                
                for index = 1:numberOfCycles
                    % If the cycle is purely compressive, assume no damage
                    if (min(pairs(index, :)) < 0.0 && max(pairs(index, :)) <= 0.0) && (getappdata(0, 'ndCompression') == 1.0)
                        cumulativeDamage(index) = 0.0;
                        continue
                    end
                    
                    %{
                        If the mean stress was too large, report infinite
                        damage
                    %}
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
                    
                    if cycles(index) < 0.0
                        cumulativeDamage(index) = 0.0;
                    else
                        % Divide the LHS by Sf' so that LHS == Nf^b
                        if msCorrection == 1.0
                            quotient = (cycles(index) + residualStress)/morrowSf(index);
                        else
                            quotient = (cycles(index) + residualStress)/Sf;
                        end
                        
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
                            
                            if msCorrection == 1.0
                                quotient = (ktn*cycles(index) + residualStress)/morrowSf(index);
                            else
                                quotient = (ktn*cycles(index) + residualStress)/Sf;
                            end
                            
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
        function [] = worstItemAnalysis(stress, phiC, thetaC, signalLength,...
                msCorrection, precision, gateTensors, tensorGate, step,...
                signConvention, S1, S2, S3)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the stress tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [stress(1.0, i), stress(4.0, i), stress(5.0, i); stress(4.0, i), stress(2.0, i), stress(6.0, i); stress(5.0, i), stress(6.0, i), stress(3.0, i)];
            end
            
            % Initialize matrices for normal stress on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            tauXY = zeros(1.0, signalLength);
            tauXZ = zeros(1.0, signalLength);
            S_prime = cell(1.0, signalLength);
            
            % Maximum chord buffer
            distance = zeros(1.0, signalLength^2);
            
            % Theta index
            thetaIndex = 0.0;
            
            % Critical plane search
            for theta = 0:step:180
                thetaIndex = thetaIndex + 1.0;
                
                % Calculate the current Q matrix
                Q = [...
                    sind(phiC)*cosd(theta), -sind(theta), -cosd(phiC)*cosd(theta);...
                    sind(phiC)*sind(theta), cosd(theta), -cosd(phiC)*sind(theta);...
                    cosd(phiC), 0.0, sind(phiC)...
                    ];
                
                % Calculate the transform stress tensor for the current plane
                for y = 1:1:signalLength
                    S_prime{y}=Q'*St{y}*Q;
                end
                
                % Calculate stress components for the first face of rotated stress matrix
                for i = 1:signalLength
                    normalStress(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
                    tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear stress on that plane
                    tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear stress on that plane
                end
                
                % Get the maximum shear stress on the current plane
                %{
                    Ideally, this should be calculated using the
                    Maximum Chord Method, but the user can choose a
                    faster calculation which just takes the maximum
                    resultant shear stress over the loading
                %}
                if getappdata(0, 'cpShearStress') == 1.0
                    % Use the MCM
                    number = 0.0;
                    for x = 1:signalLength
                        for y = 1:signalLength
                            number = number + 1.0;
                            luku = ((tauXY(x) - tauXY(y))^2 + (tauXZ(x) - tauXZ(y))^2 )^0.5;
                            distance(number) = luku;
                        end
                    end
                    
                    % Maximum shear stress range
                    tn(thetaIndex) = max(distance);
                else
                    % Use the global maximum
                    
                    % Maximum shear stress range
                    tn(thetaIndex) = max(sqrt(tauXY.^2 + tauXZ.^2));
                end
                
                % Normal stress is maximum over time
                sn(thetaIndex) = max(normalStress);
                
                % Resultant shear stress history on the current plane
                shearStress = sqrt(tauXY.^2 + tauXZ.^2);

                % Apply sign to resultant shear stress
                shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, stress(1.0, :), stress(2.0, :), tauXY);
                
                %% Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    amplitudes = 0.5*(max(normalStress) - min(normalStress));
                    pairs = [min(normalStress), max(normalStress)];
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) = algorithm_ns.damageCalculation(damageParamAll, msCorrection, pairs);
                else
                    %% Gate the tensors if applicable
                    if gateTensors > 0.0
                        fT = analysis.gateTensors(normalStress, gateTensors, tensorGate);
                        
                        %% Pre-filter the signal
                        fT = analysis.preFilter(fT, length(fT));
                    else
                        fT = analysis.preFilter(normalStress, signalLength);
                    end
                    
                    %% Now rainflow the shear stresses
                    rfData = analysis.rainFlow(fT);
                    
                    %% Get rainflow pairs from rfData
                    pairs = rfData(:, 1.0:2.0);
                    
                    %% Get the amplitudes from the rainflow pairs
                    [damageParamAll, ~] = analysis.getAmps(pairs);
                    amplitudes = damageParamAll;
                    
                    %% Calculate the normal stress on this plane
                    damageParam = max(damageParamAll);
                    
                    %% Add the normal stress to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    %% Perform damage calculation on this plane
                    damageCube(thetaIndex) = algorithm_ns.damageCalculation(damageParamAll, msCorrection, pairs);
                end
                
                %% Save data for history output
                if theta == thetaC
                    setappdata(0, 'CS', shearStress)
                    setappdata(0, 'CN', normalStress)
                    setappdata(0, 'cyclesOnCP', pairs)
                    setappdata(0, 'amplitudesOnCP', amplitudes)
                    setappdata(0, 'damageParametersOnCP', damageParamAll)
                    setappdata(0, 'worstNodeCumulativeDamage', getappdata(0, 'cumulativeDamage'))
                end
            end
            
            setappdata(0, 'worstNodeDamageParamCube', damageParamCube)
            setappdata(0, 'worstNodeDamageCube', damageCube)
            
            setappdata(0, 'shear_cp', tn)
            setappdata(0, 'normal_cp', sn)
        end
    end
end
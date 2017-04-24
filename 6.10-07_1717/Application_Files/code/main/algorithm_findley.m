classdef algorithm_findley < handle
%ALGORITHM_FINDLEY    QFT class for Findley algorithm.
%   This class contains methods for the Findley fatigue analysis
%   algorithm.
%   
%   ALGORITHM_FINDLEY is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also algorithm_bs7608, algorithm_nasa, algorithm_ns,
%   algorithm_sbbm, algorithm_sip, algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.4 Findley's Method
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalDamageParameter, nodalAmplitudes,...
                nodalPairs, nodalPhiC, nodalThetaC, nodalDamage,...
                maxPhiCurve] = main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi,...
                signalLength, step, planePrecision, nodalDamageParameter,...
                nodalAmplitudes, nodalPairs, nodalPhiC, nodalThetaC, node,...
                nodalDamage, msCorrection, gateTensors, tensorGate,...
                vonMisesSign, S1, S2, S3, maxPhiCurve, k)
            
            % Perform the new critical plane search
            [damageParameter, damageParamAll, phiC, thetaC, amplitudes,...
                pairs, maxPhiCurve_i] =...
                algorithm_findley.criticalPlaneAnalysis(Sxxi, Syyi,...
                Szzi, Txyi, Tyzi, Txzi, signalLength, step, gateTensors,...
                tensorGate, planePrecision, vonMisesSign, S1, S2, S3, k);
            
            % Get current Findley parameter
            nodalDamageParameter(node) = damageParameter;
            
            % Get the current maximum phi curve value
            maxPhiCurve(node) = maxPhiCurve_i;
            
            % Store worst cycles for current item
            nodalAmplitudes{node} = amplitudes;
            nodalPairs{node} = pairs;
            
            % Record angle
            nodalPhiC(node) = phiC;
            nodalThetaC(node) = thetaC;
            
            % Perform a damage calculation on the current analysis item
            nodalDamage(node) = algorithm_findley.damageCalculation(damageParamAll, pairs, msCorrection);
        end
        
        %% CRITICAL PLANE SEARCH ALGORITHM
        function [damageParameter, damageParamAll, phiC, thetaC,...
                amplitudes, pairs, maxPhiCurve] =...
                criticalPlaneAnalysis(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi,...
                signalLength, step, gateTensors, tensorGate, precision,...
                signConvention, S1, S2, S3, k)
            
            % Create the stress tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Sxxi(i), Txyi(i), Txzi(i); Txyi(i), Syyi(i), Tyzi(i); Txzi(i), Tyzi(i), Szzi(i)];
            end
            
            % Initialize matrices for normal and shear stress components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn and tn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Stress buffers
            sigmaX = zeros(1.0, signalLength);
            tauXY = zeros(1.0, signalLength);
            tauXZ = zeros(1.0, signalLength);
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
                        sigmaX(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
                        tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear stress on that plane
                        tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear stress on that plane
                    end
                    
                    % Get the maximum shear stress on the current plane
                    % Use the global maximum
                        
                    % Maximum shear stress range
                    shearStress = sqrt(tauXY.^2 + tauXZ.^2);
                    
                    % Apply sign to resultant shear stress
                    shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, Sxxi, Syyi, tauXY);
                    
                    % Normal stress is maximum over time
                    normalStress = sigmaX;
                    
                    % Scaled normal stress history on the current plane
                    normalStressK = normalStress*k;
                    
                    % Rainflow
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        amplitudes = 0.5*(max(shearStress) - min(shearStress));
                        
                        damageParam = amplitudes + max(normalStressK);
                    else
                        % Gate the tensors if applicable
                        if gateTensors > 0.0
                            fT = analysis.gateTensors(shearStress, gateTensors, tensorGate);
                            
                            % Pre-filter the signal
                            fT = analysis.preFilter(fT, length(fT));
                        else
                            fT = analysis.preFilter(shearStress, signalLength);
                        end
                        
                        % Now rainflow the shear stresses
                        rfData = analysis.rainFlow(fT);
                        
                        % Get rainflow pairs from rfData
                        pairs = rfData(:, 1.0:2.0);
                        
                        % Get timestamps from rainflow pairs
                        times = rfData(:, 3.0:4.0);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes, numberOfAmps] = analysis.getAmps(pairs);
                        
                        % Calculate the Findley parameter on this plane
                        [damageParam, ~] = analysis.getFindleyParameter(amplitudes, times, normalStressK, numberOfAmps);
                    end
                    
                    % Calculate the Findley parameter on this plane
                    f(index_theta, index_phi) = damageParam;
                end
            end
            
            % Get the maximum Findley parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum Findley paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the Findley parameter on the critical plane
            findleyParameter = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the Findley parameter is maximum
            %}
            maxThetaCurve = find(findleyParameter == max(findleyParameter), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            %% Calculate the Findley parameter history on the critical plane
            
            % Calculate the critical Q matrix
            Q = [...
                sind(phiC)*cosd(thetaC), -sind(thetaC), -cosd(phiC)*cosd(thetaC);...
                sind(phiC)*sind(thetaC), cosd(thetaC), -cosd(phiC)*sind(thetaC);...
                cosd(phiC), 0.0, sind(phiC)...
                ];
            
            % Calculate the transform stress tensor for the critical plane
            for y = 1:1:signalLength
                S_prime{y}=Q'*St{y}*Q;
            end
            
            % Calculate stress components for the first face of rotated stress matrix
            for i = 1:signalLength
                sigmaX(i)=S_prime{i}(1.0, 1.0); % Normal stress on CP
                tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear stress on CP
                tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear stress on CP
            end
            
            % Calculate the resultant shear stress on the critical plane
            shearStress = sqrt(tauXY.^2 + tauXZ.^2);
            
            % Apply sign to resultant shear stress
            shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, Sxxi, Syyi, tauXY);

            % Calculate the normal stress on the critical plane
            normalStress = sigmaX;
            normalStressK = getappdata(0, 'k')*normalStress;
                    
            %% Rainflow
            if signalLength < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                
                amplitudes = 0.5*(max(shearStress) - min(shearStress));
                pairs = [min(shearStress), max(shearStress)];
                
                damageParamAll = amplitudes + max(normalStressK);
                damageParameter = damageParamAll;
            else
                %% Gate the tensors if applicable
                if gateTensors > 0.0
                    fT = analysis.gateTensors(shearStress, gateTensors, tensorGate);
                    
                    %% Pre-filter the signal
                    fT = analysis.preFilter(fT, length(fT));
                else
                    fT = analysis.preFilter(shearStress, signalLength);
                end
                
                %% Now rainflow the shear stresses
                rfData = analysis.rainFlow(fT);
                
                %% Get rainflow pairs from rfData
                pairs = rfData(:, 1:2);
                
                %% Get timestamps from rainflow pairs
                times = rfData(:, 3:4);
                
                %% Get the amplitudes from the rainflow pairs
                [amplitudes, numberOfAmps] = analysis.getAmps(pairs);
                
                %% Calculate the Findley parameter on this plane
                [damageParameter, damageParamAll] = analysis.getFindleyParameter(amplitudes, times, normalStressK, numberOfAmps);
            end
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(combinations, pairs, msCorrection)
            
            %% CALCULATE DAMAGE FOR EACH SHEAR-NORMAL COMBINATION DEFINED BY FINDLEYPARAMALL
            
            % Is the S-N curve derived or direct?
            use_sn = getappdata(0, 'useSN');
            
            % Get the residual stress
            residualStress = getappdata(0, 'residualStress');
            
            % Get number of repeats of loading
            repeats = getappdata(0, 'repeats');
            
            numberOfCycles = length(combinations);
            
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Plasticity correction
            nlMaterial = getappdata(0, 'nlMaterial');
            
            % Get the endurance limit
            modifyEnduranceLimit = getappdata(0, 'modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'ndEndurance');
            fatigueLimit = getappdata(0, 'fatigueLimit');
            fatigueLimit_original = fatigueLimit;
            enduranceScale = getappdata(0, 'enduranceScaleFactor');
            cyclesToRecover = abs(round(getappdata(0, 'cyclesToRecover')));
            
            if nlMaterial == 1.0
                scaleFactors = zeros(1.0, length(combinations));
                E = getappdata(0, 'E');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                for i = 1:length(combinations)
                    if combinations(i) == 0.0
                        continue
                    else
                        oldCycle = combinations(i);
                        
                        [~, combinations_i, ~] = css(combinations(i), E, kp, np);
                        combinations_i(1) = []; combinations_i = real(combinations_i);
                        
                        combinations(i) = combinations_i;
                    end
                    
                    scaleFactors(i) = combinations_i/oldCycle;
                end
            else
                scaleFactors = ones(1.0, length(combinations));
            end
            
            if use_sn == 1.0 % S-N curve was defined directly
                [cumulativeDamage] = interpolate(cumulativeDamage, pairs, msCorrection, numberOfCycles, combinations, scaleFactors, 0.0, 0.0);
            else % S-N curve is derived
                Tfs = getappdata(0, 'Tfs');
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
                    [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, combinations(index), cyclesToRecover, residualStress, enduranceScale);
                    if (zeroDamage == 1.0) && (kt == 1.0)
                        cumulativeDamage(index) = 0.0;
                        continue
                    end
                    
                    %{
                        If the current value of [dT/2 + kSn] is negative, continue to the
                        next value in order to avoid complex damage values
                    %}
                    
                    if combinations(index) < 0.0
                        cumulativeDamage(index) = 0.0;
                    else
                        % Divide the LHS by Tf* so that LHS == Nf^b
                        quotient = (combinations(index) + residualStress)/Tfs;
                        
                        % Raise the LHS to the power of 1/b so that LHS == Nf
                        life = quotient^(1.0/b);
                        
                        % If the life was above the knee-point,
                        % re-calculate the life using B2
                        if life > b2Nf
                            life = quotient^(1.0/b2);
                        end
                        
                        % Find the value of Kt at this life and
                        % re-calculate the life if necessary
                        if kt ~= 1.0
                            radius = getappdata(0, 'notchRootRadius');
                            constant = getappdata(0, 'notchSensitivityConstant');
                            
                            ktn = analysis.getKtn(life, constant, radius);
                            
                            quotient = (ktn*combinations(index) + residualStress)/Tfs;
                            
                            if life > b2Nf
                                life = quotient^(1.0/b2);
                            else
                                life = quotient^(1.0/b);
                            end
                        end
                        
                        % Invert the life value to get the damage
                        cumulativeDamage(index) = 1.0/life;
                    end
                end
            end
            
            %% SAVE THE CUMULATIVE DAMAGE
            
            setappdata(0, 'cumulativeDamage',cumulativeDamage);
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            
            damage = sum(cumulativeDamage)*repeats;
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis(stress, phiC, thetaC, signalLength,...
                msCorrection, precision, gateTensors, tensorGate, step,...
                signConvention, S1, S2, S3, k)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the stress tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [stress(1.0, i), stress(4.0, i), stress(5.0, i); stress(4.0, i), stress(2.0, i), stress(6.0, i); stress(5.0, i), stress(6.0, i), stress(3.0, i)];
            end
            
            % Initialize matrices for normal and shear stress components on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Stress buffers
            sigmaX = zeros(1.0, signalLength);
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
                    sigmaX(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
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
                sn(thetaIndex) = max(sigmaX);
                
                % Resultant shear stress history on the current plane
                shearStress = sqrt(tauXY.^2 + tauXZ.^2);
                
                % Apply sign to resultant shear stress
                shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, stress(1.0, :), stress(2.0, :), tauXY);
                
                % Normal stress history on the current plane
                normalStress = sigmaX;
                
                % Scaled normal stress history on the current plane
                normalStressK = normalStress*k;
                
                %% Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    amplitudes = 0.5*(max(shearStress) - min(shearStress));
                    pairs = [min(shearStress), max(shearStress)];
                    
                    damageParamAll = amplitudes + max(normalStressK);
                    
                    damageParamCube(thetaIndex) = amplitudes + max(normalStressK);
                    
                    damageCube(thetaIndex) = algorithm_findley.damageCalculation(damageParamAll, pairs, msCorrection);
                else
                    %% Gate the tensors if applicable
                    if gateTensors > 0.0
                        fT = analysis.gateTensors(shearStress, gateTensors, tensorGate);
                        
                        %% Pre-filter the signal
                        fT = analysis.preFilter(fT, length(fT));
                    else
                        fT = analysis.preFilter(shearStress, signalLength);
                    end
                    
                    %% Now rainflow the shear stresses
                    rfData = analysis.rainFlow(fT);
                    
                    %% Get rainflow pairs from rfData
                    pairs = rfData(:, 1.0:2.0);
                    
                    %% Get timestamps from rainflow pairs
                    times = rfData(:, 3.0:4.0);
                    
                    %% Get the amplitudes from the rainflow pairs
                    [amplitudes, numberOfAmps] = analysis.getAmps(pairs);
                    
                    %% Calculate the Findley parameter on this plane
                    [damageParam, damageParamAll] = analysis.getFindleyParameter(amplitudes, times, normalStressK, numberOfAmps);
                    
                    %% Add the Findley parameters to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    %% Perform damage calculation on this plane
                    damageCube(thetaIndex) = algorithm_findley.damageCalculation(damageParamAll, pairs, msCorrection);
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
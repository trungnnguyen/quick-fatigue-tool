classdef multiaxialAnalysis < handle
%MULTIAXIALANALYSIS    QFT class for Multiaxial Gauge Fatigue.
%   This class contains methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   MULTIAXIALANALYSIS is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also multiaxialPostProcess, multiaxialPreProcess, gaugeOrientation,
%   materialOptions, MultiaxialFatigue.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      A3.2 Multiaxial Gauge Fatigue
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 17-May-2017 14:54:51 GMT
    
    %%
    
    methods (Static = true)
        %% Critical plane analysis for SBBM algorithm
        function [life, phiC, thetaC, cyclesOnCP] = CP_BM(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
                signalLength, precision, step, signConvention, ndCompression)
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn and tn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            epsXY = zeros(1.0, signalLength);
            epsXZ = zeros(1.0, signalLength);
            eps_prime = cell(1.0, signalLength);
            
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
                    
                    % Calculate the transform strain tensor for the current plane
                    for y = 1:signalLength
                        eps_prime{y}=Q'*St{y}*Q;
                    end
                    
                    % Calculate strain components for the first face of rotated strain matrix
                    for i = 1:signalLength
                        normalStrain(i)=eps_prime{i}(1.0, 1.0); % Normal strain on that plane
                        epsXY(i)=eps_prime{i}(1.0, 2.0);  % Shear strain on that plane
                        epsXZ(i)=eps_prime{i}(1.0, 3.0);  % Shear strain on that plane
                    end
                    
                    % Get the resultant shear strain history on the current plane
                    shearStrain = sqrt(epsXY.^2 + epsXZ.^2);
                    
                    % Apply sign to resultant shear strain
                    if signConvention == 2.0
                        % Sign from maximum strain
                        sign_value = sign(Exx);
                        sign_value(sign_value == 0.0) = 1.0;
                    else
                        % Sign from hydrostatic strain
                        sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                        sign_value(sign_value == 0.0) = 1.0;
                    end
                    shearStrain = shearStrain.*sign_value;
                    
                    % Rainflow the normal strain on this plane
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        
                        % Get the strain cycle
                        amplitudes_normal = 0.5*(max(normalStrain) - min(normalStrain));
                        amplitudes_shear = 0.5*(max(shearStrain) - min(shearStrain));
                        amplitudes = amplitudes_normal + amplitudes_shear;
                        
                        pairs_normal = [min(normalStrain), max(normalStrain)];
                        pairs_shear = [min(shearStrain), max(shearStrain)];
                        pairs = pairs_normal + pairs_shear;
                        
                    else
                        % Get the strain cycles
                        % Rainflow the normal strain
                        rfData_normal = analysis.rainFlow_2(normalStrain);
                        
                        % Rainflow the shear strain
                        rfData_shear = analysis.rainFlow_2(shearStrain);
                        
                        % Get rainflow pairs from rfData
                        [pairs, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                        [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                        amplitudes = amplitudes_normal + amplitudes_shear;
                    end
                    
                    % Store the SBBM parameter on this plane
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                end
            end
            
            % Get the maximum SBBM parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum SBBM paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the SBBM parameter on the critical plane
            sbbmOnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the SBBM parameter is maximum
            %}
            maxThetaCurve = find(sbbmOnCP == max(sbbmOnCP), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            % Get AMPLITUDES and PAIRS on critical plane
            amplitudes = amplitudesBuffer{maxThetaCurve, maxPhiCurve};
            pairs = pairsBuffer{maxThetaCurve, maxPhiCurve};
            
            % Perform the damage calculation
            damage = multiaxialAnalysis.dcBM(amplitudes, msCorrection,...
                0.0, 0.0, pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                ndCompression);
            
            life = 1.0/damage;
            
            cyclesOnCP = length(amplitudes);
        end
        
        %% Critical plane analysis for SBBM algorithm (NONLINEAR)
        function [life, phiC, thetaC, cyclesOnCP] = CP_BM_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
                signalLength, precision, step, signConvention, S11, S22,...
                S33, S12, S13, S23, ndCompression)
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Create the stress tensor
            St_Stress = cell(1.0, signalLength);
            for i = 1:signalLength
                St_Stress{i} = [S11(i), S12(i), S13(i); S12(i), S22(i), S23(i); S13(i), S23(i), S33(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn and tn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            amplitudesBuffer_Stress = cell(precision, precision);
            pairsBuffer_Stress = cell(precision, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            epsXY = zeros(1.0, signalLength);
            epsXZ = zeros(1.0, signalLength);
            eps_prime = cell(1.0, signalLength);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            epsXY_Stress = zeros(1.0, signalLength);
            epsXZ_Stress = zeros(1.0, signalLength);
            eps_prime_Stress = cell(1.0, signalLength);
            
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
                    
                    % Calculate the transform strain tensor for the current plane
                    for y = 1:signalLength
                        eps_prime{y}=Q'*St{y}*Q;
                        eps_prime_Stress{y}=Q'*St_Stress{y}*Q;
                    end
                    
                    % Calculate strain components for the first face of rotated strain matrix
                    for i = 1:signalLength
                        normalStrain(i)=eps_prime{i}(1.0, 1.0); % Normal strain on that plane
                        epsXY(i)=eps_prime{i}(1.0, 2.0);  % Shear strain on that plane
                        epsXZ(i)=eps_prime{i}(1.0, 3.0);  % Shear strain on that plane
                        
                        normalStress(i)=eps_prime_Stress{i}(1.0, 1.0); % Normal stress on that plane
                        epsXY_Stress(i)=eps_prime_Stress{i}(1.0, 2.0);  % Shear stress on that plane
                        epsXZ_Stress(i)=eps_prime_Stress{i}(1.0, 3.0);  % Shear stress on that plane
                    end
                    
                    % Get the resultant shear strain history on the current plane
                    shearStrain = sqrt(epsXY.^2 + epsXZ.^2);
                    
                    % Get the resultant shear stress history on the current plane
                    shearStress = sqrt(epsXY_Stress.^2 + epsXZ_Stress.^2);
                    
                    % Apply sign to resultant shear strain
                    if signConvention == 2.0
                        % Sign from maximum strain
                        sign_value = sign(Exx);
                        sign_value(sign_value == 0.0) = 1.0;
                    else
                        % Sign from hydrostatic stress
                        sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                        sign_value(sign_value == 0.0) = 1.0;
                    end
                    shearStrain = shearStrain.*sign_value;
                    shearStress = shearStress.*sign_value;
                    
                    % Rainflow the normal strain on this plane
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        
                        % Get the strain cycle
                        amplitudes_normal = 0.5*(max(normalStrain) - min(normalStrain));
                        amplitudes_shear = 0.5*(max(shearStrain) - min(shearStrain));
                        amplitudes = amplitudes_normal + amplitudes_shear;
                        
                        pairs_normal = [min(normalStrain), max(normalStrain)];
                        pairs_shear = [min(shearStrain), max(shearStrain)];
                        pairs = pairs_normal + pairs_shear;
                        
                        % Get the stress cycle
                        amplitudes_normal = 0.5*(max(normalStress) - min(normalStress));
                        amplitudes_shear = 0.5*(max(shearStress) - min(shearStress));
                        amplitudes_Stress = amplitudes_normal + amplitudes_shear;
                        
                        pairs_normal = [min(normalStress), max(normalStress)];
                        pairs_shear = [min(shearStress), max(shearStress)];
                        pairs_Stress = pairs_normal + pairs_shear;
                    else
                        % Get the strain cycles
                        % Rainflow the normal strain
                        rfData_normal = analysis.rainFlow_2(normalStrain);
                        
                        % Rainflow the shear strain
                        rfData_shear = analysis.rainFlow_2(shearStrain);
                        
                        % Get rainflow pairs from rfData
                        [pairs, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                        [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                        amplitudes = amplitudes_normal + amplitudes_shear;
                        
                        % Get the stress cycles
                        % Rainflow the normal stress
                        rfData_normal = analysis.rainFlow_2(normalStress);
                        
                        % Rainflow the shear stress
                        rfData_shear = analysis.rainFlow_2(shearStress);
                        
                        % Get rainflow pairs from rfData
                        [pairs_Stress, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                        [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                        amplitudes_Stress = amplitudes_normal + amplitudes_shear;
                    end
                    
                    % Store the SBBM parameter on this plane
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                    
                    amplitudesBuffer_Stress{index_theta, index_phi} = amplitudes_Stress;
                    pairsBuffer_Stress{index_theta, index_phi} = pairs_Stress;
                end
            end
            
            % Get the maximum SBBM parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum SBBM paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the SBBM parameter on the critical plane
            sbbmOnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the SBBM parameter is maximum
            %}
            maxThetaCurve = find(sbbmOnCP == max(sbbmOnCP), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            % Get AMPLITUDES and PAIRS on critical plane
            amplitudes = amplitudesBuffer{maxThetaCurve, maxPhiCurve};
            pairs = pairsBuffer{maxThetaCurve, maxPhiCurve};
            amplitudes_Stress = amplitudesBuffer_Stress{maxThetaCurve, maxPhiCurve};
            pairs_Stress = pairsBuffer_Stress{maxThetaCurve, maxPhiCurve};
            
            % Perform the damage calculation
            damage = multiaxialAnalysis.dcBM(amplitudes, msCorrection,...
                amplitudes_Stress, pairs_Stress, pairs, uts, ucs, Sf, b,...
                Ef, c, E, Nf, ktn, ndCompression);
            life = 1.0/damage;
            
            cyclesOnCP = length(amplitudes);
        end
        
        %% Critical plane analysis for principal strain algorithm
        function [life, phiC, thetaC, cyclesOnCP] = CP_PS(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
                signalLength, precision, step, ndCompression)
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn and tn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            eps_prime = cell(1.0, signalLength);
            
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
                    
                    % Calculate the transform strain tensor for the current plane
                    for y = 1:signalLength
                        eps_prime{y}=Q'*St{y}*Q;
                    end
                    
                    % Calculate strain components for the first face of rotated strain matrix
                    for i = 1:signalLength
                        normalStrain(i)=eps_prime{i}(1.0, 1.0); % Normal strain on that plane
                    end
                    
                    % Get the principal strain parameter
                    psParameter = normalStrain;
                    
                    % Rainflow the normal strain on this plane
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        amplitudes = 0.5*(max(psParameter) - min(psParameter));
                        pairs = [min(psParameter), max(psParameter)];
                    else
                        % Now rainflow the SBBM parameter
                        rfData = analysis.rainFlow_2(psParameter);
                        
                        % Get rainflow pairs from rfData
                        pairs = rfData(:, 1.0:2.0);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes, ~] = analysis.getAmps(pairs);
                    end
                    
                    % Store the normal stress parameter on this plane
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                end
            end
            
            % Get the maximum SBBM parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum SBBM paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the SBBM parameter on the critical plane
            psOnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the SBBM parameter is maximum
            %}
            maxThetaCurve = find(psOnCP == max(psOnCP), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            % Get AMPLITUDES and PAIRS on critical plane
            amplitudes = amplitudesBuffer{maxThetaCurve, maxPhiCurve};
            pairs = pairsBuffer{maxThetaCurve, maxPhiCurve};
            
            %% Perform the damage calculation
            damage = multiaxialAnalysis.dcPS(amplitudes, msCorrection,...
                0.0, 0.0, pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                ndCompression);
            life = 1.0/damage;
            
            cyclesOnCP = length(amplitudes);
        end
        
        %% Critical plane analysis for principal strain algorithm (NONLINEAR)
        function [life, phiC, thetaC, cyclesOnCP] = CP_PS_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, uts, ucs, Sf, b, Ef, c, E, Nf, ktn, msCorrection,...
                signalLength, precision, step, S11, S22, S33, S12, S13,...
                S23, ndCompression)
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Create the stress tensor
            St_Stress = cell(1.0, signalLength);
            for i = 1:signalLength
                St_Stress{i} = [S11(i), S12(i), S13(i); S12(i), S22(i), S23(i); S13(i), S23(i), S33(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            f = zeros(precision, precision);
            
            % Indexes for sn and tn
            index_phi = 0.0;
            index_theta = 0.0;
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            amplitudesBuffer_Stress = cell(precision, precision);
            pairsBuffer_Stress = cell(precision, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            eps_prime = cell(1.0, signalLength);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            eps_prime_Stress = cell(1.0, signalLength);
            
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
                    
                    % Calculate the transform strain tensor for the current plane
                    for y = 1:signalLength
                        eps_prime{y}=Q'*St{y}*Q;
                        eps_prime_Stress{y}=Q'*St_Stress{y}*Q;
                    end
                    
                    % Calculate strain components for the first face of rotated strain matrix
                    for i = 1:signalLength
                        normalStrain(i)=eps_prime{i}(1.0, 1.0); % Normal strain on that plane
                        
                        normalStress(i)=eps_prime_Stress{i}(1.0, 1.0); % Normal stress on that plane
                    end
                    
                    % Get the principal strain parameter
                    psParameter = normalStrain;
                    
                    % Get the principal stress parameter
                    psParameter_Stress = normalStress;
                    
                    % Rainflow the normal strain on this plane
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        amplitudes = 0.5*(max(psParameter) - min(psParameter));
                        pairs = [min(psParameter), max(psParameter)];
                        
                        amplitudes_Stress = 0.5*(max(psParameter_Stress) - min(psParameter_Stress));
                        pairs_Stress = [min(psParameter_Stress), max(psParameter_Stress)];
                    else
                        % Now rainflow the SBBM parameter
                        rfData = analysis.rainFlow_2(psParameter);
                        rfData_Stress = analysis.rainFlow_2(psParameter_Stress);
                        
                        % Get rainflow pairs from rfData
                        pairs = rfData(:, 1.0:2.0);
                        pairs_Stress = rfData_Stress(:, 1.0:2.0);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes, ~] = analysis.getAmps(pairs);
                        [amplitudes_Stress, ~] = analysis.getAmps(pairs_Stress);
                    end
                    
                    % Store the normal stress parameter on this plane
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                    
                    amplitudesBuffer_Stress{index_theta, index_phi} = amplitudes_Stress;
                    pairsBuffer_Stress{index_theta, index_phi} = pairs_Stress;
                end
            end
            
            % Get the maximum SBBM parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum SBBM paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the normal strain parameter on the critical plane
            psOnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the SBBM parameter is maximum
            %}
            maxThetaCurve = find(psOnCP == max(psOnCP), 1.0);
            
            % Get the critical plane angles
            phiC = maxPhiCurve*step - step;
            thetaC = maxThetaCurve*step - step;
            
            % Get AMPLITUDES and PAIRS on critical plane
            amplitudes = amplitudesBuffer{maxThetaCurve, maxPhiCurve};
            pairs = pairsBuffer{maxThetaCurve, maxPhiCurve};
            amplitudes_Stress = amplitudesBuffer_Stress{maxThetaCurve, maxPhiCurve};
            pairs_Stress = pairsBuffer_Stress{maxThetaCurve, maxPhiCurve};
            
            %% Perform the damage calculation
            damage = multiaxialAnalysis.dcPS(amplitudes, msCorrection,...
                amplitudes_Stress, pairs_Stress, pairs, uts, ucs, Sf, b,...
                Ef, c, E, Nf, ktn, ndCompression);
            life = 1.0/damage;
            
            cyclesOnCP = length(amplitudes);
        end
        
        %% Mean stress correction
        function [mscCycles, morrowSf] = msc(uts, ucs, msCorrection,...
                cycles, cycles_Stress, pairs_Stress)
            
            % Initialize output
            mscCycles = cycles;
            morrowSf = 0.0;
            
            % Convert the mean strain to its equivalent mean stress
            % Get the mean stress from the corrected stress amplitudes
            Sm = 0.5*(pairs_Stress(:, 1.0) + pairs_Stress(:, 2.0));
            
            % Get the stress amplitude from the corrected stress amplitudes
            cycles = cycles_Stress;
            
            if msCorrection == 1.0
                % Morrow correction is applied partially
                morrowSf = getappdata(0, 'Sf') - Sm;
                % Check for negative values
                for i = 1:length(Sm)
                    if morrowSf(i) <= 0.0
                        morrowSf(i) = 1e-06;
                    end
                end
                setappdata(0, 'morrowSf', morrowSf)
            else
                % Get the user-defined mean stress correction data
                mscData = getappdata(0, 'userMSCData');
                mscData_m = mscData(:, 1.0);
                mscData_a = mscData(:, 2.0);
                
                % Initialise the MSC cycles buffer
                mscCycles = zeros(1.0, length(Sm));
                
                % Normalize the mean stress of the cycle with the UTS
                % or the UCS
                Sm(Sm > 0.0) = Sm(Sm > 0.0)/uts;
                Sm(Sm < 0.0) = Sm(Sm < 0.0)/ucs;
                
                % For each cycle, find the MSC factor
                for i = 1:length(Sm)
                    % If the mean stress of the cycle is outside the
                    % range of the data, take the edge amplitude value
                    if Sm(i) < mscData_m(end)
                        Sa_prime = mscData_a(end);
                        
                        % Avoid division by zero
                        if Sa_prime == 0.0
                            Sa_prime = 1e-6;
                        end
                        
                        % Calculate the MSC scaling factor
                        MSC = 1.0/Sa_prime;
                        
                        % Scale the current cycle to its equivalent
                        % value
                        mscCycles(i) = cycles(i)*MSC;
                        
                        setappdata(0, 'multiaxial_gauge_fatigue_warning_001', 1.0)
                    elseif Sm(i) > mscData_m(1.0)
                        Sa_prime = mscData_a(1.0);
                        
                        % Avoid division by zero
                        if Sa_prime == 0.0
                            Sa_prime = 1e-6;
                        end
                        
                        % Calculate the MSC scaling factor
                        MSC = 1.0/Sa_prime;
                        
                        % Scale the current cycle to its equivalent
                        % value
                        mscCycles(i) = cycles(i)*MSC;
                        
                        setappdata(0, 'multiaxial_gauge_fatigue_warning_001', 1.0)
                    elseif isempty(find(mscData_m == Sm(i), 1.0)) == 0.0
                        % The mean stress of the current cycle is an
                        % exact match so there is no need to interpolate
                        
                        Sa_prime = mscData_a(find(mscData_m == Sm(i), 1.0));
                        
                        % Avoid division by zero
                        if Sa_prime == 0.0
                            Sa_prime = 1e-6;
                        end
                        
                        % Calculate the MSC scaling factor
                        MSC = 1.0/Sa_prime;
                        
                        % Scale the current cycle to its equivalent
                        % value
                        mscCycles(i) = cycles(i)*MSC;
                    else
                        % Find which two mean stress points the cycle lies
                        % between
                        for j = 1:length(mscData_m) - 1.0
                            if (Sm(i) < mscData_m(j)) && (Sm(i) > mscData_m(j + 1.0))
                                Sm_lo = mscData_m(j);
                                Sm_lo_j = j;
                                
                                Sm_hi = mscData_m(j + 1.0);
                                Sm_hi_j = j + 1.0;
                                break
                            end
                        end
                        
                        % Get the corresponding values of the stress
                        % amplitude data points
                        Sa_lo = mscData_a(Sm_lo_j);
                        Sa_hi = mscData_a(Sm_hi_j);
                        
                        % Make the equation of the straight line
                        % joining the two Sm-Sa data points
                        m = (Sa_hi - Sa_lo)/(Sm_hi - Sm_lo);
                        
                        Sa_prime = m.*(Sm(i) - Sm_hi) + Sa_hi;
                        
                        % Avoid division by zero
                        if Sa_prime == 0.0
                            Sa_prime = 1e-6;
                        end
                        
                        % Calculate the MSC scaling factor
                        MSC = 1.0/Sa_prime;
                        
                        % Scale the current cycle to its equivalent
                        % value
                        mscCycles(i) = cycles(i)*MSC;
                    end
                end
            end
        end
        
        %% Damage calculation for Brown-Miller algorithm
        function damage = dcBM(cycles, msCorrection, cycles_Stress,...
                pairs_Stress, pairs, uts, ucs, Sf, b, Ef, c, E, Nf,...
                ktn, ndCompression)
            
            %% Initialise variables
            % Get the endurance limit
            modifyEnduranceLimit = getappdata(0, 'multiaxialFatigue_modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'multiaxialFatigue_ndEndurance');
            cyclesToRecover = getappdata(0, 'multiaxialFatigue_cyclesToRecover');
            enduranceScale = getappdata(0, 'multiaxialFatigue_enduranceScaleFactor');
            
            %% Get the fatigue limit
            if msCorrection == 2.0
                signalLength = length(cycles_Stress);
                fatigueLimit = getappdata(0, 'fatigueLimit_stress');
                damagePairs = pairs_Stress;
                damageCycles = cycles_Stress;
            else
                signalLength = length(cycles);
                fatigueLimit = getappdata(0, 'fatigueLimit_strain');
                damagePairs = pairs;
                damageCycles = cycles;
            end
            fatigueLimit_original = fatigueLimit;
            cumulativeDamage = zeros(1.0, signalLength);
            
            %% Perform mean stress correction if applicable
            if msCorrection > 0.0
                [cycles, morrowSf] = multiaxialAnalysis.msc(uts, ucs,...
                    msCorrection, cycles, cycles_Stress, pairs_Stress);
            end
            
            if msCorrection == 1.0
                if length(morrowSf) < length(cycles)
                    diff = length(cycles) - length(morrowSf);
                    morrowSf = [morrowSf', linspace(Sf, Sf, diff)];
                end
            elseif msCorrection == 2.0
                BM = E*((1.0./ktn).*(((((1.65*Sf))/E)*(Nf).^b) + (1.75*Ef)*((Nf).^c)));
            else
                BM = (1.0./ktn).*(((((1.65*Sf))/E)*(Nf).^b) + (1.75*Ef)*((Nf).^c));
            end
            
            for index = 1:signalLength
                % If the cycle is purely compressive, assume no damage
                if (min(damagePairs(index, :)) <= 0.0 && max(damagePairs(index, :)) <= 0.0) && (ndCompression == 1.0)
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                % Modify the endurance limit if applicable
                [fatigueLimit, zeroDamage] = multiaxialAnalysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, damageCycles(index), cyclesToRecover, enduranceScale);
                
                if zeroDamage == 1.0
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                %{
                    If the current cycle is negative, continue to the
                    next value in order to avoid complex damage values
                %}
                if damageCycles(index) <= 0.0
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                if msCorrection == 1.0
                    % Apply Morrow mean stress correction
                    BM = (1.0./ktn).*((((1.65*morrowSf(index))/E)*(Nf).^b) + (1.75*Ef)*((Nf).^c));
                end
                    
                if damageCycles(index) > max(BM)
                    life = 0.0;
                elseif damageCycles(index) < min(BM)
                    life = inf;
                elseif any(BM == damageCycles(index)) == 1.0
                    pos = find(BM == damageCycles(index));
                    life = Nf(pos); %#ok<FNDSB>
                else
                    life = 10^(interp1(log10(BM), log10(Nf), log10(damageCycles(index)), 'linear', 'extrap'));
                end
                
                if life < 0.0
                    life = 0.0;
                end
                
                % Invert the life value to get the damage
                cumulativeDamage(index) = (1.0/life);
            end
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            damage = sum(cumulativeDamage);
        end
        
        %% Damage calculation for principal strain algorithm
        function damage = dcPS(cycles, msCorrection, cycles_Stress,...
                pairs_Stress, pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                ndCompression)
            
            %% Initialise variables
            % Get the endurance limit
            modifyEnduranceLimit = getappdata(0, 'multiaxialFatigue_modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'multiaxialFatigue_ndEndurance');
            cyclesToRecover = getappdata(0, 'multiaxialFatigue_cyclesToRecover');
            enduranceScale = getappdata(0, 'multiaxialFatigue_enduranceScaleFactor');
            
            %% Get the fatigue limit
            if msCorrection == 2.0
                signalLength = length(cycles_Stress);
                fatigueLimit = getappdata(0, 'fatigueLimit_stress');
                damagePairs = pairs_Stress;
                damageCycles = cycles_Stress;
            else
                signalLength = length(cycles);
                fatigueLimit = getappdata(0, 'fatigueLimit_strain');
                damagePairs = pairs;
                damageCycles = cycles;
            end
            fatigueLimit_original = fatigueLimit;
            cumulativeDamage = zeros(1.0, signalLength);
            
            %% Perform mean stress correction if applicable
            if msCorrection > 0.0
                [cycles, morrowSf] = multiaxialAnalysis.msc(uts, ucs,...
                    msCorrection, cycles, cycles_Stress, pairs_Stress);
            end

            if msCorrection == 1.0
                if length(morrowSf) < length(cycles)
                    diff = length(cycles) - length(morrowSf);
                    morrowSf = [morrowSf', linspace(Sf, Sf, diff)];
                end
            elseif msCorrection == 2.0
                BM = E*((1.0./ktn).*((((Sf)/E)*(Nf).^b) + Ef*((Nf).^c)));
            else
                BM = (1.0./ktn).*((((Sf)/E)*(Nf).^b) + Ef*((Nf).^c));
            end
            
            for index = 1:signalLength
                % If the cycle is purely compressive, assume no damage
                if (min(damagePairs(index, :)) <= 0.0 && max(damagePairs(index, :)) <= 0.0) && (ndCompression == 1.0)
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                % Modify the endurance limit if applicable
                [fatigueLimit, zeroDamage] = multiaxialAnalysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, damageCycles(index), cyclesToRecover, enduranceScale);
                
                if zeroDamage == 1.0
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                %{
                    If the current cycle is negative, continue to the
                    next value in order to avoid complex damage values
                %}
                if damageCycles(index) <= 0.0
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                    
                if msCorrection == 1.0
                    % Apply Morrow mean stress correction
                    BM = (1.0./ktn).*((((morrowSf(index))/E)*(Nf).^b) + Ef*((Nf).^c));
                end
                
                if damageCycles(index) > max(BM)
                    life = 0.0;
                elseif damageCycles(index) < min(BM)
                    life = inf;
                elseif any(BM == damageCycles(index)) == 1.0
                    pos = find(BM == damageCycles(index));
                    life = BM(pos); %#ok<FNDSB>
                else
                    life = 10^(interp1(log10(BM), log10(Nf), log10(damageCycles(index)), 'linear', 'extrap'));
                end
                
                if life < 0.0
                    life = 0.0;
                end
                
                % Invert the life value to get the damage
                cumulativeDamage(index) = (1.0/life);
            end
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            damage = sum(cumulativeDamage);
        end
        
        %% Post analysis at worst item for Brown-Miller algorithm
        function [] = worstItemAnalysis_SBBM(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, phiC, thetaC, signalLength, msCorrection, precision,...
                step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                ndCompression)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Stress buffers
            normalStrain = zeros(1.0, signalLength);
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
                
                % Calculate the transform strain tensor for the current plane
                for y = 1:1:signalLength
                    S_prime{y}=Q'*St{y}*Q;
                end
                
                % Calculate strain components for the first face of rotated strain matrix
                for i = 1:signalLength
                    normalStrain(i)=S_prime{i}(1.0, 1.0); % Normal strain on that plane
                    tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear strain on that plane
                    tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear strain on that plane
                end
                
                % Get the maximum shear strain on the current plane
                number = 0.0;
                for x = 1:signalLength
                    for y = 1:signalLength
                        number = number + 1.0;
                        luku = ((tauXY(x) - tauXY(y))^2 + (tauXZ(x) - tauXZ(y))^2 )^0.5;
                        distance(number) = luku;
                    end
                end
                
                % Maximum shear strain range
                tn(thetaIndex) = max(distance);
                
                % Normal strain is maximum over time
                sn(thetaIndex) = max(normalStrain);
                
                % Resultant shear strain history on the current plane
                shearStrain = sqrt(tauXY.^2 + tauXZ.^2);
                
                % Apply sign to resultant shear strain
                if signConvention == 2.0
                    % Sign from maximum strain
                    sign_value = sign(Exx);
                else
                    % Sign from hydrostatic strain
                    sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                end
                sign_value(sign_value == 0.0) = 1.0;
                shearStrain = shearStrain.*sign_value;
                
                % Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    
                    % Get the strain cycle
                    amplitudes_normal = 0.5*(max(normalStrain) - min(normalStrain));
                    amplitudes_shear = 0.5*(max(shearStrain) - min(shearStrain));
                    amplitudes = amplitudes_normal + amplitudes_shear;
                    
                    pairs_normal = [min(normalStrain), max(normalStrain)];
                    pairs_shear = [min(shearStrain), max(shearStrain)];
                    pairs = pairs_normal + pairs_shear;
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcBM(damageParamAll,...
                        msCorrection, 0.0, 0.0, pairs, uts, ucs, Sf, b,...
                        Ef, c, E, Nf, ktn, ndCompression); 
                else
                    % Get the strain cycles
                    % Rainflow the normal strain
                    rfData_normal = analysis.rainFlow_2(normalStrain);
                    
                    % Rainflow the shear strain
                    rfData_shear = analysis.rainFlow_2(shearStrain);
                    
                    % Get rainflow pairs from rfData
                    [pairs, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                    
                    % Get the amplitudes from the rainflow pairs
                    [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                    [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                    damageParamAll = amplitudes_normal + amplitudes_shear;
                    amplitudes = damageParamAll;
                    
                    % Calculate the SBBM parameter on this plane
                    damageParam = max(damageParamAll);
                    
                    % Add the SBBM parameter to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    % Perform damage calculation on this plane
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcBM(damageParamAll,...
                        msCorrection, 0.0, 0.0, pairs, uts, ucs, Sf, b,...
                        Ef, c, E, Nf, ktn, ndCompression); 
                end
                
                % Save data for history output
                if theta == thetaC
                    setappdata(0, 'CS', shearStrain)
                    setappdata(0, 'CN', normalStrain)
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
        
        %% Post analysis at worst item for Brown-Miller algorithm (NONLINEAR)
        function [] = worstItemAnalysis_SBBM_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, phiC, thetaC, signalLength, msCorrection, precision,...
                step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                S11, S22, S33, S12, S13, S23, ndCompression)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Create the stress tensor
            St_Stress = cell(1.0, signalLength);
            for i = 1:signalLength
                St_Stress{i} = [S11(i), S12(i), S13(i); S12(i), S22(i), S23(i); S13(i), S23(i), S33(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Initialize matrices for normal and shear stress components on each plane
            sn_Stress = zeros(1.0, precision);
            tn_Stress = zeros(1.0, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            tauXY = zeros(1.0, signalLength);
            tauXZ = zeros(1.0, signalLength);
            S_prime = cell(1.0, signalLength);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            tauXY_Stress = zeros(1.0, signalLength);
            tauXZ_Stress = zeros(1.0, signalLength);
            S_prime_Stress = cell(1.0, signalLength);
            
            % Maximum chord buffer
            distance = zeros(1.0, signalLength^2);
            distance_Stress = zeros(1.0, signalLength^2);
            
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
                
                % Calculate the transform stress/strain tensor for the current plane
                for y = 1:1:signalLength
                    S_prime{y}=Q'*St{y}*Q;
                    S_prime_Stress{y}=Q'*St_Stress{y}*Q;
                end
                
                % Calculate stress/strain components for the first face of rotated strain matrix
                for i = 1:signalLength
                    normalStrain(i)=S_prime{i}(1.0, 1.0); % Normal strain on that plane
                    tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear strain on that plane
                    tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear strain on that plane
                    
                    normalStress(i)=S_prime_Stress{i}(1.0, 1.0); % Normal stress on that plane
                    tauXY_Stress(i)=S_prime_Stress{i}(1.0, 2.0);  % Shear stress on that plane
                    tauXZ_Stress(i)=S_prime_Stress{i}(1.0, 3.0);  % Shear stress on that plane
                end
                
                % Get the maximum shear strain on the current plane
                number = 0.0;
                for x = 1:signalLength
                    for y = 1:signalLength
                        number = number + 1.0;
                        luku = ((tauXY(x) - tauXY(y))^2 + (tauXZ(x) - tauXZ(y))^2 )^0.5;
                        distance(number) = luku;
                        
                        luku_Stress = ((tauXY_Stress(x) - tauXY_Stress(y))^2 + (tauXZ_Stress(x) - tauXZ_Stress(y))^2 )^0.5;
                        distance_Stress(number) = luku_Stress;
                    end
                end
                
                % Maximum shear stress/strain range
                tn(thetaIndex) = max(distance);
                tn_Stress(thetaIndex) = max(distance_Stress);
                
                % Normal stress/strain is maximum over time
                sn(thetaIndex) = max(normalStrain);
                sn_Stress(thetaIndex) = max(normalStress);
                
                % Resultant shear stress/strain history on the current plane
                shearStrain = sqrt(tauXY.^2 + tauXZ.^2);
                shearStress = sqrt(tauXY_Stress.^2 + tauXZ_Stress.^2);
                
                % Apply sign to resultant shear stress/strain
                if signConvention == 2.0
                    % Sign from maximum strain
                    sign_value = sign(Exx);
                else
                    % Sign from hydrostatic strain
                    sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                end
                sign_value(sign_value == 0.0) = 1.0;
                shearStrain = shearStrain.*sign_value;
                shearStress = shearStress.*sign_value;
                
                % Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    
                    % Get the strain cycle
                    amplitudes_normal = 0.5*(max(normalStrain) - min(normalStrain));
                    amplitudes_shear = 0.5*(max(shearStrain) - min(shearStrain));
                    amplitudes = amplitudes_normal + amplitudes_shear;
                    
                    pairs_normal = [min(normalStrain), max(normalStrain)];
                    pairs_shear = [min(shearStrain), max(shearStrain)];
                    pairs = pairs_normal + pairs_shear;
                    
                    % Get the stress cycle
                    amplitudes_normal = 0.5*(max(normalStress) - min(normalStress));
                    amplitudes_shear = 0.5*(max(shearStress) - min(shearStress));
                    amplitudes_Stress = amplitudes_normal + amplitudes_shear;
                    
                    pairs_normal = [min(normalStress), max(normalStress)];
                    pairs_shear = [min(shearStress), max(shearStress)];
                    pairs_Stress = pairs_normal + pairs_shear;
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcBM(damageParamAll,...
                        msCorrection, amplitudes_Stress, pairs_Stress,...
                        pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                        ndCompression); 
                else
                    % Get the strain cycles
                    % Rainflow the normal strain
                    rfData_normal = analysis.rainFlow_2(normalStrain);
                    
                    % Rainflow the shear strain
                    rfData_shear = analysis.rainFlow_2(shearStrain);
                    
                    % Get rainflow pairs from rfData
                    [pairs, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                    
                    % Get the amplitudes from the rainflow pairs
                    [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                    [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                    damageParamAll = amplitudes_normal + amplitudes_shear;
                    amplitudes = damageParamAll;
                    
                    % Get the stress cycles
                    % Rainflow the normal stress
                    rfData_normal = analysis.rainFlow_2(normalStress);
                    
                    % Rainflow the shear stress
                    rfData_shear = analysis.rainFlow_2(shearStress);
                    
                    % Get rainflow pairs from rfData
                    [pairs_Stress, pairs_normal, pairs_shear] = multiaxialAnalysis.getConsistentPairs(rfData_normal, rfData_shear);
                    
                    % Get the amplitudes from the rainflow pairs
                    [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
                    [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
                    amplitudes_Stress = amplitudes_normal + amplitudes_shear;
                    
                    % Calculate the SBBM parameter on this plane
                    damageParam = max(damageParamAll);
                    
                    % Add the SBBM parameter to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    % Perform damage calculation on this plane
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcBM(damageParamAll,...
                        msCorrection, amplitudes_Stress, pairs_Stress,...
                        pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                        ndCompression); 
                end
                
                % Save data for history output
                if theta == thetaC
                    setappdata(0, 'CS', shearStrain)
                    setappdata(0, 'CN', normalStrain)
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
        
        %% Post analysis at worst item for Principal Strain algorithm
        function [] = worstItemAnalysis_PS(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, phiC, thetaC, signalLength, msCorrection, precision,...
                step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                ndCompression)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
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
                
                % Calculate the transform strain tensor for the current plane
                for y = 1:1:signalLength
                    S_prime{y}=Q'*St{y}*Q;
                end
                
                % Calculate strain components for the first face of rotated strain matrix
                for i = 1:signalLength
                    normalStrain(i)=S_prime{i}(1.0, 1.0); % Normal strain on that plane
                    tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear strain on that plane
                    tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear strain on that plane
                end
                
                % Get the maximum shear strain on the current plane
                number = 0.0;
                for x = 1:signalLength
                    for y = 1:signalLength
                        number = number + 1.0;
                        luku = ((tauXY(x) - tauXY(y))^2 + (tauXZ(x) - tauXZ(y))^2 )^0.5;
                        distance(number) = luku;
                    end
                end
                    
                % Maximum shear strain range
                tn(thetaIndex) = max(distance);
                
                % Normal strain is maximum over time
                sn(thetaIndex) = max(normalStrain);
                
                % Resultant shear strain history on the current plane
                shearStrain = sqrt(tauXY.^2 + tauXZ.^2);
                
                % Apply sign to resultant shear strain
                if signConvention == 2.0
                    % Sign from maximum strain
                    sign_value = sign(S1);
                else
                    % Sign from hydrostatic strain
                    sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                end
                sign_value(sign_value == 0.0) = 1.0;
                shearStrain = shearStrain.*sign_value;
                
                % Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    amplitudes = 0.5*(max(normalStrain) - min(normalStrain));
                    pairs = [min(normalStrain), max(normalStrain)];
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcPS(damageParamAll,...
                        msCorrection, 0.0, 0.0, pairs, uts, ucs, Sf, b,...
                        Ef, c, E, Nf, ktn, ndCompression); 
                else
                    % Now rainflow the SBBM parameter
                    rfData = analysis.rainFlow_2(normalStrain);
                    
                    % Get rainflow pairs from rfData
                    pairs = rfData(:, 1.0:2.0);
                    
                    % Get the amplitudes from the rainflow pairs
                    [damageParamAll, ~] = analysis.getAmps(pairs);
                    amplitudes = damageParamAll;
                    
                    % Calculate the SBBM parameter on this plane
                    damageParam = max(damageParamAll);
                    
                    % Add the SBBM parameter to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    % Perform damage calculation on this plane
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcPS(damageParamAll,...
                        msCorrection, 0.0, 0.0, pairs, uts, ucs, Sf, b,...
                        Ef, c, E, Nf, ktn, ndCompression); 
                end
                
                % Save data for history output
                if theta == thetaC
                    setappdata(0, 'CS', shearStrain)
                    setappdata(0, 'CN', normalStrain)
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
        
        %% Post analysis at worst item for Principal Strain algorithm (NONLINEAR)
        function [] = worstItemAnalysis_PS_NONLINEAR(Exx, Eyy, Ezz, Exy, Exz,...
                Eyz, phiC, thetaC, signalLength, msCorrection, precision,...
                step, signConvention, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                S11, S22, S33, S12, S13, S23, ndCompression)
            
            % Initialize the damage buffers
            damageParamCube = zeros(1.0, precision);
            damageCube = damageParamCube;
            
            % Create the strain tensor
            St = cell(1.0, signalLength);
            for i = 1:signalLength
                St{i} = [Exx(i), Exy(i), Exz(i); Exy(i), Eyy(i), Eyz(i); Exz(i), Eyz(i), Ezz(i)];
            end
            
            % Create the stress tensor
            St_Stress = cell(1.0, signalLength);
            for i = 1:signalLength
                St_Stress{i} = [S11(i), S12(i), S13(i); S12(i), S22(i), S23(i); S13(i), S23(i), S33(i)];
            end
            
            % Initialize matrices for normal and shear strain components on each plane
            sn = zeros(1.0, precision);
            tn = zeros(1.0, precision);
            
            % Strain buffers
            normalStrain = zeros(1.0, signalLength);
            tauXY = zeros(1.0, signalLength);
            tauXZ = zeros(1.0, signalLength);
            S_prime = cell(1.0, signalLength);
            
            % Stress buffers
            normalStress = zeros(1.0, signalLength);
            tauXY_Stress = zeros(1.0, signalLength);
            tauXZ_Stress = zeros(1.0, signalLength);
            S_prime_Stress = cell(1.0, signalLength);
            
            % Maximum chord buffer
            distance = zeros(1.0, signalLength^2);
            distance_Stress = zeros(1.0, signalLength^2);
            
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
                
                % Calculate the transform strain tensor for the current plane
                for y = 1:1:signalLength
                    S_prime{y}=Q'*St{y}*Q;
                    S_prime_Stress{y}=Q'*St_Stress{y}*Q;
                end
                
                % Calculate strain components for the first face of rotated strain matrix
                for i = 1:signalLength
                    normalStrain(i)=S_prime{i}(1.0, 1.0); % Normal strain on that plane
                    tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear strain on that plane
                    tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear strain on that plane
                    
                    normalStress(i)=S_prime_Stress{i}(1.0, 1.0); % Normal stress on that plane
                    tauXY_Stress(i)=S_prime_Stress{i}(1.0, 2.0);  % Shear stress on that plane
                    tauXZ_Stress(i)=S_prime_Stress{i}(1.0, 3.0);  % Shear stress on that plane
                end
                
                % Get the maximum shear strain on the current plane
                number = 0.0;
                for x = 1:signalLength
                    for y = 1:signalLength
                        number = number + 1.0;
                        luku = ((tauXY(x) - tauXY(y))^2 + (tauXZ(x) - tauXZ(y))^2 )^0.5;
                        distance(number) = luku;
                        
                        luku_Stress = ((tauXY_Stress(x) - tauXY_Stress(y))^2 + (tauXZ_Stress(x) - tauXZ_Stress(y))^2 )^0.5;
                        distance_Stress(number) = luku_Stress;
                    end
                end
                    
                % Maximum shear strain range
                tn(thetaIndex) = max(distance);
                
                % Normal stress/strain is maximum over time
                sn(thetaIndex) = max(normalStrain);
                
                % Resultant shear strain history on the current plane
                shearStrain = sqrt(tauXY.^2 + tauXZ.^2);
                
                % Apply sign to resultant shear strain
                if signConvention == 2.0
                    % Sign from maximum strain
                    sign_value = sign(S1);
                else
                    % Sign from hydrostatic strain
                    sign_value = sign((1.0/3.0)*(Exx + Eyy + Ezz));
                end
                sign_value(sign_value == 0.0) = 1.0;
                shearStrain = shearStrain.*sign_value;
                
                % Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    amplitudes = 0.5*(max(normalStrain) - min(normalStrain));
                    pairs = [min(normalStrain), max(normalStrain)];
                    
                    amplitudes_Stress = 0.5*(max(normalStress) - min(normalStress));
                    pairs_Stress = [min(normalStress), max(normalStress)];
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcPS(damageParamAll,...
                        msCorrection, amplitudes_Stress, pairs_Stress,...
                        pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                        ndCompression); 
                else
                    % Now rainflow the SBBM parameter
                    rfData = analysis.rainFlow_2(normalStrain);
                    rfData_Stress = analysis.rainFlow_2(normalStress);
                    
                    % Get rainflow pairs from rfData
                    pairs = rfData(:, 1.0:2.0);
                    pairs_Stress = rfData_Stress(:, 1.0:2.0);
                    
                    % Get the amplitudes from the rainflow pairs
                    [damageParamAll, ~] = analysis.getAmps(pairs);
                    amplitudes = damageParamAll;
                    [amplitudes_Stress, ~] = analysis.getAmps(pairs_Stress);
                    
                    % Calculate the SBBM parameter on this plane
                    damageParam = max(damageParamAll);
                    
                    % Add the SBBM parameter to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    % Perform damage calculation on this plane
                    damageCube(thetaIndex) =...
                        multiaxialAnalysis.dcPS(damageParamAll,...
                        msCorrection, amplitudes_Stress, pairs_Stress,...
                        pairs, uts, ucs, Sf, b, Ef, c, E, Nf, ktn,...
                        ndCompression); 
                end
                
                % Save data for history output
                if theta == thetaC
                    setappdata(0, 'CS', shearStrain)
                    setappdata(0, 'CN', normalStrain)
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
        
        %% Combine shear and normal quantities for Brown-Miller analysis
        function [pairs, pairs_normal, pairs_shear] = getConsistentPairs(normals, shears)
            %{
                Normal and shear pairs are cycle counted separately before
                being combined. Therefore it is possible that after the
                cycle counting process, the number of normal and shear
                pairs is not the same. This function corrects the pair data
                so that the number of normal and shear pairs is the same,
                allowing for them to be combined into a singe effective
                pair list for the resultant amplitude calculation
            %}
            
            % Make sure the number of cycle in NORMALS and SHEARS is the same
            [numberNormals, ~] = size(normals);
            [numberShears, ~] = size(shears);
            
            % Append emtpy cycles to the shorter cycle matrix
            if numberNormals < numberShears
                normals = [normals; zeros(numberShears - numberNormals, 4.0)];
            elseif numberShears < numberNormals
                shears = [shears; zeros(numberNormals - numberShears, 4.0)];
            end
            
            % Get the individual normal and shear data
            pairs_normal = normals(:, 1.0:2.0);
            pairs_shear = shears(:, 1.0:2.0);
            
            % Get the combined pair data
            pairs = pairs_normal + pairs_shear;
        end
        
        %% Modify the endurance limit
        function [fatigueLimit, zeroDamage] = modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycle, cyclesToRecover, enduranceScale)
            %{
                Flag to indicate whether the current cycle will result in
                fatigue damage
            %}
            zeroDamage = 0.0;
            
            if (modifyEnduranceLimit == 1.0) && (ndEndurance == 1.0)
                %{
                    Treatment of the endurance limit is enabled by the
                    user. Zero damage for cycles under the endurance limit
                    must also be enabled
                %}
                if cycle < fatigueLimit
                    %{
                        The current the cycle is below the fatigue limit, so
                        assume no damage
                    %}
                    zeroDamage = 1.0;
                elseif cycle >= fatigueLimit_original
                    %{
                        The current cycle exceeds the unmodified endurance
                        limit. Reduce the endurance limit to 25% of the
                        original value
                    %}
                    fatigueLimit = enduranceScale*fatigueLimit_original;
                end
                
                if (fatigueLimit < fatigueLimit_original) && (cycle < fatigueLimit_original)
                    %{
                        The endurance limit was modified by a previous cycle. If the
                        current cycle and endurance limit are less than the unmodified
                        endurance limit, apply an increment of recovery to the
                        endurance limit
                    %}
                    fatigueLimit = fatigueLimit + ((fatigueLimit_original - (enduranceScale*fatigueLimit_original))/cyclesToRecover);
                end                
            elseif (isempty(fatigueLimit) == 0.0) && (ndEndurance == 1.0)
                if cycle < fatigueLimit
                    %{
                        Treatment of the endurance limit is not enabled by
                        the user, zero damage for cycles below the
                        endurance limit is enabled, the endurance limit is
                        defined and the current cycle is below the
                        endurance limit
                    %}
                    zeroDamage = 1.0;
                end
            end
        end
    end
end
classdef algorithm_nasa < handle
%ALGORITHM_NASA    QFT class for NASALIFE algorithm.
%   This class contains methods for the NASALIFE fatigue analysis
%   algorithm.
%   
%   ALGORITHM_NASA is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_ns,
%   algorithm_sbbm, algorithm_sip, algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.8 NASALIFE
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 12-May-2017 15:25:52 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalAmplitudes, nodalPairs, nodalDamage,...
                nodalDamageParameter] = main(Sxx, Syy, Szz, Txy, Tyz, Txz,...
                signalLength, node, nodalDamage, nodalAmplitudes, nodalPairs,...
                nodalDamageParameter, s1i, s2i, s3i, vonMisesSign,...
                gateTensors, tensorGate, vm, nasalifeParameter)
            
            %% Get fatigue properties
            Sf = getappdata(0, 'Sf');
            b = getappdata(0, 'b');
            
            %% Arrange stress history into a sequence of stress tensors
            tensor = zeros(3.0, 3.0, signalLength);
            
            for i = 1:signalLength
                tensor(:, :, i) = [Sxx(i), Txy(i), Txz(i); Txy(i), Syy(i), Tyz(i); Txz(i), Tyz(i), Szz(i)];
            end
            
            % Apply sign convention to the von Mises stress
            if vonMisesSign == 2.0
                % Sign from maximum stress
                vm = vm.*sign(s1i);
            else
                % Sign from hydrostatic stress
                vm = vm.*sign((1/3)*(s1i + s2i + s3i));
            end
            
            % Combination indices
            combinations = nchoosek(linspace(1.0, signalLength, signalLength), 2.0);
            [N, ~] = size(combinations);
            
            %% Find the Most Damaging Major Cycle (MDMC)
            damage = zeros(1.0, N);
            
            for i = 1.0:N
                % Get the individual mean stress components
                Sxm = 0.5*(max(Sxx(combinations(i, :))) + min(Sxx(combinations(i, :))));
                Sym = 0.5*(max(Syy(combinations(i, :))) + min(Syy(combinations(i, :))));
                Szm = 0.5*(max(Szz(combinations(i, :))) + min(Szz(combinations(i, :))));
                
                Txym = 0.5*(max(Txy(combinations(i, :))) + min(Txy(combinations(i, :))));
                Tyzm = 0.5*(max(Tyz(combinations(i, :))) + min(Tyz(combinations(i, :))));
                Txzm = 0.5*(max(Txz(combinations(i, :))) + min(Txz(combinations(i, :))));
                
                %% Get the individual stress amplitude components
                Sxa = 0.5*(max(Sxx(combinations(i, :))) - min(Sxx(combinations(i, :))));
                Sya = 0.5*(max(Syy(combinations(i, :))) - min(Syy(combinations(i, :))));
                Sza = 0.5*(max(Szz(combinations(i, :))) - min(Szz(combinations(i, :))));
                
                Txya = 0.5*(max(Txy(combinations(i, :))) - min(Txy(combinations(i, :))));
                Tyza = 0.5*(max(Tyz(combinations(i, :))) - min(Tyz(combinations(i, :))));
                Txza = 0.5*(max(Txz(combinations(i, :))) - min(Txz(combinations(i, :))));
                
                %{
                    Get the effective stress parameter, depending on the
                    user-specified setting
                %}
                
                switch nasalifeParameter
                    case 1.0
                        % Check the principal stresses of this cycle pair
                        % in case the modifier is required
                        s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                        s1 = s1(1.0);
                        s1 = s1i(s1);
                        
                        s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                        s3 = s3(1.0);
                        s3 = s3i(s3);
                        
                        % Get the equivalent mean stress of the cycle
                        if sign(s1) ~= sign(s3)
                            % Get the equivalent mean stress of the cycle
                            % (Modified Manson MacKnight)
                            %{
                                In the NASALIFE document, this equation is
                                quoted without the SIGN function, resulting
                                in the incorrect value of the mean stress.
                                The equation below has been modified to fix
                                this issue.
                            %}
                            Sm = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        else
                            % Get the equivalent mean stress of the cycle
                            % (Manson MacKnight)
                            Sm = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        end
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    case 2.0
                        % Sines
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = Sxm + Sym + Szm;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2) + Sm);
                    case 3.0
                        % Smith-Watson-Topper
                        
                        % Get the maximum and minimum value of the first
                        % principal stress
                        s1_max = max(s1i(combinations(i, :)));
                        s1_min = min(s1i(combinations(i, :)));
                        
                        % The mean stress is assumed to be zero
                        Sm = 0.0;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(s1_max*(s1_max - s1_min));
                    case 4.0
                        % R-Ratio Sines
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = Sxm + Sym + Szm;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    case 5.0
                        % Effective method
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = sqrt(2.0)*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2)) - Sa;
                    otherwise
                        % Check the principal stresses of this cycle pair
                        % in case the modifier is required
                        s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                        s1 = s1(1.0);
                        s1 = s1i(s1);
                        
                        s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                        s3 = s3(1.0);
                        s3 = s3i(s3);
                        
                        % Get the equivalent mean stress of the cycle
                        if sign(s1) ~= sign(s3)
                            % Get the equivalent mean stress of the cycle
                            % (Modified Manson MacKnight)
                            Sm = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        else
                            % Get the equivalent mean stress of the cycle
                            % (Manson MacKnight)
                            Sm = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        end
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                end
                
                % Get the A-ratio and R-ratio
                A = Sa/Sm;
                
                if (isinf(A) == 1.0) || (A == -1.0)
                    %{
                        If the mean stress is zero, A will be INF and R will be
                        NaN. If this is the case, override the value of R to -1
                    %}
                    % OR:
                    %{
                        If A -1, R will be INF and the equivalent stress
                        amplitude will also be INF. If this is the case,
                        override the value of R to -1
                    %}
                    R = -1.0;
                else
                    R = (1.0 - A)/(1.0 + A);
                    
                    if R < -1.0
                        %{
                            NASALIFE does not allow for additional benefit
                            arising from the effect of negative mean stress
                        %}
                        R = -1.0;
                    end
                end
                
                % Get the gamma parameter
                gamma = algorithm_nasa.getGamma(R);
                
                % Correct the amplitude for the effect of mean stress
                Saw = algorithm_nasa.walker(R, A, Sa, nasalifeParameter, gamma);
                
                % Get the damage of the current cycle
                damage(i) = (0.5*(Saw/Sf)^(1.0/b))^-1.0;
            end
            
            %%
            %{
                If the load signal is less than 3.0 points, the worst cycle
                is already known. Use the existing damage value
            %}
            if N == 1.0
                % Store worst cycles for current item
                nodalAmplitudes{node} = Saw;
                nodalPairs{node} = vm;
                
                % Get current damage parameter
                nodalDamageParameter(node) = Saw;
                
                % Perform a damage calculation on the current analysis item
                nodalDamage(node) = damage(1.0);
            else
                %{
                    The load history is greater than 2.0 points, therefore
                    resolve the history onto the plane of maximum
                    octahedral stress and rainflow cycle count the shear
                    parameter
                %}
                
                %% Get the tensor pair corresponding to the largest damage
                worstTensorPair = find(damage == max(damage));
                worstTensorPair = worstTensorPair(1.0);
                
                % Get the tensor difference
                indexA = combinations(worstTensorPair, 1.0);
                tensorA = tensor(:, :, indexA);
                
                indexB = combinations(worstTensorPair, 2.0);
                tensorB = tensor(:, :, indexB);
                
                % Choose tensor with larger von Mises stress
                vonMisesA = sqrt(0.5.*((Sxx(indexA) - Syy(indexA)).^2 + (Syy(indexA) - Szz(indexA)).^2 + (Szz(indexA) - Sxx(indexA)).^2 + 6.*(Txy(indexA).^2 + Tyz(indexA).^2 + Txz(indexA).^2)));
                vonMisesB = sqrt(0.5.*((Sxx(indexB) - Syy(indexB)).^2 + (Syy(indexB) - Szz(indexB)).^2 + (Szz(indexB) - Sxx(indexB)).^2 + 6.*(Txy(indexB).^2 + Tyz(indexB).^2 + Txz(indexB).^2)));
                
                % Which way to take the difference?
                if vonMisesA >= vonMisesB
                    worstTensor = tensorA - tensorB;
                elseif vonMisesA < vonMisesB
                    worstTensor = tensorB - tensorA;
                end
                
                eigenStress = eig(worstTensor);
                worstPrincipalTensor = [max(eigenStress), 0, 0; 0, median(eigenStress), 0; 0, 0, min(eigenStress)];
                
                %% Get the rotation matrix
                R = [sqrt(worstPrincipalTensor(1.0, 1.0)/worstTensor(1.0, 1.0)), 0.0, 0.0; 0.0, sqrt(worstPrincipalTensor(2.0, 2.0)/worstTensor(2.0, 2.0)), 0.0; 0.0, 0.0, sqrt(worstPrincipalTensor(3.0, 3.0)/worstTensor(3.0, 3.0))];
                
                R(isinf(R)) = 0.0;
                R(isnan(R)) = 0.0;
                
                % If the R-matrix is all zero, there is no damage
                if any(R) == 0.0
                    % Store worst cycles for current item
                    nodalAmplitudes{node} = 0.0;
                    nodalPairs{node} = [0.0, 0.0];
                    
                    % Get current damage parameter
                    nodalDamageParameter(node) = 0.0;
                    
                    % Perform a damage calculation on the current analysis item
                    nodalDamage(node) = 0.0;
                    
                    return
                end
                
                % Transform the load history to align the tensors with the principal directions of the MDMC
                octahedralTensor = zeros(3.0, 3.0, signalLength);
                for i = 1:signalLength
                    octahedralTensor(:, :, i) = R'.*tensor(:, :, i).*R;
                end
                
                % Get the octahedral shear stress tensor history for the loading
                octahedralShearStress = zeros(1.0, signalLength);
                for i = 1:signalLength
                    octahedralShearStress(i) = (1.0/3.0)*sqrt((octahedralTensor(1.0, 1.0, i) - octahedralTensor(2.0, 2.0, i))^2.0 +...
                        (octahedralTensor(2.0, 2.0, i) - octahedralTensor(3.0, 3.0, i))^2.0 +...
                        (octahedralTensor(1.0, 1.0, i) - octahedralTensor(3.0, 3.0, i))^2.0);
                end
                
                %% Rainflow count the octahedral shear stress
                % Gate the tensors if applicable
                if gateTensors > 0.0
                    octahedralShearStress = analysis.gateTensors(octahedralShearStress, gateTensors, tensorGate);
                end
                
                % Filter the octahedral shear stress
                octahedralShearStress = analysis.preFilter(octahedralShearStress, length(octahedralShearStress));
                if (length(octahedralShearStress) ~= signalLength) && (length(octahedralShearStress) > 2.0)
                    if octahedralShearStress(end) > octahedralShearStress(1.0)
                        octahedralShearStress(1.0) = [];
                    else
                        octahedralShearStress(end) = [];
                    end
                end
                
                % Rainflow cycle count the octahedral shear stress
                rfData = analysis.rainFlow(octahedralShearStress);
                
                % Get rainflow pair indices from rfData
                combinations = rfData(:, 3:4);
                [numberOfCycles, ~] = size(combinations);
                
                %% Use the pair indices to locate the equivalent stress cycles
                Sm = zeros(1.0, numberOfCycles);
                Sa = zeros(1.0, numberOfCycles);
                pairs = zeros(numberOfCycles, 2.0);
                
                for i = 1:numberOfCycles
                    if combinations(i, 1.0) > signalLength
                        combinations(i, 1.0) = signalLength;
                    end
                    if combinations(i, 2.0) > signalLength
                        combinations(i, 2.0) = signalLength;
                    end
                    
                    % Get the von Mises stress of each cycle. This is the
                    % cycle pair information
                    pairs(i, :) = vm(combinations(i, :));
                    
                    % Get the individual mean stress components
                    Sxm = 0.5*(max(Sxx(combinations(i, :))) + min(Sxx(combinations(i, :))));
                    Sym = 0.5*(max(Syy(combinations(i, :))) + min(Syy(combinations(i, :))));
                    Szm = 0.5*(max(Szz(combinations(i, :))) + min(Szz(combinations(i, :))));
                    
                    Txym = 0.5*(max(Txy(combinations(i, :))) + min(Txy(combinations(i, :))));
                    Tyzm = 0.5*(max(Tyz(combinations(i, :))) + min(Tyz(combinations(i, :))));
                    Txzm = 0.5*(max(Txz(combinations(i, :))) + min(Txz(combinations(i, :))));
                    
                    %% Get the individual stress amplitude components
                    Sxa = 0.5*(max(Sxx(combinations(i, :))) - min(Sxx(combinations(i, :))));
                    Sya = 0.5*(max(Syy(combinations(i, :))) - min(Syy(combinations(i, :))));
                    Sza = 0.5*(max(Szz(combinations(i, :))) - min(Szz(combinations(i, :))));
                    
                    Txya = 0.5*(max(Txy(combinations(i, :))) - min(Txy(combinations(i, :))));
                    Tyza = 0.5*(max(Tyz(combinations(i, :))) - min(Tyz(combinations(i, :))));
                    Txza = 0.5*(max(Txz(combinations(i, :))) - min(Txz(combinations(i, :))));
                    
                    % Get the effective stress parameter, depending on the
                    % user-specified setting
                    nasalifeParameter = getappdata(0, 'nasalifeParameter');
                    
                    switch nasalifeParameter
                        case 1.0
                            % Check the principal stresses of this cycle pair
                            % in case the modifier is required
                            s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                            s1 = s1(1.0);
                            s1 = s1i(s1);
                            
                            s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                            s3 = s3(1.0);
                            s3 = s3i(s3);
                            
                            % Get the equivalent mean stress of the cycle
                            if sign(s1) ~= sign(s3)
                                % Get the equivalent mean stress of the cycle
                                % (Modified Manson MacKnight)
                                Sm(i) = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            else
                                % Get the equivalent mean stress of the cycle
                                % (Manson MacKnight)
                                Sm(i) = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            end
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        case 2.0
                            % Sines
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = Sxm + Sym + Szm;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2) + Sm(i));
                        case 3.0
                            % Smith-Watson-Topper
                            
                            % Get the maximum and minimum value of the first
                            % principal stress
                            s1_max = max(s1i(combinations(i, :)));
                            s1_min = min(s1i(combinations(i, :)));
                            
                            % The mean stress is assumed to be zero
                            Sm(i) = 0.0;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(s1_max*(s1_max - s1_min));
                        case 4.0
                            % R-Ratio Sines
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = Sxm + Sym + Szm;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        case 5.0
                            % Effective method
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = sqrt(2.0)*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2)) - Sa(i);
                        otherwise
                            % Check the principal stresses of this cycle pair
                            % in case the modifier is required
                            s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                            s1 = s1(1.0);
                            s1 = s1i(s1);
                            
                            s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                            s3 = s3(1.0);
                            s3 = s3i(s3);
                            
                            % Get the equivalent mean stress of the cycle
                            if sign(s1) ~= sign(s3)
                                % Get the equivalent mean stress of the cycle
                                % (Modified Manson MacKnight)
                                Sm(i) = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            else
                                % Get the equivalent mean stress of the cycle
                                % (Manson MacKnight)
                                Sm(i) = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            end
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    end
                end
                
                %% Store worst cycles for current item
                nodalAmplitudes{node} = Sa;
                nodalPairs{node} = pairs;
                
                %% Get current damage parameter
                nodalDamageParameter(node) = max(Sa);
                
                %% Perform a mean stress correction on the nodal damage parameter
                % Get the A-ratio and R-ratio
                maximumMean = find(Sa == nodalDamageParameter(node));
                maximumMean = maximumMean(1.0);
                maximumMean = Sm(maximumMean);
                
                A = nodalDamageParameter(node)/maximumMean;
                if (isinf(A) == 1.0) || (A == -1.0)
                    R = -1.0;
                else
                    R = (1.0 - A)/(1.0 + A);
                    
                    if R < -1.0
                        R = -1.0;
                    end
                end
                
                % Correct the amplitude for the effect of mean stress
                nodalDamageParameter(node) = algorithm_nasa.walker(R, A, nodalDamageParameter(node), nasalifeParameter, gamma);
                
                %% Perform a damage calculation on the current analysis item
                nodalDamage(node) = algorithm_nasa.damageCalculation(Sa, pairs, gamma, nasalifeParameter);
            end
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(Sa, pairs, gamma, nasalifeParameter)
            %% CALCULATE DAMAGE FOR EACH VON MISES CYCLE
            
            % Is the S-N curve derived or direct?
            useSN = getappdata(0, 'useSN');
            
            % Get the residual stress
            residualStress = getappdata(0, 'residualStress');
            
            % Get number of repeats of loading
            repeats = getappdata(0, 'repeats');
            numberOfCycles = length(Sa);
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Get the fatigue limit
            modifyEnduranceLimit = getappdata(0, 'modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'ndEndurance');
            fatigueLimit = getappdata(0, 'fatigueLimit');
            fatigueLimit_original = fatigueLimit;
            enduranceScale = getappdata(0, 'enduranceScaleFactor');
            cyclesToRecover = abs(round(getappdata(0, 'cyclesToRecover')));
            
            % Get the Walker-corrected stress amplitude
            for i = 1:numberOfCycles
                % Get the A-ratio and R-ratio
                A = Sa(i)/(0.5.*(max(pairs(i, :)) + min(pairs(i, :))));
                if (isinf(A) == 1.0) || (A == -1.0)
                    R = -1.0;
                else
                    R = (1.0 - A)/(1.0 + A);
                    
                    if R < -1.0
                        R = -1.0;
                    end
                end
                
                % Correct the amplitude for the effect of mean stress
                Sa(i) = algorithm_nasa.walker(R, A, Sa(i), nasalifeParameter, gamma);
            end
            
            % Plasticity correction
            nlMaterial = getappdata(0, 'nlMaterial');
            
            if nlMaterial == 1.0
                scaleFactors = zeros(1, length(Sa));
                E = getappdata(0, 'E');
                kp = getappdata(0, 'kp');
                np = getappdata(0, 'np');
                
                for i = 1:length(Sa)
                    if Sa(i) == 0.0
                        continue
                    else
                        oldCycle = Sa(i);
                        
                        [~, cycles_i, ~] = css(Sa(i), E, kp, np);
                        cycles_i(1) = []; cycles_i = real(cycles_i);
                        
                        Sa(i) = cycles_i;
                    end
                    
                    scaleFactors(i) = cycles_i/oldCycle;
                end
            else
                scaleFactors = ones(1.0, length(Sa));
            end
            
            if useSN == 1.0 % S-N curve was defined directly
                [cumulativeDamage] = interpolate(cumulativeDamage, pairs, 4.0, numberOfCycles, Sa, scaleFactors, 0.0, 0.0);
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
                    [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, Sa(index), cyclesToRecover, residualStress, enduranceScale);
                    if (zeroDamage == 1.0) && (kt == 1.0)
                        cumulativeDamage(index) = 0.0;
                        continue
                    end
                    
                    %{
                        If the current cycle is negative, continue to the
                        next value in order to avoid complex damage values
                    %}
                    
                    if Sa(index) < 0.0
                        cumulativeDamage(index) = 0.0;
                    else
                        % Divide the LHS by Sf' so that LHS == Nf^b
                        quotient = (Sa(index) + residualStress)/Sf;
                        
                        % Raise the LHS to the power of 1/b so that LHS == Nf
                        life = 0.5*(quotient^(1/b));
                        
                        % If the life was above the knee-point,
                        % re-calculate the life using B2
                        if life > b2Nf
                            life = 0.5*quotient^(1/b2);
                        end
                        
                        % Find the value of Kt at this life and
                        % re-calculate the life if necessary
                        if kt ~= 1.0
                            radius = getappdata(0, 'notchRootRadius');
                            constant = getappdata(0, 'notchSensitivityConstant');
                            
                            ktn = analysis.getKtn(life, constant, radius);
   
                            quotient = (ktn*Sa(index) + residualStress)/Sf;

                            if life > b2Nf
                                life = 0.5*quotient^(1/b2);
                            else
                                life = 0.5*quotient^(1/b);
                            end
                        end
                        
                        % Invert the life value to get the damage
                        cumulativeDamage(index) = 1/life;
                    end
                end
            end
            
            %% SAVE THE CUMULATIVE DAMAGE
            
            setappdata(0, 'cumulativeDamage', cumulativeDamage);
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            
            damage = sum(cumulativeDamage)*repeats;
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis(worstAnalysisItem, G, stress, signalLength, s1i, s2i, s3i, signConvention, gateTensors, tensorGate, nasalifeParameter)
            %% Get the material properties at the worst analysis item
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            for i = 1:G
                groupItems = groupIDBuffer(i).IDs;
                if any(groupItems == worstAnalysisItem) == 1.0
                    break
                end
            end
            
            group_materialProps = getappdata(0, 'group_materialProps');
            
            Sf = group_materialProps(i).Sf;
            b = group_materialProps(i).b;
            
            %% Arrange stress history into a sequence of stress tensors
            tensor = zeros(3.0, 3.0, signalLength);
            
            for i = 1:signalLength
                tensor(:, :, i) = [stress(1.0, i), stress(4.0, i), stress(6.0, i); stress(4.0, i), stress(2.0, i), stress(5.0, i); stress(6.0, i), stress(5.0, i), stress(3.0, i)];
            end
            
            % Combination indices
            combinations = nchoosek(linspace(1.0, signalLength, signalLength), 2.0);
            [N, ~] = size(combinations);
            
            % Find the Most Damaging Major Cycle (MDMC)
            damage = zeros(1.0, N);
            
            % Extract stress components from variable STRESS
            Sxx = stress(1.0, :);
            Syy = stress(2.0, :);
            Szz = stress(3.0, :);
            
            Txy = stress(4.0, :);
            Tyz = stress(5.0, :);
            Txz = stress(6.0, :);
            
            %% Get the von Mises stress
            vm = sqrt(0.5.*((Sxx - Syy).^2 + (Syy - Szz).^2 +...
                (Szz - Sxx).^2 + 6.*(Txy.^2 + Tyz.^2 + Txz.^2)));
            
            % Apply sign to the von Mises stress
            tauXY = s1i - s2i;
            vm = applySignConvention(vm, signConvention, s1i, s2i, s3i, Sxx, Syy, tauXY);
            
            for i = 1.0:N
                % Get the individual mean stress components
                Sxm = 0.5*(max(Sxx(combinations(i, :))) + min(Sxx(combinations(i, :))));
                Sym = 0.5*(max(Syy(combinations(i, :))) + min(Syy(combinations(i, :))));
                Szm = 0.5*(max(Szz(combinations(i, :))) + min(Szz(combinations(i, :))));
                
                Txym = 0.5*(max(Txy(combinations(i, :))) + min(Txy(combinations(i, :))));
                Tyzm = 0.5*(max(Tyz(combinations(i, :))) + min(Tyz(combinations(i, :))));
                Txzm = 0.5*(max(Txz(combinations(i, :))) + min(Txz(combinations(i, :))));
                
                %% Get the individual stress amplitude components
                Sxa = 0.5*(max(Sxx(combinations(i, :))) - min(Sxx(combinations(i, :))));
                Sya = 0.5*(max(Syy(combinations(i, :))) - min(Syy(combinations(i, :))));
                Sza = 0.5*(max(Szz(combinations(i, :))) - min(Szz(combinations(i, :))));
                
                Txya = 0.5*(max(Txy(combinations(i, :))) - min(Txy(combinations(i, :))));
                Tyza = 0.5*(max(Tyz(combinations(i, :))) - min(Tyz(combinations(i, :))));
                Txza = 0.5*(max(Txz(combinations(i, :))) - min(Txz(combinations(i, :))));
                
                switch nasalifeParameter
                    case 1.0
                        % Check the principal stresses of this cycle pair
                        % in case the modifier is required
                        s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                        s1 = s1(1.0);
                        s1 = s1i(s1);
                        
                        s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                        s3 = s3(1.0);
                        s3 = s3i(s3);
                        
                        % Get the equivalent mean stress of the cycle
                        if sign(s1) ~= sign(s3)
                            % Get the equivalent mean stress of the cycle
                            % (Modified Manson MacKnight)
                            Sm = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        else
                            % Get the equivalent mean stress of the cycle
                            % (Manson MacKnight)
                            Sm = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        end
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    case 2.0
                        % Sines
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = Sxm + Sym + Szm;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2) + Sm);
                    case 3.0
                        % Smith-Watson-Topper
                        
                        % Get the maximum and minimum value of the first
                        % principal stress
                        s1_max = max(s1i(combinations(i, :)));
                        s1_min = min(s1i(combinations(i, :)));
                        
                        % The mean stress is assumed to be zero
                        Sm = 0.0;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(s1_max*(s1_max - s1_min));
                    case 4.0
                        % R-Ratio Sines
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = Sxm + Sym + Szm;
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    case 5.0
                        % Effective method
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        
                        % Get the equivalent mean stress of the cycle
                        Sm = sqrt(2.0)*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2)) - Sa;
                    otherwise
                        % Check the principal stresses of this cycle pair
                        % in case the modifier is required
                        s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                        s1 = s1(1.0);
                        s1 = s1i(s1);
                        
                        s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                        s3 = s3(1.0);
                        s3 = s3i(s3);
                        
                        % Get the equivalent mean stress of the cycle
                        if sign(s1) ~= sign(s3)
                            % Get the equivalent mean stress of the cycle
                            % (Modified Manson MacKnight)
                            Sm = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        else
                            % Get the equivalent mean stress of the cycle
                            % (Manson MacKnight)
                            Sm = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                        end
                        
                        % Get the equivalent stress amplitude of the cycle
                        Sa = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                end
                
                % Get the A-ratio and R-ratio
                A = Sa/Sm;
                
                % If the mean stress is zero, A will be INF and R will be
                % NaN. If this is the case, override the value of R to -1
                if (isinf(A) == 1.0) || (A == -1.0)
                    R = -1.0;
                else
                    R = (1.0 - A)/(1.0 + A);
                    
                    if R < -1.0
                        R = -1.0;
                    end
                end
                
                % Get the gamma parameter
                gamma = algorithm_nasa.getGamma(R);

                % Correct the amplitude for the effect of mean stress
                Saw = algorithm_nasa.walker(R, A, Sa, nasalifeParameter, gamma);
                
                % Get the damage of the current cycle
                damage(i) = (0.5*(Saw/Sf)^(1/b))^-1.0;
            end
            
            %%
            
            %% Get the tensor pair corresponding to the largest damage
            worstTensorPair = find(damage == max(damage));
            worstTensorPair = worstTensorPair(1.0);
            
            % Get the tensor difference
            indexA = combinations(worstTensorPair, 1.0);
            tensorA = tensor(:, :, indexA);
            
            indexB = combinations(worstTensorPair, 2.0);
            tensorB = tensor(:, :, indexB);
            
            % Choose tensor with larger von Mises stress
            vonMisesA = sqrt(0.5.*((Sxx(indexA) - Syy(indexA)).^2 + (Syy(indexA) - Szz(indexA)).^2 + (Szz(indexA) - Sxx(indexA)).^2 + 6.*(Txy(indexA).^2 + Tyz(indexA).^2 + Txz(indexA).^2)));
            vonMisesB = sqrt(0.5.*((Sxx(indexB) - Syy(indexB)).^2 + (Syy(indexB) - Szz(indexB)).^2 + (Szz(indexB) - Sxx(indexB)).^2 + 6.*(Txy(indexB).^2 + Tyz(indexB).^2 + Txz(indexB).^2)));
            
            % Which way to take the difference?
            if vonMisesA >= vonMisesB
                worstTensor = tensorA - tensorB;
            elseif vonMisesA < vonMisesB
                worstTensor = tensorB - tensorA;
            end
            
            eigenStress = eig(worstTensor);
            worstPrincipalTensor = [max(eigenStress), 0.0, 0.0; 0.0, median(eigenStress), 0.0; 0.0, 0.0, min(eigenStress)];
            
            %% Get the rotation matrix
            R = [sqrt(worstPrincipalTensor(1.0, 1.0)/worstTensor(1.0, 1.0)), 0.0, 0.0; 0.0, sqrt(worstPrincipalTensor(2.0, 2.0)/worstTensor(2.0, 2.0)), 0.0; 0.0, 0.0, sqrt(worstPrincipalTensor(3.0, 3.0)/worstTensor(3.0, 3.0))];
            
            R(isinf(R)) = 0.0;
            R(isnan(R)) = 0.0;
            
            % If the R-matrix is all zero, there is no damage
            if any(R) == 0.0
                setappdata(0, 'CS', zeros(1.0, signalLength))
                setappdata(0, 'CN', zeros(1.0, signalLength))
                setappdata(0, 'cyclesOnCP', [0.0, 0.0])
                setappdata(0, 'amplitudesOnCP', 0.0)
                setappdata(0, 'worstNodeCumulativeDamage', 0.0)
                
                return
            end
            
            % Transform the load history to align the tensors with the principal directions of the MDMC
            octahedralTensor = zeros(3.0, 3.0, signalLength);
            for i = 1:signalLength
                octahedralTensor(:, :, i) = R'.*tensor(:, :, i).*R;
            end
            
            % Get the octahedral shear stress tensor history for the loading
            octahedralShearStress = zeros(1, signalLength);
            for i = 1:signalLength
                octahedralShearStress(i) = (1.0/3.0)*sqrt((octahedralTensor(1.0, 1.0, i) - octahedralTensor(2.0, 2.0, i))^2.0 +...
                    (octahedralTensor(2.0, 2.0, i) - octahedralTensor(3.0, 3.0, i))^2.0 +...
                    (octahedralTensor(1.0, 1.0, i) - octahedralTensor(3.0, 3.0, i))^2.0);
            end
            
            %% Rainflow count the octahedral shear stress
            if signalLength < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                Sa = 0.5*abs(max(octahedralShearStress) - min(octahedralShearStress));
                pairs = [min(octahedralShearStress), max(octahedralShearStress)];
            else
                % Gate the tensors if applicable
                if gateTensors > 0.0
                    octahedralShearStress = analysis.gateTensors(octahedralShearStress, gateTensors, tensorGate);
                end
                
                % Filter the octahedral shear stress
                octahedralShearStress = analysis.preFilter(octahedralShearStress, length(octahedralShearStress));
                if (length(octahedralShearStress) ~= signalLength) && (length(octahedralShearStress) > 2.0)
                    if octahedralShearStress(end) > octahedralShearStress(1.0)
                        octahedralShearStress(1.0) = [];
                    else
                        octahedralShearStress(end) = [];
                    end
                end
                
                % Rainflow cycle count the octahedral shear stress
                rfData = analysis.rainFlow(octahedralShearStress);
                
                % Get rainflow pair indices from rfData
                combinations = rfData(:, 3:4);
                [numberOfCycles, ~] = size(combinations);
                
                %% Use the pair indices to locate the equivalent stress cycles
                Sm = zeros(1.0, numberOfCycles);
                Sa = zeros(1.0, numberOfCycles);
                pairs = zeros(numberOfCycles, 2.0);
                
                for i = 1:numberOfCycles
                    if combinations(i, 1.0) > signalLength
                        combinations(i, 1.0) = signalLength;
                    end
                    if combinations(i, 2.0) > signalLength
                        combinations(i, 2.0) = signalLength;
                    end
                    
                    % Get the von Mises stress of each cycle. This is the
                    % cycle pair information
                    pairs(i, :) = vm(combinations(i, :));
                    
                    % Get the individual mean stress components
                    Sxm = 0.5*(max(Sxx(combinations(i, :))) + min(Sxx(combinations(i, :))));
                    Sym = 0.5*(max(Syy(combinations(i, :))) + min(Syy(combinations(i, :))));
                    Szm = 0.5*(max(Szz(combinations(i, :))) + min(Szz(combinations(i, :))));
                    
                    Txym = 0.5*(max(Txy(combinations(i, :))) + min(Txy(combinations(i, :))));
                    Tyzm = 0.5*(max(Tyz(combinations(i, :))) + min(Tyz(combinations(i, :))));
                    Txzm = 0.5*(max(Txz(combinations(i, :))) + min(Txz(combinations(i, :))));
                    
                    %% Get the individual stress amplitude components
                    Sxa = 0.5*(max(Sxx(combinations(i, :))) - min(Sxx(combinations(i, :))));
                    Sya = 0.5*(max(Syy(combinations(i, :))) - min(Syy(combinations(i, :))));
                    Sza = 0.5*(max(Szz(combinations(i, :))) - min(Szz(combinations(i, :))));
                    
                    Txya = 0.5*(max(Txy(combinations(i, :))) - min(Txy(combinations(i, :))));
                    Tyza = 0.5*(max(Tyz(combinations(i, :))) - min(Tyz(combinations(i, :))));
                    Txza = 0.5*(max(Txz(combinations(i, :))) - min(Txz(combinations(i, :))));
                    
                    % Get the effective stress parameter, depending on the
                    % user-specified setting
                    nasalifeParameter = getappdata(0, 'nasalifeParameter');
                    
                    switch nasalifeParameter
                        case 1.0
                            % Check the principal stresses of this cycle pair
                            % in case the modifier is required
                            s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                            s1 = s1(1.0);
                            s1 = s1i(s1);
                            
                            s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                            s3 = s3(1.0);
                            s3 = s3i(s3);
                            
                            % Get the equivalent mean stress of the cycle
                            if sign(s1) ~= sign(s3)
                                % Get the equivalent mean stress of the cycle
                                % (Modified Manson MacKnight)
                                Sm(i) = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            else
                                % Get the equivalent mean stress of the cycle
                                % (Manson MacKnight)
                                Sm(i) = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            end
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        case 2.0
                            % Sines
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = Sxm + Sym + Szm;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2) + Sm(i));
                        case 3.0
                            % Smith-Watson-Topper
                            
                            % Get the maximum and minimum value of the first
                            % principal stress
                            s1_max = max(s1i(combinations(i, :)));
                            s1_min = min(s1i(combinations(i, :)));
                            
                            % The mean stress is assumed to be zero
                            Sm(i) = 0.0;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(s1_max*(s1_max - s1_min));
                        case 4.0
                            % R-Ratio Sines
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = Sxm + Sym + Szm;
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                        case 5.0
                            % Effective method
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                            
                            % Get the equivalent mean stress of the cycle
                            Sm(i) = sqrt(2.0)*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2)) - Sa(i);
                        otherwise
                            % Check the principal stresses of this cycle pair
                            % in case the modifier is required
                            s1 = find(abs(s1i(combinations(i, :))) == max(abs(s1i(combinations(i, :)))));
                            s1 = s1(1.0);
                            s1 = s1i(s1);
                            
                            s3 = find(abs(s3i(combinations(i, :))) == max(abs(s3i(combinations(i, :)))));
                            s3 = s3(1.0);
                            s3 = s3i(s3);
                            
                            % Get the equivalent mean stress of the cycle
                            if sign(s1) ~= sign(s3)
                                % Get the equivalent mean stress of the cycle
                                % (Modified Manson MacKnight)
                                Sm(i) = sign((s1 + s3)/(s1 - s3))*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            else
                                % Get the equivalent mean stress of the cycle
                                % (Manson MacKnight)
                                Sm(i) = sign(Sxm + Sym + Szm)*(0.5*sqrt(2.0))*sqrt((Sxm - Sym)^2 + (Sym - Szm)^2 + (Szm - Sxm)^2 + 6*(Txym^2 + Tyzm^2 + Txzm^2));
                            end
                            
                            % Get the equivalent stress amplitude of the cycle
                            Sa(i) = 0.5*sqrt(2.0)*sqrt((Sxa - Sya)^2 + (Sya - Sza)^2 + (Sza - Sxa)^2 + 6*(Txya^2 + Tyza^2 + Txza^2));
                    end
                end
            end
            
            % Save data for history output
            CS = zeros(1.0, signalLength);
            CN = CS;
            
            for i = 1:signalLength
                CS(i) = 0.5*(octahedralTensor(1.0, 1.0, i) - octahedralTensor(3.0, 3.0, i));
                CN(i) = 0.5*(octahedralTensor(1.0, 1.0, i) + octahedralTensor(3.0, 3.0, i));
            end
            
            setappdata(0, 'CS', CS)
            setappdata(0, 'CN', CN)
            setappdata(0, 'cyclesOnCP', pairs)
            setappdata(0, 'amplitudesOnCP', Sa)
            
            % Get the damage per cycle for the worst node for the damage
            % accumulation plot
            if getappdata(0, 'outputFigure') == 1.0
                [~] = algorithm_nasa.damageCalculation(Sa, pairs, gamma, nasalifeParameter);
                setappdata(0, 'worstNodeCumulativeDamage', getappdata(0, 'cumulativeDamage'))
            end
        end
        
        %% GET THE WALKER GAMMA PARAMETER FOR THE CURRENT ITEM
        function [gamma] = getGamma(R)
            % Get the gamma parameter
            gamma = getappdata(0, 'walkerGamma');
            
            if gamma == -9999.9
                % Calculate gamma based on load ratio
                if R < 0.0
                    gamma = 1.0;
                else
                    gamma = 0.5;
                end
            end
        end
        
        %% CORRECT THE CYCLE FOR THE EFFECT OF MEAN STRESS
        function [Saw] = walker(R, A, Sa, nasalifeParameter, gamma)
            % Get the Walker-corrected stress amplitude
            if nasalifeParameter == 3.0
                Saw = Sa;
            elseif (A <= 0.0) || (A > 1e7) || (nasalifeParameter == 2.0)
                Saw = real(Sa*(0.5*(1.0 - R))^(gamma - 1.0));
            elseif A <= 0.9
                Saw = real(Sa*(((1.0 + A)/(2.0*A))*(1.0 - R))^(gamma - 1.0));
            else
                %{
                    Testing shows that the Walker mean stress correction as
                    stated in the NASALIFE document is incorrect:
                
                    Saw = real(Sa*(1.0 - R)^(gamma - 1.0));
                    
                    The classic version as reported by Walker is used
                    instead.
                %}
                Saw = real(Sa*(2.0/(1.0 - R))^(1.0 - gamma));
            end
            
            if isnan(Saw) == 1.0
                Saw = 0.0;
            end
        end
    end
end
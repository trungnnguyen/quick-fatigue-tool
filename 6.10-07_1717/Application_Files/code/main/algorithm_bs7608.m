classdef algorithm_bs7608 < handle
%ALGORITHM_BS7608    QFT class for BS 7608 algorithm.
%   This class contains methods for the BS 7608 fatigue analysis
%   algorithm.
%   
%   ALGORITHM_BS7608 is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also algorithm_findley, algorithm_nasa, algorithm_ns,
%   algorithm_sbbm, algorithm_sip, algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.6 BS 7608 Fatigue of Welded Steel Joints
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalDamageParameter, nodalAmplitudes, nodalPairs,...
                nodalPhiC, nodalThetaC, nodalDamage, maxPhiCurve] =...
                main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, signalLength,...
                step, planePrecision, nodalDamageParameter,...
                nodalAmplitudes, nodalPairs, nodalPhiC, nodalThetaC,...
                node, nodalDamage, failureMode, gateTensors, tensorGate,...
                signConvention, S1, S2, S3, maxPhiCurve, repeats)
            
            % Perform the critical plane search
            [damageParameter, damageParamAll, phiC, thetaC,...
                amplitudes, pairs, maxPhiCurve_i] =...
                algorithm_bs7608.criticalPlaneAnalysis(Sxxi, Syyi, Szzi,...
                Txyi, Tyzi, Txzi, signalLength, step, planePrecision,...
                failureMode, gateTensors, tensorGate, signConvention,...
                S1, S2, S3);
            
            % Get current Damage parameter
            nodalDamageParameter(node) = damageParameter;
            
            % Store worst cycles for current item
            nodalAmplitudes{node} = amplitudes;
            nodalPairs{node} = pairs;
            
            % Get the current maximum phi curve value
            maxPhiCurve(node) = maxPhiCurve_i;
            
            % Record angle
            nodalPhiC(node) = phiC;
            nodalThetaC(node) = thetaC;
            
            %% Perform a damage calcuacalculationltion on the current analysis item
            nodalDamage(node) = algorithm_bs7608.damageCalculation(damageParamAll, pairs, repeats);
        end
        
        %% BS 7608 S-N CURVE
        function [error] = getBS7608Properties()
            % Initialize error flag
            error = 0.0;
            
            % Initialize custom Sr-N data flag
            setappdata(0, 'bs7608_customSrNData', 0.0)
            
            % Get the BS7608 user settings
            weldClass = getappdata(0, 'weldClass');
            d = getappdata(0, 'devsBelowMean');
            
            % Check the validity of the inputs
            if isempty(weldClass) == 1.0
                weldClass = 1.0;
            end
            
            if ischar(weldClass) == 0.0 && isinteger(weldClass) == 0.0 && iscell(weldClass) == 0.0
                weldClass = 1.0;
            end
            
            if isnumeric(weldClass) == 1.0 && (weldClass > 10.0 || weldClass < 1.0)
                weldClass = 1.0;
            end
            
            if isempty(d) == 1.0 || ~isnumeric(d) == 1.0
                d = 0.0;
            elseif d < 0.0
                d = abs(d);
            end
            
            if isnumeric(weldClass) == 1.0 && weldClass == 11.0
                if (d ~= 0.0 && d ~= 2.0)
                    d = 0.0;
                end
            elseif strcmpi(weldClass, 'x') == 1.0
                if (d ~= 0.0 && d ~= 2.0)
                    d = 0.0;
                end
            end
            setappdata(0, 'devsBelowMean', d)
            
            failureMode = getappdata(0, 'bs7608FailureMode');
            if isempty(failureMode) == 1.0
                setappdata(0, 'failureMode', 1.0)
            elseif isnumeric(failureMode) == 0.0
                setappdata(0, 'failureMode', 1.0)
            elseif isinteger(failureMode) == 0.0 || failureMode > 3.0 || failureMode < 1.0
                setappdata(0, 'failureMode', 1.0)
            end
            
            % Calculate the S-N curve parameters
            if iscell(weldClass) == 0.0 && (weldClass(1.0) == 1.0 || strcmpi(weldClass, 'b'))
                log_C0 = 15.3697;
                sigma = 0.1821;
                m = 4.0;
                S0 = 100.0;
                weldClassInt = 1.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 2.0 || strcmpi(weldClass, 'c'))
                log_C0 = 14.0342;
                sigma = 0.2041;
                m = 3.5;
                S0 = 78.0;
                weldClassInt = 2.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 3.0 || strcmpi(weldClass, 'd'))
                log_C0 = 12.6007;
                sigma = 0.2095;
                m = 3.0;
                S0 = 53.0;
                weldClassInt = 3.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 4.0 || strcmpi(weldClass, 'e'))
                log_C0 = 12.5169;
                sigma = 0.2509;
                m = 3.0;
                S0 = 47.0;
                weldClassInt = 4.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 5.0 || strcmpi(weldClass, 'f'))
                log_C0 = 12.2370;
                sigma = 0.2183;
                m = 3.0;
                S0 = 40.0;
                weldClassInt = 5.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 6.0 || strcmpi(weldClass, 'f2'))
                log_C0 = 12.0900;
                sigma = 0.2279;
                m = 3.0;
                S0 = 35.0;
                weldClassInt = 6.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 7.0 || strcmpi(weldClass, 'g'))
                log_C0 = 11.7525;
                sigma = 0.1793;
                m = 3.0;
                S0 = 29.0;
                weldClassInt = 7.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 8.0 || strcmpi(weldClass, 'w'))
                log_C0 = 11.5662;
                sigma = 0.1846;
                m = 3.0;
                S0 = 25.0;
                weldClassInt = 8.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 9.0 || strcmpi(weldClass, 's'))
                log_C0 = 23.3284;
                sigma = 0.5045;
                m = 8.0;
                S0 = 82.0;
                weldClassInt = 9.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 10.0 || strcmpi(weldClass, 't'))
                log_C0 = 12.6606;
                sigma = 0.2484;
                m = 3.0;
                S0 = 53.0;
                weldClassInt = 10.0;
            elseif iscell(weldClass) == 0.0 && (weldClass(1.0) == 11.0 || strcmpi(weldClass, 'x'))
                log_C0 = -1.0;
                sigma = -1.0;
                m = -1.0;
                uts = getappdata(0, 'bs7608UTS');
                if isempty(uts) == 1.0
                    uts = 785.0;
                    messenger.writeMessage(68.0)
                elseif uts <= 0.0 || isinf(uts) == 1.0 || isnan(uts) == 1.0
                    uts = 785.0;
                    messenger.writeMessage(68.0)
                elseif uts > 785.0
                    uts = 785.0;
                    messenger.writeMessage(69.0)
                end
                S0 = (800/1e6)^(1.0/3.0)*uts;
                weldClassInt = 11.0;
                setappdata(0, 'bs7608UTS', uts)
            elseif iscell(weldClass) == 1.0 && exist(weldClass{1.0}, 'file') == 2.0
                % The weld class is a user-defined Sr-N curve
                [error, S0] = algorithm_bs7608.getUserSrNCurve(weldClass);
                if error > 0.0
                    return
                end
                weldClassInt = 12.0;
                log_C0 = 0.0;
                sigma = 0.0;
                m = 0.0;
            elseif ischar(weldClass) == 1.0
                weldClass = cellstr(weldClass);
                if exist(weldClass{1.0}, 'file') == 2.0
                    [error, S0] = algorithm_bs7608.getUserSrNCurve(weldClass);
                end
                weldClassInt = 12.0;
                log_C0 = 0.0;
                sigma = 0.0;
                m = 0.0;
            else
                log_C0 = 15.3697;
                sigma = 0.1821;
                m = 4.0;
                S0 = 100.0;
                weldClassInt = 1.0;
                setappdata(0, 'weldClass', 1.0)
                messenger.writeMessage(70.0)
            end
            
            % Save the BS 7608 variables
            setappdata(0, 'weldClassInt', weldClassInt)
            factor = log_C0 - (sigma*d);
            setappdata(0, 'bs7608Factor', factor);
            setappdata(0, 'bs7608_m', m)
            setappdata(0, 'bs7608_s0', S0)
            if getappdata(0, 'enduranceLimitSource') == 3.0
                messenger.writeMessage(89.0)
            end
            
            t = getappdata(0, 'plateThickness');
            if isempty(t) == 1.0
                if weldClassInt == 11.0
                    setappdata(0, 'plateThickness', 25.0)
                else
                    setappdata(0, 'plateThickness', 16.0)
                end
                setappdata(0, 'bs_thicknessCorrection', 1.0)
            elseif t <= 0.0
                if weldClassInt == 11.0
                    setappdata(0, 'plateThickness', 25.0)
                else
                    setappdata(0, 'plateThickness', 16.0)
                end
                setappdata(0, 'bs_thicknessCorrection', 1.0)
            elseif weldClassInt < 8.0 && t <= 16.0
                % Classes B to G are valid up to 16mm without correction
                setappdata(0, 'bs_thicknessCorrection', 1.0)
            elseif weldClassInt == 10.0 && t == 16.0
                % Class T is valid for 16mm only
                setappdata(0, 'bs_thicknessCorrection', 1.0)
            elseif weldClassInt == 11.0 && t <= 25.0
                % Class X is valid up to 25mm without correction
                setappdata(0, 'bs_thicknessCorrection', 1.0)
            else
                S = S0*(16.0/getappdata(0, 'plateThickness'))^(0.25);
                setappdata(0, 'bs_thicknessCorrection', S0/S)
            end
        end
        
        %% GET USER SR-N CURVE
        function [error, S0] = getUserSrNCurve(userCurve)
            % Initialize the error flag
            error = 0.0;
            
            % Initialize the endurance limit
            S0 = 0.0;
            
            % Check whether reading from rows or columns
            rowsCols = 2.0; % Default is columns
            if length(userCurve) == 2.0
                if strcmpi(userCurve{2.0}, 'row') == 1.0
                    rowsCols = 1.0;
                elseif strcmpi(userCurve{2.0}, 'col') == 1.0
                    rowsCols = 2.0;
                end
                setappdata(0, 'bs7608_weldClass1Arg', 0.0)
            elseif length(userCurve) == 1.0
                setappdata(0, 'bs7608_weldClass1Arg', 1.0)
                messenger.writeMessage(221.0)
            end
            
            % Get the data
            data = load(userCurve{1.0});
            
            % Get the data dimensions
            [r, c] = size(data);
            
            % Check data for consistency
            if rowsCols == 1.0
                if r ~= 2.0
                    error = 1.0;
                    return
                elseif c < 2.0
                    error = 2.0;
                    return
                end
                
                % Check that N-values are in the correct direction
                N = data(1.0, :);
                S = data(2.0, :);
                
                for i = 2:length(S)
                    if S(i) > S(i - 1.0)
                        error = 3.0;
                        return
                    elseif N(i) < N(i - 1.0)
                        error = 4.0;
                        return
                    end
                end
            else
                if c ~= 2.0
                    error = 5.0;
                    return
                elseif r < 2.0
                    error = 6.0;
                    return
                end
                
                % Check that N-values are in the correct direction
                N = data(:, 1.0);
                S = data(:, 2.0);
                
                for i = 2:length(S)
                    if S(i) > S(i - 1.0)
                        error = 7.0;
                        return
                    elseif N(i) < N(i - 1.0)
                        error = 8.0;
                        return
                    end
                end
            end
            
            % Save SR-N data
            S0 = S(end);
            setappdata(0, 'bs7608_sValues', S)
            setappdata(0, 'bs7608_nValues', N)
        end
        
        %% CRITICAL PLANE SEARCH ALGORITHM
        function [damageParameter, damageParamAll, phiC, thetaC,...
                amplitudes, pairs, maxPhiCurve] = criticalPlaneAnalysis(Sxxi, Syyi, Szzi,...
                Txyi, Tyzi, Txzi, signalLength, step, precision,...
                failureMode, gateTensors, tensorGate, signConvention, S1, S2, S3)
            
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
            
            % Store AMPLITUDES and PAIRS in a cell
            amplitudesBuffer = cell(precision, precision);
            pairsBuffer = cell(precision, precision);
            
            % Stress buffers
            bs7608Parameter = zeros(1.0, signalLength);
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
                    if failureMode == 1.0 % NORMAL
                        for i = 1:signalLength
                            bs7608Parameter(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
                        end
                    elseif failureMode == 2.0 % SHEAR
                        for i = 1:signalLength
                            tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear stress on that plane
                            tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear stress on that plane
                        end
                        
                        % Get the resultant shear stress history on the current plane
                        bs7608Parameter = sqrt(tauXY.^2 + tauXZ.^2);
                        
                        % Apply sign to resultant shear stress
                        bs7608Parameter = applySignConvention(bs7608Parameter, signConvention, S1, S2, S3, Sxxi, Syyi, tauXY);
                    else % COMBINED (NORMAL + SHEAR)
                        normalStress = zeros(1.0, signalLength);
                        for i = 1:signalLength
                            normalStress(i)=S_prime{i}(1.0, 1.0); % Normal stress on that plane
                        end
                        
                        for i = 1:signalLength
                            tauXY(i)=S_prime{i}(1.0, 2.0);  % Shear stress on that plane
                            tauXZ(i)=S_prime{i}(1.0, 3.0);  % Shear stress on that plane
                        end
                        
                        % Get the resultant (normal + shear) stress history on the current plane
                        shearStress = sqrt(tauXY.^2 + tauXZ.^2);
                        
                        % Apply sign to resultant shear stress
                        shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, Sxxi, Syyi, tauXY);
                        
                        bs7608Parameter = normalStress + shearStress;
                    end
                    
                    % Rainflow the BS7608 parameter on this plane
                    %{
                        Note that for the BS 7608 method, the damage
                        parameter is taken as the stress range instead of
                        the stress amplitude
                    %}
                    if signalLength < 3.0
                        % If the signal length is less than 3, there is no need to cycle count
                        amplitudes = 0.5*(max(bs7608Parameter) - min(bs7608Parameter));
                        pairs = [min(bs7608Parameter), max(bs7608Parameter)];
                    else
                        % Gate the tensors if applicable
                        if gateTensors > 0.0
                            fT = analysis.gateTensors(bs7608Parameter, gateTensors, tensorGate);
                            
                            % Pre-filter the signal
                            fT = analysis.preFilter(fT, length(fT));
                        else
                            fT = analysis.preFilter(bs7608Parameter, signalLength);
                        end
                        
                        % Now rainflow the BS 7608 parameter
                        rfData = analysis.rainFlow(fT);
                        
                        % Get rainflow pairs from rfData
                        pairs = rfData(:, 1.0:2.0);
                        
                        % Get the amplitudes from the rainflow pairs
                        [amplitudes, ~] = analysis.getAmps(pairs);
                    end
                    
                    % Calculate the BS 7608 parameter on this plane
                    f(index_theta, index_phi) = max(amplitudes);
                    
                    % Save the CP variables to their respective buffers
                    amplitudesBuffer{index_theta, index_phi} = amplitudes;
                    pairsBuffer{index_theta, index_phi} = pairs;
                end
            end
            
            % Get the maximum BS 7608 parameter over THETA for each value of PHI
            maximums = max(f);
            
            % Find the PHI curve whcih contains the maximum BS 7608 paramter
            maxPhiCurve = find(maximums == max(maximums));
            maxPhiCurve = maxPhiCurve(1.0);
            
            % Extract the BS 7608 parameter on the critical plane
            bs7608OnCP = f(:, maxPhiCurve);
            
            %{
                The critical value of THETA is that pertaining to the plane
                where the BS 7608 parameter is maximum
            %}
            maxThetaCurve = find(bs7608OnCP == max(bs7608OnCP), 1.0);
            
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
        function damage = damageCalculation(cycles, pairs, repeats)
            
            %% CALCULATE DAMAGE FOR EACH CYCLE
            
            % Get the residual stress
            residualStress = getappdata(0, 'residualStress_original');
            residualStress = residualStress(getappdata(0, 'getMaterial_currentGroup'));
            
            numberOfCycles = length(cycles);
            
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Initial non-propagating stress range, S0
            S0 = getappdata(0, 'bs7608_s0');
            
            % Get user S-values
            userS = getappdata(0, 'bs7608_sValues');
            userN = getappdata(0, 'bs7608_nValues');
            
            % Tensile yield strength 
            y = getappdata(0, 'bs7608Twops');
            
            % Get the weld class number
            weldClassInt = getappdata(0, 'weldClassInt');
                
            for index = 1:numberOfCycles
                if ((min(pairs(index, :)) < 0.0 && max(pairs(index, :)) <= 0.0) &&...
                        (getappdata(0, 'ndCompression') == 1.0)) ||...
                        (2.0*cycles(index) < S0)
                    %{
                        If the stress range is purely compressive, or the
                        stress range falls below the non-propagating stress
                        range, assume no damage
                    %}
                    cumulativeDamage(index) = 0.0;
                    continue
                elseif isempty(y) == 0.0
                    if 2.0*cycles(index) > (2.0*y)
                        %{
                            If the stress range exceeds twice the tensile
                            yield strength, assume non-fatigue failure
                        %}
                        cumulativeDamage(index) = 1.0;
                        
                        messenger.writeMessage(67.0)
                    end
                elseif min(pairs(index, :)) < 0.0 && max(pairs(index, :)) > 0.0
                    %{
                        The cycle is partially compressive, so account for
                        the effect of stress relief
                    %}
                    cycles(index) = max(pairs(index, :)) + 0.6*(abs(min(pairs(index, :))));
                end
                
                %{
                    If the current cycle is negative, continue to the next
                    value  in order to avoid complex damage values
                %}
                if cycles(index) < 0.0
                    cumulativeDamage(index) = 0.0;
                else
                    % Scale the stress range to account for plate thickness
                    cycles(index) = getappdata(0, 'bs_thicknessCorrection')*cycles(index);
                    
                    if getappdata(0, 'seaWater') == 1.0
                        % The stress is increased by a factor of 2.0
                        cycles(index) = 2.0*cycles(index);
                    end
                    
                    % Calculate the life
                    if weldClassInt == 12.0
                        life = 10^(interp1(log10(userS), log10(userN), log10(2.0*cycles(index) + residualStress), 'linear', 'extrap'));
                    elseif weldClassInt == 11.0
                        if getappdata(0, 'devsBelowMean') == 0.0
                            life = 800.0/((2.0*cycles(index)/getappdata(0, 'bs7608UTS'))^3.0);
                        else
                            life = 400.0/((2.0*cycles(index)/getappdata(0, 'bs7608UTS'))^3.0);
                        end
                    else
                        life = 10.0^(getappdata(0, 'bs7608Factor') - getappdata(0, 'bs7608_m')*log10(2.0*cycles(index) + residualStress));
                    end
                    
                    if weldClassInt < 11.0
                        %{
                            If the life value is greater than 1E7 cycles,
                            re-calculate with modified slope
                        %}
                        if life > 1e7 && getappdata(0, 'seaWater') == 0.0
                            life = 10.0^(getappdata(0, 'bs7608Factor') - (getappdata(0, 'bs7608_m') + 2.0)*log10(2.0*cycles(index) + residualStress));
                        end
                    else
                        %{
                            For Class X welds, infinite life occurs at 2e6
                            cycles
                        %}
                        if life > 2e6
                            life = inf;
                        end
                    end
                    
                    % Invert the life value to get the damage
                    cumulativeDamage(index) = (1.0/life);
                end
            end
            
            %% SAVE THE CUMULATIVE DAMAGE
            setappdata(0, 'cumulativeDamage', cumulativeDamage);
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            damage = sum(cumulativeDamage)*repeats;
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis(stress, phiC, thetaC,...
                signalLength, failureMode, precision, gateTensors,...
                tensorGate, step, signConvention, S1, S2, S3, repeats)
            
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
                sn(thetaIndex) = max(abs(normalStress));
                
                % Resultant shear stress history on the current plane
                shearStress = sqrt(tauXY.^2 + tauXZ.^2);
                
                % Apply sign to resultant shear stress
                shearStress = applySignConvention(shearStress, signConvention, S1, S2, S3, stress(1.0, :), stress(2.0, :), tauXY);
                
                % Get the BS 7608 parameter
                if failureMode == 1.0
                    bs7608Parameter = normalStress;
                else
                    bs7608Parameter = shearStress;
                end
                
                % Rainflow
                if signalLength < 3.0
                    % If the signal length is less than 3, there is no need to cycle count
                    amplitudes = 0.5*(max(bs7608Parameter) - min(bs7608Parameter));
                    pairs = [min(bs7608Parameter), max(bs7608Parameter)];
                    
                    damageParamAll = amplitudes;
                    
                    damageParamCube(thetaIndex) = amplitudes;
                    
                    damageCube(thetaIndex) = algorithm_bs7608.damageCalculation(damageParamAll, pairs, repeats);
                else
                    % Gate the tensors if applicable
                    if gateTensors > 0.0
                        fT = analysis.gateTensors(bs7608Parameter, gateTensors, tensorGate);
                        
                        % Pre-filter the signal
                        fT = analysis.preFilter(fT, length(fT));
                    else
                        fT = analysis.preFilter(bs7608Parameter, signalLength);
                    end
                    
                    % Now rainflow the BS 7608 parameter
                    rfData = analysis.rainFlow(fT);
                    
                    % Get rainflow pairs from rfData
                    pairs = rfData(:, 1.0:2.0);
                    
                    % Get the amplitudes from the rainflow pairs
                    [damageParamAll, ~] = analysis.getAmps(pairs);
                    amplitudes = damageParamAll;
                    
                    % Calculate the BS 7608 parameter on this plane
                    damageParam = max(damageParamAll);
                    
                    % Add the normal stress to the parameter cube
                    damageParamCube(thetaIndex) = damageParam;
                    
                    % Perform damage calculation on this plane
                    damageCube(thetaIndex) = algorithm_bs7608.damageCalculation(damageParamAll, pairs, repeats);
                end
                
                % Save data for history output
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
        
        %% BS 7608 GET FIELD OUTPUT
        function [] = getFields()
            
            mainID = getappdata(0, 'mainID');
            subID = getappdata(0, 'subID');
            worstItem = getappdata(0, 'worstItem');
            
            N = getappdata(0, 'numberOfNodes');
            
            %% SMAX (Largest stress in loading)
            
            L = getappdata(0, 'signalLength');
            
            Sxx = getappdata(0, 'Sxx');
            Syy = getappdata(0, 'Syy');
            Szz = getappdata(0, 'Szz');
            Txy = getappdata(0, 'Txy');
            Tyz = getappdata(0, 'Tyz');
            Txz = getappdata(0, 'Txz');
            
            S1j = zeros(1.0, L);
            S2j = S1j;
            S3j = S1j;
            hydroStress = zeros(N, L);
            SMAX_ABS = zeros(1.0, N);
            
            for i = 1:N
                for j = 1:L
                    trueTensor = [Sxx(i, j) Txy(i, j) Txz(i, j);...
                        Txy(i, j) Syy(i, j) Tyz(i, j);...
                        Txz(i, j) Tyz(i, j) Szz(i, j)];
                    
                    eigenStress = eig(trueTensor);
                    S1j(j) = max(eigenStress);
                    S2j(j) = median(eigenStress);
                    S3j(j) = min(eigenStress);
                    
                    hydroStress(i, j) = (1/3)*(S1j(j) + S2j(j) + S3j(j));
                end
                
                nodalS1 = max(S1j);
                nodalS3 = min(S3j);
                
                if abs(nodalS1) > abs(nodalS3)
                    SMAX_ABS(i) = nodalS1;
                else
                    SMAX_ABS(i) = nodalS3;
                end
            end
            
            if abs(min(SMAX_ABS)) > abs(max(SMAX_ABS))
                MAX_SMAX_ABS = min(SMAX_ABS);
                SMAX_item = find(SMAX_ABS == min(SMAX_ABS));
            else
                MAX_SMAX_ABS = max(SMAX_ABS);
                SMAX_item = find(SMAX_ABS == max(SMAX_ABS));
            end
            SMAX_item = SMAX_item(1.0);
            
            setappdata(0, 'SMAX', SMAX_ABS)
            setappdata(0, 'SMAX_ABS', MAX_SMAX_ABS)
            setappdata(0, 'SMAX_mainID', mainID(SMAX_item))
            setappdata(0, 'SMAX_subID', subID(SMAX_item))
            
            %% SMXP (Largest stress in loading / 0.2% yield stress)
            
            twops = getappdata(0, 'bs7608Twops');
            
            if isempty(twops)
                setappdata(0, 'SMXP', linspace(-1.0, -1.0, length(SMAX_ABS)))
                setappdata(0, 'SMXP_ABS', linspace(-1.0, -1.0, length(SMAX_ABS)))
                
                setappdata(0, 'SMXP_mainID', 0.0)
                setappdata(0, 'SMXP_subID', 0.0)
            else
                SMXP = SMAX_ABS/twops;
                setappdata(0, 'SMXP', SMXP)
                
                if abs(min(SMXP)) > abs(max(SMXP))
                    MAX_SMXP = min(SMXP);
                    SMXP_item = find(SMXP == min(SMXP));
                else
                    MAX_SMXP = max(SMXP);
                    SMXP_item = find(SMXP == max(SMXP));
                end
                
                setappdata(0, 'SMXP_ABS', MAX_SMXP)
                
                SMXP_item = SMXP_item(1.0);
                
                setappdata(0, 'SMXP_mainID', mainID(SMXP_item))
                setappdata(0, 'SMXP_subID', subID(SMXP_item))
            end
            
            %% SMXU (Largest stress in loading / UTS)
            
            uts = getappdata(0, 'bs7608UTS');
            
            if isempty(uts)
                setappdata(0, 'SMXU', linspace(-1.0, -1.0, length(SMAX_ABS)))
                setappdata(0, 'SMXU_ABS', linspace(-1.0, -1.0, length(SMAX_ABS)))
                
                setappdata(0, 'SMXU_mainID', 0.0)
                setappdata(0, 'SMXU_subID', 0.0)
            else
                SMXU = SMAX_ABS/uts;
                setappdata(0, 'SMXU', SMXU)
                
                if abs(min(SMXU)) > abs(max(SMXU))
                    MAX_SMXU = min(SMXU);
                    SMXU_item = find(SMXU == min(SMXU));
                else
                    MAX_SMXU = max(SMXU);
                    SMXU_item = find(SMXU == max(SMXU));
                end
                
                setappdata(0, 'SMXU_ABS', MAX_SMXU)
                
                SMXU_item = SMXU_item(1);
                
                setappdata(0, 'SMXU_mainID', mainID(SMXU_item))
                setappdata(0, 'SMXU_subID', subID(SMXU_item))
            end
            
            %% WCA (Worst cycle amplitude)
            
            % Get the worst mean stress for each item in the model
            WCA = getappdata(0, 'WCA');
            
            % Find the maximum value of the worst mean stress in the model
            WCA_ABS = max(WCA);
            
            % If there is more than one value, take the first value
            WCA_ABS = WCA_ABS(1.0);
            
            % Get the item ID for this value of mean stress
            WCA_item = find(WCA == WCA_ABS);
            
            % If there is more than one value
            if any(WCA_item == worstItem) == 1.0
                WCA_item = worstItem;
            else
                WCA_item = WCA_item(1.0);
            end
            
            % Save the variables to the APPDATA
            setappdata(0, 'WCA_ABS', WCA_ABS)
            setappdata(0, 'WCA_mainID', mainID(WCA_item))
            setappdata(0, 'WCA_subID', subID(WCA_item))
            
            %% WCM (Worst cycle mean stress)
            
            % Get the worst mean stress for each item in the model
            WCM = getappdata(0, 'WCM');
            
            % Find the maximum value of the worst mean stress in the model
            WCM_ABS = max(WCM);
            
            % If there is more than one value, take the first value
            WCM_ABS = WCM_ABS(1.0);
            
            % Get the item ID for this value of mean stress
            WCM_item = find(WCM == WCM_ABS);
            
            % If there is more than one value
            if any(WCM_item == worstItem) == 1.0
                WCM_item = worstItem;
            else
                WCM_item = WCM_item(1.0);
            end
            
            % Save the variables to the APPDATA
            setappdata(0, 'WCM_ABS', WCM_ABS)
            setappdata(0, 'WCM_mainID', mainID(WCM_item))
            setappdata(0, 'WCM_subID', subID(WCM_item))
            
            %% WCDP (Damage parameter)
            
            %{
                This variable was already saved to the appdata immediately
                after the critical plane search
            %}
            
            WCDP = getappdata(0, 'WCDP');
            
            WCDP_ABS = max(WCDP);
            WCDP_item = find(WCDP == WCDP_ABS);
            if length(WCDP_ABS) > 1 || length(WCDP_item) > 1
                WCDP_ABS = WCDP_ABS(1);
                WCDP_item = WCDP_item(1);
            end
            
            setappdata(0, 'WCDP_ABS', WCDP_ABS)
            
            setappdata(0, 'WCDP_mainID', mainID(WCDP_item))
            setappdata(0, 'WCDP_subID', subID(WCDP_item))
            
            %% TRF (Triaxiality Factor)
        
            triaxialityFactor = zeros(1, N);
            
            % Get the von Mises stress history for each analysis item
            for i = 1:N
                % Get the von Mises stress at the current analysis item
                vonMises = sqrt(0.5.*((Sxx(i, :) - Syy(i, :)).^2 +...
                    (Syy(i, :) - Szz(i, :)).^2 + (Szz(i, :) - Sxx(i, :)).^2 +...
                    6.*(Txy(i, :).^2 + Tyz(i, :).^2 + Txz(i, :).^2)));
                
                % Get the triaxiality factors at the current analysis item
                triaxialityFactors = hydroStress(i, :)./vonMises;
                
                % Get the maximum triaxiality factor in the loading at the
                % current analysis item
                triaxialityFactor(i) = max(triaxialityFactors);
            end
            
            setappdata(0, 'TRF', triaxialityFactor)
        end
        
        %% BS 7608 WRITE FIELD OUTPUT
        function [] = exportFields(loadEqUnits)
            
            %{
                FIELDS -> Single value per item
            %}
            
            mainID = getappdata(0, 'mainID');
            subID = getappdata(0, 'subID');
            
            LL = getappdata(0, 'LL');
            D = getappdata(0, 'D');
            DDL = D*getappdata(0, 'dLife');
            L = D.^-1;
            SMAX = getappdata(0, 'SMAX');
            SMXP = getappdata(0, 'SMXP');
            SMXU = getappdata(0, 'SMXU');
            TRF = getappdata(0, 'TRF');
            WCM = getappdata(0, 'WCM');
            WCA = getappdata(0, 'WCA');
            WCDP = getappdata(0, 'WCDP');
            WCATAN = atand(WCM./WCA);
            YIELD = getappdata(0, 'YIELD');
            
            data = [mainID'; subID'; L; LL; D; DDL; SMAX; SMXP; SMXU; TRF; WCM; WCA; WCATAN; WCDP; YIELD]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_F_OUTPUT_ALL') == 1.0
                dir = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-all.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'FIELDS [WHOLE MODEL]\r\nJob:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
                
                fprintf(fid, 'Main ID\tSub ID\tL (%s)\tLL (%s)\tD\tDDL\tSMAX (MPa)\tSMXP\tSMXU\tTRF\tWCM (MPa)\tWCA (MPa)\tWCATAN (Deg)\tWCDP (MPa)\tYIELD\r\n', loadEqUnits, loadEqUnits);
                fprintf(fid, '%.0f\t%.0f\t%.4e\t%.4f\t%.4g\t%.4g\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
                
                fclose(fid);
            end
        end
        
        %% BS 7608 GET HISTORY OUTPUT
        function [] = getHistories(loadEqUnits, outputField, outputFigure)
            
            mainID = getappdata(0, 'worstMainID');
            subID = getappdata(0, 'worstSubID');
            
            figureFormat = getappdata(0, 'figureFormat');
            
            root = getappdata(0, 'outputDirectory');
            
            midnightBlue = [25/255, 25/255, 112/255];
            fireBrick =  [178/255, 34/255, 34/255];
            forestGreen = [34/255, 139/255, 34/255];
            lineWidth = getappdata(0, 'defaultLineWidth');
            fontX = getappdata(0, 'defaultFontSize_XAxis');
            fontY = getappdata(0, 'defaultFontSize_YAxis');
            fontTitle = getappdata(0, 'defaultFontSize_Title');
            fontTicks = getappdata(0, 'defaultFontSize_Ticks');
            XTickPartition = getappdata(0, 'XTickPartition');
            gridLines = getappdata(0, 'gridLines');
            
            %% VM (von Mises stress at worst item)
            worstItem = getappdata(0, 'worstItem');
            
            L = getappdata(0, 'signalLength');
            
            vm = getappdata(0, 'VM');
            vm = vm(worstItem, :);
            
            setappdata(0, 'WNVM', vm)
            
            if  getappdata(0, 'figure_VM') == 1.0 && outputFigure == 1.0
                if outputFigure == 1.0
                    f3 = figure('visible', 'off');
                    
                    plot(vm, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                    
                    msg = sprintf('VM, von Mises stress for item %.0f.%.0f', mainID, subID);
                    xlabel('Increment', 'FontSize', fontX)
                    ylabel('von Mises Stress [MPa]', 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                    set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/VM, von Mises stress at worst item'];
                    saveas(f3, dir, 'fig')
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% PS1 (Maximum Principal stress at worst item)
            
            s1 = getappdata(0, 'S1');
            s1 = s1(worstItem, :);
            s2 = getappdata(0, 'S2');
            s2 = s2(worstItem, :);
            s3 = getappdata(0, 'S3');
            s3 = s3(worstItem, :);
            
            setappdata(0, 'WNPS1', s1)
            setappdata(0, 'WNPS2', s2)
            setappdata(0, 'WNPS3', s3)
            
            if getappdata(0, 'figure_PS') == 1.0 && outputFigure == 1.0
                f4 = figure('visible', 'off');
                subplot(3, 1, 1)
                plot(s1, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)

                msg = sprintf('PS1, Maximum principal stress for item %.0f.%.0f', mainID, subID);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                %% PS2 (Middle Principal stress at worst item)
                
                subplot(3, 1, 2)
                plot(s2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS2, Middle principal stress for item %.0f.%.0f', mainID, subID);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                %% PS3 (Minimum Principal stress at worst item)
                
                subplot(3, 1, 3)
                plot(s3, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS3, Minimum principal stress for item %.0f.%.0f', mainID, subID);
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/PS, Principal stresses at worst item'];
                saveas(f4, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% CN (Normal stress on critical plane)
        
            if getappdata(0, 'figure_CN') == 1.0 && outputFigure == 1.0
                normalOnCP = getappdata(0, 'CN');
                
                f7 = figure('visible', 'off');
                subplot(2, 1, 1)
                plot(normalOnCP, '-', 'LineWidth', lineWidth, 'Color', fireBrick)

                msg = sprintf('CN, Maximum normal stress history on critical plane for item %.0f.%.0f', mainID, subID);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
            end
            
            %% CS (Shear stress on critical plane)
            
            if getappdata(0, 'figure_CS') == 1.0 && outputFigure == 1.0
                shearOnCP = getappdata(0, 'CS');
                
                subplot(2, 1, 2)
                plot(shearOnCP, '-', 'LineWidth', lineWidth, 'Color', forestGreen)

                msg = sprintf('CS, Maximum shear stress history on critical plane for item %.0f.%.0f', mainID, subID);
                xlabel('Sample', 'FontSize', fontX);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/CN + CS, Normal and shear stress on critical plane at worst item'];
                saveas(f7, dir, 'fig')
                postProcess.makeVisible([dir, '.fig'])
            end
            
            %% CP PLOTS
            figureFormat = getappdata(0, 'figureFormat');
            
            root = getappdata(0, 'outputDirectory');
            
            midnightBlue = [25/255, 25/255, 112/255];
            lineWidth = getappdata(0, 'defaultLineWidth');
            fontX = getappdata(0, 'defaultFontSize_XAxis');
            fontY = getappdata(0, 'defaultFontSize_YAxis');
            fontTitle = getappdata(0, 'defaultFontSize_Title');
            fontTicks = getappdata(0, 'defaultFontSize_Ticks');
            gridLines = getappdata(0, 'gridLines');
            
            mainID = getappdata(0, 'worstMainID');
            subID = getappdata(0, 'worstSubID');
            
            smoothness = getappdata(0, 'cpSample');
            if isempty(smoothness)
                smoothness = 1.0;
            elseif isnumeric(smoothness) == 0.0
                smoothness = 1.0;
            elseif isnan(smoothness) || isreal(smoothness) == 0.0 || ...
                    isinf(smoothness) || isreal(smoothness) == 0.0
                smoothness = 1.0;
            end
            
            damageParameter = getappdata(0, 'worstNodeDamageParamCube');
            damage = getappdata(0, 'worstNodeDamageCube');
            
            steps = getappdata(0, 'stepSize');
            step = steps(worstItem);
            
            %% DPP-THETA (Damage parameter vs THETA)
            
            setappdata(0, 'DPT', damageParameter)
            thetaOnCP = getappdata(0, 'thetaOnCP');
            
            if outputFigure == 1.0 && getappdata(0, 'figure_DPP') == 1.0
                f6 = figure('visible', 'off');
                
                % Smooth the data
                if length(damageParameter) > 9.0 && range(damageParameter) ~= 0.0 && smoothness > 0.0
                    damageParameter = interp(damageParameter, smoothness);
                end
                x = linspace(0.0, 180.0, length(damageParameter));
                
                plot(x, damageParameter, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                scatter(thetaOnCP, damageParameter((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                
                
                msg = sprintf('DPP-THETA, Damage parameter vs theta for item %.0f.%.0f', mainID, subID);
                xlabel('Angle [deg]', 'FontSize', fontX)
                ylabel('Damage parameter [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/DPP, Damage parameter vs angle at worst item'];
                saveas(f6, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% DP-THETA (Damage vs THETA)
            setappdata(0, 'DT', damage)
            
            if outputFigure == 1.0 && getappdata(0, 'figure_DP') == 1.0
                f7 = figure('visible', 'off');
                
                % Smooth the data
                if length(damage) > 9.0 && range(damage) ~= 0.0 && smoothness > 0.0
                    damageTheta2 = interp(damage, smoothness);
                else
                    damageTheta2 = damage;
                end
                x = linspace(0.0, 180.0, length(damageTheta2));
                
                plot(x, damageTheta2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                scatter(thetaOnCP, damageTheta2((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                
                msg = sprintf('DP-THETA, Damage vs theta for item %.0f.%.0f', mainID, subID);
                xlabel('Angle [deg]', 'FontSize', fontX)
                ylabel(sprintf('Damage [1/%s]', loadEqUnits), 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/DP, Damage vs angle at worst item'];
                saveas(f7, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% LP-THETA (Life vs THETA)
            
            lifeTheta = 1.0./damage;
            
            setappdata(0, 'LT', lifeTheta)
            
            if outputFigure == 1.0 && getappdata(0, 'figure_LP') == 1.0
                f8 = figure('visible', 'off');
                
                % Smooth the data
                if length(lifeTheta) > 9.0 && any(isinf(lifeTheta)) == 0.0 && range(lifeTheta) ~= 0.0 && smoothness > 0.0
                    lifeTheta = interp(lifeTheta, smoothness);
                end
                x = linspace(0.0, 180.0, length(lifeTheta));
                
                plot(x, lifeTheta, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                scatter(thetaOnCP, lifeTheta((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                
                msg = sprintf('LP-THETA, Life vs theta for item %.0f.%.0f', mainID, subID);
                xlabel('Angle [deg]', 'FontSize', fontX)
                ylabel(sprintf('Life %s', loadEqUnits), 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/LP, Life vs angle at worst item'];
                saveas(f8, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% SHEAR/NORMAL  STRESS VS THETA
            if outputFigure == 1.0
                if getappdata(0, 'figure_CPS') == 1.0
                    %% SHEAR STRESS VS THETA
                    f9 = figure('visible', 'off');
                    
                    shearStress = getappdata(0, 'shear_cp');
                    
                    % Smooth the data
                    if length(shearStress) > 9.0 && any(isinf(shearStress)) == 0.0 && range(shearStress) ~= 0.0 && smoothness > 0.0
                        shearStress = interp(shearStress, smoothness);
                    end
                    x = linspace(0.0, 180.0, length(shearStress));
                    
                    subplot(2.0, 1.0, 1.0)
                    plot(x, shearStress, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                    scatter(thetaOnCP, shearStress((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                    'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                    
                    if getappdata(0, 'cpShearStress') == 1.0
                        msg = sprintf('CPS-THETA, Maximum shear stress vs theta for item %.0f.%.0f', mainID, subID);
                    else
                        msg = sprintf('CPS-THETA, Resultant shear stress vs theta for item %.0f.%.0f', mainID, subID);
                    end
                    
                    xlabel('Angle [deg]', 'FontSize', fontX)
                    ylabel('Stress [MPa]', 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                end
                
                if getappdata(0, 'figure_CPN') == 1.0
                    %% NORMAL STRESS VS THETA
                    normalStress = getappdata(0, 'normal_cp');
                    
                    % Smooth the data
                    if length(normalStress) > 9.0 && any(isinf(normalStress)) == 0.0 && range(normalStress) ~= 0.0 && smoothness > 0.0
                        normalStress = interp(normalStress, smoothness);
                    end
                    x = linspace(0.0, 180.0, length(normalStress));
                    
                    subplot(2.0, 1.0, 2.0)
                    plot(x, normalStress, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                    scatter(thetaOnCP, normalStress((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                    'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                    
                    msg = sprintf('CPN-THETA, Normal stress vs theta for item %.0f.%.0f', mainID, subID);
                    xlabel('Angle [deg]', 'FontSize', fontX)
                    ylabel('Stress [MPa]', 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/CPS, Critical plane stresses vs angle at worst item'];
                    saveas(f9, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
            end
            
            %% DAC DAMAGE ACCUMULATION AT WORST ITEM
            
            if outputFigure == 1.0 && getappdata(0, 'figure_DAC') == 1.0
                damagePerCycle = getappdata(0, 'worstNodeCumulativeDamage');
                numberOfCycles = length(damagePerCycle);
                
                if numberOfCycles > 1.0
                    cumulativeDamage = zeros(1, numberOfCycles);
                    for i = 1:numberOfCycles
                        cumulativeDamage(i) = sum(damagePerCycle(1:i));
                    end
                    
                    % If the maximum damage is zero, skip this variable
                    if max(cumulativeDamage) ~= 0.0
                        % Check whether damage crosses the infinite life
                        % envelope
                        crossing = -999.0;
                        cael = 0.5*getappdata(0, 'cael');
                        if 1/max(cumulativeDamage) < cael
                            % Search for the point at which finite life
                            % begins
                            if 1/cumulativeDamage(1) > cael
                                for i = 1:length(cumulativeDamage)
                                    if 1/cumulativeDamage(i) < cael
                                        crossing = i - 1;
                                        break
                                    end
                                end
                            end 
                        end
                        
                        cumulativeDamage = cumulativeDamage/max(cumulativeDamage);
                        
                        f11 = figure('visible', 'off');
                        plot(cumulativeDamage, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                        
                        if crossing ~= -999.0
                            l1 = line([crossing, crossing], [0.0, 1.0], 'lineWidth', lineWidth);
                            legend(l1, 'Infinite Life Envelope')
                        end

                        msg = sprintf('DAC, Cumulative damage at item %.0f.%.0f', mainID, subID);
                        xlabel('Cycle', 'FontSize', fontX)
                        ylabel('Normalised Damage', 'FontSize', fontY)
                        title(msg, 'FontSize', fontTitle)
                        set(gca, 'FontSize', fontTicks)
                        set(gca, 'XTick', linspace(1.0, numberOfCycles, XTickPartition + 1.0))
                        set(gca, 'XTickLabel', round(linspace(1.0, numberOfCycles, XTickPartition + 1.0)));
                        
                        try
                            axis tight
                        catch
                            % Don't tighten the axis
                        end
                        
                        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                            grid on
                        end
                        
                        dir = [root, 'MATLAB Figures/DAC, Cumulative damage at worst item'];
                        saveas(f11, dir, 'fig')
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
            end
            
            amplitudes = getappdata(0, 'amplitudesOnCP');
            cycles = getappdata(0, 'cyclesOnCP');
            Sm = 0.5*(cycles(:, 1) + cycles(:, 2));
            
            %% RHIST RAINFLOW HISTOGRAM OF CYCLES
            
            if outputFigure == 1.0 && outputField == 1.0 && getappdata(0, 'figure_RHIST') == 1.0
                f12 = figure('visible', 'off');
                rhistData = [Sm'; 2.*amplitudes]';
                nBins = getappdata(0, 'numberOfBins');
                hist3(rhistData, [nBins, nBins])
                
                set(gcf, 'renderer', 'opengl');
                set(get(gca, 'child'), 'FaceColor', 'interp', 'CDataMode', 'auto');
                colorbar
                
                msg = sprintf('RHIST, Rainflow cycle histogram at item %.0f.%.0f', mainID, subID);
                xlabel('Mean Stress (MPa)', 'FontSize', fontX)
                ylabel('Stress Range (MPa)', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                dir = [root, 'MATLAB Figures/RHIST, Rainflow cycle histogram at worst item'];
                saveas(f12, dir, 'fig')
                postProcess.makeVisible([dir, '.fig'])
            end
            
            %% RC RANGE vs CYCLES
            
            if outputFigure == 1.0 && outputField == 1.0 && getappdata(0, 'figure_RC') == 1.0
                f13 = figure('visible', 'off');
                rhistData = [Sm'; 2*amplitudes]';
                [h, bins] = hist3(rhistData, [nBins, nBins]);
                
                plot(bins{2}, sum(h), '-', 'LineWidth', lineWidth, 'Color', midnightBlue);

                msg = sprintf('RC, Stress range distribution at item %.0f.%.0f', mainID, subID);
                xlabel('Stress Range (MPa)', 'FontSize', fontX)
                ylabel('Cycles', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/RC, Stress range distribution at worst item'];
                saveas(f13, dir, 'fig')
                postProcess.makeVisible([dir, '.fig'])
            end
        end
        
        %% BS 7608 WRITE HISTORY OUTPUT
        function [] = exportHistories(loadEqUnits)
        
            root = getappdata(0, 'outputDirectory');
            
            %{
                LOAD HISTORIES -> Multiple values at worst item over all signal
                increments
            %}
            
            worstMainID = getappdata(0, 'worstMainID');
            worstSubID = getappdata(0, 'worstSubID');
            
            INCi = getappdata(0, 'signalLength');
            INC = 1:INCi;
            
            VM = getappdata(0, 'WNVM');
            PS1 = getappdata(0, 'WNPS1');
            PS2 = getappdata(0, 'WNPS2');
            PS3 = getappdata(0, 'WNPS3');
            CN = getappdata(0, 'CN');
            CS = getappdata(0, 'CS');
            
            data = [INC; VM; PS1; PS2; PS3; CN; CS]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_LOAD') == 1.0
                dir = [root, 'Data Files/h-output-load.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'WORST ITEM LOAD HISTORIES (%.0f.%.0f)\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa\r\n');
                
                fprintf(fid, 'Load Increment\tVM\tPS1\tPS2\tPS3\tCN\tCS\r\n');
                fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
                
                fclose(fid);
            end
            
            %{
                ANGLE HISTORIES -> Multiple values at worst item over all plane
                orientations
            %}
            steps = getappdata(0, 'stepSize');
            step = steps(getappdata(0, 'worstItem'));
            planes = 0:step:180;
            
            ST = getappdata(0, 'shear_cp');
            NT = getappdata(0, 'normal_cp');
            
            PT = getappdata(0, 'DPT');
            DT = getappdata(0, 'DT');
            LT = getappdata(0, 'LT');
            
            data = [planes; ST; NT; PT; DT; LT]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_ANGLE') == 1.0
                dir = [root, 'Data Files/h-output-angle.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'ST, NT, DPP, DP, LP, WORST ITEM ANGLE HISTORIES (%.0f.%.0f)\r\n\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'PHI = %.0f degrees\r\n', getappdata(0, 'phiOnCP'));
                
                if getappdata(0, 'cpShearStress') == 1.0
                    fprintf(fid, 'Plane orientation (THETA-degrees)\tMaximum shear stress (MPa)\tMaximum normal stress (MPa)\tDamage parameter (MPa)\tDamage\tLife (%s)\n', loadEqUnits);
                else
                    fprintf(fid, 'Plane orientation (THETA-degrees)\tResultant shear stress (MPa)\tMaximum normal stress (MPa)\tDamage parameter (MPa)\tDamage\tLife (%s)\n', loadEqUnits);
                end
                
                fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4e\t%.4e\r\n', data');
                
                fclose(fid);
            end
            
            %{
                TENSOR HISTORIES -> Multiple values at worst item on the
                critical plane
            %}
            
            Sxx = getappdata(0, 'worstNodeSxx');
            Syy = getappdata(0, 'worstNodeSyy');
            Szz = getappdata(0, 'worstNodeSzz');
            Txy = getappdata(0, 'worstNodeTxy');
            Tyz = getappdata(0, 'worstNodeTyz');
            Txz = getappdata(0, 'worstNodeTxz');
            
            data = [INC; Sxx; Syy; Szz; Txy; Txz; Tyz]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_TENSOR') == 1.0
                dir = [root, 'Data Files/h-output-tensor.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'ST, WORST ITEM TENSOR HISTORY (%.0f.%.0f)\r\n\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa\r\n');
                
                fprintf(fid, 'Load Increment\tS11\tS22\tS33\tS12\tS13\tS23\r\n');
                
                fprintf(fid, '%.0f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\r\n', data');
                
                fclose(fid);
            end
        end
    end
end
classdef analysis < handle
%ANALYSIS    QFT class for general analysis tasks.
%   This class contains methods for general analysis tasks.
%   
%   ANALYSIS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 25-Apr-2017 12:13:25 GMT
    
    %%
    
    methods(Static = true)
        %% Pre filter the stress signal:
        function fT = preFilter(T, signalLength)
        %PREFILTER Filters a set of stresses to remove any data that could cause
        %the rainflow algorithm to crash.
        %   fT = PREFILTER(T) returns the filtered stresses from the input stresses
        %   defined by T.
        %
        %   See also rainFlow
        
        %   Copyright Louis Vallance, Dassault Systemes Austria GmbH
        %   Last modified 15-Jan-2015 16:24:51
        
        fT = zeros(1.0, signalLength);
        
        [rows, cols] = size(T);
        
        if cols == 1.0
            cols = rows;
        end
        
        index = 2.0;
        
        for j = 1.0:(cols - 1.0)
            if T(j + 1.0) ~= T(j)
                fT(index) = T(j + 1.0);
                index = index + 1.0;
            elseif T(j + 1.0) == T(j)
                fT(index) = 0.999*fT(j + 1.0);
                index = index + 1.0;
            end
        end
        
        if getappdata(0, 'rainflowAlgorithm') == 1.0
            fT(cols + 1.0) = T(2.0);
        end
        
        fT(1.0) = T(1.0);
        end
        
        %% Rainflow cycle count the stress signal:
        function rfData = rainFlow(fT)
            switch getappdata(0, 'rainflowAlgorithm');
                case 1.0
                    rfData = analysis.rainFlow_1(fT);
                case 2.0
                    rfData = analysis.rainFlow_2(fT);
                otherwise
                    rfData = analysis.rainFlow_2(fT);
            end
        end
        
        %% Old cycle counting algorithm:
        function rfData = rainFlow_1(fT)
            peaks = zeros(1.0, 2.0);
            valleys = peaks;
            
            rfData = zeros(1.0, 4.0);
            
            [rows, cols] = size(fT);
            
            if cols > rows
                rows = cols;
            end
            
            %{
                Add a higher peak and a lower valley to the stack so that
                any first data is automatically stored
            %}
            
            ftMax = max(fT);
            ftMin = min(fT);
            
            interv = (0.1/100.0)*abs(ftMax - ftMin);
            
            peaks(1.0, 1.0) = ftMax + interv;
            valleys(1.0, 1.0) = ftMin - interv;
            
            rfT = fT;
            
            % The last point in the signal equals the first
            rfT(rows + 1.0) = rfT(1.0);
            
            pk = 1.0;
            vl = pk;
            pr = pk;
            govys = -1.0;
            gopks = govys;
            
            for index2 = 2:rows
                
                if (rfT(index2) < rfT(index2 + 1.0)) && (rfT(index2) < rfT(index2 - 1.0)) % Valley
                    govys = 0.0;
                elseif (rfT(index2) > rfT(index2 + 1.0)) && (rfT(index2) > rfT(index2 - 1.0)) % Peak
                    gopks = 0.0;
                end
                
                if (govys == 0.0) || (govys == -1.0)
                    while (1.0 < 2.0)
                        
                        if (vl < 1.0)
                            messenger.writeMessage(62.0)
                            return
                        end
                        
                        if rfT(index2) > valleys(vl, 1.0)
                            vl = vl + 1.0;
                            
                            valleys(vl, 1.0) = rfT(index2);
                            valleys(vl, 2.0) = index2 + 1.0;
                            break
                        else
                            % Count a pair
                            rfData(pr, 1.0) = peaks(pk, 1.0);
                            rfData(pr, 2.0) = valleys(vl, 1.0);
                            
                            % Position in the tensor history
                            rfData(pr, 3.0) = peaks(pk, 2.0);
                            rfData(pr, 4.0) = valleys(vl, 2.0);
                            
                            pk = pk - 1.0;
                            vl = vl - 1.0;
                            pr = pr + 1.0;
                        end
                    end
                    govys = -1.0;
                end
                
                if (gopks == 0.0) || (gopks == -1.0)
                    while (1.0 < 2.0)
                        
                        if rfT(index2) < peaks(pk, 1.0)
                            pk = pk + 1.0;
                            
                            peaks(pk, 1.0) = rfT(index2);
                            peaks(pk, 2.0) = index2 + 1.0;
                            break
                        else
                            % Count a pair
                            rfData(pr, 1.0) = peaks(pk, 1.0);
                            rfData(pr, 2.0) = valleys(vl, 1.0);
                            
                            % Position in the tensor history
                            rfData(pr, 3.0) = peaks(pk, 2.0);
                            rfData(pr, 4.0) = valleys(vl, 2.0);
                            
                            pk = pk - 1.0;
                            vl = vl - 1.0;
                            pr = pr + 1.0;
                        end
                        
                    end
                    gopks = -1.0;
                end
            end
            

            %% Re-order the cycles to match the original signal as closely as possible
            positions = sort(min(rfData(:, 3.0:4.0), [], 2.0));
            [N, ~] = size(rfData);
            rfData2 = zeros(N, 4.0);
            for x = 1.0:N
                for y = 1.0:N
                    if rfData(y, 3.0) == positions(x) || rfData(y, 4.0) == positions(x)
                        rfData2(x, :) = rfData(y, :);
                        break
                    end
                end
            end
            rfData = rfData2;
        end
        
        %% New cycle counting algorithm:
        function rfData = rainFlow_2(fT)
            %% If the signal is all zero, set the cycle buffer to a zero-valued cycle
            if all(fT == 0.0) == 1.0
                rfData = zeros(1.0, 4.0);
                return
            end
            
            %% Re-arrange fT so max is at the start:
            L = length(fT);
            
            % Store locations of load history
            historyPosition = linspace(1.0, L, L);
            
            if abs(fT(1.0)) ~= max(abs(fT))
                signal_temp = zeros(1.0, L);
                historyPosition_temp = zeros(1.0, L);
                
                maxA = max(fT);
                maxB = abs(min(fT));
                if maxA >= maxB
                    indexOfMaximum = find(fT == maxA);
                else
                    indexOfMaximum = find(fT == min(fT));
                end
                
                if length(indexOfMaximum) > 1.0
                    indexOfMaximum = indexOfMaximum(1.0);
                end
                
                rightHandElements = L - indexOfMaximum;
                
                % Reconstruct the fT with the maximum at the start
                if rightHandElements == 0.0
                    % fT
                    signal_temp(1.0) = fT(end);
                    signal_temp(2.0 : end) = fT(1.0 : end - 1.0);
                    
                    % History position
                    historyPosition_temp(1.0) = historyPosition(end);
                    historyPosition_temp(2.0 : end) = historyPosition(1.0 : end - 1.0);
                else
                    % fT
                    signal_temp(1.0) = fT(indexOfMaximum);
                    signal_temp(2.0 : rightHandElements + 1.0) = fT(indexOfMaximum + 1.0 : end);
                    signal_temp(rightHandElements + 2.0 : end) = fT(1.0 : indexOfMaximum - 1.0);
                    
                    % History position
                    historyPosition_temp(1.0) = historyPosition(indexOfMaximum);
                    historyPosition_temp(2.0 : rightHandElements + 1.0) = historyPosition(indexOfMaximum + 1.0 : end);
                    historyPosition_temp(rightHandElements + 2.0 : end) = historyPosition(1.0 : indexOfMaximum - 1.0);
                end
                
                fT = signal_temp;
                historyPosition = historyPosition_temp;
            end
            
            %% Remove plateaus
            %{
                Sometimes after rearranging the signal to put the maximum
                at the start can result in plateaus (e.g. if the original
                signal has equal start and finish values). Check for these
                plateaus and remove them if applicable
            %}
            % Remove tails at start of signal
            finished = 0.0;
            while finished == 0.0
                if fT(1.0) == fT(2.0)
                    fT(1.0) = [];
                    
                    % Update the history position buffer
                    historyPosition(1.0) = [];
                else
                    finished = 1.0;
                end
            end
            
            % If the signal now has a length of 2.0, count the cycle and RETURN
            if length(fT) < 3.0
                rfData = [min(fT), max(fT), find(fT == min(fT)), find(fT == max(fT))];
                return
            end
            
            % Remove tails at end of signal
            finished = 0.0;
            while finished == 0.0
                if fT(end) == fT(end - 1.0)
                    fT(end) = [];
                    
                    % Update the history position buffer
                    historyPosition(end) = [];
                else
                    finished = 1.0;
                end
            end
            
            % If the signal now has a length of 2.0, count the cycle and RETURN
            if length(fT) < 3.0
                rfData = [min(fT), max(fT), find(fT == min(fT)), find(fT == max(fT))];
                return
            end
            
            % Remove constant values in the middle of the signal
            finished = 0.0;
            index = 3.0;
            while finished == 0.0
                if fT(index) == fT(index - 1.0)
                    if (fT(index - 2.0) > fT(index - 1.0) && fT(index + 1.0) < fT(index)) || ((fT(index - 2.0) < fT(index - 1.0) && fT(index + 1.0) > fT(index)))
                        %{
                            The plateau is in the middle of an excursion
                            e.g. [1, 0, 0, -1] or [-1, 0, 0, 1]
    
                            Remove both similar points
                        %}
                        fT(index - 1.0:index) = [];
                        
                        % Update the history position buffer
                        historyPosition(index - 1.0:index) = [];
                    else
                        %{
                            The plateau is in the middle of a turning
                            point
                            e.g. [1, 0, 0, 1] or [-1, 0, 0, -1],
                            or the current point is between two or more 
                            similar points
                            e.g. [-1, 0, 0, 0, 1]
                        
                            Remove the current point only
                        %}
                        fT(index) = [];
                        
                        % Update the history position buffer
                        historyPosition(index) = [];
                    end
                else
                    % No plateau was detected at this point, so move
                    % forward in the load history
                    index = index + 1.0;
                end
                
                if index >= length(fT)
                    finished = 1.0;
                end
            end
            
            if length(fT) < 3.0
                % If the signal now has a length of 2.0, count the cycle and RETURN
                rfData = [min(fT), max(fT), find(fT == min(fT)), find(fT == max(fT))];
                return
            else
                %{
                    If the end value of the signal is different from the
                    start value, append the start value to the end of the
                    signal
                %}
                if fT(1.0) ~= fT(end)
                    fT = [fT, fT(1.0)];
                    historyPosition = [historyPosition, historyPosition(1.0)];
                end
            end
            
            %% Check the signal for intermediate data points
            %{
                After removing plateaus, it is possible that the signal now
                contains intermediate points (points which lie between two
                inflection points). These load values do not contribute
                towards fatigue and can cause spurious cycles to be
                counted. Remove the intermediate data.
            %}
            if length(fT) > 2.0
                finished = 0.0;
                index = 2.0;
                while finished == 0.0
                    if length(fT) < 3.0 || index == length(fT)
                        finished = 1.0;
                    elseif fT(index) > fT(index - 1.0) && fT(index) < fT(index + 1.0) ||...
                            fT(index) < fT(index - 1.0) && fT(index) > fT(index + 1.0)
                        % Remove the cycle from the signal
                        fT(index) = [];
                        historyPosition(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
            
            %% Cycle count the fT
            signal_rainflow = fT;
            historyPosition_rainflow = historyPosition;
            rfData = zeros(length(fT), 4.0);
            buffer_index = 1.0;
            cycle_index = 2.0;
            finished = 0.0;
            
            while finished == 0.0
                % Update index
                cycle_index = 1.0 + cycle_index;
                if cycle_index == 2.0
                    cycle_index = 3.0;
                end
                
                % Update local cycle counter
                remainingCycles = 1.0;
                cyclesRemoved = 0.0;
                
                while remainingCycles == 1.0
                    if length(signal_rainflow) >= cycle_index
                        %{
                            Only continue if there are enough history
                            points remaining to compare two adjacent ranges
                        %}
                        if cycle_index < 3.0
                            %{
                                There are not enough hostory points behind
                                the current point to count a cycle. Move to
                                the next point in the load history
                            %}
                            
                            remainingCycles = 0.0;
                        elseif abs(signal_rainflow(cycle_index) - signal_rainflow(cycle_index - 1.0)) >= abs(signal_rainflow(cycle_index - 1.0) - signal_rainflow(cycle_index - 2.0))
                            %{
                                If the range of the current excursion
                                exceeds the range of the previous
                                excursion, count a cycle. The cycle is
                                defined as the range of the previous
                                excursion
                            %}
                            
                            % Count the cycle
                            rfData(buffer_index, 1.0) = signal_rainflow(cycle_index - 2.0);
                            rfData(buffer_index, 2.0) = signal_rainflow(cycle_index - 1.0);
                            
                            % Position in the history
                            rfData(buffer_index, 3.0) = historyPosition_rainflow(cycle_index - 2.0);
                            rfData(buffer_index, 4.0) = historyPosition_rainflow(cycle_index - 1.0);
                            
                            % Remove cycle from fT
                            signal_rainflow(cycle_index - 2.0:cycle_index - 1.0) = [];
                            historyPosition_rainflow(cycle_index - 2.0:cycle_index - 1.0) = [];
                            
                            % Update index
                            buffer_index = buffer_index + 1.0;
                            cycle_index = cycle_index - 2.0;
                            
                            % Count the number of cycles removed
                            cyclesRemoved = cyclesRemoved + 1.0;
                        else
                            remainingCycles = 0.0;
                        end
                    else
                        remainingCycles = 0.0;
                        finished = 1.0;
                    end
                end
            end
            
            %{
                All cycles have been extracted
            %}
            
            %% Check the signal for intermediate data points
            %{
                After the initial cycle counting procedure, it is possible
                that the signal now contains intermediate points (points
                which lie between two inflection points). These load values
                do not contribute towards fatigue and can cause spurious
                cycles to be counted. Remove the intermediate data.
            %}
            if length(signal_rainflow) > 2.0
                finished = 0.0;
                index = 2.0;
                while finished == 0.0
                    if length(signal_rainflow) < 3.0 || index == length(signal_rainflow)
                        finished = 1.0;
                    elseif signal_rainflow(index) > signal_rainflow(index - 1.0) && signal_rainflow(index) < signal_rainflow(index + 1.0) ||...
                            signal_rainflow(index) < signal_rainflow(index - 1.0) && signal_rainflow(index) > signal_rainflow(index + 1.0)
                        % Remove the cycle from the signal
                        signal_rainflow(index) = [];
                        historyPosition_rainflow(index) = [];
                    else
                        index = index + 1.0;
                    end
                end
            end
            
            %% Check for unmatched half cycles
            finished = 0.0;
            index = 1.0;
            
            while finished == 0.0
                if length(signal_rainflow) <= 1.0
                    % All data has been removed from the fT, so stop counting
                    finished = 1.0;
                else
                    % Count the cycle
                    rfData(buffer_index, 1.0) = signal_rainflow(index);
                    rfData(buffer_index, 2.0) = signal_rainflow(index + 1.0);
                    
                    % Position in the history
                    rfData(buffer_index, 3.0) = historyPosition_rainflow(index);
                    rfData(buffer_index, 4.0) = historyPosition_rainflow(index + 1.0);
                    
                    % Remove cycle from fT
                    signal_rainflow(index:index + 1.0) = [];
                    historyPosition_rainflow(index:index + 1.0) = [];
                    
                    buffer_index = buffer_index + 1.0;
                end
            end
            
            %% Remove empty cycles from the cycle buffer
            i = 1.0;
            emptyCycles = 1.0;
            [cycleRemaining, ~] = size(rfData);
            while emptyCycles == 1.0
                if rfData(i, 1.0) == 0.0 && rfData(i, 2.0) == 0.0
                    rfData(i, :) = [];
                    cycleRemaining = cycleRemaining - 1.0;
                else
                    i = i + 1.0;
                end
                
                if i > cycleRemaining
                    emptyCycles = 0.0;
                end
            end
            
            %% If no cycles were counted, reset the cycle buffer to a zero-valued cycle
            if isempty(rfData) == 1.0
                rfData = zeros(1.0, 4.0);
            else
                %% Re-order the cycles to match the original signal as closely as possible
                positions = sort(min(rfData(:, 3.0:4.0), [], 2.0));
                [N, ~] = size(rfData);
                rfData2 = zeros(N, 4.0);
                for x = 1:N
                    for y = 1:N
                        if (rfData(y, 3.0) == positions(x)) || (rfData(y, 4.0) == positions(x))
                            rfData2(x, :) = rfData(y, :);
                            break
                        end
                    end
                end
                rfData = rfData2;
            end
        end
        
        %% Get amplitudes from rainflow pairs:
        function [amps, numberOfAmps] = getAmps(pairs)
        [numberOfAmps, ~] = size(pairs);
            
        amps = zeros(1.0, numberOfAmps);
        
        for index = 1:numberOfAmps
            amp = 0.5*(max(pairs(index, :)) - min(pairs(index, :)));
            amps(index) = abs(amp);
        end
        end
        
        %% Obtain the Findley parameter:
        function [findleyParam, findleyParamAll] = getFindleyParameter(amps, times, normals, numberOfAmps)
            
            %{
                If the user chose to take the maximum normal stress over
                the entire loading, the normal stress can be determined
                immediately
            %}
            if getappdata(0, 'findleyNormalStress') == 1.0
                % Use maximum normal stress over loading
                normalStress = max(normals);
                
                findleyParamAll = amps + normalStress;
                findleyParam = max(findleyParamAll);
                return
            end
            
            %% Initialise variables
            loTimes = times(:, 1.0)';
            hiTimes = times(:, 2.0)';
            
            findleyParamAll = zeros(1.0, numberOfAmps);
            
            numberOfNormals = length(normals);
            
            %% Begin calculation
            for index = 1:numberOfAmps
                if (loTimes(index) > numberOfNormals) || (hiTimes(index) > numberOfNormals)
                    %{
                        The normal range falls at least partially out of
                        the scope of the shear cycle
        
                        -> Collect all the normal stresses which fit inside this range
                    %}
                    if (loTimes(index) > numberOfNormals) && (hiTimes(index)> numberOfNormals)
                        %{
                            In this case, the requested normal range falls completely
                            outside the scope of the shear cycle
            
                            -> Set the number of normals within the shear cycle to zero
                        %}
                        
                        normalsInRange = 0.0;
                    elseif (hiTimes(index) > numberOfNormals)
                        %{
                            The high end of the cycle falls out of scope
                        %}
                        
                        normalsInRange = normals(loTimes(index):length(normals));
                    end
                elseif (loTimes(index) == 0.0) && (hiTimes(index) == 0.0)
                    %{
                        There is no normal stress associated with the shear cycle
        
                        -> Use only the shear stress for the Findley parameter
                    %}
                    
                    messenger.writeMessage(63.0)
                    normalsInRange = 0.0;
                elseif (loTimes(index) < hiTimes(index))
                    normalsInRange = normals(loTimes(index):hiTimes(index));
                else
                    normalsInRange = normals(hiTimes(index):loTimes(index));
                end
                
                % Get the correct normal stress based on the user setting
                if getappdata(0, 'findleyNormalStress') == 2.0
                    % Use maximum normal stress over maximum shear cycle interval
                    normalStress = max(normalsInRange);
                elseif getappdata(0, 'findleyNormalStress') == 3.0
                    % Use average normal stress over maximum shear cycle interval
                    normalStress = mean(normalsInRange);
                else
                    % Use maximum normal stress over maximum shear cycle interval
                    normalStress = max(normalsInRange);
                end
                
                findleyParamAll(index) = amps(index) + normalStress;
            end
            
            findleyParam = max(findleyParamAll);
        end
        
        %% Get the value of Kt for a given life N
        function ktn = getKtn(N, constant, radius)
            % Get the reference (un-notched) value of Kt
            kt = getappdata(0, 'kt');
            
            % Get the notch sensitivity method
            method = getappdata(0, 'notchFactorEstimation');
            
            % Warn the user if the notch factor could not be evaluated
            if ((method ~= 1.0) && (method ~= 6.0)) && ((constant == 0.0) || (radius == 0.0))
                messenger.writeMessage(220.0)
                method = 1.0;
            end
            if (method == 6.0) && (constant == 0.0)
                messenger.writeMessage(220.0)
                method = 1.0;
            end
            
            % Get value of Kt at the given life (Kt_f)
            switch method
                case 1.0 % Peterson (default)
                    ktn = 1.0 + ((kt - 1.0)/(0.915 + ((200.0)/((log10(N))^4.0))));
                case 2.0 % Peterson B
                    ktn = 1.0 + ((kt - 1.0)/(1.0 + (constant/radius)));
                case 3.0 % Neuber
                    ktn = 1.0 + ((kt - 1.0)/(1.0 + sqrt(constant/radius)));
                case 4.0 % Harris
                    ktn = exp(-radius/constant) + kt^(1.0 - exp(-radius/constant));
                case 5.0 % Heywood
                    ktn = (kt)/(1.0 + 2.0*sqrt(constant/radius));
                case 6.0 % Notch sensitivity
                    ktn = 1.0 + constant*(kt - 1.0);
                otherwise % Peterson (default)
                    ktn = 1.0 + ((kt - 1.0)/(0.915 + ((200.0)/((log10(N))^4.0))));
            end
        end
        
        %% Gate the tensors
        function damageParameter = gateTensors(damageParameter, gateTensors, tensorGate)
            % Perform peak-valley detection if a user-defined history is being used
            if gateTensors == 1.0
                % Get gating values from % of max tensor
                if tensorGate > 0.0
                    tensorGate = preProcess.autoGate(damageParameter, tensorGate);
                end
                
                [peaks, valleys] = preProcess.peakdet(damageParameter, tensorGate);
                
                if isempty(peaks) || isempty(valleys)
                    % Use Nielsony's method
                    damageParameter = preProcess.sig2ext(damageParameter)';
                    return
                end
                
                % Order the P-V time values from low to high
                times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                
                % Reconstruct the history signal
                newLength = length(times);
                damageParameter = zeros(1.0, newLength);
                
                peak_j = 1.0; valley_j = 1.0;
                
                for j = 1.0:newLength
                    if any(peaks(:, 1.0) == times(j))
                        damageParameter(j) = peaks(peak_j, 2.0);
                        peak_j = peak_j + 1.0;
                    else
                        damageParameter(j) = valleys(valley_j, 2.0);
                        valley_j = valley_j + 1.0;
                    end
                end
            elseif gateTensors == 2.0
                % Use Nielsony's method
                damageParameter = preProcess.sig2ext(damageParameter)';
            end
        end
        
        %% Mean stress correction
        function [mscCycles, warning, overflowCycles] = msc(cycles, pairs, msCorrection)
            % Initialize output
            warning = 0.0;
            k = 1.0;
            overflowCycles = 0.0;
            mscCycles = [];
            
            % Check if the UTS is available
            uts = getappdata(0, 'uts');
            if isempty(uts) && (msCorrection == 5.0 || msCorrection == 7.0)
                mscCycles = cycles;
                return
            end
            
            % Check if the UCS is available
            ucs = getappdata(0, 'ucs');
            if isempty(ucs)
                ucs = uts;
            end
            
            % Get the yield stress
            twops = getappdata(0, 'twops');
            
            % Get the mean stress from each cycle
            Sm = 0.5*(pairs(:, 1.0) + pairs(:, 2.0));
            
            % Get the corrected stress amplitudes
            switch msCorrection
                case 1.0 % Morrow
                    Sf = getappdata(0, 'Sf');
                    
                    if getappdata(0, 'useSN') == 0.0 && getappdata(0, 'algorithm') ~= 7.0
                        morrowSf = Sf - Sm;
                        
                        % Check for negative values
                        for i = 1:length(Sm)
                            if morrowSf(i) < 0.0
                                morrowSf(i) = 1e-06;
                                
                                % Warn the user
                                messenger.writeMessage(257.0)
                            end
                        end
                        setappdata(0, 'morrowSf', morrowSf)
                        mscCycles = cycles;
                    else
                        mscCycles = cycles.*((1.0 - ((Sm')./(Sf))).^-1.0);
                        
                        % Check for negative values
                        for i = 1:length(Sm)
                            if mscCycles(i) < 0.0
                                mscCycles(i) = Sf;
                                
                                % Warn the user
                                messenger.writeMessage(159.0)
                            end
                        end
                    end
                case 2.0 % Goodman
                    % Initialise the MSC cycles buffer
                    mscCycles = zeros(1.0, length(Sm));
                    
                    if isempty(twops) == 0.0 && getappdata(0, 'modifiedGoodman') == 1.0
                        % The proof stress is defined, so use the enhanced
                        % Goodman correction if requested
                        
                        % Get the fatigue limit stress
                        S0 = getappdata(0, 'fatigueLimit');
                        
                        % Check for division by zero
                        if uts == S0
                            S0 = S0 - (0.01*S0);
                        end
                        
                        for i = 1:length(Sm)
                            if abs(Sm(i)) > twops
                                % If the mean stress exceeds the proof
                                % stress (positive or negative)
                                mscCycles(i) = cycles(i);
                                warning = 1.0;
                                
                                overflowCycles(k) = i;%#ok<AGROW>
                                k = k + 1.0;
                                
                                % Warn the user
                                messenger.writeMessage(160.0)
                            elseif (Sm(i) == 0.0) || (Sm(i) < 0.0 && Sm(i) >= (S0 - twops))
                                % If the mean stress zero, or in the
                                % flat negative region
                                mscCycles(i) = cycles(i);
                            elseif (Sm(i) > 0.0) && (Sm(i) < (twops - S0)/(1.0 - (S0/uts)))
                                % If the mean stress lies between 0 and yield intercept
                                mscCycles(i) = cycles(i)/(1.0 - (Sm(i)/uts));
                            elseif (Sm(i) >= (twops - S0)/(1.0 - (S0/uts)) && Sm(i) <= twops) || (Sm(i) < (S0 - twops) && abs(Sm(i)) <= twops)
                                % If the mean stress lies between the yield
                                % intercept and the yield stress (positive
                                % or negative)
                                Sm(i) = abs(Sm(i));
                                mscCycles(i) = cycles(i)/(1.0 - (Sm(i)/twops));
                            end
                        end
                    else
                        % Get the Goodman limit stress (x-axis intercept)
                        goodmanLimit = getappdata(0, 'goodmanMeanStressLimit');
                        
                        % Use the standard Goodman envelope
                        for i = 1:length(Sm)
                            if Sm(i) < 0.0
                                % Special case where the mean stress is negative
                                mscCycles(i) = cycles(i);
                            else
                                mscCycles(i) = cycles(i)*((1.0 - ((Sm(i))/(goodmanLimit))).^-1.0);
                            end
                        end
                        
                        %{
                            If the mean stress of the cycle exceeds the
                            Goodman limit stress, warn the user
                        %}
                        if max(Sm) >= goodmanLimit
                            warning = 1.0;
                            for j = 1:length(mscCycles)
                                if Sm(j) >= goodmanLimit
                                    % Record the overflow cycle number
                                    overflowCycles(k) = j;%#ok<AGROW>
                                    k = k + 1.0;
                                    
                                    % Reset the corrected cycle
                                    mscCycles(j) = cycles(j);
                                    
                                    % Warn the user
                                    messenger.writeMessage(161.0)
                                end
                            end
                        end
                    end
                case 3.0 % Soderberg
                    mscCycles = cycles.*((1.0 - ((Sm')./(twops))).^-1.0);
                    
                    if max(Sm) >= twops
                        warning = 1.0;
                        for j = 1:length(mscCycles)
                            if Sm(j) >= twops
                                overflowCycles(k) = j;%#ok<AGROW>
                                k = k + 1.0;
                                
                                % Reset the corrected cycle
                                mscCycles(j) = cycles(j);
                                
                                % Warn the user
                                messenger.writeMessage(160.0)
                            end
                        end
                    end
                case 4.0 % Walker
                    gamma = getappdata(0, 'walkerGamma');
                    
                    % Get the maximum cycle and load ratio
                    [numberOfPairs, ~] = size(pairs);
                    maxCycle = zeros(1.0, numberOfPairs);
                    minCycle = maxCycle;
                    for i = 1:numberOfPairs
                        maxCycle(i) = max(pairs(i, :));
                        minCycle(i) = min(pairs(i, :));
                    end
                    R = minCycle./maxCycle;
                    
                    if gamma == -9999.0
                        % Calculate gamma based on load ratio
                        gamma = zeros(1.0, numberOfPairs);
                        for i = 1:numberOfPairs
                            if R(i) < 0.0
                                gamma(i) = 1.0;
                            else
                                gamma(i) = 0.5;
                            end
                        end
                    end
                    
                    mscCycles = maxCycle.*((1.0-R)./2.0).^gamma;
                    for i = 1:numberOfPairs
                        if isreal(mscCycles(i)) == 0.0 || isinf(mscCycles(i)) || isnan(mscCycles(i))
                            mscCycles(i) = cycles(i);
                        end
                    end
                case 5.0 % Smith-Watson-Topper
                        % SWT correction is applied indirectly
                        [numberOfPairs, ~] = size(pairs);
                        maxCycle = zeros(1.0, numberOfPairs);
                        minCycle = maxCycle;
                        for i = 1:numberOfPairs
                            maxCycle(i) = max(pairs(i, :));
                            minCycle(i) = min(pairs(i, :));
                        end
                        R = minCycle./maxCycle;
                        mscCycles = maxCycle.*((1.0-R)./2.0).^0.5;
                        for i = 1:numberOfPairs
                            if isreal(mscCycles(i)) == 0.0 || isinf(mscCycles(i)) || isnan(mscCycles(i))
                                mscCycles(i) = cycles(i);
                            end
                        end
                case 6.0 % Gerber
                    mscCycles = cycles.*((1.0 - ((Sm')./(uts)).^2.0).^-1.0);
                    
                    if max(Sm) >= uts
                        warning = 1.0;
                        for j = 1:length(mscCycles)
                            if Sm(j) >= uts
                                overflowCycles(k) = j;%#ok<AGROW>
                                k = k + 1.0;
                                
                                % Reset the corrected cycle
                                mscCycles(j) = cycles(j);
                                
                                % Warn the user
                                messenger.writeMessage(161.0)
                            end
                        end
                    end
                case -1.0 % User-defined
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
                            
                            messenger.writeMessage(58.0)
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
                            
                            messenger.writeMessage(58.0)
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
                otherwise
            end
        end
        
        %% Modify the endurance limit
        function [fatigueLimit, zeroDamage] = modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycle, cyclesToRecover, residual, enduranceScale)
            %{
                Flag to indicate whether the current cycle will result in
                fatigue damage
            %}
            zeroDamage = 0.0;
            
            %{
                The FOS calculation can become unreliable if the fatigue
                limit is modified. If the function is called during the FOS
                calculation, RETURN
            %}
            if getappdata(0, 'FOS_disableEnduranceZeroDamage') == 1.0
                return
            end
            
            if (modifyEnduranceLimit == 1.0) && (ndEndurance == 1.0)
                %{
                    Treatment of the fatigue limit is enabled by the
                    user. Zero damage for cycles under the fatigue limit
                    must also be enabled
                %}
                if (cycle + residual) < fatigueLimit
                    %{
                        The current the cycle is below the fatigue limit,
                        so assume no damage
                    %}
                    zeroDamage = 1.0;
                elseif (cycle + residual) >= fatigueLimit_original
                    %{
                        The current cycle exceeds the unmodified fatigue
                        limit. Reduce the fatigue limit by the
                        pre-determined scale factor
                    %}
                    fatigueLimit = enduranceScale*fatigueLimit_original;
                end
                
                if (fatigueLimit < fatigueLimit_original) && ((cycle + residual) < fatigueLimit_original)
                    %{
                        The fatigue limit was modified by a previous
                        cycle. If the current cycle and fatigue limit are
                        less than the unmodified fatigue limit, apply an
                        increment of recovery to the fatigue limit
                    %}
                    fatigueLimit = fatigueLimit + ((fatigueLimit_original - (enduranceScale*fatigueLimit_original))/cyclesToRecover);
                end
            elseif (isempty(fatigueLimit) == 0.0) && (ndEndurance == 1.0)
                if (cycle + residual) < fatigueLimit
                    %{
                        Treatment of the endurance limit is not enabled by
                        the user, zero damage for cycles below the
                        fatigue limit is enabled, the fatigue limit is
                        defined and the current cycle is below the
                        fatigue limit
                    %}
                    zeroDamage = 1.0;
                end
            end
        end
        
        %% Pre-count the shear and normal parameters
        function [pairs, amplitudes] = preCount(shearStress, normalStress)
            % Pre-rainflow the normal and shear stress
            rfData_shear = analysis.rainFlow(shearStress);
            rfData_normal = analysis.rainFlow(normalStress);
            
            % Get rainflow pairs from rfData
            pairs_shear = rfData_shear(:, 1.0:2.0);
            pairs_normal = rfData_normal(:, 1.0:2.0);
            
            % Get the amplitudes from the rainflow pairs
            [amplitudes_shear, ~] = analysis.getAmps(pairs_shear);
            [amplitudes_normal, ~] = analysis.getAmps(pairs_normal);
            
            % Resample the amplitudes in case they are different lengths
            lengthShear = length(amplitudes_shear);
            lengthNormal = length(amplitudes_normal);
            
            if lengthShear ~= lengthNormal
                if lengthShear > lengthNormal
                    % Set the filter parameter
                    if mod(lengthLowF, 2.0) == 1.0
                        L = (lengthNormal - 1.0)/2.0;
                    else
                        L = (lengthNormal - 2.0)/2.0;
                        
                        if L == 0.0
                            L = 1.0;
                        end
                    end
                    
                    R = lengthShear/lengthNormal;
                    
                    try
                        amplitudes_normal = interp(amplitudes_normal, R, L, 0.5);
                    catch
                        messenger.writeMessage(190.0)
                        amplitudes_normal = [amplitudes_normal, zeros(1.0, lengthShear - lengthNormal)];
                    end
                else
                    % Set the filter parameter
                    if mod(lengthShear, 2.0) == 1.0
                        L = (lengthShear - 1.0)/2.0;
                    else
                        L = (lengthShear - 2.0)/2.0;
                        
                        if L == 0.0
                            L = 1.0;
                        end
                    end
                    
                    R = lengthNormal/lengthShear;
                    
                    try
                        amplitudes_shear = interp(amplitudes_shear, R, L, 0.5);
                    catch
                        messenger.writeMessage(190.0)
                        amplitudes_shear = [amplitudes_shear, zeros(1.0, lengthNormal - lengthShear)];
                    end
                end
            end
            
            % Get rainflow pairs from rfData
            [rowsShear, ~] = size(pairs_shear);
            [rowsNormal, ~] = size(pairs_normal);
            
            if rowsShear > rowsNormal
                pairs_normal = [pairs_normal; zeros((rowsShear - rowsNormal), 2.0)];
            elseif rowsShear < rowsNormal
                pairs_shear = [pairs_shear; zeros((rowsNormal - rowsShear), 2.0)];
            end
            
            pairs = pairs_shear + pairs_normal;
            
            % Get the SBBM parameter
            amplitudes = amplitudes_shear + amplitudes_normal;
        end
    end
end
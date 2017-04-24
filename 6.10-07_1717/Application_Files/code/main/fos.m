function [] = fos(gateTensors, tensorGate, coldItems, algorithm, msCorrection, N, L, mainID, subID, fid_status)
%FOS    QFT function to calculate Factor of Strength.
%   This function calculates the Factor of Strength (FOS) of the fatigue
%   loading.
%   
%   FOS is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      8.3 Factor of Strength
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
% Get the loading
Sxx = getappdata(0, 'Sxx');
Syy = getappdata(0, 'Syy');
Szz = getappdata(0, 'Szz');
Txy = getappdata(0, 'Txy');
Tyz = getappdata(0, 'Tyz');
Txz = getappdata(0, 'Txz');

% Get the principal stress history
s1 = getappdata(0, 'S1');
s2 = getappdata(0, 'S2');
s3 = getappdata(0, 'S3');

% Get the damage at each item
nodalDamage = getappdata(0, 'D');

% Get the FOS target life mode
fosTarget = getappdata(0, 'fosTarget');

% Get the design life defined in the job file
dLife = getappdata(0, 'dLife');

% Save the original nodal damage variable
nodalDamage_original = nodalDamage;

% Initialise the FOS variable
fos = zeros(1.0, N);

% Save thte total number of items
Nt = N;

% Get the rainflow type variable
rainflowMode = getappdata(0, 'rainflowMode');

% Get the stress invariant parameter type
stressInvParamType = getappdata(0, 'stressInvariantParameter');

% Fetch important variables
step = getappdata(0, 'stepSize');
planePrecision = getappdata(0, 'planePrecision');
nodalPhiC = zeros(1.0, 1.0);
nodalThetaC = zeros(1.0, 1.0);
signConvention = getappdata(0, 'signConvention');
nodalPairs = cell(1.0, 1.0);
nodalAmplitudes = cell(1.0, 1.0);
setappdata(0, 'FOS_disableEnduranceZeroDamage', 1.0)

% Get the initial damage parameter for each item
nodalDamageParameter = getappdata(0, 'WCDP');

% Get the FOS band definitions
fosMaxValue = getappdata(0, 'fosMaxValue');
fosMaxFine = getappdata(0, 'fosMaxFine');
fosMinFine = getappdata(0, 'fosMinFine');
fosMinValue = getappdata(0, 'fosMinValue');
fosFineIncrement = getappdata(0, 'fosFineIncrement');
fosCoarseIncrement = getappdata(0, 'fosCoarseIncrement');
fosMaxFineIterations = getappdata(0, 'fosMaxFineIterations');
fosMaxCoarseIterations = getappdata(0, 'fosMaxCoarseIterations');
fosTolerance = 0.01*getappdata(0, 'fosTolerance');
fosBreakAfterBracket = getappdata(0, 'fosBreakAfterBracket');

% Get the augmentation parameters
fosAugment = getappdata(0, 'fosAugment');
fosAugmentThreshold = getappdata(0, 'fosAugmentThreshold');
fosAugmentFactor = getappdata(0, 'fosAugmentFactor');

% FOS/Life Buffer
nodal_fos_buffer = cell(1.0, N);
nodal_life_buffer = cell(1.0, N);
nodal_tolerance_buffer = cell(1.0, N);
iterFine_buffer = zeros(1.0, N);
iterCoarse_buffer = zeros(1.0, N);

% Get the number of groups
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Record each target life if necessary
targetLife_buffer = zeros(1.0, G);

% Total counter
totalCounter = 0.0;

% Flag indicating if the solution is bracketed
bracketedSolution = 0.0;

% Flag indicating why the FOS calculation was terminated
setappdata(0, 'message_247_breakCondition', 0.0)

% Flag to indicate that automatical backeting has been enabled
autoBracket = 0.0;

% Print FOS header to status file
fprintf(fid_status, '\n[POST] Begin FOS analysis');

%% While the FOS limits are met, re-calculate the life for each node
for groups = 1:G
    %{
        If the analysis is a PEEK analysis, override the value of GROUP to
        the group containing the PEEK item
    %}
    if getappdata(0, 'peekAnalysis') == 1.0
        groups = getappdata(0, 'peekGroup'); %#ok<FXSET>
    end
    
    if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
        % There is one, default group
        groupIDs = linspace(1.0, N, N);
    else
        % Assign group parameters to the current set of analysis IDs
        [N, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
    end
    
    % Get the target life for the current group
    if fosTarget == 1.0
        targetLife = dLife;
    else
        targetLife = 0.5*getappdata(0, 'cael');
        targetLife_buffer(groups) = targetLife;
    end
    
    for node = 1.0:N
        
        totalCounter = totalCounter + 1.0;
        
        %{
            If groups are being used, convert the current item number to
            the current item ID in the current group
        %}
        groupItem = groupIDs(node);
        
        % Skip items which have been eliminated from the analysis
        if any(totalCounter == coldItems) == 1.0
            % Update the FOS variable
            fos(totalCounter) = fosMaxValue;
            nodal_tolerance_buffer{totalCounter} = 0.0;
            continue
        end
        
        % Initialize the iteration counter
        iterFine = 0.0;
        iterCoarse = 0.0;
        
        % Get the life for the current analysis item
        life_i = 1.0/nodalDamage(totalCounter);
        
        % Calculate the initial FOS value
        if life_i < targetLife
            if (1.0 <= fosMaxFine) && (1.0 >= fosMinFine)
                fos_i = 1.0 - fosFineIncrement;
                iterFine = iterFine + 1.0;
                iterType = 2.0;
            else
                fos_i = 1.0 - fosCoarseIncrement;
                iterCoarse = iterCoarse + 1.0;
                iterType = 1.0;
            end
        elseif life_i > targetLife
            if(1.0 <= fosMaxFine) && (1.0 >= fosMinFine)
                fos_i = 1.0 + fosFineIncrement;
                iterFine = iterFine + 1.0;
                iterType = 2.0;
            else
                fos_i = 1.0 + fosCoarseIncrement;
                iterCoarse = iterCoarse + 1.0;
                iterType = 1.0;
            end
        else
            % The initial FOS is correct
            fos(totalCounter) = 1.0;
            
            % Save the nodal buffers
            nodal_fos_buffer{totalCounter} = 1.0;
            nodal_life_buffer{totalCounter} = life_i;
            nodal_tolerance_buffer{totalCounter} = 0.0;
            iterFine_buffer(totalCounter) = 0.0;
            iterCoarse_buffer(totalCounter) = 0.0;
            
            continue
        end
        
        % Calculate the initial tolerance
        tolerance = life_i/targetLife;
        if tolerance > 1.0
            tolerance = tolerance - 1.0;
        else
            tolerance = 1.0 - tolerance;
        end
        
        fos_buffer = [1.0, fos_i];
        life_buffer = life_i;
        tolerance_buffer = tolerance;
        
        % Get the current loading
        Sxxi_old = Sxx(groupItem, :);
        Syyi_old = Syy(groupItem, :);
        Szzi_old = Szz(groupItem, :);
        Txyi_old = Txy(groupItem, :);
        Tyzi_old = Tyz(groupItem, :);
        Txzi_old = Txz(groupItem, :);
        
        % Re-calculate the life at the current analysis item based on the new
        % loading
        while (tolerance > fosTolerance) && (fos_i <= fosMaxValue) && (fos_i >= fosMinValue)
            % Previous life value
            life_i_old = life_i;
            
            % Scale the stresses by this FOS value
            Sxxi = Sxxi_old.*fos_i;
            Syyi = Syyi_old.*fos_i;
            Szzi = Szzi_old.*fos_i;
            Txyi = Txyi_old.*fos_i;
            Tyzi = Tyzi_old.*fos_i;
            Txzi = Txzi_old.*fos_i;
            
            % Save scaled stresses to the %APPDATA%
            setappdata(0, 'Sxxi_FOS', Sxxi)
            setappdata(0, 'Syyi_FOS', Syyi)
            setappdata(0, 'Szzi_FOS', Szzi)
            setappdata(0, 'Txyi_FOS', Txyi)
            setappdata(0, 'Tyzi_FOS', Tyzi)
            setappdata(0, 'Txzi_FOS', Txzi)
            
            % If necessray, re-calculate the principal stress history
            if algorithm == 4.0 || algorithm == 6.0 || algorithm == 7.0 || algorithm == 9.0
                preProcess.getPrincipalStress(1.0, Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, algorithm, 1.0)
                
                s1i = getappdata(0, 'S1_FOS');
                s2i = getappdata(0, 'S2_FOS');
                s3i = getappdata(0, 'S3_FOS');
            end
            
            switch algorithm
                case 3.0 % UNIAXIAL STRESS-LIFE
                    [~, ~, nodalDamage, nodalDamageParameter, ~] = algorithm_usl.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi, L,...
                        totalCounter, nodalDamage, msCorrection, nodalAmplitudes, nodalPairs, nodalDamageParameter, gateTensors, tensorGate);
                case 4.0 % STRESS-BASED BROWN-MILLER
                    [nodalDamageParameter, ~, ~, ~, ~, nodalDamage] = algorithm_sbbm.main(Sxxi, Syyi, Szzi,...
                        Txyi, Tyzi, Txzi, L, step(totalCounter), planePrecision(totalCounter),...
                        nodalDamageParameter, nodalAmplitudes, nodalPairs, nodalPhiC,...
                        nodalThetaC, totalCounter, msCorrection, nodalDamage, gateTensors, tensorGate,...
                        signConvention, s1i, s2i, s3i, 1.0, rainflowMode);
                case 5.0 % NORMAL STRESS
                    [nodalDamageParameter, ~, ~, ~, ~, nodalDamage] = algorithm_ns.main(Sxxi, Syyi, Szzi,...
                        Txyi, Tyzi, Txzi, L, step(totalCounter), planePrecision(totalCounter),...
                        nodalDamageParameter, nodalAmplitudes, nodalPairs, nodalPhiC,...
                        nodalThetaC, totalCounter, msCorrection, nodalDamage, gateTensors, tensorGate, 1.0);
                case 6.0 % FINDLEY'S METHOD
                    k = getappdata(0, 'k');
                    [nodalDamageParameter, ~, ~, ~, ~, nodalDamage] = algorithm_findley.main(Sxxi, Syyi, Szzi,...
                        Txyi, Tyzi, Txzi, L, step(totalCounter), planePrecision(totalCounter),...
                        nodalDamageParameter, nodalAmplitudes, nodalPairs, nodalPhiC,...
                        nodalThetaC, totalCounter, nodalDamage, msCorrection, gateTensors, tensorGate,...
                        signConvention, s1i, s2i, s3i, 1.0, k);
                case 7.0 % STRESS INVARIANT PARAMETER
                    % Update the stress invariant parameter according to the new loading
                    stressInvParam = preProcess.getStressInvParam(1.0);
                    
                    [nodalAmplitudes, nodalPairs, nodalDamage, nodalDamageParameter] = algorithm_sip.main(s1i, s2i, s3i,...
                        L, totalCounter, nodalDamage, msCorrection, nodalAmplitudes, nodalPairs, nodalDamageParameter,...
                        signConvention, gateTensors, tensorGate, stressInvParam, stressInvParamType, Sxxi, Syyi);
                case 9.0 % NASALIFE
                    % Get the NASALIFE parameter
                    nasalifeParameter = getappdata(0, 'nasalifeParameter');
                    
                    % Update the von Mises stress according to the new loading
                    vm = sqrt(0.5.*((Sxxi - Syyi).^2 + (Syyi - Szzi).^2 +...
                        (Szzi - Sxxi).^2 + 6.*(Txyi.^2 + Tyzi.^2 + Txzi.^2)));
                    
                    % Get the current principal stresses
                    % Get the principal stress history at the current item
                    s1i = s1(totalCounter, :);  s2i = s2(totalCounter, :);  s3i = s3(totalCounter, :);
                    
                    [~, ~, nodalDamage, nodalDamageParameter] = algorithm_nasa.main(Sxxi, Syyi, Szzi, Txyi, Tyzi, Txzi,...
                        L, totalCounter, nodalDamage, nodalAmplitudes, nodalPairs, nodalDamageParameter, s1i, s2i, s3i,...
                        signConvention, gateTensors, tensorGate, vm, nasalifeParameter);
                otherwise
            end
            
            % Get the current life value
            if nodalDamage(totalCounter) == 0.0
                fos_buffer = [fos_buffer, fosMaxValue]; %#ok<AGROW>
                life_buffer = [life_buffer, inf]; %#ok<AGROW>
                tolerance_buffer = [tolerance_buffer, inf]; %#ok<AGROW>
                break
            else
                life_i = 1.0/nodalDamage(totalCounter);
            end
            
            %{
                If the current life value crosses the target life and FOS
                bracketing is enabled, stop the calculation
            %}
            if (fosBreakAfterBracket == 1.0) && ((life_i_old < targetLife && life_i > targetLife) || (life_i_old > targetLife && life_i < targetLife))
                bracketedSolution = 1.0;
                
                life_buffer = [life_buffer, life_i]; %#ok<AGROW>
                
                % Calculate the current tolerance
                tolerance = life_i/targetLife;
                if tolerance > 1.0
                    tolerance = tolerance - 1.0;
                else
                    tolerance = 1.0 - tolerance;
                end
                tolerance_buffer = [tolerance_buffer, tolerance]; %#ok<AGROW>
                
                %{
                    When the FOS is chattering, the last calculated FOS
                    value is not necessarily the most accurate. Take the
                    best FOS value since the chattering began
                %}
                if length(tolerance_buffer) > 2.0
                    % Get the last three tolerance values
                    tolerance_chatter = tolerance_buffer(end - 2.0:end);
                    
                    % Get the smallest FOS of the last three values
                    lowestTolerance = find(tolerance_chatter == min(tolerance_chatter), 1.0);
                    
                    if lowestTolerance < 3.0
                        if lowestTolerance == 1.0
                            stepBackLife = 1.0;
                            stepBackFOS = 0.0;
                        else
                            stepBackLife = 0.0;
                            stepBackFOS = -1.0;
                        end
                        
                        % Step back 1 or 2 iterations
                        life_buffer(end - stepBackLife:end) = [];
                        tolerance_buffer(end - stepBackLife:end) = [];
                        fos_buffer(end - stepBackFOS:end) = [];
                        
                        % Remove the iteration
                        if iterType(end - stepBackLife) == 1.0
                            iterCoarse = iterCoarse - 1.0;
                        else
                            iterFine = iterFine - 1.0;
                        end
                        
                        % Update the tolerance
                        tolerance = tolerance_buffer(end - stepBackLife);
                    end
                end
                
                break
            end
            
            life_buffer = [life_buffer, life_i]; %#ok<AGROW>
            
            % Update the FOS value
            [fos_i, iterFine, iterCoarse, iterType] =...
                fosUpdate(targetLife, life_buffer, iterType,...
                fosFineIncrement, fosCoarseIncrement, life_i, fosMaxFine,...
                fosMinFine, fos_i, iterFine, iterCoarse, fosAugment,...
                fosAugmentThreshold, fosAugmentFactor);
            
            % Calculate the current tolerance
            tolerance = life_i/targetLife;
            if tolerance > 1.0
                tolerance = tolerance - 1.0;
            else
                tolerance = 1.0 - tolerance;
            end
            
            fos_buffer = [fos_buffer, fos_i]; %#ok<AGROW>
            tolerance_buffer = [tolerance_buffer, tolerance]; %#ok<AGROW>
            
            % If the iteration limit has been reached, BREAK
            if iterFine > fosMaxFineIterations
                iterFine = iterFine - 1.0;
                break
            elseif iterCoarse > fosMaxCoarseIterations
                iterCoarse = iterCoarse - 1.0;
                break
            end
            
            % If the FOS appears to be chattering, enable bracketing
            if (length(life_buffer) > 2.0) && (life_buffer(end) == life_buffer(end - 2.0))
                % The FOS appears to be chattering
                fosBreakAfterBracket = 1.0;
                
                autoBracket = 1.0;
            end
        end
        
        %% Get the reason for the FOS algorithm abort
        if Nt == 1.0
            if autoBracket == 1.0
                messenger.writeMessage(246.0)
            end
            
            if (tolerance > fosTolerance) == 0.0
                setappdata(0, 'message_247_breakCondition', 1.0)
            elseif (fos_i <= fosMaxValue) == 0.0
                setappdata(0, 'message_247_breakCondition', 2.0)
            elseif (fos_i >= fosMinValue) == 0.0
                setappdata(0, 'message_247_breakCondition', 3.0)
            elseif iterFine >= fosMaxFineIterations
                setappdata(0, 'message_247_breakCondition', 4.0)
            elseif iterCoarse >= fosMaxCoarseIterations
                setappdata(0, 'message_247_breakCondition', 5.0)
            elseif bracketedSolution == 1.0
                setappdata(0, 'message_247_breakCondition', 6.0)
            end
            messenger.writeMessage(247.0)
        end
        
        %%
        %{
            If the FOS calculation was cut off by the iteration limit,
            remove the last FOS value from the buffer, since the
            corresponding life was not calculated from this value
        %}
        if length(fos_buffer) ~= length(life_buffer)
            fos_buffer(end) = [];
			fos_i = fos_buffer(end);
            
            %{
                If the total number of FOS iterations exceeds the length of
                the FOS buffer,reduce the iteration count by one
            %}
            totalIters = iterCoarse + iterFine;
            if totalIters > length(fos_buffer) - 1.0
                if iterType(end) == 1.0
                    iterCoarse = iterCoarse - 1.0;
                else
                    iterFine = iterFine - 1.0;
                end
            end
        end
        
        % Make sure final FOS value is within the specified limits
        if fos_i > fosMaxValue
            fos_i = fosMaxValue;
        elseif fos_i < fosMinValue
            fos_i = fosMinValue;
        end
        
        % Update the FOS variable
        if length(tolerance_buffer) > 1.0
            if tolerance_buffer(end - 1.0) < tolerance_buffer(end)
                %{
                    If the last FOS calculation crossed the target life, but the
                    FOS value on the other side of the target life is more
                    accurate, use that value instead
                %}
                fos(totalCounter) = fos_buffer(end - 1.0);
            else
                fos(totalCounter) = fos_i;
            end
        else
            fos(totalCounter) = fos_i;
        end
        
        %% Save the nodal buffers
        nodal_fos_buffer{totalCounter} = fos_buffer;
        nodal_life_buffer{totalCounter} = life_buffer;
        nodal_tolerance_buffer{totalCounter} = tolerance_buffer;
        iterFine_buffer(totalCounter) = iterFine;
        iterCoarse_buffer(totalCounter) = iterCoarse;
    end
end

%% Save the FOS variable
setappdata(0, 'FOS', fos)

% Get the worst value of the FOS
WNFOS = min(fos);

% Get the corresponding item
item = find(fos == WNFOS);

%{
    It is possible that the value of WNFOS will be the same for many
    analysis items, since the FOS value is limited by a lower bound. In the
    event that WNFOS is the same for multiple analysis items, take the FOS
    at the items that had the worst life
%}
if length(item) > 1.0
    livesAtFOSItems = 1.0./nodalDamage_original(item);
    worstLifeAtFOSItem = livesAtFOSItems == min(livesAtFOSItems);
    item = item(worstLifeAtFOSItem);
    
    %{
        If multiple analysis items share the same worst life value, it
        doesn't matter, just take the first value
    %}
    item = item(1.0);
end

if length(WNFOS) > 1.0
    WNFOS = WNFOS(1.0);
end

WNFOS_mainID = mainID(item);
WNFOS_subID = subID(item);

setappdata(0, 'WNFOS', WNFOS)
setappdata(0, 'WNFOS_mainID', WNFOS_mainID)
setappdata(0, 'WNFOS_subID', WNFOS_subID)

% Get the FOS/Life buffers for the worst node FOS item
fos_buffer = nodal_fos_buffer{item};
life_buffer = nodal_life_buffer{item};
tolerance_buffer = nodal_tolerance_buffer{item};

%{
    Determine which group the worst FOS value belongs to, in order to
    record the correct target life for the FOS diagnostics
%}
if fosTarget == 1.0
    % The target life was defined in the job file
    setappdata(0, 'fosTargetLife', targetLife)
else
    % The target life depends on the group material
    for i = 1:G
        IDs = groupIDBuffer(i).IDs;
        
        if isempty(find(IDs == item, 1.0)) == 0.0
            setappdata(0, 'fosTargetLife', targetLife_buffer(i))
            break
        end
    end
end

%% Save FOS diagnostics
if getappdata(0, 'fosDiagnostics') == 1.0
    % Calculate the FOS accuracy from the tolerance value
    tolerance = tolerance_buffer(end);
    if tolerance <= 1.0
        accuracy = sprintf('%.3g%% Accurate', 100.0*(1.0 - tolerance));
    else
        accuracy = sprintf('POOR ACCURACY');
        setappdata(0, 'fosRatio', life_buffer(end)/targetLife)
        messenger.writeMessage(79.0)
    end
    
    % Compare the achieved tolerance to the actual tolerance
    if (tolerance > fosTolerance) || (tolerance < 0.0)
        messenger.writeMessage(80.0)
    end
    
    L = length(fos_buffer);
    
    if getappdata(0, 'outputFigure') == 1.0
        % Create the output directory if it doesn't already exist
        dir = sprintf('Project/output/%s/MATLAB Figures', getappdata(0, 'jobName'));
        if exist(dir, 'dir') == 0.0
            mkdir(dir)
        end
        
        figureFormat = getappdata(0, 'figureFormat');
        
        lineWidth = getappdata(0, 'defaultLineWidth');
        fontX = getappdata(0, 'defaultFontSize_XAxis');
        fontY = getappdata(0, 'defaultFontSize_YAxis');
        fontTitle = getappdata(0, 'defaultFontSize_Title');
        fontTicks = getappdata(0, 'defaultFontSize_Ticks');
        XTickPartition = getappdata(0, 'XTickPartition');
        gridLines = getappdata(0, 'gridLines');
        
        f13 = figure('visible', 'off');
        
        title(sprintf('Item %.0f.%.0f', mainID(item), subID(item)))
        
        subplot(2.0, 1.0, 1.0)
        plot(0:(L - 1.0), fos_buffer, 'o-', 'LineWidth', lineWidth, 'Color', [25/255, 25/255, 112/255])
        
        msg = sprintf('Factor of Strength History (%s)', accuracy);
        title(msg, 'FontSize', fontTitle)
        xlabel('Iteration', 'FontSize', fontX)
        ylabel('FOS', 'FontSize', fontY)
        set(gca, 'FontSize', fontTicks)
        if L > 30.0
            set(gca, 'xtick', linspace(0.0, (L - 1.0), XTickPartition + 1.0))
            set(gca, 'XTickLabel', round(linspace(0.0, (L - 1.0), XTickPartition + 1.0)));
        end
        
        try
            axis tight
        catch
            % Don't tighten the axis
        end
        
        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
            grid on
        end
        
        subplot(2.0, 1.0, 2.0)
        L = length(life_buffer);
        p1 = plot(0:(L - 1.0), life_buffer, 'o-', 'LineWidth', lineWidth, 'Color', [34/255, 139/255, 34/255]);
        
        targetLife = getappdata(0, 'fosTargetLife');
        hold on
        p2 = plot(0:(L - 1.0), linspace(targetLife, targetLife, L), '--', 'lineWidth', lineWidth, 'Color', [178/255, 34/255, 34/255]);
        
        legend([p1, p2], 'Life (Calculated)', 'Life (Target)', 'location', 'SouthEast')
        
        msg = sprintf('Life History');
        title(msg, 'FontSize', fontTitle)
        xlabel('Iteration', 'FontSize', fontX)
        ylabel('Life', 'FontSize', fontY)
        set(gca, 'FontSize', fontTicks)
        if L > 30.0
            set(gca, 'xtick', linspace(0.0, (L - 1.0), XTickPartition + 1.0))
            set(gca, 'XTickLabel', round(linspace(0.0, (L - 1.0), XTickPartition + 1.0)));
        end
        
        try
            axis tight
        catch
            % Don't tighten the axis
        end
        
        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
            grid on
        end
        
        % Main title
        axes('Position', [0.0, 0.0, 1.0, 1.0], 'Xlim', [0.0, 1.0], 'Ylim',[0.0, 1.0], 'Box',...
            'off', 'Visible', 'off', 'Units', 'normalized', 'clipping' , 'off');
        
        text(0.5, 1.0, sprintf('FOS, Factor of Strength Diagnositcs at item %.0f.%.0f',...
            mainID(item), subID(item)), 'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'top', 'FontSize', fontTitle)
        
        dir = [getappdata(0, 'outputDirectory'), 'MATLAB Figures/FOS, Factor of strength diagnostics'];
        saveas(f13, dir, figureFormat)
        if strcmpi(figureFormat, 'fig') == true
            postProcess.makeVisible([dir, '.fig'])
        end
    end
    
    % Save diagnostic variables so that they can be printed to the log file
    setappdata(0, 'fos_diagnostics_fos_buffer', fos_buffer)
    setappdata(0, 'fos_diagnostics_life_buffer', life_buffer)
    setappdata(0, 'fos_diagnostics_iterations', 0:(L - 1.0))
    setappdata(0, 'fos_diagnostics_accuracy', accuracy)
    setappdata(0, 'fos_diagnostics_mainID', mainID(item))
    setappdata(0, 'fos_diagnostics_subID', subID(item))
    setappdata(0, 'fos_diagnostics_fineIters', iterFine_buffer(item))
    setappdata(0, 'fos_diagnostics_coarseIters', iterCoarse_buffer(item))
    setappdata(0, 'fos_diagnostics_tolerance_buffer', tolerance_buffer)
    
    % Print FOS accuracy to a text file
    nodal_tolerance = zeros(1.0, Nt);
    for i = 1:Nt
        nodal_tolerances = nodal_tolerance_buffer{i};
        nodal_tolerance(i) = nodal_tolerances(end);
    end
    nodalAccuracy = 100.*(1.0 - nodal_tolerance);
    nodalAccuracy(nodalAccuracy < 0.0) = 0.0;
    nodalAccuracy(nodalAccuracy > 100.0) = 100.0;
    
    data = [mainID'; subID'; nodalAccuracy]';
    
    % Print information to file
    root = getappdata(0, 'outputDirectory');
    
    if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
        mkdir(sprintf('%s/Data Files', root))
    end
    
    dir = [root, 'Data Files/fos_accuracy.dat'];
    
    fid = fopen(dir, 'w+');
    
    fprintf(fid, 'FOS_ACCURACY\r\n');
    fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
    
    fprintf(fid, 'Main ID\tSub ID\tAccuracy (%%)\r\n');
    fprintf(fid, '%.0f\t%.0f\t%f\r\n', data');
    
    fclose(fid);
    
    % Tell the user that FOS accuracy has been exported
    messenger.writeMessage(215.0)
end

% Print FOS footer to status file
fprintf(fid_status, '\n[POST] End FOS analysis');
end
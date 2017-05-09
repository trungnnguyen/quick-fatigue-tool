function [] = virtualStrainGauge(xx_o, yy_o, xy_o, zz, xz, yz)
%VIRTUALSTRAINGAUGE    QFT function for virtual strain gauges.
%    This function contains code for the calculation of virtual strain
%    gauge data.
%
%    VIRTUALSTRAINGAUGE is used internally by Quick Fatigue Tool. The user
%    is not required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      4.9 Virtual strain gauges
%    
%    Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%    Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%% GET THE GAUGE LOCATION
vGaugeLoc = getappdata(0, 'vGaugeLoc');
vGaugeOri = getappdata(0, 'vGaugeOri');

%% GET THE IDS
mainID = getappdata(0, 'mainID_master');
subID = getappdata(0, 'subID_master');

%% CHECK IF VIRTUAL STRAIN GAUGES HAVE BEEN DEFINED
if ischar(vGaugeLoc) == 1.0
    messenger.writeMessage(230.0)
    return
elseif iscell(vGaugeLoc) == 0.0
    messenger.writeMessage(230.0)
    return
end

if isempty(vGaugeLoc) == 1.0
    return
else
    % One or more gauges have been defined
    if isempty(vGaugeOri) == 1.0
        % A gauge location was defined, but there is no orientation
        messenger.writeMessage(222.0)
        return
    end
    
    if iscell(vGaugeOri) == 0.0
        % Convert the orientation definition to a cell if necessary
        vGaugeOri = num2cell(vGaugeOri, 2.0);
    end
    
    if length(vGaugeOri) ~= length(vGaugeLoc)
        % The number of orienatations and locations does not match
        messenger.writeMessage(223.0)
        return
    end
end

N = length(vGaugeLoc);

% Gauges to ignore
badGauges = zeros(1.0, N);

%% PROCESS THE ORIENTATIONS
for gaugeNumber = 1:N
    setappdata(0, 'vGaugeNumber', gaugeNumber)
    
    if ischar(vGaugeOri{gaugeNumber}) == 1.0
        % If orientation is CHAR, check the definition
        if strcmpi(vGaugeOri{gaugeNumber}, 'RECTANGULAR') == 1.0
            vGaugeOri{gaugeNumber} = [0.0, 45.0, 45.0];
        elseif strcmpi(vGaugeOri{gaugeNumber}, 'DELTA') == 1.0
            vGaugeOri{gaugeNumber} = [30.0, 60.0, 60.0];
        else
            setappdata(0, 'vGaugeOri', vGaugeOri{gaugeNumber})
            messenger.writeMessage(249.0)
            
            badGauges(gaugeNumber) = 1.0;
        end
    else
        % If orientation is NUM, check the definition
        orientation = vGaugeOri{gaugeNumber};
        if length(orientation) ~= 3.0
            setappdata(0, 'vGaugeNOri', length(orientation))
            messenger.writeMessage(250.0)
            
            badGauges(gaugeNumber) = 1.0;
        else
            alpha = orientation(1.0);
            beta = orientation(2.0);
            gamma = orientation(3.0);
            
            if (isnumeric(alpha) == 0.0) || (isinf(alpha) == 1.0) || (isnan(alpha) == 1.0)
                setappdata(0, 'vGaugeOriName', 'ALPHA')
                messenger.writeMessage(251.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
            if (isnumeric(beta) == 0.0) || (isinf(beta) == 1.0) || (isnan(beta) == 1.0)
                setappdata(0, 'vGaugeOriName', 'BETA')
                messenger.writeMessage(251.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
            if (isnumeric(gamma) == 0.0) || (isinf(gamma) == 1.0) || (isnan(gamma) == 1.0)
                setappdata(0, 'vGaugeOriName', 'GAMMA')
                messenger.writeMessage(251.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
            
            if (alpha < 0.0) || (alpha >= 180.0)
                setappdata(0, 'vGaugeOriSymbol', '<=')
                setappdata(0, 'vGaugeOriName', 'ALPHA')
                setappdata(0, 'vGaugeValue', alpha)
                messenger.writeMessage(252.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
            if (beta <= 0.0) || (beta >= 180.0)
                setappdata(0, 'vGaugeOriSymbol', '<')
                setappdata(0, 'vGaugeOriName', 'BETA')
                setappdata(0, 'vGaugeValue', beta)
                messenger.writeMessage(252.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
            if (gamma <= 0.0) || (gamma >= 180.0)
                setappdata(0, 'vGaugeOriSymbol', '<')
                setappdata(0, 'vGaugeOriName', 'GAMMA')
                setappdata(0, 'vGaugeValue', gamma)
                messenger.writeMessage(252.0)
                
                badGauges(gaugeNumber) = 1.0;
            end
        end
    end
    if badGauges(gaugeNumber) == 1.0
        messenger.writeMessage(253.0)
    end
end

%% INITIALIZE VARIABLES
groupIDBuffer = getappdata(0, 'groupIDBuffer');
Gr = getappdata(0, 'numberOfGroups');
jobName = getappdata(0, 'jobName');
loadEqVal = getappdata(0, 'loadEqVal');
loadEqUnits = getappdata(0, 'loadEqUnits');

root = getappdata(0, 'outputDirectory');
if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
    mkdir(sprintf('%s/Data Files', root))
end

for gaugeNumber = 1:N
    %% IGNORE GAUGE IF DEFINED BADLY
    if badGauges(gaugeNumber) == 1.0
        continue
    end
    
    %% SAVE THE CURRENT GAUGE NUMBER
    setappdata(0, 'vGaugeNumber', gaugeNumber)
    
    %% GET THE ITEM FOR THE CURRENT GAUGE
    currentGaugeLoc = vGaugeLoc{gaugeNumber};
    
    if isempty(find(currentGaugeLoc == '.', 1.0)) == 1.0
        messenger.writeMessage(232.0)
        continue
    elseif length(find(currentGaugeLoc == '.')) > 1.0
        messenger.writeMessage(233.0)
        continue
    end
    
    mainID_g = strtok(currentGaugeLoc, '.');
    subID_g = str2double(currentGaugeLoc(length(mainID_g) + 2.0:end));
    mainID_g = str2double(mainID_g);
    
    setappdata(0, 'vGaugeMainID', mainID_g)
    setappdata(0, 'vGaugeSubID', subID_g)
    
    if isnan(mainID_g) == 1.0 || isnan(subID_g) == 1.0
        messenger.writeMessage(228.0)
        continue
    end
    
    % Get the item number from the Main ID list
    mainIDs = find(mainID == mainID_g);
    subIDs = find(subID == subID_g);
    currentLocation = intersect(mainIDs, subIDs);
    if isempty(currentLocation) == 1.0
        messenger.writeMessage(224.0)
        continue
    elseif length(currentLocation) > 1.0
        messenger.writeMessage(229.0)
        currentLocation = currentLocation(1.0);
    end
    
    gaugeGroup = 0.0;
    for groups = 1:Gr
        groupIDs = groupIDBuffer(groups).IDs;
        
        if isempty(intersect(groupIDs, currentLocation)) == 0.0
            % The gauge belongs to this group
            gaugeGroup = groups;
            break
        end
    end
    
    %% GET THE STRESSES AT THE CURRENT GAUGE
    xx = xx_o(currentLocation, :);
    yy = yy_o(currentLocation, :);
    xy = xy_o(currentLocation, :);
    
    % CHECK FOR OUT-OF-PLANE STRESS COMPONENTS
    if any(zz(currentLocation, :)) == 1.0 || any(xz(currentLocation, :)) == 1.0 || any(yz(currentLocation, :)) == 1.0
        messenger.writeMessage(231.0)
    end
    
    %% GET THE GAUGE ORIENTATION
    orientations = vGaugeOri{gaugeNumber};
    alpha = orientations(1.0);
    beta = orientations(2.0);
    gamma = orientations(3.0);
    
    %% GET THE MATERIAL PROPERTIES
    [~, ~] = group.switchProperties(gaugeGroup, groupIDBuffer(gaugeGroup));
    
    % Get the shear modulus
    E = getappdata(0, 'E');
    v = getappdata(0, 'poisson');
    kp = getappdata(0, 'kp');
    np = getappdata(0, 'np');
    G = E/(2.0*(1.0 - v));
    
    if (isempty(E) == 1.0) || (isempty(v) == 1.0)
        % The Young's Modulus and/or the Poisson's ratio is not defined for the current gauge
        setappdata(0, 'vGauge_E', E)
        setappdata(0, 'vGauge_v', v)
        messenger.writeMessage(225.0)
        continue
    end
    
    %% CORRECT THE HISTORIES FOR PLASTICITY
    if (isempty(kp) == 1.0) || (isempty(np) == 1.0)
        % The cyclic strain hardening coefficient/exponent is not defined for the current gauge
        setappdata(0, 'vGauge_kp', kp)
        setappdata(0, 'vGauge_np', np)
        messenger.writeMessage(227.0)
        
        % Convert the stress histories to strain histories elastically
        xx = xx./E;
        yy = yy./E;
        xy = xy./G;
    else
        [xx_temp, ~, ~] = css2(xx, E, kp, np);
        [yy_temp, ~, ~] = css2(yy, E, kp, np);
        [xy_temp, ~, ~] = css2(xy, E, kp, np);
        
        if length(xx_temp) ~= length(xx)
            diff = abs(length(xx_temp) - length(xx));
            if length(xx_temp) > length(xx)
                xx_temp(1:diff) = [];
                xx = xx_temp;
            end
        end
        
        if length(yy_temp) ~= length(yy)
            diff = abs(length(yy_temp) - length(yy));
            if length(yy_temp) > length(yy)
                yy_temp(1:diff) = [];
                yy = yy_temp;
            end
        end
        
        if length(xy_temp) ~= length(xy)
            diff = abs(length(xy_temp) - length(xy));
            if length(xy_temp) > length(xy)
                xy_temp(1:diff) = [];
                xy = xy_temp;
            end
        end
    end
    
    %% GET THE GAUGE HISTORIES
    A = 0.5*(xx + yy) + 0.5*(xx - yy)*cosd(2.0*alpha) + xy*sind(2.0*alpha);
    B = 0.5*(xx + yy) + 0.5*(xx - yy)*cosd(2.0*(alpha + beta)) + xy*sind(2.0*(alpha + beta));
    C = 0.5*(xx + yy) + 0.5*(xx - yy)*cosd(2.0*(alpha + beta + gamma)) + xy*sind(2.0*(alpha + beta + gamma));
    
    data = [A; B; C]';
    
    %% WRITE THE GAUGE DATA TO A TEXT FILE
    dir = [root, sprintf('Data Files/virtual_strain_gauge_#%.0f.dat', gaugeNumber)];
    
    fid = fopen(dir, 'w+');
    
    fprintf(fid, 'VIRTUAL STRAIN GAUGE #%.0f (ITEM %.0f.%.0f)\r\n', gaugeNumber, mainID_g, subID_g);
    fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\nUnits:\tStrain\r\n', jobName, loadEqVal, loadEqUnits);
    
    fprintf(fid, 'Gauge A (%.3g Degrees)\tGauge B (%.3g Degrees)\tGauge C (%.3g Degrees)\r\n', alpha, (alpha + beta), (alpha + beta + gamma));
    fprintf(fid, '%f\t%f\t%f\r\n', data');
    
    fprintf(fid, '\r\nGauge orientations are measured counterclockwise from the positive global (Cartesian) x-direction\r\n');
    fclose(fid);
    
    %% INFORM THE USER THAT GAUGE DATA HAS BEEN WRITTEN TO FILE
    messenger.writeMessage(248.0)
end
end
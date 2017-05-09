function [trueStrain, trueStress, signal2] = css(signal, E, K, n)
%CSS Iteratively solves the Ramberg-Osgood model for elastic stress and
%strain data.
%   [TRUESTRAIN, TRUESTRESS, SIGNAL2] = CSS(SIGNAL) returns 1xN vectors
%   containing the nonlinear elsatic stress and strain from a 1xN vector of
%   elastic stress or strain, SIGNAL.
%
%   SIGNAL is a 1xN vector containing a time history of stresses or
%   strains.
%
%   VARARGIN is a flag telling CSS whether the data has stress or strain
%   units. By default, the data is assumed to be in strain units (%E). In
%   such cases, no assignment is required for VARARGIN. To specify stress
%   units, assign a value of 1.0 to VARARGIN, or the string value 'stress'
%   or simply 's'. Units of stress are in MPa.
%
%   TRUESTRAIN is a 1xN vector containing the true strain values which lie
%   on the cyclic hystresis curve.
%
%   TRUESTRESS is a 1xN vector containing the true stress values which lie
%   on the cyclic hysteresis curve.
%
%   SIGNAL2 is a 1xN vector containing a modified version of SIGNAL in
%   which the starting point is moved to the location of the absolute
%   maximum value in the history.
%
%   Running CSS prompts the user to specify the three material properties
%   which define the cyclic behaviour of a metallic specimen. Default
%   properties for SAE 950C Manten steel are provided. Units of Young's
%   Modulus are MPa.
%
%   CSS uses Neuber's Rule to correct for plasticity.
%
%   CSS assumes the material memory behaviour, whereby upon closure of a
%   hysteresis loop, the material response reverts to the previous history
%   point.

%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 24-Jul-2015 10:43:07 GMT

%% Convert to strain units:
signal = signal/E;

%% Re-arrange signal so max is at the start:
if abs(signal(1)) ~= max(abs(signal))
    L = length(signal);
    signal2 = zeros(1, L);
    
    maxA = max(signal);
    maxB = abs(min(signal));
    if maxA > maxB
        indexOfMaximum = find(signal == maxA);
    else
        indexOfMaximum = find(signal == min(signal));
    end

    if length(indexOfMaximum) > 1
        indexOfMaximum = indexOfMaximum(1);
    end
    
    rightHandElements = L - indexOfMaximum;
    
    if rightHandElements == 0
        signal2(1) = signal(end);
        signal2(2:end) = signal(1:end-1);
    else
        signal2(1) = signal(indexOfMaximum);
        signal2(2:rightHandElements+1) = signal(indexOfMaximum+1:end);
        signal2(rightHandElements+2:end) = signal(1:indexOfMaximum-1);
    end
else
    L = length(signal);
    signal2 = signal;
end

if signal2(1) ~= 0
    signal2 = [0 signal2];
    L = L + 1;
end

if length(signal2) == 1.0
    signal2 = [0 signal2];
end

%% Material properties:
Ee = signal2(2);

x0 = abs(Ee); % first guess

trueStrain = zeros(1, L);
trueStrainRange = 0;
elasticStrainRange = 0;

%% Monotonic stage:
% Initial estimate of monotnic excursion
f = (Ee^2/x0) + ((E*Ee^2)/(x0*K))^(1/n) - x0;

num = E*Ee^2*((E*Ee^2)/(x0*K))^(-1 + (1/n));
den = K*n*x0^2;
df = -1 - (Ee/x0)^2 - (num/den);

x1 = x0 - f/df; % initial estimate

N = 0.0;
tol = getappdata(0, 'cssTolerance');
maxIters = getappdata(0, 'cssMaxIterations');

% iterate to determine monotonic excursion
while (f > tol) && (N < maxIters)
    x0 = x1;
    
    f = (Ee^2/x0) + ((E*Ee^2)/(x0*K))^(1/n) - x0;
    
    num = E*Ee^2*((E*Ee^2)/(x0*K))^(-1 + (1/n));
    den = K*n*x0^2;
    df = -1 - (Ee/x0)^2 - (num/den);
    
    x1 = x0 - f/df;
    N = N + 1;
end

trueStrain(1) = 0; % the first strain in the history is always zero
if Ee < 0
    trueStrain(2) = -x1; % if the first elastic strain is negative
else
    trueStrain(2) = x1; % if the first elastic strain is positive
end

%% Equivalent stress from first strain:
trueStress = zeros(1, L); % initial buffer for the true stress history

Ep = abs(trueStrain(2)); % the first true strain value

% first guess is the elastic stress from the true strain (more likely to
% converge?)
x0 = Ep*E;

f = (x0/E) + (x0/K)^(1/n) - Ep;

num = (x0/K)^((1-n)/n);
den = K*n;
df = (num/den) + (1/E);

x1 = x0 - f/df; % initial estimate

N = 0;

% iterate to determine monotonic excursion
while (f > tol) && (N < maxIters)
    x0 = x1;
    
    f = (x0/E) + (x0/K)^(1/n) - Ep;
    
    num = (x0/K)^((1-n)/n);
    den = K*n;
    df = (num/den) + (1/E);
    
    x1 = x0 - f/df;
    N = N + 1;
end

trueStress(1) = 0; % first true stress in the history is always zero
if trueStrain(2) < 0
    trueStress(2) = -x1; % if the first elastic strain is negative
else
    trueStress(2) = x1; % if the first elastic strain is positive
end

%% cyclic stage:

% this variable determines how many points to look back in case the next
% strain is in the same direction (no reversal). This never applies to the
% first cyclic strain hence the initial value is zero
numStepsBack = 0;

for i = 3:length(signal2)
    dEe = abs(signal2(i-1) - signal2(i)); % elastic strain range from elastic history
    % if the elastic strain range is zero (identical adjacent strain
    % history pair) then continue to next point in the history
    if dEe == 0
        trueStrain(i) = trueStrain(i-1);
        trueStress(i) = trueStress(i-1);
        trueStrainRange = 0.0;
        elasticStrainRange = 0.0;
        continue
    end
    
    % if next excursion is in the same direction, look at the beginning of
    % the cyclic curve as reference. The number of steps required to look
    % back is numStepsBack
    
    % make sure code doesn't falsely identify an increased strain range as a closed loop
    ignoreClosure = 0;
    % this can only happen after at least two previous excursions
    if (i > 3) && ((signal2(i-1) < signal2(i-2) && signal2(i) < signal2(i-1))...
            || (signal2(i-1) > signal2(i-2) && signal2(i) > signal2(i-1)))
        % otherwise calculate the true strain range normally
        
        if numStepsBack == 0 % this is the first instance of a non-reversal event
            numStepsBack = 1;
        else % this is a consecutive instance of a non-reversal event
            numStepsBack = numStepsBack + 1;
        end
        
        ignoreClosure = 1;
        
        dEe = abs((signal2(i)-signal2(i-1))) + sum(abs(trueStrainRange(end-(numStepsBack-1):end))); % sum of previous range and next strain
        x0 = dEe; % first guess
        
        f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
        
        num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
        den = K*n*x0^2;
        df = -1 - (dEe/x0)^2 - (num/den);
        
        x1 = x0 - f/df; % initial estimate
        
        N = 0;
        
        % iterate to determine cyclic excursion
        while (f > tol) && (N < maxIters)
            x0 = x1;
            
            f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
            
            num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
            den = K*n*x0^2;
            df = -1 - (dEe/x0)^2 - (num/den);
            
            x1 = x0 - f/df; % true strain range
            N = N + 1;
        end
    else % otherwise calculate the true strain range normally
        numStepsBack = 0;
        
        x0 = dEe; % first guess
        
        f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
        
        num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
        den = K*n*x0^2;
        df = -1 - (dEe/x0)^2 - (num/den);
        
        x1 = x0 - f/df; % initial estimate
        
        N = 0;
        while (f > tol) && (N < maxIters)
            x0 = x1;
            
            f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
            
            num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
            den = K*n*x0^2;
            df = -1 - (dEe/x0)^2 - (num/den);
            
            x1 = x0 - f/df; % true strain range
            N = N + 1;
        end
    end
    
    % record strain range in buffer
    if i == 3
        trueStrainRange = x1;
        elasticStrainRange = dEe;
    elseif ignoreClosure == 1
        trueStrainRange = [trueStrainRange (x1 - abs(sum(trueStrainRange(end-(numStepsBack-1):end))))]; %#ok<*AGROW>
        elasticStrainRange =  [elasticStrainRange dEe];
        x1 = trueStrainRange(end);
        
        % record true strain in buffer
        if signal2(i) < signal2(i-1)
            trueStrain(i) = trueStrain(i-1-numStepsBack) - x1;
        else
            trueStrain(i) = trueStrain(i-1-numStepsBack) + x1;
        end
        
        % re-define true strain range to exclude previous curve
        trueStrainRange(end) = abs(trueStrain(i) - trueStrain(i-1));
    else
        trueStrainRange = [trueStrainRange x1];
        elasticStrainRange = [elasticStrainRange dEe];
        x1 = trueStrainRange(end);
    end
    
    % check if a hysteresis loop is closed
    if (i > 4) && (trueStrainRange(end) > trueStrainRange(end-1))...
            && (ignoreClosure == 0) && length(elasticStrainRange) > 2.0
        trueStrainRange(end-1) = [];
        % then re-calculate the strain
        extraElasticStrainRange = dEe - elasticStrainRange(end-1);

        dEe = elasticStrainRange(end-2) + extraElasticStrainRange;
        
        x0 = dEe; % first guess
        
        f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
        
        num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
        den = K*n*x0^2;
        df = -1 - (dEe/x0)^2 - (num/den);
        
        x1 = x0 - f/df; % initial estimate
        
        N = 0;
        while (f > tol) && (N < maxIters)
            x0 = x1;
            
            f = (dEe^2/x0) + 2*((E*dEe^2)/(2*K*x0))^(1/n) - x0;
            
            num = (2^((n-1)/n))*dEe^2*E*((dEe^2*E)/(K*x0))^((1-n)/n);
            den = K*n*x0^2;
            df = -1 - (dEe/x0)^2 - (num/den);
            
            x1 = x0 - f/df; % true strain range
            N = N + 1;
        end
        
        % add the true strain value to the history
        if signal2(i) < signal2(i-1)
            trueStrain(i) = trueStrain(i-3) - x1;
        else
            trueStrain(i) = trueStrain(i-3) + x1;
        end
    elseif ignoreClosure == 0
        if signal2(i) < signal2(i-1)
            trueStrain(i) = trueStrain(i-1) - x1;
        else
            trueStrain(i) = trueStrain(i-1) + x1;
        end     
    end
    
    
    %% equivalent stress from remaining strains:
    if ignoreClosure == 0
        dE = trueStrainRange(end); % previously calculated true strain range
    else
        dE = sum(trueStrainRange((end-numStepsBack):end));
    end

    x0 = E*dEe; % first guess is elastic stress range from elastic strain
    
    f = (x0/E) + 2*(x0/(2*K))^(1/n) - dE;
    
    num = (2^((n-1)/n))*(x0/K)^((1-n)/n);
    den = K*n;
    df = (num/den) + (1/E);
    
    x1 = x0 - f/df; % initial estimate
    
    N = 0;
    while (f > tol) && (N < maxIters)
        x0 = x1;
        
        f = (x0/E) + 2*(x0/(2*K))^(1/n) - dE;
        
        num = (2^((n-1)/n))*(x0/K)^((1-n)/n);
        den = K*n;
        df = (num/den) + (1/E);
        
        x1 = x0 - f/df; % true strain range
        N = N + 1;
    end
    
    if length(trueStrainRange) > 1.0
        if i > 4 && (trueStrainRange(end) > trueStrainRange(end-1))
            if trueStrain(i) < trueStrain(i-1)
                trueStress(i) = trueStress(i-3) - x1;
            else
                trueStress(i) = trueStress(i-3) + x1;
            end
        elseif ignoreClosure == 0
            if trueStrain(i) < trueStrain(i-1)
                trueStress(i) = trueStress(i-1) - x1;
            else
                trueStress(i) = trueStress(i-1) + x1;
            end
        else
            if trueStrain(i) < trueStrain(i-1)
                trueStress(i) = trueStress(i-(numStepsBack+1)) - x1;
            else
                trueStress(i) = trueStress(i-(numStepsBack+1)) + x1;
            end
        end
    else
        if trueStrain(i) < trueStrain(i-1)
            trueStress(i) = trueStress(i-(numStepsBack+1)) - x1;
        else
            trueStress(i) = trueStress(i-(numStepsBack+1)) + x1;
        end
    end
end
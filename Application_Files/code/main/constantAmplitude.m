function [Sxx, Syy, Szz, Txy, Txz, Tyz] = constantAmplitude(Sxx, Syy, Szz, Txy, Txz, Tyz, repeats, historyGate)
%CONSTANTAMPLITUDE    QFT function to check for constant amplitude loading.
%   This function checks if a load history is constant amplitude.
%   
%   CONSTANTAMPLITUDE is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
gate = historyGate(1.0)/100;
originalLength = length(Sxx);

%{
	If the load history is constant amplitude, reduce the
	history to a single cycle and update the number of repeats
%}
uniques = Sxx(1.0);
if ismember(Sxx(2.0), uniques) == 0.0
    uniques = [uniques, Sxx(2.0)];
end

for i = 3:length(Sxx)
    ratio = abs(Sxx(i)/Sxx(i - 2.0));
    if ratio > 1.0
        ratio = ratio - 1.0;
    elseif ratio < 1.0
        ratio = 1.0 - ratio;
    else
        ratio = 0.0;
    end
    
    if ratio > gate
        uniques = [uniques, Sxx(i)]; %#ok<AGROW>
    end
end

if length(uniques) < 3.0
    % Constant amplitude loading detected
    Sxx = Sxx(1.0:2.0);
    Syy = Syy(1.0:2.0);
    Szz = Szz(1.0:2.0);
    Txy = Txy(1.0:2.0);
    Txz = Txz(1.0:2.0);
    Tyz = Tyz(1.0:2.0);
    extraRepeats = floor(originalLength/length(Sxx));
    repeats = repeats*extraRepeats;
    
    setappdata(0, 'repeats', repeats)
    messenger.writeMessage(226.0)
end
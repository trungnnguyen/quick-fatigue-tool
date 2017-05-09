function [] = getRMinus1Curve(useSN, msCorrection, nSets, G)
%GETRMINUS1CURVE    QFT function to calculate fully-reversed S-N curve.
%   This function calculates the equivalent S-N curve for a fully-reversed
%   load (R=-1).
%   
%   GETRMINUS1CURVE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%{
    If the user provided multiple S-N curves for different R-ratios and
    requested S-N data for fatigue analysis, but did not request R-ratio
    S-N curves mean stress correction, the S-N curve for R = -1.0 must be
    found
%}
% Get the group material properties
group_materialProps = getappdata(0, 'group_materialProps');

for groups = 1:G
    % Get the material properties for the current group
    
    
    if (useSN == 1.0) && (nSets > 1.0)
        preProcess.snInterpolate(msCorrection)
    end
    
    % If there is only one S-N curve, scale it by Kt now
    if nSets == 1.0
        S = group_materialProps(groups).sValues;
        Ni = group_materialProps(groups).nValues;
        kt = group_materialProps(groups).Kt;
        constant = group_materialProps(groups).notchSensitivityConstant;
        radius = group_materialProps(groups).notchRootRadius;
        
        if kt ~= 1.0
            ktn = zeros(1.0, length(S));
            for ktIndex = 1:length(S)
                ktn(ktIndex) = analysis.getKtn(Ni(ktIndex), constant, radius);
            end
            
            group_materialProps(groups).sValues = S.*(1.0./ktn);
            
            % Save the material properties for the current group
            setappdata(0, 'group_materialProps', group_materialProps)
        end
    end
end
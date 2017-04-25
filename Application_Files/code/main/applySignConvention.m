function [signal] = applySignConvention(signal, signConvention, S1, S2, S3, Sxx, Syy, Txy)
%APPLYSIGNCONVENTION    QFT function to apply sign convention.
%   This function applies a user-specified sign convention to a load
%   history.
%   
%   APPLYSIGNCONVENTION is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
switch signConvention
    case 1.0
        % Sign from hydrostatic stress
        sign_value = sign((1.0/3.0)*(S1 + S2 + S3));
    case 2.0
        % Sign from maximum stress
        sign_value = sign(S1);
    case 3.0
        % Sign from Mohr circle space
        sign_value = sign(atand(Txy./(Sxx - Syy)));
end
sign_value(sign_value == 0.0) = 1.0;
sign_value(isnan(sign_value)) = 1.0;
signal = signal.*sign_value;
end
function [fos_i, iterFine, iterCoarse, iterType] =...
    fosUpdate(targetLife, life_buffer, iterType, fosFineIncrement,...
    fosCoarseIncrement, life_i, fosMaxFine, fosMinFine, fos_i, iterFine,...
    iterCoarse, fosAugment, fosAugmentThreshold, fosAugmentFactor)
%FOSUPDATE    QFT function to update current FOS estimate.
%   This function updates the current FOS estimate based on the current
%   loading.
%   
%   FOSUPDATE is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%{
    This code compares the current FOS iteration to the previous FOS
    iteration. If it looks unlikely that the FOS calulation will converge
    within the next few increments, augment the next increment. If the next
    increment falls within the convergence tolerance, the calculaiton is
    terminated. Otherwise, the code reverts back to the original
    incrementation scheme.

    This function is called iteratively after each FOS incrementation.
%}
if fosAugment > 0.0
    % Get the current and previous life values
    currentLife = life_buffer(end);
    previousLife = life_buffer(end - 1.0);
    
    % Get the difference between the current life and the previous life
    deltaLife = abs(currentLife - previousLife);
    
    % Get the difference between the previous life and the target life
    deltaTarget = abs(targetLife - previousLife);
    
    %{
        Get the ratio between the last two lives, and the previous life
        with the target life
    %}
    ratioBetweenLives = deltaLife/deltaTarget;
    
    %{
        If the life ratio is less than the specified tolerance, perform an
        augmented iteration
    %}
    if ratioBetweenLives < fosAugmentThreshold
        augmentedPrevious = 1.0; %#ok<NASGU>
        
        if iterType == 1.0
            fosCoarseIncrement = fosCoarseIncrement*fosAugmentFactor;
        else
            fosFineIncrement = fosFineIncrement*fosAugmentFactor;
        end
    end
end

% Update the FOS value
if life_i < targetLife
    if (fos_i <= fosMaxFine) && (fos_i >= fosMinFine)
        fos_i = fos_i - fosFineIncrement;
        iterFine = iterFine + 1.0;
        iterType = [iterType, 2.0];
    else
        fos_i = fos_i - fosCoarseIncrement;
        iterCoarse = iterCoarse + 1.0;
        iterType = [iterType, 1.0];
    end
elseif life_i > targetLife
    if (fos_i <= fosMaxFine) && (fos_i >= fosMinFine)
        fos_i = fos_i + fosFineIncrement;
        iterFine = iterFine + 1.0;
        iterType = [iterType, 2.0];
    else
        fos_i = fos_i + fosCoarseIncrement;
        iterCoarse = iterCoarse + 1.0;
        iterType = [iterType, 1.0];
    end
end
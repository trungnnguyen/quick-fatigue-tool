function [previousN, groupAlpha] = getAlpha(mainID, subID, stressInvParam,...
    previousN, groupAlpha, s1, s2, s3, groups, algorithm, N, totalCounter,...
    groupIDs, groupIDBuffer)
%GETALPHA    QFT function to calculate biaxiality ratio.
%   This function calculates the biaxiality ratio for the Stress Invariant
%   Parameter fatigue analysis algorithm.
%   
%   GETALPHA is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
%% Get the maximum stress range in the loading
%{
	Get the maximum (and minimum) principal stresses in the current group,
    and record the position
%}
% Get the principal stresses for the current group
maxS1 = max(s1((totalCounter - (N - 1.0)):totalCounter, :), [], 2.0);
maxS2 = max(s2((totalCounter - (N - 1.0)):totalCounter, :), [], 2.0);
minS3 = min(s3((totalCounter - (N - 1.0)):totalCounter, :), [], 2.0);

if (isempty(maxS1) == 1.0) || (isempty(maxS2) == 1.0) || (isempty(minS3) == 1.0)
    groupAlpha{groups} = [0.0, 0.0];
    return
end

% Get the position IDs for the maximum principal stress
maxS1Index = maxS1 == max(maxS1);
maxS1Index = find(maxS1Index == 1.0, 1.0);

maxS1MainID = mainID(groupIDs(maxS1Index));
maxS1SubID = subID(groupIDs(maxS1Index));

maxS1MainID = maxS1MainID(1.0);
maxS1SubID = maxS1SubID(1.0);

% Get the position IDs for the middle principal stress
maxS2Index = maxS2 == max(maxS2);
maxS2Index = find(maxS2Index == 1.0, 1.0);

maxS2MainID = mainID(groupIDs(maxS2Index));
maxS2SubID = subID(groupIDs(maxS2Index));

maxS2MainID = maxS2MainID(1.0);
maxS2SubID = maxS2SubID(1.0);

% Get the position IDs for the minimum principal stress
minS3Index = minS3 == min(minS3);
minS3Index = find(minS3Index == 1.0, 1.0);

minS3MainID = mainID(groupIDs(minS3Index));
minS3SubID = subID(groupIDs(minS3Index));

minS3MainID = minS3MainID(1.0);
minS3SubID = minS3SubID(1.0);

setappdata(0, 'message_206_maxStress', max(maxS1))
setappdata(0, 'message_206_minStress', min(minS3))

setappdata(0, 'message_206_maxStressID', sprintf('%.0f.%.0f', maxS1MainID, maxS1SubID))
setappdata(0, 'message_206_minStressID', sprintf('%.0f.%.0f', minS3MainID, minS3SubID))

setappdata(0, 'message_206_groupNumber', groups)
setappdata(0, 'message_206_groupName', groupIDBuffer(groups).name)

messenger.writeMessage(206.0)

%% Get alpha
if algorithm == 7.0
    %{
    	Advance the group indexes so that the alpha calculation is
        performed on the correct group of prinicpal stress values
    %}
    maxS1Index = maxS1Index + previousN;
    maxS2Index = maxS2Index + previousN;
    
    %{
    	Get the biaxiality ratio in the current group, and record the position
    %}
    if abs(min(maxS2)) > abs(max(maxS1))
        alphaMainID = maxS2Index;
        setappdata(0, 'message_207_alphaID', sprintf('%.0f.%.0f', maxS2MainID, maxS2SubID))
    else
        alphaMainID = maxS1Index;
        setappdata(0, 'message_207_alphaID', sprintf('%.0f.%.0f', maxS1MainID, maxS1SubID))
    end
    
    alpha = s2(alphaMainID, :)./s1(alphaMainID, :);
    
    % Change INF values (uniaxial 2-direction) to 0.0
    alpha(isinf(alpha)) = 0.0;
    
    % Change NAN values (zero stress) to 0.0
    alpha(isnan(alpha)) = 0.0;
    
    setappdata(0, 'message_207_alphaMin', min(alpha))
    setappdata(0, 'message_207_alphaMax', max(alpha))
    
    messenger.writeMessage(207.0)
    
    if stressInvParam == 0.0
        groupAlpha{groups} = [min(alpha), max(alpha)];
    end
end
previousN = previousN + N;
end
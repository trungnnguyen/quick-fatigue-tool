function [] = fetchMaterial(material)
%FETCHMATERIAL    QFT function to import material text file.
%   This function imports a material text file into the local material
%   database.
%   
%   FETCHMATERIAL(MATERIAL) imports material data from a text file
%   'MATERIAL.*' containing valid material definitioins. The file must
%   begin and end with the keywords *USER MATERIAL and *END MATERIAL,
%   respectively.
%
%   Example material text file:
%       *USER MATERIAL, steel
%       *MECHANICAL
%       200e3, , 400, ,
%       *FATIGUE, constants
%       930, -0.095, , ,
%       *REGRESSION, none
%       *END MATERIAL
%   
%   See also importMaterial, keywords, job.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      5.6 Creating a material from a text file
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      3 Material keywords
%   
%   Quick Fatigue Tool 6.10-08 Copyright Louis Vallance 2017
%   Last modified 04-Apr-2017 13:26:59 GMT
    
    %%
    
clc
setappdata(0, 'materialManagerImport', 1.0)

% Check that the material exists
if exist(material, 'file') == 0.0
    fprintf('ERROR: Unable to locate material ''%s''\n', material)
    return
end

[error, material_properties, materialName, ~, ~] = importMaterial.processFile(material, -1.0); %#ok<ASGLU>

if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
    % User is attempting to overwrite an existing material
    response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Cancel', 'Overwrite');
    
    if (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
        return
    elseif strcmpi(response, 'Keep file') == 1.0
        % Change the name of the old material
        oldMaterial = materialName;
        while exist([oldMaterial, '.mat'], 'file') == 2.0
            oldMaterial = [oldMaterial , '-old']; %#ok<AGROW>
        end
        
        % Rename the original material
        movefile(['Data/material/local/', materialName, '.mat'], ['Data/material/local/', oldMaterial, '.mat'])
    end
end

% Save the material
try
    save(['Data/material/local/', materialName], 'material_properties')
catch
    fprintf('ERROR: Unable to save material ''%s''. Make sure the material save location has read/write access\n', materialName)
    return
end
end
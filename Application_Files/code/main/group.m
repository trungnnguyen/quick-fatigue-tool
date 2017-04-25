classdef group < handle
%GROUP    QFT class for group processing tasks.
%   This class contains methods for group processing tasks.
%   
%   GROUP is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   Reference section in Quick Fatigue Tool User Guide
%      4.6 Analysis groups
%   
%   Quick Fatigue Tool 6.10-07 Copyright Louis Vallance 2017
%   Last modified 07-Apr-2017 14:38:24 GMT
    
    %%
    
    methods(Static = true)
        
        %% INITIALIZE GROUP PROPERTIES
        function [error, numberOfGroups] = initialize()
            % Initialize the ERROR variable
            error = 0.0;
            
            % Get the analysis algorithm
            algorithm = getappdata(0, 'algorithm');
            
            % Determine if groups are being used in the analysis
            analysisGroups = getappdata(0, 'analysisGroups');
            
            % Analysis groups are not compatible with the Uniaxial
            % Stress-Life algorithm
            if algorithm == 3.0
                if (ischar(analysisGroups) == 1.0) && (strcmpi(analysisGroups, 'DEFAULT') == 0.0)
                    messenger.writeMessage(135.0)
                    analysisGroups = {'DEFAULT'};
                elseif (ischar(analysisGroups) == 0.0) && (length(analysisGroups) > 1.0)
                    messenger.writeMessage(135.0)
                    analysisGroups = {'DEFAULT'};
                elseif (ischar(analysisGroups) == 0.0) && (strcmpi(analysisGroups, 'DEFAULT') == 0.0)
                    messenger.writeMessage(135.0)
                    analysisGroups = {'DEFAULT'};
                end
            end
            setappdata(0, 'analysisGroups', analysisGroups)
            
            %{
                If GROUP is defined as a character array, warn the user
                that this option must be defined as a cell in order to work
                properly. Convert the character array into a cell
            %}
            if ischar(analysisGroups) == 1.0
                analysisGroups = cellstr(analysisGroups);
                setappdata(0, 'analysisGroups', analysisGroups)
                
                messenger.writeMessage(92.0)
            end
            
            % Get the number of analysis groups
            numberOfGroups = length(analysisGroups);
            
            if numberOfGroups > 0.0
                groupIDBuffer(numberOfGroups).name = []; % Group names
                groupIDBuffer(numberOfGroups).material = []; % Material names
                groupIDBuffer(numberOfGroups).kt = []; % Surface finish definitions
                groupIDBuffer(numberOfGroups).IDs = [];  % Group IDs
                groupIDBuffer(numberOfGroups).NIDs = []; % Number of IDs per group
                groupIDBuffer(numberOfGroups).OIDs = []; % Number of IDs in different group
                groupIDBuffer(numberOfGroups).UIDs = []; % Used IDs in each group
                groupIDBuffer(numberOfGroups).worstLife = []; % Worst life in group
                groupIDBuffer(numberOfGroups).worstLifeMainID = []; % Worst life main ID
                groupIDBuffer(numberOfGroups).worstLifeSubID = []; % Worst life sub ID
                
                % Commit the group ID buffer to the APPDATA
                setappdata(0, 'groupIDBuffer', groupIDBuffer)
            end
            
            %% Verify material definition
            
            material = getappdata(0, 'material');
            
            % Save the number of groups for later use
            if numberOfGroups == 0.0
                setappdata(0, 'numberOfGroups', 1.0)
            else
                setappdata(0, 'numberOfGroups', numberOfGroups)
            end
            
            %{
                Material validation is not required if the BS 7608 is being
                used
            %}
            if algorithm ~= 8.0
                
                if (ischar(material) == 1.0) || (getappdata(0, 'algorithm') == 8.0)
                    numberOfMaterials = 1.0;
                else
                    numberOfMaterials = length(material);
                end
                
                if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                    %{
                        The GROUP option is empty, so analysis groups are not
                        being used, or the GROUP option is specified with the
                        single argument DEFAULT, in which case analysis groups
                        are also not to be used for the analysis
                    %}
                    
                    %{
                        Verify the definition of MATERIAL in case of multiple
                        definitions
                    %}
                    if ischar(material) == 0.0
                        %{
                            The material has been defined as a cell when it
                            shouldn't
                        %}
                        if numberOfMaterials == 1.0
                            %{
                                There is only one material defined, so
                                there is no problem. Inform the user anyway
                            %}
                            setappdata(0, 'material', char(material))
                            messenger.writeMessage(90.0)
                        elseif isempty(material) == 1.0
                            %{
                                No materials are defined. Inform the user
                                and abort the analysis
                            %}
                            error = 1.0;
                            setappdata(0, 'E001', 1.0)
                            return
                        else
                            %{
                                There is more than one material defined,
                                making the definition ambiguous. Inform the
                                user and abort the analysis
                            %}
                            error = 1.0;
                            setappdata(0, 'E053', 1.0)
                            return
                        end
                    end
                elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                    %{
                        The GROUP option is specified with a single argument
                        other than DEFAULT. Only this group is to be analysed
                    %}
                    
                    % Verify the definition of MATERIAL
                    if ischar(material) == 0.0
                        %{
                            It doesn't matter whether or not the material is
                            defined as a cell or as a string. The important
                            check is whether multiple material definitions
                            exist
                        %}
                        if numberOfMaterials > 2.0
                            %{
                                There are multiple material definitions, making
                                the definition ambiguous. Inform the user and
                                abort the analysis
                            %}
                            error = 1.0;
                            setappdata(0, 'E054', 1.0)
                            return
                        elseif numberOfMaterials == 2.0
                            %{
                                There are two material definitions, making the
                                definition ambiguous. It's possible that the
                                user meant to define a group material followed
                                by a DEFAULT group, but forgot to add 'DEFAULT'
                                to the GROUP option. Inform the user and abort
                                the analysis
                            %}
                            error = 1.0;
                            setappdata(0, 'E055', 1.0)
                            return
                        end
                        
                        % Convert the material name into a character array
                        setappdata(0, 'material', char(material))
                    end
                    
                    if numberOfGroups > 1.0
                        % Save the material to the group ID buffer
                        groupIDBuffer(numberOfGroups).material = material;
                    end
                elseif numberOfGroups > 1.0
                    %{
                        The GROUP option is specified with more than one
                        argument
                    %}
                    if ischar(material) == 1.0
                        %{
                            A single material is defined as a character array.
                            Each group will be analysed with this material, but
                            warn the user that the material definition might be
                            redundant
                        %}
                        messenger.writeMessage(91.0)
                        
                        % Propagate material definition
                        material_i = cell(1.0, numberOfGroups);
                        for i = 1:numberOfGroups
                            material_i{i} = material;
                        end
                        setappdata(0, 'material', material_i)
                    elseif ischar(material) == 0.0
                        if numberOfMaterials < numberOfGroups
                            % There are fewer material than analysis groups
                            error = 1.0;
                            setappdata(0, 'E056', 1.0)
                            setappdata(0, 'error_log_056_numberOfMaterials', numberOfMaterials)
                            setappdata(0, 'error_log_056_numberOfGroups', numberOfGroups)
                            return
                        elseif numberOfMaterials == (numberOfGroups - 1.0)
                            %{
                                There is one more material than there are
                                analysis groups
                            %}
                            error = 1.0;
                            setappdata(0, 'E057', 1.0)
                            setappdata(0, 'error_log_057_numberOfMaterials', numberOfMaterials)
                            setappdata(0, 'error_log_057_numberOfGroups', numberOfGroups)
                            return
                        elseif numberOfMaterials > numberOfGroups
                            %{
                                There is greater than one material more than
                                there are analysis groups
                            %}
                            error = 1.0;
                            setappdata(0, 'E058', 1.0)
                            setappdata(0, 'error_log_058_numberOfMaterials', numberOfMaterials)
                            setappdata(0, 'error_log_058_numberOfGroups', numberOfGroups)
                            return
                        end
                    end
                    
                    % Save the material to the group ID buffer
                    for i = 1:numberOfGroups
                        if ischar(material) == 1.0
                            groupIDBuffer(i).material = material;
                        else
                            groupIDBuffer(i).material = material(i);
                        end
                    end
                end
            else
                numberOfMaterials = numberOfGroups;
            end
            
            %{
                Initialize the structure which will contain the properties
                for each material
            %}
            group_materialProps(numberOfMaterials).materialDescription = [];
            group_materialProps(numberOfMaterials).defaultAlgorithm = [];
            group_materialProps(numberOfMaterials).defaultMSC = [];
            group_materialProps(numberOfMaterials).fsc = [];
            group_materialProps(numberOfMaterials).cael = [];
            group_materialProps(numberOfMaterials).cael_status = [];
            group_materialProps(numberOfMaterials).E = [];
            group_materialProps(numberOfMaterials).uts = [];
            group_materialProps(numberOfMaterials).ucs = [];
            group_materialProps(numberOfMaterials).poisson = [];
            group_materialProps(numberOfMaterials).sValues = [];
            group_materialProps(numberOfMaterials).sValuesReduced = [];
            group_materialProps(numberOfMaterials).nSNDatasets = [];
            group_materialProps(numberOfMaterials).nValues = [];
            group_materialProps(numberOfMaterials).rValues = [];
            group_materialProps(numberOfMaterials).k = [];
            group_materialProps(numberOfMaterials).ndEndurance = [];
            group_materialProps(numberOfMaterials).materialBehavior = [];
            group_materialProps(numberOfMaterials).regressionModel = [];
            group_materialProps(numberOfMaterials).b = [];
            group_materialProps(numberOfMaterials).b2 = [];
            group_materialProps(numberOfMaterials).b2Nf = [];
            group_materialProps(numberOfMaterials).Sf = [];
            group_materialProps(numberOfMaterials).Ef = [];
            group_materialProps(numberOfMaterials).c = [];
            group_materialProps(numberOfMaterials).kp = [];
            group_materialProps(numberOfMaterials).np = [];
            group_materialProps(numberOfMaterials).twops = [];
            group_materialProps(numberOfMaterials).TfPrime = [];
            group_materialProps(numberOfMaterials).Tfs = [];
            group_materialProps(numberOfMaterials).fatigueLimit = [];
            group_materialProps(numberOfMaterials).Kt = [];
            group_materialProps(numberOfMaterials).KtFileType = [];
            group_materialProps(numberOfMaterials).KtCurve = [];
            group_materialProps(numberOfMaterials).strainLimitEnergy = [];
            group_materialProps(numberOfMaterials).residualStress = [];
            group_materialProps(numberOfMaterials).frfEnvelope = [];
            group_materialProps(numberOfMaterials).userFRFData = [];
            group_materialProps(numberOfMaterials).userFRFNormParamMeanT = [];
            group_materialProps(numberOfMaterials).userFRFNormParamMeanC = [];
            group_materialProps(numberOfMaterials).userFRFNormParamAmp = [];
            group_materialProps(numberOfMaterials).userEnduranceLimit = [];
            group_materialProps(numberOfMaterials).walkerGamma = [];
            group_materialProps(numberOfMaterials).snKnockDown = [];
            group_materialProps(numberOfMaterials).modifiedGoodman = [];
            group_materialProps(numberOfMaterials).goodmanLimitStress = [];
            group_materialProps(numberOfMaterials).notchSensitivityConstant = [];
            group_materialProps(numberOfMaterials).notchRootRadius = [];
            
            setappdata(0, 'group_materialProps', group_materialProps)
            
            %% Verify surface finish definition
            
            ktDef = getappdata(0, 'ktDef');
            
            if ischar(ktDef) == 1.0
                numberOfKtDefinitions = 1.0;
            else
                numberOfKtDefinitions = length(ktDef);
            end
            
            if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                %{
                    Verify the definition of KT_DEF in case of multiple
                    definitions
                %}
                if (ischar(ktDef) == 0.0) && (isnumeric(ktDef) == 0.0)
                    %{
                        The Kt definition has been defined as a cell when
                        it shouldn't
                    %}
                    if numberOfKtDefinitions == 1.0
                        %{
                            There is only one Kt defintion, so there is
                            no problem. Inform the user anyway
                        %}
                        setappdata(0, 'ktDef', char(ktDef))
                        messenger.writeMessage(105.0)
                    else
                        %{
                            There is more than one Kt definition, making
                            the definition ambiguous. Inform the user and
                            abort the analysis
                        %}
                        error = 1.0;
                        setappdata(0, 'E065', 1.0)
                        return
                    end
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definition of KT_DEF
                if ischar(ktDef) == 0.0
                    %{
                        It doesn't matter whether or not the surface finish
                        is defined as a cell or as a string. The important
                        check is whether multiple Kt definitions exist
                    %}
                    if numberOfKtDefinitions > 2.0
                        %{
                            There are multiple Kt definitions, making the
                            definition ambiguous. Inform the user and abort
                            the analysis
                        %}
                        error = 1.0;
                        setappdata(0, 'E066', 1.0)
                        return
                    elseif numberOfKtDefinitions == 2.0
                        %{
                            There are two Kt definitions, making the
                            definition ambiguous. It's possible that the
                            user meant to define a group Kt definition
                            followed by a DEFAULT group, but forgot to add
                            'DEFAULT' to the GROUP option. Inform the user
                            and abort the analysis
                        %}
                        error = 1.0;
                        setappdata(0, 'E067', 1.0)
                        return
                    end
                    
                    % Convert the Kt definition into a character array
                    setappdata(0, 'ktDef', char(ktDef))
                end
                
                if numberOfGroups > 1.0
                    % Save the Kt definition to the group ID buffer
                    groupIDBuffer(numberOfGroups).kt = ktDef;
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if ischar(ktDef) == 1.0
                    %{
                        A single Kt definition is defined as a character
                        array. Each group will be analysed with this
                        Kt definition, but warn the user that the
                        definition might be redundant
                    %}
                    messenger.writeMessage(106.0)
                elseif ischar(ktDef) == 0.0
                    if numberOfKtDefinitions < numberOfGroups
                        % There are fewer Kt definitions than analysis groups
                        error = 1.0;
                        setappdata(0, 'E068', 1.0)
                        setappdata(0, 'error_log_068_numberOfKtDefinitions', numberOfKtDefinitions)
                        setappdata(0, 'error_log_068_numberOfGroups', numberOfGroups)
                        return
                    elseif numberOfKtDefinitions == (numberOfGroups - 1.0)
                        %{
                            There is one more Kt definition than there are
                            analysis groups
                        %}
                        error = 1.0;
                        setappdata(0, 'E069', 1.0)
                        setappdata(0, 'error_log_069_numberOfKtDefinitions', numberOfKtDefinitions)
                        setappdata(0, 'error_log_069_numberOfGroups', numberOfGroups)
                        return
                    elseif numberOfKtDefinitions > numberOfGroups
                        %{
                            There is greater than one Kt definition more
                            than there are analysis groups
                        %}
                        error = 1.0;
                        setappdata(0, 'E070', 1.0)
                        setappdata(0, 'error_log_070_numberOfKtDefinitions', numberOfKtDefinitions)
                        setappdata(0, 'error_log_070_numberOfGroups', numberOfGroups)
                        return
                    end
                end
                
                % Save the material to the group ID buffer
                if ischar(ktDef) == 1.0
                    groupIDBuffer(1.0).kt = ktDef;
                else
                    for i = 1:numberOfKtDefinitions
                        groupIDBuffer(i).kt = ktDef(i);
                    end
                end
            end
            
            %% Verify the fatigue notch constant
            notchConstant = getappdata(0, 'notchSensitivityConstant');
            
            numberOfConstants = length(notchConstant);
            
            if isempty(notchConstant) == 1.0
                setappdata(0, 'notchSensitivityConstant', zeros(1.0, numberOfGroups))
            elseif (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                %{
                    Verify the definition of NOTCH_SENSITIVITY_CONSTANT in
                    case of multiple definitions
                %}
                
                if numberOfConstants > 1.0
                    %{
                        There is more than one constant, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(216.0)
                    setappdata(0, 'notchSensitivityConstant', notchConstant(1.0))
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definition of NOTCH_SENSITIVITY_CONSTANT
                if numberOfConstants > 2.0
                    %{
                        There are multiple constants, making the
                        definition ambiguous
                    %}
                    messenger.writeMessage(217.0)
                    setappdata(0, 'notchSensitivityConstant', notchConstant(1.0))
                elseif numberOfConstants == 2.0
                    %{
                        There are two constants, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group constant followed by a DEFAULT
                        group, but forgot to add 'DEFAULT' to the GROUP
                        option. Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E112', 1.0)
                    return
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if numberOfConstants < numberOfGroups
                    % There are fewer constant definitions than analysis groups
                    error = 1.0;
                    setappdata(0, 'E129', 1.0)
                    setappdata(0, 'error_log_129_numberOfConstants', numberOfConstants)
                    setappdata(0, 'error_log_129_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfConstants == (numberOfGroups - 1.0)
                    %{
                        There is one more constant than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E130', 1.0)
                    setappdata(0, 'error_log_130_numberOfConstants', numberOfConstants)
                    setappdata(0, 'error_log_130_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfConstants > numberOfGroups
                    %{
                        There is greater than one constant more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E131', 1.0)
                    setappdata(0, 'error_log_131_numberOfConstants', numberOfConstants)
                    setappdata(0, 'error_log_131_numberOfGroups', numberOfGroups)
                    return
                end
            end
            
            %% Verify the fatigue notch root radius
            notchRadius = getappdata(0, 'notchRootRadius');
            
            numberOfRadii = length(notchRadius);
            
            if isempty(notchRadius) == 1.0
                setappdata(0, 'notchRootRadius', zeros(1.0, numberOfGroups))
            elseif (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                %{
                    Verify the definition of NOTCH_SENSITIVITY_CONSTANT in
                    case of multiple definitions
                %}
                
                if numberOfRadii > 1.0
                    %{
                        There is more than one constant, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(218.0)
                    setappdata(0, 'notchRootRadius', notchRadius(1.0))
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definition of NOTCH_SENSITIVITY_CONSTANT
                if numberOfRadii > 2.0
                    %{
                        There are multiple constants, making the
                        definition ambiguous
                    %}
                    messenger.writeMessage(219.0)
                    setappdata(0, 'notchRootRadius', notchRadius(1.0))
                elseif numberOfRadii == 2.0
                    %{
                        There are two constants, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group constant followed by a DEFAULT
                        group, but forgot to add 'DEFAULT' to the GROUP
                        option. Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E132', 1.0)
                    return
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if numberOfRadii < numberOfGroups
                    % There are fewer constant definitions than analysis groups
                    error = 1.0;
                    setappdata(0, 'E133', 1.0)
                    setappdata(0, 'error_log_133_numberOfRadii', numberOfRadii)
                    setappdata(0, 'error_log_133_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfRadii == (numberOfGroups - 1.0)
                    %{
                        There is one more constant than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E134', 1.0)
                    setappdata(0, 'error_log_134_numberOfRadii', numberOfRadii)
                    setappdata(0, 'error_log_134_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfRadii > numberOfGroups
                    %{
                        There is greater than one constant more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E135', 1.0)
                    setappdata(0, 'error_log_135_numberOfRadii', numberOfRadii)
                    setappdata(0, 'error_log_135_numberOfGroups', numberOfGroups)
                    return
                end
            end
            
            %% Verify the S-N scale factors
            
            %{
                The S-N scale factors only need to be verified if USE_SN =
                1.0 in the job file
            %}
            if getappdata(0, 'useSN') == 1.0
                snScale = getappdata(0, 'snScale');
            
                numberOfSNScales = length(snScale);
                
                if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                    %{
                        The GROUP option is empty, so analysis groups are not
                        being used, or the GROUP option is specified with the
                        single argument DEFAULT, in which case analysis groups
                        are also not to be used for the analysis
                    %}
                    
                    %{
                        Verify the definition of SN_SCALE in case of multiple
                        definitions
                    %}
                    
                    if numberOfSNScales > 1.0
                        %{
                            There is more than one S-N scale, making the
                            definition ambiguous. Use only the first value
                        %}
                        messenger.writeMessage(27.0)
                        setappdata(0, 'snScale', snScale(1.0))
                    end
                elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                    %{
                        The GROUP option is specified with a single argument
                        other than DEFAULT. Only this group is to be analysed
                    %}
                    
                    % Verify the definition of SN_SCALE
                    if numberOfSNScales > 2.0
                        %{
                            There are multiple S-N scales, making the
                            definition ambiguous
                        %}
                        messenger.writeMessage(110.0)
                        setappdata(0, 'snScale', snScale(1.0))
                    elseif numberOfSNScales == 2.0
                        %{
                            There are two S-N scales, making the definition
                            ambiguous. It's possible that the user meant to
                            define a group S-N scale followed by a DEFAULT
                            group, but forgot to add 'DEFAULT' to the GROUP
                            option. Inform the user and abort the analysis
                        %}
                        error = 1.0;
                        setappdata(0, 'E071', 1.0)
                        return
                    end
                elseif numberOfGroups > 1.0
                    %{
                        The GROUP option is specified with more than one
                        argument
                    %}
                    if numberOfSNScales == 1.0
                        %{
                            A single S-N scale is defined. Each group will
                            be analysed with this factor, but warn the
                            user that the definition might be redundant
                        %}
                        messenger.writeMessage(244.0)
                        
                        % Propagate S-N scale definition
                        snScale = linspace(snScale, snScale, numberOfGroups);
                        setappdata(0, 'snScale', snScale)
                    elseif numberOfSNScales < numberOfGroups
                        % There are fewer S-N scales definitions than analysis groups
                        error = 1.0;
                        setappdata(0, 'E072', 1.0)
                        setappdata(0, 'error_log_072_numberOfSNScales', numberOfSNScales)
                        setappdata(0, 'error_log_072_numberOfGroups', numberOfGroups)
                        return
                    elseif numberOfSNScales == (numberOfGroups - 1.0)
                        %{
                            There is one more S-N scale than there are analysis
                            groups
                        %}
                        error = 1.0;
                        setappdata(0, 'E073', 1.0)
                        setappdata(0, 'error_log_073_numberOfSNScales', numberOfSNScales)
                        setappdata(0, 'error_log_073_numberOfGroups', numberOfGroups)
                        return
                    elseif numberOfSNScales > numberOfGroups
                        %{
                            There is greater than one S-N scale more than there
                            are analysis groups
                        %}
                        error = 1.0;
                        setappdata(0, 'E074', 1.0)
                        setappdata(0, 'error_log_074_numberOfSNScales', numberOfSNScales)
                        setappdata(0, 'error_log_074_numberOfGroups', numberOfGroups)
                        return
                    end
                end
            end
            
            %% Verify residual stress definition
            residualStress = getappdata(0, 'residualStress');
            
            numberOfResiduals = length(residualStress);
            
            if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                %{
                    Verify the definition of RESIDUAL in case of multiple
                    definitions
                %}

                if numberOfResiduals > 1.0
                    %{
                        There is more than one residual stress, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(111.0)
                    setappdata(0, 'residualStress', residualStress(1.0))
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definition of RESIDUAL
                if numberOfResiduals > 2.0
                    %{
                        There are multiple residuals, making the definition
                        ambiguous
                    %}
                    messenger.writeMessage(112.0)
                    setappdata(0, 'residualStress', residualStress(1.0))
                elseif numberOfResiduals == 2.0
                    %{
                        There are two residuals, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group residual stress followed by a
                        DEFAULT group, but forgot to add 'DEFAULT' to the
                        GROUP option. Inform the user and abort the
                        analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E075', 1.0)
                    return
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if numberOfResiduals == 1.0
                    %{
                        A single residual is defined. Each group will
                        be analysed with this residual, but warn the
                        user that the definition might be redundant
                    %}
                    messenger.writeMessage(245.0)
                        
                    % Propagate residual stress definition
                    residualStress = linspace(residualStress, residualStress, numberOfGroups);
                    setappdata(0, 'residualStress', residualStress)
                elseif numberOfResiduals < numberOfGroups
                    % There are fewer residual stresses than analysis groups
                    error = 1.0;
                    setappdata(0, 'E076', 1.0)
                    setappdata(0, 'error_log_076_numberOfResidualStresses', numberOfResiduals)
                    setappdata(0, 'error_log_076_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfResiduals == (numberOfGroups - 1.0)
                    %{
                        There is one more residual stress than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E077', 1.0)
                    setappdata(0, 'error_log_077_numberOfResidualStresses', numberOfResiduals)
                    setappdata(0, 'error_log_077_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfResiduals > numberOfGroups
                    %{
                        There is greater than one residual stress more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E078', 1.0)
                    setappdata(0, 'error_log_078_numberOfResidualStresses', numberOfResiduals)
                    setappdata(0, 'error_log_078_numberOfGroups', numberOfGroups)
                    return
                end
            end
            
            % Save the residual stresses
            setappdata(0, 'residualStress_original', residualStress)
            
            %% Verify B2/B2_NF/UCS definition
            b2 = getappdata(0, 'b2');
            b2Nf = getappdata(0, 'b2Nf');
            ucs = getappdata(0, 'ucs');
            
            if isempty(b2) == 1.0
                numberOfB2 = [];
            else
                numberOfB2 = length(b2);
            end
            if isempty(b2Nf) == 1.0
                numberOfB2Nf = [];
            else
                numberOfB2Nf = length(b2Nf);
            end
            if isempty(ucs) == 1.0
                numberOfUCS = [];
            else
                numberOfUCS = length(ucs);
            end
            
            if length(b2) ~= length(b2Nf)
                error = 1.0;
                setappdata(0, 'E095', 1.0)
                return
            end
            
            if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                % Verify the definitions in case of multiple definitions

                if numberOfB2 > 1.0
                    %{
                        There is more than one b2, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(127.0)
                    setappdata(0, 'b2', b2(1.0))
                end
                
                if numberOfB2Nf > 1.0
                    %{
                        There is more than one b2Nf, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(128.0)
                    setappdata(0, 'b2Nf', b2Nf(1.0))
                end
                
                if numberOfUCS > 1.0
                    %{
                        There is more than one UCS, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(129.0)
                    setappdata(0, 'ucs', ucs(1.0))
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definitions
                if numberOfB2 > 2.0
                    %{
                        There are multiple B2s, making the definition
                        ambiguous
                    %}
                    messenger.writeMessage(130.0)
                    setappdata(0, 'b2', b2(1.0))
                elseif numberOfB2 == 2.0
                    %{
                        There are two b2s, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group b2 followed by a DEFAULT group, but
                        forgot to add 'DEFAULT' to the GROUP option.
                        Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E083', 1.0)
                    return
                end
                
                if numberOfB2Nf > 2.0
                    %{
                        There are multiple B2Nfs, making the definition
                        ambiguous
                    %}
                    messenger.writeMessage(131.0)
                    setappdata(0, 'b2Nf', b2Nf(1.0))
                elseif numberOfB2Nf == 2.0
                    %{
                        There are two B2Nfs, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group B2Nf followed by a DEFAULT group,
                        but forgot to add 'DEFAULT' to the GROUP option.
                        Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E084', 1.0)
                    return
                end
                
                if numberOfUCS > 2.0
                    %{
                        There are multiple B2Nfs, making the definition
                        ambiguous
                    %}
                    messenger.writeMessage(132.0)
                    setappdata(0, 'ucs', ucs(1.0))
                elseif numberOfUCS == 2.0
                    %{
                        There are two UCS values, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group UCS followed by a DEFAULT group,
                        but forgot to add 'DEFAULT' to the GROUP option.
                        Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E085', 1.0)
                    return
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if numberOfB2 < numberOfGroups
                    % There are fewer b2s than analysis groups
                    error = 1.0;
                    setappdata(0, 'E086', 1.0)
                    setappdata(0, 'error_log_086_numberOfB2', numberOfB2)
                    setappdata(0, 'error_log_086_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfB2 == (numberOfGroups - 1.0)
                    %{
                        There is one more b2 than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E087', 1.0)
                    setappdata(0, 'error_log_087_numberOfB2', numberOfB2)
                    setappdata(0, 'error_log_087_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfB2 > numberOfGroups
                    %{
                        There is greater than one b2 more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E088', 1.0)
                    setappdata(0, 'error_log_088_numberOfB2', numberOfB2)
                    setappdata(0, 'error_log_088_numberOfGroups', numberOfGroups)
                    return
                end
                
                if numberOfB2Nf < numberOfGroups
                    % There are fewer b2Nfs than analysis groups
                    error = 1.0;
                    setappdata(0, 'E089', 1.0)
                    setappdata(0, 'error_log_089_numberOfB2Nf', numberOfB2Nf)
                    setappdata(0, 'error_log_089_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfB2Nf == (numberOfGroups - 1.0)
                    %{
                        There is one more b2Nf than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E090', 1.0)
                    setappdata(0, 'error_log_090_numberOfB2Nf', numberOfB2Nf)
                    setappdata(0, 'error_log_090_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfB2Nf > numberOfGroups
                    %{
                        There is greater than one b2Nf more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E091', 1.0)
                    setappdata(0, 'error_log_091_numberOfB2Nf', numberOfB2Nf)
                    setappdata(0, 'error_log_091_numberOfGroups', numberOfGroups)
                    return
                end
                
                if numberOfUCS < numberOfGroups
                    % There are fewer UCS values than analysis groups
                    error = 1.0;
                    setappdata(0, 'E092', 1.0)
                    setappdata(0, 'error_log_092_numberOfUCS', numberOfUCS)
                    setappdata(0, 'error_log_092_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfUCS == (numberOfGroups - 1.0)
                    %{
                        There is one more UCS than there are analysis
                        groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E093', 1.0)
                    setappdata(0, 'error_log_093_numberOfUCS', numberOfUCS)
                    setappdata(0, 'error_log_093_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfUCS > numberOfGroups
                    %{
                        There is greater than one UCS more than there
                        are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E094', 1.0)
                    setappdata(0, 'error_log_094_numberOfUCS', numberOfUCS)
                    setappdata(0, 'error_log_094_numberOfGroups', numberOfGroups)
                    return
                end
            end
            
            % Save b2
            setappdata(0, 'b2_original', b2)
            
            % Save b2Nf
            setappdata(0, 'b2Nf_original', b2Nf)
            
            % Save UCS
            setappdata(0, 'ucs_original', ucs)
            
            %% Verify SN_KNOCK_DOWN definition
            snKnockDown = getappdata(0, 'snKnockDown');
            
            %{
                If SN_KNOCK_DOWN is defined as a character array, warn the
                user that this option must be defined as a cell in order
                to work properly. Convert the character array into a cell
            %}
            if ischar(snKnockDown) == 1.0
                snKnockDown = cellstr(snKnockDown);
                setappdata(0, 'snKnockDown', snKnockDown)
                
                messenger.writeMessage(44.0)
            end
            
            if isempty(snKnockDown) == 1.0
                numberOfSnKnockDown = [];
            else
                numberOfSnKnockDown = length(snKnockDown);
            end
            
            if (isempty(analysisGroups) == 1.0) || ((numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'default') == 1.0))
                %{
                    The GROUP option is empty, so analysis groups are not
                    being used, or the GROUP option is specified with the
                    single argument DEFAULT, in which case analysis groups
                    are also not to be used for the analysis
                %}
                
                % Verify the definitions in case of multiple definitions

                if numberOfSnKnockDown > 1.0
                    %{
                        There is more than one knock-down, making the
                        definition ambiguous. Use only the first value
                    %}
                    messenger.writeMessage(146.0)
                    setappdata(0, 'snKnockDown', snKnockDown(1.0))
                end
            elseif (numberOfGroups == 1.0) && (strcmpi(analysisGroups, 'defualt') == 0.0)
                %{
                    The GROUP option is specified with a single argument
                    other than DEFAULT. Only this group is to be analysed
                %}
                
                % Verify the definitions
                if numberOfSnKnockDown > 2.0
                    %{
                        There are multiple knock-downs, making the
                        definition ambiguous
                    %}
                    messenger.writeMessage(146.0)
                    setappdata(0, 'snKnockDown', snKnockDown(1.0))
                elseif numberOfSnKnockDown == 2.0
                    %{
                        There are two knock-downs, making the definition
                        ambiguous. It's possible that the user meant to
                        define a group knock-down followed by a DEFAULT
                        group, but forgot to add 'DEFAULT' to the GROUP
                        option. Inform the user and abort the analysis
                    %}
                    error = 1.0;
                    setappdata(0, 'E102', 1.0)
                    return
                end
            elseif numberOfGroups > 1.0
                %{
                    The GROUP option is specified with more than one
                    argument
                %}
                if numberOfSnKnockDown < numberOfGroups
                    % There are fewer knock-downs than analysis groups
                    error = 1.0;
                    setappdata(0, 'E103', 1.0)
                    setappdata(0, 'error_log_103_numberOfSnKnockDown', numberOfSnKnockDown)
                    setappdata(0, 'error_log_103_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfSnKnockDown == (numberOfGroups - 1.0)
                    %{
                        There is one more knock-down than there are
                        analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E104', 1.0)
                    setappdata(0, 'error_log_104_numberOfSnKnockDown', numberOfSnKnockDown)
                    setappdata(0, 'error_log_104_numberOfGroups', numberOfGroups)
                    return
                elseif numberOfSnKnockDown > numberOfGroups
                    %{
                        There is greater than one knock-down more than
                        there are analysis groups
                    %}
                    error = 1.0;
                    setappdata(0, 'E105', 1.0)
                    setappdata(0, 'error_log_105_numberOfSnKnockDown', numberOfSnKnockDown)
                    setappdata(0, 'error_log_105_numberOfGroups', numberOfGroups)
                    return
                end
            end
            
            % Save S-N knock-down
            setappdata(0, 'snKnockDown', snKnockDown)
            
            %% Save the group ID buffer
            if numberOfGroups > 0.0
                % Commit the group ID buffer to the APPDATA
                setappdata(0, 'groupIDBuffer', groupIDBuffer)
            end
            
            %% Verify the algorithm
            %{
                For now, only multiple materials are supported. Later on,
                the GROUP option will also allow for multiple algorithm/MSC
                definitions
            %}
        end
        
        %% GET GROUP ITEMS
        function [error, N, mainIDs_master, subIDs_master] = getItems(N, mainIDs_master, subIDs_master)
            %{
                Read each group file in turn. For each file, compare the
                position/item IDs with the master mainID/subID list
            
                After reading each group file, eliminate any matched IDs
                from the master ID domain so that repeat IDs in subsequent
                groups are excluded from the search
            
                The default behaviour should be to assume the following:
            
                1 data column: Item ID list unless stated otherwise
                >1 data column: Always assume FEA subset
            %}
            
            % Initialize the error variable
            error = 0.0;
            
            % Initialize the variable to store the history of deleted IDs
            deletedMainIDs = [];
            deletedSubIDs = [];
            deletedMainIDIndexes = [];
            
            % Get the list of analysis groups
            analysisGroups = getappdata(0, 'analysisGroups');
            
            %{
                If there are no analysis groups defined for the analysis,
                RETURN and continue the analysis without group definitions
            %}
            if isempty(analysisGroups) == 1.0
                return
            end
            
            %{
                If the DEFAULT group is used, save the master ID list as
                this will be used as the final ID list for the analysis
            %}
            mainID = mainIDs_master;
            subID = subIDs_master;
            
            % Save the position IDs from the original model
            setappdata(0, 'mainID_master', mainIDs_master)
            setappdata(0, 'subID_master', subIDs_master)
            
            % Get the group definition environment variable
            groupDefinitionRequest = getappdata(0, 'groupDefinition');
            
            % Get the original number of master IDs
            numberOfMasterIDs = length(mainIDs_master);
            
            %{
                Create address list for the master IDs. This is so the
                true location of remaining IDs is still known after
                removing matching IDs from the master list
            %}
            addressBuffer = linspace(1.0, length(mainIDs_master), length(mainIDs_master));
            addressBuffer_idList = addressBuffer;
            
            % Get the length of the address buffer
            addressBufferLength = length(addressBuffer);
            
            % Initialize the buffer for the group IDs
            L = length(analysisGroups);
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Store all duplicate ID indexes
            intersectingIDBuffer = [];
            
            % Variable which indicates an early break from the loop
            earlyBreak = 0.0;
            
            % Initialize the container for the final group IDs
            mainIDs_master_group = [];
            subIDs_master_group = [];
            
            % Initialize the container for the ID list in the group order
            mainID_groupAll = [];
            subID_groupAll = [];
            
            % Group definition variable
            %{
                1: Item ID list
                2: FEA subset
            %}
            groupDefinition = zeros(1.0, L);
            
            for i = 1:L
                %{
                    Initialize the variable which counts the number of
                    duplicate IDs
                %}
                numberOfDuplicateIDs = 0.0;
                foundIDFromFieldFail = 0.0;
                
                % Save the name of the current group file
                setappdata(0, 'message_groupFile', analysisGroups{i})
                setappdata(0, 'message_groupNumber', i)
                
                % Check if the current group is the default group
                if strcmpi(analysisGroups{i}, 'default') == 1.0 && i ~= length(analysisGroups)
                    error = 1.0;
                    setappdata(0, 'E064', 1.0)
                    
                    return
                elseif strcmpi(analysisGroups{i}, 'default') == 1.0
                    %{
                        This is the DEFAULT group, so there is no file to
                        read
                    %}
                    break
                end
                
                [subIDs_group, mainIDs_group, fieldData, error, nodeType] = group.readFile(analysisGroups{i});
                
                % Store the number of IDs for the current group
                groupIDBuffer(i).NIDs = length(subIDs_group);
                
                % Store the current group name
                groupIDBuffer(i).name = analysisGroups{i};
                
                if error == 1.0
                    % There was an error while reading one of the groups
                    return
                end
                
                % Check how the group data is defined
                dataLabel_master = getappdata(0, 'dataLabel');
                dataLabel_group = getappdata(0, 'dataLabel_group');
                
                % Get the field data content from the FIELDDATA variable
                dataPosition_master = getappdata(0, 'dataPosition');
                [~, C] = size(fieldData);
                
                %{
                    If the group file is formatted exactly the same as the
                    master dataset file, the field data of the group file
                    can be used in the event that the analysis encounters a
                    duplicate ID in order to resolve the ambiguity
                %}
                if dataLabel_master == dataLabel_group
                    if (dataPosition_master == 1.0) && (C > 2.0)
                        %{
                            The field data in the group matches that of the
                            master dataset. The data is elemental or
                            integration point
                        %}
                        fieldData_group = fieldData(:, 3:end);
                        
                        % Get the field data from the master dataset
                        fieldData_master = getappdata(0, 'fieldData_master');
                    elseif (dataPosition_master == 2.0) && (C > 1.0)
                        %{
                            The field data in the group matches that of the
                            master dataset. The data is nodal or centroidal
                        %}
                        fieldData_group = fieldData(:, 2:end);
                        
                        % Get the field data from the master dataset
                        fieldData_master = getappdata(0, 'fieldData_master');
                    else
                        %{
                            Matching field data could not be found. Field
                            data cannot be used to resolve duplicate ID
                            conflicts
                        %}
                        fieldData_group = [];
                    end
                else
                    fieldData_group = [];
                end
                
                %{
                    Decide whether to treat group data as an item ID list 
                    or as an FEA subset
                %}
                if dataLabel_group == 1.0
                    %{
                        There is only one column of data in the current
                        group file. Most likely this is an item ID list,
                        because .rpt files from Abaqus always contain a
                        minimum of two columns (1 position + 1 field).
                        However, it is feasible that the user created a
                        single data column of position IDs manually, in
                        which case the data should be read as an FEA subset
                    %}
                    if groupDefinitionRequest == 0.0
                        % Treat the group data as an item ID list by default
                        messenger.writeMessage(93.0)
                        
                        groupDefinition(i) = 1.0;
                        
                        %{
                            Since the gorup is being treated as an item ID
                            list, the variables subIDs_group and
                            mainIDs_group need to be corrected to reflect
                            the actual position labels which the group ID
                            list is referencing
                        %}
                        mainIDs_group2 = mainID(mainIDs_group);
                        subIDs_group2 = subID(mainIDs_group);
                    else
                        % Treat the group data as an FEA subset
                        if getappdata(0, 'nodeType_master') ~= nodeType
                            %{
                                The data positions of the master and group
                                data do not match. Abort the analysis
                            %}
                            error = 1.0;
                            setappdata(0, 'E106', 1.0)
                            return
                        else
                            messenger.writeMessage(98.0)
                        end
                        groupDefinition(i) = 2.0;
                    end
                else
                    % Treat group data as an FEA subset
                    
                    %{
                        Compare the position labels from the group data to
                        the master dataset. A discrepancy between the
                        position labels could lead to inaccurate results
                    %}
                    messenger.writeMessage(97.0)
                    
                    if dataLabel_group == dataLabel_master
                        %{
                            Groups are defined as FEA subsets and the
                            position IDs match
                        %}
                        messenger.writeMessage(94.0)
                    else
                        %{
                            Groups are defined as FEA subsets and the
                            position IDs do not match
                        %}
                        messenger.writeMessage(95.0)
                    end
                    
                    if getappdata(0, 'nodeType_master') ~= nodeType
                        %{
                            The data positions of the master and group
                            data do not match. Abort the analysis
                        %}
                        error = 1.0;
                        setappdata(0, 'E106', 1.0)
                        return
                    end
                    
                    groupDefinition(i) = 2.0;
                end
                
                % Initialize some variables related to the ID matching code
                groupIDs =  [];
                IDsToDelete = [];
                IDsToDelete2 = [];
                unmatchedIDs = 0.0;
                IDsInOtherGroup = 0.0;
                eliminationWarning = 0.0;
                
                % Define an item list for the current group
                if groupDefinition(i) == 2.0
                    %{
                        The current group is defined as an FEA subset.
                        Find matching position IDs with the master dataset
                    %}
                    for j = 1:length(mainIDs_group)
                        
                        % Get matching position IDs
                        matchingMainIDs = find(mainIDs_master == mainIDs_group(j));
                        matchingSubIDs = find(subIDs_master == subIDs_group(j));
                        
                        % Get matching position IDs for unedited item ID list
                        matchingMainIDs2 = find(mainID == mainIDs_group(j));
                        matchingSubIDs2 = find(subID == subIDs_group(j));
                        
                        if (isempty(matchingMainIDs) == 1.0) || (isempty(matchingSubIDs) == 1.0) || (isempty(intersect(matchingMainIDs, matchingSubIDs)) == 1.0)
                            %{
                                There is no ID in the master dataset
                                corresponding to the current group ID.
                                Ignore this ID and continue
                            %}
                            if intersect((find(deletedMainIDs == mainIDs_group(j))), (find(deletedSubIDs == subIDs_group(j)))) == 0.0
                                %{
                                    This ID does not belong to the model.
                                    Warn the user
                                %}
                                unmatchedIDs = unmatchedIDs + 1.0;
                                eliminationWarning = 1.0;
                            elseif i == 1.0
                                %{
                                    This ID does not belong to the model.
                                    Warn the user
                                %}
                                unmatchedIDs = unmatchedIDs + 1.0;
                                eliminationWarning = 1.0;
                            else
                                %{
                                    This ID belongs to the model, but was
                                    eliminated by a previous group. No need
                                    to inform the user
                                %}
                                IDsInOtherGroup = IDsInOtherGroup + 1.0;
                            end
                            
                            continue
                        end
                        
                        intersectingIDs = intersect(matchingMainIDs, matchingSubIDs);
                        intersectingIDs2 = intersect(matchingMainIDs2, matchingSubIDs2);
                        %{
                            If the FEA subset contains multiple regions,
                            it's possible for the same analysis item to
                            appear twice. If this happens, take the first
                            analysis items encountered in the set
                        %}
                        if length(intersectingIDs) > 1.0
                            %{
                                Make sure the same ID is not marked for
                                deletion more than once
                            %}
                            if isempty(fieldData_group) == 0.0
                                %{
                                    Since there is field data included in
                                    the group file, try to match the
                                    correct ID based on the field data
                                %}
                                
                                %{
                                    Get the field data associated with the
                                    current group item
                                %}
                                fieldData_group_j = fieldData_group(j, :);
                                
                                %{
                                    Get the field data associated with the
                                    matching main IDs
                                %}
                                for k = 1:length(intersectingIDs)
                                    %{
                                        The mainIDs_master variable changes
                                        throughout the analysis, so its
                                        index needs to be converted to the
                                        master dataset index before it can
                                        be used to get the field data
                                    %}
                                    itemFromMasterID = mainIDs_master(intersectingIDs(k));
                                    itemFromOrigialDataset = find(mainID == itemFromMasterID);
                                    
                                    fieldData_master_j = fieldData_master(itemFromOrigialDataset(k), :);

                                    if all(fieldData_group_j == fieldData_master_j) == 1.0
                                        intersectingIDs = intersectingIDs(k);
                                        break
                                    end
                                    
                                    if k == length(intersectingIDs)
                                        %{
                                            The field data could not be
                                            used to find a match. There is
                                            probably an issue with the
                                            group definition. Take the
                                            first ID encountered and
                                            eliminate it from the group.
                                            Warn the user
                                        %}
                                        foundIDFromFieldFail = [foundIDFromFieldFail, 1.0]; %#ok<AGROW>
                                        for k2 = 1:length(intersectingIDs)
                                            if any(IDsToDelete == intersectingIDs(k2)) == 0.0
                                                intersectingIDs = intersectingIDs(k2);
                                                break
                                            end
                                        end
                                    end
                                end
                            else
                                for k = 1:length(intersectingIDs)
                                    if any(IDsToDelete == intersectingIDs(k)) == 0.0
                                        intersectingIDs = intersectingIDs(k);
                                        break
                                    end
                                end
                            end
                            
                            numberOfDuplicateIDs = numberOfDuplicateIDs + 1.0;
                            intersectingIDBuffer = [intersectingIDBuffer, intersectingIDs]; %#ok<AGROW>
                        end
                        
                        IDsToDelete(j) = intersectingIDs; %#ok<AGROW>
                        IDsToDelete2(j) = intersectingIDs2; %#ok<AGROW>
                        groupIDs(j) = addressBuffer(IDsToDelete(j)); %#ok<AGROW>
                        
                        %{
                            If the number of group IDs is equal to or
                            greater than the number of elements in the
                            address buffer, then the current group has
                            removed all itesm from the model
                        %}
                        if length(find(groupIDs > 0.0)) >= length(addressBuffer)
                            earlyBreak = 1.0;
                            break
                        end
                    end
                    
                    % Warn the user if there are duplicate IDs in the group
                    if numberOfDuplicateIDs > 1.0
                        setappdata(0, 'numberOfDuplicateIDs', numberOfDuplicateIDs)
                        if isempty(fieldData_group) == 0.0
                            if all(foundIDFromFieldFail == 1.0) == 1.0
                                messenger.writeMessage(116.0)
                            elseif any(foundIDFromFieldFail == 1.0) == 1.0
                                messenger.writeMessage(115.0)
                            else
                                messenger.writeMessage(114.0)
                            end
                        else
                            messenger.writeMessage(113.0)
                        end
                    end
                    
                    %{
                        Warn the user in case unmatched IDs were found in
                        the current group
                    %}
                    if (eliminationWarning == 1.0) && (unmatchedIDs == length(mainIDs_group))
                        %{
                            There are no matching IDs in the current group.
                            None of these IDs belong to the model
                        %}
                        messenger.writeMessage(101.0)
                    elseif eliminationWarning == 1.0
                        %{
                            There are some unmatched IDs in the current
                            group. These IDs do not belong to the model
                        %}
                        setappdata(0, 'unmatchedIDs', unmatchedIDs)
                        if earlyBreak == 1.0
                            messenger.writeMessage(122.0)
                        else
                            messenger.writeMessage(100.0)
                        end
                    elseif (isempty(groupIDs) == 1.0) && (i > 1.0)
                        %{
                            There are no matching IDs in the current group.
                            These IDs were removed by a previous group
                        %}
                        messenger.writeMessage(102.0)
                    end
                    IDsToDelete(IDsToDelete == 0.0) = []; %#ok<AGROW>
                    IDsToDelete2(IDsToDelete2 == 0.0) = []; %#ok<AGROW>
                    groupIDs(groupIDs == 0.0) = []; %#ok<AGROW>
                    
                    % Add the matching IDs to the group ID cell
                    groupIDBuffer(i).IDs = groupIDs;
                    groupIDBuffer(i).UIDs = length(groupIDs);
                    groupIDBuffer(i).OIDs = IDsInOtherGroup;
                    
                    % Save the list of deleted items
                    deletedMainIDs = [deletedMainIDs, mainIDs_master(IDsToDelete)']; %#ok<AGROW>
                    deletedMainIDIndexes = [deletedMainIDIndexes, IDsToDelete]; %#ok<AGROW>
                    deletedSubIDs = [deletedSubIDs, subIDs_master(IDsToDelete)']; %#ok<AGROW>
                    
                    %{
                        Output the new mainID and subID list which
                        represents the group definition
                    %}
                    mainIDs_master_group = [mainIDs_master_group, mainIDs_master(IDsToDelete)']; %#ok<AGROW>
                    subIDs_master_group = [subIDs_master_group, subIDs_master(IDsToDelete)']; %#ok<AGROW>
                    
                    % From the current group, remove the matching IDs from
                    % the master IDs
                    addressBuffer(IDsToDelete) = [];
                    mainIDs_master(IDsToDelete) = [];
                    subIDs_master(IDsToDelete) = [];
                    
                    %{
                        Modify the address buffer for item ID lists
                    %}
                    addressBuffer_idList(IDsToDelete2) = 0.0;
                    
                    % Warn the user if all IDs were removed
                    if (isempty(addressBuffer) == 1.0) && (i ~= L)
                        %{
                            Subsequent group files will not be read beyond
                            this point. Populate their fields in the
                            groupIDBuffer
                        %}
                        for k = (i + 1.0):L
                            % See if these groups were correctly defined
                            if strcmpi(analysisGroups{k}, 'default') == 0.0
                                [~, ~, ~, error, ~] = group.readFile(analysisGroups{k});
                                if error == 1.0
                                    return
                                end
                            end
                            
                            groupIDBuffer(k).name = analysisGroups{k};
                            groupIDBuffer(k).IDs = [];
                            groupIDBuffer(k).NIDs = 0.0;
                            groupIDBuffer(k).UIDs = 0.0;
                            groupIDBuffer(k).OIDs = 0.0;
                        end
                        
                        messenger.writeMessage(99.0)
                            
                        break
                    end
                    
                    % Save the IDs in the order that the groups were read
                    mainID_groupAll = [mainID_groupAll, mainIDs_group']; %#ok<AGROW>
                    subID_groupAll = [subID_groupAll, subIDs_group'];  %#ok<AGROW>
                else
                    %{
                        The current group is defined as an item ID list.
                        Find matching item IDs with the master dataset
                    %}
                    for j = 1:length(mainIDs_group)
                        %{
                            Check that the current item ID exists in the
                            master ID list
                        %}
                        if (mainIDs_group(j) <= 0.0) || (mainIDs_group(j) > addressBufferLength) || (isempty(intersect(mainIDs_group(j), addressBuffer_idList)))
                            %{
                                The current item ID does not exist in the
                                master ID list. Ignore this ID and continue
                            %}
                            if any(deletedMainIDIndexes == mainIDs_group(j)) ~= 1.0
                                %{
                                    This ID does not belong to the model.
                                    Warn the user
                                %}
                                unmatchedIDs = unmatchedIDs + 1.0;
                                eliminationWarning = 1.0;
                            elseif i == 1.0
                                %{
                                    This ID does not belong to the model.
                                    Warn the user
                                %}
                                unmatchedIDs = unmatchedIDs + 1.0;
                                eliminationWarning = 1.0;
                            else
                                %{
                                    This ID belongs to the model, but was
                                    eliminated by a previous group. No need
                                    to inform the user
                                %}
                                IDsInOtherGroup = IDsInOtherGroup + 1.0;
                            end
                            
                            continue
                        else
                            % Assign the current item ID to the list
                            groupIDs(j) = mainIDs_group(j); %#ok<AGROW>
                        end
                    end
                    
                    %{
                        Warn the user in case unmatched IDs were found in
                        the current group
                    %}
                    if (eliminationWarning == 1.0) && (unmatchedIDs == length(mainIDs_group))
                        %{
                            There are no matching IDs in the current group.
                            None of these IDs belong to the model
                        %}
                        messenger.writeMessage(101.0)
                    elseif eliminationWarning == 1.0
                        %{
                            There are some unmatched IDs in the current
                            group. These IDs do not belong to the model
                        %}
                        setappdata(0, 'unmatchedIDs', unmatchedIDs)
                        messenger.writeMessage(100.0)
                    elseif (isempty(groupIDs) == 1.0) && (i > 1.0)
                        %{
                            There are no matching IDs in the current group.
                            These IDs were removed by a previous group
                        %}
                        messenger.writeMessage(102.0)
                    end
                    
                    % Add the matching IDs to the group ID cell
                    groupIDBuffer(i).IDs = groupIDs;
                    groupIDBuffer(i).UIDs = length(groupIDs);
                    groupIDBuffer(i).OIDs = IDsInOtherGroup;
                    
                    % Save the list of deleted items
                    deletedMainIDs = [deletedMainIDs, addressBuffer_idList(groupIDs)]; %#ok<AGROW>
                    deletedMainIDIndexes = [deletedMainIDIndexes, groupIDs]; %#ok<AGROW>
                    deletedSubIDs = [deletedSubIDs, addressBuffer_idList(groupIDs)]; %#ok<AGROW>
                    
                    %{
                        Output the new mainID and subID list which
                        represents the group definition
                    %}
                    mainIDs_master_group = [mainIDs_master_group, mainID(addressBuffer_idList(groupIDs))']; %#ok<AGROW>
                    subIDs_master_group = [subIDs_master_group, subID(addressBuffer_idList(groupIDs))']; %#ok<AGROW>
                    
                    %{
                        From the current group, remove the matching IDs
                        from the master IDs
                    %}
                    addressBuffer_idList(groupIDs) = 0.0;
                    mainIDs_master(groupIDs) = 0.0;
                    subIDs_master(groupIDs) = 0.0;
                    
                    % Warn the user if all IDs were removed
                    if (any(addressBuffer_idList)) == 0.0 && (i ~= L)
                        %{
                            Subsequent group files will not be read beyond
                            this point. Populate their fields in the
                            groupIDBuffer
                        %}
                        for k = (i + 1.0):L
                            % See if these groups were correctly defined
                            if strcmpi(analysisGroups{k}, 'default') == 0.0
                                [~, ~, ~, error, ~] = group.readFile(analysisGroups{k});
                                if error == 1.0
                                    return
                                end
                            end
                            
                            groupIDBuffer(k).name = analysisGroups{k};
                            groupIDBuffer(k).IDs = [];
                            groupIDBuffer(k).NIDs = 0.0;
                            groupIDBuffer(k).UIDs = 0.0;
                            groupIDBuffer(k).OIDs = 0.0;
                        end
                        
                        messenger.writeMessage(99.0)
                        break
                    end
                    
                    % Save the IDs in the order that the groups were read
                    mainID_groupAll = [mainID_groupAll, mainIDs_group2']; %#ok<AGROW>
                    subID_groupAll = [subID_groupAll, subIDs_group2'];  %#ok<AGROW>
                end
            end
            
            %{
                Check if there are any items remaining. If GROUP was
                defined with the DEFAULT parameter, remaining IDs should
                now be collected into the DEFAULT group
            %}
            if strcmpi(analysisGroups(end), 'default') == 1.0
                %{
                    The DEFAULT group is specified. Assign all remaining
                    analysis IDs to this group
                %}
                
                % Add the DEFAULT IDs to the group ID cell
                groupIDBuffer(end).name = 'DEFAULT';
                groupIDBuffer(end).IDs = addressBuffer;
                groupIDBuffer(end).NIDs = numberOfMasterIDs;
                
                if L == 1.0
                    groupIDBuffer(end).UIDs = length(addressBuffer);
                else
                    UIDs = 0.0;
                    for i = 1:(L - 1.0)
                        UIDs = UIDs + groupIDBuffer(i).UIDs;
                    end
                    groupIDBuffer(end).UIDs = length(mainID) - UIDs;
                end
                
                % Inform the user if the default group is empty
                if isempty(addressBuffer) == 1.0
                    messenger.writeMessage(103.0)
                end
                
                %{
                    The number of DEFAULT IDs in other groups is the
                    sum of the used IDs used in these groups
                %}
                if L == 1.0
                    groupIDBuffer(end).OIDs = 0.0;
                else
                    OIDs = 0.0;
                    for i = 1:(L - 1.0)
                        if isempty(groupIDBuffer(i).UIDs) == 0.0
                            OIDs = OIDs + groupIDBuffer(i).UIDs;
                        end
                    end
                    groupIDBuffer(end).OIDs = OIDs;
                end
                
                %{
                    Output the new mainID and subID list which represents
                    the group definition. Since the DEFAULT group was used,
                    whether alone or in conjunction with user-defined
                    groups, the master ID list is unchanged from the
                    original ID list, since the DEFAULT option is
                    guaranteed to include the whole model
                %}
                
                if isempty(deletedMainIDs) == 0.0
                    mainIDs_master_group = mainID;
                    subIDs_master_group = subID;
                end
                
                mainID_groupAll = [mainID_groupAll, mainID(addressBuffer)'];
                subID_groupAll = [subID_groupAll, subID(addressBuffer)'];
            else
                %{
                    If either deletedMainIDs or deletedSubIDs is empty, this
                    means that no item IDs from the groups match the main
                    model. The analysis cannot continue
                %}
                if isempty(deletedMainIDs) == 1.0 || isempty(deletedSubIDs) == 1.0
                    setappdata(0, 'E079', 1.0)
                    error = 1.0;
                    
                    return
                end
                
                %{
                    Although the DEFAULT group was not requested, add it to
                    the group ID buffer and indicate that no DEFAULT items
                    will be used for the analysis
                %}
                groupIDBuffer(L + 1.0).name = 'DEFAULT';
                groupIDBuffer(L + 1.0).IDs = [];
                groupIDBuffer(L + 1.0).NIDs = numberOfMasterIDs;
                groupIDBuffer(L + 1.0).UIDs = 0.0;
                
                OIDs = 0.0;
                for i = 1:L
                    if isempty(groupIDBuffer(i).UIDs) == 0.0
                        OIDs = OIDs + groupIDBuffer(i).UIDs;
                    end
                end
                groupIDBuffer(L + 1.0).OIDs = OIDs;
                
                %{
                    Since the DEFAULT group was not specified, the total
                    number of analysis items might have changed.
                    Re-calculate the value of N
                %}
                Ni = 0.0;
                for i = 1:L
                    if isempty(groupIDBuffer(i).UIDs) == 0.0
                        Ni = Ni + groupIDBuffer(i).UIDs;
                    end
                end
                N = Ni;
                
                x = find(addressBuffer_idList == 0.0);
                setappdata(0, 'mainID_master', mainID(x))
                setappdata(0, 'subID_master', subID(x))
            end
            
            %{
                The master ID list may be modified if the DEFAULT parameter
                is omitted. Save the original ID list from the master
                dataset which is never modified
            %}
            setappdata(0, 'mainID_original', mainID)
            setappdata(0, 'subID_original', subID)
            
            setappdata(0, 'mainID_groupAll', mainID_groupAll)
            setappdata(0, 'subID_groupAll', subID_groupAll)
            
            if isempty(mainIDs_master_group) == 1.0
                mainIDs_master = mainID;
                subIDs_master = subID;
            else
                mainIDs_master = mainIDs_master_group;
                subIDs_master = subIDs_master_group;
            end
            
            % Commit the groupIDBuffer to the APPDATA
            setappdata(0, 'groupIDBuffer', groupIDBuffer)
            
            % If there were any intersecting IDs, write these to file
            if isempty(intersectingIDBuffer) == 0.0
                root = getappdata(0, 'outputDirectory');
                
                if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                    mkdir(sprintf('%s/Data Files', root))
                end
                
                dir = [root, 'Data Files/warn_group_duplicate_ids.dat'];
                
                fid = fopen(dir, 'w+');
                
                data = [mainID(intersectingIDBuffer)'; subID(intersectingIDBuffer)']';
                
                fprintf(fid, 'WARN_GROUP_DUPLICATE_IDS\r\n');
                fprintf(fid, 'Job:\t%s\r\n', getappdata(0, 'jobName'));
                fprintf(fid, 'Main ID\tSub ID\r\n');
                fprintf(fid, '%.0f\t%.0f\r\n', data');
                fclose(fid);
                
                messenger.writeMessage(117.0)
            end
        end
        
        %% SAVE MATERIAL PROPERTIES
        function [] = saveMaterial(materialNumber)
            %{
                Save the current material into the group material property
                structure array
            %}
            group_materialProps = getappdata(0, 'group_materialProps');
            
            group_materialProps(materialNumber).materialDescription = getappdata(0, 'materialDescription');
            group_materialProps(materialNumber).defaultAlgorithm = getappdata(0, 'defaultAlgorithm');
            group_materialProps(materialNumber).defaultMSC = getappdata(0, 'defaultMSC');
            group_materialProps(materialNumber).fsc = getappdata(0, 'fsc');
            group_materialProps(materialNumber).cael = getappdata(0, 'cael');
            group_materialProps(materialNumber).cael_status = getappdata(0, 'cael_status');
            group_materialProps(materialNumber).E = getappdata(0, 'E');
            group_materialProps(materialNumber).uts = getappdata(0, 'uts');
            group_materialProps(materialNumber).ucs = getappdata(0, 'ucs');
            group_materialProps(materialNumber).poisson = getappdata(0, 'poisson');
            group_materialProps(materialNumber).sValues = getappdata(0, 's_values');
            group_materialProps(materialNumber).sValuesReduced = getappdata(0, 's_values_reduced');
            group_materialProps(materialNumber).nSNDatasets = getappdata(0, 'nSNDatasets');
            group_materialProps(materialNumber).nValues = getappdata(0, 'n_values');
            group_materialProps(materialNumber).rValues = getappdata(0, 'r_values');
            group_materialProps(materialNumber).k = getappdata(0, 'k');
            group_materialProps(materialNumber).ndEndurance = getappdata(0, 'ndEndurance');
            group_materialProps(materialNumber).materialBehavior = getappdata(0, 'materialBehavior');
            group_materialProps(materialNumber).regressionModel = getappdata(0, 'regressionModel');
            group_materialProps(materialNumber).b = getappdata(0, 'b');
            group_materialProps(materialNumber).b2 = getappdata(0, 'b2');
            group_materialProps(materialNumber).b2Nf = getappdata(0, 'b2Nf');
            group_materialProps(materialNumber).Sf = getappdata(0, 'Sf');
            group_materialProps(materialNumber).Ef = getappdata(0, 'Ef');
            group_materialProps(materialNumber).c = getappdata(0, 'c');
            group_materialProps(materialNumber).kp = getappdata(0, 'kp');
            group_materialProps(materialNumber).np = getappdata(0, 'np');
            group_materialProps(materialNumber).twops = getappdata(0, 'twops');
            group_materialProps(materialNumber).TfPrime = getappdata(0, 'TfPrime');
            group_materialProps(materialNumber).Tfs = getappdata(0, 'Tfs');
            group_materialProps(materialNumber).fatigueLimit = getappdata(0, 'fatigueLimit');
            group_materialProps(materialNumber).Kt = getappdata(0, 'kt');
            group_materialProps(materialNumber).KtFileType = getappdata(0, 'ktFileType');
            group_materialProps(materialNumber).KtCurve = getappdata(0, 'ktCurve');
            group_materialProps(materialNumber).strainLimitEnergy = getappdata(0, 'strainLimitEnergy');
            group_materialProps(materialNumber).residualStress = getappdata(0, 'residualStress');
            group_materialProps(materialNumber).frfEnvelope = getappdata(0, 'frfEnvelope');
            group_materialProps(materialNumber).userFRFData = getappdata(0, 'userFRFData');
            group_materialProps(materialNumber).userFRFNormParamMeanT = getappdata(0, 'frfNormParamMeanT');
            group_materialProps(materialNumber).userFRFNormParamMeanC = getappdata(0, 'frfNormParamMeanC');
            group_materialProps(materialNumber).userFRFNormParamAmp = getappdata(0, 'frfNormParamAmp');
            group_materialProps(materialNumber).userEnduranceLimit = getappdata(0, 'userEnduranceLimit');
            group_materialProps(materialNumber).walkerGamma = getappdata(0, 'walkerGamma');
            group_materialProps(materialNumber).snKnockDown = getappdata(0, 'snKnockDown');
            group_materialProps(materialNumber).modifiedGoodman = getappdata(0, 'modifiedGoodman');
            group_materialProps(materialNumber).goodmanLimitStress = getappdata(0, 'goodmanMeanStressLimit');
            group_materialProps(materialNumber).notchSensitivityConstant = getappdata(0, 'notchSensitivityConstant');
            group_materialProps(materialNumber).notchRootRadius = getappdata(0, 'notchRootRadius');
            
            setappdata(0, 'group_materialProps', group_materialProps)
        end
        
        %% RECALL MATERIAL PROPERTIES
        function [] = recallMaterial(materialNumber)
            %{
                Recall the current material into the group material
                property structure array
            %}
            group_materialProps = getappdata(0, 'group_materialProps');
            
            setappdata(0, 'materialDescription', group_materialProps(materialNumber).materialDescription)
            setappdata(0, 'defaultAlgorithm', group_materialProps(materialNumber).defaultAlgorithm)
            setappdata(0, 'defaultMSC', group_materialProps(materialNumber).defaultMSC)
            setappdata(0, 'fsc', group_materialProps(materialNumber).fsc)
            setappdata(0, 'cael', group_materialProps(materialNumber).cael)
            setappdata(0, 'cael_status', group_materialProps(materialNumber).cael_status)
            setappdata(0, 'E', group_materialProps(materialNumber).E)
            setappdata(0, 'uts', group_materialProps(materialNumber).uts)
            setappdata(0, 'ucs', group_materialProps(materialNumber).ucs)
            setappdata(0, 'poisson', group_materialProps(materialNumber).poisson)
            setappdata(0, 's_values', group_materialProps(materialNumber).sValues)
            setappdata(0, 's_values_reduced', group_materialProps(materialNumber).sValuesReduced)
            setappdata(0, 'nSNDatasets', group_materialProps(materialNumber).nSNDatasets)
            setappdata(0, 'n_values', group_materialProps(materialNumber).nValues)
            setappdata(0, 'r_values', group_materialProps(materialNumber).rValues)
            setappdata(0, 'k', group_materialProps(materialNumber).k)
            setappdata(0, 'ndEndurance', group_materialProps(materialNumber).ndEndurance)
            setappdata(0, 'materialBehavior', group_materialProps(materialNumber).materialBehavior)
            setappdata(0, 'regressionModel', group_materialProps(materialNumber).regressionModel)
            setappdata(0, 'b', group_materialProps(materialNumber).b)
            setappdata(0, 'b2', group_materialProps(materialNumber).b2)
            setappdata(0, 'b2Nf', group_materialProps(materialNumber).b2Nf)
            setappdata(0, 'Sf', group_materialProps(materialNumber).Sf)
            setappdata(0, 'Ef', group_materialProps(materialNumber).Ef)
            setappdata(0, 'c', group_materialProps(materialNumber).c)
            setappdata(0, 'kp', group_materialProps(materialNumber).kp)
            setappdata(0, 'np', group_materialProps(materialNumber).np)
            setappdata(0, 'twops', group_materialProps(materialNumber).twops)
            setappdata(0, 'TfPrime', group_materialProps(materialNumber).TfPrime)
            setappdata(0, 'Tfs', group_materialProps(materialNumber).Tfs)
            setappdata(0, 'fatigueLimit', group_materialProps(materialNumber).fatigueLimit)
            setappdata(0, 'kt', group_materialProps(materialNumber).Kt)
            setappdata(0, 'ktFileType', group_materialProps(materialNumber).KtFileType)
            setappdata(0, 'ktCurve', group_materialProps(materialNumber).KtCurve)
            setappdata(0, 'strainLimitEnergy', group_materialProps(materialNumber).strainLimitEnergy)
            setappdata(0, 'residualStress', group_materialProps(materialNumber).residualStress)
            setappdata(0, 'frfEnvelope', group_materialProps(materialNumber).frfEnvelope)
            setappdata(0, 'userFRFData', group_materialProps(materialNumber).userFRFData)
            setappdata(0, 'frfNormParamMeanT', group_materialProps(materialNumber).userFRFNormParamMeanT)
            setappdata(0, 'frfNormParamMeanC', group_materialProps(materialNumber).userFRFNormParamMeanC)
            setappdata(0, 'frfNormParamAmp', group_materialProps(materialNumber).userFRFNormParamAmp)
            setappdata(0, 'userEnduranceLimit', group_materialProps(materialNumber).userEnduranceLimit)
            setappdata(0, 'walkerGamma', group_materialProps(materialNumber).walkerGamma)
            setappdata(0, 'snKnockDown', group_materialProps(materialNumber).snKnockDown)
            setappdata(0, 'modifiedGoodman', group_materialProps(materialNumber).modifiedGoodman)
            setappdata(0, 'goodmanMeanStressLimit', group_materialProps(materialNumber).goodmanLimitStress)
            setappdata(0, 'notchSensitivityConstant', group_materialProps(materialNumber).notchSensitivityConstant)
            setappdata(0, 'notchRootRadius', group_materialProps(materialNumber).notchRootRadius)
        end
        
        %% READ A GROUP FILE
        function [subIDs, mainIDs, fieldData, error, nodeType] = readFile(FILENAME)
            error = 0.0;
            nodeType = 0.0;
            
            %% Open the .rpt file:
            
            fid = fopen(['input/', FILENAME], 'r');
            setappdata(0, 'FOPEN_error_file', FILENAME)
            
            if fid == -1.0
                mainIDs = -999.0;
                subIDs = -999.0;
                error = 1.0;
                fieldData = -999.0;
                setappdata(0, 'E059', 1.0)
                
                return
            end
            
            %% Check if there is a header:
            
            try
                cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
            catch unhandledException
                mainIDs = -999.0;
                subIDs = -999.0;
                error = 1.0;
                setappdata(0, 'E060', 1.0)
                setappdata(0, 'error_log_060_exceptionMessage', unhandledException.identifier)
                
                return
            end
            
            if isempty(cellData{1.0}) == 1.0
                hasHeader = true; % There is a header in the file
            else
                hasHeader = false; % There might be no header in the file
            end
            
            if hasHeader == 0.0
                for i = 1.0:length(cellData)
                    if isempty(cellData{i})
                        hasHeader = true;
                        break
                    end
                end
            end
            
            %% Scan the file:
            
            if hasHeader
                cellData_region = cell(1.0);
                region = 0.0;
                
                while feof(fid) == 0.0
                    % Begin searching the file for the first set of data
                    fgetl(fid);
                    cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
                    
                    if isempty(cellData{1.0}) == 0.0
                        %{
                            A region of data has been found. Add the current
                            region to the nested cell
                        %}
                        region = region + 1.0;
                        cellData_region{region} = cellData;
                    end
                end
                
                %{
                    Concatenate individual regions into single cell if
                    necessary
                %}
                if region > 1.0
                    for region_ID = 1:10
                        %{
                            For each region in the model, concatenate
                            each nested cell
                        %}
                        region_index = 2.0;
                        
                        a = cellData_region{1.0};
                        c = a{region_ID};
                        while region_index <= region
                            a = cellData_region{region_index};
                            c = [c; a{region_ID}]; %#ok<AGROW>
                            
                            region_index = region_index + 1.0;
                        end
                        
                        %{
                            The current column of data has been concatenated
                            for every region. Move on to the next column
                        %}
                        cellData{region_ID} = c;
                    end
                end
            end
            
            %{
                If the REGION variable is undefined, it could be because
                multiple data blocks were specified in the RPT file without
                text headers. Assume a single region in the model
            %}
            if exist('region', 'var') == 0.0
                region = 1.0;
            end
            
            %% Remove unused columns if required:
            
            % Initialize the dataset buffers
            fieldDataBuffer = cell(1.0, region);
            mainIDBuffer = cell(1.0, region);
            subIDBuffer = cell(1.0, region);
            
            if region < 2.0
                region = 1.0;
                cellData_region_i = cellData;
            end
            
            for i = 1:region
                remove = 0.0;
                
                % Get the cell data for the current region
                if region > 1.0
                    cellData_region_i = cellData_region{i};
                end
                
                % Plane stress, shell section data, one position label columns
                if length(cellData_region_i{10.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                elseif isnan(cellData_region_i{10.0})
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                end
                
                % 3D stress, two position label columns
                if length(cellData_region_i{9.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                elseif isnan(cellData_region_i{9.0})
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                end
                
                % 3D stress, one position label column
                if length(cellData_region_i{8.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                elseif isnan(cellData_region_i{8.0})
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                end
                
                % 3D stress, no position label columns
                % OR
                % Plane stress, two position label columns
                if length(cellData_region_i{7.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                elseif isnan(cellData_region_i{7.0})
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                end
                
                % Plane stress, one position label column
                if length(cellData_region_i{6.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                elseif isnan(cellData_region_i{6.0})
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                end
                
                % Plane stress, no position label columns
                if length(cellData_region_i{5.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                elseif isnan(cellData_region_i{5.0})
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                end
                
                % Remove further unnecessary columns
                if length(cellData_region_i{4.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                elseif isnan(cellData_region_i{4.0})
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                end
                if length(cellData_region_i{3.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                elseif isnan(cellData_region_i{3.0})
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                end
                if length(cellData_region_i{2.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                elseif isnan(cellData_region_i{2.0})
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                end
                
                %% Check for concatenation errors:
                
                try
                    fieldData_i = cell2mat(cellData_region_i);
                catch unhandledException
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E061', 1.0)
                    setappdata(0, 'error_log_061_exceptionMessage', unhandledException.message)
                    
                    return
                end
                
                if isempty(fieldData_i)
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E062', 1.0)
                    
                    return
                elseif any(any(isnan(fieldData_i))) || any(any(isinf(fieldData_i)))
                    subIDs = -999.0;
                    mainIDs = -999.0;
                    error = 1.0;
                    setappdata(0, 'E063', 1.0)
                    
                    return
                end
                
                if remove == 9.0
                    fieldData_i(:, 2:10) = [];
                elseif remove == 8.0
                    fieldData_i(:, 3:10) = [];
                elseif remove == 7.0
                    fieldData_i(:, 4:10) = [];
                elseif remove == 6.0
                    fieldData_i(:, 5:10) = [];
                elseif remove == 5.0
                    fieldData_i(:, 6:10) = [];
                elseif remove == 4.0
                    fieldData_i(:, 7:10) = [];
                elseif remove == 3.0
                    fieldData_i(:, 8:10) = [];
                elseif remove == 2.0
                    fieldData_i(:, 9:10) = [];
                elseif remove == 1.0
                    fieldData_i(:, 10) = [];
                end
                
                %% Interpret columns:
                
                %{
                    NODETYPE: Format of nodal information
                    0: No listing. Take item label from row number
                    1: Centroidal or unique nodal
                    2: Element-nodal or integration point
                    -1: Error
                %}
                
                % Get the element type
                elementType = getappdata(0, 'elementType');
                if isempty(elementType)
                    elementType = 0.0;
                elseif isnumeric(elementType) == 0.0
                    elementType = 0.0;
                elseif isnan(elementType) || ~isreal(elementType) || ...
                        isinf(elementType) || ~isreal(elementType)
                    elementType = 0.0;
                end
                
                [R, C] = size(fieldData_i);
                switch C
                    case 10.0
                        nodeType = 2.0;
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = fieldData_i(:, 2.0);
                        setappdata(0, 'dataLabel_group', 10.0)
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 4:2:10) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 3:2:9) = [];
                        end
                        
                        fieldData_i(:, 7:8) = 0.0;
                    case 9.0
                        nodeType = 1.0;
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = linspace(1.0, 1.0, R)';
                        setappdata(0, 'dataLabel_group', 9.0)
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 3:2:9) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 2:2:8) = [];
                        end
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 8.0
                        nodeType = 2.0;
                        
                        mainIDs_i = fieldData_i(:, 1.0);
                        subIDs_i = fieldData_i(:, 2.0);
                        setappdata(0, 'dataLabel_group', 8.0)
                    case 7.0
                        nodeType = 1.0;
                        
                        subIDs_i = linspace(1.0, 1.0, R)';
                        mainIDs_i = fieldData_i(:, 1.0);
                        setappdata(0, 'dataLabel_group', 7.0)
                    case 6.0
                        nodeType = 0.0;
                        
                        if elementType == 0.0
                            subIDs_i = linspace(1.0, 1.0, R)';
                            mainIDs_i = linspace(1.0, R, R)';
                        else
                            mainIDs_i = fieldData_i(:, 1.0);
                            subIDs_i = fieldData_i(:, 2.0);
                            
                            fieldData_i(:, 7:8) = 0.0;
                        end
                        setappdata(0, 'dataLabel_group', 6.0)
                    case 5.0
                        nodeType = 1.0;
                        
                        subIDs_i = linspace(1.0, 1.0, R)';
                        mainIDs_i = fieldData_i(:, 1.0);
                        setappdata(0, 'dataLabel_group', 5.0)
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 4.0
                        nodeType = 0.0;
                        
                        subIDs_i = linspace(1.0, 1.0, R)';
                        mainIDs_i = linspace(1.0, R, R)';
                        setappdata(0, 'dataLabel_group', 4.0)
                        
                        fieldData_i(:, 5:6) = 0.0;
                    case 2.0
                        nodeType = 2.0;
                        
                        subIDs_i = fieldData_i(:, 2.0);
                        mainIDs_i = fieldData_i(:, 1.0);
                        setappdata(0, 'dataLabel_group', 2.0)
                        
                        fieldData_i(:, 3:8) = 0.0;
                    case 1.0
                        nodeType = 1.0;
                        
                        subIDs_i = linspace(1.0, 1.0, R)';
                        mainIDs_i = fieldData_i(:, 1.0);
                        setappdata(0, 'dataLabel_group', 1.0)
                        
                        fieldData_i(:, 2:7) = 0.0;
                    otherwise
                        nodeType = 0.0;
                        subIDs = -999.0;
                        mainIDs = -999.0;
                        error = 1.0;
                        setappdata(0, 'E032', 1.0)
                        
                        return
                end
                
                % Append the data from the current group to the buffers
                fieldDataBuffer{i} = fieldData_i;
                mainIDBuffer{i} = mainIDs_i;
                subIDBuffer{i} = subIDs_i;
            end
            
            %% Concatenate data buffers
            fieldData = cell2mat(fieldDataBuffer');
            mainIDs = cell2mat(mainIDBuffer');
            subIDs = cell2mat(subIDBuffer');
            
            fclose(fid);
        end
        
        %% SWITCH PROPERTIES
        function [N, groupIDs] = switchProperties(currentGroup, groupIDBuffer)
            % If groups aren't being used for analysis, RETURN
            if isempty(getappdata(0, 'analysisGroups')) == 1.0
                return
            end
            
            % Set the material properties to the current group
            group.recallMaterial(currentGroup)
            
            % Get the number of analysis items for the current group
            N = groupIDBuffer.UIDs;
            
            % Get the group IDs for the current group
            groupIDs = groupIDBuffer.IDs;
        end
        
        %% GET THE WORST LIFE FOR EACH ANALYSIS GROUP
        function [] = worstLifePerGroup(life, mainID, subID, groupWorstLife, peekAnalysis)
            %{
                If the analysis was a peek analysis, use the original
                number of groups
            %}
            if peekAnalysis == 1.0
                % Get the number of analysis groups
                G = getappdata(0, 'numberOfGroupsPeek');
            else
                % Get the number of analysis groups
                G = getappdata(0, 'numberOfGroups');
            end
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            for groups = 1:G
                % Get the worst life in the current group
                worstLife = groupWorstLife(groups);
                
                % The the IDs for the current group
                groupIDs = groupIDBuffer(groups).IDs;
                
                % If the group is empty, skip this iteration
                if isempty(groupIDs) == 1.0
                    groupIDBuffer(groups).worstLife = 'N/A';
                    groupIDBuffer(groups).worstLifeMainID = [];
                    groupIDBuffer(groups).worstLifeSubID = [];
                    continue
                end
                               
                % Record value into the group ID buffer
                groupIDBuffer(groups).worstLife = worstLife;
                
                % Worst life index
                worstLifeIndex = find(life == worstLife, 1.0);
                
                % Worst life main/sub IDs for the current group
                groupIDBuffer(groups).worstLifeMainID = mainID(worstLifeIndex);
                groupIDBuffer(groups).worstLifeSubID = subID(worstLifeIndex);
            end
            
            % Save the group ID buffer
            setappdata(0, 'groupIDBuffer', groupIDBuffer)
        end
        
        %% GET THE TENSOR ID FROM THE WORST ANALYSIS ITEM ID
        function [tensorID] = getTensorID(worstAnalysisItem, nodalDamage, mainID, subID)
            
            % Get the position IDs from the worst item IDs
            worstItemMainID = mainID(worstAnalysisItem);
            worstItemSubID = subID(worstAnalysisItem);
            
            x = find(mainID == worstItemMainID);
            
            % Get the original ID list from the master dataset
            mainID_master = getappdata(0, 'mainID_master');
            subID_master = getappdata(0, 'subID_master');
            
            % Find where these IDs are located in the master list
            worstItemMainID_master = find(mainID_master == worstItemMainID);
            worstItemSubID_master = find(subID_master == worstItemSubID);
            intersectingID = intersect (worstItemMainID_master, worstItemSubID_master);
            
            %{
                There could be multiple instances of this ID in the
                master ID list. Iterate over life values corresponding to
                these IDs to confirm the correct ID based on the lowest
                life value
            %}
            try
                if length(intersectingID) > 1.0
                    L = length(x);
                    life = zeros(1.0, L);
                    
                    for i = 1:L
                        life(i) = 1.0/nodalDamage(x(i));
                    end
                    
                    % Get the ID corresponding to the minimum life value
                    minLifeID = find(life == min(life));
                    
                    % Get the tensor ID from minLifeID
                    tensorID = intersectingID(minLifeID); %#ok<FNDSB>
                else
                    % Get the tensor ID from minLifeID
                    tensorID = intersectingID;
                end
            catch unhandledException
                setappdata(0, 'message_166_exceptionMessage', unhandledException.identifier)
                messenger.writeMessage(166.0)
                tensorID = worstAnalysisItem;
            end
        end
        
        %% CHECK FOR ITEMS WHICH WERE REMOVED BY NODAL ELIMINATION
        function [] = checkEliminatedGroupItems(coldItems, mainID, subID, G)
            % Get the position IDs
            mainID_original = getappdata(0, 'mainID_master');
            subID_original = getappdata(0, 'subID_master');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            % Get the path to the output directory
            root = getappdata(0, 'outputDirectory');
            
            % Convert the COLDITEMS variable to match the group item IDs
            coldItems_new = zeros(1.0, length(coldItems));
            for i = 1:length(coldItems)
                id1 = mainID(coldItems(i));
                id2 = subID(coldItems(i));
                x1 = find(mainID_original == id1);
                x2 = find(subID_original == id2);
                x3 = intersect(x1, x2);
                coldItems_new(i) = x3(1.0);
            end
            coldItems = coldItems_new;
            
            if G > 1.0
                for groups = 1:(G - 1.0)
                    % Get the IDs from the current group
                    groupIDs = groupIDBuffer(groups).IDs;
                    
                    % Set the name of the current group
                    setappdata(0, 'currentGroup', groupIDBuffer(groups).name)
                    
                    % Get the short name of the group
                    [~, groupNameShort, ~] = fileparts(groupIDBuffer(groups).name);
                    
                    % Set the current group number
                    setappdata(0, 'currentGroupNumber', groups)
                    
                    % Get potentially eliminated IDs
                    eliminatedItems = intersect(groupIDs, coldItems);
                    
                    % Get the number of eliminated IDs
                    setappdata(0, 'numberOfEliminatedItems', length(eliminatedItems))
                    
                    if isempty(eliminatedItems) == 0.0
                        %{
                            At least one item in this group was removed by
                            nodal elimination. Write a list of these items
                            to file and inform the user
                        %}
                        if length(eliminatedItems) == length(groupIDs)
                            messenger.writeMessage(152.0)
                        else
                            messenger.writeMessage(151.0)
                        end
                        
                        if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                            mkdir(sprintf('%s/Data Files', root))
                        end
                        
                        data = [mainID(eliminatedItems), subID(eliminatedItems)]';
                        
                        dir = [root, sprintf('Data Files/%s_eliminated_items.dat', groupNameShort)];
                        
                        fid = fopen(dir, 'w+');
                        
                        fprintf(fid, [sprintf('ELIMINATED ITEMS'), '\r\n']);
                        fprintf(fid, 'Job:\t%s\r\nGroup name:\t%s\r\nOrder of analysis:\t%.0f\r\n', getappdata(0, 'jobName'), groupNameShort, groups);
                        
                        fprintf(fid, 'Main ID\tSub ID\r\n');
                        fprintf(fid, '%.0f\t%.0f\r\n', data);
                        
                        fclose(fid);
                    end
                end
            end
        end
    end
end
clc;
clear;
close all;

%% =========================================================
% DATASET PATH
% =========================================================

datasetPath = 'pathe where dataset is stored';

%% =========================================================
% READ DIAGNOSIS CSV
% =========================================================

diagnosisFile = fullfile(datasetPath, 'patient_diagnosis.csv');

diagnosisTable = readtable(diagnosisFile, ...
    'Delimiter', ',', ...
    'Format', '%f%s', ...
    'ReadVariableNames', false);

diagnosisTable.Properties.VariableNames = ...
    {'PatientID', 'Condition'};

%% =========================================================
% GET ALL WAV FILES
% =========================================================

wavFiles = dir(fullfile(datasetPath, '*.wav'));

fprintf('Total WAV files : %d\n\n', length(wavFiles));

%% =========================================================
% OUTPUT FOLDER
% =========================================================

outputBase = fullfile(datasetPath, 'Condition_Wise_Split');

if ~exist(outputBase, 'dir')
    mkdir(outputBase);
end

%% =========================================================
% CONDITION COUNTS
% =========================================================

conditionCounts = containers.Map;

%% =========================================================
% PROCESS FILES
% =========================================================

for i = 1:length(wavFiles)

    filename = wavFiles(i).name;

    % Example:
    % 101_1b1_Al_sc_AKGC417L.wav

    parts = split(filename, '_');

    patientID = str2double(parts{1});

    %% Find diagnosis

    idx = diagnosisTable.PatientID == patientID;

    if any(idx)

        % IMPORTANT FIX
        condition = diagnosisTable.Condition{find(idx,1)};

        % Convert to char/string
        condition = char(condition);

    else

        condition = 'Unknown';

    end

    %% Update count

    if isKey(conditionCounts, condition)

        conditionCounts(condition) = ...
            conditionCounts(condition) + 1;

    else

        conditionCounts(condition) = 1;

    end

    %% Create condition folder

    conditionFolder = fullfile(outputBase, condition);

    if ~exist(conditionFolder, 'dir')
        mkdir(conditionFolder);
    end

    %% Copy WAV file

    sourceFile = fullfile(datasetPath, filename);

    destinationFile = fullfile(conditionFolder, filename);

    copyfile(sourceFile, destinationFile);

end

%% =========================================================
% DISPLAY RESULTS
% =========================================================

fprintf('\n====================================\n');
fprintf(' CONDITION-WISE FILE DISTRIBUTION\n');
fprintf('====================================\n');

allConditions = keys(conditionCounts);

for i = 1:length(allConditions)

    cond = allConditions{i};

    fprintf('%-20s : %d files\n', ...
        cond, conditionCounts(cond));

end

fprintf('====================================\n');

%% =========================================================
% SAVE SUMMARY CSV
% =========================================================

conditions = keys(conditionCounts)';
counts = cell2mat(values(conditionCounts))';

summaryTable = table(conditions, counts, ...
    'VariableNames', {'Condition', 'NumFiles'});

summaryCSV = fullfile(outputBase, ...
    'Condition_File_Counts.csv');

writetable(summaryTable, summaryCSV);

fprintf('\nSummary saved at:\n%s\n', summaryCSV);

clc;
clear;
close all;

%% =========================================================
% ICBHI DATASET : CONDITION-WISE WAV FILE SPLITTING
% =========================================================

datasetPath = '';

%% =========================================================
% READ PATIENT DIAGNOSIS FILE
% =========================================================

diagnosisFile = fullfile(datasetPath, 'patient_diagnosis.csv');

diagnosisTable = readtable(diagnosisFile, ...
    'Delimiter', ',', ...
    'Format', '%f%s', ...
    'ReadVariableNames', false);

diagnosisTable.Properties.VariableNames = ...
    {'PatientID', 'Condition'};

%% =========================================================
% GET ALL WAV FILES
% =========================================================

wavFiles = dir(fullfile(datasetPath, '*.wav'));

fprintf('Total WAV files found : %d\n\n', length(wavFiles));

%% =========================================================
% OUTPUT BASE FOLDER
% =========================================================

outputBase = fullfile(datasetPath, '');

if ~exist(outputBase, 'dir')
    mkdir(outputBase);
end

%% =========================================================
% CONDITION COUNTER
% =========================================================

conditionCounts = containers.Map;

%% =========================================================
% PROCESS EACH WAV FILE
% =========================================================

for i = 1:length(wavFiles)

    %% Current file name

    filename = wavFiles(i).name;

    % Example:
    % 101_1b1_Al_sc_AKGC417L.wav

    %% Extract patient ID

    parts = split(filename, '_');

    patientID = str2double(parts{1});

    %% Find disease condition

    idx = diagnosisTable.PatientID == patientID;

    if any(idx)

        condition = diagnosisTable.Condition{find(idx,1)};

        condition = char(condition);

    else

        condition = 'Unknown';

    end

    %% Create disease folder

    conditionFolder = fullfile(outputBase, condition);

    if ~exist(conditionFolder, 'dir')
        mkdir(conditionFolder);
    end

    %% Copy WAV file

    sourceFile = fullfile(datasetPath, filename);

    destinationFile = fullfile(conditionFolder, filename);

    copyfile(sourceFile, destinationFile);

    %% Update counts

    if isKey(conditionCounts, condition)

        conditionCounts(condition) = ...
            conditionCounts(condition) + 1;

    else

        conditionCounts(condition) = 1;

    end

    %% Display progress

    fprintf('Copied: %s --> %s\n', ...
        filename, condition);

end

%% =========================================================
% FINAL SUMMARY
% =========================================================

fprintf('\n====================================\n');
fprintf(' CONDITION-WISE WAV FILE COUNTS\n');
fprintf('====================================\n');

allConditions = keys(conditionCounts);

for i = 1:length(allConditions)

    cond = allConditions{i};

    fprintf('%-20s : %d WAV files\n', ...
        cond, conditionCounts(cond));

end

fprintf('====================================\n');

%% =========================================================
% SAVE SUMMARY CSV
% =========================================================

conditions = keys(conditionCounts)';
counts = cell2mat(values(conditionCounts))';

summaryTable = table(conditions, counts, ...
    'VariableNames', {'Condition', 'NumWavFiles'});

summaryCSV = fullfile(outputBase, ...
    'Condition_Wise_Counts.csv');

writetable(summaryTable, summaryCSV);

fprintf('\nSummary CSV saved at:\n%s\n', summaryCSV);

%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

%% =========================================================
% PATHS
% =========================================================

datasetPath = ';

splitFile = fullfile(datasetPath, 'official_split.txt');

diagnosisFile = fullfile(datasetPath, 'patient_diagnosis.csv');

outputBase = fullfile(datasetPath, '');

%% =========================================================
% CREATE OUTPUT FOLDERS
% =========================================================

mkdir(fullfile(outputBase,'train','COPD'));
mkdir(fullfile(outputBase,'train','Non_COPD'));

mkdir(fullfile(outputBase,'test','COPD'));
mkdir(fullfile(outputBase,'test','Non_COPD'));

%% =========================================================
% READ DIAGNOSIS FILE
% =========================================================

diagnosisTable = readtable(diagnosisFile, ...
    'Delimiter', ',', ...
    'Format', '%f%s', ...
    'ReadVariableNames', false);

diagnosisTable.Properties.VariableNames = ...
    {'PatientID','Condition'};

%% =========================================================
% READ SPLIT FILE MANUALLY
% =========================================================

fid = fopen(splitFile);

splitData = textscan(fid, '%s %s');

fclose(fid);

fileNames = splitData{1};

splitTypes = splitData{2};

%% =========================================================
% COUNTERS
% =========================================================

trainCOPD = 0;
trainNonCOPD = 0;

testCOPD = 0;
testNonCOPD = 0;

%% =========================================================
% MAIN LOOP
% =========================================================

for i = 1:length(fileNames)

    %% File info

    baseName = fileNames{i};

    splitType = lower(splitTypes{i});

    wavName = [baseName '.wav'];

    sourceFile = fullfile(datasetPath, wavName);

    %% Skip if wav missing

    if ~exist(sourceFile, 'file')

        fprintf('Missing file: %s\n', wavName);
        continue;

    end

    %% Extract patient ID

    parts = split(baseName, '_');

    patientID = str2double(parts{1});

    %% Find diagnosis

    idx = diagnosisTable.PatientID == patientID;

    if any(idx)

        condition = diagnosisTable.Condition{find(idx,1)};

        condition = char(condition);

    else

        condition = 'Unknown';

    end

    %% COPD vs Non-COPD

    if strcmpi(condition, 'COPD')

        classLabel = 'COPD';

    else

        classLabel = 'Non_COPD';

    end

    %% Destination folder

    destinationFolder = ...
        fullfile(outputBase, splitType, classLabel);

    %% Copy file

    copyfile(sourceFile, destinationFolder);

    %% Update counters

    if strcmpi(splitType, 'train')

        if strcmpi(classLabel, 'COPD')

            trainCOPD = trainCOPD + 1;

        else

            trainNonCOPD = trainNonCOPD + 1;

        end

    else

        if strcmpi(classLabel, 'COPD')

            testCOPD = testCOPD + 1;

        else

            testNonCOPD = testNonCOPD + 1;

        end

    end

end

%% =========================================================
% FINAL SUMMARY
% =========================================================

fprintf('\n====================================\n');

fprintf('TRAIN SET\n');
fprintf('COPD       : %d\n', trainCOPD);
fprintf('Non_COPD   : %d\n\n', trainNonCOPD);

fprintf('TEST SET\n');
fprintf('COPD       : %d\n', testCOPD);
fprintf('Non_COPD   : %d\n', testNonCOPD);

fprintf('====================================\n');

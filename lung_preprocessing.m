%% Downsampling (NON-CHRONIC)
targetSamplingRate = 4000; % 4kHz
inputDirectory = 'location where non-chronic lung sounds are stored in.wav format';
outputDirectory = 'location where resampled non-chronic .wav files to be stored'; 
files = dir(fullfile(inputDirectory, '*.wav'));
for i = 1:length(files)
    filename = files(i).name;
    inputFilePath = fullfile(inputDirectory, filename);
    [audioSignal, currentSamplingRate] = audioread(inputFilePath);
    resampledSignal = resample(audioSignal, targetSamplingRate, currentSamplingRate);
    lengthSeconds = length(audioSignal) / currentSamplingRate;
    lengthResampled = length(resampledSignal) / targetSamplingRate;
    [~, name, ext] = fileparts(filename);
    outputFilename = ['resampled_', name, ext];
    outputFilePath = fullfile(outputDirectory, outputFilename);
    audiowrite(outputFilePath, resampledSignal, targetSamplingRate);
    fprintf('File: %s\n', filename);
    fprintf('Original sampling rate: %d Hz\n', currentSamplingRate);
    fprintf('Target sampling rate: %d Hz\n', targetSamplingRate);
    fprintf('Length of signal: %.2f seconds\n', lengthSeconds);
    fprintf('Resampled file saved to: %s\n\n', outputFilePath);
end

% Downsampling (CHRONIC)
inputDirectory = 'location where chronic lung sounds are stored in.wav format';
outputDirectory = 'location where resampled chronic.wav files to be stored'; 
files = dir(fullfile(inputDirectory, '*.wav'));
for i = 1:length(files)
    filename = files(i).name;
    inputFilePath = fullfile(inputDirectory, filename);
    [audioSignal, currentSamplingRate] = audioread(inputFilePath);
    resampledSignal = resample(audioSignal, targetSamplingRate, currentSamplingRate);
    lengthSeconds = length(audioSignal) / currentSamplingRate;
    lengthResampled = length(resampledSignal) / targetSamplingRate;
    [~, name, ext] = fileparts(filename);
    outputFilename = ['resampled_', name, ext];
    outputFilePath = fullfile(outputDirectory, outputFilename);
    audiowrite(outputFilePath, resampledSignal, targetSamplingRate);
    fprintf('File: %s\n', filename);
    fprintf('Original sampling rate: %d Hz\n', currentSamplingRate);
    fprintf('Target sampling rate: %d Hz\n', targetSamplingRate);
    fprintf('Length of signal: %.2f seconds\n', lengthSeconds);
    fprintf('Resampled file saved to: %s\n\n', outputFilePath);
end

%% SEGMENTATION
% for non-chronic
segmentDuration = "type the window length in seconds, for example 1,2,3,4,5,6...";
inputDirectory = 'location where resampled non-chronic .wav files were stored';
outputDirectory = 'location where segmented non-chronic .wav files to be stored'; 
files = dir(fullfile(inputDirectory, '*.wav'));
totalSegments = 0;
for i = 1:length(files)
    filename = files(i).name;
    inputFilePath = fullfile(inputDirectory, filename);
    [audioSignal, currentSamplingRate] = audioread(inputFilePath);
    numSegments = floor(length(audioSignal) / (targetSamplingRate * segmentDuration));
    totalSegments = totalSegments + numSegments;
    for j = 1:numSegments
        segmentStart = (j - 1) * targetSamplingRate * segmentDuration + 1;
        segmentEnd = j * targetSamplingRate * segmentDuration;
        segment = audioSignal(segmentStart:segmentEnd);
        
        % Create output file path for segment
        outputFilename = sprintf('segment_%s_%d.wav', filename, j);
        outputFilePath = fullfile(outputDirectory, outputFilename);
        audiowrite(outputFilePath, segment, targetSamplingRate);
    end
end
fprintf('Total number of audio segments created: %d\n', totalSegments);

% for chronic 
segmentDuration = 'type the window length in seconds, for example 1,2,3,4,5,6...';
inputDirectory = 'location where resampled chronic .wav files were stored'; 
outputDirectory = 'location where segmented chronic .wav files to be stored'; 
files = dir(fullfile(inputDirectory, '*.wav'));
totalSegments = 0;
for i = 1:length(files)
    filename = files(i).name;
    inputFilePath = fullfile(inputDirectory, filename);
    [audioSignal, currentSamplingRate] = audioread(inputFilePath);
    numSegments = floor(length(audioSignal) / (targetSamplingRate * segmentDuration));
    totalSegments = totalSegments + numSegments;
    for j = 1:numSegments
        segmentStart = (j - 1) * targetSamplingRate * segmentDuration + 1;
        segmentEnd = j * targetSamplingRate * segmentDuration;
        segment = audioSignal(segmentStart:segmentEnd);
        outputFilename = sprintf('segment_%s_%d.wav', filename, j);
        outputFilePath = fullfile(outputDirectory, outputFilename);
        audiowrite(outputFilePath, segment, targetSamplingRate);
    end
end
fprintf('Total number of audio segments created: %d\n', totalSegments);

%% SAVING DATA AND LABELS IN A STRUCT

Lungsdata = struct();
fixed_size = 'number of samples (for 2 seconds it will be 8000)';
Data = cell("total number of segmented .wav files (chronic+nonchronic)", 1);      
Labels = cell("total number of segmented .wav files (chronic+nonchronic)", 1); 
nonchronic_folder = 'location where the segmented .wav files are stored for non-chronic';
chronic_folder = 'location where the segmented .wav files are stored for chronic';
nonchronic_files = dir(fullfile(nonchronic_folder, '*.wav'));
for i = 1:length(nonchronic_files)
    file_path = fullfile(nonchronic_folder, nonchronic_files(i).name);
    [audio, Fs] = audioread(file_path);
    resampled_audio = resample(audio, 4000, Fs);
    if length(resampled_audio) < fixed_size
        resampled_audio = [resampled_audio; zeros(fixed_size - length(resampled_audio), 1)];
    elseif length(resampled_audio) > fixed_size
        resampled_audio = resampled_audio(1:fixed_size);
    end
    Data{i} = resampled_audio';
    Labels{i} = 'Nonchronic';
end

chronic_files = dir(fullfile(chronic_folder, '*.wav'));
for i = 1:length(chronic_files)
    file_path = fullfile(chronic_folder, chronic_files(i).name);
    [audio, Fs] = audioread(file_path);
    resampled_audio = resample(audio, 4000, Fs);
    if length(resampled_audio) < fixed_size
        resampled_audio = [resampled_audio; zeros(fixed_size - length(resampled_audio), 1)];
    elseif length(resampled_audio) > fixed_size
        resampled_audio = resampled_audio(1:fixed_size);
    end
    Data{i+length(nonchronic_files)} = resampled_audio';
    Labels{i+length(nonchronic_files)} = 'Chronic';
end
Data = cell2mat(Data);
Lungsdata.Data = Data;
Lungsdata.Labels = Labels;

%% TFR Generation using CWT
imageRoot = "path to the folder where CWT TFRs images to be stored";
if ~exist(imageRoot,'dir')
    mkdir(imageRoot);
end
folderLabels = unique(Lungsdata.Labels);
for i = 1:numel(folderLabels)
    mkdir(fullfile(imageRoot,char(folderLabels(i))));
end
%
data = Lungsdata.Data;
labels = Lungsdata.Labels;
Fs = 4000;
num_signals = size(data,1);
imf_storage = struct('IMFs',cell(1,num_signals));

%% Process each signal using VMD
for i = 1:num_signals
    sig = data(i,:);
    [imf,~] = vmd(sig,'NumIMFs',5);
    imf_storage(i).IMFs = imf;
    fprintf('Processed signal %d out of %d\n',i,num_signals);

end
[~,signalLength] = size(data);
fb = cwtfilterbank( ...
    'SignalLength',signalLength, ...
    'VoicesPerOctave',12);
r = size(data,1);
for ii = 1:r
    % Extract IMF5 and IMF4
    first_imf  = imf_storage(ii).IMFs(:,5);
    second_imf = imf_storage(ii).IMFs(:,4);
    third_imf = imf_storage(ii).IMFs(:,3);
    fourth_imf = imf_storage(ii).IMFs(:,2);
    fifth_imf = imf_storage(ii).IMFs(:, 1);
    sum_imf = first_imf + second_imf + third_imf + fourth_imf + fifth_imf;
    cfs = abs(fb.wt(sum_imf));
    im = ind2rgb(round(rescale(cfs,0,255)),jet(128));
    imgLoc = fullfile(imageRoot,char(labels(ii)));
    if ~exist(imgLoc,'dir')
        mkdir(imgLoc);
    end
    imFileName = sprintf('%s_%d_sum.jpg',char(labels(ii)),ii);
    fullPath = fullfile(imgLoc,imFileName);
    imwrite(imresize(im,[227 227]),fullPath);
    fprintf('Saved scalogram for signal %d: %s\n',ii,fullPath);
end

disp('All scalogram images saved successfully.');
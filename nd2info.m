function Info = nd2info(filename)
%ND2INFO Returns brief info of ND2 file.
%   Brief info includes the filename, capturing date, image size, total
%   number of images, fps, optics, scales and imaging dimensions.

% Create Nd2Reader object
f = Nd2Reader(filename);

[filepath, name, ext] = fileparts(filename);
MetaData = f.getmetadata();
imageInfo = f.getimageinfo();

Info.filepath = filepath;
Info.name = [name ext];
Info.height = imageInfo.height;
Info.width = imageInfo.width;
Info.nChannels = imageInfo.components;

if strcmp(ext, '.tif')
    Info.nImg = length(imfinfo(filename));
else
    Info.nImg = f.getnimg();
end

try
    Info.date = f.gettextinfo().date;
catch
end

try
    [Info.fps, Info.period, Info.duration] = nd2fps(f, Info.nImg);
catch
end

try
    Info.Dimensions = f.getdimensions();
catch
end

%   Determine the objective from 1. filename and 2. metadata.
expression = '^\d+(?=x_)|(?<=_)\d+(?=x_)|(?<=_)\d+(?=x$)';
% Check if the filename includes the form of objective. _10x _10x_ 10x_
objective = regexpi(name, expression,'match');
if ~isempty(objective)
    Info.objectiveFromFilename = str2double(objective{1});
    Info.scaleFromFilename = 6.5/Info.objectiveFromFilename;
end

try
    Info.objectiveFromMetaData = MetaData.channels(1).microscope.objectiveMagnification;
    Info.scaleFromMetaData = MetaData.channels(1).volume.axesCalibration(1);
catch
end

f.close();
end

function [fps, period, duration] = nd2fps(f, nImg)
% ND2FPS Extracts frames per second (fps), period, and duration from ND2 file.

if ischar(f.getexperiment()) && strcmp(f.getexperiment(), 'N/A')
    [fps, period, duration] = deal('N/A');
    return
end

Experiment = f.getexperiment();
type = {Experiment.type};

if any(strcmp(type, 'TimeLoop'))
    parameters = Experiment(strcmp(type, 'TimeLoop' )).parameters;
    if parameters.periodMs == 0
        period = round(parameters.periodDiff.avg, 2)/1000; % fast time lapse
        fps = 1/period;
        duration = period * nImg;
    else
        period = parameters.periodMs/1000; % ND acquisition (s)
        fps = 1/period;
        duration = f.getframemetadata(nImg-1).time/1000;
        if duration == 0 % bug
            duration = period * (nImg-1);  % (s)
        end
    end
elseif any(strcmp(type, 'NETimeLoop'))
    parameters = Experiment(strcmp(type, 'NETimeLoop' )).parameters;
    if  isfield(parameters,'periods')
        period = [([parameters.periods.periodMs]/1000)' [parameters.periods.count]'];
    elseif isfield(parameters,'periodMs')
        period = [(parameters.periodMs/1000) nImg]; % some bad cases
    end
    fps = [1./period(:,1) period(:,2)];
    
    if size(period,1) == 1
        period = period(1);
        fps = 1/period;
    end
    duration = f.getframemetadata(nImg-1).time/1000;
end
end

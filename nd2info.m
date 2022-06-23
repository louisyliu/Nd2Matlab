function Info = nd2info(filename)
%ND2INFO Returns brief info of ND2 file.
%   Brief info includes the filename, capturing date, image size, total
%   number of images, fps, optics, scales and imaging dimensions.
%   To see the more info, use ND2ALLINFO.
f = Nd2Reader(filename);
[filepath, name, ext] = fileparts(filename);
MetaData = f.getmetadata;
% [Info.scale] = deal(zeros(size(MetaData.channels, 1), 1));

Info.filepath = filepath;
Info.name = [name ext];
Info.height = f.getimageinfo.height;
Info.width = f.getimageinfo.width;
Info.nChannels = f.getimageinfo.components;
if strcmp(ext, '.tif')
    Info.nImg = length(imfinfo(filename));
else
    Info.nImg = f.getattributes.sequenceCount;
end
try
    Info.date = f.gettextinfo.date;
    [Info.fps, Info.period, Info.duration] = nd2fps(f);
    Info.Dimensions = f.getdimensions;
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
    Info.objectiveFromMetaData = MetaData.channels(1).microscope.objectiveMagnification;
    Info.scaleFromMetaData = MetaData.channels(1).volume.axesCalibration(1);
% end
f.close();
end

function [fps, period, duration] = nd2fps(f)
if ischar(f.getexperiment) && strcmp(f.getexperiment, 'N/A')
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
        duration = period * f.getattributes.sequenceCount;
    else
        period = parameters.periodMs/1000; % ND acquisition (s)
        fps = 1/period;
        duration = f.getframemetadata(f.getattributes.sequenceCount-1).time/1000;
    end
elseif any(strcmp(type, 'NETimeLoop'))
    parameters = Experiment(strcmp(type, 'NETimeLoop' )).parameters;
    period = [([parameters.periods.periodMs]/1000)' [parameters.periods.count]'];
    fps = [1./period(:,1), period(:,2)];
    duration = f.getframemetadata(f.getattributes.sequenceCount-1).time/1000;
end
end

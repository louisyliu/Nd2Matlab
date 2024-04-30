function timeSeq = nd2time(filename, varargin)
%ND2TIME Returns the time sequences of movie.
%   Detailed explanation goes here
f = Nd2Reader(filename);

if nargin == 1
    seqNo = 1:f.getattributes.sequenceCount;
elseif nargin == 2
    seqNo = varargin{1};
else
    error('Wrong number of arguments.');
end

flag = false;

iCurrent = 0;
% nTot = numel(seqNo);

timeSeq = zeros(length(seqNo), 1, 'single');
for iImg = seqNo
    iCurrent = iCurrent+1;
    timeSeq(iCurrent) = f.getframemetadata(iImg).time;
    if iCurrent == 2 && timeSeq(iCurrent) ==0
        flag = true;
        break
    end
end

% if bug, calculate the time from fps
if flag
    Experiment = f.getexperiment();
    type = {Experiment.type};
    if any(strcmp(type, 'TimeLoop'))
        parameters = Experiment(strcmp(type, 'TimeLoop' )).parameters;
        if parameters.periodMs == 0
            period = round(parameters.periodDiff.avg, 2); % fast time lapse (ms)
        else
            period = parameters.periodMs; % ND acquisition (ms)
        end
    end
    timeSeq = (0:length(seqNo)-1)'*period;
end

f.close();
end

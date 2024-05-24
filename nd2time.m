function timeSeq = nd2time(filename, varargin)
%ND2TIME Returns the time sequences of movie.

%   Open the nd2 file
f = Nd2Reader(filename);

% Get the sequence numbers
if nargin == 1
    seqNo = 1:f.getattributes.sequenceCount;
elseif nargin == 2
    seqNo = varargin{1};
else
    error('Wrong number of arguments.');
end

% Initialize variables
nSeq = length(seqNo);
timeSeq = zeros(nSeq, 1, 'single');

% Check if there is a bug (time is zero for the second frame)
if nSeq > 1 && f.getframemetadata(seqNo(2)).time == 0
    % Get the experiment details
    Experiment = f.getexperiment();
    type = {Experiment.type};
    
    % Determine the period based on the experiment type
    if any(strcmp(type, 'TimeLoop'))
        parameters = Experiment(strcmp(type, 'TimeLoop' )).parameters;
        if parameters.periodMs == 0
            period = round(parameters.periodDiff.avg, 2); % fast time lapse (ms)
        else
            period = parameters.periodMs; % ND acquisition (ms)
        end
    elseif any(strcmp(type, 'NETimeLoop'))
        parameters = Experiment(strcmp(type, 'NETimeLoop' )).parameters;
        if  isfield(parameters,'periods')
            period = [parameters.periods.periodMs' parameters.periods.count'];
        elseif isfield(parameters,'periodMs')
            period = parameters.periodMs; % some bad cases
        end
    end
    
    % Calculate the time sequence based on the period
    if size(period,1) == 1
        period = period(1);
        timeSeq = (0:nSeq-1)'*period;
    else
        nImgPreviousT = 0;
        for i = 1:size(period,1)
            nImgCurrentT = period(i,2);
            timeSeq(nImgPreviousT+1:nImgPreviousT+nImgCurrentT) = [timeSeq; (nImgPreviousT:nImgPreviousT+nImgCurrentT-1)'*period(i,1)];
            nImgPreviousT = nImgCurrentT;
        end
    end
else
    % Normal case: get the frame metadata for the specified sequence numebers
    for iImg = 1:nSeq
        idx = seqNo(iImg);
        timeSeq(iImg) = f.getframemetadata(idx).time;
    end
end

f.close();
end

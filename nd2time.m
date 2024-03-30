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

iCurrent = 0;
% nTot = numel(seqNo);

timeSeq = zeros(length(seqNo), 1, 'single');
for iImg = seqNo
    iCurrent = iCurrent+1;
    timeSeq(iCurrent) = f.getframemetadata(iImg).time;
end

f.close();
end

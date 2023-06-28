function img = nd2read(filename, varargin)
%ND2READ Reads images of ND2 of TIFFs format.
%   Detailed explanation goes here
f = Nd2Reader(filename);
ImgInfo = f.ImageData;

if nargin == 1
    seqNo = 1:f.getattributes.sequenceCount;
elseif nargin == 2
    if isrow(varargin{1})
        seqNo = varargin{1};
    else
        seqNo = varargin{1}';
    end
else
    error('Wrong number of arguments.');
end

if any(seqNo>f.getnimg)
    error('Image index out of range.');
end

iCurrent = 0;
nTot = numel(seqNo);
bits = f.ImageData.uiBitsPerComp;
if bits <= 16 && bits > 8 % in case of 12 bits
    bits = 16;
end
strbits = ['uint' num2str(bits)];

if ImgInfo.uiComponents == 1  % creating 3D array is much faster than 4D.
    img = zeros(ImgInfo.uiHeight, ImgInfo.uiWidth,  length(seqNo), strbits);
    for iImg = seqNo
        iCurrent = iCurrent+1;
        img(:,:,iCurrent) = f.getimage(iImg);
        if nTot ~= 1
            dispbar(iCurrent, nTot);
        end
    end
else
    img = zeros(ImgInfo.uiHeight, ImgInfo.uiWidth, ImgInfo.uiComponents,  length(seqNo), strbits);
    for iImg = seqNo
        iCurrent = iCurrent+1;
        img(:,:,:,iCurrent) = f.getimage(iImg);
        if nTot ~= 1
            dispbar(iCurrent, nTot);
        end
    end
end

f.close();
end
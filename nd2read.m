function img = nd2read(filename, varargin)
% ND2READ reads images from ND2 files.
% This function provides a convenient way to read image data from ND2 
% files. It supports reading specific image sequences and handles different
% bit depths. The output is returned as a 3D or 4D array, depending on the
% number of color components in the image.
%
% Usage:
%   img = nd2read(filename)
%   img = nd2read(filename, seqNo)
%
% Inputs:
%   filename - Path to the ND2 or TIFF file.
%   seqNo    - (Optional) Image sequence numbers to read. Default is all.
%
% Output:
%   img - 3D or 4D array containing the image data.
%
% Example:
%   img = nd2read('sample.nd2', 1:10);
%
% Dependencies:
%   - Nd2Reader class for reading ND2 files.
%   - dispbar function for displaying progress (optional).

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

% check if there is dispbar
dispbarExist = ~isempty(which('dispbar'));
if ~dispbarExist
    warning(" 'dispbar' not found. ");
end

if ImgInfo.uiComponents == 1  % creating 3D array is much faster than 4D.
    img = zeros(ImgInfo.uiHeight, ImgInfo.uiWidth,  length(seqNo), strbits);
    for iImg = seqNo
        iCurrent = iCurrent+1;
        img(:,:,iCurrent) = f.getimage(iImg);
        if dispbarExist && nTot ~= 1
            dispbar(iCurrent, nTot);
        end
    end
else
    img = zeros(ImgInfo.uiHeight, ImgInfo.uiWidth, ImgInfo.uiComponents,  length(seqNo), strbits);
    for iImg = seqNo
        iCurrent = iCurrent+1;
        img(:,:,:,iCurrent) = f.getimage(iImg);
        if dispbarExist && nTot ~= 1
            dispbar(iCurrent, nTot);
        end
    end
end

f.close();
end
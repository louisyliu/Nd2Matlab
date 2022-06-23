function seqNo = coordconvert(Dimensions, options)
%COORDCONVERT Converts the coordinates into sequence index.
%   To obtain the dimension size, use dimensionsize.
%   Dimensions is obtained from Nd2Reader f.getDimensions.
%   {Ranks: ZStackLoop < XYPosLoop < NETimeLoop (or TimeLoop) }
arguments
    Dimensions struct = []
    options.T (1,:) {mustBePositive, mustBeInteger} = []
    options.XY (1,:) {mustBeNumeric, mustBeInteger} = []
    options.Z (1,:) {mustBePositive, mustBeInteger} = []
end

count = [Dimensions.count];
type = {Dimensions.type};
sz = count(end:-1:1);

iVar = 0;

if any(contains(type, 'Z'))
    iVar = iVar + 1;
    if isempty(options.Z)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = options.Z;
    end
    count(end) = [];
end

if any(contains(type, 'XY'))
    iVar = iVar + 1;
    if isempty(options.XY)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = options.XY;
    end
    count(end) = [];
end

if any(contains(type, 'T'))
    iVar = iVar + 1;
    if isempty(options.T)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = options.T;
    end
end

if length(inVar) > 1
    [inVar{:}] = meshgrid(inVar{:});
    index = sub2ind(sz, inVar{:});
    seqNo = unique(index(:))';
elseif length(inVar) == 1
    seqNo = inVar{1};
else
    error('Error: Wrong number of arguments. ');
end

end


function seqNo = coordconvert2019(Dimensions, XY, Z, T)
%COORDCONVERT Converts the coordinates into sequence index.
%   To obtain the dimension size, use dimensionsize.
%   Dimensions is obtained from Nd2Reader f.getDimensions.
%   {Ranks: ZStackLoop < XYPosLoop < NETimeLoop (or TimeLoop) }

count = [Dimensions.count];
type = {Dimensions.type};
sz = count(end:-1:1);

iVar = 0;

if any(contains(type, 'Z'))
    iVar = iVar + 1;
    if isempty(Z)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = Z;
    end
    count(end) = [];
end

if any(contains(type, 'XY'))
    iVar = iVar + 1;
    if isempty(XY)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = XY;
    end
    count(end) = [];
end

if any(contains(type, 'T'))
    iVar = iVar + 1;
    if isempty(T)
        inVar{iVar} = 1:count(end);
    else
        inVar{iVar} = T;
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


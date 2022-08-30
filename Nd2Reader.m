classdef Nd2Reader
    %ND2READER Access to the proprietary ND2 files as well as TIFFs based
    %on Nd2ReadSdk provided in https://www.nd2sdk.com/.
    %   Provide a interface to access all metadata including attributes,
    %   frame (images) cooridnates, coordinate dimensions, images,
    %   experiment info, image info, and text info.

    properties
        fHandle; % File handle to access.
        ImageData; % The LIMPICTURE structure.
        pPicture;  % The pointer to LIMPICTURE structure.
    end

    methods
        function obj = Nd2Reader(filename)
            %ND2READER Constructs an instance of this class.
            %   Opens an ND2 file for reading.
            if ~libisloaded('nd2readsdk')
                warning('off');
                tempdir = fileparts(mfilename("fullpath"));
                imread([tempdir '\img\preloadimg.tif']); % Required!! To resolve the conflict of built-in .tif-related function.  
                [~,~] = loadlibrary('nd2readsdk',@nd2proto);
                warning('on');
            end

            filenameUtf8 = libpointer('voidPtr', [int8(filename) 0]);
            obj.fHandle = calllib('nd2readsdk', 'openfile', filenameUtf8);
            if isNull(obj.fHandle)
                error('Cannot open file!');
            end

            obj.pPicture = libstruct('s_LIMPICTURE', {});
            [~, ~, obj.ImageData] = calllib('nd2readsdk', 'getimage', obj.fHandle, 0, obj.pPicture);
            bits = obj.ImageData.uiBitsPerComp; % determine bit
            if bits == 16
                setdatatype(obj.ImageData.pImageData, 'uint16Ptr', obj.ImageData.uiSize/2);
            elseif bits == 8
                setdatatype(obj.ImageData.pImageData, 'uint8Ptr', obj.ImageData.uiSize);
            end
        end

        function Attributes = getattributes(obj)
            %  Returns attributes as struct.
            attributesPointer = calllib('nd2readsdk', 'getattributes', obj.fHandle);
            Attributes = nd2strfind(attributesPointer);
            calllib('nd2readsdk', 'freestr', attributesPointer); % Deallocates the string
        end

        function Coordinates = getcoordinates(obj)
            %   Returns all frame coordinates.
            Dimensions = obj.getdimensions();
            seqNo = 1:obj.getattributes.sequenceCount;
            seqNo = seqNo';
            nDimensions = size(Dimensions, 1);
            sizeDimensions = [Dimensions.count];
            outVar = cell(1, nDimensions);
            [outVar{:}] = ind2sub(fliplr(sizeDimensions), seqNo);
            Coordinates.seqNo = uint16(seqNo);
            for i = 1:nDimensions
                Coordinates.(Dimensions(i).type) = uint16(outVar{nDimensions+1-i});
            end
            Coordinates = struct2table(Coordinates);
        end

        function Dimensions = getdimensions(obj)
            %   Extracts dimensions from the text info.  This method is
            %   more avialible than that provided in the sdk.
            nDimensions = calllib('nd2readsdk', 'getcoordsize', obj.fHandle);
            if nDimensions == 1 || nDimensions == 0
                if obj.getattributes.sequenceCount == 1
                    Dimensions = 'N/A';
                    return
                else % fix the bug of zero dimension for multiple frames. Extract the dimension from the text info.
                    description = obj.gettextinfo.description;
                    temp = extractAfter(description, 'Dimensions:');
                    dimensionStr = split(extractBefore(temp, 'Camera'), 'x');
                    nDimensions = size(dimensionStr, 1);

                    Dimensions = struct;
                    for iDimension = 1:nDimensions
                        num = dimensionStr{iDimension};
                        character = dimensionStr{iDimension};
                        num(num<'0' | num>'9') = '';
                        character(character =='(' | character ==')' | (character>='0' & character<='9')) = '';
                        character = strtrim(character);
                        if  strcmp(character, 'T')
                            character = 'TimeLoop';
                        elseif strcmp(character, 'T''')
                            character = 'NETimeLoop';
                        elseif strcmp(character, 'XY')
                            character = 'XYPosLoop';
                        elseif  strcmp(character, 'Z')
                            character = 'ZStackLoop';
                        else
                            continue;
                        end
                        Dimensions(iDimension,1).nestingLevel = iDimension-1;
                        Dimensions(iDimension,1).type = character;
                        Dimensions(iDimension,1).count = str2double(num);
                    end
                end
            else
                Dimensions = struct;
                for iDimensions = nDimensions-1:-1:0
                    buffer = libpointer('int8Ptr', zeros(1024, 1));
                    countRequested = calllib('nd2readsdk', 'getcoordinfo', obj.fHandle, iDimensions, buffer, 1024);
                    dimensionName = deblank(char(buffer.Value'));
                    Dimensions(iDimensions+1, 1).nestingLevel = iDimensions;
                    Dimensions(iDimensions+1, 1).type = dimensionName;
                    Dimensions(iDimensions+1, 1).count = countRequested;
                end
            end
        end

        function image = getimage(obj, seqIndex)
            %   Returns image data.
            [~, ~, obj.ImageData] = calllib('nd2readsdk', 'getimage', obj.fHandle, seqIndex-1, obj.pPicture);

            if obj.ImageData.uiComponents == 1 % creating 3D array is faster than 4D
                image = reshape(obj.ImageData.pImageData, obj.ImageData.uiWidth, obj.ImageData.uiHeight)';
            else
                image = permute(reshape(obj.ImageData.pImageData, [obj.ImageData.uiComponents, obj.ImageData.uiWidth, obj.ImageData.uiHeight]), [3 2 1]);
            end
        end

        function Experiment = getexperiment(obj)
            %   Returns experiment as struct.
            %   Fix the bug by reading the dimension from the text info:
            %   zero dimension still has multiple frames.
            expPointer = calllib('nd2readsdk', 'getexp', obj.fHandle);
            try
                % dimension is nonzero.
                Experiment = nd2strfind(expPointer);
                Nettimeloop = Experiment(1);
                if length(Experiment) ~= length(obj.getdimensions)
                    error('Error: Experiment size does not match the dimension size. ');
                end
            catch
                if obj.getattributes.sequenceCount == 1
                    % 0 dimension and 1 frame. (normal case)
                    Experiment = 'N/A';
                else
                    % 0 dimension and multiple frames.
                    Dimensions = obj.getdimensions;
                    nDimensions = size(Dimensions, 1);
                    Experiment = struct(Dimensions);
                    Experiment(1).parameters = [];
                    count = [Dimensions.count];
                    for iDim = 1:nDimensions
                        if iDim+1 <= nDimensions
                            intervalFrame = prod(count(iDim+1:end));
                        else
                            intervalFrame = 1;
                        end
                        para = [];
                        % Add the filed {parameters} to struct {Experiment}
                        if strcmp(Experiment(iDim).type, 'TimeLoop')
                            % Add duration and period.
                            para.durationMs = obj.getframemetadata(obj.getattributes.sequenceCount-1).time;
                            try
                                para.periodMs = round(obj.getframemetadata(intervalFrame+1).time-obj.getframemetadata(1).time, -1);
                            catch
                                break
                            end
                        elseif strcmp(Experiment(iDim).type, 'NETimeLoop')
                            try
                                para = Nettimeloop.parameters;
                            catch
                                para.durationMs = obj.getframemetadata(obj.getattributes.sequenceCount).time;
                                para.periodMs = round(obj.getframemetadata(intervalFrame+1).time-obj.getframemetadata(1).time, -1);
                            end

                        elseif strcmp(Experiment(iDim).type, 'XYPosLoop')
                            for iPos = 1:count(iDim)
                                try
                                    % Add stage position.
                                    para.points(iPos,1).stagePositionUm = obj.getframemetadata(intervalFrame*(iPos-1)+1).position;
                                catch
                                    break
                                end
                            end
                        end
                        Experiment(iDim).parameters = para;
                    end
                end
            end
            calllib('nd2readsdk', 'freestr', expPointer); % Deallocates the string
        end

        function ImageInfo = getimageinfo(obj)
            %   Returns experiment as struct. (not recommended; use
            %   {obj.ImageData}).
            %   Note: .bitdepth cannot show the bitdepth of raw image. Both
            %   12bits and 16bits show 16bits here.
            ImgInfoAll = obj.ImageData;
            ImageInfo.width = ImgInfoAll.uiWidth;
            ImageInfo.height = ImgInfoAll.uiHeight;
            ImageInfo.components = ImgInfoAll.uiComponents;
            ImageInfo.bitdepth = ImgInfoAll.uiBitsPerComp;
        end

        function Metadata = getmetadata(obj)
            %   Returns metadata as struct.  Channel = Component
            metadataPointer = calllib('nd2readsdk', 'getmeta', obj.fHandle);
            Metadata = nd2strfind(metadataPointer);
            calllib('nd2readsdk', 'freestr', metadataPointer); % Deallocates the string
        end

        function FrameMetadata = getframemetadata(obj, seqIndex)
            %   Returns metadata as struct.
            %   Add position and time.
            metadataPointer = calllib('nd2readsdk', 'getimagemeta', obj.fHandle, seqIndex-1);
            temp = nd2strfind(metadataPointer);
            FrameMetadata.position = temp.channels(1).position.stagePositionUm;
            FrameMetadata.time = temp.channels(1).time.relativeTimeMs;
            calllib('nd2readsdk', 'freestr', metadataPointer); % Deallocates the string
        end

        function TextInfo = gettextinfo(obj)
            %   Returns metadata as struct with fields of capturing, date,
            %   description, optics.  Type TextInfo.{filedname} to navigate
            %   the formatted text info.
            textInfoPointer = calllib('nd2readsdk', 'gettextinfo', obj.fHandle);
            TextInfo = nd2strfind(textInfoPointer);
            calllib('nd2readsdk', 'freestr', textInfoPointer); % Deallocates the string
        end

        function nImg = getnimg(obj)
            %   Returns the number of image sequences from attributes
            %   (shortcut).
            nImg = getattributes(obj).sequenceCount;
        end

        function close(obj)
            %   Closes a file previously opened by this SDK.
            calllib('nd2readsdk', 'closefile', obj.fHandle);
            calllib('nd2readsdk', 'destroypic', obj.pPicture); % Deallocates resources
            % unloadlibrary('nd2readsdk');
        end

    end
end

function Out = nd2strfind(strPointer)
%ND2STRDECODE Finds the complete property and decode the json from
%lib.pointer.
%  strPointer: lib.pointer.
%  Out: struct decoded from json where the string starts at lib.pointer and
%  end with null terminator.

testLength = 1000;
strLength = [];
while isempty(strLength)
    testLength = testLength * 2;
    setdatatype(strPointer, 'int8Ptr', testLength)
    strPointerValue = strPointer.Value';
    strLength = find(strPointerValue == 0, 1);
end

Out = char(strPointerValue(1:strLength-1));
Out = jsondecode(Out);
end

# ![Nd2SdkMatlab](/img/logo.png)

![license](https://img.shields.io/badge/License-MIT-blue)

To read `.nd2` file in MATLAB as easy as possible.

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

> Nd2SdkMatlab consists of an [ND2SDK](https://www.nd2sdk.com/) by [Laboratory Imaging s.r.o.](https://www.laboratory-imaging.com) and several Matlab scripts.  It only supports for __Windows__ system.

- __Matlab__

- __MinGW-w64 Complier__ ('Home' --> 'Add-Ons') to load the libraries in Matlab.

### Installation Options

1. Install with [`git`](https://git-scm.com/)

   ```sh
    git clone https://github.com/tytghy/Nd2SdkMatlab.git
    ```

2. Download ZIP from [Nd2SdkMatlab](https://github.com/tytghy/Nd2SdkMatlab) and unzip the files.  

## Usage

### `nd2read()`

Safe to load the images.

```matlab
IMG = nd2read(FILENAME);         % Read the entire movie. 

IMG = nd2read(FILENAME, i);      % Read the i-th image. 

IMG = nd2read(FILENAME, i:j);    % Read images ranging from the i-th to j-th frames.
```

> __Note__  
>
> - As `nd2read` includes the following commands (open file --> read image data --> close file), it is strongly suggested that using [`.getimage`](#fgetimage) below to reduce the running time if you repeatedly read image data from the same file.
>  
> - The i-th image does not mean the image in Time = i, if you have more than one $XY$ position or one $Z$ position.  Try to find out the image index with [`coordconvert`](#coordconvert-and-coordconvert2019) (R2019b or later releases) and [`coordconvert2019`](#coordconvert-and-coordconvert2019) (R2019a or ealier releases) for multiple $XY/Z$ channels.
>
> - For one $\lambda$ channel, `IMG` is an array of size $height \times width \times time$.  For two or more $\lambda$ channels, `IMG` is an array of size  $height \times width \times \lambda \times time$.

### `nd2info()`

Quick to scan the metadata.

``` matlab
INFO = nd2info(FILENAME)    % Read the brief information of .nd2 file.
```

> __Note__
>
> - `nd2info` automatically reads objective and time series from the file metadata.  The objective from the metadata stores in `INFO.objectiveFromMetadata`, and the objective from the filename stores in `INFO.objectiveFromFilename`.
>
> - `nd2info` reads filename and recognizes the keyword `_?x_`, `?x_` and ``_?x.nd2`` as `INFO.objectiveFromFilename`.  E.g., `INFO.objectiveFromFilename = 20` for the filename of *'20x_cell.nd2', 'cell_20x.nd2', 'cell_20x_liquid.nd2'*.
>
> - A 6.5 µm pixel camera sensor is used by default.  This means that with a 10x objective, the pixel size at the image is in fact 6.5/10 = 0.65 µm.

### `nd2time()`

Obtain time series of the file.

```matlab
IMG = nd2time(FILENAME)         % Read the time sequence of entire movie. 

IMG = nd2time(FILENAME, i)      % Read the time of the i-th image. 

IMG = nd2time(FILENAME, i:j)    % Read time sequences of images ranging from the i-th to j-th frames.
```

<!-- ### `unloadsdk`

Fix conflict with in-built Matlab function like `imwrite`.

> __Note__
>
> *nd2readsdk* uses a library to read `.tif` file that may conflict with in-built functions in Matlab such as `imwrite` a `.tif` image.  If so, use `unloadsdk` to unload the contradicted library.

``` matlab
img = nd2read(filename);    % read the first image.

% imwrite(1, 'a.tif')       % Sometimes, imwrite unworks. 

unloadsdk;                  % unloadsdk solves the problem. 

imwrite(1, 'a.tif');        % imwrite works again. 
``` -->

### Advanced Usage

Versatile to read the file.

> __Warning__
>
> - Remember to close Nd2Reader with [`f.close()`](#fclose) after use.  
>
> - Don't recall the deallocated Nd2Reader; otherwise the program crashes.

#### `Nd2Reader()`

Open `.nd2` file.

```matlab
f = Nd2Reader(FILENAME);    % Initialize Nd2Reader.  
```

#### `f.getimage()`

Read image data with Nd2Reader.

```matlab
image = f.getimage(i);          % Read the i-th image.
```

#### Other usage with `Nd2Reader()`

```matlab

nImg = f.getnimg();                 % Get the number of images. Also in Attributes. 

Attributes = f.getattributes();     % Get file attributes (bits, componentCount, heightPx, widthPx, widthBytes, etc)

Coordinates = f.getcoordinates();   % Get coordinates for different dimensions. (index <--> (T, XY, Z))

Dimensions = f.getdimensions();     % Get dimensions. 

Experiment = f.getexperiment();     % Get experiment. Similar to dimensions but with detailed parameters.

ImageInfo = f.getimageinfo();       % Image Info. (bits, height, width and components)

Metadata = f.getmetadata();         % Get metadata.

FrameMetadata = f.getframemetadata(i);   % Get the i-th image metadata. (image position and time)

TextInfo = f.gettextinfo();         % Get text info.  (capturing, date, description, optics)
```

#### `f.close()`

Close the file after loading.

```matlab
f.close();      % Deallocate resources after use.
```

#### `coordconvert()` and `coordconvert2019()`

Simple to convert the $T/XY/Z$ indexes into an image index.

> __Note__
>
> Normally, for multi-dimensional image acqusition, it acquires the Z stack -> XY stack -> T stack.  Therefore, we need to know the exact image index to get a specific image.

```matlab
f = Nd2Reader(FILENAME);            % Initialize Nd2Reader.

Dimensions = f.getdimensions();     % Dimensions is required. 

% Get the image index at Time = 5, in XY position = 3 in the 1st Z position. 
seqNo = coordconvert(Dimensions, 'T', 5, 'XY', 3, 'Z', 1);       

% You can also get many indexes for a seqeunce of Time and XY position. 
seqNo = coordconvert(Dimensions, 'T', 5:10, 'XY', 2:3, 'Z', 1);   

% For MATLAB version 2019b or before, use coordconvert2019 instead. 
T = 5:10; XY = 2:3; Z = 1;
seqNo = coordconvert2019(Dimensions, T, XY, Z);  

f.close();  % Don't forget to close the file every time you finish reading data.
```

## Examples

```matlab
f = Nd2Reader('D:\20x_cell.nd2');   % Initialize Nd2Reader.

nImg = f.getImageNum(); 
parameter = zeros(nImg,1);  % Initilize the parameter you want to get.

for i = 1:nImg
    img = f.getimage(i);
    parameter(i) = processing(img);     % Processing the image to get the parameter.
end

f.close();  % Done

% img2 = f.getimage(1);     % This command will lead to a crash because of recalling the deallocated Nd2Reader!!

clear f;    % Clear f in case of recalling it. 
```

## Acknowledgements

- This project was inspired by [nd2reader](https://github.com/JacobZuo/nd2reader) by [JacobZuo](https://github.com/JacobZuo)
- Thank [Laboratory Imaging s.r.o.](https://www.laboratory-imaging.com/) for providing [ND2SDK](www.nd2sdk.com).
- Thank [leeeasonnn](https://github.com/leeeasonnn) for providing various `.nd2` files and suggestions.
- Thank [xhrphx](https://github.com/xhrphx) for resolving conflict with built-in `.tif`-related function.

## License

This project is licensed under the terms of the [MIT](/LICENSE).

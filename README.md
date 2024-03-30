# ![Nd2Matlab Logo](/assets/logo.png)

![license](https://img.shields.io/badge/License-MIT-blue)

Effortless `.nd2` file reading in MATLAB powered by **Nd2Matlab**.

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

> **Nd2Matlab** combines the power of [ND2SDK](https://www.nd2sdk.com/) by [Laboratory Imaging s.r.o.](https://www.laboratory-imaging.com) with user-friendly MATLAB scripts. It currently supports **Windows** systems only.

- **Matlab**

- **MinGW-w64 Complier** (install via 'Home' --> 'Add-Ons') to load the libraries in Matlab.

### Installation

> Choose one of the following methods:

1. Clone the repository using [`git`](https://git-scm.com/)

   ```sh
    git clone https://github.com/tytghy/Nd2SdkMatlab.git
   ```

2. Download the ZIP file from [**Nd2Matlab**](https://github.com/tytghy/Nd2SdkMatlab) and extract its contents.

## Usage

### `nd2read()`

Safely load images from `.nd2` files:

```matlab
IMG = nd2read(FILENAME);         % Read the entire movie

IMG = nd2read(FILENAME, i);      % Read the i-th image

IMG = nd2read(FILENAME, i:j);    % Read images ranging from the i-th to j-th frames
```

> **Note**
>
> - To optimize performance when repeatedly reading data from the same file, consider using [`.getimage`](#fgetimage) instaed of `nd2read()`.
>
> - The i-th image may not correspond to Time = i if you have multiple $XY$ or $Z$ positions. Use [`coordconvert`](#coordconvert-and-coordconvert2019) (for MATLAB R2019b or later) or [`coordconvert2019`](#coordconvert-and-coordconvert2019) (for MATLAB R2019a or ealier) to find the correct iamge index.
>
> - For single-channel data, `IMG` is a $height \times width \times time$ array. For multi-channel data, `IMG` is a $height \times width \times \lambda \times time$ array.

### `nd2info()`

Quickly scan file metadata:

```matlab
INFO = nd2info(FILENAME)    % Read brief information about the .nd2 file
```

> **Note**
>
> - `nd2info` extracts objective and time series data from the file metadata, storing them in `INFO.objectiveFromMetadata` and `INFO.objectiveFromFilename`, respectively.
>
> - `nd2info` recognizes keywords like `_?x_`, `?x_`, and `_?x.nd2` in the filename as `INFO.objectiveFromFilename`. For example, `INFO.objectiveFromFilename = 20` for filenames like _'20x_cell.nd2'_, _'cell_20x.nd2'_, or _'cell_20x_liquid.nd2'_.
>
> - A 6.5 µm pixel camera sensor is assumed by default. With a 10x objective, the effective pixel size is 6.5/10 = 0.65 µm.

### `nd2time()`

Obtain the time series of a file:

```matlab
IMG = nd2time(FILENAME)         % Read the time sequence of the entire movie

IMG = nd2time(FILENAME, i)      % Read the time of the i-th image

IMG = nd2time(FILENAME, i:j)    % Read time sequences from the i-th to j-th frames
```

### Advanced Usage

**Nd2Matlab** offers versatile options for reading `.nd2` files:

> **Warning**
>
> - Always close the Nd2Reader using [`f.close()`](#fclose) after use to avoid resource leaks.
>
> - Do not attempt to reuse a deallocated Nd2Reader, as this may cause program to crash.

#### `Nd2Reader()`

Open an `.nd2` file:

```matlab
f = Nd2Reader(FILENAME);    % Initialize Nd2Reader
```

#### `f.getimage()`

Read image data using Nd2Reader:

```matlab
image = f.getimage(i);          % Read the i-th image
```

#### Other Nd2Reader Methods

```matlab

nImg = f.getnimg();                 % Get the number of images (also available in Attributes)

Attributes = f.getattributes();     % Get file attributes (bits, componentCount, heightPx, widthPx, widthBytes, etc)

Coordinates = f.getcoordinates();   % Get coordinates for different dimensions. (index <--> (T, XY, Z))

Dimensions = f.getdimensions();     % Get dimensions

Experiment = f.getexperiment();     % Get experiment details (similar to dimensions but with more parameters)

ImageInfo = f.getimageinfo();       % Get image Info  (bits, height, width and components)

Metadata = f.getmetadata();         % Get metadata

FrameMetadata = f.getframemetadata(i);   % Get metadata for the i-th image (image position and time)

TextInfo = f.gettextinfo();         % Get text info  (capturing details, date, description, optics)
```

#### `f.close()`

Close the file after use to deallocate resources:

```matlab
f.close();      % Deallocate resources after use
```

#### `coordconvert()` and `coordconvert2019()`

Convert the $T/XY/Z$ indexes to an image index:

> **Note**
>
> For multi-dimensional image acqusition, the typical order is Z stack -> XY stack -> T stack. Knowing the exact image index is crucial for accessing specific images.

```matlab
f = Nd2Reader(FILENAME);            % Initialize Nd2Reader

Dimensions = f.getdimensions();     % Dimensions are required

% Get the image index at Time = 5, XY position = 3, and Z position = 1
seqNo = coordconvert(Dimensions, 'T', 5, 'XY', 3, 'Z', 1);

% Get multiple indexes for a seqeunce of Time and XY positions
seqNo = coordconvert(Dimensions, 'T', 5:10, 'XY', 2:3, 'Z', 1);

% For MATLAB version R2019a or earlier, use coordconvert2019 instead
T = 5:10; XY = 2:3; Z = 1;
seqNo = coordconvert2019(Dimensions, T, XY, Z);

f.close();  % Always close the file after reading data
```

## Examples

```matlab
f = Nd2Reader('D:\20x_cell.nd2');   % Initialize Nd2Reader

nImg = f.getImageNum();
parameter = zeros(nImg,1);  % Initilize the parameter array

for i = 1:nImg
    img = f.getimage(i);
    parameter(i) = processing(img);     % Process the image to extract the parameter
end

f.close();  % Done

% img2 = f.getimage(1);     % This will crash the program (recalling a deallocated Nd2Reader)!

clear f;    % Clear f to prevent accidental reuse
```

## Acknowledgements

- Inspired by [nd2reader](https://github.com/JacobZuo/nd2reader) by [JacobZuo](https://github.com/JacobZuo)
- Thank to [Laboratory Imaging s.r.o.](https://www.laboratory-imaging.com/) for providing [ND2SDK](www.nd2sdk.com)
- Thank to [leeeasonnn](https://github.com/leeeasonnn) for providing various `.nd2` files and suggestions
- Thank to [xhrphx](https://github.com/xhrphx) for resolving conflict with built-in `.tif`-related functions.

## License

This project is licensed under the terms of the [MIT License](/LICENSE).

# swiftarr-fotomat
An image processing microservice for https://github.com/grundoon/swiftarr.

`swiftarr-fotomat` takes a supplied image of JPEG, PNG, or animated GIF format and produces images for use by `swiftarr` according to the following flow:

* if the image is for a user's profile, a GIF is rejected
* if the image is for a user's profile, a JPEG or PNG is auto-oriented and cropped to a centered square; the resulting full-sized image is saved as JPEG, and a thumbnail version is saved as PNG
* if the image is for a post, a GIF is thumbnailed, and the original file is used as the full-sized image
* if the image is for a post, a JPEG or PNG is auto-oriented and a thumbnail version is saved as PNG; the full-sized version is then optionally watermarked and saved as JPEG

## Usage

By default, `swiftarr-fotomat` runs on localhost:8082 using HTTP. It should not be directly exposed to the open network. A future version will likely support HTTPS as well, but that won't really change the applicability of the previous sentence.

### Docker

The easiest way to run this is in a Docker container. Simply `docker-compose up`. The initial build will take quite some time.

This is, however, generally not going to be terribly useful on its own and should typically be run as part of the full suite of [`swiftarr`](https://github.com/grundoon/swiftarr) integrated services.

### Ubuntu 18.04

We'll properly document this when we get around to actually trying it out for production. It will essentially be very similar to the recipe within `Dockerfile`, with a primary difference being the assignment of shared directories rather than the volume mapping in `docker-compose.yml`.
 
## API Usage

There is only one endpoint – `POST localhost:8082/process` – which requires a JSON (or multipart) payload in the HTTP body.

```swift
{
    "destDir": String, // the base path for the processed image storage, e.g. "images/profile/"
    "image": String, // the image's filename in the temp directory, e.g. "DCE5F906-6DCE-4EBD-8941-68CE3A204F76"
    "height": Int, // the height of the thumbnail to be produced, e.g. 100
    "watermark": String?, // optional, the text to use for a watermark, e.g. "@grundoon\nJoCo Cruise 2020", omit if none
    "gravity": String? // optional, the position for the watermark, e.g. "Center" (defaults to "SouthEast", bottom right corner)
}
```


## Development

This version of `swiftarr-fotomat` uses ImageMagick v6.x and a deprecated system package method for the `module.modulemap`, which is good enough for our needs at present. A future version using ImageMagick v7.x and the system library method is planned.

1. Install ImageMagick v6.x using Homebrew.

```shell
% brew install imagemagick@6
```

2. Because this is a keg-only Homebrew installation, we're going to need to jump through some `pkg-config` hoops specific to the version of ImageMagick installed. If you don't have `pkg-config` installed, you'll need that.

```shell
% brew install pkg-config
```

3. `pkg-config` will need the path to ImageMagick (adjusting the version number to the correct one for your installation, of course).

```shell
% echo 'export PKG_CONFIG_PATH="/usr/local/Cellar/imagemagick@6/6.9.10-81/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc
```

4. Ensure that `pkg-config` can indeed find the ImageMagick components.

```shell
% pkg-config --list-all | grep -i Magick // should output a list of about a dozen
```

5. You will need the header search path.

```shell
% pkg-config --cflags-only-I MagickWand
-I/usr/local/Cellar/imagemagick@6/6.9.10-81/include/ImageMagick-6
```

6. Plus the library search path and linker flags.

```shell
% pkg-config --libs MagickWand
-L/usr/local/Cellar/imagemagick@6/6.9.10-81/lib -lMagickWand-6.Q16 -lMagickCore-6.Q16
```

7. Update `Package.xcconfig` with those values so that Xcode can generate a proper `.xcodeproj`.

```shell
% swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig
% open ./fotomat.xcodeproj
```



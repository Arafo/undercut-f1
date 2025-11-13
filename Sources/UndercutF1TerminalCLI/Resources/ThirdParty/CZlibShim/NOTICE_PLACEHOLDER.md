# CZlibShim Redistribution Notes

The Swift build links against the system `libz` through the `CZlibShim` target. To match the .NET release,
include a copy of the `LICENSE` file distributed with zlib (https://zlib.net/zlib_license.html) in this
folder when staging artifacts. The shim itself is compiled from sources in `Sources/CZlibShim`, so no
additional binaries are required beyond the license acknowledgement.

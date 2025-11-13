# SwiftTerm Asset Placeholder

SwiftTerm is resolved as a Swift Package Manager dependency. The Swift build pipeline does not need to stage
additional binaries, but packaging automation should copy the SwiftTerm license into the final archive so the
redistribution mirrors the .NET release expectations. When preparing a release artifact, drop the upstream
`LICENSE` file from https://github.com/migueldeicaza/SwiftTerm into this directory before invoking the
`stage-dist.sh` helper.

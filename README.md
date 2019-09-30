# assetgen

A simple command line tool to generate constants from an asset catalog. Currently only supports image assets
but could be trivially extended to support other types.

### Usage

`assetgen --target "$ASSET_CATALOG" --swiftVersion $SWIFT_VERSION --swiftFormatConfig "$SWIFT_FORMAT_CONFIG" --swiftFormatPath "$SWIFT_FORMAT_PATH"`

#### Required
- `--target` is the asset catalog to generate

#### Optional
- `--swiftFormatConfig` is the path to a version of swiftformat to format the output, otherwise the output is ugly
- `--swiftVersion` and `--swiftFormatConfig` are to pass to swiftformat as options. 

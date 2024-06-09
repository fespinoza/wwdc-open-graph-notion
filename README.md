# OpenGraphNotion

## Installation

first, set up environment variables
```bash
export WWDC_IMPORTER_NOTION_ACCESS_KEY="<VALUE_HERE>"
export WWDC_IMPORTER_DB_ID="<VALUE_HERE>"
```

Compile the script
```bash
swift build --configuration release
sudo cp -f .build/release/OpenGraphNotion /usr/local/bin/wwdc
```

## Usage

```bash
wwdc https://developer.apple.com/wwdc22/110350
```

## Development

```bash
swift run OpenGraphNotion wwdc https://developer.apple.com/wwdc22/110350
```

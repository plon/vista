# Vista Project Build Instructions

This project uses a Makefile to automate the build process with Xcode's command-line tool `xcodebuild`. The Makefile defines a series of steps that will:

1. Clean the previous build directory.
2. Archive the project.
3. Export the archived build.

## Prerequisites

- **macOS** with [Xcode](https://developer.apple.com/xcode/) installed.
- Xcode Command Line Tools installed. You can install them by running:
  
  ```bash
  xcode-select --install
  ```

- The project file `vista.xcodeproj` must be present in the project root.
- The export configuration file `exportOptions.plist` must also be present in the project root.

## Using Make to Build the Project

The Makefile is configured with the following targets:

- **clean**: Removes the previous build directory.
- **archive**: Builds an archive using `xcodebuild`.
- **export**: Exports the archived build.
- **all**: Runs the clean, archive, and export steps sequentially.

To build the project, open a terminal, navigate to the project directory, and run:

```bash
make
```

This will execute the following steps:
1. **Clean**: Removes the existing `build` directory.
2. **Archive**: Archives the project, creating `./build/vista.xcarchive`.
3. **Export**: Exports the archive into `./build/export`.

## Running Individual Steps

If you want to run individual parts of the process, you can use the following commands:

- To clean the build directory only:

  ```bash
  make clean
  ```

- To create the archive only:

  ```bash
  make archive
  ```

- To export the archive only:

  ```bash
  make export
  ```

## Troubleshooting

- **Xcode Issues**: Ensure Xcode and its command-line tools are properly installed.
- **Missing Files**: Verify that both `vista.xcodeproj` and `exportOptions.plist` are in the project root.
- **Permissions**: If you encounter permission issues, check that you have the right access to create and modify the `build` directory.

## Further Information

For more details on the Xcode build commands and options, please refer to the official [Xcode Build Documentation](https://developer.apple.com/documentation/xcode).
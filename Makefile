.PHONY: clean archive export all

all: clean archive export

clean:
	@echo "Cleaning build directory..."
	rm -rf build

archive:
	@echo "Creating archive..."
	xcodebuild archive \
	  -project vista.xcodeproj \
	  -scheme vista \
	  -archivePath ./build/vista.xcarchive \
	  CODE_SIGN_IDENTITY="-"

export:
	@echo "Exporting archive..."
	xcodebuild -exportArchive \
	  -archivePath ./build/vista.xcarchive \
	  -exportPath ./build/export \
	  -exportOptionsPlist exportOptions.plist

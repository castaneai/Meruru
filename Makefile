build:
	swift build -c release
	swift bundler bundle -o . -c release -u
	mkdir -p Meruru.app/Contents/Frameworks
	cp -r .build/release/VLCKit.framework Meruru.app/Contents/Frameworks/

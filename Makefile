EXECUTABLE_NAME = locheck
REPO = https://github.com/Asana/locheck
VERSION = 0.9.3

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
BUILD_PATH = .build/apple/Products/Release/$(EXECUTABLE_NAME)
CURRENT_PATH = $(PWD)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz
GIT_STATUS := $(shell git status -s)

.PHONY: install build uninstall format_code release # publish

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_PATH) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release --arch arm64 --arch x86_64

uninstall:
	rm -f $(INSTALL_PATH)

format_code:
	swiftformat Sources Tests

# Homebrew discourages self-submission unless the project is popular, so this is commented out for now.
# publish: zip_binary bump_brew
# 	echo "published $(VERSION)"

# Homebrew discourages self-submission unless the project is popular, so this is commented out for now.
# bump_brew:
# 	brew update
# 	brew bump-formula-pr --url=$(RELEASE_TAR) locheck

zip_binary: build
	zip -jr $(EXECUTABLE_NAME).zip $(BUILD_PATH)

release:
	git checkout main
ifeq ($(GIT_STATUS),"")
	sed -E -i '' 's/let version = ".*"/let version = "$(VERSION)"/' Sources/LocheckCommand/main.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)
else
	echo "Working directory is not clean"
endif

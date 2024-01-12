# Makefile
#
# picturesize
#


VERSION=v0.1.0


dist/picturesize.exe: picturesize.py requirements.txt
	docker run --rm -v "$(shell pwd)":/src cdrx/pyinstaller-windows:python3 'pyinstaller --onefile --clean picturesize.py'


.PHONY: test clean
test: dist/picturesize.exe test.sh
	./test.sh


release: dist/picturesize.exe
	gh release create $(VERSION) 'dist/picturesize.exe#picturesize.exe'


clean:
	sudo rm -rf __pycache__/ build/ dist/
	sudo rm -f *.spec


.PHONY: all

all: build

build: clean
	mkdir -p build
	hare build -L. -lraylib -lm -o build/main main.ha

clean:
	rm -rf build


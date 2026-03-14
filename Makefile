.PHONY: all

all: build

build: clean
	mkdir -p bin
	hare build -L. -lraylib -lm -o bin/main main.ha

clean:
	rm -rf bin


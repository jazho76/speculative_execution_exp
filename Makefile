CC      := gcc
TARGET  := main
SRC     := main.c speculative_gadget.s

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean


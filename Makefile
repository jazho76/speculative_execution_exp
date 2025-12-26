CC      := gcc
TARGET  := exploit
SRC     := exploit.c speculative_exploit.s

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean


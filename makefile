# ----------------------------
# group nb 077
# 16241600 : Docquier Eric
# 28751600 : d'Herbais de Thun Sebastien
# ----------------------------

OZC = ozc.exe
RM = rm
DEL = del

SRC = $(wildcard *.oz)
OBJECTS = $(patsubst %.oz, %.ozf, $(SRC))

BIN = $(filter-out PlayerBasicAI.ozf, $(wildcard *.ozf))

.PHONY: clean

all: run

compilePlayers:
	$(OZC) -c Player072Random.oz

run: build
	ozengine.exe Main.ozf

%.ozf: %.oz
	$(OZC) -c $<

build: $(OBJECTS)

clean: 
	$(RM) $(BIN)

clean_win:
	$(DEL) $(BIN)

# These commands should NOT be executed unless
# - You're running on Linux (can work on Windows but tricky, using WSL)
# - Have python3 installed
# - You have Pillow and other required packages installed (using pip)
images:
	python3 ./python/img_to_gif.py
	python3 ./python/players_to_sprites.py
	python3 ./python/environment_to_sprites.py
	python3 ./python/img_to_animation.py
	python3 ./python/img_to_oz.py > Images.oz

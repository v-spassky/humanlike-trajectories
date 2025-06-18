APP_NAME := app
SRC := src/*.vala
OUT_DIR := artifacts
BIN := $(OUT_DIR)/$(APP_NAME)
VALA_FLAGS := --pkg gtk4 --Xcc=-w

.PHONY: build run clean

build:
	@mkdir -p $(OUT_DIR)
	valac $(VALA_FLAGS) -o $(BIN) $(SRC)
	@echo "Built $(BIN)."

run:
	@$(MAKE) build
	@$(BIN)
	@rm -f $(BIN)

clean:
	@rm -f $(OUT_DIR)/*
	@echo "Cleaned build artifacts inside $(OUT_DIR)/."

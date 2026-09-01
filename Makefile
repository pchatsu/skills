SKILLS_DIR := $(CURDIR)/skills
TARGET_DIR := $(HOME)/.claude/skills

.PHONY: install uninstall reinstall list

install:
	@mkdir -p "$(TARGET_DIR)"
	@for dir in $(SKILLS_DIR)/*/; do \
		name=$$(basename "$${dir%/}"); \
		link="$(TARGET_DIR)/$$name"; \
		if [ -L "$$link" ] || [ -e "$$link" ]; then \
			echo "skip:   $$name (already exists)"; \
		else \
			ln -s "$${dir%/}" "$$link"; \
			echo "linked: $$name"; \
		fi; \
	done

uninstall:
	@for dir in $(SKILLS_DIR)/*/; do \
		name=$$(basename "$${dir%/}"); \
		link="$(TARGET_DIR)/$$name"; \
		if [ -L "$$link" ]; then \
			rm "$$link"; \
			echo "unlinked: $$name"; \
		fi; \
	done

reinstall: uninstall install

list:
	@ls -la "$(TARGET_DIR)"

SKILLS_DIR := $(CURDIR)/skills
TARGET_DIR := $(HOME)/.claude/skills
DIST_DIR := $(CURDIR)/dist
# claude.ai にアップロードして配るスキル。Cloud セッションでも使うため、symlink はせず claude.ai からの同期に任せる
CLAUDE_AI_SKILLS := pr ship

.PHONY: install uninstall reinstall list package

install:
	@mkdir -p "$(TARGET_DIR)"
	@for dir in $(SKILLS_DIR)/*/; do \
		name=$$(basename "$${dir%/}"); \
		link="$(TARGET_DIR)/$$name"; \
		if echo " $(CLAUDE_AI_SKILLS) " | grep -q " $$name "; then \
			echo "skip:   $$name (claude.ai から同期)"; \
		elif [ -L "$$link" ] || [ -e "$$link" ]; then \
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

# claude.ai アップロード用の zip を dist/ に作る
package:
	@mkdir -p "$(DIST_DIR)"
	@for name in $(CLAUDE_AI_SKILLS); do \
		rm -f "$(DIST_DIR)/$$name.zip"; \
		(cd "$(SKILLS_DIR)" && zip -qr "$(DIST_DIR)/$$name.zip" "$$name" -x '*.DS_Store'); \
		echo "packaged: dist/$$name.zip"; \
	done

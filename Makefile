# Цвета для красивого вывода
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
WHITE=\033[1;37m
NC=\033[0m # No Color

# Символы для статуса
CHECK=✓
CROSS=✗
ARROW=→
BUILDING=🔨
PACKAGE=📦

GOMOBILE_REPO = https://github.com/protonjohn/gomobile.git
GOMOBILE_TV_OS_BRANCH = pr/jkb/add-tvos-xros-support

BUILDDIR=$(shell pwd)/build
BUILDDIR_GOMOBILE=$(BUILDDIR)/gomobile
BUILDDIR_GOMOBILE_CMD=$(BUILDDIR_GOMOBILE)/cmd/gomobile

GOMOBILE=$(BUILDDIR)/gomobile_with_tvos
GOBIND=$(GOMOBILE) bind

BUILDDIR_IOS=$(BUILDDIR)/ios
BUILDDIR_MACOS=$(BUILDDIR)/macos
BUILDDIR_ANDROID=$(BUILDDIR)/android

APPLE_ARTIFACT=$(BUILDDIR)/XRayCoreIOSWrapper.xcframework
ANDROID_ARTIFACT=$(BUILDDIR)/xray.aar

IOS_TARGET=ios/arm64
TV_OS_TARGET=appletvos
TV_OS_SIMULATOR_TARGET=appletvsimulator
IOS_SIMULATOR_TARGET=iossimulator
MACOS_TARGET=macos
MACOSX_TARGET=maccatalyst

IOS_VERSION=14.0
ANDROID_API=24

LDFLAGS='-s -w -extldflags -lresolv'
IMPORT_PATH=github.com/JustYay/XrayCore-BasicWrapper

BUILD_GOMOBILE = "cd $(BUILDDIR) && git clone $(GOMOBILE_REPO) && cd $(BUILDDIR_GOMOBILE) && git checkout $(GOMOBILE_TV_OS_BRANCH) && cd $(BUILDDIR_GOMOBILE_CMD) && go build -o $(GOMOBILE)"

BUILD_ANDROID="cd $(BUILDDIR_ANDROID) && $(GOBIND) -v -androidapi $(ANDROID_API) -ldflags='-s -w' $(IMPORT_PATH)"

BUILD_IOS="cd $(BUILDDIR) && $(GOBIND) -a -ldflags $(LDFLAGS) -target=$(IOS_TARGET),$(IOS_SIMULATOR_TARGET) -o $(APPLE_ARTIFACT) $(IMPORT_PATH)"
BUILD_IOS_SIMULATOR="cd $(BUILDDIR) && $(GOBIND) -a -ldflags $(LDFLAGS) -target=$(IOS_SIMULATOR_TARGET) -o $(APPLE_ARTIFACT) $(IMPORT_PATH)" 

BUILD_MACOS ="cd $(BUILDDIR) && $(GOBIND) -a -ldflags $(LDFLAGS) -target=$(MACOS_TARGET) -o $(APPLE_ARTIFACT) $(IMPORT_PATH)" 

BUILD_ALL_APPLE_PLATFORMS = "cd $(BUILDDIR) && $(GOBIND) -a -ldflags $(LDFLAGS) -target=$(TV_OS_TARGET),$(TV_OS_SIMULATOR_TARGET),$(IOS_TARGET),$(IOS_SIMULATOR_TARGET),$(MACOS_TARGET) -o $(APPLE_ARTIFACT) $(IMPORT_PATH)"

# Функция для красивого вывода
define log_info
	@echo "$(CYAN)$(ARROW) $(1)$(NC)"
endef

define log_success
	@echo "$(GREEN)$(CHECK) $(1)$(NC)"
endef

define log_error
	@echo "$(RED)$(CROSS) $(1)$(NC)"
endef

define log_building
	@echo "$(YELLOW)$(BUILDING) $(1)$(NC)"
endef

define log_package
	@echo "$(PURPLE)$(PACKAGE) $(1)$(NC)"
endef

define print_header
	@echo ""
	@echo "$(WHITE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(WHITE)║                    XRay Core Mobile Wrapper                  ║$(NC)"
	@echo "$(WHITE)║                        Build System                          ║$(NC)"
	@echo "$(WHITE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
endef

gomobiletvos:
	$(call print_header)
	$(call log_info, "Подготовка среды сборки...")
	@mkdir -p $(BUILDDIR)
	$(call log_building, "Клонирование и сборка gomobile с поддержкой tvOS...")
	@eval $(BUILD_GOMOBILE) && $(call log_success, "gomobile успешно собран!") || $(call log_error, "Ошибка сборки gomobile")

all: clean gomobiletvos allapple 
	$(call log_package, "Сборка завершена! Все платформы готовы.")

allapple:
	$(call log_building, "Сборка для всех Apple платформ (iOS, tvOS, macOS)...")
	@eval $(BUILD_ALL_APPLE_PLATFORMS) && $(call log_success, "Apple платформы успешно собраны!") || $(call log_error, "Ошибка сборки Apple платформ")
	$(call log_package, "Артефакт: $(APPLE_ARTIFACT)")

ios:
	$(call print_header)
	$(call log_info, "Начинаю сборку для iOS...")
	@$(MAKE) gomobiletvos
	@mkdir -p $(BUILDDIR_IOS)
	$(call log_building, "Компиляция iOS framework...")
	@eval $(BUILD_IOS) && $(call log_success, "iOS framework успешно собран!") || $(call log_error, "Ошибка сборки iOS")
	$(call log_package, "iOS артефакт: $(APPLE_ARTIFACT)")

macos:
	$(call print_header)
	$(call log_info, "Начинаю сборку для macOS...")
	@$(MAKE) gomobiletvos
	@mkdir -p $(BUILDDIR_MACOS)
	$(call log_building, "Компиляция macOS framework...")
	@eval $(BUILD_MACOS) && $(call log_success, "macOS framework успешно собран!") || $(call log_error, "Ошибка сборки macOS")
	$(call log_package, "macOS артефакт: $(APPLE_ARTIFACT)")

android:
	$(call print_header)
	$(call log_info, "Начинаю сборку для Android...")
	$(call log_building, "Проверка gomobile...")
	@command -v gomobile >/dev/null 2>&1 || { $(call log_error, "gomobile не найден. Установите: go install golang.org/x/mobile/cmd/gomobile@latest"); exit 1; }
	@mkdir -p $(BUILDDIR_ANDROID)
	$(call log_building, "Компиляция Android AAR...")
	@eval $(BUILD_ANDROID) && $(call log_success, "Android AAR успешно собран!") || $(call log_error, "Ошибка сборки Android")
	$(call log_package, "Android артефакт: $(ANDROID_ARTIFACT)")

clean:
	$(call log_info, "Очистка директории сборки...")
	@rm -rf $(BUILDDIR)
	$(call log_success, "Директория сборки очищена!")

.PHONY: help
help:
	$(call print_header)
	@echo "$(CYAN)Доступные команды:$(NC)"
	@echo ""
	@echo "  $(YELLOW)make ios$(NC)        - Собрать для iOS"
	@echo "  $(YELLOW)make macos$(NC)      - Собрать для macOS"
	@echo "  $(YELLOW)make android$(NC)    - Собрать для Android"
	@echo "  $(YELLOW)make allapple$(NC)   - Собрать для всех Apple платформ"
	@echo "  $(YELLOW)make all$(NC)        - Собрать для всех платформ"
	@echo "  $(YELLOW)make clean$(NC)      - Очистить директорию сборки"
	@echo "  $(YELLOW)make help$(NC)       - Показать эту справку"
	@echo ""
	@echo "$(CYAN)Поддерживаемые транспорты:$(NC)"
	@echo "  • TCP, UDP, WebSocket, gRPC"
	@echo "  • HTTP/2, QUIC, KCP"
	@echo "  • $(GREEN)SplitHTTP$(NC) (новый!)"
	@echo "  • Reality, TLS"
	@echo ""

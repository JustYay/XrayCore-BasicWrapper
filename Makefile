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

BUILDDIR=$(shell pwd)/build
BUILDDIR_IOS=$(BUILDDIR)/ios
BUILDDIR_MACOS=$(BUILDDIR)/macos
BUILDDIR_ANDROID=$(BUILDDIR)/android

APPLE_ARTIFACT=$(BUILDDIR)/XRayCoreIOSWrapper.xcframework
ANDROID_ARTIFACT=$(BUILDDIR)/xray.aar

IOS_TARGET=ios/arm64
IOS_SIMULATOR_TARGET=iossimulator
MACOS_TARGET=macos

IOS_VERSION=14.0
ANDROID_API=24

LDFLAGS='-s -w -extldflags -lresolv'
IMPORT_PATH=github.com/JustYay/XrayCore-BasicWrapper

# Функция для красивого вывода
define log_info
	echo "$(CYAN)$(ARROW) $(1)$(NC)"
endef

define log_success
	echo "$(GREEN)$(CHECK) $(1)$(NC)"
endef

define log_error
	echo "$(RED)$(CROSS) $(1)$(NC)"
endef

define log_building
	echo "$(YELLOW)$(BUILDING) $(1)$(NC)"
endef

define log_package
	echo "$(PURPLE)$(PACKAGE) $(1)$(NC)"
endef

define print_header
	echo ""
	echo "$(WHITE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	echo "$(WHITE)║                    XRay Core Mobile Wrapper                  ║$(NC)"
	echo "$(WHITE)║                        Build System                          ║$(NC)"
	echo "$(WHITE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	echo ""
endef

setup:
	@$(call print_header)
	@$(call log_info,Настройка среды разработки...)
	@$(call log_building,Проверка Go версии...)
	@go version || { $(call log_error,Go не установлен! Установите Go 1.20+); exit 1; }
	@$(call log_building,Установка gomobile...)
	@go install golang.org/x/mobile/cmd/gomobile@latest && \
		$(call log_success,gomobile установлен!) || \
		$(call log_error,Ошибка установки gomobile)
	@$(call log_building,Установка gobind...)
	@go install golang.org/x/mobile/cmd/gobind@latest && \
		$(call log_success,gobind установлен!) || \
		$(call log_error,Ошибка установки gobind)
	@$(call log_building,Установка mobile bind пакета...)
	@go get golang.org/x/mobile/bind && \
		$(call log_success,mobile bind пакет установлен!) || \
		$(call log_error,Ошибка установки mobile bind)
	@$(call log_building,Инициализация gomobile...)
	@export PATH=$$PATH:$$HOME/go/bin && gomobile init && \
		$(call log_success,gomobile инициализирован!) || \
		$(call log_error,Ошибка инициализации gomobile)
	@$(call log_building,Обновление зависимостей проекта...)
	@go mod tidy && \
		$(call log_success,Зависимости обновлены!) || \
		$(call log_error,Ошибка обновления зависимостей)
	@$(call log_success,Среда разработки готова! Теперь можно запускать make ios или make android)

all: setup ios android
	@$(call log_package,Сборка завершена! Все платформы готовы.)

ios: check-setup
	@$(call print_header)
	@$(call log_info,Начинаю сборку для iOS...)
	@mkdir -p $(BUILDDIR)
	@$(call log_building,Компиляция iOS framework...)
	@export PATH=$$PATH:$$HOME/go/bin && \
		gomobile bind -v -target=ios -o $(APPLE_ARTIFACT) -ldflags $(LDFLAGS) $(IMPORT_PATH) && \
		$(call log_success,iOS framework успешно собран!) || \
		$(call log_error,Ошибка сборки iOS)
	@$(call log_package,iOS артефакт: $(APPLE_ARTIFACT))

macos: check-setup
	@$(call print_header)
	@$(call log_info,Начинаю сборку для macOS...)
	@mkdir -p $(BUILDDIR)
	@$(call log_building,Компиляция macOS framework...)
	@export PATH=$$PATH:$$HOME/go/bin && \
		gomobile bind -v -target=macos -o $(APPLE_ARTIFACT) -ldflags $(LDFLAGS) $(IMPORT_PATH) && \
		$(call log_success,macOS framework успешно собран!) || \
		$(call log_error,Ошибка сборки macOS)
	@$(call log_package,macOS артефакт: $(APPLE_ARTIFACT))

android: check-setup
	@$(call print_header)
	@$(call log_info,Начинаю сборку для Android...)
	@mkdir -p $(BUILDDIR_ANDROID)
	@$(call log_building,Компиляция Android AAR...)
	@export PATH=$$PATH:$$HOME/go/bin && \
		cd $(BUILDDIR_ANDROID) && \
		gomobile bind -v -target=android -androidapi $(ANDROID_API) -o xray.aar -ldflags='-s -w' $(IMPORT_PATH) && \
		$(call log_success,Android AAR успешно собран!) || \
		$(call log_error,Ошибка сборки Android)
	@$(call log_package,Android артефакт: $(BUILDDIR_ANDROID)/xray.aar)

check-setup:
	@export PATH=$$PATH:$$HOME/go/bin && command -v gomobile >/dev/null 2>&1 || { \
		$(call log_error,gomobile не найден! Запустите: make setup); \
		exit 1; \
	}

clean:
	@$(call log_info,Очистка директории сборки...)
	@rm -rf $(BUILDDIR)
	@$(call log_success,Директория сборки очищена!)

.PHONY: help setup check-setup
help:
	@$(call print_header)
	@echo "$(CYAN)Доступные команды:$(NC)"
	@echo ""
	@echo "  $(YELLOW)make setup$(NC)      - Настроить среду разработки (первый запуск)"
	@echo "  $(YELLOW)make ios$(NC)        - Собрать для iOS"
	@echo "  $(YELLOW)make macos$(NC)      - Собрать для macOS"
	@echo "  $(YELLOW)make android$(NC)    - Собрать для Android"
	@echo "  $(YELLOW)make all$(NC)        - Настроить среду и собрать для всех платформ"
	@echo "  $(YELLOW)make clean$(NC)      - Очистить директорию сборки"
	@echo "  $(YELLOW)make help$(NC)       - Показать эту справку"
	@echo ""
	@echo "$(CYAN)Поддерживаемые транспорты:$(NC)"
	@echo "  • TCP, UDP, WebSocket, gRPC"
	@echo "  • HTTP/2, QUIC, KCP"
	@echo "  • $(GREEN)SplitHTTP$(NC) (новый!)"
	@echo "  • Reality, TLS"
	@echo ""
	@echo "$(CYAN)Быстрый старт:$(NC)"
	@echo "  1. $(YELLOW)make setup$(NC)   - Настроить среду (только один раз)"
	@echo "  2. $(YELLOW)make ios$(NC)     - Собрать для iOS"
	@echo "  3. $(YELLOW)make android$(NC) - Собрать для Android"
	@echo ""

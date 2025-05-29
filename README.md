# XRay Core Mobile Wrapper

[![Go Version](https://img.shields.io/badge/Go-1.20+-blue.svg)](https://golang.org/)
[![XRay Core](https://img.shields.io/badge/XRay%20Core-v1.250516.0-green.svg)](https://github.com/xtls/xray-core)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Мобильная обертка для XRay Core с поддержкой iOS, iOS Simulator, Android и macOS.

## Особенности

- ✅ Последняя версия XRay Core (v1.250516.0)
- 📱 Поддержка нескольких платформ (iOS, Android, macOS)
- 🚀 Новый транспорт **SplitHTTP**
- 🔒 Полная поддержка Reality и TLS
- 🛠️ Простой API для интеграции
- 🎨 Красивый вывод сборки
- ⚡ Автоматическая настройка среды разработки

## Быстрый старт

### Требования

- Go 1.20 или выше
- Xcode (для iOS/macOS сборки)
- Android SDK (для Android сборки)

### Установка и настройка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/JustYay/XrayCore-BasicWrapper.git
   cd XrayCore-BasicWrapper
   ```

2. **Настройте среду разработки (только один раз):**
   ```bash
   make setup
   ```
   
   Эта команда автоматически:
   - Проверит версию Go
   - Установит `gomobile` и `gobind`
   - Установит необходимые пакеты (`golang.org/x/mobile/bind`)
   - Инициализирует `gomobile`
   - Обновит зависимости проекта

3. **Соберите для нужной платформы:**
   ```bash
   # Для iOS
   make ios
   
   # Для Android
   make android
   
   # Для macOS
   make macos
   
   # Для всех платформ
   make all
   ```

### Команды сборки

| Команда | Описание |
|---------|----------|
| `make setup` | Настроить среду разработки (первый запуск) |
| `make ios` | Собрать iOS framework |
| `make android` | Собрать Android AAR |
| `make macos` | Собрать macOS framework |
| `make all` | Настроить среду и собрать для всех платформ |
| `make clean` | Очистить директорию сборки |
| `make help` | Показать справку |

## Поддерживаемые транспорты

- TCP/UDP
- WebSocket
- gRPC
- HTTP/2
- QUIC
- KCP
- **SplitHTTP** (новый!)
- Reality
- TLS

## API документация

### Основные функции

```go
// Управление памятью
func FreeMemory()

// Настройка окружения
func SetXrayEnv(key, value string)

// Управление XRay
func StartXray(configPath string) error
func StopXray() error
func RestartXray(configPath string) error

// Измерение задержки
func MeasureDelay(config string) (int64, error)
```

### Пример использования

```go
import "github.com/JustYay/XrayCore-BasicWrapper"

// Настройка окружения
wrapper.SetXrayEnv("XRAY_LOCATION_ASSET", "/path/to/assets")

// Запуск XRay
err := wrapper.StartXray("/path/to/config.json")
if err != nil {
    log.Fatal(err)
}

// Остановка XRay
wrapper.StopXray()

// Освобождение памяти
wrapper.FreeMemory()
```

## Переменные окружения

Поддерживаемые переменные для `SetXrayEnv`:

- `XRAY_LOCATION_ASSET` - путь к ресурсам
- `XRAY_LOCATION_CONFIG` - путь к конфигурации
- `XRAY_BUFFER_SIZE` - размер буфера

## Артефакты сборки

После успешной сборки вы найдете:

- **iOS**: `build/XRayCoreIOSWrapper.xcframework`
- **Android**: `build/android/xray.aar`
- **macOS**: `build/XRayCoreIOSWrapper.xcframework`

## Устранение неполадок

### Ошибка "gomobile not found"

Если вы получаете ошибку о том, что `gomobile` не найден, просто запустите:

```bash
make setup
```

Эта команда автоматически установит все необходимые зависимости.

### Ошибка "no Go package in golang.org/x/mobile/bind"

Команда `make setup` также решает эту проблему, устанавливая все необходимые пакеты.

## Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add some amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## Благодарности

- [XRay Core](https://github.com/xtls/xray-core) - основной проект
- [gomobile](https://golang.org/x/mobile) - инструменты для мобильной разработки

## Поддержка

Если у вас есть вопросы или проблемы, пожалуйста, создайте [issue](https://github.com/JustYay/XrayCore-BasicWrapper/issues).
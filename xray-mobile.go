package XRay

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"math"
	"net"
	"net/http"
	"os"
	"runtime"
	"runtime/debug"
	"time"

	_ "github.com/JustYay/XrayCore-BasicWrapper/all_core_packages"

	xrayNet "github.com/xtls/xray-core/common/net"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
)

type CompletionHandler func(int64, error)

type Logger interface {
	LogInput(s string)
}

var coreInstance *core.Instance

// Константа для жесткого ограничения памяти в 50МБ
const HARD_MEMORY_LIMIT = MEMORY_LIMIT_50MB // Используем константу из memory_manager.go

// init автоматически устанавливает жесткое ограничение памяти при загрузке пакета
func init() {
	// Устанавливаем жесткое ограничение памяти в 50МБ
	debug.SetMemoryLimit(HARD_MEMORY_LIMIT)
	// Устанавливаем более агрессивную сборку мусора для экономии памяти
	debug.SetGCPercent(AGGRESSIVE_GC_PERCENT)
}

// Sets the limit on memory consumption by a process.
// Also set garbage collection target percentage
// ВНИМАНИЕ: Эта функция переопределена для принудительного ограничения в 50МБ
func SetMemoryLimit(byteLimit int64, garbageCollectionTargetPercentage int) {
	// Принудительно ограничиваем максимальный лимит до 50МБ
	if byteLimit > HARD_MEMORY_LIMIT {
		byteLimit = HARD_MEMORY_LIMIT
	}
	debug.SetGCPercent(garbageCollectionTargetPercentage)
	debug.SetMemoryLimit(byteLimit)
}

// Removes the memory usage limit
// and returns the garbage collector frequency to the default
// ВНИМАНИЕ: Эта функция переопределена для сохранения ограничения в 50МБ
func RemoveMemoryLimit() {
	// Не позволяем полностью убрать ограничение - максимум 50МБ
	debug.SetGCPercent(100)
	debug.SetMemoryLimit(HARD_MEMORY_LIMIT)
}

// Ser AssetsDirectory in Xray env
func SetAssetsDirectory(path string) {
	os.Setenv("xray.location.asset", path)
}

// [key] can be:
// PluginLocation  = "xray.location.plugin"
// ConfigLocation  = "xray.location.config"
// ConfdirLocation = "xray.location.confdir"
// ToolLocation    = "xray.location.tool"
// AssetLocation   = "xray.location.asset"
// UseReadV         = "xray.buf.readv"
// UseFreedomSplice = "xray.buf.splice"
// UseVmessPadding  = "xray.vmess.padding"
// UseCone          = "xray.cone.disabled"
// BufferSize           = "xray.ray.buffer.size"
// BrowserDialerAddress = "xray.browser.dialer"
// XUDPLog              = "xray.xudp.show"
// XUDPBaseKey          = "xray.xudp.basekey"
func SetXrayEnv(key string, path string) {
	os.Setenv(key, path)
}

func StartXray(config []byte, logger Logger) error {
	// Принудительно устанавливаем ограничение памяти в 50МБ перед запуском
	EnforceMemoryLimit(logger)
	
	// Выводим подробную статистику памяти
	LogMemoryStats(logger)
	
	conf, err := serial.DecodeJSONConfig(bytes.NewReader(config))
	if err != nil {
		logger.LogInput("Config load error: " + err.Error())
		return err
	}

	pbConfig, err := conf.Build()
	if err != nil {
		return err
	}
	instance, err := core.New(pbConfig)
	if err != nil {
		logger.LogInput("Create XRay error: " + err.Error())
		return err
	}

	err = instance.Start()
	if err != nil {
		logger.LogInput("Start XRay error: " + err.Error())
	}

	coreInstance = instance
	
	// Проверяем память после запуска
	CheckMemoryAndCleanup(logger)
	
	return nil
}

func StopXray() {
	coreInstance.Close()
}

// GetMemoryUsage возвращает информацию об использовании памяти
func GetMemoryUsage() (currentMB int64, limitMB int64, isWithinLimit bool) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	
	currentBytes := int64(m.Alloc)
	currentMB = currentBytes / (1024 * 1024)
	limitMB = HARD_MEMORY_LIMIT / (1024 * 1024)
	isWithinLimit = currentBytes <= HARD_MEMORY_LIMIT
	
	return currentMB, limitMB, isWithinLimit
}

// ForceGarbageCollection принудительно запускает сборку мусора для освобождения памяти
func ForceGarbageCollection() {
	runtime.GC()
	debug.FreeOSMemory()
}

// CheckMemoryAndCleanup проверяет использование памяти и при необходимости очищает её
func CheckMemoryAndCleanup(logger Logger) {
	currentMB, limitMB, isWithinLimit := GetMemoryUsage()
	
	if logger != nil {
		logger.LogInput(fmt.Sprintf("Использование памяти: %d МБ из %d МБ", currentMB, limitMB))
	}
	
	if !isWithinLimit {
		if logger != nil {
			logger.LogInput("ВНИМАНИЕ: Превышен лимит памяти! Запуск принудительной очистки...")
		}
		ForceGarbageCollection()
		
		// Проверяем снова после очистки
		currentMB, _, isWithinLimit = GetMemoryUsage()
		if logger != nil {
			if isWithinLimit {
				logger.LogInput(fmt.Sprintf("Память очищена. Текущее использование: %d МБ", currentMB))
			} else {
				logger.LogInput(fmt.Sprintf("КРИТИЧНО: Не удалось освободить достаточно памяти! Текущее использование: %d МБ", currentMB))
			}
		}
	}
}

// / Real ping
func MeasureOutboundDelay(config []byte, url string) (int64, error) {
	// Принудительно устанавливаем ограничение памяти перед тестом
	debug.SetMemoryLimit(HARD_MEMORY_LIMIT)
	debug.SetGCPercent(AGGRESSIVE_GC_PERCENT)
	
	conf, err := serial.DecodeJSONConfig(bytes.NewReader(config))
	if err != nil {
		return -1, err
	}
	pbConfig, err := conf.Build()
	if err != nil {
		return -1, err
	}

	// dont listen to anything for test purpose
	pbConfig.Inbound = nil
	// config.App: (fakedns), log, dispatcher, InboundConfig, OutboundConfig, (stats), router, dns, (policy)
	// keep only basic features
	pbConfig.App = pbConfig.App[:5]

	inst, err := core.New(pbConfig)
	if err != nil {
		return -1, err
	}

	inst.Start()
	defer func() {
		inst.Close()
		// Принудительная очистка памяти после теста
		ForceGarbageCollection()
	}()
	
	return measureInstDelay(context.Background(), inst, url)
}

func measureInstDelay(ctx context.Context, inst *core.Instance, url string) (int64, error) {
	if inst == nil {
		return -1, errors.New("core instance nil")
	}

	tr := &http.Transport{
		TLSHandshakeTimeout: 6 * time.Second,
		DisableKeepAlives:   true,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			dest, err := xrayNet.ParseDestination(fmt.Sprintf("%s:%s", network, addr))
			if err != nil {
				return nil, err
			}
			return core.Dial(ctx, inst, dest)
		},
	}

	c := &http.Client{
		Transport: tr,
		Timeout:   12 * time.Second,
	}

	if len(url) <= 0 {
		url = "https://www.google.com/generate_204"
	}
	req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
	start := time.Now()

	resp, err := c.Do(req)
	if err != nil {
		return -1, err
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return -1, fmt.Errorf("status != 20x: %s", resp.Status)
	}
	resp.Body.Close()
	return time.Since(start).Milliseconds(), nil

}

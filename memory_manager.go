package XRay

import (
	"fmt"
	"runtime"
	"runtime/debug"
	"time"
)

// Константы для управления памятью
const (
	// Жесткое ограничение памяти в 50МБ
	MEMORY_LIMIT_50MB = 50 * 1024 * 1024
	
	// Агрессивный процент сборки мусора для экономии памяти
	AGGRESSIVE_GC_PERCENT = 20
	
	// Интервал для автоматической проверки памяти
	MEMORY_CHECK_INTERVAL = 30 * time.Second
)

// MemoryStats содержит статистику использования памяти
type MemoryStats struct {
	AllocatedMB    int64
	TotalAllocMB   int64
	SystemMB       int64
	LimitMB        int64
	IsWithinLimit  bool
	GCCount        uint32
}

// GetDetailedMemoryStats возвращает подробную статистику памяти
func GetDetailedMemoryStats() MemoryStats {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	
	return MemoryStats{
		AllocatedMB:   int64(m.Alloc) / (1024 * 1024),
		TotalAllocMB:  int64(m.TotalAlloc) / (1024 * 1024),
		SystemMB:      int64(m.Sys) / (1024 * 1024),
		LimitMB:       HARD_MEMORY_LIMIT / (1024 * 1024),
		IsWithinLimit: int64(m.Alloc) <= HARD_MEMORY_LIMIT,
		GCCount:       m.NumGC,
	}
}

// StartMemoryMonitor запускает фоновый мониторинг памяти
func StartMemoryMonitor(logger Logger) chan bool {
	stopChan := make(chan bool)
	
	go func() {
		ticker := time.NewTicker(MEMORY_CHECK_INTERVAL)
		defer ticker.Stop()
		
		for {
			select {
			case <-ticker.C:
				CheckMemoryAndCleanup(logger)
			case <-stopChan:
				return
			}
		}
	}()
	
	return stopChan
}

// LogMemoryStats выводит подробную статистику памяти в лог
func LogMemoryStats(logger Logger) {
	if logger == nil {
		return
	}
	
	stats := GetDetailedMemoryStats()
	logger.LogInput(fmt.Sprintf("=== СТАТИСТИКА ПАМЯТИ ==="))
	logger.LogInput(fmt.Sprintf("Выделено: %d МБ", stats.AllocatedMB))
	logger.LogInput(fmt.Sprintf("Всего выделялось: %d МБ", stats.TotalAllocMB))
	logger.LogInput(fmt.Sprintf("Системная память: %d МБ", stats.SystemMB))
	logger.LogInput(fmt.Sprintf("Лимит: %d МБ", stats.LimitMB))
	logger.LogInput(fmt.Sprintf("В пределах лимита: %t", stats.IsWithinLimit))
	logger.LogInput(fmt.Sprintf("Количество сборок мусора: %d", stats.GCCount))
	logger.LogInput(fmt.Sprintf("========================"))
}

// EnforceMemoryLimit принудительно устанавливает и проверяет лимит памяти
func EnforceMemoryLimit(logger Logger) {
	debug.SetMemoryLimit(HARD_MEMORY_LIMIT)
	debug.SetGCPercent(AGGRESSIVE_GC_PERCENT)
	
	if logger != nil {
		logger.LogInput(fmt.Sprintf("Принудительно установлен лимит памяти: %d МБ", HARD_MEMORY_LIMIT/(1024*1024)))
		logger.LogInput(fmt.Sprintf("Установлен агрессивный GC: %d%%", AGGRESSIVE_GC_PERCENT))
	}
	
	// Немедленная проверка и очистка при необходимости
	CheckMemoryAndCleanup(logger)
} 
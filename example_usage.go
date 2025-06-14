package XRay

import (
	"fmt"
	"log"
	"time"
)

// Простой логгер для примера
type SimpleLogger struct{}

func (l *SimpleLogger) LogInput(s string) {
	log.Printf("[XRay] %s", s)
}

// DemoMemorySystem демонстрирует работу системы ограничения памяти
func DemoMemorySystem() {
	logger := &SimpleLogger{}
	
	// Демонстрация системы ограничения памяти
	fmt.Println("=== ДЕМОНСТРАЦИЯ СИСТЕМЫ ОГРАНИЧЕНИЯ ПАМЯТИ ===")
	
	// 1. Проверяем текущее состояние памяти
	fmt.Println("\n1. Начальное состояние памяти:")
	LogMemoryStats(logger)
	
	// 2. Принудительно устанавливаем лимит
	fmt.Println("\n2. Принудительная установка лимита:")
	EnforceMemoryLimit(logger)
	
	// 3. Получаем базовую статистику
	fmt.Println("\n3. Базовая статистика памяти:")
	currentMB, limitMB, isWithinLimit := GetMemoryUsage()
	fmt.Printf("Текущее использование: %d МБ\n", currentMB)
	fmt.Printf("Лимит: %d МБ\n", limitMB)
	fmt.Printf("В пределах лимита: %t\n", isWithinLimit)
	
	// 4. Получаем подробную статистику
	fmt.Println("\n4. Подробная статистика памяти:")
	stats := GetDetailedMemoryStats()
	fmt.Printf("Выделено: %d МБ\n", stats.AllocatedMB)
	fmt.Printf("Всего выделялось: %d МБ\n", stats.TotalAllocMB)
	fmt.Printf("Системная память: %d МБ\n", stats.SystemMB)
	fmt.Printf("Количество сборок мусора: %d\n", stats.GCCount)
	
	// 5. Запускаем мониторинг памяти
	fmt.Println("\n5. Запуск фонового мониторинга памяти...")
	stopMonitor := StartMemoryMonitor(logger)
	
	// Ждем немного, чтобы увидеть работу мониторинга
	time.Sleep(35 * time.Second)
	
	// 6. Останавливаем мониторинг
	fmt.Println("\n6. Остановка мониторинга...")
	stopMonitor <- true
	
	// 7. Принудительная очистка памяти
	fmt.Println("\n7. Принудительная очистка памяти:")
	ForceGarbageCollection()
	LogMemoryStats(logger)
	
	fmt.Println("\n=== ДЕМОНСТРАЦИЯ ЗАВЕРШЕНА ===")
}
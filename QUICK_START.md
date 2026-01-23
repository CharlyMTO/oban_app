# 🚀 Guía Rápida de Oban

## ✅ Todo está configurado y funcionando!

### 🌐 URLs disponibles:
- **Aplicación**: http://localhost:4000
- **Oban Dashboard**: http://localhost:4000/dev/oban
- **LiveDashboard**: http://localhost:4000/dev/dashboard

## 🔥 Prueba rápida (Abre IEx)

```bash
# Abre una consola interactiva
iex -S mix
```

### Ejemplo 1: Procesamiento simple
```elixir
# En IEx:
alias ObanApp.Workers.HeavyDataWorker

# Crear un trabajo
%{task: "process_data", data_id: 1}
|> HeavyDataWorker.new()
|> Oban.insert()

# Verás en los logs del servidor:
# 🚀 Iniciando procesamiento de datos para ID: 1
# ⏳ Procesando 1000 registros (complejidad: medium)...
# ✅ Procesamiento completado exitosamente para ID: 1
```

### Ejemplo 2: Múltiples trabajos
```elixir
# Crear 5 trabajos a la vez
jobs = for id <- 1..5 do
  %{task: "process_data", data_id: id, complexity: "high"}
  |> HeavyDataWorker.new()
end

Oban.insert_all(jobs)
```

### Ejemplo 3: Generar reporte
```elixir
%{task: "generate_report", report_type: "sales"}
|> HeavyDataWorker.new()
|> Oban.insert()
```

### Ejemplo 4: Trabajo programado (en 10 segundos)
```elixir
%{task: "process_data", data_id: 999}
|> HeavyDataWorker.new(schedule_in: 10)
|> Oban.insert()
```

## 📊 Ver el Dashboard

Abre tu navegador en: **http://localhost:4000/dev/oban**

Allí podrás:
- ✅ Ver todos los trabajos en tiempo real
- 🔄 Ver el estado de las colas
- 📈 Ver estadísticas de rendimiento
- 🗑️ Gestionar trabajos (cancelar, reintentar, etc.)

## 📖 Documentación completa

Para más detalles, mira el archivo [OBAN_USAGE.md](./OBAN_USAGE.md)

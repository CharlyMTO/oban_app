# Ejemplo de Uso de Oban y Workers

Este proyecto incluye **Oban** para procesamiento de trabajos en segundo plano y **Oban Web** para monitoreo visual.

## 🚀 Configuración

### 1. Dependencias instaladas:
- `oban ~> 2.18` - Sistema de procesamiento de trabajos
- `oban_web ~> 2.10` - Dashboard web para monitoreo

### 2. Configuración de colas (config/dev.exs):
```elixir
config :oban_app, Oban,
  repo: ObanApp.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, heavy: 5]
```

- **default**: 10 workers concurrentes
- **heavy**: 5 workers concurrentes (para tareas pesadas)

## 📊 Dashboard Web

Accede al dashboard de Oban en: **http://localhost:4000/dev/oban**

El dashboard te permite:
- ✅ Ver trabajos en ejecución, completados y fallidos
- 🔄 Reintentar trabajos fallidos
- 📈 Ver estadísticas en tiempo real
- 🗑️ Eliminar trabajos obsoletos

## 🛠️ Worker de Ejemplo: HeavyDataWorker

### Tipos de tareas disponibles:

#### 1. Procesamiento de datos
```elixir
# En IEx:
iex> alias ObanApp.Workers.HeavyDataWorker

# Tarea simple
iex> %{task: "process_data", data_id: 123}
...> |> HeavyDataWorker.new()
...> |> Oban.insert()

# Con configuración personalizada
iex> %{
...>   task: "process_data",
...>   data_id: 456,
...>   complexity: "high",
...>   batch_size: 5000
...> }
...> |> HeavyDataWorker.new()
...> |> Oban.insert()
```

**Parámetros:**
- `data_id` (requerido): ID de los datos a procesar
- `complexity`: "low", "medium", "high" (default: "medium")
- `batch_size`: número de registros (default: 1000)

#### 2. Generación de reportes
```elixir
iex> %{task: "generate_report", report_type: "sales"}
...> |> HeavyDataWorker.new()
...> |> Oban.insert()
```

**Tipos de reporte:** "sales", "analytics", "inventory", etc.

#### 3. Análisis de datasets
```elixir
iex> %{task: "analyze_dataset", dataset_id: "dataset-2024-01"}
...> |> HeavyDataWorker.new()
...> |> Oban.insert()
```

#### 4. Simular fallo (para testing)
```elixir
iex> %{task: "simulate_failure"}
...> |> HeavyDataWorker.new()
...> |> Oban.insert()
```

Este trabajo fallará y Oban automáticamente lo reintentará hasta 3 veces.

## 🎯 Opciones avanzadas

### Programar para el futuro
```elixir
# Ejecutar en 1 hora
iex> %{task: "process_data", data_id: 789}
...> |> HeavyDataWorker.new(schedule_in: 3600)
...> |> Oban.insert()

# Ejecutar en una fecha específica
iex> scheduled_at = DateTime.utc_now() |> DateTime.add(86400, :second)
iex> %{task: "generate_report", report_type: "monthly"}
...> |> HeavyDataWorker.new(scheduled_at: scheduled_at)
...> |> Oban.insert()
```

### Configurar prioridad
```elixir
# Mayor prioridad (0 = máxima, 3 = default)
iex> %{task: "process_data", data_id: 999}
...> |> HeavyDataWorker.new(priority: 0)
...> |> Oban.insert()
```

### Limitar reintentos
```elixir
# Solo 1 intento (sin reintentos)
iex> %{task: "process_data", data_id: 111}
...> |> HeavyDataWorker.new(max_attempts: 1)
...> |> Oban.insert()
```

### Agregar tags
```elixir
iex> %{task: "process_data", data_id: 222}
...> |> HeavyDataWorker.new(tags: ["urgent", "customer-123"])
...> |> Oban.insert()
```

## 📦 Insertar múltiples trabajos
```elixir
iex> jobs = for id <- 1..10 do
...>   %{task: "process_data", data_id: id}
...>   |> HeavyDataWorker.new()
...> end
iex> Oban.insert_all(jobs)
```

## 🔍 Consultar trabajos

### Ver trabajos pendientes
```elixir
iex> import Ecto.Query
iex> alias ObanApp.Repo
iex> Oban.Job
...> |> where([j], j.state == "available")
...> |> Repo.all()
```

### Ver trabajos completados
```elixir
iex> Oban.Job
...> |> where([j], j.state == "completed")
...> |> order_by([j], desc: j.completed_at)
...> |> limit(10)
...> |> Repo.all()
```

### Cancelar un trabajo
```elixir
iex> job_id = 123
iex> Oban.cancel_job(job_id)
```

## 🏗️ Crear tu propio Worker

```elixir
defmodule ObanApp.Workers.MiWorker do
  use Oban.Worker, 
    queue: :default,    # o :heavy para tareas pesadas
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Tu lógica aquí
    IO.inspect(args, label: "Procesando")
    
    # Retornar :ok o {:ok, resultado}
    {:ok, %{resultado: "éxito"}}
  end
end
```

## 🔥 Tips

1. **Monitoreo**: Siempre revisa el dashboard en `/dev/oban`
2. **Logs**: Los trabajos imprimen mensajes con emojis para fácil seguimiento
3. **Testing**: Usa `simulate_failure` para probar el sistema de reintentos
4. **Performance**: Ajusta la concurrencia de las colas según tus necesidades
5. **Producción**: En producción, protege el dashboard con autenticación

## 🚦 Iniciar el servidor

```bash
mix phx.server
```

Luego visita:
- **Aplicación**: http://localhost:4000
- **Oban Dashboard**: http://localhost:4000/dev/oban
- **LiveDashboard**: http://localhost:4000/dev/dashboard

## 📚 Recursos

- [Documentación de Oban](https://hexdocs.pm/oban/Oban.html)
- [Oban Web](https://getoban.pro/docs/web/overview.html)
- [Recetas de Oban](https://hexdocs.pm/oban/Oban.html#module-recipes)

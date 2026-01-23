# 💡 Mejores Prácticas con Oban

## 🎯 Casos de Uso Reales

### 1. Procesamiento de Archivos Grandes
```elixir
# Subida de archivo en un controller
def upload_file(conn, %{"file" => file_params}) do
  # Guardar archivo temporalmente
  file_path = save_uploaded_file(file_params)
  
  # Encolar procesamiento en segundo plano
  %{task: "process_file", file_path: file_path}
  |> FileWorker.new(queue: :heavy)
  |> Oban.insert()
  
  # Responder inmediatamente al usuario
  json(conn, %{status: "processing", message: "El archivo se está procesando"})
end
```

### 2. Envío de Emails en Lote
```elixir
defmodule ObanApp.Workers.EmailWorker do
  use Oban.Worker, queue: :mailer, max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"emails" => emails, "template" => template}}) do
    emails
    |> Enum.each(fn email ->
      ObanApp.Mailer.send_email(email, template)
    end)
    
    {:ok, %{sent: length(emails)}}
  end
end
```

### 3. Generación de Reportes Pesados
```elixir
# En un LiveView
def handle_event("generate_report", %{"type" => type}, socket) do
  case ObanApp.Examples.generate_report(type) do
    {:ok, job} ->
      {:noreply, 
       socket
       |> put_flash(:info, "Reporte en proceso. ID: #{job.id}")
       |> assign(:processing_job_id, job.id)}
    
    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Error al generar reporte")}
  end
end
```

### 4. Limpieza de Datos Antiguos (Cron-like)
```elixir
# Agregar a config/dev.exs
config :oban_app, Oban,
  repo: ObanApp.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Limpiar datos antiguos cada día a las 2 AM
       {"0 2 * * *", ObanApp.Workers.CleanupWorker},
       # Generar reporte semanal cada lunes a las 9 AM
       {"0 9 * * 1", ObanApp.Workers.WeeklyReportWorker}
     ]}
  ],
  queues: [default: 10, heavy: 5]
```

## 🔒 Seguridad

### Proteger el Dashboard en Producción
```elixir
# lib/oban_web/router.ex
if Mix.env() == :prod do
  pipeline :admin do
    plug :basic_auth
  end

  scope "/admin" do
    pipe_through [:browser, :admin]
    
    import Oban.Web.Router
    oban_dashboard "/oban"
  end
  
  defp basic_auth(conn, _opts) do
    username = System.get_env("ADMIN_USERNAME")
    password = System.get_env("ADMIN_PASSWORD")
    
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
```

## ⚡ Performance

### 1. Ajustar Concurrencia por Cola
```elixir
# config/runtime.exs
config :oban_app, Oban,
  queues: [
    default: String.to_integer(System.get_env("OBAN_DEFAULT_QUEUE", "10")),
    heavy: String.to_integer(System.get_env("OBAN_HEAVY_QUEUE", "5")),
    mailer: 20  # Emails pueden ser muchos y rápidos
  ]
```

### 2. Limitar Recursos de Trabajos Pesados
```elixir
defmodule ObanApp.Workers.HeavyWorker do
  use Oban.Worker, 
    queue: :heavy, 
    max_attempts: 3,
    # Limitar a 5 trabajos activos de este tipo
    unique: [period: 60, states: [:executing]]
  
  # ...
end
```

### 3. Batch Processing Eficiente
```elixir
# En lugar de un job por item:
def process_items_inefficient(items) do
  Enum.each(items, fn item ->
    %{item_id: item.id}
    |> Worker.new()
    |> Oban.insert()
  end)
end

# Mejor: agrupa en lotes
def process_items_efficient(items) do
  items
  |> Enum.chunk_every(100)
  |> Enum.each(fn batch ->
    %{item_ids: Enum.map(batch, & &1.id)}
    |> Worker.new()
    |> Oban.insert()
  end)
end
```

## 🚨 Manejo de Errores

### 1. Reintentos con Backoff Exponencial
```elixir
defmodule ObanApp.Workers.APIWorker do
  use Oban.Worker, 
    queue: :api,
    max_attempts: 5

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)

  @impl Oban.Worker
  def perform(%Oban.Job{attempt: attempt} = job) do
    case call_external_api(job.args) do
      {:ok, result} ->
        {:ok, result}
      
      {:error, :rate_limit} ->
        # Backoff exponencial: 1min, 2min, 4min, 8min, 16min
        {:snooze, trunc(:math.pow(2, attempt) * 60)}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### 2. Notificaciones de Fallos
```elixir
# Agregar a config/dev.exs
config :oban_app, Oban,
  plugins: [
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)},
    # Notificador personalizado
    {ObanApp.ErrorNotifier, []}
  ]
```

```elixir
# lib/oban_app/error_notifier.ex
defmodule ObanApp.ErrorNotifier do
  use Oban.Plugin

  @impl Oban.Plugin
  def init(opts), do: {:ok, opts}

  @impl Oban.Plugin
  def handle_event([:oban, :job, :exception], _measure, meta, _state) do
    %{job: job, kind: kind, reason: reason} = meta
    
    # Enviar notificación (Slack, email, etc.)
    notify_error(job, kind, reason)
    
    :ok
  end
  
  defp notify_error(job, kind, reason) do
    # Tu lógica de notificación
    IO.puts("❌ Job #{job.id} falló: #{inspect(kind)} - #{inspect(reason)}")
  end
end
```

## 📊 Monitoreo

### 1. Telemetry Events
```elixir
# lib/oban_web/telemetry.ex
def handle_event([:oban, :job, :start], _measure, meta, _state) do
  %{job: job} = meta
  Logger.info("Starting job: #{job.worker} (#{job.id})")
end

def handle_event([:oban, :job, :stop], measure, meta, _state) do
  %{job: job} = meta
  duration_ms = System.convert_time_unit(measure.duration, :native, :millisecond)
  
  Logger.info("Completed job: #{job.worker} (#{job.id}) in #{duration_ms}ms")
end
```

### 2. Métricas Personalizadas
```elixir
# En tu worker
def perform(job) do
  start_time = System.monotonic_time()
  
  result = do_work(job.args)
  
  duration = System.monotonic_time() - start_time
  :telemetry.execute(
    [:oban_app, :worker, :duration],
    %{duration: duration},
    %{worker: __MODULE__, queue: job.queue}
  )
  
  result
end
```

## 🎓 Tips Importantes

1. **Idempotencia**: Diseña tus workers para que puedan ejecutarse múltiples veces sin efectos secundarios
2. **Timeout**: Define timeouts apropiados para evitar trabajos eternos
3. **Logging**: Agrega logs detallados para debugging
4. **Testing**: Usa `Oban.Testing` para testear workers sin procesamiento real
5. **Documentación**: Documenta los argumentos esperados en cada worker
6. **Validación**: Valida los argumentos al inicio del perform/1
7. **Limpieza**: Usa `Oban.Plugins.Pruner` para limpiar trabajos antiguos
8. **Monitoreo**: Revisa regularmente el dashboard de Oban
9. **Recursos**: Considera el uso de recursos (memoria, CPU, DB) de cada worker
10. **Escalabilidad**: Diseña pensando en escalar horizontalmente

## 🧪 Testing

```elixir
# test/oban_app/workers/heavy_data_worker_test.exs
defmodule ObanApp.Workers.HeavyDataWorkerTest do
  use ObanApp.DataCase, async: true
  use Oban.Testing, repo: ObanApp.Repo

  alias ObanApp.Workers.HeavyDataWorker

  test "procesa datos correctamente" do
    job = 
      %{task: "process_data", data_id: 123}
      |> HeavyDataWorker.new()
      |> Oban.insert!()
    
    # Ejecutar el job
    assert :ok = perform_job(HeavyDataWorker, job.args)
    
    # Verificar resultados
    # ...
  end

  test "falla con argumentos inválidos" do
    job = 
      %{task: "unknown_task"}
      |> HeavyDataWorker.new()
      |> Oban.insert!()
    
    assert {:error, _} = perform_job(HeavyDataWorker, job.args)
  end
end
```

---

Para más información, consulta:
- [Documentación oficial de Oban](https://hexdocs.pm/oban)
- [Oban Web](https://getoban.pro/docs/web/overview.html)
- [Oban Recipes](https://hexdocs.pm/oban/Oban.html#module-recipes)

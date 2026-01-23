defmodule ObanApp.Workers.HeavyDataWorker do
  @moduledoc """
  Worker de ejemplo para procesamiento de datos pesados.

  Este worker simula tareas que requieren mucho tiempo o recursos,
  como procesamiento de archivos grandes, análisis de datos complejos,
  generación de reportes, etc.
  """
  use Oban.Worker, queue: :heavy, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task" => "process_data", "data_id" => data_id} = args}) do
    # Simular procesamiento pesado
    IO.puts("🚀 Iniciando procesamiento de datos para ID: #{data_id}")

    # Obtener configuración opcional
    complexity = Map.get(args, "complexity", Enum.random(["low", "medium", "high"]))
    batch_size = Map.get(args, "batch_size", 1000)

    # Simular diferentes tiempos de procesamiento según complejidad
    processing_time = case complexity do
      "low" -> 1_000
      "medium" -> 3_000
      "high" -> 5_000
      _ -> 2_000
    end

    IO.puts("⏳ Procesando #{batch_size} registros (complejidad: #{complexity})...")
    Process.sleep(processing_time)

    # Simular resultado exitoso
    IO.puts("✅ Procesamiento completado exitosamente para ID: #{data_id}")

    {:ok, %{
      data_id: data_id,
      records_processed: batch_size,
      complexity: complexity,
      processing_time_ms: processing_time,
      completed_at: DateTime.utc_now()
    }}
  end

  def perform(%Oban.Job{args: %{"task" => "generate_report", "report_type" => report_type}}) do
    IO.puts("📊 Generando reporte de tipo: #{report_type}")

    # Simular generación de reporte
    Process.sleep(2_000)

    report_path = "/tmp/reports/#{report_type}_#{:os.system_time(:second)}.pdf"

    IO.puts("✅ Reporte generado en: #{report_path}")

    {:ok, %{
      report_type: report_type,
      report_path: report_path,
      generated_at: DateTime.utc_now()
    }}
  end

  def perform(%Oban.Job{args: %{"task" => "analyze_dataset", "dataset_id" => dataset_id}}) do
    IO.puts("🔍 Analizando dataset: #{dataset_id}")

    # Simular análisis de datos
    Process.sleep(4_000)

    results = %{
      total_records: :rand.uniform(10_000),
      valid_records: :rand.uniform(9_000),
      errors: :rand.uniform(100),
      warnings: :rand.uniform(500)
    }

    IO.puts("✅ Análisis completado: #{inspect(results)}")

    {:ok, Map.put(results, :analyzed_at, DateTime.utc_now())}
  end

  def perform(%Oban.Job{args: %{"task" => "simulate_failure"}}) do
    # Simular un fallo para demostrar reintentos
    IO.puts("❌ Simulando fallo en el procesamiento...")
    {:error, "Simulated failure for testing retry mechanism"}
  end

  def perform(%Oban.Job{args: args}) do
    # Caso por defecto para argumentos no reconocidos
    IO.puts("⚠️ Tarea no reconocida: #{inspect(args)}")
    {:error, "Unknown task type"}
  end
end

defmodule ObanApp.Workers.HeavyDataWorker do
  @moduledoc """
  Example worker for heavy data processing.

  This worker simulates tasks that require significant time or resources,
  such as processing large files, complex data analysis,
  report generation, etc.
  """
  use Oban.Worker, queue: :heavy, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task" => "process_data", "data_id" => data_id} = args}) do
    # Simulate heavy processing
    IO.puts("🚀 Iniciando procesamiento de datos para ID: #{data_id}")

    # Get optional configuration
    complexity = Map.get(args, "complexity", Enum.random(["low", "medium", "high"]))
    batch_size = Map.get(args, "batch_size", 1000)

    # Simulate different processing times based on complexity
    processing_time = case complexity do
      "low" -> 1_000
      "medium" -> 3_000
      "high" -> 5_000
      _ -> 2_000
    end

    IO.puts("⏳ Procesando #{batch_size} registros (complejidad: #{complexity})...")
    Process.sleep(processing_time)

    # Simulate successful result
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

    # Simulate report generation
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

    # Simulate data analysis
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
    # Simulate a failure to demonstrate retries
    IO.puts("❌ Simulando fallo en el procesamiento...")
    {:error, "Simulated failure for testing retry mechanism"}
  end

  def perform(%Oban.Job{args: args}) do
    # Default case for unrecognized arguments
    IO.puts("⚠️ Tarea no reconocida: #{inspect(args)}")
    {:error, "Unknown task type"}
  end
end

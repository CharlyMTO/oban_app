defmodule ObanApp.Examples do
  @moduledoc """
  Ejemplos de uso de Oban Workers en tu aplicación.

  Puedes llamar estas funciones desde tus controllers, LiveViews, o cualquier
  parte de tu aplicación Phoenix.
  """

  alias ObanApp.Workers.HeavyDataWorker

  @doc """
  Encola un trabajo para procesar datos.

  ## Ejemplos

      iex> ObanApp.Examples.process_data(123)
      {:ok, %Oban.Job{}}

      iex> ObanApp.Examples.process_data(123, complexity: "high", batch_size: 5000)
      {:ok, %Oban.Job{}}
  """
  def process_data(data_id, opts \\ []) do
    complexity = Keyword.get(opts, :complexity, "medium")
    batch_size = Keyword.get(opts, :batch_size, 1000)

    %{
      task: "process_data",
      data_id: data_id,
      complexity: complexity,
      batch_size: batch_size
    }
    |> HeavyDataWorker.new()
    |> Oban.insert()
  end

  @doc """
  Encola un trabajo para generar un reporte.

  ## Ejemplos

      iex> ObanApp.Examples.generate_report("sales")
      {:ok, %Oban.Job{}}
  """
  def generate_report(report_type) do
    %{
      task: "generate_report",
      report_type: report_type
    }
    |> HeavyDataWorker.new()
    |> Oban.insert()
  end

  @doc """
  Encola un trabajo para analizar un dataset.

  ## Ejemplos

      iex> ObanApp.Examples.analyze_dataset("dataset-2024-01")
      {:ok, %Oban.Job{}}
  """
  def analyze_dataset(dataset_id) do
    %{
      task: "analyze_dataset",
      dataset_id: dataset_id
    }
    |> HeavyDataWorker.new()
    |> Oban.insert()
  end

  @doc """
  Procesa múltiples datos en lote.

  ## Ejemplos

      iex> ObanApp.Examples.process_batch([1, 2, 3, 4, 5])
      {:ok, 5}
  """
  def process_batch(data_ids) when is_list(data_ids) do
    jobs =
      data_ids
      |> Enum.map(fn id ->
        %{task: "process_data", data_id: id}
        |> HeavyDataWorker.new()
      end)

    case Oban.insert_all(jobs) do
      {count, _} -> {:ok, count}
      error -> error
    end
  end

  @doc """
  Programa un trabajo para ejecutarse en el futuro.

  ## Ejemplos

      # Procesar en 1 hora
      iex> ObanApp.Examples.schedule_processing(123, hours: 1)
      {:ok, %Oban.Job{}}

      # Procesar en 30 minutos
      iex> ObanApp.Examples.schedule_processing(456, minutes: 30)
      {:ok, %Oban.Job{}}
  """
  def schedule_processing(data_id, schedule_opts) do
    seconds = cond do
      hours = Keyword.get(schedule_opts, :hours) -> hours * 3600
      minutes = Keyword.get(schedule_opts, :minutes) -> minutes * 60
      seconds = Keyword.get(schedule_opts, :seconds) -> seconds
      true -> 0
    end

    %{task: "process_data", data_id: data_id}
    |> HeavyDataWorker.new(schedule_in: seconds)
    |> Oban.insert()
  end

  @doc """
  Cancela un trabajo por su ID.

  ## Ejemplos

      iex> ObanApp.Examples.cancel_job(123)
      {:ok, %Oban.Job{}}
  """
  def cancel_job(job_id) do
    Oban.cancel_job(job_id)
  end

  @doc """
  Obtiene el estado de un trabajo.

  ## Ejemplos

      iex> ObanApp.Examples.get_job_status(123)
      {:ok, %Oban.Job{state: "completed"}}
  """
  def get_job_status(job_id) do
    case ObanApp.Repo.get(Oban.Job, job_id) do
      nil -> {:error, :not_found}
      job -> {:ok, job}
    end
  end

  @doc """
  Lista trabajos por estado.

  ## Ejemplos

      iex> ObanApp.Examples.list_jobs_by_state("completed")
      [%Oban.Job{}, ...]

      iex> ObanApp.Examples.list_jobs_by_state("executing", limit: 5)
      [%Oban.Job{}, ...]
  """
  def list_jobs_by_state(state, opts \\ []) do
    import Ecto.Query

    limit = Keyword.get(opts, :limit, 10)

    Oban.Job
    |> where([j], j.state == ^state)
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> ObanApp.Repo.all()
  end

  @doc """
  Reintenta un trabajo fallido.

  ## Ejemplos

      iex> ObanApp.Examples.retry_job(123)
      {:ok, %Oban.Job{}}
  """
  def retry_job(job_id) do
    Oban.retry_job(job_id)
  end
end

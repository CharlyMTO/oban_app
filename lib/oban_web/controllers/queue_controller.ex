defmodule ObanWeb.QueueController do
  use ObanWeb, :controller

  def add_queue(conn, _params) do
    # Generar un ID único para cada trabajo
    data_id = "data_#{:os.system_time(:millisecond)}"

    # Insertar el trabajo en Oban
    case %{task: "process_data", data_id: data_id}
         |> ObanApp.Workers.HeavyDataWorker.new()
         |> Oban.insert() do
      {:ok, job} ->
        conn
        |> put_flash(:info, "✅ Trabajo agregado a la cola! ID: #{data_id}, Job: ##{job.id}")
        |> redirect(to: "/dev/oban")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "❌ Error al agregar trabajo: #{inspect(changeset.errors)}")
        |> redirect(to: "/")
    end
  end
end

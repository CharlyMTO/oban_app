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

  def add_queue_pdf(conn, _params) do
    # Generar un ID único para el trabajo de PDF
    pdf_id = "pdf_#{:os.system_time(:millisecond)}"

    # Insertar el trabajo en Oban
    case %{pdf_id: pdf_id}
         |> ObanApp.Workers.PdfWorker.new()
         |> Oban.insert() do
      {:ok, job} ->
        conn
        |> put_flash(:info, "✅ Trabajo PDF agregado a la cola! ID: #{pdf_id}, Job: ##{job.id}")
        |> redirect(to: "/dev/oban")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "❌ Error al agregar trabajo PDF: #{inspect(changeset.errors)}")
        |> redirect(to: "/")
    end
  end
end

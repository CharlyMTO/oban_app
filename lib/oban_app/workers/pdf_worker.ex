defmodule ObanApp.Workers.PdfWorker do
  @moduledoc """
  Worker to generate PDFs via HTTP requests to /gen_pdf.

  This worker makes an HTTP request to the local PDF generation endpoint
  and handles the response, saving the file or logging errors.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"pdf_id" => pdf_id} = _args}) do
    Logger.info("📄 Iniciando generación de PDF para ID: #{pdf_id}")

    # Local endpoint URL
    url = "http://localhost:4000/gen_pdf"

    # Make HTTP request using Req
    case Req.get(url) do
      {:ok, %{status: 200, body: pdf_content, headers: headers}} ->
        Logger.info("✅ PDF generado exitosamente para ID: #{pdf_id}")

        # Extract filename from content-disposition header if it exists
        filename = extract_filename(headers) || "pdf_#{pdf_id}.pdf"

        # Save the PDF (optional - endpoint already saves it, but we can save with a different name)
        pdf_dir = Path.join(File.cwd!(), "pdfs")
        File.mkdir_p!(pdf_dir)
        filepath = Path.join(pdf_dir, "worker_#{filename}")

        case File.write(filepath, pdf_content, [:binary]) do
          :ok ->
            Logger.info("📁 PDF guardado en: #{filepath}")
            {:ok, %{
              pdf_id: pdf_id,
              filename: filename,
              filepath: filepath,
              size_bytes: byte_size(pdf_content),
              completed_at: DateTime.utc_now()
            }}

          {:error, reason} ->
            Logger.error("❌ Error al guardar PDF: #{inspect(reason)}")
            {:error, reason}
        end

      {:ok, %{status: status, body: body}} ->
        Logger.error("❌ Error en generación de PDF. Status: #{status}, Body: #{inspect(body)}")
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        Logger.error("❌ Error en petición HTTP: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Extract filename from Content-Disposition header
  defp extract_filename(headers) do
    headers
    |> Enum.find(fn {key, _value} -> String.downcase(key) == "content-disposition" end)
    |> case do
      {_key, value} ->
        case Regex.run(~r/filename="([^"]+)"/, value) do
          [_, filename] -> filename
          _ -> nil
        end

      nil ->
        nil
    end
  end
end

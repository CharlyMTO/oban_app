defmodule ObanWeb.PdfController do
  use ObanWeb, :controller
  require Logger

  def gen_pdf(conn, _params) do
    # Seleccionar aleatoriamente un template (1 o 2)
    template_number = Enum.random([1, 2])
    template_path = Path.join([File.cwd!(), "templates", "#{template_number}.html"])

    Logger.info("Cargando template #{template_number} desde: #{template_path}")

    # Leer el contenido del archivo HTML
    html_content = case File.read(template_path) do
      {:ok, content} ->
        Logger.info("✓ Template cargado exitosamente (#{byte_size(content)} bytes)")
        content
      {:error, reason} ->
        Logger.error("Error al leer template: #{inspect(reason)}")
        # Fallback a un HTML simple si falla la lectura
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Error</title>
        </head>
        <body>
          <h1>Error al cargar template</h1>
          <p>No se pudo leer el archivo: #{template_path}</p>
        </body>
        </html>
        """
    end

    Logger.info("Iniciando generación de PDF...")

    case ChromicPDF.print_to_pdf({:html, html_content}) do
      {:ok, pdf_content} ->
        # Decodificar si está en Base64
        decoded_pdf =
          if is_binary(pdf_content) and String.starts_with?(pdf_content, "JVBER") do
            Logger.info("Detectado contenido Base64, decodificando...")
            Base.decode64!(pdf_content)
          else
            pdf_content
          end

        pdf_size = byte_size(decoded_pdf)
        Logger.info("PDF generado exitosamente, tamaño: #{pdf_size} bytes")

        # Verificar que sea un PDF válido (debe comenzar con %PDF)
        pdf_header = binary_part(decoded_pdf, 0, min(10, pdf_size))
        Logger.info("PDF header: #{inspect(pdf_header, limit: :infinity)}")

        if String.starts_with?(pdf_header, "%PDF") do
          Logger.info("✓ PDF header válido detectado")
        else
          Logger.error("✗ PDF header inválido - el archivo puede estar corrupto")
        end

        # Crear directorio pdfs si no existe
        pdf_dir = Path.join(File.cwd!(), "pdfs")
        File.mkdir_p!(pdf_dir)

        # Generar nombre de archivo con timestamp
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        filename = "output_#{timestamp}.pdf"
        filepath = Path.join(pdf_dir, filename)

        # Guardar el PDF usando IO.binwrite para mayor seguridad
        case File.open(filepath, [:write, :binary]) do
          {:ok, file} ->
            IO.binwrite(file, decoded_pdf)
            File.close(file)
            Logger.info("PDF guardado exitosamente en: #{filepath}")

            # Verificar que el archivo guardado tiene el mismo tamaño
            case File.stat(filepath) do
              {:ok, %{size: saved_size}} ->
                if saved_size == pdf_size do
                  Logger.info("✓ Tamaño verificado: #{saved_size} bytes")
                else
                  Logger.error("✗ Tamaño no coincide! Original: #{pdf_size}, Guardado: #{saved_size}")
                end
              {:error, reason} ->
                Logger.error("No se pudo verificar el archivo: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.error("Error al abrir archivo para escritura: #{inspect(reason)}")
        end

        # También devolver el PDF al navegador
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "inline; filename=\"#{filename}\"")
        |> put_resp_header("content-length", "#{pdf_size}")
        |> send_resp(200, decoded_pdf)

      {:error, reason} ->
        Logger.error("Error generando PDF: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> put_status(503)
        |> json(%{
          success: false,
          error: "PDF Generation Error",
          reason: inspect(reason)
        })
    end
  end
end

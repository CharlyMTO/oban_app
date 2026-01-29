defmodule ObanWeb.PdfController do
  use ObanWeb, :controller
  require Logger

  def gen_pdf(conn, _params) do
    # Randomly select a template (1 or 2)
    template_number = Enum.random([1, 2])
    template_path = Path.join([File.cwd!(), "templates", "#{template_number}.html"])

    Logger.info("Loading template #{template_number} from: #{template_path}")

    # Read HTML file content
    html_content = case File.read(template_path) do
      {:ok, content} ->
        Logger.info("✓ Template loaded successfully (#{byte_size(content)} bytes)")
        content
      {:error, reason} ->
        Logger.error("Error reading template: #{inspect(reason)}")
        # Fallback to simple HTML if read fails
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Error</title>
        </head>
        <body>
          <h1>Error loading template</h1>
          <p>Could not read file: #{template_path}</p>
        </body>
        </html>
        """
    end

    Logger.info("Starting PDF generation...")

    case ChromicPDF.print_to_pdf({:html, html_content}) do
      {:ok, pdf_content} ->
        # Decode if Base64 encoded
        decoded_pdf =
          if is_binary(pdf_content) and String.starts_with?(pdf_content, "JVBER") do
            Logger.info("Base64 content detected, decoding...")
            Base.decode64!(pdf_content)
          else
            pdf_content
          end

        pdf_size = byte_size(decoded_pdf)
        Logger.info("PDF generated successfully, size: #{pdf_size} bytes")

        # Verify valid PDF (must start with %PDF)
        pdf_header = binary_part(decoded_pdf, 0, min(10, pdf_size))
        Logger.info("PDF header: #{inspect(pdf_header, limit: :infinity)}")

        if String.starts_with?(pdf_header, "%PDF") do
          Logger.info("✓ Valid PDF header detected")
        else
          Logger.error("✗ Invalid PDF header - file may be corrupted")
        end

        # Create pdfs directory if it doesn't exist
        pdf_dir = Path.join(File.cwd!(), "pdfs")
        File.mkdir_p!(pdf_dir)

        # Generate filename with timestamp
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        filename = "output_#{timestamp}.pdf"
        filepath = Path.join(pdf_dir, filename)

        # Save PDF using IO.binwrite for greater safety
        case File.open(filepath, [:write, :binary]) do
          {:ok, file} ->
            IO.binwrite(file, decoded_pdf)
            File.close(file)
            Logger.info("PDF saved successfully at: #{filepath}")

            # Verify saved file has the same size
            case File.stat(filepath) do
              {:ok, %{size: saved_size}} ->
                if saved_size == pdf_size do
                  Logger.info("✓ Size verified: #{saved_size} bytes")
                else
                  Logger.error("✗ Size mismatch! Original: #{pdf_size}, Saved: #{saved_size}")
                end
              {:error, reason} ->
                Logger.error("Could not verify file: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.error("Error opening file for writing: #{inspect(reason)}")
        end

        # Also return PDF to browser
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "inline; filename=\"#{filename}\"")
        |> put_resp_header("content-length", "#{pdf_size}")
        |> send_resp(200, decoded_pdf)

      {:error, reason} ->
        Logger.error("Error generating PDF: #{inspect(reason)}")

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

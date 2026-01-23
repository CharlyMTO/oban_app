defmodule ObanWeb.PdfController do
  use ObanWeb, :controller

  def gen_pdf(conn, _params) do
    case ChromicPDF.print_to_pdf({:html, "<h1>Hello World</h1>"}) do
      {:ok, pdf_content} ->
        # Crear directorio pdfs si no existe
        pdf_dir = Path.join(File.cwd!(), "pdfs")
        File.mkdir_p!(pdf_dir)

        # Generar nombre de archivo con timestamp
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        filename = "output_#{timestamp}.pdf"
        filepath = Path.join(pdf_dir, filename)

        # Guardar el PDF
        File.write!(filepath, pdf_content)

        # Responder con éxito
        conn
        |> put_resp_content_type("application/json")
        |> json(%{
          success: true,
          message: "PDF generated successfully",
          file: filename,
          path: filepath
        })

      {:error, reason} ->
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

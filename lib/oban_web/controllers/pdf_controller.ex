defmodule ObanWeb.PdfController do
  use ObanWeb, :controller

  def gen_pdf(conn, _params) do
    # Verificar si ChromicPDF está disponible
    if Process.whereis(ChromicPDF.Supervisor) do
      # Generar el PDF
      {:ok, pdf_content} = ChromicPDF.print_to_pdf({:html, "<h1>Hello World</h1>"})

      # Enviar el PDF como respuesta
      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "inline; filename=\"output.pdf\"")
      |> send_resp(200, pdf_content)
    else
      # ChromicPDF no está disponible
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(503, """
      <html>
        <body>
          <h1>PDF Generation Not Available</h1>
          <p>ChromicPDF is not running. Please install Chrome/Chromium:</p>
          <pre>sudo apt install -y chromium-browser</pre>
          <p>Then restart the application.</p>
        </body>
      </html>
      """)
    end
  end
end

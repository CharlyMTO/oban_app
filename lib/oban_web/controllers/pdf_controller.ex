defmodule ObanWeb.PdfController do
  use ObanWeb, :controller

  def gen_pdf(conn, _params) do
    case ChromicPDF.print_to_pdf({:html, "<h1>Hello World</h1>"}) do
      {:ok, pdf_content} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "inline; filename=\"output.pdf\"")
        |> send_resp(200, pdf_content)

      {:error, reason} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(503, """
        <html>
          <body>
            <h1>PDF Generation Error</h1>
            <p>Error: #{inspect(reason)}</p>
            <p>Make sure Chrome/Chromium is installed:</p>
            <pre>sudo apt install -y chromium-browser</pre>
          </body>
        </html>
        """)
    end
  end
end

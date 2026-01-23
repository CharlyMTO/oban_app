defmodule ObanWeb.PdfController do
  use ObanWeb, :controller

  def gen_pdf(conn, _params) do
    # Generar el PDF
    {:ok, pdf_content} = ChromicPDF.print_to_pdf({:html, "<h1>Hello World</h1>"})

    # Enviar el PDF como respuesta
    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", "inline; filename=\"output.pdf\"")
    |> send_resp(200, pdf_content)
  end
end

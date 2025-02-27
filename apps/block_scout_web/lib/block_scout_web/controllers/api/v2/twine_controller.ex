defmodule BlockScoutWeb.API.V2.TwineController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [
      next_page_params: 4,
      paging_options: 1,
      split_list_by_page: 1
    ]

  alias Explorer.Chain.Twine.{Reader, TransactionBatch}

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @batch_necessity_by_association %{
    # :batch_details => :required,
    # :commit_transaction => :optional,
    # # # :prove_transaction => :optional,
    # :execute_transaction => :optional
  }

  @doc """
    Function to handle GET requests to `/api/v2/twine/batches/:batch_number` endpoint.
  """
  @spec batch(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def batch(conn, %{"batch_number" => batch_number}) do
    case Reader.batch(batch_number) do
      {:ok, batch} ->
        conn
        |> put_status(200)
        |> render(:twine_batch, batch: batch)

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "Batch not found"})
    end
  end

  @doc """
    Function to handle GET requests to `/api/v2/twine/batches` endpoint.
  """

  @spec batches(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def batches(conn, params) do
    {batches, next_page} =
      params
      |> paging_options()
      |> Keyword.put(:necessity_by_association, @batch_necessity_by_association)
      |> Reader.batches()
      |> split_list_by_page()

    next_page_params =
      next_page_params(
        next_page,
        batches,
        params,
        fn %TransactionBatch{number: number} -> %{"number" => number} end
      )

    conn
    |> put_status(200)
    |> render(:twine_batches, %{batches: batches, next_page_params: next_page_params})
  end


  @doc """
    Function to handle GET requests to `/api/v2/twine/batches/count` endpoint.
  """

@spec batches_count(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def batches_count(conn, _params) do
    count = Reader.batches_count()

    conn
    |> put_status(200)
    |> render(:twine_batches_count, %{count: count})
  end

@spec batches_confirmed(Plug.Conn.t(), map()) :: Plug.Conn.t()
def batches_confirmed(conn, _params) do
  batches =
    []
    |> Keyword.put(:necessity_by_association, @batch_necessity_by_association)
    |> Keyword.put(:api?, true)
    |> Keyword.put(:confirmed?, true)
    |> Reader.batches()

  conn
  |> put_status(200)
  |> render(:twine_batches, %{batches: batches})
end


  @spec batch_latest_number(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def batch_latest_number(conn, _params) do
    number = Reader.batch_latest_number()

    conn
    |> put_status(200)
    |> render(:twine_batch_latest_number, %{number: number})
  end

  defp batch_latest_number do
    case Reader.batch(:latest, api?: true) do
      {:ok, batch} -> batch.number
      {:error, :not_found} -> 0
    end
  end

end

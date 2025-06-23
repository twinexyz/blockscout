defmodule Explorer.Chain.Twine.Reader do
  @moduledoc "Reads data from the Twine chain."

  require Logger

  import Ecto.Query,
    only: [
      from: 2,
      limit: 2,
      order_by: 2,
      where: 2,
      where: 3,
      join: 5,
      select: 3,
      preload: 3
    ]

  import Explorer.Chain, only: [select_repo: 1]

  alias Explorer.Chain.Twine.{
    TransactionBatch,
    TransactionBatchDetail,
    BatchBlock,
    CelestiaBlob
  }

  alias Explorer.Chain.Hash
  alias Explorer.{Chain, PagingOptions, Repo}

  @doc """
    Returns the number of batches in the Twine chain.

    ## Examples

        iex> Explorer.Chain.Twine.Reader.batches_count(%{})
        {:ok, 42}
  """

  @spec batches_count(keyword()) :: any()
  def batches_count(options) do
    TransactionBatch
    |> select_repo(options).aggregate(:count, timeout: :infinity)
  end

  defp build_batch_query(query \\ nil) do
    # If no query is provided, create the base query
    query = query || from(b in TransactionBatch, select: b)

    from(b in query,
      order_by: [desc: b.number],
      left_join: d in TransactionBatchDetail,
      on: d.batch_number == b.number,
      preload: [batch_details: d]
    )
  end

  @doc """
    Returns the latest batch in the Twine chain.

    ## Examples

        iex> Explorer.Chain.Twine.Reader.batch(:latest, %{})
        {:ok, %Explorer.Chain.Twine.TransactionBatch{...}}
  """

  @spec batch(:latest | binary() | integer(), keyword()) ::
          {:error, :not_found} | {:ok, Explorer.Chain.Twine.TransactionBatch}
  def batch(batch_number, opts \\ [])

  def batch(batch_number, opts) when is_list(opts) do
    query = build_batch_query()

    query =
      case batch_number do
        "latest" ->
          # Get the most recent batch
          from(b in query, order_by: [desc: b.number], limit: 1)

        batch_number when is_integer(batch_number) or is_binary(batch_number) ->
          # Query by batch number
          from(b in query, where: b.number == ^batch_number)

        _ ->
          # Default case, if the value is something unexpected
          query
      end

    case select_repo(opts).one(query) do
      nil -> {:error, :not_found}
      batch -> {:ok, batch}
    end
  end

  @doc """
    Returns a list of batches in the Twine chain.

    ## Examples

        iex> Explorer.Chain.Twine.Reader.batches(1, 10, %{})
        {:ok, [%Explorer.Chain.Twine.TransactionBatch{...}, ...]}
  """

  @spec batches(integer(), integer(), keyword()) :: [TransactionBatch]

  def batches(start_number, end_number, options)
      when is_integer(start_number) and
             is_integer(end_number) and
             is_list(options) do
    necessity_by_association = Keyword.get(options, :necessity_by_association, %{})

    base_query = from(tb in TransactionBatch, order_by: [desc: tb.number])

    base_query
    |> where([tb], tb.number >= ^start_number and tb.number <= ^end_number)
    |> join(:left, [tb], bd in BatchDetails, on: tb.number == bd.batch_number)
    |> Chain.join_associations(necessity_by_association)
    |> select_repo(options).all()
  end

  @spec batches(keyword()) :: [Explorer.Chain.Twine.TransactionBatch]
  @spec batches() :: [Explorer.Chain.Twine.TransactionBatch]
  def batches(options \\ []) do
    # necessity_by_association = Keyword.get(options, :necessity_by_association, %{})

    base_query = build_batch_query()

    query =
      if Keyword.get(options, :confirmed?, false) do
        base_query
        # |> Chain.join_associations(@necessity_by_association)
        |> where([tb], not is_nil(tb.commit_id) and tb.commit_id > 0)
        |> limit(10)
      else
        paging_options = Keyword.get(options, :paging_options, Chain.default_paging_options())

        case paging_options do
          %PagingOptions{key: {0}} ->
            []

          _ ->
            base_query
            |> page_batches(paging_options)
            |> limit(^paging_options.page_size)
        end
      end

    select_repo(options).all(query)
  end

  defp page_batches(query, %PagingOptions{key: nil}), do: query

  defp page_batches(query, %PagingOptions{key: {number}}) do
    from(tb in query, where: tb.number < ^number)
  end

  @doc """
    Returns the commitment hash, namespace, and height for a given Twine block hash.

    ## Examples

        iex> Explorer.Chain.Twine.Reader.celestia_commitment_info_by_block("0x123...", %{})
        {:ok, %{commitment_hash: "0xabc...", namespace: "celestia-namespace-01", height: 0}}
  """
  @spec celestia_commitment_info_by_block(Hash.t(), keyword()) :: {:ok, %{commitment_hash: String.t(), namespace: String.t(), height: integer()}} | {:error, :not_found}
  def celestia_commitment_info_by_block(block_hash, options \\ [])
  def celestia_commitment_info_by_block(%Explorer.Chain.Hash{bytes: bytes}, options) do
    celestia_commitment_info_by_block(bytes, options)
  end
  def celestia_commitment_info_by_block(block_hash, options) when is_binary(block_hash) do
    query =
      from(b in CelestiaBlob,
        where: b.twine_block_hash == ^block_hash,
        select: %{commitment_hash: b.commitment_hash, namespace: b.namespace, height: b.height},
        limit: 1
      )

    result = select_repo(options).one(query)

    case result do
      nil -> {:error, :not_found}
      info -> {:ok, info}
    end
  end
end

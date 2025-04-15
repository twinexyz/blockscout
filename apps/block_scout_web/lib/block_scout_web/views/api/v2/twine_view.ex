defmodule BlockScoutWeb.API.V2.TwineView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.Twine.TransactionBatchDetail
  alias Explorer.Chain.{Block, Transaction}
  alias Explorer.Chain.Twine.TransactionBatch

  alias BlockScoutWeb.API.V2.Helper, as: APIV2Helper

  require Logger

  @doc """
    Function to render GET requests to `/api/v2/twine/batches/:batch_number` endpoint.
  """
  @spec render(binary(), map()) :: map() | non_neg_integer()
  def render("twine_batch.json", %{batch: batch}) do
    %{
      number: batch.number,
      start_block: batch.start_block,
      end_block: batch.end_block,
      timestamp: batch.timestamp,
      root_hash: batch.root_hash,
      details: render_many(batch.batch_details, __MODULE__, "twine_batch_detail.json", as: :twine_batch_detail)
    }
  end

  @doc """
    Function to render details of batch.
  """

  def render("twine_batch_detail.json", %{twine_batch_detail: detail}) do
    %{
      id: detail.id,
      l1_transaction_count: detail.l1_transaction_count,
      l2_transaction_count: detail.l2_transaction_count,
      l1_gas_price: detail.l1_gas_price,
      l2_fair_gas_price: detail.l2_fair_gas_price,
      chain_id: detail.chain_id
    }
    |> add_l1_transactions_info_and_status(detail)
  end

  @doc """
    Function to render GET requests to `/api/v2/twine/batches` endpoint.
  """

  @spec render(binary(), map()) :: map() | non_neg_integer()
  def render("twine_batches.json", %{batches: batches, next_page_params: next_page_params}) do
    %{
      batches: render_many(batches, __MODULE__, "twine_batch.json", as: :batch),
      next_page_params: next_page_params
    }
  end

  def render("twine_batches.json", %{batches: batches}) do
    %{batches: render_many(batches, __MODULE__, "twine_batch.json", as: :batch)}
  end

  @doc """
    Function to render GET requests to `/api/v2/twine/batches/count` endpoint.
  """
  def render("twine_batches_count.json", %{count: count}) do
    count
  end

  @doc """
    Function to render GET requests to `/api/v2/twine/batches/latest-number` endpoint.
  """
  def render("twine_batch_latest_number.json", %{number: number}) do
    number
  end

  @doc """
  Extends the output JSON with L1 transaction information and status.
  """

  @spec extend_transaction_json_response(map(), %{
          :__struct__ => Explorer.Chain.Transaction,
          :twine_batch => any(),
          :twine_commit_transaction => any(),
          :twine_prove_transaction => any(),
          :twine_execute_transaction => any(),
          optional(any()) => any()
        }) :: map()

  def extend_transaction_json_response(out_json, %Transaction{} = transaction) do
    do_add_twine_info(out_json, transaction)
  end

  @spec extend_block_json_response(map(), %{
          :__struct__ => Explorer.Chain.Block,
          :twine_batch => any(),
          :twine_commit_transaction => any(),
          # :twine_prove_transaction => any(),
          :twine_execute_transaction => any(),
          optional(any()) => any()
        }) :: map()

  def extend_block_json_response(out_json, %Block{} = block) do
    do_add_twine_info(out_json, block)
  end

  defp do_add_twine_info(out_json, twine_item) do

    Map.put(out_json, "twine", %{
      number: twine_item.twine_batch && twine_item.twine_batch.number,
      start_block: twine_item.twine_batch && twine_item.twine_batch.start_block,
      end_block: twine_item.twine_batch && twine_item.twine_batch.end_block,
      timestamp: twine_item.twine_batch && twine_item.twine_batch.timestamp,
      root_hash: twine_item.twine_batch && twine_item.twine_batch.root_hash,
      details: render_many(
        (twine_item.twine_batch && twine_item.twine_batch.batch_details) || [],
        __MODULE__,
        "twine_batch_detail.json",
        as: :twine_batch_detail
      )
    })

  end

  defp get_batch_number(twine_entity) do
    case Map.get(twine_entity, :twine_batch) do
      nil -> nil
      %Ecto.Association.NotLoaded{} -> nil
      value -> value.number
    end
  end

  defp add_l1_transactions_info_and_status(out_json, %TransactionBatchDetail{} = batch) do
    do_add_l1_transactions_info_and_status(out_json, batch)
  end

  defp do_add_l1_transactions_info_and_status(out_json, twine_item) do
    l1_transactions = get_associated_l1_transactions(twine_item)


    out_json
    |> Map.merge(%{
      "status" => batch_status(twine_item),
      "commit_transaction_hash" => APIV2Helper.get_2map_data(l1_transactions, :commit_transaction, :hash),
      "commit_transaction_timestamp" => APIV2Helper.get_2map_data(l1_transactions, :commit_transaction, :ts),
      "prove_transaction_hash" => APIV2Helper.get_2map_data(l1_transactions, :prove_transaction, :hash),
      "prove_transaction_timestamp" => APIV2Helper.get_2map_data(l1_transactions, :prove_transaction, :ts),
      "execute_transaction_hash" => APIV2Helper.get_2map_data(l1_transactions, :execute_transaction, :hash),
      "execute_transaction_timestamp" => APIV2Helper.get_2map_data(l1_transactions, :execute_transaction, :ts)
    })
  end

  # Extract transaction hash and timestamp for L1 transactions associated with
  # a twine rollup entity: batch, transaction or block.
  #
  # ## Parameters
  # - `twine_item`: A batch, transaction, or block.
  #
  # ## Returns
  # A map containing nesting maps describing corresponding L1 transactions
  defp get_associated_l1_transactions(twine_item) do
    [:commit_transaction, :execute_transaction]
    |> Enum.reduce(%{}, fn key, l1_transactions ->
      case Map.get(twine_item, key) do
        nil -> Map.put(l1_transactions, key, nil)
        %Ecto.Association.NotLoaded{} -> Map.put(l1_transactions, key, nil)
        value -> Map.put(l1_transactions, key, %{hash: Base.encode16(value.hash, case: :lower), ts: value.timestamp})
      end
    end)
  end

  # Inspects L1 transactions of the batch to determine the batch status.
  #
  # ## Parameters
  # - `twine_item`: A batch, transaction, or block.
  #
  # ## Returns
  # A string with one of predefined statuses
  defp batch_status(twine_item) do
    cond do
      APIV2Helper.specified?(twine_item.execute_transaction) -> "Executed on L1"
      APIV2Helper.specified?(twine_item.prove_transaction) -> "Validated on L1"
      APIV2Helper.specified?(twine_item.commit_transaction) -> "Sent to L1"
      # Batch entity itself has no batch_number
      not Map.has_key?(twine_item, :batch_number) -> "Sealed on L2"
      not is_nil(twine_item.batch_number) -> "Sealed on L2"
      true -> "Processed on L2"
    end
  end
end

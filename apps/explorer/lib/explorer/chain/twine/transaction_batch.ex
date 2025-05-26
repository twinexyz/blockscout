defmodule Explorer.Chain.Twine.TransactionBatch do
  @moduledoc "Models a batch of transactions for Twine."

  use Explorer.Schema

  alias Explorer.Chain.Twine.TransactionBatchDetail
  alias Explorer.Chain.{
    Block,
    Hash,
    Wei
  }

  @required_attrs ~w(number timestamp root_hash start_block end_block)a

  @type t :: %__MODULE__{
          number: non_neg_integer(),
          timestamp: DateTime.t(),
          root_hash: Hash.t() | nil,
          start_block: Block.block_number(),
          end_block: Block.block_number(),

          batch_details: %Ecto.Association.NotLoaded{} | TransactionBatchDetail.t() | nil
        }

  @primary_key {:number, :integer, autogenerate: false}
  schema "twine_transaction_batch" do
    field(:timestamp, :utc_datetime_usec)
    field(:root_hash, Hash.Full)
    field(:start_block, :integer)
    field(:end_block, :integer)

    has_many(:batch_details, TransactionBatchDetail, foreign_key: :batch_number)

    has_many(:l2_transactions, BatchTransaction, foreign_key: :batch_number)

    timestamps()
  end

  @spec changeset(Explorer.Chain.Twine.TransactionBatch.t()) :: Ecto.Changeset.t()
  @doc """
    Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = batches, attrs \\ %{}) do
    batches
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:number)
  end
end

defmodule Explorer.Chain.Twine.TransactionBatchDetail do
  @moduledoc "Models a batch of transactions for Twine."

  use Explorer.Schema

  alias Explorer.Chain.{
    Block,
    Hash,
    Wei
  }

  alias Explorer.Chain.Twine.{BatchTransaction, TransactionBatch}

  @optional_attrs ~w(commit_transaction_hash finalize_transaction_hash)a

  @required_attrs ~w(number timestamp chain_id l1_transaction_count l2_transaction_count l1_gas_price l2_fair_gas_price)a

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          l1_transaction_count: non_neg_integer(),
          l2_transaction_count: non_neg_integer(),
          l1_gas_price: Wei.t(),
          l2_fair_gas_price: Wei.t(),
          chain_id: Wei.t(),
          batch_number: non_neg_integer(),
          batch: %Ecto.Association.NotLoaded{} | TransactionBatch.t() | nil,
          commit_transaction_hash: Hash.t() | nil,
          finalize_transaction_hash: Hash.t() | nil
        }

  @primary_key {:id, :id, autogenerate: true}
  schema "twine_transaction_batch_detail" do
    field(:l1_transaction_count, :integer)
    field(:l2_transaction_count, :integer)
    field(:l1_gas_price, Wei)
    field(:l2_fair_gas_price, Wei)
    field(:chain_id, Wei)
    field(:commit_transaction_hash, Hash.Full)
    field(:finalize_transaction_hash, Hash.Full)
    field(:committed_at, :utc_datetime_usec)
    field(:finalized_at, :utc_datetime_usec)

    belongs_to(:batch, TransactionBatch, foreign_key: :batch_number, references: :number, type: :integer)

    has_many(:l2_transactions, BatchTransaction, foreign_key: :batch_number)

    timestamps()
  end

  @doc """
    Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = batches, attrs \\ %{}) do
    batches
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:number)
  end
end

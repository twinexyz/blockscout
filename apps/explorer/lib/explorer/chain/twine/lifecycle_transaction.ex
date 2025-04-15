defmodule Explorer.Chain.Twine.LifecycleTransaction do
  @moduledoc "Models an L1 lifecycle transaction for Twine."

  use Explorer.Schema

  alias Explorer.Chain.Hash
  alias Explorer.Chain.Twine.TransactionBatch

  alias Explorer.Chain.{
    Block,
    Hash,
    Wei
  }

  @required_attrs ~w(id hash timestamp)a

  @type t :: %__MODULE__{
          hash: binary(),
          timestamp: DateTime.t(),
          chain_id: Wei.t(),
        }

  @primary_key {:id, :integer, autogenerate: false}
  schema "twine_lifecycle_l1_transactions" do
    field(:hash, :binary)
    field(:timestamp, :utc_datetime_usec)
    field(:chain_id, Wei)

    has_many(:committed_batches, TransactionBatch, foreign_key: :commit_id)
    # has_many(:proven_batches, TransactionBatch, foreign_key: :prove_id)
    has_many(:executed_batches, TransactionBatch, foreign_key: :execute_id)

    timestamps()
  end

  @doc """
    Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = txn, attrs \\ %{}) do
    txn
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:id)
  end
end

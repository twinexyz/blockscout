defmodule Explorer.Chain.Twine.BatchTransaction do
  @moduledoc """
  Models a list of transactions related to a batch for Twine.

  Changes in the schema should be reflected in the bulk import module:
  - Explorer.Chain.Import.Runner.Twine.BatchTransactions

  Migrations:
  - Explorer.Repo.Twine.Migrations.CreateTwineTables
  """
  use Explorer.Schema

  alias Explorer.Chain.{Hash, Transaction}
  alias Explorer.Chain.Twine.TransactionBatch

  @required_attrs ~w(batch_number hash)a

  @typedoc """
    * `hash` - The hash of the rollup transaction.
    * `l2_transaction` - An instance of `Explorer.Chain.Transaction` referenced by `hash`.
    * `batch_number` - The number of the Twine batch.
    * `batch` - An instance of `Explorer.Chain.Twine.TransactionBatch` referenced by `batch_number`.
  """
  @primary_key false
  typed_schema "twine_batch_l2_transactions" do
    belongs_to(:batch, TransactionBatch, foreign_key: :batch_number, references: :number, type: :integer)

    belongs_to(:l2_transaction, Transaction,
      foreign_key: :hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @spec changeset(Explorer.Chain.Twine.BatchTransaction.t()) :: Ecto.Changeset.t()
  @doc """
    Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = transactions, attrs \\ %{}) do
    transactions
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:batch_number)
    |> unique_constraint(:hash)
  end
end

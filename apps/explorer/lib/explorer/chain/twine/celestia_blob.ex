defmodule Explorer.Chain.Twine.CelestiaBlob do
  @moduledoc "Models a Celestia blob for Twine chain."

  use Explorer.Schema

  alias Explorer.Chain.{Block, Hash}

  @required_attrs ~w(commitment_hash namespace height data)a

  @type t :: %__MODULE__{
          twine_block_hash: Hash.t(),
          commitment_hash: String.t(),
          namespace: String.t(),
          height: non_neg_integer(),
          data: binary(),
          block: %Ecto.Association.NotLoaded{} | Block.t() | nil
        }

  @primary_key false
  schema "celestia_blobs" do
    field(:commitment_hash, :string)
    field(:namespace, :string)
    field(:height, :integer)
    field(:data, :binary)

    belongs_to(:block, Block, foreign_key: :twine_block_hash, primary_key: true, references: :hash, type: Hash.Full)

    timestamps()
  end

  @doc """
    Validates that the `attrs` are valid.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Schema.t()
  def changeset(%__MODULE__{} = blob, attrs \\ %{}) do
    blob
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:commitment_hash)
  end
end

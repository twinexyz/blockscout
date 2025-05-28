defmodule Explorer.Repo.Migrations.MakeBlockNumbersUnique do
  use Ecto.Migration

  def change do
    # Drop the existing index that only makes consensus blocks unique
    drop_if_exists(index(:blocks, [:number], name: :one_consensus_block_at_height))

    # Create new index that makes all block numbers unique
    create(index(:blocks, [:number], unique: true, name: :unique_block_numbers))
  end
end

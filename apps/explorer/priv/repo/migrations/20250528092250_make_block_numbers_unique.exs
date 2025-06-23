defmodule Explorer.Repo.Migrations.MakeBlockNumbersUnique do
  use Ecto.Migration

  def change do
    # Keep the existing consensus index and add a new index for all blocks
    create(index(:blocks, [:number], unique: true, name: :unique_block_numbers))
  end
end

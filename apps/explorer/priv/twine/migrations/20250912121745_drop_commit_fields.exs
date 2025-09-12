defmodule Explorer.Repo.Twine.Migrations.DropCommitFields do
  use Ecto.Migration

  def change do
    alter table(:twine_transaction_batch_detail) do
      remove(:commit_transaction_hash, :string)
      remove(:committed_at, :utc_datetime_usec)
    end
  end
end

defmodule Explorer.Repo.Twine.Migrations.CreateTwineTables do
  use Ecto.Migration

  def change do
    create table(:twine_lifecycle_l1_transactions, primary_key: false) do
      add(:id, :integer, null: false, primary_key: true)
      add(:hash, :bytea, null: false)
      add(:chain_id, :numeric, precision: 100, null: false)
      add(:timestamp, :"timestamp without time zone", null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(unique_index(:twine_lifecycle_l1_transactions, :hash))


    create table(:twine_transaction_batch, primary_key: false) do
      add(:number, :integer, null: false, primary_key: true)
      add(:start_block, :integer, null: false)
      add(:end_block, :integer, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
      add(:root_hash, :bytea, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end


    create table(:twine_transaction_batch_detail, primary_key: false) do
      add(:id, :serial, null: false, primary_key: true)
      add(:batch_number, references(:twine_transaction_batch, column: :number, on_delete: :delete_all, on_update: :update_all, type: :integer), null: false)
      add(:l1_transaction_count, :integer, null: false)
      add(:l2_transaction_count, :integer, null: false)
      add(:l1_gas_price, :numeric, precision: 100, null: false)
      add(:l2_fair_gas_price, :numeric, precision: 100, null: false)
      add(:chain_id, :numeric, precision: 100, null: false)

      add(:commit_id, references(:twine_lifecycle_l1_transactions, on_delete: :restrict, on_update: :update_all, type: :integer), null: true)
      add(:execute_id, references(:twine_lifecycle_l1_transactions, on_delete: :restrict, on_update: :update_all, type: :integer), null: true)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:twine_transaction_batch_detail, :batch_number))

    create table(:twine_batch_l2_transactions, primary_key: false) do
      add(:batch_number, references(:twine_transaction_batch, column: :number, on_delete: :delete_all, on_update: :update_all, type: :integer), null: false)
      add(:hash, :bytea, null: false, primary_key: true)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:twine_batch_l2_transactions, :batch_number))

    create table(:twine_batch_l2_blocks, primary_key: false) do
      add(:batch_number, references(:twine_transaction_batch, column: :number, on_delete: :delete_all, on_update: :update_all, type: :integer), null: false)
      add(:hash, :bytea, null: false, primary_key: true)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:twine_batch_l2_blocks, :batch_number))

    create table(:celestia_blobs, primary_key: false) do
      add(:twine_block_hash, :bytea, null: false, primary_key: true)
      add(:commitment_hash, :string, null: false)
      add(:namespace, :string, null: false)
      add(:height, :bigint, null: false)
      add(:data, :bytea, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(index(:celestia_blobs, [:twine_block_hash]))
    create(index(:celestia_blobs, [:commitment_hash]))
  end
end

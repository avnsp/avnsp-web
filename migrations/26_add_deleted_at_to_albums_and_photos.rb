Sequel.migration do
  change do
    alter_table :albums do
      add_column :deleted_at, DateTime
    end
    alter_table :photos do
      add_column :deleted_at, DateTime
    end
  end
end

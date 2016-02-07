Sequel.migration do
  change do
    alter_table :members do
      add_column :admin, :bool
    end
  end
end

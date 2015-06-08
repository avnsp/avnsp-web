Sequel.migration do
  change do
    alter_table :parties do
      drop_column :price
      add_column :price, :float
    end
  end
end

Sequel.migration do
  change do
    alter_table :parties do
      drop_column :type
      add_column :type, :text
    end
  end
end

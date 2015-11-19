Sequel.migration do
  change do
    alter_table :albums do
      add_column :text, :text
      add_column :date, :date
      rename_column :create_by, :created_by
    end
  end
end

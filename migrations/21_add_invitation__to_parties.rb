Sequel.migration do
  change do
    alter_table :parties do
      add_column :invitation, :text
    end
  end
end

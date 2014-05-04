Sequel.migration do
  change do
    alter_table :parties do
      add_column :type, :party_type
    end
  end
end

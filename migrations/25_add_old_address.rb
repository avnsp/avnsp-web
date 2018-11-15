Sequel.migration do
  change do
    alter_table :members do
      add_column :old_address, :text
    end
  end
end

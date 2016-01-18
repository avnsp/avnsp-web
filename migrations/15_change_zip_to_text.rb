Sequel.migration do
  change do
    alter_table :members do
      set_column_type :zip, 'text'
    end
  end
end

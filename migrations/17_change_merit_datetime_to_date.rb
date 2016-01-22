Sequel.migration do
  change do
    alter_table :merits do
      set_column_type :start, 'date'
      set_column_type :end, 'date'
    end
  end
end


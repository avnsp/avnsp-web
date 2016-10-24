Sequel.migration do
  change do
    alter_table :members do
      add_column :password_hash, "text"
    end
  end
end

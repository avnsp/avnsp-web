Sequel.migration do
  up do
    alter_table :members do
      drop_column :password_hash
    end

    alter_table :parties do
      add_column :attendance_deadline, :date
    end

    run "UPDATE parties SET attendance_deadline = (date - interval '1 week')"
    alter_table :parties do
      set_column_not_null :attendance_deadline
    end
  end

  down do
    alter_table :members do
      add_column :password_hash, :text
    end

    alter_table :parties do
      drop_column :attendance_deadline
    end
  end
end

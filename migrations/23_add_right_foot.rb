Sequel.migration do
  change do
    create_table(:right_feet) do
      Text :name
      Bool :vegitarian, default: false, null: false
      Bool :non_alcoholic, default: false, null: false
      Text :allergies

      foreign_key :attendance_id, :attendances, on_delete: :cascade
    end
  end
end

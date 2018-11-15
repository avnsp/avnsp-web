Sequel.migration do
  change do
    alter_table(:parties) { add_primary_key [:id] }
    alter_table(:members) { add_primary_key [:id] }
    alter_table(:albums) { add_primary_key [:id] }
    alter_table(:transactions) { add_primary_key [:id] }
    alter_table(:merits) { add_primary_key [:id] }
    alter_table(:photo_comments) { add_primary_key [:id] }
    alter_table(:purchases) { add_primary_key [:id] }
    alter_table(:articles) { add_primary_key [:id] }
    alter_table(:right_feet) { add_primary_key [:name, :attendance_id] }
    alter_table(:photos) { add_primary_key [:id] }
    alter_table(:attendances) { add_primary_key [:id] }
    alter_table :attendances do
      add_foreign_key [:member_id], :members, not_valid: true
      add_foreign_key [:party_id], :parties, not_valid: true
    end
  end
end

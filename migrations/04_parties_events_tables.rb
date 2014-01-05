Sequel.migration do
  change do
    rename_table :events, :parties
    create_table :events do
      primary_key :id

      String :subject
      String :message

      String :type

      String :table
      Integer :id

      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :members, :member_id
    end
  end
end

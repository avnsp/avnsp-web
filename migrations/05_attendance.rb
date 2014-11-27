Sequel.migration do
  change do
    create_table(:attendances) do
      primary_key :id

      Bool :vegitarian, default: false, null: false
      Bool :non_alcoholic, default: false, null: false
      Text :allergies
      Text :message

      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :member_id, :members
      foreign_key :party_id, :parties
    end
  end
end

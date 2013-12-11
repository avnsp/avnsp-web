Sequel.migration do
  change do
    create_table :events do
      primary_key :id
      String :name, null: false
      Date :date, null: false
      String :location
      String :comment
      String :theme
      Int :price
    end
  end
end

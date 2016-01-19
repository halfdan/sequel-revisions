Sequel.migration do
  up do
    create_table :posts do
      primary_key :id, :integer, auto_increment: true
      varchar :title, null: false
      text :content, null: false

      DateTime :created_at
      DateTime :updated_at
    end

    create_table :post_history_events do
      primary_key :id, :integer, auto_increment: true
      integer :post_id, null: false
      text :meta, default: "{}"
      text :changes, default: "{}"

      DateTime :created_at
      DateTime :updated_at

      index [:post_id]
    end
  end

  down do
    drop_table :posts
    drop_table :post_history_events
  end
end


class User < Sequel::Model
  one_to_many :user_activities
  one_to_many :user_activity_counts

end

class Activity < Sequel::Model
  one_to_many :user_activities

end

class UserActivityCount < Sequel::Model
  set_primary_key [:user_id, :activity_id]

  many_to_one :user
  many_to_one :activity
end

class UserActivity < Sequel::Model
  many_to_one :user
  many_to_one :activity

end

# define database migrations. pending migrations are run at startup and
# are guaranteed to run exactly once per database.
migration "Create initial tables" do
  database.create_table :users do
    primary_key :id
    String      :username
    integer     :fitocracy_id, :null => false

    index :username, :unique => true
  end

  database.create_table :activities do
    primary_key :id
    integer     :fitocracy_id, :null => false
    String      :name, :null => false

    index :fitocracy_id, :unique => true
  end

  database.create_table :user_activity_counts do
    integer   :user_id,               :null => false
    integer   :activity_id,           :null => false
    integer   :fitocracy_activity_id, :null => false
    integer   :count,                 :null=>false

    index [:user_id, :activity_id], :unique => true
    index [:user_id, :fitocracy_activity_id], :unique => true
  end

  database.create_table :user_activities do
    primary_key :id
    integer     :fitocracy_id, :null => false
    integer     :fitocracy_group_id
    integer     :user_id, :null => false
    integer     :activity_id, :null => false

    DateTime    :date, :null => false
    String      :units
    integer     :reps
    integer     :weight

    index :fitocracy_id, :unique => true
  end
end
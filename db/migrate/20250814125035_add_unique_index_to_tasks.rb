class AddUniqueIndexToTasks < ActiveRecord::Migration[7.0]
  def change
    remove_index :tasks, :name, if_exists: true
    remove_index :tasks, [:name, :taskable_type, :taskable_id], if_exists: true
    add_index :tasks, [:name, :taskable_type, :taskable_id], unique: true
  end
end

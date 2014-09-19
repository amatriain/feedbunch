class RenameReadAllTourToFeedTour < ActiveRecord::Migration
  def change
    rename_column :users, :show_read_all_tour, :show_feed_tour
  end
end

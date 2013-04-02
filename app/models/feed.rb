class Feed < ActiveRecord::Base
  attr_accessible :url
  has_and_belongs_to_many :users
  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true
end

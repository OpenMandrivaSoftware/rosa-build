class Container < ActiveRecord::Base
  belongs_to :platform
  has_many :build_lists
end

# frozen_string_literal: true

##
# All application models inherit from this class.

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
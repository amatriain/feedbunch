##
# User model. Each instance of this class represents a single user that can log in to the application
# (or at least that has passed through the signup process but has not yet confirmed his email).
#
# This class has been created by installing the Devise[https://github.com/plataformatec/devise] gem and
# running the following commands:
#   rails generate devise:install
#   rails generate devise User
#
# The Devise[https://github.com/plataformatec/devise] gem manages authentication in this application. To
# learn more about Devise visit:
# {https://github.com/plataformatec/devise}[https://github.com/plataformatec/devise]
#
# Beyond the attributes added to this class by Devise[https://github.com/plataformatec/devise] for authentication,
# Openreader establishes a relationship between User and Feed models. Each user can be suscribed to many
# feeds and many users can be suscribed to a single feed (many-to-many relationship).
#
# A relationship is also established between User and Folder models. Each user can have many folders and eah folder
# belongs to a single user (one-to-many relationship).
#
# A relationship is also established between User and Entry models, through the Feed model. This enables us to retrieve
# all entries for all feeds a user is suscribed to.
#
# It is not mandatory that a user be suscribed to any feeds (in fact when a user first signs up he won't
# have any suscriptions).

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_and_belongs_to_many :feeds
  has_many :folders, dependent: :destroy
  has_many :entries, through: :feeds
end

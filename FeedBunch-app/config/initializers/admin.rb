# frozen_string_literal: true

##
# Class to restrict access to Sidekiq web ui to admin users.

class CanAccessSidekiq
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    Ability.new(current_user).can? :manage, Sidekiq
  end
end

##
# Class to restrict access to ActiveAdmin to admin users.

class CanAccessActiveAdmin
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    Ability.new(current_user).can? :manage, ActiveAdmin
  end
end

##
# Class to restrict access to Redmon to admin users.

class CanAccessRedmon
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    Ability.new(current_user).can? :manage, Redmon
  end
end

##
# Class to restrict access to PgHero to admin users.

class CanAccessPgHero
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    Ability.new(current_user).can? :manage, PgHero
  end
end
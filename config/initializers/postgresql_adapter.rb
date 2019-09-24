# frozen_string_literal: true

# Copied from https://github.com/discourse/discourse/blob/master/lib/freedom_patches/postgresql_adapter.rb
#
# Awaiting decision on https://github.com/rails/rails/issues/31190
#
# Since https://github.com/rails/rails/pull/22122 (rails 5.2) migrations cannot be run through pgbouncer in
# transaction pooling mode unless this patch is applied

require 'active_record/connection_adapters/postgresql_adapter'

#if ENV['DISABLE_MIGRATION_ADVISORY_LOCK']
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    def supports_advisory_locks?
      false
    end
  end
#end
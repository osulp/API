Honeycomb.configure do |config|
  config.write_key = ENV.fetch('HONEYCOMB_WRITEKEY', 'hereisareallylonglookingkey')
  config.dataset = ENV.fetch('HONEYCOMB_DATASET', 'api-test')
  config.notification_events = %w[
    sql.active_record
    render_template.action_view
    render_collection.action_view
    process_action.action_controller
    send_file.action_controller
    send_data.action_controller
    deliver.action_mailer
  ].freeze

  # Scrub unused, private data
  config.presend_hook do |fields|
    if fields.key?("redis.command")
      fields["redis.command"] = fields["redis.command"].slice(0, 300)
    elsif fields.key?("sql.active_record.binds")
      fields.delete("sql.active_record.binds")
      fields.delete("sql.active_record.type_casted_binds")
    end
  end

  config.client = Libhoney::NullClient.new if Rails.env.development? || ENV.key?("HONEYCOMB_DEBUG")
end

require 'sequel'

module Sequel::Plugins
  module History
    def self.apply(model, options = {})
      options = {
        model_name: "#{model.name}HistoryEvent",
        table_name: "#{model.table_name.to_s.singularize}_history_events",
        exclude: [:created_at, :updated_at]
      }.merge(options)

      base_name = options[:model_name]

      mods = options[:model_name].split("::")
      if mods.length > 1
        mobject = Object.const_get mods[0..mods.length-2].join("::")
        base_name = mods.last
      else
        mobject = Object
      end

      klass = Class.new(Sequel::Model(options[:table_name].to_sym))
      klass.class_eval %{
        plugin :timestamps
        many_to_one :#{model.table_name}, class: "#{model.name}"
      }
      # Actually define the class in the module
      mobject.const_set base_name, klass

      model.class_eval %{
        one_to_many :#{options[:table_name]}, class: "#{options[:model_name]}"
      }
    end

    def self.configure(model, options = {})
      options = {
        model_name: "#{model.name}HistoryEvents",
        table_name: "#{model.table_name}_history_events",
        exclude: [:created_at, :updated_at]
      }.merge(options)

      model.instance_eval do
        @history_opts = options
      end

      # ToDo: Define Model

    end

    module ClassMethods
    end

    module InstanceMethods

      def after_update
        track_changes
        super
      end

    private

      def track_changes
        return if changed_columns.empty?

        changes = changed_columns.map do |key|
          { key => column_change(key) }
        end


      end
    end
  end
end

require 'sequel'
require 'json'

module Sequel::Plugins
  module Revisions
    def self.apply(model, options = {})
      options = {
        model_name: "#{model.name}Revisions",
        table_name: "#{model.table_name.to_s.singularize}_revisions",
        exclude: [:created_at, :updated_at],
        meta: nil
      }.merge(options)

      base_name = options[:model_name]

      mods = options[:model_name].split("::")
      if mods.length > 1
        mobject = Object.const_get mods[0..mods.length-2].join("::")
        base_name = mods.last
      else
        mobject = Object
      end

      # Dynamically create Model class
      klass = Class.new(Sequel::Model(options[:table_name].to_sym))
      klass.class_eval do
        @@lmeta = options[:meta]
        plugin :timestamps
        plugin :serialization

        serialize_attributes :json, :meta
        serialize_attributes :json, :changes
        many_to_one model.table_name.to_sym, class: model.name

        def before_create
          # ToDo: This should not call to_json. Maybe a bug?
          self[:meta] = @@lmeta.call().to_json unless @@lmeta.nil?
          super
        end
      end

      # Actually define the class in the module
      mobject.const_set base_name, klass

      model.class_eval do
        plugin :dirty
        one_to_many :revisions, class: options[:model_name]

        def revert
          return if revisions.empty?

          last = revisions.last
          changes = last.changes
          changes.keys.each do |key|
            send("#{key}=", changes[key][0])
          end
        end

        def revert!
          revert
          save
        end
      end
    end

    def self.configure(model, options = {})
    end

    module ClassMethods
    end

    module InstanceMethods

      def before_update
        track_changes
        super
      end

    private

      def track_changes
        return if changed_columns.empty?

        # Map the changed fields into an object
        changes = changed_columns.inject({}) do |obj, key|
          obj[key] = column_change(key)
          obj
        end

        add_revision(changes: changes)
      end
    end
  end
end

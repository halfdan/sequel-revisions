require 'sequel'
require 'json'

module Sequel::Plugins
  module Revisions
    def self.apply(model, options = {})

    end

    def self.configure(model, options = {})
      options = set_options(model, options)

      base_name = options[:model_name]

      mods = options[:model_name].split("::")
      if mods.length > 1
        mobject = Object.const_get mods[0..mods.length-2].join("::")
        base_name = mods.last
      else
        mobject = Object
      end

      # Don't redefine
      unless mobject.const_defined?(base_name)
        klass = setup_revisions_model(model, options)
        # Actually define the class in the module
        mobject.const_set base_name, klass
      end

      # Configure associations / methods on models
      setup_model(model, options)
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

  private

    def self.set_options(model, options)
      model_name = options[:polymorphic] ? "Revision" : "#{model.name}Revision"
      table_name = options[:polymorphic] ? "revisions" : "#{model.table_name.to_s.singularize}_revisions"

      options = {
        model_name: model_name,
        table_name: table_name,
        exclude: [:created_at, :updated_at],
        meta: nil
      }.merge(options)
    end

    def self.setup_revisions_model(model, options)
      # Dynamically create Model class
      klass = Class.new(Sequel::Model(options[:table_name].to_sym))
      klass.class_eval do
        @@lmeta = options[:meta]
        plugin :timestamps
        plugin :serialization

        serialize_attributes :json, :meta
        serialize_attributes :json, :changes

        def before_create
          # ToDo: This should not call to_json. Maybe a bug?
          self[:meta] = @@lmeta.call().to_json unless @@lmeta.nil?
          super
        end
      end

      if options[:polymorphic]
        klass.class_eval do
          many_to_one :trackable, polymorphic: true
        end
      else
        klass.class_eval do
          many_to_one model.table_name.to_sym, class: model.name
        end
      end
      klass
    end

    def self.setup_model(model, options)
      model.class_eval do
        plugin :dirty

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

      if options[:polymorphic]
        model.class_eval do
          one_to_many :revisions, as: :trackable
        end
      else
        model.class_eval do
          one_to_many :revisions, class: options[:model_name]
        end
      end
    end
  end
end

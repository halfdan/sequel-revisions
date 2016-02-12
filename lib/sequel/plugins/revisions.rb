require 'sequel'
require 'json'

module Sequel
  module Plugins
    module Revisions
      def self.apply(model, options = {})
        options = set_options(model, options)
        model.class_eval do
          @revisions_polymorphic = options[:polymorphic]
          @revisions_embedded_in = options[:embedded_in]
          @revisions_on          = options[:on]
          @revisions_meta        = options[:meta]
          @revisions_exclude     = options[:exclude]
        end
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
        Plugins.inherited_instance_variables(self,
          :@revisions_polymorphic => nil,
          :@revisions_embedded_in => :dup,
          :@revisions_on => :dup,
          :@revisions_exclude => :dup,
          :@revisions_meta => nil)

        def revisions_polymorphic?
          @revisions_polymorphic
        end

        def revisions_embedded_in
          @revisions_embedded_in
        end

        def revisions_on? action
          # We track everything by default
          unless @revisions_on
            true
          else
            @revisions_on.include? action
          end
        end

        def revisions_meta
          @revisions_meta
        end

        def revisions_exclude
          @revisions_exclude
        end
      end

      module InstanceMethods

        def before_update
          super
          track_changes(:update) if model.revisions_on? :update
        end

        def before_destroy
          super
          track_changes(:destroy) if model.revisions_on? :destroy
        end

        def after_create
          super
          track_changes(:create) if model.revisions_on? :create
        end

      private

        def track_changes(action)
          case action
          when :update
            return if changed_columns.empty?
            # Map the changed fields into an object
            changes = changed_columns.inject({}) do |obj, key|
              obj[key] = column_change(key)
              obj
            end
          when :create
            changes = (columns - model.revisions_exclude).inject({}) do |obj, key|
              obj[key] = [nil, send(key)]
              obj
            end
          when :destroy
            changes = (columns - model.revisions_exclude).inject({}) do |obj, key|
              obj[key] = [send(key), nil]
              obj
            end
          end

          #
          meta = model.revisions_meta.call() unless model.revisions_meta.nil?

          if model.revisions_embedded_in.nil?
            add_revision(changes: changes, action: action, meta: meta)
          else
            trackable = self.send(model.revisions_embedded_in)
            add_revision(changes: changes, action: action, meta: meta, trackable: trackable)
          end
        end
      end

    private

      def self.set_options(model, options)
        model_name = options[:polymorphic] ? "Revision" : "#{model.name}Revision"
        table_name = options[:polymorphic] ? "revisions" : "#{model.table_name.to_s.singularize}_revisions"

        options = {
          model_name: model_name,
          table_name: table_name,
          exclude: [:id, :created_at, :updated_at],
          meta: nil
        }.merge(options)
      end

      def self.setup_revisions_model(model, options)
        # Dynamically create Model class
        klass = Class.new(Sequel::Model(options[:table_name].to_sym))
        klass.class_eval do
          plugin :timestamps
          plugin :serialization

          serialize_attributes :json, :meta
          serialize_attributes :json, :changes
        end

        if options[:polymorphic]
          klass.class_eval do
            many_to_one :trackable, polymorphic: true
            many_to_one :embeddable, polymorphic: true
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
            one_to_many :revisions, as: :trackable, class: "::#{options[:model_name]}"
          end
        elsif options[:embedded_in]
          model.class_eval do
            one_to_many :revisions, as: :embeddable, class: "::#{options[:model_name]}"
          end
        else
          model.class_eval do
            one_to_many :revisions, class: "::#{options[:model_name]}"
          end
        end
      end
    end
  end
end

module Workarea
  class Release
    module Activation
      extend ActiveSupport::Concern

      included do
        around_create :save_activate_with
        attr_accessor :activate_with
      end

      def save_activate_with
        self.active = false if activate_with?
        yield
        create_activation_changeset(activate_with) if activate_with?
      end

      def activate_with?
        activate_with.present? && BSON::ObjectId.legal?(activate_with)
      end

      def create_activation_changeset(release_id)
        set = changesets.find_or_initialize_by(release_id: release_id)
        set.document_path = document_path

        active_changeset = if Workarea.config.localized_active_fields
          { 'active' => { I18n.locale => true } }
        else
          { 'active' => true }
        end

        set.changeset = active_changeset
        set.save!
      end

      def was_active?
        (Workarea.config.localized_active_fields && active_was[I18n.locale]) ||
          (!Workarea.config.localized_active_fields && active_was)
      end
    end
  end
end

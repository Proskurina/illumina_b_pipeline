module Presenters
  class QCTubePresenter < TubePresenter

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending     => [ 'labware-summary-button', 'labware-state-button' ],
        :started     => [ 'labware-state-button', 'labware-summary-button' ],
        :passed      => [ 'labware-state-button', 'labware-summary-button' ],
        :qc_complete => [ 'labware-creation-button','labware-summary-button' ],
        :cancelled   => [ 'labware-summary-button' ],
        :failed      => [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      event :start do
        transition :pending => :started
      end

      event :take_default_path do
        transition :pending => :started
        transition :started => :passed
        transition :passed  => :qc_complete
      end

      event :pass do
        def has_qc_data?; true; end
        transition [ :pending, :started ] => :passed
      end

      event :qc_complete do
        def has_qc_data?; true; end
        transition :passed => :qc_complete
      end

      event :fail do
        transition [ :passed ] => :failed
      end

      event :cancel do
        transition [ :pending, :started ] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, :human_name => 'QC Complete' do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless default_child_purpose.nil?
          nil
        end

        # Returns the child plate purposes that can be created in the qc_complete state.
        def default_child_purpose
          purpose.children.first
        end
      end

    end
  end
end

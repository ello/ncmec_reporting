module NcmecReporting
  class Submission
    class State
      include AASM

      aasm do
        state :none, initial: true
        state :submitted
        state :finished
        state :retracted

        event :submit do
          transitions to: :submitted, from: :none
        end

        event :upload do
          transitions to: :submitted, from: :submitted
        end

        event :finish do
          transitions to: :finished, from: [:submitted]
        end

        event :retract do
          transitions to: :retracted, from: [:submitted]
        end
      end
    end
  end
end

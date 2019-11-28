RSpec.describe SteelWheel::Action do
  vars do
    action_class do
      Class.new(SteelWheel::Action) do
        def upcased_title
          'new action'.upcase
        end
      end
    end
    title { 'new action' }
    action { action_class.new }
  end

  it { expect(action).to respond_to(:upcased_title) }

  it 'has access to data passed in context object' do
    expect(action.upcased_title).to eq title.upcase
  end

  it 'raises error when no method defined on context' do
    expect { action.not_defined_method }.to raise_error(NoMethodError, /undefined method `not_defined_method'/)
  end
end

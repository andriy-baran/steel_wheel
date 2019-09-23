RSpec.describe SteelWheel::Action do
  vars do
    action_class do
      Class.new(SteelWheel::Action) do
        def upcased_title
          title.upcase
        end
      end
    end
    title { 'new action' }
    context_object { OpenStruct.new(title: title) }
    action { action_class.new(context_object) }
  end

  it { expect(action).to respond_to(:title) }
  it { expect(action).to respond_to(:upcased_title) }

  it 'has access to data passed in context object' do
    expect(action.title).to eq title
    expect(action.upcased_title).to eq title.upcase
  end

  it 'raises error when no method defined on context' do
    expect { action.not_defined_method }.to raise_error(NoMethodError, /undefined method `not_defined_method'/)
  end
end

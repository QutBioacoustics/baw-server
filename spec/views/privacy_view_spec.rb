require 'rails_helper'

describe 'public/disclaimers', type: :view do
  standard_text = 'No privacy statement available for this project.'

  it 'should render a stock welcome message for new pages' do
    render
    expect(rendered).to have_content(standard_text)
  end

  it 'should allow the standard welcome message to be replaced' do
    stub_template 'public/_privacy.md' => <<~MARKDOWN
      This is a testy **test** test
    MARKDOWN

    render
    expect(rendered).to_not have_content(standard_text)
    expect(rendered).to include('This is a testy <strong>test</strong> test')
  end

end
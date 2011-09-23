require File.join( File.dirname(__FILE__), "spec_helper" )

describe "credentials" do
  include_context "ey integration reset"

  before(:each) do
    Chronos::EyIntegration.destroy_creds
  end
  after(:each) do
    Chronos::EyIntegration.destroy_creds
  end

  it "records service credentials" do
    Chronos::EyIntegration.api_creds.should be_nil
    save_creds_result =
#{save_creds_call{
      Chronos::EyIntegration.save_creds('ff4d04dbea52c605', 'e301bcb647fc4e9def6dfb416722c583cf3058bc1b516ebb2ac99bccf7ff5c5ea22c112cd75afd28')
#}save_creds_call}
    DocHelper.save('save_creds_result', save_creds_result.inspect)
    Chronos::EyIntegration.api_creds.should_not be_nil
    Chronos::EyIntegration.api_creds.auth_id.should eq "ff4d04dbea52c605"
    Chronos::EyIntegration.api_creds.auth_key.should eq "e301bcb647fc4e9def6dfb416722c583cf3058bc1b516ebb2ac99bccf7ff5c5ea22c112cd75afd28"
  end

end
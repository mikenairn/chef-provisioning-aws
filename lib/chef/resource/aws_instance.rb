require 'chef/provisioning/aws_driver/aws_resource_with_entry'

class Chef::Resource::AwsInstance < Chef::Provisioning::AWSDriver::AWSResourceWithEntry
  # The require needs to be inside this class otherwise it gets loaded before the rest of the SDK
  # and starts causing issues - AWS expects to load all this stuff itself
  aws_sdk_type ::Aws::EC2::Instance,
    managed_entry_type: :machine,
    managed_entry_id_name: 'instance_id'

  # TODO need to remove this for now because the SDK V2 uses a different tagging mechanism
  undef_method(:aws_tags)

  attribute :name, kind_of: String, name_attribute: true

  attribute :instance_id, kind_of: String, aws_id_attribute: true, lazy_default: proc {
    name =~ /^i-[a-f0-9]{8}$/ ? name : nil
  }

  def aws_object
    driver, id = get_driver_and_id
    result = driver.ec2_resource.instance(id) if id
    result && result.exists? ? result : nil
  end
end

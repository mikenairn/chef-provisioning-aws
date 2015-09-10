require 'chef/provisioning/aws_driver/aws_provider'

class Chef::Provider::AwsInstance < Chef::Provisioning::AWSDriver::AWSProvider
  provides :aws_instance

  def create_aws_object(instance); end

  def update_aws_object(instance); end

  def destroy_aws_object(instance)
    message = "delete instance #{new_resource}"
    message += " in VPC #{instance.vpc.id}" unless instance.vpc.nil?
    message += " in #{region}"
    converge_by message do
      instance.delete
    end
    converge_by "waited until instance #{new_resource} is :terminated" do
      # When purging, we must wait until the instance is fully terminated - thats the only way
      # to delete the network interface that I can see
      wait_for_status(instance, :terminated, [AWS::EC2::Errors::InvalidInstanceID::NotFound])
    end
  end
end

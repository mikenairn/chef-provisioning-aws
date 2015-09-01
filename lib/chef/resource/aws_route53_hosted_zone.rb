require 'chef/provisioning/aws_driver/aws_resource'
require 'chef/resource/aws_subnet'
require 'chef/resource/aws_eip_address'

class Chef::Resource::AwsRoute53HostedZone < Chef::Provisioning::AWSDriver::AWSResourceWithEntry

  # :id is not actually :name, it's the ID provided by AWS
  # aws_sdk_type AWS::Route53::HostedZone, load_provider: false, id: :aws_route_53_zone_id
  aws_sdk_type AWS::Route53::HostedZone, load_provider: false #, id: :id

  # silence deprecations--since provisioning figures out the resource name itself, it seems like it could do
  # this, too...
  resource_name :aws_route53_hosted_zone

  # name of the domain.
  attribute :name, kind_of: String, name_attribute: true

  # The comment included in the CreateHostedZoneRequest element. String <= 256 characters.
  attribute :comment, kind_of: String

  attribute :aws_route_53_zone_id, kind_of: String, aws_id_attribute: true

  # If you want to associate a reusable delegation set with this hosted zone, the ID that Amazon Route 53
  # assigned to the reusable delegation set when you created it. For more information about reusable
  # delegation sets, see Actions on Reusable Delegation Sets.
  # This is unimplemented pending a strong use case.
  # attribute :delegation_set_id

  # A complex type that contains information about the Amazon VPC that you're associating with this hosted
  # zone.
  # You can specify only one Amazon VPC when you create a private hosted zone. To associate additional Amazon
  # VPC with the hosted zone, use POST AssociateVPCWithHostedZone after you create a hosted zone.
  # 1. name of a Chef VPC resource.
  # 2. a Chef VPC resource.
  # 3. an AWS::EC2::VPC.
  attribute :vpcs

  def aws_object
    driver, id = get_driver_and_id
    result = driver.route53.hosted_zones[id] if id
    result && result.exists? ? result : nil
  end
end

class Chef::Provider::AwsRoute53HostedZone < Chef::Provisioning::AWSDriver::AWSProvider
  provides :aws_route53_hosted_zone

  def create_aws_object
    converge_by "create new #{new_resource}" do
      zone = new_resource.driver.route53.hosted_zones.create(new_resource.name) #, comment: new_resource.comment)
      new_resource.aws_route_53_zone_id(zone.id)
      puts "\nHosted zone ID (#{new_resource.name}): #{zone.id}"
      zone
    end
  end

  def update_aws_object(hosted_zone)
    puts "\nUPDATE"
  end

  def destroy_aws_object(hosted_zone)
    puts "\nDESTROY"
    converge_by "delete Route53 zone #{new_resource}" do
      result = new_resource.driver.route53.hosted_zone[new_resource.aws_route_53_zone_id].delete
    end
  end
end

require 'chef/provisioning/aws_driver/aws_resource'
require 'chef/resource/aws_subnet'
require 'chef/resource/aws_eip_address'

require 'securerandom'

class Chef::Resource::AwsRoute53HostedZone < Chef::Provisioning::AWSDriver::AWSResourceWithEntry

  # :id is not actually :name, it's the ID provided by AWS
  aws_sdk_type ::Aws::Route53::Types::HostedZone, load_provider: false

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
    result = driver.route53_client.get_hosted_zone(id: id).hosted_zone if id rescue nil
    result || nil
  end
end

class Chef::Provider::AwsRoute53HostedZone < Chef::Provisioning::AWSDriver::AWSProvider
  provides :aws_route53_hosted_zone

  # resp = client.create_hosted_zone({
  #   name: "DNSName", # required
  #   vpc: {
  #     vpc_region: "us-east-1", # accepts us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1, cn-north-1
  #     vpc_id: "VPCId",
  #   },
  #   caller_reference: "Nonce", # required
  #   hosted_zone_config: {
  #     comment: "ResourceDescription",
  #     private_zone: true,
  #   },
  #   delegation_set_id: "ResourceId",
  # })
  def create_aws_object

    converge_by "create new Route 53 zone #{new_resource}" do
      values = {
        name: new_resource.name,
        hosted_zone_config: {
          comment: new_resource.comment,
        },
        caller_reference: "chef-provisioning-aws-#{SecureRandom.uuid.upcase}",  # required
      }

      zone = new_resource.driver.route53_client.create_hosted_zone(values).hosted_zone
      puts "\nHosted zone ID (#{new_resource.name}): #{zone.id}"
      new_resource.aws_route_53_zone_id(zone.id)
      zone
    end
  end

  def update_aws_object(hosted_zone)
    if new_resource.comment != hosted_zone.config.comment
      converge_by "update Route 53 zone #{new_resource}" do
        new_resource.driver.route53_client.update_hosted_zone_comment(id: hosted_zone.id, comment: new_resource.comment)
      end
    end
  end

  def destroy_aws_object(hosted_zone)
    converge_by "delete Route53 zone #{new_resource}" do
      result = new_resource.driver.route53_client.delete_hosted_zone(id: hosted_zone.id)
    end
  end
end

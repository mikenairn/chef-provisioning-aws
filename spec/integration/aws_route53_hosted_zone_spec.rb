require 'spec_helper'

describe Chef::Resource::AwsRoute53HostedZone do
  extend AWSSupport

  when_the_chef_12_server "exists", organization: 'foo', server_scope: :context do
    with_aws "when connected to AWS" do

      it "aws_route53_hosted_zone :create creates a Route 53 hosted zone" do
        skip "broken, :destroy doesn't work"
        zone_name = "aws-spec-#{Time.now.to_i}.com."
        expect_recipe {
          aws_route53_hosted_zone zone_name do
            action :create
            comment "comment thing"
          end
        }.to create_an_aws_route53_hosted_zone(zone_name, comment: "comment thing") #.and be_idempotent
      end
    end
  end
end

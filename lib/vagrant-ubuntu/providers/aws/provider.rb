require 'erb'
require 'ostruct'
require 'fog'
require 'iniparse'

module VagrantUbuntu
    module Providers
        module Aws
            def self.provision(vagrant, user_config, machine_name, machine_config)

                vagrant.vm.define machine_name do |config|

                    config.vm.box = machine_config.guest.box

                    fog_config = create_fog_config(machine_config.aws.profile)
                    image = get_image(fog_config, machine_config.aws.image_name)

                    config.trigger.before :up do |trigger|
                        trigger.info = image.inspect
                    end

                    # Keypair configuration
                    config.ssh.insert_key = false
                    config.ssh.private_key_path = File.expand_path(
                        user_config.ssh.private_key_path)

                    config.vm.provider :aws do |aws, override|
                        aws.ami = image.id
                        aws.aws_profile = machine_config.aws.profile
                        aws.instance_type = machine_config.aws.instance_type
                        aws.ssh_host_attribute = :private_ip_address
                        aws.subnet_id = machine_config.aws.subnet_id
                        aws.associate_public_ip = false
                        aws.security_groups = machine_config.aws.security_groups
                        aws.tags = machine_config.aws.tags
                        aws.user_data = render_user_data(user_config.ssh.username,
                            File.expand_path(user_config.ssh.public_key_path),
                            user_config.meta.host_templates_path)
                    end

                    PROVIDERS[:common].provision(config,
                        user_config,
                        machine_name,
                        machine_config)
                end
            end

            def self.read_aws_files(profile, aws_config_path, aws_creds_path)
                # determine section in config ini file
                if profile == "default"
                  ini_profile = profile
                else
                  ini_profile = "profile #{profile}"
                end

                # get info from config ini file for selected profile
                data = File.read(aws_config_path)
                doc_cfg = IniParse.parse(data)
                aws_region = doc_cfg[ini_profile]["region"]

                # determine section in credentials ini file
                ini_profile = profile
                # get info from credentials ini file for selected profile
                data = File.read(aws_creds_path)
                doc_cfg = IniParse.parse(data)
                aws_id = doc_cfg[ini_profile]["aws_access_key_id"]
                aws_secret = doc_cfg[ini_profile]["aws_secret_access_key"]
                aws_token = doc_cfg[ini_profile]["aws_session_token"]

                return aws_region, aws_id, aws_secret, aws_token
            end

            def self.create_fog_config(profile)
                aws_dir = ENV['HOME'].to_s + '/.aws/'
                aws_region, aws_id, aws_secret, aws_token = read_aws_files(
                    profile,
                    aws_dir + "config",
                    aws_dir + "credentials")
                return {
                  :provider => :aws,
                  :region => aws_region,
                  :aws_access_key_id => aws_id,
                  :aws_secret_access_key => aws_secret,
                  :aws_session_token => aws_token
                }
            end

            def self.get_image(fog_config, image_name)
                fog_aws = Fog::Compute.new(fog_config)

                filter = {
                  "name" => "ubuntu/images/hvm-ssd/#{image_name}*",
                  "image-type" => "machine",
                  "root-device-type" => "ebs",
                  "architecture" => "x86_64",
                  "ExecutableBy" => "all",
                  "virtualization-type" => "hvm",
                  "owner-id" => "099720109477"
                }
                images =  fog_aws.images.all(filter)
                image = images.sort_by! { |a| a.creation_date }.reverse![0]
                return image
            end

            def self.render_user_data(username, pub_key_path, templates_path)
                pub_key = File.read(pub_key_path)
                template = ERB.new File.read("#{templates_path}/user_data.erb")
                state = OpenStruct.new(
                    user_name: "#{username}",
                    ssh_pub_key: "#{pub_key}")
                user_data = template.result(state.instance_eval { binding })
                return user_data
            end
        end
    end
end
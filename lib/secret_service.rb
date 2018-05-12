require 'vault'
require 'google/apis/cloudkms_v1'

# This class is used to interface with secrets, and can handle either Vault
# or Google Cloud
class SecretService

  def SecretService.write_fitocracy_cred(fitocracy_user, fitocracy_password)
    if vault?
      Vault.logical.write("secret/user_#{fitocracy_user}", pw: fitocracy_password)
    elsif gce?
      kms_client = Google::Apis::CloudkmsV1::CloudKMSService.new
      kms_client.authorization = Google::Auth.get_application_default(
          "https://www.googleapis.com/auth/cloud-platform"
      )
      # The resource name of the location associated with the key rings
      parent = "projects/#{ENV['GCLOUD_PROJECT_ID']}/locations/#{ENV['GCLOUD_KEY_LOCATION']}"

      # Request list of key rings
      response = kms_client.list_project_location_key_rings parent

      # List all key rings for your project
      puts "Key Rings: "
      if response.key_rings
        response.key_rings.each do |key_ring|
          puts key_ring.name
        end
      else
        puts "No key rings found"
      end
    else
      raise "No secrets store configured. Vault or GCE need environment variables to be set."
    end
  end

  def SecretService.read_fitocracy_cred(fitocracy_user)

  end

  private

  def SecretService.vault?
    return ENV['VAULT_ADDR'] && ENV['VAULT_TOKEN']
  end

  def SecretService.gce?
    return ENV['GCLOUD_PROJECT_ID'] && ENV['GCLOUD_KEY_LOCATION']
  end

end
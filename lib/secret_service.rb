require 'vault'
require 'google/apis/cloudkms_v1'
require 'google/cloud/storage'

# This class is used to interface with secrets, and can handle either Vault
# or Google Cloud
class SecretService

  def SecretService.write_fitocracy_cred(fitocracy_user, fitocracy_password)
    if vault?
      Vault.logical.write(SecretService.pw_path(fitocracy_user), pw: fitocracy_password)
    elsif gce?
      storage = SecretService.get_gce_storage
      puts "Accessing bucket #{ENV['GCLOUD_STORAGE_BUCKET']}"
      bucket  = storage.bucket ENV['GCLOUD_STORAGE_BUCKET']
      enc = SecretService.gce_encrypt(fitocracy_password)
      bucket.create_file StringIO.new(enc), SecretService.pw_path(fitocracy_user)
    else
      raise "No secrets store configured. Vault or GCE need environment variables to be set."
    end
  end

  def SecretService.read_fitocracy_cred(fitocracy_user)
    if vault?
      Vault.logical.read(SecretService.pw_path(fitocracy_user))
    elsif gce?
      storage = SecretService.get_gce_storage
      bucket  = storage.bucket ENV['GCLOUD_STORAGE_BUCKET']
      file = bucket.file SecretService.pw_path(fitocracy_user)
      downloaded = file.download
      downloaded.rewind
      enc = downloaded.read
      return SecretService.gce_decrypt(enc)
    else
      raise "No secrets store configured. Vault or GCE need environment variables to be set."
    end
  end

  private

  def SecretService.vault?
    return ENV['VAULT_ADDR'] && ENV['VAULT_TOKEN']
  end

  def SecretService.gce?
    return ENV['GCLOUD_PROJECT_ID'] && ENV['GCLOUD_KEY_LOCATION']
  end

  def SecretService.pw_path(fitocracy_user)
    "fitpw/user_#{fitocracy_user}"
  end

  def SecretService.get_kms_client
    kms_client = Google::Apis::CloudkmsV1::CloudKMSService.new
    kms_client.authorization = Google::Auth.get_application_default(
        "https://www.googleapis.com/auth/cloud-platform"
    )
    return kms_client
  end

  def SecretService.get_gce_storage
    Google::Cloud::Storage.new project: ENV['GCLOUD_PROJECT_ID']
  end

  def SecretService.get_gce_resource
    "projects/#{ENV['GCLOUD_PROJECT_ID']}/locations/#{ENV['GCLOUD_KEY_LOCATION']}"
  end

  def SecretService.get_gce_keyring_resource
    "#{SecretService.get_gce_resource}/keyRings/#{ENV['GCLOUD_KEYRING_NAME']}"
  end

  def SecretService.get_gce_key_resource
    "#{get_gce_keyring_resource}/cryptoKeys/#{ENV['GCLOUD_KEY_NAME']}"
  end

  # Get the encryption/decryption key used for Google Compute Engine
  # Note these functions will create the keys if required
  def SecretService.get_gce_key
    kms_client = SecretService.get_kms_client
    key_ring = nil
    begin
      puts "Fetching key ring #{SecretService.get_gce_keyring_resource}"
      key_ring = kms_client.get_project_location_key_ring  SecretService.get_gce_keyring_resource
    rescue Google::Apis::ClientError
      puts "Keyring not found. Creating: #{$!}"
      key_ring = kms_client.create_project_location_key_ring(
          SecretService.get_gce_resource,
          Google::Apis::CloudkmsV1::KeyRing.new,
          key_ring_id: ENV['GCLOUD_KEYRING_NAME']
      )
    end

    key = nil
    begin
      puts "Fetching key ring #{SecretService.get_gce_key_resource}"
      key = kms_client.get_project_location_key_ring_crypto_key SecretService.get_gce_key_resource
    rescue Google::Apis::ClientError
      puts "Key not found. Creating: #{$!}"
      key = kms_client.create_project_location_key_ring_crypto_key(
          SecretService.get_gce_keyring_resource,
          Google::Apis::CloudkmsV1::CryptoKey.new(purpose: "ENCRYPT_DECRYPT"),
          crypto_key_id: ENV['GCLOUD_KEY_NAME']
      )
    end
    return key
  end

  def SecretService.gce_encrypt(secret)
    kms_client = SecretService.get_kms_client
    request = Google::Apis::CloudkmsV1::EncryptRequest.new plaintext: secret
    response = kms_client.encrypt_crypto_key SecretService.get_gce_key_resource, request
    return response.ciphertext
  end

  def SecretService.gce_decrypt(ciphertext)
    kms_client = SecretService.get_kms_client
    request = Google::Apis::CloudkmsV1::DecryptRequest.new ciphertext: ciphertext
    response = kms_client.decrypt_crypto_key SecretService.get_gce_key_resource, request
    return response.plaintext
  end

end
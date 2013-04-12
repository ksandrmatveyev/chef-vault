class ChefVault
  class Certificate
    attr_accessor :name

    def initialize(data_bag, name, chef_config_file)
      @name = name
      @data_bag = data_bag

      if chef_config_file
        chef = ChefVault::ChefOffline.new(chef_config_file)
        chef.connect
      end
    end

    def decrypt_contents
      # use the private client_key file to create a decryptor
      private_key = open(Chef::Config[:client_key]).read
      private_key = OpenSSL::PKey::RSA.new(private_key)
      
      begin
        keys = Chef::DataBagItem.load(@data_bag, "#{name}_keys")
      rescue
        throw "Could not find data bag item #{name}_keys in data bag #{@data_bag}"
      end

      unless keys[Chef::Config[:node_name]]
        throw "#{name} is not encrypted for you!  Rebuild the certificate data bag"
      end

      node_key = Base64.decode64(keys[Chef::Config[:node_name]])
      shared_secret = private_key.private_decrypt(node_key)
      certificate = Chef::EncryptedDataBagItem.load(@data_bag, @name, shared_secret)

      certificate["contents"]
    end
  end
end
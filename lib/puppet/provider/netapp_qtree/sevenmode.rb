require_relative '../netapp_sevenmode'

Puppet::Type.type(:netapp_qtree).provide(:sevenmode, :parent => Puppet::Provider::NetappSevenmode) do
  @doc = "Manage Netapp Qtree creation, modification and deletion."

  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :qlist => 'qtree-list'
  netapp_commands :qadd  => 'qtree-create'
  netapp_commands :qdel  => 'qtree-delete'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: got to self.instances.")
    qtree_instances = []

    # Query Netapp for qtree-list against volume.
    result = qlist()

    # Get a list of qtrees
    qtree_list = result.child_get("qtrees")
    Puppet.debug("Qtree_list looks like:")
    Puppet.debug("#{qtree_list.sprintf()}")

    # Create array of children
    qtrees = qtree_list.children_get

    # Itterate through each 'qtree-info' block.
    qtrees.each do |qtree_info|

      # Pull out the qtree name.
      name = qtree_info.child_get_string("qtree")
      # Skip record is 'name' is empty, as it's not actually a qtree.
      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode.prefetch: Checking if this is an actual qtree, not a volume. ")
      next if name.empty?
      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode.prefetch: Processing rule for qtree '#{name}'.")

      # Construct an export hash for rule
      qtree_hash = { :name => name,
                     :ensure => :present }

      # Add the volume details
      qtree_hash[:volume] = qtree_info.child_get_string("volume") unless qtree_info.child_get_string("volume").empty?
      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode.prefetch: Volume for '#{name}' is '#{qtree_info.child_get_string("volume")}'.")

      # Create the instance and add to exports array.
      Puppet.debug("Creating instance for '#{name}'. \n")
      qtree_instances << new(qtree_hash)
    end

    Puppet.debug("Processed all qtree instances. ")

    # Return the final exports array.
    Puppet.debug("Returning qtrees array. ")
    qtree_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: Got to flush for resource #{@resource[:qtname]}.")

    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    if @property_hash[:ensure] == :absent

      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: Ensure is absent.")
      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: destroying Netapp Qtree #{@resource[:qtname]} against volume #{@resource[:volume]}")

      # Query Netapp to remove qtree against volume.
      result = qdel('qtree', "/vol/#{@resource[:volume]}/#{@resource[:qtname]}")

      Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: qtree #{@resource[:qtname]} destroyed successfully. \n")

    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: creating Netapp Qtree #{@resource[:qtname]} on volume #{@resource[:volume]}.")

    # Query Netapp to create qtree against volume. .
    result = qadd('qtree', @resource[:qtname], 'volume', @resource[:volume])

    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: Qtree #{@resource[:qtname]} created successfully on volume #{@resource[:volume]}. \n")

  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: destroying Netapp Qtree #{@resource[:qtname]} against volume #{@resource[:volume]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_qtree.sevenmode: checking existance of Netapp qtree #{@resource[:qtname]} against volume #{@resource[:volume]}")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end

end

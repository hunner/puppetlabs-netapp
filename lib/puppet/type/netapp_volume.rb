Puppet::Type.newtype(:netapp_volume) do
  @doc = "Manage Netapp Volume creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The volume name. Valid characters are a-z, 1-9 & underscore."
    isnamevar
    validate do |value|
      unless value =~ /^\w+$/
        raise ArgumentError, "%s is not a valid volume name." % value
      end
    end
  end

  newproperty(:state) do
    desc "The volume state. Valid options are: online, offline, restricted."
    newvalues(:online, :offline, :restricted)
  end

  newproperty(:initsize) do
    desc "The initial volume size. Valid format is [0-9]+[kmgt]."
    validate do |value|
      unless value =~ /^\d+[kmgt]$/
         raise ArgumentError, "%s is not a valid initial volume size." % value
      end
    end
  end

  newparam(:aggregate) do
    desc "The aggregate this volume should be created in."
    isrequired
    validate do |value|
      unless value =~ /^\w+$/
        raise ArgumentError, "%s is not a valid aggregate name." % value
      end
    end
  end

  newparam(:languagecode) do
    desc "The language code this volume should use."
    newvalues(:C, :ar, :cs, :da, :de, :en, :en_US, :es, :fi, :fr, :he, :hr, :hu, :it, :ja, :ja_v1, :ko, :no, :nl, :pl, :pt, :ro, :ru, :sk, :sl, :sv, :tr, :zh, :zh_TW)
  end

  newparam(:spaceres) do
    desc "The space reservation mode."
    newvalues(:none, :file, :volume)
  end

  newproperty(:snapreserve) do
    desc "The percentage of space to reserve for snapshots."

    validate do |value|
      raise ArgumentError, "%s is not a valid snapreserve." % value unless value =~ /^\d+$/
      raise ArgumentError, "Puppet::Type::Netapp_volume: Reserved percentage must be between 0 and 100." unless value.to_i.between?(0,100)
    end

    munge do |value|
      case value
      when String
        if value =~ /^[-0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end

  newproperty(:junctionpath) do
    desc "The fully-qualified pathname in the owning Vserver's namespace at which a volume is mounted."
    newvalues(/^\//,false)
    munge do |value|
      case value
      when false, :false, "false"
        false
      else
        value
      end
    end
  end

  newproperty(:autosize, :boolean => true) do
    desc "Should volume autosize be grow, grow_shrink, or off?"
    newvalues(:off, :grow, :grow_shrink)
  end

  newproperty(:exportpolicy) do
    desc "The export policy with which the volume is associated."
  end

  newproperty(:options, :array_matching => :all) do
    desc "The volume options hash."
    validate do |value|
      raise ArgumentError, "Puppet::Type::Netapp_volume: options property must be a hash." unless value.is_a? Hash
    end

    def insync?(is)
      # @should is an Array. see lib/puppet/type.rb insync?
      should = @should.first

      # Comparison of hashes
      return false unless is.class == Hash and should.class == Hash
      should.each do |k,v|
        return false unless is[k] == should[k]
      end
      true
    end

    def should_to_s(newvalue)
      # Newvalue is an array, but we're only interested in first record.
      newvalue = newvalue.first
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:snapschedule, :array_matching=> :all) do
    desc "The volume snapshot schedule, in a hash format. Valid keys are: 'minutes', 'hours', 'days', 'weeks', 'which-hours', 'which-minutes'. "
    validate do |value|
      raise ArgumentError, "Puppet::Type::Netapp_volume: snapschedule property must be a hash." unless value.is_a? Hash
    end

    def insync?(is)
      # @should is an Array. see lib/puppet/type.rb insync?
      should = @should.first

      # Comparison of hashes
      return false unless is.class == Hash and should.class == Hash
      should.each do |k,v|
        # Skip record if is is " " and should is "0"
        next if is[k] == " " and should[k] == "0"
        return false unless is[k] == should[k].to_s
      end
      true
    end

    def should_to_s(newvalue)
      # Newvalue is an array, but we're only interested in first record.
      newvalue = newvalue.first
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  autorequire(:netapp_export_policy) do
    self[:exportpolicy]
  end

  ## Validate required params
  validate do
    raise ArgumentError, 'aggregate is required' if self[:aggregate].nil? and self.provider.aggregate.nil?
  end
end

class Comment
    ATTRIBUTES = {
		:id => "INTEGER PRIMARY KEY",
		:content => "TEXT"
	}

	# def self.attributes
	# 	ATTRIBUTES
	# end

	# ATTRIBUTES.keys.each do |attribute_name|
	# 	attr_accessor attribute_name
	# end

	include Persistable::InstanceMethods
	extend Persistable::ClassMethods

end
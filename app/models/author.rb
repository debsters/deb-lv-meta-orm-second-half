class Author

	ATTRIBUTES = {
		:id => "INTEGER PRIMARY KEY",
		:name => "TEXT",
		:state => "TEXT",
		:city => "TEXT",
		:age => "INTEGER"
	}
	# def self.attributes
	# 	ATTRIBUTES
	# end

	# ATTRIBUTES.keys.each do |attribute_name|
	# 	attr_accessor attribute_name
	# end

	include Persistable::InstanceMethods # Can I hook into this moment in time?
	extend Persistable::ClassMethods

end
# class Post < ActiveRecord::Base
# 	ATTRIBUTES = {
# 		:id => "INTEGER PRIMARY KEY",
# 		:title => "TEXT",
# 		:content => "TEXT",
# 		:author_name => "TEXT"
# 	}

# 	include Persistable::InstanceMethods
# 	extend Persistable::ClassMethods
# end

class Post 
	ATTRIBUTES = {
		:id => "INTEGER PRIMARY KEY",
		:title => "TEXT",
		:content => "TEXT",
		:author_name => "TEXT"
	}
	# @@table_name = "blog_posts"

# DO NOT EDIT ANYTHING BELOW THIS
	ATTRIBUTES.keys.each do |attribute_name|
		attr_accessor attribute_name
	end

	def destroy
		sql = <<-SQL
			DELETE FROM #{self.class.table_name} WHERE id = ?
		SQL

		DB[:conn].execute(sql, self.id)
	end

	def self.table_name
		"#{self.to_s.downcase}s"
		# @@table_name || "#{self.to_s.downcase}s"
	end

	def self.find(id)
		sql = <<-SQL
			SELECT * FROM #{self.table_name} WHERE id = ?
		SQL

		rows = DB[:conn].execute(sql, id)
		if rows.first
			self.reify_from_row(rows.first)  
		else
			nil
		end
		# we add "if rows.first" in case we have nothing in our DB, b/c if not this code breaks our program
		# "if rows.first" we are basically saying that if no row, then don't try to reify
	end

	def self.reify_from_row(row)
		self.new.tap do |p|
			ATTRIBUTES.keys.each.with_index do |attribute_name, i|
				p.send("#{attribute_name}=", row[i])
			end
		end
	end

	def self.create_sql
		ATTRIBUTES.collect{|attribute_name, schema| "#{attribute_name} #{schema}"}.join(",")
	end

	def self.create_table
		sql = <<-SQL
			CREATE TABLE IF NOT EXISTS #{self.table_name} (
				#{self.create_sql}
			)
		SQL
		DB[:conn].execute(sql)
	end

	def ==(other_post)
		self.id == other_post.id
	end

	def save
		# if the post has been saved before, then call update
		persisted? ? update : insert
		#otherwise call insert
	end

	def persisted? # if it has an ID, then I know its true #checks if already in database
		!!self.id
	end

	def self.attribute_names_for_insert
		"title, content" # basically every key from the ATTRIBUTES hash except id joined by a comma.
		ATTRIBUTES.keys[1..-1].join(",")
	end

	def self.question_marks_for_insert
		(ATTRIBUTES.keys.size-1).times.collect{"?"}.join(",")
		# 4 #=> "?,?,?,?"
	end

	def attribute_values
		# Trying to get the following: ["Post Title", "Post Content", "Post Author"]
		#without saying Title, Content, Author
		#This method gives you the values saved into the database // p.attribute_values => ["TITLE", "CONTENT", nil]
		ATTRIBUTES.keys[1..-1].collect{|attribute_name| self.send(attribute_name)}

		# if you send the word "title" to a post, it is like calling self.title
		# self.send(attribute_name) // is basically saying self.content and self.author_name etc.
	end

	def self.sql_for_update
		# Post.sql_for_update => "title = ?,content = ?,author_name = ?"
		ATTRIBUTES.keys[1..-1].collect{|attribute_name| "#{attribute_name} = ?"}.join(",")
	end

	private
		def insert
			sql = <<-SQL
				INSERT INTO #{self.class.table_name} (#{self.class.attribute_names_for_insert}) VALUES (#{self.class.question_marks_for_insert})
			SQL

			#	INSERT INTO posts (title, content) VALUES (?, ?)

			DB[:conn].execute(sql, *attribute_values)
			self.id = DB[:conn].execute("SELECT last_insert_rowid();").flatten.first
			#After we insert a post, we need to get the primary key out of the DB
			#and set the id of this instance to that value
		end

		def update
			sql = <<-SQL
				UPDATE posts SET #{self.class.sql_for_update} WHERE id = ?
			SQL

			DB[:conn].execute(sql, *attribute_values, self.id)
		end

    
end
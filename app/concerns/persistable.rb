module Persistable
		module ClassMethods
			def self.extended(base) # HOOK / LifeCycle / Callback
				puts "#{base} has been extended by #{self}"
				base.attributes.keys.each do |attribute_name|
					attr_accessor attribute_name
				end
			end

			# Post::ATTRIBUTES => {:id=>"INTEGER PRIMARY KEY", :title=>"TEXT", :content=>"TEXT", :author_name=>"TEXT"}
			def attributes
				self::ATTRIBUTES # #self refers to the class # :: is a scope accessor 
				# Its like saying POST::ATTRIBUTES and being able to access/reach into the hash of the object
			end

			def table_name
				"#{self.to_s.downcase}s"
			end

			#p = Post.create(:title => "OMG PROGRAMMING") => #<Post:0x0000000004a32808 @id=3, @title="OMG PROGRAMMING">
			#c = Comment.create(:content => "WHAT REALLY?") => #<Comment:0x0000000003ac7378 @content="WHAT REALLY?", @id=2> 
			def create(attributes_hash) #ActiveRecord does this for you
				self.new.tap do |p|
					attributes_hash.each do |attribute_name, attribute_value|
						p.send("#{attribute_name}=", attribute_value)
					end
					p.save
				end
			end
			
			def find(id)
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
			
			def reify_from_row(row)
				self.new.tap do |p|
					self.attributes.keys.each.with_index do |attribute_name, i|
						p.send("#{attribute_name}=", row[i])
					end
				end
			end
			
			def create_sql
				self.attributes.collect{|attribute_name, schema| "#{attribute_name} #{schema}"}.join(",")
			end
			
			def create_table
				sql = <<-SQL
					CREATE TABLE IF NOT EXISTS #{self.table_name} (
						#{self.create_sql}
					)
				SQL
				DB[:conn].execute(sql)
			end

			def attribute_names_for_insert
				"title, content" # basically every key from the ATTRIBUTES hash except id joined by a comma.
				self.attributes.keys[1..-1].join(",")
			end
			
			def question_marks_for_insert
				(self.attributes.keys.size-1).times.collect{"?"}.join(",")
				# 4 #=> "?,?,?,?"
			end

			def sql_for_update
				# Post.sql_for_update => "title = ?,content = ?,author_name = ?"
				self.attributes.keys[1..-1].collect{|attribute_name| "#{attribute_name} = ?"}.join(",")
			end

    end

		module InstanceMethods
			def self.included(base) # HOOK / LifeCycle / Callback
				puts "#{base} has mixed in #{self}"
			end

			def destroy
				sql = <<-SQL
					DELETE FROM #{self.class.table_name} WHERE id = ?
				SQL
			
				DB[:conn].execute(sql, self.id)
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

			def attribute_values
				# Trying to get the following: ["Post Title", "Post Content", "Post Author"]
				#without saying Title, Content, Author
				#This method gives you the values saved into the database // p.attribute_values => ["TITLE", "CONTENT", nil]
				self.class.attributes.keys[1..-1].collect{|attribute_name| self.send(attribute_name)}
			
				# if you send the word "title" to a post, it is like calling self.title
				# self.send(attribute_name) // is basically saying self.content and self.author_name etc.
			end

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

end


	
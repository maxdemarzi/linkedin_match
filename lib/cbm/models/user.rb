module CBM
  class User < Neography::Node

    def self.find_by_uid(uid)
      user = $neo_server.get_node_index("user_index", "uid", uid)

      if user
        self.new(user.first)
      else
        nil
      end
    end

    def self.create_with_omniauth(auth)
      node = $neo_server.create_unique_node("user_index", "uid", auth.uid)
      $neo_server.set_node_properties(node,
                                      {"name"       => auth.info.name,
                                       "location"  => auth.info.location,
                                       "image_url" => auth.info.image,
                                       "uid"       => auth.uid,
                                       "token"     => auth.credentials.token,
                                       "secret"    => auth.credentials.secret})

      Sidekiq::Client.enqueue(CBM::Job::ImportLinkedinProfile, auth.uid)
      User.load(node)
    end

    def self.create_from_linkedin(friend)
      id        = friend["id"]
      name      = (friend["first_name"] || "") + " " + (friend["last_name"] || "")
      location  = friend["location"] ? friend["location"]["name"] : ""
      image_url = (friend["picture_url"] || "")

      node = $neo_server.create_unique_node("user_index", "uid", id,
                                            {"name"      => name,
                                             "location"  => location,
                                             "image_url" => image_url,
                                             "uid"       => id
                                            })
      User.load(node)
    end

    def client
      @client ||= authorize_client
    end

    def authorize_client
      client = LinkedIn::Client.new
      client.authorize_from_access(self.token, self.secret)
      client
    end

    def values
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has]-> values
                RETURN ID(values), values.name"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def values_count
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has]-> values
                RETURN COUNT(values)"
      results = $neo_server.execute_query(cypher)
      results["data"][0][0]
    end

    def skills
      #TODO - Add Where Clause limiting has relationship to skills
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has]-> values
                RETURN ID(values), values.name"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def skills_count
      #TODO - Add Where Clause limiting has relationship to skills
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has]-> values
                RETURN COUNT(values)"
      results = $neo_server.execute_query(cypher)
      results["data"][0][0]
    end

    def connections
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:is_connected]-> connections
                RETURN connections.uid, connections.name, connections.image_url"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def connections_count
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:is_connected]-> connections
                RETURN COUNT(connections)"
      results = $neo_server.execute_query(cypher)
      results["data"][0][0]
    end

    def locations
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has_location]-> location
                RETURN ID(location), location.name"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

  end
end
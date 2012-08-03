module CBM
  class User < Neography::Node
    @neo_server = Neography::Rest.new

    def self.find_by_uid(uid)
      user = @neo_server.get_node_index("user_index", "uid", uid)

      if user && user.first["data"]["token"]
        self.new(user.first)
      else
        nil
      end
    end

    def self.create_with_omniauth(auth)
      node = @neo_server.create_unique_node("user_index", "uid", auth.uid)
      @neo_server.set_node_properties(node,
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

      node = @neo_server.create_unique_node("user_index", "uid", id,
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
  end
end
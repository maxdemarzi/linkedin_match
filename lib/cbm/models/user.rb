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

    def set_location(location)
      location.gsub!('Greater','')
      location.gsub!('Area','')
      location.strip!

      geo = Geocoder.search(location).first
      if geo
        city_node = CBM::Location.cities(geo.city).first
        if city_node
          $neo_server.create_unique_relationship("has_location_index", "user_location", "#{self.neo_id}-#{city_node[0]}", "has_location", self.neo_id, city_node[0])
        end
      end

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

      if results["data"][0]
        results["data"][0][0]
      else
        0
      end
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

      if results["data"][0]
        results["data"][0][0]
      else
        0
      end

    end

    def locations
      cypher = "START me = node(#{self.neo_id})
                MATCH me -[:has_location]-> location
                RETURN ID(location), location.name"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def matching
      gremlin = "matches = [] as Set;
                 values  = [] as Set;
                 params  = [] as Set;
                 trace   = [:].withDefault{ key -> [] as Set };
                 output  = [:].withDefault{ key -> [] as Set };

                 g.v(212281).out('has').
                   gather{ for(item in it){
                             values.add(item.getId());
                             if(item.in('belongs_to').hasNext()) {
                               params.add(item.in('belongs_to').next().getId() );
                             };
                           };
                  return it }.iterate();

                g.v(212281).out('has_location').as('next').
                  outE('in_path','in_path_excluded','in_criteria').
                  sideEffect{ path = it.getProperty('path'); }.
                  filter{ path == it.getProperty('path')}.
                  filter{ next_node = it.inV().next();
                        is_criteria = next_node.getProperty('type') == 'criteria';
                        if(is_criteria){
                        matches.add(next_node.getId());
                        };
                        !is_criteria;}.
                  filter{ if(it.label().next() == 'in_path')
                            {excluded = false;}
                          else
                            {excluded = true;};

                          params_contained = false;
                          next_node = it.inV().next();
                          contained = values.contains(next_node.getId());

                          if(!contained) {
                            if(next_node.in('belongs_to').hasNext()) {
                               param = item.in('belongs_to').next().getId(); }
                            else
                               { param = next_node.getId(); };

                            params_contained = params.contains(param);
                            if(!params_contained){
                              trace[path].add(param);
                            };
                          };

                          pass = excluded ? !contained : (contained || !params_contained);

                          if(!pass){ trace.remove(path); };

                          pass;
                  }.
                  inV().
                  loop('next'){it.getLoops() < 50}.
                  iterate();

                  matches;
                "

      $neo_server.execute_script(gremlin, {:user => self.neo_id})
    end

  end
end
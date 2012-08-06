module CBM
  class Util
    @neo_server = Neography::Rest.new

    # Import values, 50 at a time.
    def self.import(model, properties, values)
      puts "Importing #{model}"
      values.each_slice(50) do |slice|
        commands = []
        slice.each do |value|
          node_properties = Hash.new
          properties.each_with_index do |p,index|
            node_properties[p]= value[index]
          end
          commands << [:create_unique_node, "#{model}_index", "ref_id", node_properties[:id], node_properties]

        end
        @neo_server.batch *commands
      end


    end
  end
end

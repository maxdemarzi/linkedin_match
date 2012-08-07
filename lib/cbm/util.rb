module CBM
  class Util

    # Import values, 50 at a time.
    def self.import(model, properties, values)
      puts "Importing #{model}"
      @neo_server.create_node_index("#{model}_index", "fulltext", "lucene")

      values.each_slice(50) do |slice|
        commands = []
        slice.each do |value|
          node_properties = Hash.new
          properties.each_with_index do |p,index|
            node_properties[p]= value[index]
          end
          commands << [:create_unique_node, "#{model}_index", "ref_id", node_properties[:id], node_properties]

        end

        slice.each_with_index do |value, index|
          node_properties = Hash.new
          properties.each_with_index do |p,index|
            node_properties[p]= value[index]
          end

          commands << [:add_node_to_index, "#{model}_index", "name", node_properties[:name], "{#{index}}"]
        end

        @neo_server.batch *commands
      end


    end
  end
end

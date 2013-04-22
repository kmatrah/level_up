module LevelUp
  class GraphBuilder
    attr_accessor :target
    attr_reader :configuration

    @default_configuration = {
      bgcolor: '#fafbfb',

      node: {
        color: '#111111',
        style: 'filled',
        shape: 'box',
        fillcolor: '#666666',
        fontcolor: 'white',
        fontname: 'Verdana',

        start: {
          fillcolor: '#5db1a4',
          color: '#048282'
        },

        end: {
          fillcolor: '#b40d28',
          color: '#600615'
        }
      },

      edge: {
        color: '#000000',
        arrowhead: 'open'
      }
    }

    class << self
      attr_reader :default_configuration
    end

    def initialize(target, options = {})
      @target = target
      @configuration = self.class.default_configuration.deep_merge(options)
    end

    def graph
      graph = GraphViz.new(:G, type: :digraph)

      graph[:bgcolor] = @configuration[:bgcolor]

      @configuration[:node].each do |k, v|
        graph.node[k] = v unless v.is_a? Hash
      end

      @configuration[:edge].each do |k, v|
        graph.edge[k] = v unless v.is_a? Hash
      end

      tasks = {}
      @target.tasks.each do |task|
        tasks[task] = graph.add_nodes(task.to_s.humanize.downcase)
        if @configuration[:node].has_key? task
          @configuration[:node][task].each do |k, v|
            tasks[task][k] = v
          end
        end
      end

      @target.tasks.each do |task|
        @target.transitions(task).each do |transition|
          edge = graph.add_edges(tasks[task], tasks[transition])
          if @configuration[:edge].has_key? task
            @configuration[:edge][task].each do |k, v|
              edge[k] = v
            end
          end
        end
      end

      graph
    end
  end
end
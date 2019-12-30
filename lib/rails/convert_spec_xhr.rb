Synvert::Rewriter.new 'rails', 'convert_spec_xhr' do
  description <<-EOF
Replaces 
  xhr :get, :show, { id: user.id }, { notice: 'Welcome' }, { admin: user.admin? } 
with 
  get :show, xhr: true, params: { id: user.id }, flash: { notice: 'Welcome' }, session: { admin: user.admin? } in test files.

  EOF

  # xhr :get :show, { id: user.id }, { notice: 'Welcome' }, { admin: user.admin? }
  # =>
  # get :show, xhr: true, params: { id: user.id }, flash: { notice: 'Welcome' }, session: { admin: user.admin? }.
  within_files '{test,spec}/{functional,controllers}/**/*.rb' do
    #%w(get post put patch delete).each do |message|
    message = 'xhr'
    with_node type: 'send', message: 'xhr' do
      def make_up_hash_pair(key, argument_node)
        if argument_node.to_source != 'nil'
          if argument_node.type == :hash
            "#{key}: #{add_curly_brackets_if_necessary(argument_node.to_source)}"
          else
            "#{key}: #{argument_node.to_source}"
          end
        end
      end
      if node.arguments.size > 2 && node.arguments[2].type == :hash
        method_name = node.arguments[0].to_source[1..-1]
        action_name = node.arguments[1].to_source
        options = []
        if node.arguments[2].has_key?(:params)
          replace_with "#{method_name} #{action_name}, xhr: true, {{arguments[2..-1]}}"
        else
          options << make_up_hash_pair('params', node.arguments[2])
          options << make_up_hash_pair('flash', node.arguments[3]) if node.arguments.size > 3
          options << make_up_hash_pair('session', node.arguments[4]) if node.arguments.size > 4
          replace_with "#{method_name} #{action_name}, xhr: true, #{options.compact.join(', ')}"
        end
      end
    end
    #end
  end
end
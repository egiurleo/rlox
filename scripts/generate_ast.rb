# typed: strict
# frozen_string_literal: true

class GenerateAST
  class << self
    #: (String) -> void
    def main(output_dir)
      define_ast(output_dir, 'Expr', {
                   Assign: { name: 'Token', value: 'Expr' },
                   Binary: { left: 'Expr', operator: 'Token', right: 'Expr' },
                   Grouping: { expression: 'Expr' },
                   Literal: { value: 'untyped' },
                   Unary: { operator: 'Token', right: 'Expr' },
                   Variable: { name: 'Token' }
                 })

      define_ast(output_dir, 'Stmt', {
                   Block: { statements: 'Array[Stmt]' },
                   Expression: { expression: 'Expr' },
                   Print: { expression: 'Expr' },
                   Var: { name: 'Token', initializer: 'Expr?' }
                 })
    end

    private

    #: (String, String, Hash[String, Hash[String, String]]) -> void
    def define_ast(output_dir, base_name, types)
      path = "#{output_dir}/#{base_name.downcase}.rb"

      File.write(path, <<~RUBY)
        # typed: strict
        # frozen_string_literal: true

        require 'rlox/token'

        class Rlox
          # @abstract
          class #{base_name}
            # @abstract
            #: [R] (Visitor[R]) -> R
            def accept(visitor); end

            #{define_visitor(base_name, types)}
          end

          #{
           types.map do |class_name, fields|
             define_type(base_name, class_name, fields)
           end.join("\n")
         }
        end
      RUBY
    end

    #: (String, String, Hash[String, String]) -> String
    def define_type(base_name, class_name, fields)
      <<~RUBY
        class #{class_name} < #{base_name}
          #{
            fields.map do |field_name, field_type|
              <<~ATTR_READER
                #: #{field_type}
                attr_reader :#{field_name}
              ATTR_READER
            end.join("\n")
          }

          #: (#{fields.values.join(', ')}) -> void
          def initialize(#{fields.keys.join(', ')})
            super()
            #{
              fields.keys.map do |field_name|
                "@#{field_name} = #{field_name}"
              end.join("\n")
            }
          end

          # @override
          #: [R] (Visitor[R]) -> R
          def accept(visitor)
            visitor.visit_#{class_name.downcase}_#{base_name.downcase}(self)
          end
        end
      RUBY
    end

    #: (String, Hash[String, Hash[String, String]]) -> String
    def define_visitor(base_name, types)
      <<~RUBY
        # @abstract
        #: [R]
        module Visitor
          #{
            types.map do |class_name, fields|
              <<~CLASS
                # @abstract
                #: (#{class_name}) -> R
                def visit_#{class_name.downcase}_#{base_name.downcase}(#{base_name.downcase}); end
              CLASS
            end.join("\n\n")
          }
        end
      RUBY
    end
  end
end

GenerateAST.main('lib/rlox')

# typed: false
# frozen_string_literal: true

# # frozen_string_literal: true

# require 'rlox/expr'

# class Rlox
#   #: [R = String]
#   class ASTPrinter
#     include Expr::Visitor

#     #: (Expr) -> String
#     def print(expr)
#       expr.accept(self)
#     end

#     # @override
#     #: (Binary) -> String
#     def visit_binary_expr(expr)
#       parenthesize(expr.operator.lexeme, expr.left, expr.right)
#     end

#     # @override
#     #: (Grouping) -> String
#     def visit_grouping_expr(expr)
#       parenthesize('group', expr.expression)
#     end

#     # @override
#     #: (Literal) -> String
#     def visit_literal_expr(expr)
#       return 'nil' if expr.value.nil?

#       expr.value.to_s
#     end

#     # @override
#     #: (Unary) -> String
#     def visit_unary_expr(expr)
#       parenthesize(expr.operator.lexeme, expr.right)
#     end

#     private

#     #: (String, *Expr) -> String
#     def parenthesize(name, *exprs)
#       "(#{name}#{exprs.map { |expr| " #{expr.accept(self)}" }.join})"
#     end
#   end
# end
